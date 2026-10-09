extends SceneTree
## Real Host lifecycle consumer. No state assignment, replacement model, clock/tick or finish calls.
const Lab = preload("res://experiments/game_feel_01/host/core_lab.tscn")
const Key = preload("res://foundation/contracts/state_key.gd")
var checks := 0
var failures: Array[String] = []
var cases: Array = []
var evidence := ""
var host: Node3D
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): evidence = arg.trim_prefix("--evidence=")
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func key(code: int, pressed: bool = true, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	event.echo = echo
	Input.parse_input_event(event)
func tap(code: int) -> void:
	key(code)
	await process_frame
	key(code, false)
	await process_frame
func wait_phase(phase: String) -> void:
	var deadline := Time.get_ticks_msec() + 4000
	while Time.get_ticks_msec() < deadline:
		if host.presenter.snapshot().phase == phase and (phase != "IDLE" or host.runtime.is_idle()): return
		await process_frame
	check(false, "bounded actual phase: " + phase)
func run_case(letter: String, phase: String, input_id: String) -> void:
	host.load_map(letter)
	await process_frame
	var level: Dictionary = host.runtime.get_level()
	var initial: Dictionary = host.runtime.get_state()
	var initial_tweens := get_processed_tweens().size()
	var source_key: String = Key.build(level, initial).key
	var offset: int = host.events.size()
	var observed: Array = []
	var observer: Callable = func(event): observed.append({"event": event, "actual_state": host.runtime.get_state(), "actual_key": Key.build(level, host.runtime.get_state()).key})
	host.runtime.game_feel_event.connect(observer)
	var first_failure: int = failures.size()
	var first_check := checks
	await tap(KEY_F)
	await wait_phase(phase)
	var accepted: Array = host.events.slice(offset).filter(func(event): return event.semantic == "PERSPECTIVE_FALL_APPLIED" and event.phase == "STARTED")
	check(accepted.size() == 1, "one initial native Fall accepted")
	var expected_fall: Dictionary = accepted[0].result.next_state if accepted.size() == 1 else {}
	var active: Dictionary = host.presenter.snapshot().duplicate(true)
	check(active.phase == phase, "input occurs during actual " + phase)
	var before: Dictionary = host.runtime.get_state()
	if phase == "LANDING": check(before == expected_fall, "Landing begins in exact accepted canonical Fall endpoint")
	var pose: Transform3D = host.actor.transform
	match input_id:
		"held_wasd", "edge_spam", "reverse":
			var codes := [KEY_W, KEY_A, KEY_S, KEY_D] if input_id == "held_wasd" else ([KEY_A, KEY_D] if input_id == "reverse" else [KEY_A])
			for code in codes: key(code)
			for iteration in 12:
				for code in codes: key(code, true, input_id == "held_wasd")
			await process_frame
			for code in codes: key(code, false)
			await process_frame
		"camera_qe":
			key(KEY_Q);key(KEY_E)
			await process_frame
			key(KEY_Q, false);key(KEY_E, false)
			await process_frame
		"pause":
			await tap(KEY_ESCAPE)
			var paused: Dictionary = host.presenter.snapshot()
			var frozen: Transform3D = host.actor.transform
			await create_timer(0.12).timeout
			check(host.paused and host.runtime.get_state() == before and host.actor.transform == frozen, "native Pause freezes actual pose and state")
			check(host.presenter.snapshot().elapsed == paused.elapsed and host.presenter.snapshot().presentation_identity == active.presentation_identity, "Pause retains token and suspends elapsed")
			await tap(KEY_ESCAPE)
		"reset":
			await tap(KEY_R)
			check(host.runtime.get_commit_count() == 0 and Key.build(level, host.runtime.get_state()).key == source_key, "native Reset restores official full statekey")
			check(host.presenter.snapshot().phase == "IDLE" and host.presenter.snapshot().presentation_identity.is_empty(), "native Reset clears active presentation")
			var projected: Dictionary = host.project_pose(host.runtime.get_state().player)
			check(projected.ok and host.actor.transform.is_equal_approx(projected.transform), "Reset restores actual formal visual pose")
			await tap(KEY_F)
			await wait_phase("IDLE")
			check(host.runtime.get_commit_count() == 1 and host.runtime.get_state().player.location.cube_id == &"target", "new native Fall remains usable after Reset")
	if phase == "FALL" and input_id not in ["reset", "pause"]:
		check(host.runtime.get_state() == before and host.runtime.get_commit_count() == 0, "in-flight input preserves committed state")
		check(host.presenter.snapshot().presentation_identity == active.presentation_identity and host.runtime.get_state().camera_quadrant == before.camera_quadrant, "in-flight input cannot retarget token or camera")
	await wait_phase("IDLE")
	var commits := {}
	var starts := {}
	for event in host.events.slice(offset):
		if event.semantic in ["PERSPECTIVE_FALL_APPLIED", "MOVE_APPLIED_NORMAL"]:
			var identity := str(event.transition_identity)
			if event.phase == "STARTED": starts[identity] = int(starts.get(identity, 0)) + 1
			if event.phase == "COMMITTED": commits[identity] = int(commits.get(identity, 0)) + 1
	check(starts.values().all(func(count): return count == 1) and commits.values().all(func(count): return count == 1), "one start/commit per actual captured token")
	check(commits.keys().all(func(identity): return starts.has(identity)), "every commit belongs to an accepted captured token")
	var fall_commits: Array = observed.filter(func(row): return row.event.semantic == "PERSPECTIVE_FALL_APPLIED" and row.event.phase == "COMMITTED")
	var fall_starts: Array = observed.filter(func(row): return row.event.semantic == "PERSPECTIVE_FALL_APPLIED" and row.event.phase == "STARTED")
	var expected_count := 2 if phase == "LANDING" and input_id == "reset" else 1
	check(fall_commits.size() == expected_count, "required Fall commits occur; cancellation cannot pass as successful completion")
	if input_id == "reset":
		check(fall_starts.size() == 2 and fall_starts[0].event.transition_identity != fall_starts[1].event.transition_identity, "Reset creates distinct captured old/new transition identities")
		check(not fall_commits.is_empty() and fall_starts.size() == 2 and fall_commits[-1].event.transition_identity == fall_starts[1].event.transition_identity, "new post-Reset token supplies actual successful commit")
		if phase == "FALL": check(fall_commits.all(func(row): return row.event.transition_identity != active.transition_identity), "cancelled old in-flight identity never commits")
	else:
		check(fall_commits.size() == 1 and fall_commits[0].event.transition_identity == active.transition_identity, "captured initial Fall identity supplies actual successful commit")
	check(fall_commits.all(func(row): return row.actual_state == row.event.result.next_state and row.actual_key == Key.build(level, row.event.result.next_state).key), "each actual Fall commit matches full native proposal and official StateKey")
	var state: Dictionary = host.runtime.get_state()
	if phase == "LANDING" and input_id == "edge_spam":
		var rejections: Array = observed.filter(func(row): return row.event.semantic == "MOVE_REJECTED_EDGE" and row.event.reason_category == "EDGE")
		check(rejections.size() == 13 and state == before, "rapid edge inputs are actual EDGE rejections with unchanged complete state")
		check(rejections.all(func(row): return row.event.result.next_state == null and row.actual_state == row.event.result.previous_state), "each native EDGE rejection preserves actual authoritative state")
	if phase == "FALL" and input_id != "reset": check(state == expected_fall, "Fall inputs preserve exact authorized target Orientation/World/camera")
	var expected_pose: Dictionary = host.project_pose(state.player)
	check(expected_pose.ok and host.actor.transform.is_equal_approx(expected_pose.transform), "settled Runtime/actual Presenter physical pose parity")
	check(state.player.location.layer == initial.player.location.layer, "input does not switch World")
	check(host.host_issues.is_empty(), "no actual Host errors")
	check(get_processed_tweens().size() <= initial_tweens, "no residual scene Tween after settled native motion")
	check([KEY_W, KEY_A, KEY_S, KEY_D, KEY_Q, KEY_E].all(func(code): return not Input.is_physical_key_pressed(code)), "injected held inputs released")
	var case_events: Array = host.events.slice(offset).duplicate(true)
	host.runtime.game_feel_event.disconnect(observer)
	var settled_pose: Transform3D = host.actor.transform
	await tap(KEY_R)
	await tap(KEY_F)
	await wait_phase("IDLE")
	check(host.runtime.get_commit_count() == 1 and host.runtime.get_state().player.location.cube_id == &"target", "subsequent native Fall accepted and naturally completed after each lifecycle case")
	var next_pose: Dictionary = host.project_pose(host.runtime.get_state().player)
	check(next_pose.ok and host.actor.transform.is_equal_approx(next_pose.transform), "subsequent native input has exact physical endpoint")
	cases.append({"id": "A_INPUT_" + phase + "_" + input_id.to_upper(), "map": letter,
		"status": "PASS" if failures.size() == first_failure else "FAIL", "checks": checks - first_check,
		"before": before, "after": state, "source_key": source_key, "final_key": Key.build(level, state).key,
		"captured_identity": active, "events": case_events, "pose": settled_pose,
		"commit_observations": fall_commits, "expected_fall": expected_fall,
		"feedback_observations": observed.filter(func(row): return row.event.semantic in ["MOVE_REJECTED_EDGE", "ACTION_FEEDBACK"]),
		"next_input_key": Key.build(level, host.runtime.get_state()).key, "next_input_pose": host.actor.transform,
		"initial_phase_pose": pose, "scope": "native Core Host input + natural 10A; Audio/Edge not included"})
func run() -> void:
	check(DisplayServer.get_name() != "headless", "real graphical renderer")
	host = Lab.instantiate()
	root.add_child(host)
	await process_frame
	for letter in ["a", "b"]:
		for phase in ["FALL", "LANDING"]:
			for input_id in ["held_wasd", "edge_spam", "reverse", "camera_qe", "reset", "pause"]:
				await run_case(letter, phase, input_id)
	host.queue_free()
	await create_timer(0.2).timeout
	FileAccess.open(evidence.path_join("report.json"), FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures,
		"cases": cases, "doubles": [], "authority": "actual native Input.parse_input_event -> existing Host/Runtime/Presenter; only natural completion",
		"display": DisplayServer.get_name(), "renderer": RenderingServer.get_current_rendering_method(), "user_data_dir": OS.get_user_data_dir()}, "\t"))
	quit(0 if failures.is_empty() else 1)
