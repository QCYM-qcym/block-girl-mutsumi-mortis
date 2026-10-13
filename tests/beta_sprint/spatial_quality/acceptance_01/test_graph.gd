extends "res://tests/beta_sprint/spatial_quality/suite.gd"
const Maps = preload("res://experiments/spatial_puzzle_batch_01/maps/map_factory.gd")
const Records = preload("res://foundation/contracts/contract_records.gd")
const Explorer = preload("res://foundation/solver/state_explorer.gd")
const Search = preload("res://foundation/solver/search_records.gd")
const Softlock = preload("res://foundation/quality/softlock/softlock_analyzer.gd")
const Trace = preload("res://foundation/solver/solution_trace.gd")
const Replayer = preload("res://foundation/parity/trace_replayer.gd")
const Facade = preload("res://foundation/game_feel/runtime_facade.gd")
const Key = preload("res://foundation/contracts/state_key.gd")
const Goal = preload("res://foundation/rules/goal_evaluator.gd")
const Safety = preload("res://foundation/validation/safety_queries.gd")
const Fall = preload("res://foundation/game_feel/fall_permission.gd")
const Kernel = preload("res://foundation/rules/puzzle_rule_kernel.gd")
const Rules = preload("res://foundation/rules/rule_records.gd")
const Classifier = preload("res://foundation/quality/intent/mechanic_classifier.gd")
const Codec = preload("res://foundation/level/level_codec.gd")
const Census = preload("res://tests/beta_sprint/spatial_quality/acceptance_01/graph_census.gd")
const ReportView = preload("res://tests/beta_sprint/spatial_quality/acceptance_01/report_projection.gd")
var level: Dictionary = {}
var graph: Dictionary = {}
var runtime: RefCounted
var native: Array = []

func write_json(name: String, value: Variant) -> void:
	FileAccess.open(evidence.path_join(name),FileAccess.WRITE).store_string(JSON.stringify(value,"\t"))

func phase(name: String) -> void:
	write_json("stage.json",{"phase":name,"pid":OS.get_process_id(),"tick_ms":Time.get_ticks_msec(),"display":DisplayServer.get_name()})
	print("ACCEPTANCE_PHASE ",name)

func started(_result: Dictionary, token: int, generation: int, global: bool) -> void:
	native.append(runtime.get_pending_identity(token,generation,global))

func fresh() -> bool:
	if runtime != null: runtime.interrupt("UNLOAD")
	runtime = Facade.new()
	native.clear()
	runtime.transition_started.connect(started)
	var loaded: Dictionary = runtime.load_level(level)
	check(loaded.ok,"actual public Facade loads same canonical map")
	return loaded.ok

func action(actual: Dictionary, expected_key: String = "") -> Dictionary:
	var before: Dictionary = runtime.get_state()
	var commits: int = runtime.get_commit_count()
	var count := native.size()
	var result: Dictionary = runtime.request_action(actual)
	if result.status == 0 and result.changed:
		check(native.size() == count+1 and runtime.get_state() == before,"native changed proposal commits only after explicit LOGICAL completion")
		if native.size() != count+1: return result
		var committed: Dictionary = runtime.finish_transition(native[-1])
		check(not committed.get("ignored",true) and runtime.get_commit_count() == commits+1,"exactly one official LOGICAL phase commit")
		check(runtime.get_state() == result.next_state and runtime.is_idle(),"actual full committed state equals formal proposal")
	else:
		check(runtime.get_state() == before and runtime.get_commit_count() == commits and native.size() == count,"rejected/noop proposal preserves state/count/identity")
	if not expected_key.is_empty(): check(Key.build(level,runtime.get_state()).key == expected_key,"actual Runtime StateKey equals live graph witness")
	rows.append({"scope":"RUNTIME_LOGICAL_PHASE_ONLY","action":actual,"result":result,"statekey":Key.build(level,runtime.get_state()).key})
	return result

func prefix(target: String) -> Array:
	# Read the canonical first-predecessor chain already supplied by Explorer.
	# No forward search, new predecessor table or graph construction.
	var path: Array = []
	var cursor := target
	while cursor != graph.initial_key:
		var edge: Dictionary = graph.edges[graph.nodes[cursor].predecessor_edge]
		path.append(edge.edge_id)
		cursor = edge.from_key
	path.reverse()
	return path

func follow_prefix(target: String) -> bool:
	if not fresh(): return false
	var ids := prefix(target)
	for edge_id in ids:
		var edge: Dictionary = graph.edges[edge_id]
		var actual := action(edge.action,edge.to_key)
		check(actual.status == 0 and actual.changed,"real Runtime accepts original graph-prefix action")
		if actual.status != 0 or not actual.changed: return false
	rows.append({"scope":"GRAPH_PATH_NOT_SOLUTION_TRACE","target_key":target,"edge_ids":ids,"shortest_prefix_depth":graph.nodes[target].depth,"actual_statekey":Key.build(level,runtime.get_state()).key})
	return Key.build(level,runtime.get_state()).key == target

func safety_samples(trace: Dictionary, label: String) -> void:
	for step in trace.steps:
		var before: Dictionary = trace.initial_state if step.index == 1 else trace.steps[step.index-2].expected_state
		var motion: Dictionary = Fall.motion(level,before,step.expected_state,step.action) if step.action.kind in [0,8] else {}
		var query := "Safety.validate_motion"
		var verdict: Dictionary
		if not motion.is_empty():
			query = "Safety.validate_perspective_motion"
			verdict = Safety.validate_perspective_motion(level,before,step.expected_state,motion.connection_id)
		elif step.action.kind == 9:
			query = "Safety.validate_state (Camera observation)"
			verdict = Safety.validate_state(level,step.expected_state)
			check(before.player == step.expected_state.player and before.world_orientations == step.expected_state.world_orientations,"Camera sample changes no physical state")
		else: verdict = Safety.validate_motion(level,before,step.expected_state,step.action)
		check(verdict.status == 0 and verdict.issues.is_empty(),"independent sampled Safety "+label+" step"+str(step.index))
		rows.append({"sample":label,"trace_step":step.index,"query":query,"verdict":verdict})

func run() -> void:
	phase("SAVED_BAKE")
	begin("current_saved_map","UNIT")
	var baked := Maps.bake(&"rubik_spatial_puzzle_01")
	check(baked.ok,"actual current saved author resources bake")
	if not baked.ok: rows.append(baked); finish(); return
	level = baked.level
	var encoded := Codec.encode(level)
	check(encoded.ok and level.schema_version == 4,"formal canonical content/version")
	write_json("map_identity.json",{"level_hash":level.content_hash,"canonical_text":encoded.text,"source_map":baked.get("source_map"),"bake_provenance":baked.get("bake_provenance")})
	var initial := Records.initial_state(level)
	check(initial.player.location.layer == 0 and initial.player.location.cube_id not in [&"target_a",&"goal"] and initial.mechanism_states.contact_lock == &"idle","independent initial side of required World/Lock/Fall cuts")
	begin("original_full_graph","SOLVER")
	var budget := {"max_states":5000,"max_edges":30000,"max_depth":-1,"max_runtime_ms":1200000,"max_action_evaluations":60000}
	var policy := Search.default_policy(1)
	write_json("budget.json",{"explorer":budget,"softlock":{"max_nodes":5000,"max_edges":30000,"max_runtime_ms":180000},"outer_process_timeout_seconds":1800,"domain":"GOAL_TERMINAL","reset_in_graph":false})
	phase("EXPLORER_FULL_GRAPH")
	var explored := Explorer.explore(level,initial,policy,budget)
	write_json("explorer.json",explored)
	check(explored.status != 3,"formal Explorer returns no ERROR")
	if explored.graph == null: rows.append(explored); finish(); return
	graph = explored.graph
	phase("SAME_LIVE_GRAPH_SOFTLOCK")
	var before: Dictionary = graph.duplicate(true)
	var analyzed := Softlock.analyze(level,graph,{"max_nodes":5000,"max_edges":30000,"max_runtime_ms":180000})
	check(graph == before,"same returned graph is unchanged by formal Analyzer")
	var summary := ReportView.summarize(graph,analyzed)
	write_json("graph_summary.json",{"solver_status":explored.status,"budget_reason":explored.budget_reason,"solver_metrics":explored.metrics,"projection":summary,"softlock":analyzed,"same_live_graph_pid":OS.get_process_id()})
	if not graph.complete or analyzed.status != 0:
		check(summary.status == "INCOMPLETE" and summary.graph_softlock_count == null,"unknown graph/analyzer conclusions preserved")
		dependency_pending.append("FULL_GRAPH_OR_SOFTLOCK_BUDGET_INCOMPLETE")
		rows.append({"summary":summary,"metrics":explored.metrics,"analyzer":analyzed})
		finish(); return
	check(explored.status == 0 and graph.stop_reason == 0 and summary.frontier_count == 0,"formal UNFILTERED Goal-terminal closure exhausted and solved")
	check(explored.metrics.explored_states == graph.nodes.size() and explored.metrics.generated_edges == graph.edges.size(),"actual node/edge counts reconcile with formal metrics")
	check(analyzed.metrics.nodes_checked == graph.nodes.size() and analyzed.metrics.edges_checked == graph.edges.size(),"formal Graph validation and Analyzer cover this exact live graph")
	phase("ALL_NODE_EDGE_PROPERTY_CENSUS")
	begin("complete_graph_permissions","SOLVER")
	var census := Census.inspect(level,graph)
	write_json("census.json",census)
	check(census.states_examined == graph.nodes.size() and census.edges_examined == graph.edges.size(),"all actual graph nodes/edges inspected")
	check(census.unlatched_inner_keys.is_empty() and census.unlatched_goal_keys.is_empty(),"no Inner/Goal without authored latch")
	check(census.wrong_lock_edges.is_empty(),"all real latch edges satisfy physical local-face contact")
	check(census.violations.is_empty(),"all graph Shift/Fall/Camera/cut/monotonic-lock properties")
	check(not census.shift_edges.is_empty() and not census.latch_edges.is_empty() and not census.fall_edges.is_empty() and not census.goal_island_cut_edges.is_empty(),"required mechanics are exercised and island cut is nonempty")
	check(not census.latched_reentry_edges.is_empty(),"repeated latched contact states exist without toggling latch")
	# Diagnostic overlap census consumes authored directed connection records.
	var overlap: Array = []
	for i in level.perspective_falls.size():
		for j in range(i+1,level.perspective_falls.size()):
			var a: Dictionary = level.perspective_falls[i]
			var b: Dictionary = level.perspective_falls[j]
			if a.source_face_id != b.source_face_id or a.source_edge != b.source_edge: continue
			for camera in a.allowed_camera_quadrants:
				for world in a.allowed_world_orientations:
					if camera in b.allowed_camera_quadrants and world in b.allowed_world_orientations: overlap.append([a.connection_id,b.connection_id,camera,world])
	check(overlap.is_empty(),"no same source/edge/Camera/World ambiguous Fork permission")
	rows.append({"census":census,"fork_permission_overlap":overlap,"safety_unproven_rejections":explored.metrics.safety_unproven_rejections})
	var anomalies: Array = []
	for violation in census.violations:
		var edge: Dictionary = graph.edges[violation.edge]
		anomalies.append({"property":violation.reason,"edge_id":edge.edge_id,"shortest_prefix_edge_ids":prefix(edge.from_key),"final_action":edge.action,"expected_before":graph.nodes[edge.from_key].state,"expected_after":graph.nodes[edge.to_key].state,"owner":"01_RUNTIME_OR_09_MAP_PENDING_COORDINATOR_TRIAGE"})
	for edge_id in census.wrong_lock_edges:
		var edge: Dictionary = graph.edges[edge_id]
		anomalies.append({"property":"wrong_local_face_latch","edge_id":edge_id,"shortest_prefix_edge_ids":prefix(edge.from_key),"final_action":edge.action,"owner":"01_RUNTIME"})
	write_json("anomalies.json",anomalies)
	begin("original_shortest_witness","SOLVER")
	var trace: Dictionary = explored.solution_trace
	check(Trace.validate(level,trace).ok and Trace.validate_semantics(level,trace).ok,"original complete-graph selected hard witness revalidated")
	check(trace.shortest and trace.total_actions == census.min_goal_depth,"original witness has minimum Goal depth across complete graph")
	FileAccess.open(evidence.path_join("selected_trace.gdvar"),FileAccess.WRITE).store_string(var_to_str(trace)+"\n")
	begin("selected_trace_safety","SAFETY")
	safety_samples(trace,"original_shortest")
	begin("logical_session_replay","LOGICAL_REPLAY")
	phase("REAL_LOGICAL_REPLAY")
	var driver := Replayer.new()
	root.add_child(driver)
	var replay: Dictionary = await driver.replay(level,trace,{"mode":0})
	check(replay.status == 0 and replay.matched_steps == trace.total_actions and replay.actual_statekey == trace.goal_statekey,"actual production LOGICAL_SESSION replays complete original shortest trace")
	rows.append({"original_shortest_trace":trace,"logical_replay":replay})
	driver.free()
	begin("runtime_shortest_and_reset","REAL_RUNTIME")
	check(follow_prefix(trace.goal_statekey),"actual Runtime follows shortest Goal predecessor path")
	check(Goal.is_goal(level,runtime.get_state()).is_goal,"actual native committed Goal")
	# Runtime may accept post-Goal input even though Explorer treats Goal terminal.
	var post_goal: Dictionary = {}
	for axis in 4:
		var result := action({"kind":0,"face_axis":axis})
		if result.status == 0 and result.changed:
			post_goal = {"action":result.action,"statekey":Key.build(level,runtime.get_state()).key,"is_goal":Goal.is_goal(level,runtime.get_state()).is_goal}
			break
	rows.append({"post_goal_runtime_observation":post_goal,"domain":"OUTSIDE_ENUMERATED_GOAL_TERMINAL_GRAPH","expanded_domain_coverage":"UNKNOWN"})
	runtime.reset()
	check(Key.build(level,runtime.get_state()).key == graph.initial_key and runtime.is_idle() and runtime.get_commit_count() == 0,"actual Runtime Reset restores exact canonical spawn key/count")
	begin("runtime_permission_negatives","REAL_RUNTIME")
	var locked := action({"kind":1})
	check(locked.status == 1 and locked.rejection_code == 2011,"actual initial Shift is locked, not a teleport")
	var wrong := ""
	var keys: Array = graph.nodes.keys()
	keys.sort()
	for key in keys:
		var state: Dictionary = graph.nodes[key].state
		if state.player.location.cube_id == &"corner" and state.mechanism_states.contact_lock == &"idle" and (wrong.is_empty() or graph.nodes[key].depth < graph.nodes[wrong].depth): wrong = key
	check(not wrong.is_empty(),"actual wrong-face sensor state is reachable")
	if not wrong.is_empty() and follow_prefix(wrong):
		check(runtime.get_state().mechanism_states.contact_lock == &"idle","wrong contact MOVE commits position without granting latch")
		var off_point := action({"kind":1})
		check(off_point.status == 1 and off_point.rejection_code == 2010,"actual off-point Shift rejected without state change")
	if not census.latched_reentry_edges.is_empty():
		var edge: Dictionary = graph.edges[census.latched_reentry_edges[0]]
		if follow_prefix(edge.from_key):
			var repeated := action(edge.action,edge.to_key)
			var tags := Classifier.classify_transition(level,repeated)
			check(tags.ok and not 7 in tags.tags and runtime.get_state().mechanism_states.contact_lock == &"latched","actual repeated contact emits no second mechanism trigger")
	begin("detour_recovery_runtime","REAL_RUNTIME")
	phase("DETOUR_RECOVERY")
	var detours: Array = census.detour_keys.duplicate()
	detours.sort()
	var target := ""
	for key in detours:
		if graph.nodes[key].state.player.location.cube_id == &"target_b" and (target.is_empty() or graph.nodes[key].depth < graph.nodes[target].depth): target = key
	check(not target.is_empty() and target in analyzed.goal_reachable_states,"actual non-goal B branch has formal graph Goal reachability")
	if not target.is_empty():
		var recovery_budget := {"max_states":500,"max_edges":5000,"max_depth":-1,"max_runtime_ms":120000,"max_action_evaluations":10000}
		var recovery := Explorer.explore(level,graph.nodes[target].state,Search.default_policy(0),recovery_budget)
		check(recovery.status == 0 and recovery.solution_trace != null,"second real local search finds recovery from exact live B state")
		if recovery.solution_trace != null:
			var witness: Dictionary = recovery.solution_trace
			check(Trace.validate(level,witness).ok and Trace.validate_semantics(level,witness).ok,"local recovery hard witness revalidated; not substituted for original")
			if follow_prefix(target):
				for step in witness.steps:
					var actual := action(step.action,step.resulting_statekey)
					check(actual.status == 0 and actual.changed,"real recovery action accepted")
				check(Goal.is_goal(level,runtime.get_state()).is_goal,"actual B detour reaches Goal without Reset")
			rows.append({"detour_key":target,"recovery_budget":recovery_budget,"recovery_metrics":recovery.metrics,"recovery_trace":witness,"scope":"LOCAL_FIRST_SHORTEST_FROM_GRAPH_NODE_AND_NATIVE_RUNTIME; no graph closure or Graphical claim"})
			begin("detour_sampled_safety","SAFETY")
			safety_samples(witness,"B_recovery")
	begin("graph_softlock_reset_classification","REAL_RUNTIME")
	phase("RESET_CLASSIFICATION")
	var classes := {"goal_terminal":census.goal_keys.size(),"self_recoverable_non_goal":analyzed.goal_reachable_states.size()-census.goal_keys.size(),"graph_softlock_count":analyzed.softlock_count,"reset_only_verified":0,"irrecoverable_verified":0,"reset_unknown":0,"non_goal_sinks":census.non_goal_sinks.size(),"detour_states":detours.size(),"runtime_reset_proofs":[]}
	for index in analyzed.softlock_states.size():
		var key: String = analyzed.softlock_states[index]
		if index >= 64 or not follow_prefix(key): classes.reset_unknown += 1; continue
		runtime.reset()
		var actual_reset: bool = Key.build(level,runtime.get_state()).key == graph.initial_key and runtime.is_idle() and runtime.get_commit_count() == 0
		var classified := "RESET_ONLY_GRAPH_SOFTLOCK" if actual_reset and graph.initial_key in analyzed.goal_reachable_states else "IRRECOVERABLE"
		if classified == "RESET_ONLY_GRAPH_SOFTLOCK": classes.reset_only_verified += 1
		else: classes.irrecoverable_verified += 1
		classes.runtime_reset_proofs.append({"target_key":key,"edge_ids":prefix(key),"actual_reset_key":Key.build(level,runtime.get_state()).key,"reset_success":actual_reset,"classification":classified})
	# This assertion records the actual classification census even when zero;
	# it never subtracts Reset-only states from the formal graph softlock count.
	check(classes.reset_only_verified+classes.irrecoverable_verified+classes.reset_unknown == analyzed.softlock_count,"Reset layer partitions graph-softlock states without hiding them")
	check(analyzed.softlock_count == 0,"current combined graph has no reachable undesigned graph softlock")
	write_json("recovery_classification.json",classes)
	if runtime != null: runtime.interrupt("UNLOAD")
	rows.append({"classification":classes,"graph_projection":summary,"goal_terminal_scope":true,"absolute_state_coverage":"UNKNOWN","graphical":"NOT_RUN_GUI_RESERVED_08_USER"})
	phase("FINISHED")
	finish()
