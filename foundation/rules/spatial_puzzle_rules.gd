extends RefCounted
## Opt-in permission and contact collection; Kernel owns the atomic transaction.
const Feel = preload("res://foundation/game_feel/schema.gd")
const Geometry = preload("res://foundation/spatial/surface_geometry.gd")
const Orientation = preload("res://foundation/orientation/discrete_orientation.gd")
enum SpatialRejectionCode { SHIFT_GATE_NOT_FOUND = 2010, SHIFT_GATE_LOCKED = 2011, SHIFT_GATE_TARGET_MISMATCH = 2012 }

static func gate_rejection(level: Dictionary, state: Dictionary) -> int:
	if not Feel.spatial(level): return 0
	var gate := _gate(level, state)
	if gate.is_empty(): return SpatialRejectionCode.SHIFT_GATE_NOT_FOUND
	for flag in gate.required_flags:
		if not state.level_flags[flag]: return SpatialRejectionCode.SHIFT_GATE_LOCKED
	for requirement in gate.required_mechanism_states:
		if state.mechanism_states[requirement.mechanism_id] != requirement.state: return SpatialRejectionCode.SHIFT_GATE_LOCKED
	return 0

static func mapping_rejection(level: Dictionary, state: Dictionary, mapping: Dictionary) -> int:
	if not Feel.spatial(level): return 0
	var gate := _gate(level, state)
	if gate.is_empty() or mapping.source_face != gate.source_face_id or mapping.target_face != gate.target_face_id or mapping.compatibility != 0:
		return SpatialRejectionCode.SHIFT_GATE_TARGET_MISMATCH
	return 0

static func is_lock(level: Dictionary, mechanism_id: StringName) -> bool:
	if not Feel.spatial(level): return false
	for lock in level.face_locks:
		if lock.mechanism_id == mechanism_id: return true
	return false

static func latch_arrival(level: Dictionary, before: Dictionary, arrived: Dictionary, snapshot: Dictionary) -> Dictionary:
	# Caller has already validated DATA/profile and the formal MOVE snapshot.
	var candidate := arrived.duplicate(true)
	if not Feel.spatial(level) or _face(before) == _face(arrived): return candidate
	var host := _face(arrived)
	for lock in level.face_locks:
		var mechanism := _find(level.mechanisms,"mechanism_id",lock.mechanism_id)
		if mechanism.face_id != host or candidate.mechanism_states[lock.mechanism_id] == lock.latched_state: continue
		var anchor := _find(snapshot.anchors,"face_id",host)
		var local_normal: Vector3i = Geometry.face_frame(lock.required_local_face).normal
		if Orientation.apply(candidate.player.orientation,local_normal) == -anchor.frame.normal:
			candidate.mechanism_states[lock.mechanism_id] = lock.latched_state
	return candidate

static func _gate(level: Dictionary, state: Dictionary) -> Dictionary:
	for gate in level.shift_gates:
		if gate.source_face_id == _face(state): return gate
	return {}

static func _face(state: Dictionary) -> StringName:
	return Geometry.face_id(state.player.location.cube_id,state.player.location.face)

static func _find(records: Array, field: String, id: StringName) -> Dictionary:
	for record in records:
		if record[field] == id: return record
	return {}
