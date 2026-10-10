extends RefCounted
## Pure presentation consumer: no Runtime/Rule/Save dependencies.
const EDGE_INTERVAL := 0.35
const CACHE_LIMIT := 4096
var _run := ""
var _retired: Dictionary = {}
var _generation := -1
var _last_event := -1
var _last_attempt := -1
var _active: Dictionary = {}
var _terminal: Dictionary = {}
var _canceled: Dictionary = {}
var _edge_at := -1000.0

func consume(event: Dictionary, elapsed_seconds: float) -> Dictionary:
	var out := {"accepted": false, "cues": [], "stop_identity": null, "world_id": null, "issues": []}
	var issue := _validate(event)
	if not issue.is_empty():
		out.issues.append(issue)
		return out
	var id: Dictionary = event.presentation_identity if event.presentation_identity is Dictionary else {}
	# Interruption addresses captured old identity; it must never rebind a run.
	if event.semantic == "ANIMATION_INTERRUPTED":
		if _active.get("key", "") == identity_key(id) and _active.version != event.contract_version: return out
		cancel(id)
		out.accepted = true
		out.stop_identity = id.duplicate(true)
		return out
	var run_key := _run_key(event)
	if _retired.has(run_key): return out
	if _run != run_key:
		if not _run.is_empty():
			_retire(_run)
			out.stop_identity = _active.get("identity", null)
		_run = run_key
		_generation = -1
		_last_event = -1
		_last_attempt = -1
		_active = {}
		_terminal.clear()
		_edge_at = -1000.0
	if event.event_id <= _last_event: return out
	_last_event = event.event_id
	if event.semantic == "ACTION_FEEDBACK":
		out.accepted = true
		return out
	var generation: int = id.generation
	if generation < _generation: return out
	if generation > _generation:
		out.stop_identity = _active.get("identity", null)
		_active = {}
		_terminal.clear()
		_generation = generation
		_last_attempt = -1
	var key := identity_key(id)
	if _terminal.has(key): return out
	if event.phase == "COMMITTED":
		if _active.is_empty() or _active.key != key or _active.semantic != event.semantic or _active.transition != event.transition_identity:
			return out
		if _active.version != event.contract_version: return out
		if event.contract_version == "game_feel.event.v2" and _active.trajectory != event.authorized_trajectory: return out
		if _active.source != event.source_pose or _active.target != event.target_pose:
			return out
		out.accepted = true
		out.stop_identity = id.duplicate(true)
		out.world_id = event.target_pose.location.layer
		out.cues = ["landing_impact"] if event.semantic == "PERSPECTIVE_FALL_APPLIED" else ["cube_contact"]
		_remember_terminal(key)
		_active = {}
		return out
	if event.attempt_id <= _last_attempt: return out
	if event.semantic == "MOVE_REJECTED_EDGE":
		# A rejection decoration cannot replace an accepted in-flight sound.
		if not _active.is_empty(): return out
		_last_attempt = event.attempt_id
		out.accepted = true
		if elapsed_seconds - _edge_at >= EDGE_INTERVAL:
			_edge_at = elapsed_seconds
			out.cues = ["edge_recoil"]
		_remember_terminal(key)
		return out
	_last_attempt = event.attempt_id
	if not _active.is_empty():
		out.stop_identity = _active.identity.duplicate(true)
		_remember_terminal(_active.key)
	_active = {"key": key, "identity": id.duplicate(true), "transition": event.transition_identity.duplicate(true), "semantic": event.semantic, "version": event.contract_version, "trajectory": event.get("authorized_trajectory", {}).duplicate(true), "source": event.source_pose.duplicate(true), "target": event.target_pose.duplicate(true)}
	out.accepted = true
	out.world_id = event.world_id
	out.cues = ["fall_start", "fall_whoosh"] if event.semantic == "PERSPECTIVE_FALL_APPLIED" else ["cube_roll"]
	return out

func cancel(identity: Dictionary) -> void:
	if not _identity_valid(identity): return
	var key := identity_key(identity)
	_canceled[key] = true
	_remember_terminal(key)
	if _active.get("key", "") == key: _active = {}

func clear() -> void:
	if not _run.is_empty(): _retire(_run)
	_run = ""
	_active = {}
	_terminal.clear()
	_generation = -1
	_last_event = -1
	_last_attempt = -1
	_edge_at = -1000.0

func is_active(identity: Dictionary) -> bool:
	return _active.get("key", "") == identity_key(identity)

func allows_external_identity(identity: Dictionary) -> bool:
	if not _identity_valid(identity): return false
	if _retired.has(_run_key(identity)) or _canceled.has(identity_key(identity)): return false
	return _run != _run_key(identity) or identity.generation >= _generation

static func identity_key(identity: Dictionary) -> String:
	return JSON.stringify([identity.get("session_id"), identity.get("level_run_id"), identity.get("generation"), identity.get("attempt_id")])

func _run_key(event: Dictionary) -> String:
	return JSON.stringify([event.session_id, event.level_run_id])

func _remember_terminal(key: String) -> void:
	_terminal[key] = true
	if _terminal.size() > CACHE_LIMIT: _terminal.erase(_terminal.keys()[0])

func _retire(key: String) -> void:
	_retired[key] = true
	# Fail closed if callers reuse an old session/run. Lifetime grows only per load.

func _identity_valid(id: Dictionary) -> bool:
	return id.get("session_id") is String and not id.session_id.is_empty() and id.get("level_run_id") is String and not id.level_run_id.is_empty() and id.get("generation") is int and id.generation >= 0 and id.get("attempt_id") is int and id.attempt_id >= 0

func _pose_valid(pose: Variant) -> bool:
	if not pose is Dictionary or not pose.get("location") is Dictionary: return false
	var loc: Dictionary = pose.location
	return loc.get("layer") is int and loc.layer in [0, 1] and (loc.get("cube_id") is String or loc.get("cube_id") is StringName) and not str(loc.cube_id).is_empty() and loc.get("face") is int and loc.face >= 0 and loc.face < 6 and pose.get("orientation") is int and pose.orientation >= 0 and pose.orientation < 24

func _validate(event: Dictionary) -> String:
	if not event.get("schema_version") is int or not event.get("contract_version") is String: return "invalid event version types"
	var v1: bool = event.get("schema_version") == 1 and event.get("contract_version") == "game_feel.event.v1"
	var v2: bool = event.get("schema_version") == 2 and event.get("contract_version") == "game_feel.event.v2"
	if not v1 and not v2: return "unsupported event version"
	if v2 and not event.get("semantic") in ["PERSPECTIVE_FALL_APPLIED", "ANIMATION_INTERRUPTED"]: return "unsupported v2 semantic"
	if not event.get("event_id") is int or event.event_id < 0: return "event_id must be monotonic integer"
	if not event.get("session_id") is String or event.session_id.is_empty() or not event.get("level_run_id") is String or event.level_run_id.is_empty(): return "missing run identity"
	if not event.get("attempt_id") is int or event.attempt_id < 0: return "invalid attempt identity"
	var kind = event.get("semantic")
	var phase = event.get("phase")
	if kind == "ACTION_FEEDBACK":
		return "" if phase == "FEEDBACK" and event.get("result") is Dictionary else "invalid neutral feedback"
	if not event.get("presentation_identity") is Dictionary: return "missing presentation identity"
	var id: Dictionary = event.presentation_identity
	if not _identity_valid(id) or id.session_id != event.session_id or id.level_run_id != event.level_run_id or id.attempt_id != event.attempt_id: return "presentation identity mismatch"
	if kind == "ANIMATION_INTERRUPTED":
		return "" if phase == "INTERRUPTED" and event.get("interruption_reason") in ["RESET", "RELOAD", "UNLOAD", "QUIT", "CANCEL"] else "invalid interruption"
	if not kind in ["MOVE_APPLIED_NORMAL", "PERSPECTIVE_FALL_APPLIED", "MOVE_REJECTED_EDGE"]: return "unknown event semantic"
	if not _pose_valid(event.get("source_pose")) or event.get("source_face") != event.source_pose.location: return "invalid source pose/face"
	if not event.get("world_id") is int or event.world_id != event.source_pose.location.layer: return "source world mismatch"
	if not event.get("camera_quadrant") is int or not event.camera_quadrant in [0, 1, 2, 3]: return "invalid discrete camera"
	var direction = event.get("intended_move_direction")
	if not (kind == "PERSPECTIVE_FALL_APPLIED" and direction == null):
		if not direction is int or not direction in [0, 1, 2, 3]: return "invalid mapped move"
	if not event.get("result") is Dictionary: return "missing native result"
	var result: Dictionary = event.result
	if not result.get("previous_state") is Dictionary or result.previous_state.get("player") != event.source_pose or not result.has("next_state"): return "result/source mismatch"
	if kind == "MOVE_REJECTED_EDGE":
		if phase != "REJECTED" or event.get("reason_category") != "EDGE" or result.get("status") != 1 or result.get("changed") != false: return "edge requires explicit unchanged rejection"
		# Rules.rejected retains null; legacy Unit snapshots may copy unchanged state.
		if result.next_state != null and result.next_state != result.previous_state: return "edge cannot carry changed next state"
		if event.get("target_pose") != null or event.get("target_face") != null or event.get("transition_identity") != null: return "edge cannot carry accepted target"
		return ""
	if not phase in ["STARTED", "COMMITTED"] or result.get("status") != 0 or result.get("changed") != true or event.get("reason_category") != "NONE": return "motion requires changed APPLIED result"
	if not result.next_state is Dictionary: return "motion requires accepted next state"
	if not _pose_valid(event.get("target_pose")) or event.get("target_face") != event.target_pose.location or result.next_state.get("player") != event.target_pose: return "invalid target/result"
	if not event.get("authoritative_final_orientation") is int or event.authoritative_final_orientation != event.target_pose.orientation: return "invalid authoritative orientation"
	if not event.get("transition_identity") is Dictionary: return "missing transition identity"
	var token: Dictionary = event.transition_identity
	if token.get("session_id") != id.session_id or token.get("level_run_id") != id.level_run_id or token.get("generation") != id.generation or not token.get("transaction_id") is int or token.transaction_id < 0 or not token.get("is_global") is bool: return "transition identity mismatch"
	if kind == "PERSPECTIVE_FALL_APPLIED" and (phase == "STARTED" or v2):
		if not _safe_verdict(event) or event.get("orientation_policy") != "PRESERVE" or event.source_pose.orientation != event.target_pose.orientation or event.target_pose.location.layer != event.world_id: return "Fall lacks explicit safe preserved same-world path"
		if v2 and (not event.safety_verdict is Dictionary or event.safety_verdict.evidence_ref.get("kind") != "dyadic_cubic_cube_sweep.v1"): return "v2 Fall lacks curve Safety evidence"
		for field in ["connection_id", "motion_profile_id", "motion_profile_hash"]:
			if not (event.get(field) is String or event.get(field) is StringName) or str(event[field]).is_empty(): return "missing Fall profile identity"
		if not event.get("source_frame") is Dictionary: return "missing source frame"
		if v2:
			if not _trajectory_valid(event.get("authorized_trajectory")): return "invalid authorized trajectory"
		else:
			if not event.get("authorized_path_points2") is Array or event.authorized_path_points2.size() < 2: return "missing authorized path"
			for point in event.authorized_path_points2:
				if not point is Vector3i: return "noncanonical path point"
		var duration = event.get("presentation_duration_seconds")
		if not (duration is float or duration is int) or not is_finite(float(duration)) or duration <= 0: return "invalid Fall duration"
	return ""

func _trajectory_valid(value: Variant) -> bool:
	# Shape gate only. Curve geometry, traversal and continuous Safety remain Owner01.
	if not value is Dictionary or not value.is_read_only() or value.size() != 3: return false
	if not value.get("trajectory_version") is String or value.trajectory_version != "pfall.departure_cubic.v1": return false
	for field in ["departure_points2", "descent_control_points2"]:
		var points = value.get(field)
		if not points is Array or not points.is_read_only() or points.size() != (2 if field == "departure_points2" else 4): return false
		for point in points:
			if not point is Vector3i: return false
			for component in [point.x, point.y, point.z]:
				if component < -1000000 or component > 1000000: return false
	return true

func _safe_verdict(event: Dictionary) -> bool:
	var verdict = event.get("safety_verdict")
	if verdict is String: return verdict == "SAFE" # Historical presentation Unit shape.
	if not verdict is Dictionary or verdict.get("status") != "SAFE": return false
	if not verdict.get("issues") is Array or not verdict.issues.is_empty(): return false
	var evidence = verdict.get("evidence_ref")
	if not evidence is Dictionary or not evidence.get("level_hash") is String or evidence.level_hash.is_empty(): return false
	return evidence.get("connection_id") == event.get("connection_id") and evidence.get("profile_hash") == event.get("motion_profile_hash")
