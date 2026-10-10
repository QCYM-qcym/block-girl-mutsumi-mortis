extends SceneTree
const F = preload("res://tests/beta_sprint/game_feel_owner_01/fixtures.gd")
const Baker = preload("res://foundation/level/level_baker.gd")
const R = preload("res://foundation/contracts/contract_records.gd")
const Actions = preload("res://foundation/solver/action_generator.gd")
const Explorer = preload("res://foundation/solver/state_explorer.gd")
const Search = preload("res://foundation/solver/search_records.gd")
const Trace = preload("res://foundation/solver/solution_trace.gd")
const Softlock = preload("res://foundation/quality/softlock/softlock_analyzer.gd")
const Replayer = preload("res://foundation/parity/trace_replayer.gd")
var checks := 0
var failures: Array[String] = []
var observations: Array = []
func check(ok: bool, name: String) -> void:
	checks += 1
	if not ok: failures.append(name)
func _initialize() -> void:
	create_timer(30).timeout.connect(func(): printerr("TEST_TIMEOUT"); quit(2))
	call_deferred("run")
func run() -> void:
	for higher in [false,true]:
		var authoring := F.level(higher)
		authoring.erase("content_hash")
		var baked := Baker.bake(authoring,{"max_configurations":4096,"max_checks":100000})
		check(baked.ok,"real Baker/legacy StaticValidator admit opt-in level; no substituted ports")
		if not baked.ok:
			observations.append(baked)
			continue
		var level: Dictionary = baked.level
		var initial := R.initial_state(level)
		var generated := Actions.generate(level,initial)
		check(generated.ok and generated.actions.has({"kind":8,"connection_id":&"edge_a"}),"formal generator enumerates authored directed Fall")
		check(generated.actions.has({"kind":9,"camera_quadrant":0}) and generated.actions.has({"kind":9,"camera_quadrant":3}),"camera is authoritative Solver graph state")
		var search := Explorer.explore(level,initial,Search.default_policy(1),Search.default_budget())
		check(search.status == 0 and search.graph != null and search.graph.complete and search.solution_trace != null,"real complete BFS reaches designed Goal")
		if search.solution_trace == null:
			observations.append(search)
			continue
		check(search.solution_trace.trace_version == "solutiontrace.game_feel.v1","trace is explicitly versioned, never mislabeled legacy v1")
		check(search.solution_trace.total_actions == 1 and search.solution_trace.steps[0].expected_state.player.location.cube_id == &"target","one intended directed connection, no fabricated shortcut")
		check(Trace.validate_semantics(level,search.solution_trace).ok,"real Kernel re-executes every generated trace step")
		var old_tag: Dictionary = search.solution_trace.duplicate(true)
		old_tag.trace_version = "solutiontrace.v1"
		check(not Trace.validate(level,old_tag).ok,"legacy trace tag cannot silently accept new camera/Fall state")
		var softlock := Softlock.analyze(level,search.graph,{"max_nodes":10000,"max_edges":100000,"max_runtime_ms":0})
		check(softlock.status == 0 and softlock.softlock_count == 0,"real reverse graph analysis proves no irreversible softlock")
		var replayer := Replayer.new()
		root.add_child(replayer)
		var replay: Dictionary = await replayer.replay(level,search.solution_trace,{"mode":0})
		check(replay.status == 0 and replay.matched_steps == search.solution_trace.total_actions,"formal LOGICAL_SESSION replay matches complete StateKey")
		var repeated: Dictionary = await replayer.replay(level,search.solution_trace,{"mode":0})
		check(repeated.status == 0 and repeated.actual_statekey == replay.actual_statekey,"fresh runtime replay is deterministic")
		var graphical: Dictionary = await replayer.replay(level,search.solution_trace,{"mode":1})
		check(graphical.status == 0 and graphical.matched_steps == search.solution_trace.total_actions and graphical.actual_statekey == replay.actual_statekey,"formal natural Bridge now replays the exact v2 Goal; missing dependency stays covered by Unit")
		observations.append({"higher":higher,"search":search,"softlock":softlock,"replay":replay})
		replayer.free()
	var summary := {"checks":checks,"failures":failures,"doubles":[],"authority":"real Baker/Validator/Explorer/Kernel/Softlock/TraceReplayer; logical and natural headless Bridge","observations":observations}
	FileAccess.open(OS.get_environment("FOUNDATION_TEST_EVIDENCE").path_join("results.json"),FileAccess.WRITE).store_string(JSON.stringify(summary))
	print("SOLVER_REPLAY checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
