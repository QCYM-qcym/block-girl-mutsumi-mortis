extends RefCounted
## Property census of the supplied live graph; no traversal/search or rule implementation.
const Geometry = preload("res://foundation/spatial/surface_geometry.gd")
const Orientation = preload("res://foundation/orientation/discrete_orientation.gd")
const Fall = preload("res://foundation/game_feel/fall_permission.gd")

static func inspect(level: Dictionary, graph: Dictionary) -> Dictionary:
	var report := {"states_examined":0,"edges_examined":0,"non_goal_sinks":[],"goal_keys":[],
		"unlatched_inner_keys":[],"unlatched_goal_keys":[],"wrong_lock_edges":[],
		"shift_edges":[],"latch_edges":[],"latched_reentry_edges":[],"fall_edges":[],
		"goal_island_cut_edges":[],"violations":[],"detour_keys":[],"action_kinds":{},
		"dimension_values":{},"min_goal_depth":null,"max_depth":0}
	var dimensions := {"Position":{},"Orientation":{},"World":{},"Camera":{},"Mechanism":{}}
	for key in graph.nodes:
		var node: Dictionary = graph.nodes[key]
		var state: Dictionary = node.state
		report.states_examined += 1
		report.max_depth = maxi(report.max_depth,node.depth)
		dimensions.Position[JSON.stringify([state.player.location.cube_id,state.player.location.face])] = true
		dimensions.Orientation[str(state.player.orientation)] = true
		dimensions.World[JSON.stringify([state.player.location.layer,state.world_orientations])] = true
		dimensions.Camera[str(state.camera_quadrant)] = true
		dimensions.Mechanism[JSON.stringify([state.mechanism_states,state.level_flags])] = true
		if not node.is_goal and graph.forward[key].is_empty(): report.non_goal_sinks.append(key)
		if state.player.location.layer == 1 and state.mechanism_states.contact_lock != &"latched": report.unlatched_inner_keys.append(key)
		if node.is_goal:
			report.goal_keys.append(key)
			if report.min_goal_depth == null or node.depth < report.min_goal_depth: report.min_goal_depth = node.depth
			if state.player.location.layer != 1 or state.mechanism_states.contact_lock != &"latched": report.unlatched_goal_keys.append(key)
		if state.player.location.cube_id in [&"target_b",&"return"]: report.detour_keys.append(key)
	for edge in graph.edges:
		report.edges_examined += 1
		var before: Dictionary = graph.nodes[edge.from_key].state
		var after: Dictionary = graph.nodes[edge.to_key].state
		var kind: int = edge.action.kind
		report.action_kinds[str(kind)] = report.action_kinds.get(str(kind),0) + 1
		if before.player.location.layer != after.player.location.layer and kind != 1: report.violations.append({"reason":"non_Shift_world_change","edge":edge.edge_id})
		if kind == 1:
			report.shift_edges.append(edge.edge_id)
			var source := Geometry.face_id(before.player.location.cube_id,before.player.location.face)
			var target := Geometry.face_id(after.player.location.cube_id,after.player.location.face)
			var gates: Array = level.shift_gates.filter(func(g):return g.source_face_id == source and g.target_face_id == target)
			var valid: bool = gates.size() == 1 and before.player.orientation == after.player.orientation and before.camera_quadrant == after.camera_quadrant
			if gates.size() == 1:
				for required in gates[0].required_mechanism_states: valid = valid and before.mechanism_states[required.mechanism_id] == required.state
				for flag in gates[0].required_flags: valid = valid and before.level_flags[flag]
			if not valid: report.violations.append({"reason":"Shift_permission_or_pose","edge":edge.edge_id})
		if kind == 9 and (before.player != after.player or before.world_orientations != after.world_orientations or before.mechanism_states != after.mechanism_states): report.violations.append({"reason":"Camera_changed_physical_state","edge":edge.edge_id})
		if before.mechanism_states.contact_lock == &"latched" and after.mechanism_states.contact_lock != &"latched": report.violations.append({"reason":"lock_unlatched_without_Reset","edge":edge.edge_id})
		if before.mechanism_states.contact_lock != after.mechanism_states.contact_lock:
			report.latch_edges.append(edge.edge_id)
			var lock: Dictionary = level.face_locks[0]
			var mechanism: Dictionary = level.mechanisms.filter(func(m):return m.mechanism_id == lock.mechanism_id)[0]
			var snapshot := Geometry.snapshot(level,after)
			var anchors: Array = snapshot.value.anchors.filter(func(a):return a.face_id == mechanism.face_id) if snapshot.ok else []
			var valid: bool = kind == 0 and after.mechanism_states.contact_lock == lock.latched_state and Geometry.face_id(after.player.location.cube_id,after.player.location.face) == mechanism.face_id and anchors.size() == 1
			if valid: valid = Orientation.apply(after.player.orientation,Geometry.face_frame(lock.required_local_face).normal) == -anchors[0].frame.normal
			if not valid: report.wrong_lock_edges.append(edge.edge_id)
		elif before.mechanism_states.contact_lock == &"latched" and kind == 0 and after.player.location.cube_id == &"corner" and before.player.location.cube_id != &"corner":
			report.latched_reentry_edges.append(edge.edge_id)
		var motion: Dictionary = Fall.motion(level,before,after,edge.action) if kind in [0,8] else {}
		if not motion.is_empty():
			report.fall_edges.append({"edge_id":edge.edge_id,"connection_id":motion.connection_id})
			var connection: Dictionary = level.perspective_falls.filter(func(c):return c.connection_id == motion.connection_id)[0]
			if before.player.orientation != after.player.orientation or before.player.location.layer != after.player.location.layer or Geometry.face_id(before.player.location.cube_id,before.player.location.face) != connection.source_face_id or Geometry.face_id(after.player.location.cube_id,after.player.location.face) != connection.target_face_id: report.violations.append({"reason":"Fall_direction_or_pose","edge":edge.edge_id})
		# A finite edge-cut proof, not another path search: any initial→Goal route
		# must enter this independently declared goal island at least once.
		if before.player.location.cube_id not in [&"target_a",&"goal"] and after.player.location.cube_id in [&"target_a",&"goal"]:
			report.goal_island_cut_edges.append(edge.edge_id)
			if motion.is_empty(): report.violations.append({"reason":"Goal_island_Fall_bypass","edge":edge.edge_id})
	for dimension in dimensions:
		report.dimension_values[dimension] = dimensions[dimension].keys()
		report.dimension_values[dimension].sort()
	return report
