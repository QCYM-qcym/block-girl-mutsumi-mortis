extends SceneTree
const SaveStore = preload("res://game/shell/save_store.gd")
const Director = preload("res://game/feel/audio/audio_director.gd")
const EXPECTED := {"master": 0.42, "music": 0.31, "sfx": 0.67, "fullscreen": false, "muted": true}
var output := ""
var mode := ""
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="): output = arg.trim_prefix("--evidence-dir=")
		if arg.begins_with("--mode="): mode = arg.trim_prefix("--mode=")
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures.append(label)
		print("FAIL: ", label)

func run() -> void:
	var store = SaveStore.new("user://owner11_volume_contract/profile.json", "fixture-level")
	if mode == "write":
		check(not FileAccess.file_exists(store.path), "fresh isolated save absent before write")
		var data: Dictionary = store.defaults()
		data.settings = EXPECTED.duplicate()
		check(store.save(data), "existing Shell SaveStore writes unchanged settings schema")
		check(store.load_save().settings == EXPECTED, "existing writer reads back values")
	else:
		check(FileAccess.file_exists(store.path), "independent process opens writer save")
		var loaded: Dictionary = store.load_save()
		check(loaded.settings == EXPECTED, "independent process settings persisted exactly")
		check(loaded.settings.size() == 5, "no new save keys")
		var director = Director.new()
		root.add_child(director)
		director.apply_settings(loaded.settings)
		for pair in [["Master", "master", 0.0], ["Ambience", "music", -12.0], ["SFX", "sfx", -6.0]]:
			var index := AudioServer.get_bus_index(pair[0])
			check(absf(AudioServer.get_bus_volume_db(index) - (linear_to_db(EXPECTED[pair[1]]) + pair[2])) < 0.01, "persisted gain applied to " + pair[0])
		check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")), "persisted muted flag applied")
		director.clear()
		root.remove_child(director)
		director.queue_free()
		await create_timer(0.1).timeout
	var actual_file := ProjectSettings.globalize_path(store.path)
	var report := {"checks": checks, "failures": failures, "mode": mode, "pid": OS.get_process_id(), "engine": Engine.get_version_info(), "user_data_dir": OS.get_user_data_dir(), "display": DisplayServer.get_name(), "fixture_kind": "EXISTING_SAVE_API_AUDIO_CONTRACT", "authoritative_runtime": false, "doubles": ["isolated synthetic progress fixture"], "save_path": actual_file, "save_sha256": FileAccess.get_sha256(actual_file), "settings": store.load_save().settings, "shell_ui_integration": "PENDING_00"}
	var file := FileAccess.open(output.path_join("settings_" + mode + ".json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("AUDIO_SETTINGS_", mode, " checks=", checks, " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
