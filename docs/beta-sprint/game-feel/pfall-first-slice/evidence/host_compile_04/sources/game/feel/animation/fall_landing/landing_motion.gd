extends RefCounted
## COMMITTED decoration only. Host retains position and authoritative cube24.
const State = preload("res://game/feel/animation/fall_landing/fall_visual_state.gd")
const Parameters = preload("res://game/feel/animation/fall_landing/motion_parameters.gd")
var parameters = Parameters.new()
var _identity: Dictionary = {}
var _config: Resource
var _normal := Vector3.UP
var _axis := Vector3.ZERO
var _duration := 0.0

func begin(event: Dictionary) -> Dictionary:
	if not _identity.is_empty(): return {"ok": false, "issues": [{"path": "motion", "message": "Clear/cancel previous landing before begin."}]}
	var issues := State.event_issues(event, "COMMITTED")
	# source_frame is required by STARTED, optional in the COMMITTED envelope.
	# The initial TOP->TOP lab defaults to UP; host may retain the captured frame.
	if event.has("source_frame") and not State.frame_valid(event.source_frame):
		issues.append({"path": "event.source_frame", "message": "Invalid captured source frame."})
	if parameters == null or not parameters is Parameters:
		issues.append({"path": "parameters", "message": "Motion parameters required."})
	else:
		issues.append_array(parameters.issues())
	if not issues.is_empty(): return {"ok": false, "issues": issues}
	_config = parameters.duplicate(true)
	_identity = event.presentation_identity.duplicate(true)
	_normal = Vector3(event.source_frame.normal).abs() if event.has("source_frame") else Vector3.UP
	_axis = State.lean_axis(event, Vector3.ZERO) if event.has("source_frame") else Vector3.RIGHT
	_duration = _config.impact_duration + _config.settle_duration
	return {"ok": true, "issues": [], "duration_seconds": _duration,
		"cue_schedule": {"LandingImpact": 0.0, "LandingSettled": _duration}}

func sample(elapsed_seconds: float) -> Dictionary:
	if _identity.is_empty() or not is_finite(elapsed_seconds): return State.neutral()
	var t := clampf(elapsed_seconds, 0.0, _duration)
	var offset := Quaternion.IDENTITY
	var scale := Vector3.ONE
	var phase := "LANDING_SETTLED" if t >= _duration else "LANDING_REBOUND"
	if t < _duration and not _config.reduced_motion:
		var deformation := 0.0
		var rock := 0.0
		if t < _config.impact_duration:
			phase = "LANDING_IMPACT"
			var amount := smoothstep(0.0, _config.impact_duration, t)
			deformation = -_config.impact_compression * amount
			rock = amount
		else:
			var p: float = (t - _config.impact_duration) / _config.settle_duration
			# A finite damped half-cycle, softly windowed to exact neutrality.
			var envelope := exp(-_config.landing_damping * p) * (1.0 - smoothstep(0.0, 1.0, p))
			deformation = (-_config.impact_compression * cos(TAU * p) + _config.landing_rebound * sin(PI * p)) * envelope
			rock = cos(TAU * p) * envelope
		var normal_scale := 1.0 + deformation
		var tangent_scale := 1.0 / sqrt(normal_scale)
		scale = Vector3.ONE * tangent_scale + _normal * (normal_scale - tangent_scale)
		if not _axis.is_zero_approx(): offset = Quaternion(_axis, deg_to_rad(_config.landing_angle_degrees) * rock)
	return {"active": true, "identity": _identity.duplicate(true), "phase": phase,
		"progress": t / _duration, "motion_done": t >= _duration, "position": null,
		"rotation_offset": offset, "scale_multiplier": scale}

func cancel(identity: Dictionary) -> void:
	if not _identity.is_empty() and identity == _identity: clear()

func clear() -> void:
	_identity = {}
	_config = null
	_axis = Vector3.ZERO
	_normal = Vector3.UP
	_duration = 0.0
