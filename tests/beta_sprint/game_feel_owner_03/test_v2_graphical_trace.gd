extends SceneTree
## Real production mode:1 only. No subclass, adapter, actor writes or manual finish.
const Maps = preload("res://experiments/game_feel_01/maps/map_factory.gd")
const Records = preload("res://foundation/contracts/contract_records.gd")
const Solver = preload("res://foundation/solver/bfs_solver.gd")
const Search = preload("res://foundation/solver/search_records.gd")
const Trace = preload("res://foundation/solver/solution_trace.gd")
const Replayer = preload("res://foundation/parity/trace_replayer.gd")
const Goal = preload("res://foundation/rules/goal_evaluator.gd")
const Geometry = preload("res://foundation/spatial/surface_geometry.gd")
const Orientation = preload("res://foundation/orientation/discrete_orientation.gd")
const View = preload("res://foundation/game_feel/view_contract.gd")
const Capture = preload("res://tests/beta_sprint/game_feel_owner_03/capture_identity.gd")
var checks := 0
var failures: Array[String] = []
var rows: Array = []
var evidence := ""
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): evidence = arg.trim_prefix("--evidence=")
	call_deferred("run")

func vector(value: Array) -> Vector3:
	return Vector3(value[0], value[1], value[2])

func verify_step(level: Dictionary, witness: Dictionary, step: Dictionary, index: int, label: String) -> void:
	var expected: Dictionary = witness.steps[index].expected_state
	var source: Dictionary = witness.initial_state if index == 0 else witness.steps[index - 1].expected_state
	var completion: Dictionary = step.get("completion_evidence", {})
	check(step.has_all(["status", "commit_delta", "commit_signals", "completion_received", "transition_identity", "expected_statekey", "actual_statekey"]), label + " public complete step evidence")
	if not step.has_all(["status", "commit_delta", "commit_signals", "completion_received", "transition_identity", "expected_statekey", "actual_statekey"]): return
	check(step.status == 0 and step.commit_delta == 1 and step.commit_signals == 1 and step.completion_received, label + " one actual commit and natural completion")
	var required := ["transition_identity", "presentation_identity", "source_pose", "target_pose", "semantic", "started_order", "committed_order", "completion_order", "cancelled_order", "frames", "terminal", "final_state", "final_statekey", "final_visual_pose", "expected_visual_pose", "final_camera_pose", "camera_quadrant", "world_id", "orientation", "delivered"]
	check(completion.has_all(required), label + " full native Bridge completion evidence")
	if not completion.has_all(required): return
	var identity: Dictionary = completion.transition_identity
	check(identity == step.transition_identity and identity.has_all(["session_id", "level_run_id", "generation", "transaction_id", "is_global"]), label + " exact full native transition identity")
	check(not str(identity.get("session_id", "")).is_empty() and not str(identity.get("level_run_id", "")).is_empty(), label + " nonempty native session and level run")
	check(["session_id", "level_run_id", "generation"].all(func(k): return completion.presentation_identity.get(k) == identity.get(k)), label + " presentation and transition share current scope")
	check(completion.delivered and completion.cancelled_order == 0 and completion.started_order < completion.committed_order and completion.committed_order < completion.completion_order, label + " STARTED then COMMITTED then settled completion")
	check(completion.source_pose == source.player and completion.target_pose == expected.player, label + " original trace source and target player pose")
	check(completion.final_state == expected and completion.final_statekey == witness.steps[index].resulting_statekey and step.actual_statekey == step.expected_statekey and step.actual_statekey == completion.final_statekey, label + " exact full authoritative state and StateKey")
	check(completion.orientation == expected.player.orientation and completion.world_id == expected.player.location.layer and completion.camera_quadrant == expected.camera_quadrant, label + " exact Orientation World Camera")
	check(completion.final_visual_pose == completion.expected_visual_pose, label + " actual physical pose equals formal projection")
	var columns: Array = Orientation.columns(expected.player.orientation)
	check(range(3).all(func(i): return vector(completion.final_visual_pose.basis[i]).is_equal_approx(Vector3(columns[i]))), label + " independent formal orientation columns")
	var spatial: Dictionary = Geometry.snapshot(level, expected)
	check(spatial.ok, label + " formal Spatial endpoint")
	if spatial.ok:
		var anchors: Array = spatial.value.anchors.filter(func(a): return a.face_id == Geometry.face_id(expected.player.location.cube_id, expected.player.location.face) and a.layer == expected.player.location.layer)
		check(anchors.size() == 1, label + " unique formal endpoint anchor")
		if anchors.size() == 1:
			check(vector(completion.final_visual_pose.origin).is_equal_approx(Vector3(anchors[0].position2 + anchors[0].frame.normal) * 0.5), label + " physical center matches formal anchor and support normal")
	var camera_basis: Basis = View.basis(expected.camera_quadrant)
	var camera_columns: Array = [camera_basis.x, camera_basis.y, camera_basis.z]
	check(range(3).all(func(i): return vector(completion.final_camera_pose.basis[i]).is_equal_approx(camera_columns[i])), label + " actual render Camera direction matches formal quadrant")
	check(completion.frames.size() > 3 and completion.frames.all(func(f): return f.has_all(["phase", "elapsed", "pose", "camera_pose", "statekey"])), label + " actual motion frame evidence including Camera")
	if index == 0:
		check(completion.semantic == "PERSPECTIVE_FALL_APPLIED" and completion.terminal.terminal_phase == "LANDING_SETTLED", label + " semantic Fall waits for actual Landing restoration")
		check(completion.frames.any(func(f): return f.phase == "FALL") and completion.frames.any(func(f): return f.phase == "LANDING"), label + " real Fall and Landing frames")
		check(completion.orientation == source.player.orientation, label + " Fall PRESERVE orientation")
	else:
		check(completion.semantic == "MOVE_APPLIED_NORMAL" and completion.terminal.terminal_phase == "ROLL_RESTORED", label + " real ordinary Roll restoration")
func run() -> void:
	check(DisplayServer.get_name() != "headless", "formal graphical attempt runs in actual renderer")
	for letter in ["a", "b"]:
		var baked := Maps.bake_game_feel(Maps.read_spec(letter))
		check(baked.ok, letter + " actual Map public Baker")
		if not baked.ok: continue
		var level: Dictionary = baked.level
		var policy := Search.default_policy(1)
		var solved := Solver.solve(level, Records.initial_state(level), policy, Search.default_budget())
		check(solved.status == 0 and solved.solution_trace != null, letter + " official Solver witness")
		check(solved.graph != null and solved.graph.complete, letter + " original complete unfiltered graph supplies selected witness")
		if solved.solution_trace == null: continue
		var witness: Dictionary = solved.solution_trace
		check(Trace.validate(level, witness).ok and Trace.validate_semantics(level, witness).ok, letter + " structural and semantic trace validation")
		check(witness.total_actions == 2 and witness.steps[0].expected_state.player.location.cube_id == &"target" and witness.steps[1].expected_state.player.location.cube_id == &"exit", letter + " same authored Fall/Roll Goal route")
		check(witness.steps.size() == 2 and witness.steps[0].action == {"kind": 0, "face_axis": 2} and witness.steps[1].action == {"kind": 0, "face_axis": 0}, letter + " original MOVE U_NEG Fall then Roll U_POS witness")
		check(Goal.is_goal(level, witness.steps[-1].expected_state).is_goal, letter + " actual original witness Goal")
		var driver := Replayer.new()
		root.add_child(driver)
		var previous: Array = []
		for repeat in 2:
			var graphical: Dictionary = await driver.replay(level, witness, {"mode": 1})
			check(graphical.status == 0 and graphical.issues.is_empty(), letter + " formal graphical MATCH")
			check(graphical.matched_steps == 2 and graphical.trace_length == 2, letter + " two naturally completed original steps")
			check(graphical.actual_statekey == witness.goal_statekey, letter + " formal replay full Goal StateKey")
			check(driver.has_method("get_step_evidence"), letter + " public read-only step evidence")
			var steps: Array = driver.get_step_evidence() if driver.has_method("get_step_evidence") else []
			check(steps.size() == 2, letter + " two public original step records")
			for index in mini(steps.size(), 2):
				verify_step(level, witness, steps[index], index, letter + " repeat " + str(repeat) + " step " + str(index))
				if repeat == 1 and index < previous.size():
					check(previous[index].actual_statekey == steps[index].actual_statekey and previous[index].completion_evidence.final_state == steps[index].completion_evidence.final_state, letter + " repeated replay exact semantic endpoint")
					check(previous[index].transition_identity != steps[index].transition_identity, letter + " repeated replay fresh native identity")
			rows.append({"map": letter, "repeat": repeat, "level": level, "level_hash": level.content_hash, "trace": witness,
				"policy": policy, "result": graphical, "steps": steps,
				"production_api": "foundation/parity/trace_replayer.gd::replay(mode=1)", "matched_steps": graphical.matched_steps})
			previous = steps
		var logical: Dictionary = await driver.replay(level, witness, {"mode": 0})
		check(logical.status == 0 and logical.matched_steps == 2 and logical.actual_statekey == witness.goal_statekey, letter + " separate LOGICAL_SESSION original witness MATCH")
		rows.append({"map": letter, "mode": "LOGICAL_SESSION", "result": logical, "trace": witness})
		driver.free()
	var capture := Capture.snapshot("FORMAL_TRACE_REPLAYER_API_MODE_1")
	capture.fixture_kind = "REAL_CANONICAL_MAP_AB"
	capture.authoritative_runtime = failures.is_empty()
	capture.doubles = []
	FileAccess.open(evidence.path_join("report.json"), FileAccess.WRITE).store_string(JSON.stringify({
		"checks": checks, "failures": failures, "doubles": [], "capture": capture, "rows": rows,
		"formal_graphical": "PASS" if failures.is_empty() else "FAIL", "display": DisplayServer.get_name(), "renderer": RenderingServer.get_current_rendering_method(),
		"user_data_dir": OS.get_user_data_dir(), "input": "official Solver witness + formal replay API; no manual completion",
		"authority": "Formal production Replayer replay(level, original Solver witness, {mode:1}); no override, adapter, manual finish or synthetic completion"}, "\t"))
	quit(0 if failures.is_empty() else 1)
