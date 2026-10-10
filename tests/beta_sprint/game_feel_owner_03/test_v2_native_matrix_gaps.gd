extends "res://tests/beta_sprint/game_feel_owner_03/test_v2_lifecycle.gd"
## Actual integrated Shell/10B/Audio inputs; no event, state, pose or clock writes.
const Capture = preload("res://tests/beta_sprint/game_feel_owner_03/capture_identity.gd")
const Mapper = preload("res://foundation/runtime/input_mapper.gd")
const View = preload("res://foundation/game_feel/view_contract.gd")
var shell: Node
var batch := "all"
func _initialize() -> void:
	super._initialize()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--batch="): batch = arg.trim_prefix("--batch=")
class FocusProbe extends Node:
	var notifications: Array = []
	func _notification(what: int) -> void:
		if what in [NOTIFICATION_WM_WINDOW_FOCUS_IN, NOTIFICATION_WM_WINDOW_FOCUS_OUT]:
			notifications.append({"time_ms": Time.get_ticks_msec(), "notification": what})
var focus_probe: FocusProbe

func settle(seconds: float) -> void:
	await create_timer(seconds).timeout

func click(control: Control) -> void:
	check(control.is_visible_in_tree(), "actual Exit control visible")
	var at := control.get_global_rect().get_center()
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = at
		event.pressed = down
		Input.parse_input_event(event)
		await process_frame

func pose(value: Transform3D) -> Dictionary:
	return {"origin": [value.origin.x, value.origin.y, value.origin.z],
		"basis": [[value.basis.x.x,value.basis.x.y,value.basis.x.z], [value.basis.y.x,value.basis.y.y,value.basis.y.z], [value.basis.z.x,value.basis.z.y,value.basis.z.z]]}

func run_case(letter: String, phase: String, input_id: String) -> void:
	var label := letter + " " + phase + " " + input_id
	var first_check := checks
	var first_failure := failures.size()
	var focus_offset := focus_probe.notifications.size()
	var start_ms := Time.get_ticks_msec()
	shell.game_feel.launch_lab(letter)
	await settle(0.12)
	root.grab_focus()
	await process_frame
	check(root.has_focus(), label + " actual window focused before native gameplay input")
	host = shell.adapter.level
	var runtime: RefCounted = host.runtime
	var presenter: RefCounted = host.presenter
	var initial: Dictionary = runtime.get_state()
	var level: Dictionary = runtime.get_level()
	var source_key: String = Key.build(level, initial).key
	var source_pose: Transform3D = host.actor.transform
	var events: Array = []
	var cancellations: Array = []
	var completions: Array = []
	var native_commits: Array = []
	var event_observer: Callable = func(e): events.append({"event": e.duplicate(true), "state": runtime.get_state().duplicate(true), "time_ms": Time.get_ticks_msec()})
	var cancel_observer: Callable = func(i, reason): cancellations.append({"identity": i, "reason": reason, "time_ms": Time.get_ticks_msec()})
	var complete_observer: Callable = func(i, proof): completions.append({"identity": i, "evidence": proof, "time_ms": Time.get_ticks_msec()})
	var commit_observer: Callable = func(s): native_commits.append({"state":s.duplicate(true), "scope":runtime.get_presentation_scope(), "count":runtime.get_commit_count(), "time_ms":Time.get_ticks_msec()})
	runtime.game_feel_event.connect(event_observer)
	presenter.motion_cancelled.connect(cancel_observer)
	presenter.motion_completed.connect(complete_observer)
	runtime.committed.connect(commit_observer)
	var baseline_tweens := get_processed_tweens().size()
	if phase == "EDGE": key(KEY_D)
	else: await tap(KEY_F)
	await wait_phase(phase)
	if phase == "EDGE":
		await process_frame
		await process_frame
	var active: Dictionary = presenter.snapshot().duplicate(true)
	check(active.phase == phase, label + " input occurs in actual required phase")
	var before: Dictionary = runtime.get_state()
	if phase == "EDGE":
		check(before == initial and runtime.get_commit_count() == 0 and runtime.is_idle(), label + " actual native EDGE preserves full authoritative spawn")
		check(not host.actor.transform.is_equal_approx(source_pose), label + " real10B lean is visibly non-neutral")
	var audio_before: Dictionary = shell.game_feel.audio.snapshot()
	var input_offset := events.size()
	var input_scope: Dictionary = runtime.get_presentation_scope()
	var held_frames: Array = []
	match input_id:
		"held_wasd", "edge_spam", "reverse":
			var codes := [KEY_W,KEY_A,KEY_S,KEY_D] if input_id == "held_wasd" else ([KEY_A,KEY_D] if input_id == "reverse" else [KEY_D])
			for code in codes: key(code)
			for iteration in 12:
				for code in codes: key(code, true, input_id == "held_wasd")
				if input_id == "held_wasd":
					await process_frame
					held_frames.append({"time_ms":Time.get_ticks_msec(),"pressed":codes.map(func(c): return Input.is_physical_key_pressed(c)),"presenter":presenter.snapshot()})
			await process_frame
			var move_receipts: Array = events.slice(input_offset).filter(func(r): return r.event.result.action.get("kind") == 0 and r.event.phase in ["STARTED","FEEDBACK","REJECTED"])
			var expected_requests := 4 if input_id == "held_wasd" else (26 if input_id == "reverse" else 13)
			check(move_receipts.size() == expected_requests, label + " every non-echo native movement input has a real Runtime receipt")
			# Isometric screen directions can legitimately map to the same axis.
			# Consume the sole official mapper instead of guessing four distinct axes.
			var directions := {KEY_W:Vector2.UP,KEY_A:Vector2.LEFT,KEY_S:Vector2.DOWN,KEY_D:Vector2.RIGHT}
			var frame: Dictionary = events[0].event.source_frame
			for index in move_receipts.size():
				var expected: Dictionary = Mapper.map_move(frame,View.basis(before.camera_quadrant),directions[codes[index % codes.size()]])
				check(expected.ok and move_receipts[index].event.result.action == expected.action, label + " native input matches official Mapper direction " + str(index))
			if input_id in ["held_wasd","reverse"]:
				check(move_receipts.any(func(r): return r.event.semantic == "PERSPECTIVE_FALL_APPLIED" and r.event.phase == "STARTED" and r.event.result.status == 0), label + " actual permitted movement preempts rejection through real Fall")
			if input_id == "held_wasd":
				check(held_frames.size() == 12 and held_frames.all(func(f): return f.pressed.all(func(v): return v)) and held_frames[-1].time_ms > held_frames[0].time_ms + 100, label + " physical WASD remains held across actual distinct frames")
			if input_id == "edge_spam":
				check(presenter.snapshot().presentation_identity == active.presentation_identity and presenter.snapshot().elapsed >= active.elapsed, label + " rapid refusal retains original rejection cycle")
				check(runtime.get_state() == before and runtime.get_commit_count() == 0, label + " rapid edge has zero mutation")
				check(move_receipts.all(func(r): return r.event.semantic == "MOVE_REJECTED_EDGE" and r.state == before and r.event.result.next_state == null), label + " all13 actual rapid requests remain native EDGE refusals")
			for code in codes: key(code, false)
			await process_frame
		"camera_qe":
			key(KEY_Q);key(KEY_E)
			await process_frame
			key(KEY_Q,false);key(KEY_E,false)
			await process_frame
			var camera_receipts: Array = events.slice(input_offset).filter(func(r): return r.event.result.action.get("kind") == 9 and r.event.phase in ["STARTED","FEEDBACK","REJECTED"])
			check(camera_receipts.size() == 2 and camera_receipts[0].event.result.action.camera_quadrant == posmod(before.camera_quadrant-1,4) and camera_receipts[1].event.result.action.camera_quadrant == posmod(before.camera_quadrant+1,4), label + " both real Q/E requests reach Runtime with exact directions")
			check(camera_receipts.size() == 2 and camera_receipts[0].event.phase == "FEEDBACK" and camera_receipts[0].event.result.status == 0 and camera_receipts[0].event.reason_category == "NONE" and camera_receipts[1].event.reason_category == "BUSY", label + " real first Camera proposal accepted and conflicting second rejected through formal FEEDBACK")
		"space":
			await tap(KEY_SPACE)
			check(runtime.get_state() == before, label + " actual denied Shift does not switch World/Face/state")
			var feedback: Array = events.filter(func(r): return r.event.get("semantic") == "ACTION_FEEDBACK" and r.event.result.action.kind == 1)
			check(feedback.size() == 1 and feedback[0].event.reason_category in ["BUSY","UNCLASSIFIED_REJECTION"], label + " native Space retains explicit non-edge classification")
			if feedback.size() == 1:
				check(feedback[0].event.result.status == 1 and feedback[0].event.result.next_state == null and feedback[0].state == feedback[0].event.result.previous_state, label + " real Shift rejection retains native status and unchanged full state")
				if phase != "FALL": check(feedback[0].event.reason_category == "UNCLASSIFIED_REJECTION" and feedback[0].event.result.rejection_code == 1400, label + " real unclassified1400 is preserved rather than inferred EDGE")
		"reset":
			await tap(KEY_R)
			check(runtime.get_state() == initial and runtime.get_commit_count() == 0 and runtime.is_idle(), label + " native Reset restores full authoritative spawn")
			check(presenter.snapshot().phase == "IDLE" and host.actor.transform.is_equal_approx(source_pose), label + " Reset clears real10B and restores exact physical pose")
			check(native_commits.size() == 1 and native_commits[0].state == initial and native_commits[0].count == 0 and native_commits[0].scope.generation == input_scope.generation+1 and native_commits[0].scope.session_id == input_scope.session_id and native_commits[0].scope.level_run_id == input_scope.level_run_id, label + " real R produces native Reset commit and same-run generation increment")
		"pause", "exit_level":
			await tap(KEY_ESCAPE)
			var paused: Dictionary = presenter.snapshot()
			var frozen: Transform3D = host.actor.transform
			await settle(0.12)
			check(shell.state == shell.State.PAUSED and runtime.is_paused(), label + " actual Shell Pause suspends Runtime")
			check(host.actor.transform == frozen and presenter.snapshot().elapsed == paused.elapsed and presenter.snapshot().presentation_identity == active.presentation_identity, label + " pause preserves elapsed/pose/captured identity")
			check(shell.game_feel.audio.snapshot().paused, label + " actual AudioDirector paused")
			if input_id == "pause": await tap(KEY_ESCAPE)
			else:
				await click(shell.view.buttons.main)
				check(shell.state == shell.State.MAIN_MENU and shell.adapter.level == null, label + " real menu click unloads level")
				check(not runtime.is_loaded() and presenter.snapshot().phase == "IDLE", label + " unloaded Runtime and cleared native motion")
				if phase == "EDGE":
					check(active.transition_identity.is_empty() and events.any(func(r): return r.event.semantic == "ANIMATION_INTERRUPTED" and r.event.interruption_reason == "UNLOAD" and r.event.presentation_identity == active.presentation_identity and r.event.transition_identity == null), label + " actual rejected presentation is interrupted without a Runtime token")
				else:
					var old_cancel: Array = cancellations.filter(func(c): return c.identity == active.transition_identity)
					var old_commit: Array = events.filter(func(r): return r.event.phase == "COMMITTED" and r.event.transition_identity == active.transition_identity)
					check(old_cancel.size() == 1 and old_cancel[0].reason == "UNLOAD" and not completions.any(func(c): return c.identity == active.transition_identity), label + " exact old UNLOAD cancellation excludes every old completion")
					check(old_commit.size() == (0 if phase == "FALL" else 1), label + " old Fall0/Landing1 native commits retained across unload")
	key(KEY_D,false)
	await process_frame
	var after := {}
	var final_pose := {}
	if input_id != "exit_level":
		await wait_phase("IDLE")
		after = runtime.get_state()
		var projected: Dictionary = host.project_pose(after.player)
		check(projected.ok and host.actor.transform.is_equal_approx(projected.transform), label + " exact full Runtime/Presenter endpoint and orientation")
		check(host.host_issues.is_empty() and not runtime.is_paused(), label + " no lifecycle issue or stuck paused input")
		if phase == "EDGE" and input_id in ["edge_spam","space","pause"]:
			check(after == initial and host.actor.transform.is_equal_approx(source_pose), label + " Recoil ends at unchanged position and orientation")
		final_pose = pose(host.actor.transform)
		if phase == "EDGE" and input_id == "edge_spam":
			check(int(shell.game_feel.audio.snapshot().cue_counts.get("edge_recoil",0))-int(audio_before.cue_counts.get("edge_recoil",0)) <= 1, label + " rapid native edge refusals cannot spam actual AudioDirector cues")
		if phase in ["FALL","LANDING"] and input_id == "space":
			var matching_commits: Array = events.filter(func(r): return r.event.phase == "COMMITTED" and r.event.transition_identity == active.transition_identity)
			var matching_completions: Array = completions.filter(func(c): return c.identity == active.transition_identity)
			check(matching_commits.size() == 1 and after == matching_commits[0].event.result.next_state and runtime.get_commit_count() == 1, label + " original captured Fall token completes exactly once at full authorized target")
			check(matching_completions.size() == 1 and matching_completions[0].evidence.terminal_phase == "LANDING_SETTLED" and not cancellations.any(func(c): return c.identity == active.transition_identity), label + " denied Space does not cancel original natural Landing completion")
	var starts := {}
	var commits := {}
	for observed in events:
		var event: Dictionary = observed.event
		if event.phase == "STARTED": starts[str(event.transition_identity)] = int(starts.get(str(event.transition_identity), 0)) + 1
		if event.phase == "COMMITTED":
			commits[str(event.transition_identity)] = int(commits.get(str(event.transition_identity), 0)) + 1
			check(observed.state == event.result.next_state and Key.build(level, observed.state).key == Key.build(level, event.result.next_state).key, label + " actual commit full state/StateKey matches native proposal")
	check(starts.values().all(func(n): return n == 1) and commits.values().all(func(n): return n == 1) and commits.keys().all(func(i): return starts.has(i)), label + " no duplicate accepted transition/commit")
	check([KEY_W,KEY_A,KEY_S,KEY_D,KEY_Q,KEY_E,KEY_SPACE].all(func(code): return not Input.is_physical_key_pressed(code)), label + " all input releases reached native system")
	var retired_at := Time.get_ticks_msec()
	var old_dead: WeakRef = weakref(host)
	shell.show_main_menu()
	await process_frame
	await process_frame
	check(old_dead.get_ref() == null, label + " old scene actually freed")
	var late_at := Time.get_ticks_msec()
	shell.game_feel.launch_lab(letter)
	await process_frame
	root.grab_focus()
	await process_frame
	check(root.has_focus(), label + " real new-run window focus")
	host = shell.adapter.level
	await tap(KEY_F)
	await wait_phase("IDLE")
	check(host.runtime.get_state().player.location.cube_id == &"target" and host.runtime.get_commit_count() == 1, label + " new native input remains usable and completes genuine Fall")
	await tap(KEY_D)
	await wait_phase("IDLE")
	check(host.runtime.get_state().player.location.cube_id == &"exit" and host.runtime.get_state().player.orientation == 12 and host.runtime.get_commit_count() == 2, label + " new native Roll reaches actual Goal after old teardown")
	var recovered: Dictionary = host.project_pose(host.runtime.get_state().player)
	check(recovered.ok and host.actor.transform.is_equal_approx(recovered.transform), label + " new physical pose exactly matches fresh Runtime")
	check(not completions.any(func(c): return c.time_ms >= late_at), label + " no old completion during new launch")
	check(get_processed_tweens().size() <= baseline_tweens, label + " no residual animation Tween")
	# Observer closures must not retain the retired RefCounted Runtime through
	# its own signal. This disconnects quality listeners only, after late checks.
	runtime.game_feel_event.disconnect(event_observer)
	presenter.motion_cancelled.disconnect(cancel_observer)
	presenter.motion_completed.disconnect(complete_observer)
	runtime.committed.disconnect(commit_observer)
	cases.append({"id": "A_INPUT_" + ("EDGE_RECOIL" if phase == "EDGE" else phase) + "_" + input_id.to_upper(), "map": letter,
		"status": "PASS" if failures.size() == first_failure else "FAIL", "checks": checks-first_check,
		"before": before, "after": after, "source_key": source_key, "active": active, "final_pose": final_pose,
		"events": events, "cancellations": cancellations, "completions": completions,
		"native_commits":native_commits,"held_frames":held_frames,
		"audio_before": audio_before, "audio_after_new_launch": shell.game_feel.audio.snapshot(),
		"recovery_state": host.runtime.get_state(), "recovery_key": Key.build(host.runtime.get_level(),host.runtime.get_state()).key,
		"start_ms": start_ms, "retired_at_ms": retired_at, "new_launch_ms": late_at,
		"focus_notifications": focus_probe.notifications.slice(focus_offset), "authority": "Native integrated Shell input / unchanged production Runtime+Presenter+10B+Audio"})

func run() -> void:
	check(DisplayServer.get_name() != "headless", "real Windows graphical matrix gaps")
	focus_probe = FocusProbe.new()
	root.add_child(focus_probe)
	shell = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	root.add_child(shell)
	root.size = Vector2i(1280,720)
	await settle(0.3)
	var inputs := ["held_wasd","edge_spam","reverse"] if batch == "base" else (["camera_qe","space","reset"] if batch == "control" else (["pause","exit_level"] if batch == "exit" else []))
	if batch == "all": inputs = ["held_wasd","edge_spam","reverse","camera_qe","space","reset","pause","exit_level"]
	check(batch in ["all","base","control","exit","fall"], "explicit native matrix batch")
	for letter in ["a","b"]:
		for input_id in inputs:
			await run_case(letter, "EDGE", input_id)
		if batch in ["all","fall"]:
			for phase in ["FALL","LANDING"]:
				for input_id in ["space","exit_level"]: await run_case(letter, phase, input_id)
	shell.queue_free()
	await settle(0.2)
	var capture := Capture.snapshot("Native Shell/10B inputs / actual menu click / no doubles")
	capture.authoritative_runtime = true
	capture.fixture_kind = "REAL_CANONICAL_MAP_AB"
	FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"doubles":[],"capture":capture,"cases":cases,"focus_notifications":focus_probe.notifications},"\t"))
	quit(0 if failures.is_empty() else 1)
