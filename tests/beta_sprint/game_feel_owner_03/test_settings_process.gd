extends SceneTree
## Two real OS processes, real SaveStore and AudioServer; no Shell fixture/double.
const Store = preload("res://game/shell/save_store.gd")
const Settings = preload("res://game/shell/settings.gd")
const Capture = preload("res://tests/beta_sprint/game_feel_owner_03/capture_identity.gd")
var checks := 0
var failures: Array[String] = []
var evidence := ""
var save_path := ""
var phase := ""
const VALUES = {"master": 0.31, "music": 0.45, "sfx": 0.0, "fullscreen": false, "muted": false}

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="): evidence = arg.trim_prefix("--evidence-dir=")
		elif arg.begins_with("--shell-save="): save_path = arg.trim_prefix("--shell-save=")
		elif arg.begins_with("--phase="): phase = arg.trim_prefix("--phase=")
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		printerr("FAIL: ", label)

func run() -> void:
	check(save_path.begins_with("user://game_feel_quality/") and not evidence.is_empty(), "isolated test save/evidence required")
	if not failures.is_empty():
		quit(2)
		return
	var store := Store.new(save_path, "mutsumi_l01")
	if phase == "seed":
		check(not FileAccess.file_exists(save_path), "seed starts from fresh isolated save")
		var data := store.defaults()
		data.settings = VALUES.duplicate()
		check(store.save(data), "production SaveStore persists volume/mute/display values")
	check(phase in ["seed", "restore"], "explicit seed or restore phase")
	var loaded := store.load_save()
	check(store.last_error.is_empty() and loaded.settings == VALUES, "production SaveStore reads exact persisted values")
	Settings.apply(loaded.settings, root)
	var buses := {}
	for key in Settings.BUS_MAP:
		var index := AudioServer.get_bus_index(Settings.BUS_MAP[key])
		check(index >= 0, "actual configured bus exists: " + key)
		if index < 0: continue
		var expected_db: float = linear_to_db(maxf(VALUES[key], 0.0001)) + Settings.BASE_DB[key]
		check(is_equal_approx(AudioServer.get_bus_volume_db(index), expected_db), "actual bus restores saved volume: " + key)
		check(AudioServer.is_bus_mute(index) == (VALUES[key] == 0.0), "actual bus restores saved mute: " + key)
		buses[key] = {"db": AudioServer.get_bus_volume_db(index), "muted": AudioServer.is_bus_mute(index)}
	var report := {"execution_kind": "PRODUCTION_HEADLESS_BASELINE", "phase": phase,
		"capture": Capture.snapshot("PRODUCTION_SAVESTORE_AUDIO_BUS_SETTINGS"),
		"checks": checks, "failures": failures, "pid": OS.get_process_id(),
		"save_absolute": ProjectSettings.globalize_path(save_path),
		"save_sha256": FileAccess.get_sha256(save_path), "values": loaded.settings, "buses": buses,
		"not_run": ["graphical volume controls", "audible mix", "Reduced Motion"]}
	FileAccess.open(evidence.path_join("settings_" + phase + ".json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("GAME_FEEL_SETTINGS_", phase.to_upper(), " checks=", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)
