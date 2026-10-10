extends "res://tests/beta_sprint/game_feel_owner_03/test_v2_graphical_trace.gd"
## Public Node lifecycle + native R input; every new run uses the sole real Replayer.

func observe(driver: Node, level: Dictionary, witness: Dictionary, options: Dictionary, slot: Dictionary) -> void:
	slot.result = await driver.replay(level, witness, options)
	slot.finished = true

func bridge_of(driver: Node) -> Node:
	for child in driver.get_children():
		if child.get_script() != null and child.get_script().resource_path == "res://game/feel/graphical_completion_bridge.gd": return child
	return null

func wait_phase(driver: Node, slot: Dictionary, phase: String) -> Dictionary:
	var deadline := Time.get_ticks_msec() + 4000
	while Time.get_ticks_msec() < deadline and not slot.finished:
		var bridge := bridge_of(driver)
		if bridge != null:
			var snapshot: Dictionary = bridge.snapshot()
			if snapshot.presenter.get("phase") == phase: return snapshot
		await process_frame
	check(false, "actual formal replay reaches " + phase)
	return {}

func wait_result(slot: Dictionary, label: String) -> void:
	var deadline := Time.get_ticks_msec() + 5000
	while not slot.finished and Time.get_ticks_msec() < deadline: await process_frame
	check(slot.finished, label + " bounded formal replay return")

func native_reset() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_R
	event.physical_keycode = KEY_R
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventKey.new()
	event.keycode = KEY_R
	event.physical_keycode = KEY_R
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func verify_new_run(driver: Node, level: Dictionary, witness: Dictionary, slot: Dictionary, old_identity: Dictionary, label: String) -> void:
	await wait_result(slot, label)
	if not slot.finished: return
	check(slot.result.status == 0 and slot.result.matched_steps == 2 and slot.result.actual_statekey == witness.goal_statekey, label + " new original witness reaches actual Goal")
	check(driver.has_method("get_step_evidence"), label + " public new-run evidence")
	var steps: Array = driver.get_step_evidence() if driver.has_method("get_step_evidence") else []
	check(steps.size() == 2, label + " exactly two uncontaminated new steps")
	for index in mini(steps.size(), 2):
		verify_step(level, witness, steps[index], index, label + " new step " + str(index))
		check(steps[index].get("transition_identity", {}) != old_identity, label + " no old native identity in new steps")

func scenario(letter: String, level: Dictionary, witness: Dictionary, phase: String, operation: String) -> void:
	var label := letter + " " + phase + " " + operation
	var driver := Replayer.new()
	root.add_child(driver)
	var old := {"finished": false, "result": {}}
	observe(driver, level, witness, {"mode": 1}, old)
	var snapshot: Dictionary = await wait_phase(driver, old, phase)
	if snapshot.is_empty():
		driver.free()
		return
	var identity: Dictionary = snapshot.presenter.transition_identity.duplicate(true)
	check(not identity.is_empty(), label + " actual in-flight native identity")
	var old_bridge := bridge_of(driver)
	var late_completions: Array = []
	var actual_cancellations: Array = []
	old_bridge.motion_completed.connect(func(i, e): late_completions.append({"identity": i, "evidence": e}))
	old_bridge.motion_cancelled.connect(func(i, r): actual_cancellations.append({"identity": i, "reason": r}))
	var retired: Dictionary = {}
	var reset_commits: Array = []
	var next := {"finished": false, "result": {}}
	if operation == "reset":
		var bound_runtime: RefCounted = old_bridge.runtime
		bound_runtime.committed.connect(func(s): reset_commits.append({"state": s.duplicate(true), "scope": bound_runtime.get_presentation_scope(), "commit_count": bound_runtime.get_commit_count(), "idle": bound_runtime.is_idle()}), CONNECT_ONE_SHOT)
		await native_reset()
		check(reset_commits.size() == 1, label + " actual native Runtime Reset commit observed")
		if reset_commits.size() == 1:
			check(reset_commits[0].state == witness.initial_state and reset_commits[0].commit_count == 0 and reset_commits[0].idle, label + " native Reset restores full spawn and idle with zero commits")
			check(reset_commits[0].scope.generation == identity.generation + 1 and reset_commits[0].scope.session_id == identity.session_id and reset_commits[0].scope.level_run_id == identity.level_run_id, label + " native Reset advances same-session generation")
		if is_instance_valid(old_bridge): retired = old_bridge.snapshot()
		await wait_result(old, label + " old")
		observe(driver, level, witness, {"mode": 1}, next)
	elif operation == "remove_readd":
		root.remove_child(driver)
		if is_instance_valid(old_bridge): retired = old_bridge.snapshot()
		root.add_child(driver)
		# Start synchronously before the old process-frame await resumes.
		observe(driver, level, witness, {"mode": 1}, next)
		await wait_result(old, label + " obsolete await")
	else:
		root.remove_child(driver)
		if is_instance_valid(old_bridge): retired = old_bridge.snapshot()
		await wait_result(old, label + " exited scene")
		var dead: WeakRef = weakref(driver)
		driver.free()
		check(dead.get_ref() == null, label + " old replay scene actually freed")
		driver = Replayer.new()
		root.add_child(driver)
		observe(driver, level, witness, {"mode": 1}, next)
	if old.finished:
		check(old.result.status in [2, 3] and old.result.matched_steps == 0, label + " cancelled old run never becomes MATCH")
	var cancelled: Array = retired.get("records", []).filter(func(r): return r.transition_identity == identity)
	check(cancelled.size() == 1, label + " one actual old Bridge record")
	if cancelled.size() == 1:
		check(cancelled[0].cancelled_order > 0 and cancelled[0].completion_order == 0 and not cancelled[0].delivered, label + " cancellation exclusive with natural completion")
		if operation == "reset": check(cancelled[0].get("cancellation_reason") == "RESET", label + " native R retains RESET cancellation reason")
	await verify_new_run(driver, level, witness, next, identity, label)
	for idle_frame in 3: await process_frame
	check(late_completions.is_empty(), label + " no late old Bridge completion after new replay")
	check(actual_cancellations.size() == 1 and actual_cancellations[0].identity == identity, label + " one actual cancellation signal across old/new lifetime")
	rows.append({"map": letter, "phase": phase, "operation": operation, "old_identity": identity,
		"old_result": old.result, "retired_bridge": retired, "new_result": next.result,
		"native_reset_commits": reset_commits,
		"old_actual_cancellations": actual_cancellations, "old_late_completions": late_completions,
		"new_steps": driver.get_step_evidence() if driver.has_method("get_step_evidence") else []})
	driver.free()

func expiry(letter: String, level: Dictionary, witness: Dictionary) -> void:
	var driver := Replayer.new()
	root.add_child(driver)
	var old := {"finished": false, "result": {}}
	observe(driver, level, witness, {"mode": 1, "step_timeout_ms": 100}, old)
	var started: Dictionary = await wait_phase(driver, old, "FALL")
	var identity: Dictionary = started.get("presenter", {}).get("transition_identity", {})
	var old_bridge := bridge_of(driver)
	var late_completions: Array = []
	var actual_cancellations: Array = []
	if old_bridge != null:
		old_bridge.motion_completed.connect(func(i, e): late_completions.append({"identity": i, "evidence": e}))
		old_bridge.motion_cancelled.connect(func(i, r): actual_cancellations.append({"identity": i, "reason": r}))
	await wait_result(old, letter + " expiry")
	if old.finished: check(old.result.status == 3 and old.result.matched_steps == 0, letter + " actual in-flight timeout remains INCOMPLETE")
	var retired: Dictionary = old_bridge.snapshot() if is_instance_valid(old_bridge) else {}
	var cancelled: Array = retired.get("records", []).filter(func(r): return r.transition_identity == identity)
	check(cancelled.size() == 1, letter + " expiry owns actual old Bridge record")
	if cancelled.size() == 1: check(cancelled[0].cancelled_order > 0 and cancelled[0].completion_order == 0 and not cancelled[0].delivered, letter + " actual timeout cleanup cancels without completion")
	var next := {"finished": false, "result": {}}
	observe(driver, level, witness, {"mode": 1}, next)
	await verify_new_run(driver, level, witness, next, identity, letter + " expiry recovery")
	for idle_frame in 3: await process_frame
	check(late_completions.is_empty(), letter + " no expired completion after recovery")
	check(actual_cancellations.size() == 1 and actual_cancellations[0].identity == identity, letter + " one actual expiry cancellation signal")
	rows.append({"map": letter, "operation": "step_timeout", "old_identity": identity,
		"old_result": old.result, "retired_bridge": retired, "new_result": next.result,
		"old_actual_cancellations": actual_cancellations, "old_late_completions": late_completions,
		"new_steps": driver.get_step_evidence() if driver.has_method("get_step_evidence") else []})
	driver.free()

func run() -> void:
	check(DisplayServer.get_name() != "headless", "actual Windows graphical lifecycle")
	for letter in ["a", "b"]:
		var baked: Dictionary = Maps.bake_game_feel(Maps.read_spec(letter))
		check(baked.ok, letter + " public canonical Baker")
		if not baked.ok: continue
		var level: Dictionary = baked.level
		var solved := Solver.solve(level, Records.initial_state(level), Search.default_policy(1), Search.default_budget())
		check(solved.status == 0 and solved.graph != null and solved.graph.complete and solved.solution_trace != null, letter + " original real FULL_GRAPH witness")
		if solved.solution_trace == null: continue
		var witness: Dictionary = solved.solution_trace
		check(Trace.validate(level, witness).ok and Trace.validate_semantics(level, witness).ok, letter + " original hard witness revalidated")
		for phase in ["FALL", "LANDING"]:
			for operation in ["reset", "remove_readd", "exit"]: await scenario(letter, level, witness, phase, operation)
		await expiry(letter, level, witness)
	var capture := Capture.snapshot("FORMAL_GRAPHICAL native R / SceneTree lifecycle / real step timeout")
	capture.authoritative_runtime = true
	capture.fixture_kind = "REAL_CANONICAL_MAP_AB"
	FileAccess.open(evidence.path_join("report.json"), FileAccess.WRITE).store_string(JSON.stringify({
		"checks": checks, "failures": failures, "doubles": [], "capture": capture, "rows": rows,
		"authority": "Sole production Replayer/Facade/Bridge. Public native R and Node removal/readdition/exit; no override, adapter, manual finish or synthetic completion"}, "\t"))
	quit(0 if failures.is_empty() else 1)
