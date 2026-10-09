extends RefCounted
## Deterministic authorized-path sampler. No nodes, tweens, clock or Runtime.
const State = preload("res://game/feel/animation/fall_landing/fall_visual_state.gd")
const Parameters = preload("res://game/feel/animation/fall_landing/motion_parameters.gd")
var parameters = Parameters.new()
var _identity: Dictionary = {}
var _points: PackedVector3Array = []
var _distances: PackedFloat64Array = []
var _curve: PackedFloat64Array = []
var _config: Resource
var _axis := Vector3.ZERO
var _total := 0.0
var _anticipation := 0.0
var _departure := 0.0
var _length := 0.0

func begin(event: Dictionary) -> Dictionary:
	if not _identity.is_empty(): return {"ok": false, "issues": [{"path": "motion", "message": "Clear/cancel active identity before beginning another motion."}]}
	var issues := State.event_issues(event, "STARTED")
	if parameters == null or not parameters is Parameters:
		issues.append({"path": "parameters", "message": "Motion parameters required."})
	else:
		issues.append_array(parameters.issues())
	var points: Variant = event.get("authorized_path_points2")
	if not points is Array or points.size() < 2:
		issues.append({"path": "event.authorized_path_points2", "message": "At least two canonical actor-center points required."})
	else:
		for point in points:
			if not point is Vector3i: issues.append({"path": "event.authorized_path_points2", "message": "Expected Vector3i half-unit positions."})
	if not State.frame_valid(event.get("source_frame")):
		issues.append({"path": "event.source_frame", "message": "Canonical source frame required."})
	if not State.text(event.get("safety_verdict")) or event.get("safety_verdict") != "SAFE" or not State.text(event.get("connection_id")) or not State.text(event.get("motion_profile_id")) or not State.text(event.get("motion_profile_hash")):
		issues.append({"path": "event.motion_profile", "message": "Explicit SAFE attestation and profile identity required; animation never supplies proof."})
	var duration: Variant = event.get("presentation_duration_seconds")
	if not (duration is float or duration is int) or not is_finite(float(duration)) or float(duration) <= 0.0 or float(duration) > 30.0:
		issues.append({"path": "event.presentation_duration_seconds", "message": "Finite duration in (0,30] required."})
	if not issues.is_empty(): return {"ok": false, "issues": issues}
	var timing: Dictionary = parameters.timing_table()
	if not timing.ok: return {"ok": false, "issues": timing.issues}
	var staged_points: PackedVector3Array = []
	var staged_distances: PackedFloat64Array = [0.0]
	var length := 0.0
	for point in points:
		staged_points.append(Vector3(point) * 0.5)
		if staged_points.size() > 1:
			length += staged_points[-1].distance_to(staged_points[-2])
			staged_distances.append(length)
	if length <= 0.000001: return {"ok": false, "issues": [{"path": "event.authorized_path_points2", "message": "Fall path must have positive length."}]}
	_config = parameters.duplicate(true)
	_points = staged_points
	_distances = staged_distances
	_length = length
	_curve = timing.values
	_identity = event.presentation_identity.duplicate(true)
	_axis = State.lean_axis(event, _points[1] - _points[0])
	_total = float(duration)
	var anticipation_weight: float = 0.0 if _config.reduced_motion else _config.anticipation_duration
	var weight: float = anticipation_weight + _config.departure_duration + _config.fall_duration
	_anticipation = _total * anticipation_weight / weight
	_departure = _total * _config.departure_duration / weight
	return {"ok": true, "issues": [], "duration_seconds": _total,
		"cue_schedule": {"FallStart": 0.0, "LeavePlatform": _anticipation, "FallMoving": _anticipation + _departure}}

func sample(elapsed_seconds: float) -> Dictionary:
	if _identity.is_empty() or not is_finite(elapsed_seconds): return State.neutral()
	var t := clampf(elapsed_seconds, 0.0, _total)
	var offset := Quaternion.IDENTITY
	var phase := "FALL_MOVING"
	var fraction := 0.0
	if t < _anticipation:
		phase = "ANTICIPATION"
		var progress := smoothstep(0.0, _anticipation, t)
		if not _axis.is_zero_approx(): offset = Quaternion(_axis, deg_to_rad(_config.anticipation_angle_degrees) * progress)
	elif t < _anticipation + _departure:
		phase = "DEPARTURE"
		var progress := (t - _anticipation) / _departure
		fraction = _config.departure_path_fraction * progress
		if not _config.reduced_motion and not _axis.is_zero_approx(): offset = Quaternion(_axis, deg_to_rad(_config.anticipation_angle_degrees) * (1.0 - smoothstep(0.0, 1.0, progress)))
	elif t < _total:
		var progress := (t - _anticipation - _departure) / (_total - _anticipation - _departure)
		var eased := progress if _config.reduced_motion else _ease(progress)
		fraction = _config.departure_path_fraction + (1.0 - _config.departure_path_fraction) * eased
	else:
		phase = "AWAITING_COMMIT"
		fraction = 1.0
	return {"active": true, "identity": _identity.duplicate(true), "phase": phase,
		"progress": t / _total, "motion_done": t >= _total, "position": _position(fraction),
		"rotation_offset": offset, "scale_multiplier": Vector3.ONE}

func _ease(t: float) -> float:
	var index := t * float(_curve.size() - 1)
	var lower := mini(int(index), _curve.size() - 2)
	return lerpf(_curve[lower], _curve[lower + 1], index - float(lower))

func _position(fraction: float) -> Vector3:
	if fraction <= 0.0: return _points[0]
	if fraction >= 1.0: return _points[-1]
	var distance := _length * fraction
	for i in range(1, _points.size()):
		if _distances[i] > _distances[i - 1] and distance <= _distances[i]:
			return _points[i - 1].lerp(_points[i], (distance - _distances[i - 1]) / (_distances[i] - _distances[i - 1]))
	return _points[-1]

func cancel(identity: Dictionary) -> void:
	if not _identity.is_empty() and identity == _identity: clear()

func clear() -> void:
	_identity = {}
	_points = []
	_distances = []
	_curve = []
	_config = null
	_axis = Vector3.ZERO
	_total = 0.0
	_length = 0.0
