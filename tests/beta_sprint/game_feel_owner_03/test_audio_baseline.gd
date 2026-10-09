extends SceneTree
## Real delivered audio resources/players/signals. Headless: no audible or contact-sync claim.
const Audio = preload("res://game/polish/p01_audio.gd")
const Capture = preload("res://tests/beta_sprint/game_feel_owner_03/capture_identity.gd")
var checks := 0
var failures: Array[String] = []
var cues: Array[String] = []
var evidence := ""

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="): evidence = arg.trim_prefix("--evidence-dir=")
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		printerr("FAIL: ", label)

func run() -> void:
	check(not evidence.is_empty(), "explicit evidence directory")
	var audio := Audio.new()
	root.add_child(audio)
	await process_frame
	audio.cue_played.connect(func(cue: String): cues.append(cue))
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://production/audio/p01/manifest.json"))
	for cue in manifest:
		var resource_path: String = manifest[cue].path
		check(ResourceLoader.exists(resource_path) and load(resource_path) is AudioStream, "actual imported audio stream: " + cue)
	for cue in ["roll", "land"]:
		audio.play(cue)
	check(cues == ["roll", "land"], "real play calls emit one event per existing valid cue")
	check(audio.players["roll"].playing and audio.players["land"].playing and audio.active_sfx_count() == 2,
		"valid cues start actual SFX streams before Reset")
	audio.play("game_feel_missing_cue")
	check(cues == ["roll", "land"], "unknown cue emits no event")
	audio.reset(0)
	check(audio.active_sfx_count() == 0, "actual Reset stops active SFX")
	audio.enabled = false
	audio.play("roll")
	audio.tick(0.1, 0, false)
	check(cues == ["roll", "land"] and audio.active_sfx_count() == 0, "disabled audio emits no cue and stops voices")
	for player in audio.ambience:
		check(player.volume_db == -80, "disabled ambience is silent")
	var weak: WeakRef = weakref(audio)
	audio.queue_free()
	await process_frame
	check(weak.get_ref() == null, "audio node and owned players are released")
	# AudioServer retires stopped/free player voices on its mixing thread. Let
	# that thread consume the teardown before exiting the entire test process.
	await create_timer(0.2).timeout
	var report := {"execution_kind": "PRODUCTION_HEADLESS_BASELINE", "checks": checks,
		"capture": Capture.snapshot("PRODUCTION_AUDIO_PLAY_RESET"),
		"failures": failures, "cues": cues, "display": DisplayServer.get_name(),
		"not_run": ["Fall cue mapping", "Landing contact timing", "Pause audio", "audible quality"]}
	FileAccess.open(evidence.path_join("audio_baseline.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("GAME_FEEL_AUDIO_BASELINE checks=", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)
