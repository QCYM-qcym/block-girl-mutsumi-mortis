extends RefCounted
## One Edge presentation per held mapped intent/current pose; full identity cancellation.
const Event = preload("res://game/feel/animation/edge_recoil/edge_event.gd")
const Recoil = preload("res://game/feel/animation/edge_recoil/recoil_motion.gd")
const Admission = preload("res://game/feel/animation/edge_recoil/edge_admission.gd")
const LEAN_SECONDS := 0.13
const BLOCK_SECONDS := 0.045
const SECONDS := LEAN_SECONDS + BLOCK_SECONDS + Recoil.SECONDS
signal cue(name: String, identity: Dictionary)
var _event: Dictionary = {}
var _return = Recoil.new()
var _admission = Admission.new()
var _latch: Dictionary = {}
var _active_intent: Dictionary = {}
var _elapsed := 0.0
var _active := false
var _done := false
var _blocked := false
var _epoch := 0

func begin(event: Dictionary) -> Dictionary:
	var issues := Event.validate(event)
	if not issues.is_empty(): return {"ok": false, "issues": issues}
	var id: Dictionary = event.presentation_identity
	var run := JSON.stringify([id.session_id, id.level_run_id])
	if not _admission.claim(event):
		return {"ok": false, "issues": ["Duplicate or stale edge delivery."]}
	var intent := {"run": run, "generation": id.generation, "pose": event.source_pose.duplicate(true),
		"frame": event.source_frame.duplicate(true), "camera": event.camera_quadrant, "axis": event.intended_move_direction}
	if _active and intent == _active_intent:
		_latch = intent
		return {"ok": false, "issues": ["Identical edge cycle still active; progress retained."]}
	if intent == _latch: return {"ok": false, "issues": ["Held edge intent already presented; release to rearm."]}
	_latch = intent
	_active_intent = intent.duplicate(true)
	_event = event.duplicate(true)
	_return.begin(_event)
	_elapsed = 0.0
	_active = true
	_done = false
	_blocked = false
	_epoch += 1
	var epoch := _epoch
	cue.emit("EdgeLeanStart", id.duplicate(true))
	return {"ok": epoch == _epoch and _active, "issues": []}

func sample(elapsed_seconds: float) -> Dictionary:
	if not _active: return Event.neutral(_event.get("presentation_identity"), _done)
	_elapsed = Event.elapsed(elapsed_seconds, _elapsed)
	var epoch := _epoch
	var id: Dictionary = _event.presentation_identity.duplicate(true)
	if _elapsed >= LEAN_SECONDS and not _blocked:
		_blocked = true
		cue.emit("EdgeBlocked", id.duplicate(true))
		# A same-token observer may synchronously sample to completion without
		# replacing the epoch. Its end cue already owns completion.
		if epoch != _epoch or not _active: return Event.neutral(id, epoch == _epoch and _done)
	if _elapsed >= SECONDS:
		_active = false
		_done = true
		cue.emit("EdgeRecoilEnd", id.duplicate(true))
		return Event.neutral(id, true) if epoch == _epoch else Event.neutral(id)
	var angle := Event.PEAK_RADIANS
	var phase := "BLOCKED"
	if _elapsed < LEAN_SECONDS:
		phase = "LEAN"
		angle *= smoothstep(0.0, 1.0, _elapsed / LEAN_SECONDS)
	elif _elapsed >= LEAN_SECONDS + BLOCK_SECONDS:
		var tail: Dictionary = _return.sample(_elapsed - LEAN_SECONDS - BLOCK_SECONDS)
		tail.progress = _elapsed / SECONDS
		return tail
	return {"active": true, "identity": id, "phase": phase, "progress": _elapsed / SECONDS,
		"motion_done": false, "position": null, "rotation_offset": Event.rotation(_event, angle), "scale_multiplier": Vector3.ONE}

func cancel(identity: Dictionary) -> void:
	if not _event.is_empty() and identity == _event.presentation_identity:
		_stop()

func clear() -> void:
	_stop()
	_latch.clear()
	# Run watermarks intentionally survive clear: an old reset/unload callback
	# must never admit a late cue from the retired attempt.

func set_intent(mapped_direction: Variant) -> void:
	# Host feeds the resolved native FaceAxis (null on release/focus loss).
	if mapped_direction == null:
		_latch.clear()
	elif typeof(mapped_direction) == TYPE_INT and mapped_direction in range(4):
		if (_active and _active_intent.axis != mapped_direction) or (not _latch.is_empty() and _latch.axis != mapped_direction):
			_stop()
			_latch.clear()

func support_pivot_offset(half_extent: float = 0.5) -> Vector3:
	return Event.pivot(_event, half_extent) if _active else Vector3.ZERO

func _stop() -> void:
	_epoch += 1
	_active = false
	_done = false
	_blocked = false
	_event.clear()
	_active_intent.clear()
	_return.clear()
	_elapsed = 0.0
