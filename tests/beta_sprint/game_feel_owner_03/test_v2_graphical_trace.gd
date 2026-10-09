extends SceneTree
## Calls the sole formal replay implementation; never overrides _make_session or builds a bridge.
const Maps = preload("res://experiments/game_feel_01/maps/map_factory.gd")
const Records = preload("res://foundation/contracts/contract_records.gd")
const Solver = preload("res://foundation/solver/bfs_solver.gd")
const Search = preload("res://foundation/solver/search_records.gd")
const Trace = preload("res://foundation/solver/solution_trace.gd")
const Replayer = preload("res://foundation/parity/trace_replayer.gd")
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
		var solved := Solver.solve(level, Records.initial_state(level), Search.default_policy(1), Search.default_budget())
		check(solved.status == 0 and solved.solution_trace != null, letter + " official Solver witness")
		check(solved.graph != null and solved.graph.complete, letter + " original complete unfiltered graph supplies selected witness")
		if solved.solution_trace == null: continue
		var witness: Dictionary = solved.solution_trace
		check(Trace.validate(level, witness).ok and Trace.validate_semantics(level, witness).ok, letter + " structural and semantic trace validation")
		check(witness.total_actions == 2 and witness.steps[0].expected_state.player.location.cube_id == &"target" and witness.steps[1].expected_state.player.location.cube_id == &"exit", letter + " same authored Fall/Roll Goal route")
		var driver := Replayer.new()
		root.add_child(driver)
		var graphical: Dictionary = await driver.replay(level, witness, {"mode": 1})
		var blocked: bool = graphical.status == 2 and graphical.matched_steps == 0 and graphical.issues.size() == 1 and graphical.issues[0].path == "dependencies.GameFeelPresenter" and graphical.issues[0].message == "CASE_DEPENDENCY_PENDING: GAME_FEEL_GRAPHICAL_COMPLETION_BRIDGE"
		check(blocked, letter + " exact current production bridge dependency identified; not a graphical MATCH")
		rows.append({"map": letter, "level_hash": level.content_hash, "trace": witness,
			"formal_graphical": "BLOCKED" if blocked else "FAIL", "result": graphical,
			"production_api": "foundation/parity/trace_replayer.gd::replay(mode=1)", "matched_steps": graphical.matched_steps})
		driver.free()
	var capture := Capture.snapshot("FORMAL_TRACE_REPLAYER_API_MODE_1")
	capture.fixture_kind = "REAL_CANONICAL_MAP_AB"
	capture.authoritative_runtime = false
	capture.dependency_probe_scope = "formal API exits before constructing graphical Runtime/Presenter session"
	capture.doubles = []
	FileAccess.open(evidence.path_join("report.json"), FileAccess.WRITE).store_string(JSON.stringify({
		"checks": checks, "failures": failures, "doubles": [], "capture": capture, "rows": rows,
		"formal_graphical": "BLOCKED", "display": DisplayServer.get_name(), "renderer": RenderingServer.get_current_rendering_method(),
		"user_data_dir": OS.get_user_data_dir(), "input": "official Solver witness + formal replay API; no manual completion",
		"authority": "Real production fail-closed dependency probe; zero graphical replay steps, never a graphical PASS"}, "\t"))
	quit(0 if failures.is_empty() else 1)
