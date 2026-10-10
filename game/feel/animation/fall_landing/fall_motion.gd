extends RefCounted
## Deterministic authorized-path sampler. No nodes, tweens, clock or Runtime.
const State = preload("res://game/feel/animation/fall_landing/fall_visual_state.gd")
const Parameters = preload("res://game/feel/animation/fall_landing/motion_parameters.gd")
const TRAJECTORY_PATH := "res://foundation/game_feel/trajectory_profile.gd"
var parameters = Parameters.new()
var _identity: Dictionary = {}
var _points: PackedVector3Array = []
var _distances: PackedFloat64Array = []
var _curve: PackedFloat64Array = []
var _curve_slopes: PackedFloat64Array = []
var _join_speed := 0.0
var _config: Resource
var _axis := Vector3.ZERO
var _total := 0.0
var _anticipation := 0.0
var _departure := 0.0
var _length := 0.0
var _trajectory: Dictionary = {}
var _trajectory_sampler: Script
var _departure_fraction := 0.15

func begin(event: Dictionary) -> Dictionary:
	if not _identity.is_empty(): return {"ok": false, "issues": [{"path": "motion", "message": "Clear/cancel active identity before beginning another motion."}]}
	var issues := State.event_issues(event, "STARTED")
	if parameters == null or not parameters is Parameters:
		issues.append({"path": "parameters", "message": "Motion parameters required."})
	else:
		issues.append_array(parameters.issues())
	var points: Variant = event.get("authorized_path_points2")
	var curved := State.event_version(event) == 2
	var staged_sampler: Script
	var staged_trajectory: Dictionary = {}
	var trajectory_points: PackedVector3Array = []
	if curved:
		var trajectory: Variant = event.get("authorized_trajectory")
		if event.has("authorized_path_points2") or not trajectory is Dictionary or not State.text(trajectory.get("trajectory_version")) or trajectory.trajectory_version != "pfall.departure_cubic.v1":
			issues.append({"path": "event.authorized_trajectory", "message": "Explicit supported v2 trajectory required; no polyline fallback."})
		elif not ResourceLoader.exists(TRAJECTORY_PATH):
			issues.append({"path": "dependencies.trajectory_profile", "message": "Owner01 pure trajectory sampler unavailable."})
		else:
			staged_sampler = load(TRAJECTORY_PATH)
			if staged_sampler == null or not staged_sampler.has_method("sample_actor_center"):
				issues.append({"path": "dependencies.trajectory_profile", "message": "Required Owner01 sampling API unavailable."})
			else:
				staged_trajectory = trajectory.duplicate(true)
				for parameter in [0.0, 0.25, 1.0]:
					var sampled: Dictionary = staged_sampler.sample_actor_center(staged_trajectory, parameter)
					if not _trajectory_sample_valid(sampled):
						issues.append({"path": "event.authorized_trajectory", "message": "Owner01 sampler rejected trajectory or returned invalid position."})
					else: trajectory_points.append(sampled.position)
		var verdict: Variant = event.get("safety_verdict")
		if not verdict is Dictionary or not verdict.get("evidence_ref") is Dictionary or not State.text(verdict.evidence_ref.get("kind")) or verdict.evidence_ref.kind != "dyadic_cubic_cube_sweep.v1":
			issues.append({"path": "event.safety_verdict", "message": "Curve requires its structured dyadic cubic sweep attestation."})
	else:
		if event.has("authorized_trajectory") or not points is Array or points.size() < 2:
			issues.append({"path": "event.authorized_path_points2", "message": "Explicit v1 actor-center polyline required; no trajectory reinterpretation."})
		else:
			for point in points:
				if not point is Vector3i: issues.append({"path": "event.authorized_path_points2", "message": "Expected Vector3i half-unit positions."})
	if not State.frame_valid(event.get("source_frame")):
		issues.append({"path": "event.source_frame", "message": "Canonical source frame required."})
	if not State.text(event.get("connection_id")) or not State.text(event.get("motion_profile_id")) or not State.text(event.get("motion_profile_hash")) or not State.safe_attestation(event):
		issues.append({"path": "event.motion_profile", "message": "Explicit SAFE attestation and profile identity required; animation never supplies proof."})
	var duration: Variant = event.get("presentation_duration_seconds")
	if not (duration is float or duration is int) or not is_finite(float(duration)) or float(duration) < 0.001 or float(duration) > 30.0:
		issues.append({"path": "event.presentation_duration_seconds", "message": "Finite duration in [0.001,30] required (Runtime millisecond resolution)."})
	if not issues.is_empty(): return {"ok": false, "issues": issues}
	var timing: Dictionary = parameters.timing_table()
	if not timing.ok: return {"ok": false, "issues": timing.issues}
	var staged_points: PackedVector3Array = []
	var staged_distances: PackedFloat64Array = [0.0]
	var length := 0.0
	if curved:
		staged_points = trajectory_points
		length = 1.0 # Geometry parameter, not approximated cubic arc length.
	else:
		for point in points:
			staged_points.append(Vector3(point) * 0.5)
			if staged_points.size() > 1:
				length += staged_points[-1].distance_to(staged_points[-2])
				staged_distances.append(length)
	if length <= 0.000001: return {"ok": false, "issues": [{"path": "event.authorized_path_points2", "message": "Fall path must have positive length."}]}
	_config = parameters.duplicate(true)
	_trajectory = staged_trajectory
	_trajectory_sampler = staged_sampler
	_departure_fraction = 0.25 if curved else _config.departure_path_fraction
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
	# Positive shared velocity across the departure/main phase boundary.
	# Each normalized Hermite slope is <= its interval's secant, so the timing
	# remains bounded and monotone. Flat custom intervals remain intentional.
	if _config.reduced_motion:
		_curve = [0.0, 1.0]
	var intervals := _curve.size() - 1
	var secants: PackedFloat64Array = []
	for i in intervals: secants.append((_curve[i + 1] - _curve[i]) * float(intervals))
	var fall_time := _total - _anticipation - _departure
	_join_speed = minf(_departure_fraction / _departure, (1.0 - _departure_fraction) * secants[0] / fall_time)
	_curve_slopes = [_join_speed * fall_time / (1.0 - _departure_fraction)]
	for i in range(1, intervals): _curve_slopes.append(minf(secants[i - 1], secants[i]))
	_curve_slopes.append(secants[-1])
	return {"ok": true, "issues": [], "duration_seconds": _total,
		"cue_schedule": {"FallStart": 0.0, "LeavePlatform": _anticipation, "FallMoving": _anticipation + _departure},
		"phase_schedule": {"ANTICIPATION": 0.0, "DEPARTURE": _anticipation, "FALL_MOVING": _anticipation + _departure, "AWAITING_COMMIT": _total}}

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
		fraction = _hermite(0.0, _departure_fraction, 0.0, _join_speed * _departure, progress)
		if not _config.reduced_motion and not _axis.is_zero_approx(): offset = Quaternion(_axis, deg_to_rad(_config.anticipation_angle_degrees) * (1.0 - smoothstep(0.0, 1.0, progress)))
	elif t < _total:
		var progress := (t - _anticipation - _departure) / (_total - _anticipation - _departure)
		var eased := _ease(progress)
		fraction = _departure_fraction + (1.0 - _departure_fraction) * eased
	else:
		phase = "AWAITING_COMMIT"
		fraction = 1.0
	var position: Vector3
	if _trajectory_sampler != null:
		var sampled: Dictionary = _trajectory_sampler.sample_actor_center(_trajectory, fraction)
		if not _trajectory_sample_valid(sampled): return State.neutral()
		position = sampled.position
	else: position = _position(fraction)
	return {"active": true, "identity": _identity.duplicate(true), "phase": phase,
		"progress": t / _total, "motion_done": t >= _total, "position": position,
		"rotation_offset": offset, "scale_multiplier": Vector3.ONE}

func _ease(t: float) -> float:
	var index := t * float(_curve.size() - 1)
	var lower := mini(int(index), _curve.size() - 2)
	var width := 1.0 / float(_curve.size() - 1)
	return _hermite(_curve[lower], _curve[lower + 1], _curve_slopes[lower] * width, _curve_slopes[lower + 1] * width, index - float(lower))

func _trajectory_sample_valid(value: Dictionary) -> bool:
	return value.size() == 3 and value.get("ok") == true and value.get("position") is Vector3 and value.position.is_finite() and value.get("issues") is Array and value.issues.is_empty()

func _hermite(a: float, b: float, da: float, db: float, t: float) -> float:
	var t2 := t * t
	var t3 := t2 * t
	return (2.0 * t3 - 3.0 * t2 + 1.0) * a + (t3 - 2.0 * t2 + t) * da + (-2.0 * t3 + 3.0 * t2) * b + (t3 - t2) * db

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
	_trajectory = {}
	_trajectory_sampler = null
	_curve_slopes = []
	_join_speed = 0.0
	_config = null
	_axis = Vector3.ZERO
	_total = 0.0
	_length = 0.0
