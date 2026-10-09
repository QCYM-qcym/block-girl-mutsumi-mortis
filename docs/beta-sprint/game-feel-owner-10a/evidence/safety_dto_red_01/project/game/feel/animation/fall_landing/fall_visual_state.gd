extends RefCounted
## Presentation validation only. Does not verify/grant traversal or Safety.
static func neutral() -> Dictionary:
	return {"active": false, "identity": null, "phase": "IDLE", "progress": 0.0,
		"motion_done": false, "position": null, "rotation_offset": Quaternion.IDENTITY,
		"scale_multiplier": Vector3.ONE}

static func identity_valid(value: Variant) -> bool:
	return value is Dictionary and value.size() == 4 and text(value.get("session_id")) and text(value.get("level_run_id")) and integer(value.get("generation"), 0) and integer(value.get("attempt_id"), 0)

static func text(value: Variant) -> bool:
	return (value is String or value is StringName) and not String(value).is_empty()

static func integer(value: Variant, minimum: int, maximum: int = 2147483647) -> bool:
	return value is int and value >= minimum and value <= maximum

static func pose_valid(value: Variant) -> bool:
	if not value is Dictionary or not integer(value.get("orientation"), 0, 23): return false
	var location: Variant = value.get("location")
	return location is Dictionary and integer(location.get("layer"), 0, 1) and integer(location.get("face"), 0, 5) and text(location.get("cube_id"))

static func event_issues(event: Dictionary, phase: String) -> Array:
	var result: Array = []
	if event.get("schema_version") != 1 or event.get("contract_version") != "game_feel.event.v1":
		result.append({"path": "event", "message": "Expected game_feel.event.v1."})
	if event.get("semantic") != "PERSPECTIVE_FALL_APPLIED" or event.get("phase") != phase:
		result.append({"path": "event.phase", "message": "Expected authorized Fall " + phase + "."})
	var identity: Variant = event.get("presentation_identity")
	if not identity_valid(identity):
		result.append({"path": "event.presentation_identity", "message": "Complete presentation identity required."})
	else:
		for key in ["session_id", "level_run_id", "attempt_id"]:
			if identity[key] != event.get(key): result.append({"path": "event." + key, "message": "Envelope identity mismatch."})
	var token: Variant = event.get("transition_identity")
	if not token is Dictionary or not integer(token.get("transaction_id"), 1) or not token.get("is_global") is bool:
		result.append({"path": "event.transition_identity", "message": "Native completion token required (host use only)."})
	elif identity_valid(identity):
		for key in ["session_id", "level_run_id", "generation"]:
			if token.get(key) != identity[key]: result.append({"path": "event.transition_identity." + key, "message": "Token identity mismatch."})
	if not integer(event.get("event_id"), 0) or not integer(event.get("camera_quadrant"), 0, 3) or not integer(event.get("world_id"), 0, 1):
		result.append({"path": "event", "message": "Event/camera/world identifiers required."})
	var source: Variant = event.get("source_pose")
	var target: Variant = event.get("target_pose")
	if not pose_valid(source) or not pose_valid(target):
		result.append({"path": "event.pose", "message": "Native source/target player records required."})
	else:
		if event.get("source_face") != source.location or event.get("target_face") != target.location or source.location.layer != event.get("world_id") or target.location.layer != event.get("world_id"):
			result.append({"path": "event.pose.location", "message": "Pose/support/world mismatch."})
		if event.get("orientation_policy", "PRESERVE" if phase == "COMMITTED" else null) != "PRESERVE" or source.orientation != target.orientation or target.orientation != event.get("authoritative_final_orientation"):
			result.append({"path": "event.orientation_policy", "message": "Only exact PRESERVE endpoints supported."})
	var native: Variant = event.get("result")
	if not native is Dictionary or native.get("status") != 0 or native.get("changed") != true or event.get("reason_category") != "NONE":
		result.append({"path": "event.result", "message": "Accepted changed result required."})
	elif pose_valid(source) and pose_valid(target):
		var previous: Variant = native.get("previous_state")
		var next: Variant = native.get("next_state")
		if not previous is Dictionary or not next is Dictionary or previous.get("player") != source or next.get("player") != target:
			result.append({"path": "event.result", "message": "Player snapshots must match the accepted native result."})
	return result

static func frame_valid(value: Variant) -> bool:
	if not value is Dictionary: return false
	for key in ["u", "v", "normal"]:
		if not value.get(key) is Vector3i or Vector3(value[key]).length_squared() != 1.0: return false
	return Vector3(value.u).cross(Vector3(value.v)) == Vector3(value.normal)

static func lean_axis(event: Dictionary, fallback: Vector3) -> Vector3:
	var frame: Dictionary = event.source_frame
	var normal := Vector3(frame.normal)
	var direction := fallback - normal * fallback.dot(normal)
	match event.get("intended_move_direction"):
		0: direction = Vector3(frame.u)
		1: direction = Vector3(frame.v)
		2: direction = -Vector3(frame.u)
		3: direction = -Vector3(frame.v)
	if direction.length_squared() < 0.000001: return Vector3.ZERO
	return normal.cross(direction.normalized()).normalized()
