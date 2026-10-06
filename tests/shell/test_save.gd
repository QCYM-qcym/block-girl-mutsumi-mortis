extends SceneTree
var checks := 0
var failures: Array[String] = []
var location := "user://shell_tests/save_" + str(Time.get_ticks_usec()) + "/progress.json"

func _initialize() -> void:
	if not ResourceLoader.exists("res://game/shell/save_store.gd"):
		printerr("FAIL: Game Shell safe progress store is missing")
		quit(1)
		return
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		printerr("FAIL: ", label)

func write_raw(path: String, content: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(content)
	f.close()

func run() -> void:
	var Store = load("res://game/shell/save_store.gd")
	var store = Store.new(location, "p01")
	var data: Dictionary = store.load_save()
	check(data.unlocked == ["p01"] and not data.has_progress, "cold start has first level but no Continue")
	data.has_progress = true
	data.recent = "p01"
	data.completed = ["p01"]
	data.unlocked = ["p01", "p02"]
	data.settings = {"master": 0.42, "music": 0.23, "sfx": 0.67, "fullscreen": false}
	check(store.save(data), "first save is written to user directory")
	var fresh = Store.new(location, "p01")
	var restored: Dictionary = fresh.load_save()
	check(restored.completed == ["p01"] and restored.unlocked == ["p01", "p02"] and restored.recent == "p01", "reopen restores recent/unlocked/completed progress")
	check(is_equal_approx(restored.settings.master, 0.42) and is_equal_approx(restored.settings.music, 0.23), "settings reopen without resetting volumes")
	data.recent = "p02"
	check(store.save(data), "overwrite an existing save safely")
	check(FileAccess.file_exists(location + ".bak"), "last valid generation retained")
	write_raw(location, "broken json")
	check(fresh.load_save().recent == "p01", "corrupt primary recovers verified backup")
	check(fresh.save(data), "can save recovered data without losing corrupt evidence")
	check(fresh.load_save().recent == "p02", "replacement after recovery reloads latest data")
	var original := FileAccess.get_file_as_string(location)
	var blocker := location + ".bak"
	DirAccess.remove_absolute(blocker)
	DirAccess.make_dir_absolute(blocker)
	data.recent = "p01"
	check(not store.save(data), "blocked backup replacement reports failure")
	check(FileAccess.get_file_as_string(location) == original, "failed write preserves exact primary bytes")
	DirAccess.remove_absolute(blocker)
	var future := JSON.stringify({"version": 99, "payload": {}, "checksum": "future"})
	write_raw(location, future)
	fresh.load_save()
	check(fresh.read_only and not fresh.save(data), "future format refuses downgrade including when backup exists")
	check(FileAccess.get_file_as_string(location) == future, "future primary preserved byte for byte")
	write_raw(location, "broken json")
	write_raw(location + ".bak", "also broken")
	check(not fresh.load_save().has_progress and not fresh.read_only, "both corrupt files still permit startup")
	check(fresh.save(data), "both corrupt files preserved before new safe save")
	var invalid := data.duplicate(true)
	invalid.settings.master = 2.0
	check(not fresh.save(invalid), "invalid volume never replaces valid progress")
	invalid = data.duplicate(true)
	invalid.unlocked = []
	check(not fresh.save(invalid), "empty unlocked set rejected")
	invalid = data.duplicate(true)
	invalid.recent = "locked"
	check(not fresh.save(invalid), "recent level must be unlocked")
	invalid = data.duplicate(true)
	invalid.settings.muted = "yes"
	check(not fresh.save(invalid), "mute flag must be a boolean")
	print("SHELL SAVE: ", checks, " checks, failures=", failures)
	quit(0 if failures.is_empty() else 1)
