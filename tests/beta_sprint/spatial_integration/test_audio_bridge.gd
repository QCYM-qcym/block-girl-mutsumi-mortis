extends SceneTree
const Host = preload("res://experiments/spatial_puzzle_batch_01/host/spatial_lab.gd")
const Maps = preload("res://experiments/spatial_puzzle_batch_01/maps/map_factory.gd")
const Key = preload("res://foundation/contracts/state_key.gd")
const BRIDGE = "res://experiments/spatial_puzzle_batch_01/host/spatial_audio_bridge.gd"
var checks := 0
var failures: Array = []
var captured: Array = []
var evidence := OS.get_environment("FOUNDATION_TEST_EVIDENCE")
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func count(bridge, cue: String) -> int:
	return int(bridge.snapshot().get("cue_counts", {}).get(cue, 0))
func settle(host) -> void:
	var deadline := Time.get_ticks_msec() + 4000
	while (not host.runtime.is_idle() or host.presenter.snapshot().phase != "IDLE") and Time.get_ticks_msec() < deadline:
		await process_frame
	check(host.runtime.is_idle() and host.presenter.snapshot().phase == "IDLE", "natural Tween completion settles")
func action(host, value: Dictionary) -> Dictionary:
	var result: Dictionary = host.runtime.request_action(value)
	check(result.status == 0, "formal action accepted " + str(value))
	await settle(host)
	check(host.runtime.get_state() == result.next_state, "audio leaves authoritative next state unchanged")
	return result
func run() -> void:
	check(ResourceLoader.exists(BRIDGE), "spatial audio bridge exists")
	if not ResourceLoader.exists(BRIDGE): finish(); return
	var host = Host.new()
	host.lab_id = &"face_lock_lab"
	root.add_child(host)
	await process_frame
	var bridge = host.get("audio_bridge")
	if "--require-host-audio" in OS.get_cmdline_user_args():
		check(bridge != null, "actual spatial Host owns the audio bridge")
		if bridge == null:
			host.free(); finish(); return
	if bridge == null:
		bridge = load(BRIDGE).new()
		host.add_child(bridge)
		bridge.bind_runtime(host.runtime)
	host.runtime.game_feel_event.connect(func(event: Dictionary): captured.append(event))
	check(bridge.snapshot().issues.is_empty(), "approved manifest resources load")
	check(bridge.snapshot().playing.has("music:surface") and bridge.snapshot().playing.has("music:inner"), "real paired world music players started")
	for value in Maps.witnesses(&"face_lock_lab").wrong_face: await action(host, value)
	check(count(bridge, "perspective_connect") == 0, "wrong local face remains silent")
	host.reset_lab()
	for value in Maps.witnesses(&"face_lock_lab").correct_face:
		var before := count(bridge, "perspective_connect")
		var result: Dictionary = host.runtime.request_action(value)
		check(result.status == 0, "correct face route accepted")
		check(count(bridge, "perspective_connect") == before, "FaceLock has no speculative cue before commit")
		await settle(host)
	check(count(bridge, "perspective_connect") == 1, "real latch commit cues exactly once")
	var key_before: String = Key.build(host.runtime.get_level(), host.runtime.get_state()).key
	var commit_event: Dictionary = captured[-1]
	host.runtime.game_feel_event.emit(commit_event)
	check(count(bridge, "perspective_connect") == 1, "duplicate actual committed event silent")
	check(Key.build(host.runtime.get_level(), host.runtime.get_state()).key == key_before, "duplicate audio delivery cannot mutate StateKey")
	await action(host, {"kind": 0, "face_axis": 1})
	await action(host, {"kind": 0, "face_axis": 2})
	var shift_before := count(bridge, "world_shift")
	var shift_result: Dictionary = host.runtime.request_action({"kind": 1})
	check(shift_result.status == 0, "real unlocked Shift accepted")
	check(count(bridge, "world_shift") == shift_before, "Shift START has no completion cue")
	bridge.set_paused(true)
	host.set_lab_paused(true)
	check(bridge.snapshot().paused, "pause reaches existing AudioDirector")
	await create_timer(0.4).timeout
	check(count(bridge, "world_shift") == shift_before, "paused native animation cannot complete Shift cue")
	host.set_lab_paused(false)
	bridge.set_paused(false)
	await settle(host)
	check(count(bridge, "world_shift") == shift_before + 1, "matching real native Shift COMMIT cues once")
	check(bridge.snapshot().target_world == 1, "music world follows committed Runtime Inner")
	host.reset_lab()
	check(bridge.snapshot().target_world == 0, "Reset music follows actual Surface state")
	for value in Maps.witnesses(&"face_lock_lab").solution:
		if value.kind == 1: break
		await action(host, value)
	check(count(bridge, "perspective_connect") == 2, "same-run new generation can cue latch again")
	host.runtime.request_action({"kind": 1})
	host.reset_lab()
	await create_timer(0.4).timeout
	check(count(bridge, "world_shift") == shift_before + 1, "Reset cancels pending native Shift without false completion")
	host.load_map("perspective_fork_lab")
	await action(host, {"kind": 9, "camera_quadrant": 1})
	var fall_before := count(bridge, "landing_impact")
	var fall: Dictionary = host.runtime.request_action({"kind": 0, "face_axis": 2})
	check(fall.status == 0 and count(bridge, "fall_start") == 1, "real Fall START cues")
	check(count(bridge, "landing_impact") == fall_before, "Landing requires COMMITTED")
	await settle(host)
	check(count(bridge, "landing_impact") == fall_before + 1, "natural Fall completion one landing impact")
	await action(host, {"kind": 0, "face_axis": 0})
	check(count(bridge, "cube_roll") > 0 and count(bridge, "cube_contact") > 0, "real Roll start/contact consumed")
	host.reset_lab()
	host.runtime.request_action({"kind": 0, "face_axis": 2})
	var stale: Dictionary = captured[-1]
	host.reset_lab()
	await create_timer(0.8).timeout
	check(count(bridge, "landing_impact") == fall_before + 1, "Reset Fall does not emit landing impact")
	var counts: Dictionary = bridge.snapshot().cue_counts
	host.runtime.game_feel_event.emit(stale)
	check(bridge.snapshot().cue_counts == counts, "stale real start after Reset rejected")
	host.load_map("world_shift_gate_lab")
	await action(host, {"kind": 0, "face_axis": 0})
	var cancel_before := count(bridge, "world_shift")
	host.runtime.request_action({"kind": 1})
	host.runtime.interrupt("CANCEL")
	await create_timer(0.4).timeout
	check(count(bridge, "world_shift") == cancel_before, "CANCEL invalidates captured native Shift")
	await action(host, {"kind": 1})
	check(count(bridge, "world_shift") == cancel_before + 1, "new generation Shift after CANCEL can complete")
	var old_run_event: Dictionary = captured[-1]
	host.load_map("orientation_loop_lab")
	counts = bridge.snapshot().cue_counts
	host.runtime.game_feel_event.emit(old_run_event)
	check(bridge.snapshot().cue_counts == counts, "old run event cannot rebind audio")
	var edge_before := count(bridge, "edge_recoil")
	var edge_state: Dictionary = host.runtime.get_state()
	host.runtime.request_action({"kind": 0, "face_axis": 2})
	check(captured[-1].semantic == "MOVE_REJECTED_EDGE", "formal Runtime supplies explicit EDGE rejection")
	check(count(bridge, "edge_recoil") == edge_before + 1, "real Edge cue consumed")
	for repeat in 10: host.runtime.request_action({"kind": 0, "face_axis": 2})
	check(count(bridge, "edge_recoil") == edge_before + 1, "held edge attempts respect existing audio debounce")
	check(host.runtime.get_state() == edge_state, "edge feedback preserves complete authoritative state")
	await settle(host)
	host.load_map("face_lock_lab")
	await action(host, {"kind": 0, "face_axis": 3})
	var latch_before := count(bridge, "perspective_connect")
	var reset_during_contact := func(cue: String, _identity: Variant):
		if cue == "cube_contact": host.reset_lab()
	bridge.director.cue_played.connect(reset_during_contact)
	host.runtime.request_action({"kind": 0, "face_axis": 0})
	await settle(host)
	bridge.director.cue_played.disconnect(reset_during_contact)
	check(count(bridge, "perspective_connect") == latch_before, "synchronous Reset during audio callback cancels stale latch cue")
	check(host.runtime.get_state().mechanism_states.get(&"contact_lock") == &"idle", "reentrant Reset restores formal mechanism state")
	check(bridge.snapshot().issues.is_empty(), "no AudioDirector contract diagnostics")
	bridge.close()
	check(bridge.snapshot().playing.is_empty(), "close stops voices")
	check(not host.runtime.game_feel_event.is_connected(bridge._on_event), "close disconnects Runtime callback")
	bridge._on_event(stale)
	bridge._on_native_started({}, 0, 0, false)
	bridge._on_committed(host.runtime.get_state())
	check(bridge.snapshot().playing.is_empty(), "captured callbacks delivered after close are inert")
	bridge.bind_runtime(host.runtime)
	bridge.bind_runtime(host.runtime)
	await action(host, {"kind": 0, "face_axis": 3})
	check(count(bridge, "cube_roll") == 1 and count(bridge, "cube_contact") == 1, "close/rebind same Facade creates live consumer; duplicate bind is idempotent")
	bridge.close()
	# Let the real audio mixer retire stopped WAV playback before process exit.
	# This is teardown only; every gameplay completion above uses natural Tween.
	await create_timer(0.25).timeout
	host.free()
	await create_timer(0.25).timeout
	finish()
func finish() -> void:
	FileAccess.open(evidence.path_join("report.json"), FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures, "doubles": [], "display": DisplayServer.get_name(), "renderer": RenderingServer.get_current_rendering_method(), "authority": "real spatial Host, Runtime and natural Tween completion; real AudioDirector/AudioStreamPlayer; no audible Human QA"}, "\t"))
	quit(0 if failures.is_empty() else 1)
