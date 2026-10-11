extends "res://tests/beta_sprint/spatial_quality/suite.gd"
## Public real Baker/Explorer/Safety/Runtime consumers; no BFS or graph builder.
## Runtime completion here is the explicit LOGICAL phase API, never graphical evidence.
const FactoryPath := "res://experiments/spatial_puzzle_batch_01/maps/map_factory.gd"
const Records = preload("res://foundation/contracts/contract_records.gd")
const Codec = preload("res://foundation/level/level_codec.gd")
const Data = preload("res://foundation/contracts/contract_validation.gd")
const Explorer = preload("res://foundation/solver/state_explorer.gd")
const Search = preload("res://foundation/solver/search_records.gd")
const Trace = preload("res://foundation/solver/solution_trace.gd")
const Key = preload("res://foundation/contracts/state_key.gd")
const Geometry = preload("res://foundation/spatial/surface_geometry.gd")
const Facade = preload("res://foundation/game_feel/runtime_facade.gd")
const Safety = preload("res://foundation/validation/safety_queries.gd")
const Softlock = preload("res://foundation/quality/softlock/softlock_analyzer.gd")
const Replayer = preload("res://foundation/parity/trace_replayer.gd")
const Fall = preload("res://foundation/game_feel/fall_permission.gd")
const PREFIX := {&"world_shift_gate_lab":"gate",&"orientation_loop_lab":"loop",&"face_lock_lab":"lock",
	&"perspective_fork_lab":"fork",&"rubik_spatial_puzzle_01":"combined"}

func native_trace(level: Dictionary, trace: Dictionary, prefix: String) -> void:
	begin(prefix + ".runtime_route","REAL_RUNTIME")
	var runtime := Facade.new()
	var events: Array = []
	var native_starts: Array = []
	var observed := weakref(runtime)
	runtime.game_feel_event.connect(func(event): events.append(event.duplicate(true)))
	runtime.transition_started.connect(func(result,token,generation,is_global):
		var live: RefCounted = observed.get_ref()
		if live != null: native_starts.append({"identity":live.get_pending_identity(token,generation,is_global),"result":result.duplicate(true)}))
	check(runtime.load_level(level).ok,"real production Facade loads")
	var initial := runtime.get_state()
	var actual_steps: Array = []
	for step in trace.steps:
		events.clear()
		native_starts.clear()
		var before := runtime.get_state()
		var commits := runtime.get_commit_count()
		var accepted := runtime.request_action(step.action)
		check(accepted.status == 0 and accepted.changed,"original Solver action accepted")
		check(native_starts.size() == 1 and runtime.get_state() == before and runtime.get_commit_count() == commits,"one native proposal, no premature commit")
		if native_starts.size() != 1: break
		var identity: Dictionary = native_starts[0].identity
		check(identity.has_all(["session_id","level_run_id","generation","transaction_id","is_global"]),"complete native identity")
		var completion := runtime.finish_transition(identity)
		check(not completion.get("ignored",true) and runtime.get_commit_count() == commits + 1,"explicit logical completion commits once")
		check(runtime.get_state() == step.expected_state and Key.build(level,runtime.get_state()).key == step.resulting_statekey,"full authoritative state matches original trace")
		var duplicate := runtime.finish_transition(identity)
		check(duplicate.get("ignored",false) and runtime.get_commit_count() == commits + 1,"duplicate token cannot commit again")
		actual_steps.append({"action":step.action,"identity":identity,"events":events.duplicate(true),"state":runtime.get_state()})
	check(runtime.get_commit_count() == trace.total_actions and runtime.is_idle(),"entire actual logical route releases pending state")
	runtime.reset()
	check(runtime.get_state() == initial and runtime.get_commit_count() == 0 and runtime.is_idle(),"native Reset restores full initial state")
	rows.append({"map":prefix,"completion_authority":"NATIVE_RUNTIME_LOGICAL_PHASE_API_ONLY","steps":actual_steps,"reset":runtime.get_state()})
	runtime.interrupt("UNLOAD")

func graph_invariants(level: Dictionary, graph: Dictionary, prefix: String) -> void:
	begin(prefix + ".graph_permissions","SOLVER")
	var shifts := 0
	var falls := 0
	var latches := 0
	for edge in graph.edges:
		var before: Dictionary = graph.nodes[edge.from_key].state
		var after: Dictionary = graph.nodes[edge.to_key].state
		if edge.action.kind == 1:
			shifts += 1
			var source := Geometry.face_id(before.player.location.cube_id,before.player.location.face)
			var target := Geometry.face_id(after.player.location.cube_id,after.player.location.face)
			var gates: Array = level.get("shift_gates",[]).filter(func(g): return g.source_face_id == source)
			check(gates.size() == 1 and gates[0].target_face_id == target,"every real Shift edge uses its exact authored pair")
			if gates.size() == 1:
				for required in gates[0].required_mechanism_states:
					check(before.mechanism_states[required.mechanism_id] == required.state,"no unlatched Shift edge")
				for flag in gates[0].required_flags:
					check(before.level_flags[flag],"no false-flag Shift edge")
			check(after.player.orientation == before.player.orientation and after.camera_quadrant == before.camera_quadrant,"SAME_NORMAL Shift preserves exact pose ID and Camera")
		if edge.action.kind in [0,8] and before.player.location.cube_id != after.player.location.cube_id:
			if edge.global_kind == 0 and after.player.orientation == before.player.orientation:
				falls += 1
		for lock in level.get("face_locks",[]):
			if before.mechanism_states[lock.mechanism_id] != after.mechanism_states[lock.mechanism_id]:
				latches += 1
				check(edge.action.kind == 0 and after.mechanism_states[lock.mechanism_id] == lock.latched_state,"only real MOVE contact latches")
	check(not graph.edges.is_empty(),"actual graph has executable edges")
	if prefix in ["gate","lock","combined"]: check(shifts > 0,"real gated Shift edges exist")
	if prefix in ["lock","combined"]: check(latches > 0,"real latch edges exist")
	if prefix in ["fork","combined"]: check(falls > 0,"real orientation-preserving translation edges exist")
	rows.append({"map":prefix,"actual_graph_shift_edges":shifts,"actual_graph_latch_edges":latches,"translation_edges":falls})

func run() -> void:
	if not ResourceLoader.exists(FactoryPath):
		dependency_pending.append("REAL_09_MAP_FACTORY")
		finish()
		return
	var factory: Script = load(FactoryPath)
	var selected := ""
	var mode := 1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--map="): selected = arg.trim_prefix("--map=")
		if arg == "--search-mode=first": mode = 0
	for id in factory.ids():
		if not selected.is_empty() and String(id) != selected: continue
		var prefix: String = PREFIX[id]
		begin(prefix + ".bake","UNIT")
		var baked: Dictionary = factory.bake(id)
		check(baked.get("ok",false) and baked.has_all(["level","issues","validation"]),"actual factory returns real Baker evidence")
		if not baked.get("ok",false):
			rows.append({"map":id,"bake":baked})
			continue
		var level: Dictionary = baked.level
		if prefix in ["loop","fork"]:
			check((level.schema_version == 3 and level.contract_version == "foundation.game_feel.v2" and level.rule_version == "foundation.rules.game_feel.v2") or (level.schema_version == 4 and level.contract_version == "foundation.spatial_puzzle.v1" and level.rule_version == "foundation.rules.spatial_puzzle.v1"),"existing cubic or explicit spatial profile")
		else:
			check(level.schema_version == 4 and level.contract_version == "foundation.spatial_puzzle.v1" and level.rule_version == "foundation.rules.spatial_puzzle.v1","exact gated opt-in versions")
		check(Data.validate_level_shape(level).is_empty(),"actual closed DATA shape")
		var repeated: Dictionary = factory.bake(id)
		check(repeated.get("ok",false) and repeated.level == level,"repeat Bake has identical canonical values")
		check(Codec.compute_content_hash(level).content_hash == level.content_hash,"all authored rules bind formal content hash")
		var initial := Records.initial_state(level)
		begin(prefix + (".full_graph" if mode == 1 else ".selected_trace"),"SOLVER")
		var explored := Explorer.explore(level,initial,Search.default_policy(mode),Search.default_budget())
		check(explored.status == 0 and explored.graph != null and explored.solution_trace != null and (mode == 0 or explored.graph.complete),"real original UNFILTERED search has a solved witness; completeness required only for FULL_GRAPH")
		if explored.graph == null or explored.solution_trace == null or (mode == 1 and not explored.graph.complete):
			rows.append({"map":id,"explorer":explored})
			continue
		var trace: Dictionary = explored.solution_trace
		check(Trace.validate(level,trace).ok and Trace.validate_semantics(level,trace).ok,"selected original hard witness revalidated")
		check(trace.total_actions > 0,"Goal requires a real route")
		if mode == 1: graph_invariants(level,explored.graph,prefix)
		begin(prefix + ".safe_edges","SAFETY")
		for step in trace.steps:
			var state: Dictionary = trace.initial_state if step.index == 1 else trace.steps[step.index-2].expected_state
			# MOVE can mean Roll or authored Fall. Consume the formal motion descriptor.
			var motion: Dictionary = Fall.motion(level,state,step.expected_state,step.action) if step.action.kind in [0,8] else {}
			var verdict: Dictionary
			var query := "Safety.validate_motion"
			if not motion.is_empty():
				query = "Safety.validate_perspective_motion"
				verdict = Safety.validate_perspective_motion(level,state,step.expected_state,motion.connection_id)
			elif step.action.kind == 9:
				query = "Safety.validate_state (observation-only Camera)"
				var before_safe := Safety.validate_state(level,state)
				check(before_safe.status == 0 and before_safe.issues.is_empty() and state.player == step.expected_state.player and state.world_orientations == step.expected_state.world_orientations,"Camera does not perform a physical motion")
				verdict = Safety.validate_state(level,step.expected_state)
			else:
				verdict = Safety.validate_motion(level,state,step.expected_state,step.action)
			check(verdict.status == 0 and verdict.issues.is_empty(),"actual Safety for selected trace edge " + str(step.index))
			rows.append({"map":id,"trace_step":step.index,"safety_query":query,"authorized_motion":motion,"actual_safety":verdict})
		var softlock: Variant = null
		if mode == 1:
			begin(prefix + ".softlock","SOLVER")
			var graph_before: Dictionary = explored.graph.duplicate(true)
			softlock = Softlock.analyze(level,explored.graph,{"max_nodes":10000,"max_edges":100000,"max_runtime_ms":0})
			check(softlock.status == 0 and softlock.softlock_count == 0,"same live original graph has zero undesigned softlocks")
			check(explored.graph == graph_before,"analysis does not mutate original graph")
		begin(prefix + ".budget","SOLVER")
		var tiny := Search.default_budget()
		tiny.max_states = 1
		var incomplete := Explorer.explore(level,initial,Search.default_policy(1),tiny)
		check(incomplete.status == 2 and incomplete.graph != null and not incomplete.graph.complete,"real max_states=1 remains BUDGET_EXCEEDED")
		native_trace(level,trace,prefix)
		begin(prefix + ".logical_replay","LOGICAL_REPLAY")
		var driver := Replayer.new()
		root.add_child(driver)
		var replay: Dictionary = await driver.replay(level,trace,{"mode":0})
		check(replay.status == 0 and replay.matched_steps == trace.total_actions and replay.actual_statekey == trace.goal_statekey,"actual LOGICAL_SESSION matches complete original witness")
		driver.free()
		rows.append({"map":id,"level_hash":level.content_hash,"rule_version":level.rule_version,
			"policy":explored.graph.policy_descriptor,"analysis_scope":"FULL_GRAPH" if mode == 1 else "SELECTED_WITNESS_ONLY","graph_complete":explored.graph.complete,"metrics":explored.metrics,
			"original_trace":trace,"softlock":softlock,"budget_result":{"status":incomplete.status,"metrics":incomplete.metrics},"logical":replay})
	finish()
