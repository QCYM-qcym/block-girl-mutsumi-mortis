extends RefCounted
## Authored directed permission only. Geometry/Orientation/Safety remain formal owners.
const Types = preload("res://foundation/contracts/foundation_types.gd")
const Rules = preload("res://foundation/rules/rule_records.gd")
const Geometry = preload("res://foundation/spatial/surface_geometry.gd")
const Derived = preload("res://foundation/rules/derived_state_resolver.gd")
const Connectivity = preload("res://foundation/rules/connectivity_resolver.gd")
const Effects = preload("res://foundation/rules/mechanism_effects.gd")
const SpatialRules = preload("res://foundation/rules/spatial_puzzle_rules.gd")
const Key = preload("res://foundation/contracts/state_key.gd")
const Safety = preload("res://foundation/validation/safety_queries.gd")
const Codec = preload("res://foundation/level/level_codec.gd")
const View = preload("res://foundation/game_feel/view_contract.gd")
const Feel = preload("res://foundation/game_feel/schema.gd")
const Trajectory = preload("res://foundation/game_feel/trajectory_profile.gd")
const Code = Types.ValidationCode
const FALL_NOT_AVAILABLE = 2100
const CAMERA_NOT_ALLOWED = 2101
const WORLD_NOT_ALLOWED = 2102
const FALL_SAFETY_REJECTED = 2103

static func connections(level: Dictionary, state: Dictionary, axis: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var source := Geometry.face_id(state.player.location.cube_id,state.player.location.face)
	for c in level.perspective_falls:
		if c.source_face_id == source and c.source_edge == axis: result.append(c)
	result.sort_custom(func(a,b):return String(a.connection_id) < String(b.connection_id))
	return result

static func evaluate(level: Dictionary, state: Dictionary, action: Dictionary) -> Dictionary:
	if action.kind == 9:
		var next := state.duplicate(true)
		next.camera_quadrant = action.camera_quadrant
		return Rules.applied(state,next,action)
	var candidates: Array[Dictionary] = []
	if action.kind == 0: candidates = connections(level,state,action.face_axis)
	else:
		for c in level.perspective_falls:
			if c.connection_id == action.connection_id: candidates.append(c)
	if candidates.is_empty(): return _reject(state,action,FALL_NOT_AVAILABLE,"FALL_NOT_AVAILABLE","No authored connection for this action.")
	var matching: Array[Dictionary] = []
	for c in candidates:
		if state.camera_quadrant in c.allowed_camera_quadrants: matching.append(c)
	if matching.is_empty(): return _reject(state,action,CAMERA_NOT_ALLOWED,"CAMERA_NOT_ALLOWED","Author did not permit this quadrant.")
	var permitted: Array[Dictionary] = []
	for candidate in matching:
		if state.world_orientations[state.player.location.layer] in candidate.allowed_world_orientations: permitted.append(candidate)
	if permitted.is_empty(): return _reject(state,action,WORLD_NOT_ALLOWED,"WORLD_NOT_ALLOWED","No authored connection permits the committed World orientation.")
	var c: Dictionary = permitted[0]
	var source := Geometry.face_id(state.player.location.cube_id,state.player.location.face)
	if c.source_face_id != source: return _reject(state,action,FALL_NOT_AVAILABLE,"FALL_NOT_AVAILABLE","Connection is directed and player is not at its source.")
	var road := Connectivity.query_move(level,state,c.source_edge)
	if not road.ok: return Rules.error(state,action,road.issues)
	if road.target_location != null: return _reject(state,action,FALL_NOT_AVAILABLE,"FALL_NOT_AVAILABLE","Ordinary Roll has priority over a Fall connection.")
	var target: Dictionary = _find(level.faces,"face_id",c.target_face_id)
	var cube: Dictionary = _find(level.cubes,"cube_id",target.cube_id)
	var layer: int = state.player.location.layer
	if cube.layer != layer or not state.world_orientations[layer] in c.allowed_world_orientations:
		return _reject(state,action,WORLD_NOT_ALLOWED,"WORLD_NOT_ALLOWED","Connection cannot change World or bypass its authored permission.")
	if not target.walkable or target.face != Types.FaceDirection.TOP or state.player.location.face != Types.FaceDirection.TOP:
		return _reject(state,action,FALL_NOT_AVAILABLE,"INVALID_FACE","Initial Fall profile requires legal TOP support faces.")
	if not Effects.enter_effects(level,c.source_face_id,c.target_face_id).is_empty():
		return _reject(state,action,FALL_NOT_AVAILABLE,"FALL_NOT_AVAILABLE","Translation-only profile cannot silently omit or invent an ENTER effect.")
	for flag in c.required_flags:
		if not state.level_flags[flag]: return _reject(state,action,Code.UNAUTHORIZED_MECHANISM,"MECHANISM_LOCKED","Connection is locked by its authored flag.")
	if (Feel.curved(level) and not Trajectory.screen_descends(c.trajectory,state.camera_quadrant)) or (not Feel.curved(level) and not View.descending(c.path_points2,state.camera_quadrant)):
		return _reject(state,action,CAMERA_NOT_ALLOWED,"CAMERA_NOT_ALLOWED","Path must descend continuously in the fixed orthographic screen column.")
	var next := state.duplicate(true)
	next.player.location = {"layer":layer,"cube_id":target.cube_id,"face":target.face}
	var safe := Safety.validate_perspective_motion(level,state,next,c.connection_id)
	if safe.status != 0 or not safe.issues.is_empty():
		if safe.issues.any(func(i):return i.code == Code.ARITHMETIC_OVERFLOW): return Rules.error(state,action,safe.issues)
		return Rules.rejected(state,action,FALL_SAFETY_REJECTED,safe.issues)
	return Rules.applied(state,next,action)

static func motion(level: Dictionary, before: Dictionary, after: Dictionary, action: Dictionary) -> Dictionary:
	var candidates: Array[Dictionary] = []
	if action.kind == 0: candidates = connections(level,before,action.face_axis)
	elif action.kind == 8:
		for c in level.perspective_falls:
			if c.connection_id == action.connection_id: candidates.append(c)
	for c in candidates:
		if c.target_face_id != Geometry.face_id(after.player.location.cube_id,after.player.location.face): continue
		if not before.camera_quadrant in c.allowed_camera_quadrants or not before.world_orientations[before.player.location.layer] in c.allowed_world_orientations: continue
		var safe := Safety.validate_perspective_motion(level,before,after,c.connection_id)
		if safe.status != 0 or not safe.issues.is_empty(): return {}
		var frame := Derived.snapshot(level,before)
		if not frame.ok: return {}
		var anchor := _find(frame.value.anchors,"face_id",c.source_face_id)
		var profile: Dictionary = Codec._to_wire(c,Feel.connection_descriptor(level))
		profile["view_contract"] = View.VERSION
		var motion := {"connection_id":c.connection_id,"motion_profile_id":c.motion_profile_id,"motion_profile_hash":Codec._json(profile).sha256_text(),"safety_verdict":{"status":"SAFE","issues":[],"evidence_ref":{"kind":"dyadic_cubic_cube_sweep.v1" if Feel.curved(level) else "exact_linear_cube_sweep.v1","query":"Safety.validate_perspective_motion","before_statekey":Key.build(level,before).key,"after_statekey":Key.build(level,after).key,"level_hash":level.content_hash,"connection_id":c.connection_id,"profile_hash":Codec._json(profile).sha256_text()}},"orientation_policy":"PRESERVE","presentation_duration_seconds":float(c.presentation_duration_ms)/1000.0,"source_frame":anchor.frame.duplicate(true)}
		if Feel.curved(level): motion["authorized_trajectory"] = c.trajectory.duplicate(true)
		else: motion["authorized_path_points2"] = c.path_points2.duplicate()
		return motion
	return {}

static func description(level: Dictionary, state: Dictionary, action: Dictionary, result: Dictionary) -> Dictionary:
	var source := Derived.snapshot(level,state)
	var frame: Dictionary = {}
	if source.ok:
		var anchor := _find(source.value.anchors,"face_id",Geometry.face_id(state.player.location.cube_id,state.player.location.face))
		frame = anchor.get("frame",{}).duplicate(true)
	var description := {"semantic":"ACTION_FEEDBACK","reason_category":"NONE","source_frame":frame,"motion":{}}
	if result.status == 2: description.reason_category = "ERROR"
	elif result.status == 0:
		if action.kind in [0,8] and result.changed:
			var path := motion(level,state,result.next_state,action)
			description.semantic = "PERSPECTIVE_FALL_APPLIED" if not path.is_empty() else "MOVE_APPLIED_NORMAL"
			description.motion = path
	elif result.rejection_code == Code.GLOBAL_TRANSITION_BUSY: description.reason_category = "BUSY"
	elif result.rejection_code == Code.UNAUTHORIZED_MECHANISM: description.reason_category = "MECHANISM_LOCKED"
	elif result.rejection_code == SpatialRules.SpatialRejectionCode.SHIFT_GATE_LOCKED: description.reason_category = "MECHANISM_LOCKED"
	elif result.rejection_code in [SpatialRules.SpatialRejectionCode.SHIFT_GATE_NOT_FOUND,SpatialRules.SpatialRejectionCode.SHIFT_GATE_TARGET_MISMATCH]: description.reason_category = "WORLD_NOT_ALLOWED"
	elif result.rejection_code == CAMERA_NOT_ALLOWED: description.reason_category = "CAMERA_NOT_ALLOWED"
	elif result.rejection_code == WORLD_NOT_ALLOWED: description.reason_category = "WORLD_NOT_ALLOWED"
	elif result.rejection_code == FALL_SAFETY_REJECTED: description.reason_category = "SAFETY_REJECTED"
	elif not result.issues.is_empty():
		description.reason_category = result.issues[0].get("details",{}).get("reason_category","UNCLASSIFIED_REJECTION")
		if description.reason_category == "UNCLASSIFIED_REJECTION":
			if result.issues.any(func(i):return i.code == Code.INVALID_FACE): description.reason_category = "INVALID_FACE"
			elif result.issues.any(func(i):return i.code in [Code.PLAYER_UNSAFE,Code.SEALED_WALKABLE_FACE,Code.SAME_WORLD_CUBE_OVERLAP,Code.INVALID_ANCHOR,Code.VALIDATION_INCOMPLETE]): description.reason_category = "SAFETY_REJECTED"
	elif result.rejection_code == FALL_NOT_AVAILABLE: description.reason_category = "FALL_NOT_AVAILABLE"
	elif action.get("kind") == 0 and result.rejection_code == 2000 and not frame.is_empty():
		# Empty-road classification is proven here; an adjacent nonwalkable support
		# remains a physical/permission rejection, never automatically an edge.
		var d: Vector3i = [frame.u,frame.v,-frame.u,-frame.v][action.face_axis]
		var anchors: Array = source.value.anchors
		var current := _find(anchors,"face_id",Geometry.face_id(state.player.location.cube_id,state.player.location.face))
		var blocked := false
		for anchor in anchors:
			if anchor.layer == state.player.location.layer and anchor.frame.normal == frame.normal and _adjacent(anchor.position2,current.position2,d):
				var face := _find(level.faces,"face_id",anchor.face_id)
				description.reason_category = "MECHANISM_LOCKED" if not face.mechanism_ids.is_empty() else "SAFETY_REJECTED"
				blocked = true
		if not blocked and connections(level,state,action.face_axis).is_empty():
			description.semantic = "MOVE_REJECTED_EDGE"
			description.reason_category = "EDGE"
		elif not blocked: description.reason_category = "FALL_NOT_AVAILABLE"
	else: description.reason_category = "UNCLASSIFIED_REJECTION"
	return description

static func _reject(state: Dictionary, action: Dictionary, code: int, category: String, message: String) -> Dictionary:
	return Rules.rejected(state,action,code,[Rules.issue(Types.ValidationCode.INVALID_ACTION,"perspective_fall",message,[],{"reason_category":category})])
static func _find(records: Array, field: String, id: Variant) -> Dictionary:
	for item in records:
		if item[field] == id: return item
	return {}

static func _adjacent(a: Vector3i, b: Vector3i, d: Vector3i) -> bool:
	for axis in 3:
		if int(a[axis])-int(b[axis]) != int(d[axis])*2: return false
	return true
