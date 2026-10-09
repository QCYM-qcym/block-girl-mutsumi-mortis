extends RefCounted
## Read-only presentation boundary. Never classifies a native code as EDGE.
const Math = preload("res://foundation/orientation/discrete_orientation.gd")
const PEAK_RADIANS := 0.20943951023931956 # 12 degrees

static func validate(event: Dictionary) -> Array:
	if typeof(event.get("schema_version")) != TYPE_INT or event.schema_version != 1 or event.get("contract_version") != "game_feel.event.v1":
		return ["Unsupported game-feel event version."]
	if event.get("semantic") != "MOVE_REJECTED_EDGE" or event.get("phase") != "REJECTED" or event.get("reason_category") != "EDGE":
		return ["Only explicitly classified EDGE refusal starts this decoration."]
	for field in ["event_id", "attempt_id", "world_id", "camera_quadrant", "intended_move_direction"]:
		if typeof(event.get(field)) != TYPE_INT: return ["Missing integer: " + field]
	if event.event_id < 0 or event.attempt_id < 0 or event.world_id not in [0, 1] or event.camera_quadrant not in range(4) or event.intended_move_direction not in range(4):
		return ["Event id, world, camera or mapped FaceAxis outside domain."]
	for field in ["session_id", "level_run_id"]:
		if typeof(event.get(field)) != TYPE_STRING or event[field].is_empty(): return ["Missing opaque run identity: " + field]
	var identity: Variant = event.get("presentation_identity")
	if not identity is Dictionary or identity.size() != 4: return ["Missing full presentation_identity."]
	for field in ["session_id", "level_run_id", "attempt_id"]:
		if identity.get(field) != event[field] or typeof(identity.get(field)) != typeof(event[field]): return ["Identity disagrees with event: " + field]
	if typeof(identity.get("generation")) != TYPE_INT or identity.generation < 0: return ["Invalid generation."]
	for field in ["transition_identity", "target_pose", "target_face", "authoritative_final_orientation"]:
		if not event.has(field) or event[field] != null: return ["Edge refusal has no accepted endpoint/token: " + field]
	var pose: Variant = event.get("source_pose")
	if not pose is Dictionary or typeof(pose.get("orientation")) != TYPE_INT or not Math.is_valid(pose.orientation): return ["Invalid source cube24 pose."]
	var location: Variant = pose.get("location")
	if not location is Dictionary or typeof(location.get("layer")) != TYPE_INT or location.layer != event.world_id or typeof(location.get("face")) != TYPE_INT or location.face not in range(6): return ["Invalid source support location."]
	if typeof(location.get("cube_id")) != TYPE_STRING_NAME or location.cube_id == &"": return ["Missing native support cube id."]
	if event.get("source_face") != location: return ["Source support does not match current pose."]
	var result: Variant = event.get("result")
	if not result is Dictionary: return ["Missing native refusal result."]
	for field in ["status", "previous_state", "next_state", "action", "changed", "rejection_code", "issues", "global_kind"]:
		if not result.has(field): return ["Missing native refusal field: " + field]
	if typeof(result.status) != TYPE_INT or result.status != 1 or typeof(result.changed) != TYPE_BOOL or result.changed or result.next_state != null or typeof(result.global_kind) != TYPE_INT or result.global_kind != 0:
		return ["Edge requires an unchanged native REJECTED result without a global transition."]
	if not result.get("previous_state") is Dictionary or result.previous_state.get("player") != pose: return ["Refusal must preserve actual before player pose."]
	if not result.get("action") is Dictionary or typeof(result.action.get("kind")) != TYPE_INT or result.action.kind != 0 or typeof(result.action.get("face_axis")) != TYPE_INT or result.action.face_axis != event.intended_move_direction: return ["Mapped MOVE action disagrees with presentation direction."]
	if typeof(result.get("rejection_code")) != TYPE_INT or not result.get("issues") is Array: return ["Native refusal diagnostics missing."]
	var frame: Variant = event.get("source_frame")
	if not frame is Dictionary: return ["Missing formal source_frame."]
	for field in ["u", "v", "normal"]:
		if typeof(frame.get(field)) != TYPE_VECTOR3I: return ["Source frame must contain exact signed axes."]
	if Math.from_columns(frame.u, frame.v, frame.normal) == -1: return ["Invalid right-handed source frame."]
	return []

static func direction(event: Dictionary) -> Vector3:
	var frame: Dictionary = event.source_frame
	return [Vector3(frame.u), Vector3(frame.v), -Vector3(frame.u), -Vector3(frame.v)][event.intended_move_direction]

static func pivot(event: Dictionary, half_extent: float) -> Vector3:
	if not is_finite(half_extent) or half_extent <= 0: return Vector3.ZERO
	return (direction(event) - Vector3(event.source_frame.normal)) * half_extent

static func rotation(event: Dictionary, angle: float) -> Quaternion:
	var axis := Vector3(event.source_frame.normal).cross(direction(event))
	return Quaternion(axis, angle) if angle != 0.0 else Quaternion.IDENTITY

static func neutral(identity: Variant = null, done: bool = false) -> Dictionary:
	return {"active": false, "identity": identity.duplicate(true) if identity is Dictionary else null,
		"phase": "DONE" if done else "IDLE", "progress": 1.0 if done else 0.0,
		"motion_done": done, "position": null, "rotation_offset": Quaternion.IDENTITY, "scale_multiplier": Vector3.ONE}

static func elapsed(value: float, previous: float) -> float:
	# A clock cannot rewind a completed/blocked phase or inject NaN into a transform.
	return maxf(previous, maxf(0.0, value)) if is_finite(value) else previous
