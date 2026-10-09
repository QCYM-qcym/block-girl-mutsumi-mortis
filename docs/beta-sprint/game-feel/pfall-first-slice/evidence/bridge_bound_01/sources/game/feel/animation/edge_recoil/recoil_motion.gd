extends RefCounted
## Absolute return sampler; never writes a node, orientation or Runtime state.
const Event = preload("res://game/feel/animation/edge_recoil/edge_event.gd")
const Admission = preload("res://game/feel/animation/edge_recoil/edge_admission.gd")
const SECONDS := 0.265
var _admission = Admission.new()
var _event: Dictionary = {}
var _elapsed := 0.0
var _cancelled := false

func begin(event: Dictionary) -> Dictionary:
	var issues := Event.validate(event)
	if not issues.is_empty(): return {"ok": false, "issues": issues}
	if not _admission.claim(event): return {"ok": false, "issues": ["Duplicate or stale edge delivery."]}
	_event = event.duplicate(true)
	_elapsed = 0.0
	_cancelled = false
	return {"ok": true, "issues": []}

func sample(elapsed_seconds: float) -> Dictionary:
	if _event.is_empty() or _cancelled: return Event.neutral()
	_elapsed = Event.elapsed(elapsed_seconds, _elapsed)
	var t := clampf(_elapsed / SECONDS, 0.0, 1.0)
	if t == 1.0: return Event.neutral(_event.presentation_identity, true)
	# Fast initial recoil, heavy deceleration into exact rest; no reverse tilt that
	# would drive the opposite bottom corner through the supporting platform.
	return {"active": true, "identity": _event.presentation_identity.duplicate(true),
		"phase": "RECOIL", "progress": t, "motion_done": false, "position": null,
		"rotation_offset": Event.rotation(_event, Event.PEAK_RADIANS * pow(1.0 - t, 3)), "scale_multiplier": Vector3.ONE}

func cancel(identity: Dictionary) -> void:
	if not _event.is_empty() and identity == _event.presentation_identity: clear()

func clear() -> void:
	_event.clear()
	_cancelled = true
	_elapsed = 0.0

func support_pivot_offset(half_extent: float = 0.5) -> Vector3:
	return Vector3.ZERO if _event.is_empty() else Event.pivot(_event, half_extent)
