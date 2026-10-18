extends "res://tests/beta_sprint/spatial_quality/suite.gd"
## Public formal algorithms only; property inspection does not construct a graph.
const Maps = preload("res://experiments/spatial_puzzle_batch_01/maps/map_factory.gd")
const Records = preload("res://foundation/contracts/contract_records.gd")
const Explorer = preload("res://foundation/solver/state_explorer.gd")
const Search = preload("res://foundation/solver/search_records.gd")
const Softlock = preload("res://foundation/quality/softlock/softlock_analyzer.gd")
const Trace = preload("res://foundation/solver/solution_trace.gd")
const Facade = preload("res://foundation/game_feel/runtime_facade.gd")
const Key = preload("res://foundation/contracts/state_key.gd")
const Goal = preload("res://foundation/rules/goal_evaluator.gd")
const Geometry = preload("res://foundation/spatial/surface_geometry.gd")
const Orientation = preload("res://foundation/orientation/discrete_orientation.gd")
const Fall = preload("res://foundation/game_feel/fall_permission.gd")
var runtime: RefCounted
var identities: Array = []
var result_row: Dictionary = {}

func save(name: String, value: Variant) -> void:
	FileAccess.open(evidence.path_join(name), FileAccess.WRITE).store_string(JSON.stringify(value, "\t"))

func started(_result: Dictionary, token: int, generation: int, global: bool) -> void:
	identities.append(runtime.get_pending_identity(token, generation, global))

func act(level: Dictionary, action: Dictionary, expected: String = "") -> void:
	var before: Dictionary = runtime.get_state()
	var count: int = runtime.get_commit_count()
	var n: int = identities.size()
	var r: Dictionary = runtime.request_action(action)
	check(r.status in [0, 1], "native action no ERROR")
	if r.status == 0 and r.changed:
		check(identities.size() == n + 1 and runtime.get_state() == before, "pending preserves committed state")
		if identities.size() != n + 1: return
		var committed: Dictionary = runtime.finish_transition(identities[-1])
		check(not committed.get("ignored", true) and runtime.get_state() == r.next_state and runtime.get_commit_count() == count + 1 and runtime.is_idle(), "captured identity commits exactly once")
	else:
		check(runtime.get_state() == before and runtime.get_commit_count() == count and identities.size() == n, "reject or noop preserves state")
	if not expected.is_empty(): check(Key.build(level, runtime.get_state()).key == expected, "native full state equals formal trace")
	rows.append({"action": action, "result": r, "actual_key": Key.build(level, runtime.get_state()).key})

func inspect(level: Dictionary, graph: Dictionary) -> Dictionary:
	var c: Dictionary = {"states": graph.nodes.size(), "edges": graph.edges.size(), "frontier": 0, "goals": 0, "action_kinds": {}, "shift_edges": 0, "fall_edges": 0, "latch_edges": 0, "violations": [], "orientations": {}, "positions": {}, "minimum_goal_depth": null, "goal_island_entries": 0, "goal_island_nonfall_entries": 0}
	for key in graph.nodes:
		var node: Dictionary = graph.nodes[key]
		if not node.expanded: c.frontier += 1
		if node.is_goal:
			c.goals += 1
			if c.minimum_goal_depth == null or node.depth < c.minimum_goal_depth: c.minimum_goal_depth = node.depth
		c.orientations[str(node.state.player.orientation)] = true
		var position: String = str(node.state.player.location)
		if not c.positions.has(position): c.positions[position] = {}
		c.positions[position][str(node.state.player.orientation)] = true
		if not level.get("face_locks", []).is_empty() and node.state.player.location.layer == 1:
			check(node.state.mechanism_states.contact_lock == &"latched", "all reached Inner states require latch")
	for edge in graph.edges:
		var a: Dictionary = graph.nodes[edge.from_key].state
		var b: Dictionary = graph.nodes[edge.to_key].state
		var kind: int = edge.action.kind
		c.action_kinds[str(kind)] = c.action_kinds.get(str(kind), 0) + 1
		if a.player.location.layer != b.player.location.layer and kind != 1: c.violations.append([edge.edge_id, "non_shift_layer_change"])
		if kind == 1:
			c.shift_edges += 1
			var gates: Array = level.shift_gates.filter(func(g): return g.source_face_id == Geometry.face_id(a.player.location.cube_id,a.player.location.face) and g.target_face_id == Geometry.face_id(b.player.location.cube_id,b.player.location.face))
			var valid: bool = gates.size() == 1 and a.player.orientation == b.player.orientation and a.camera_quadrant == b.camera_quadrant
			if gates.size() == 1:
				for required in gates[0].required_mechanism_states: valid = valid and a.mechanism_states[required.mechanism_id] == required.state
				for flag in gates[0].required_flags: valid = valid and a.level_flags[flag]
			if not valid: c.violations.append([edge.edge_id, "shift_permission_or_pose"])
		if kind == 9 and (a.player != b.player or a.world_orientations != b.world_orientations or a.mechanism_states != b.mechanism_states or a.level_flags != b.level_flags): c.violations.append([edge.edge_id, "camera_changed_physical_state"])
		for lock in level.get("face_locks", []):
			var prior: Variant = a.mechanism_states[lock.mechanism_id]
			var after: Variant = b.mechanism_states[lock.mechanism_id]
			if prior == lock.latched_state and after != prior: c.violations.append([edge.edge_id, "latch_regressed"])
			if prior != after:
				c.latch_edges += 1
				var mechanism: Dictionary = level.mechanisms.filter(func(m): return m.mechanism_id == lock.mechanism_id)[0]
				var snapshot: Dictionary = Geometry.snapshot(level,b)
				var anchors: Array = snapshot.value.anchors.filter(func(anchor): return anchor.face_id == mechanism.face_id) if snapshot.ok else []
				var valid: bool = kind == 0 and after == lock.latched_state and Geometry.face_id(b.player.location.cube_id,b.player.location.face) == mechanism.face_id and anchors.size() == 1
				if valid: valid = Orientation.apply(b.player.orientation,Geometry.face_frame(lock.required_local_face).normal) == -anchors[0].frame.normal
				if not valid: c.violations.append([edge.edge_id, "wrong_contact_face"])
		var motion: Dictionary = Fall.motion(level,a,b,edge.action) if kind in [0,8] else {}
		if not motion.is_empty():
			c.fall_edges += 1
			var connection: Dictionary = level.perspective_falls.filter(func(p): return p.connection_id == motion.connection_id)[0]
			if a.player.orientation != b.player.orientation or a.player.location.layer != b.player.location.layer or Geometry.face_id(b.player.location.cube_id,b.player.location.face) != connection.target_face_id: c.violations.append([edge.edge_id, "fall_pose_or_target"])
		if not level.get("perspective_falls", []).is_empty() and a.player.location.cube_id not in [&"target_a", &"goal"] and b.player.location.cube_id in [&"target_a", &"goal"]:
			c.goal_island_entries += 1
			if motion.is_empty(): c.goal_island_nonfall_entries += 1
	return c

func run() -> void:
	var id: StringName = &""
	var limit: int = 120000
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--map="): id = StringName(arg.trim_prefix("--map="))
		if arg.begins_with("--budget-ms="): limit = int(arg.trim_prefix("--budget-ms="))
	begin(String(id), "FORMAL_GRAPH")
	check(DisplayServer.get_name() == "headless", "headless only")
	var baked: Dictionary = Maps.bake(id)
	check(baked.ok, "actual saved map bake")
	if not baked.ok: rows.append(baked); finish(); return
	var level: Dictionary = baked.level
	var budget: Dictionary = {"max_states":2500,"max_edges":15000,"max_depth":-1,"max_runtime_ms":limit,"max_action_evaluations":30000}
	result_row = {"map":id,"level_hash":level.content_hash,"budget":budget,"domain":"GOAL_TERMINAL_STABLE_PUBLIC_ACTIONS","reset_is_graph_edge":false}
	save("map_identity.json", {"level_hash":level.content_hash,"bake_provenance":baked.bake_provenance})
	var explored: Dictionary = Explorer.explore(level, Records.initial_state(level), Search.default_policy(1), budget)
	save("explorer.json", explored)
	check(explored.status != 3, "Explorer no ERROR")
	result_row.merge({"solver_status":explored.status,"metrics":explored.metrics,"budget_reason":explored.budget_reason})
	if explored.graph == null: save("summary.json", result_row); dependency_pending.append("NO_GRAPH"); finish(); return
	var graph: Dictionary = explored.graph
	var original: Dictionary = graph.duplicate(true)
	var soft: Dictionary = Softlock.analyze(level,graph,{"max_nodes":2500,"max_edges":15000,"max_runtime_ms":15000})
	save("softlock.json",soft)
	check(original == graph, "Analyzer receives unchanged same live graph")
	var census: Dictionary = inspect(level,graph)
	check(census.violations.is_empty(), "reached edge permissions and orientation invariants")
	check(census.goal_island_nonfall_entries == 0, "no reached nonfall shortcut into authored Goal island")
	result_row.merge({"graph_complete":graph.complete,"census":census,"softlock_status":soft.status,"softlock_count":soft.softlock_count,"goal_reachable_count":soft.goal_reachable_states.size(),"unknown_states":soft.unknown_states.size(),"reset_recoverable_count":soft.reset_recoverable_count})
	if not graph.complete or soft.status != 0: dependency_pending.append("BOUNDED_GRAPH_OR_ANALYZER_INCOMPLETE")
	else: check(soft.softlock_count == 0, "complete current Goal-terminal graph has no Goal softlock")
	var overlaps: Array = []
	for i in level.get("perspective_falls", []).size():
		for j in range(i+1,level.get("perspective_falls", []).size()):
			var a: Dictionary = level.perspective_falls[i]
			var b: Dictionary = level.perspective_falls[j]
			if a.source_face_id != b.source_face_id or a.source_edge != b.source_edge: continue
			for camera in a.allowed_camera_quadrants:
				for world in a.allowed_world_orientations:
					if camera in b.allowed_camera_quadrants and world in b.allowed_world_orientations: overlaps.append([a.connection_id,b.connection_id,camera,world])
	check(overlaps.is_empty(), "authored Fork permission cells do not overlap")
	result_row.fork_overlap = overlaps
	if explored.solution_trace != null:
		begin(String(id)+"_native_shortest_reset", "REAL_RUNTIME")
		var trace: Dictionary = explored.solution_trace
		check(Trace.validate(level,trace).ok and Trace.validate_semantics(level,trace).ok, "formal trace structure and semantics")
		runtime = Facade.new()
		runtime.transition_started.connect(started)
		check(runtime.load_level(level).ok, "native canonical spawn load")
		for step in trace.steps: act(level,step.action,step.resulting_statekey)
		check(Goal.is_goal(level,runtime.get_state()).is_goal, "native shortest trace reaches Goal")
		runtime.reset()
		check(Key.build(level,runtime.get_state()).key == graph.initial_key and runtime.get_commit_count() == 0 and runtime.is_idle(), "native Goal Reset restores exact spawn and idle count zero")
		act(level,{"kind":1})
		result_row.native_shortest_steps = trace.total_actions
		result_row.native_goal_reset = true
		runtime.interrupt("UNLOAD")
	else: result_row.native_goal_reset = "NOT_RUN_NO_TRACE"
	save("summary.json", result_row)
	finish()
