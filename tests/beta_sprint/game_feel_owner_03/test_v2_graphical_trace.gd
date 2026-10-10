extends SceneTree
## Real production mode:1 only. No subclass, adapter, actor writes or manual finish.
const Maps = preload("res://experiments/game_feel_01/maps/map_factory.gd")
const Records = preload("res://foundation/contracts/contract_records.gd")
const Solver = preload("res://foundation/solver/bfs_solver.gd")
const Search = preload("res://foundation/solver/search_records.gd")
const Trace = preload("res://foundation/solver/solution_trace.gd")
const Replayer = preload("res://foundation/parity/trace_replayer.gd")
const Goal = preload("res://foundation/rules/goal_evaluator.gd")
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
		var graphical: Dictionary = await driver.replay(level, witness, {"mode": 1})
		check(graphical.status == 0 and graphical.issues.is_empty(), letter + " formal graphical MATCH")
		check(graphical.matched_steps == 2 and graphical.trace_length == 2, letter + " two naturally completed original steps")
		check(graphical.actual_statekey == witness.goal_statekey, letter + " formal replay full Goal StateKey")
		check(driver.has_method("get_step_evidence"), letter + " public read-only step evidence")
		var steps: Array = driver.get_step_evidence() if driver.has_method("get_step_evidence") else []
		rows.append({"map": letter, "level": level, "level_hash": level.content_hash, "trace": witness,
			"policy": policy, "result": graphical, "steps": steps,
			"production_api": "foundation/parity/trace_replayer.gd::replay(mode=1)", "matched_steps": graphical.matched_steps})
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
