extends SceneTree
## Actual Main/Shell/AudioDirector/Runtime. No cue fixture, player double or finish API.
const Key = preload("res://foundation/contracts/state_key.gd")
var checks := 0
var failures: Array[String] = []
var rows: Array = []
var cues: Array = []
var evidence := ""
var shell: Node
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): evidence = arg.trim_prefix("--evidence=")
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func key(code: int) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
func wait_idle(lab: Node) -> void:
	var deadline := Time.get_ticks_msec() + 4000
	while Time.get_ticks_msec() < deadline:
		if lab.runtime.is_idle() and lab.presenter.snapshot().phase == "IDLE": return
		await process_frame
	check(false, "natural audio/Presenter completion deadline")
func on_cue(cue: String, identity: Variant) -> void:
	var lab: Node = shell.adapter.level
	cues.append({"cue": cue, "identity": identity, "time_usec": Time.get_ticks_usec(),
		"actor_origin": lab.actor.transform.origin if lab != null and "runtime" in lab else null,
		"runtime_state": lab.runtime.get_state() if lab != null and "runtime" in lab else null})
func run() -> void:
	check(DisplayServer.get_name() != "headless", "actual renderer and Main")
	shell = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	root.add_child(shell)
	await create_timer(0.3).timeout
	var bridge: Node = shell.game_feel
	bridge.audio.cue_played.connect(on_cue)
	for letter in ["a", "b"]:
		bridge.launch_lab(letter)
		await process_frame
		var lab: Node = shell.adapter.level
		var state: Dictionary = lab.runtime.get_state()
		var level: Dictionary = lab.runtime.get_level()
		var before_key: String = Key.build(level, state).key
		var before_audio: Dictionary = bridge.audio.snapshot()
		await create_timer(0.8).timeout
		check(lab.runtime.get_state() == state and lab.runtime.get_commit_count() == 0 and lab.presenter.snapshot().phase == "IDLE", "idle authored connection never falls automatically")
		await key(KEY_F)
		var active: Dictionary = lab.presenter.snapshot()
		var started_audio: Dictionary = bridge.audio.snapshot()
		check(active.phase == "FALL" and lab.runtime.get_commit_count() == 0, "real Fall accepted before audio pause")
		check(int(started_audio.cue_counts.get("fall_start", 0)) == int(before_audio.cue_counts.get("fall_start", 0)) + 1, "one actual accepted Fall start cue")
		check(started_audio.playing.has("sfx:fall_whoosh"), "real scoped whoosh is playing before Pause")
		await key(KEY_ESCAPE)
		check(bridge.audio.snapshot().paused and lab.runtime.is_paused(), "native Pause reaches AudioDirector and Runtime")
		# Track the voices observed playing BEFORE pause. Godot's playing getter
		# no longer identifies paused voices; inactive players are outside this assertion.
		var live_names: Array = started_audio.playing.map(func(voice): return String(voice).replace(":", "_"))
		var players: Array = bridge.audio.get_children().filter(func(child): return child is AudioStreamPlayer and live_names.has(String(child.name)))
		var paused_players: Array = players.map(func(player): return {"name": player.name, "playing": player.playing, "stream_paused": player.stream_paused})
		check(not players.is_empty() and players.size() == live_names.size() and players.all(func(player): return player.stream_paused), "all voices active before Pause have stream_paused set")
		var frozen: Transform3D = lab.actor.transform
		await create_timer(0.15).timeout
		check(lab.actor.transform == frozen and lab.runtime.get_state() == state and bridge.audio.snapshot().cue_counts == started_audio.cue_counts, "paused native pose/state/audio cue counts frozen")
		await key(KEY_ESCAPE)
		check(not bridge.audio.snapshot().paused and lab.presenter.snapshot().presentation_identity == active.presentation_identity, "Resume retains same captured identity without restart")
		await wait_idle(lab)
		var landed_audio: Dictionary = bridge.audio.snapshot()
		check(lab.runtime.get_commit_count() == 1 and lab.runtime.get_state().player.location.cube_id == &"target", "natural committed landing")
		check(int(landed_audio.cue_counts.get("landing_impact", 0)) == int(before_audio.cue_counts.get("landing_impact", 0)) + 1, "one actual native Landing cue")
		var target: Vector3 = lab.project_pose(lab.runtime.get_state().player).transform.origin
		var impacts := cues.filter(func(cue): return cue.cue == "landing_impact" and cue.identity == active.presentation_identity)
		check(impacts.size() == 1 and impacts[0].actor_origin.is_equal_approx(target), "actual Landing cue at formal actor contact center")
		shell.open_settings()
		await process_frame
		var key_before_settings: String = Key.build(level, lab.runtime.get_state()).key
		var gains: Dictionary = bridge.audio.snapshot().bus_gains
		bridge.ui.sliders.master.value = 35
		bridge.ui.sliders.music.value = 45
		bridge.ui.sliders.sfx.value = 55
		check(is_equal_approx(AudioServer.get_bus_volume_db(0), linear_to_db(0.35)), "actual Master preview")
		check(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Ambience")), linear_to_db(0.45) + bridge.audio.BASE_DB.Ambience), "actual music preview through Ambience using formal base gain")
		check(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")), linear_to_db(0.55) + bridge.audio.BASE_DB.SFX), "actual SFX preview using formal base gain")
		var preview_gains: Dictionary = bridge.audio.snapshot().bus_gains
		shell.cancel_settings()
		await process_frame
		check(bridge.audio.snapshot().bus_gains == gains and Key.build(level, lab.runtime.get_state()).key == key_before_settings, "cancel restores actual buses without Gameplay mutation")
		if shell.state == shell.State.PAUSED: await key(KEY_ESCAPE)
		lab.reset_level()
		await process_frame
		await key(KEY_F)
		var cancel_audio: Dictionary = bridge.audio.snapshot()
		await key(KEY_R)
		await process_frame
		check(lab.runtime.get_commit_count() == 0 and Key.build(level, lab.runtime.get_state()).key == before_key, "native in-flight Reset restores state")
		check(not bridge.audio.snapshot().playing.has("sfx:fall_whoosh") and bridge.audio.snapshot().cue_counts.get("landing_impact", 0) == cancel_audio.cue_counts.get("landing_impact", 0), "Reset stops actual scoped loop without Landing cue")
		rows.append({"map": letter, "before": before_audio, "started": started_audio, "landed": landed_audio,
			"after_reset": bridge.audio.snapshot(), "paused_players": paused_players, "preview_gains": preview_gains,
			"identity": active.presentation_identity, "cues": cues.duplicate(true)})
	check(bridge.audio.snapshot().issues.is_empty(), "actual AudioDirector has no resource/stream diagnostics")
	shell.queue_free()
	await create_timer(0.2).timeout
	FileAccess.open(evidence.path_join("report.json"), FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures,
		"rows": rows, "doubles": [], "display": DisplayServer.get_name(), "renderer": RenderingServer.get_current_rendering_method(),
		"user_data_dir": OS.get_user_data_dir(), "authority": "real Main/Shell/AudioDirector/native Input/Runtime/Presenter; no manual completion",
		"timing_scope": "cue callback at actual actor contact center; hardware A/V latency and undeclared sync tolerance NOT_ASSESSED; Edge not integrated"}, "\t"))
	quit(0 if failures.is_empty() else 1)
