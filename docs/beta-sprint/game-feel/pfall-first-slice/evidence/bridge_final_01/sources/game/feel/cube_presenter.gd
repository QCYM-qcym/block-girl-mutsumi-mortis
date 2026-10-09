extends RefCounted
## One writer for the real actor. Never grants movement or changes Runtime state.
var _actor: Node3D
var _fall: RefCounted
var _landing: RefCounted
var _projection: Callable
var _finish: Callable
var _base := Transform3D.IDENTITY
var _source := Transform3D.IDENTITY
var _target := Transform3D.IDENTITY
var _path_offset := Vector3.ZERO
var _presentation: Dictionary = {}
var _token: Dictionary = {}
var _started: Dictionary = {}
var _phase := "IDLE"
var _elapsed := 0.0
var _paused := false
var _finish_sent := false
var _epoch := 0
var _seen: Dictionary = {}
var _roll_pivot := Vector3.ZERO
var _roll_axis := Vector3.ZERO
const ROLL_DURATION := 0.24

func bind(actor: Node3D, fall: RefCounted, landing: RefCounted, projection: Callable, finish_transition: Callable) -> void:
	clear()
	_actor = actor
	_fall = fall
	_landing = landing
	_projection = projection
	_finish = finish_transition
	_base = actor.transform
	_seen.clear()
	_paused = false

func sync_pose(pose: Dictionary) -> void:
	_base = _projection.call(pose.duplicate(true))
	if _phase == "IDLE": _write(_base)

func consume_event(event: Dictionary) -> Dictionary:
	if event.get("schema_version") != 1 or event.get("contract_version") != "game_feel.event.v1":
		return _failure("Expected versioned Runtime presentation event.")
	var key := str([event.get("session_id"),event.get("level_run_id"),event.get("event_id")])
	if _seen.has(key): return {"ok":true,"ignored":true,"issues":[]}
	_seen[key] = true
	var identity: Variant = event.get("presentation_identity")
	if event.get("semantic") == "ANIMATION_INTERRUPTED":
		if identity is Dictionary and identity == _presentation: clear()
		return {"ok":true,"issues":[]}
	if event.get("semantic") == "MOVE_APPLIED_NORMAL": return _consume_roll(event)
	if event.get("semantic") != "PERSPECTIVE_FALL_APPLIED":
		return {"ok":true,"ignored":true,"issues":[]}
	if event.get("phase") == "STARTED":
		var source: Transform3D = _projection.call(event.source_pose.duplicate(true))
		var target: Transform3D = _projection.call(event.target_pose.duplicate(true))
		var points: Variant = event.get("authorized_path_points2")
		if not points is Array or points.size() < 2 or not points[0] is Vector3i or not points[-1] is Vector3i:
			return _failure("Missing canonical actor-center path.")
		var offset := source.origin - Vector3(points[0])*0.5
		if not (Vector3(points[-1])*0.5+offset).is_equal_approx(target.origin):
			return _failure("Authorized path endpoint does not match the projected formal target.")
		# Validate with the same Owner sampler before replacing a live motion.
		var staged: RefCounted = _fall.get_script().new()
		staged.parameters = _fall.parameters.duplicate(true)
		var begin: Dictionary = staged.begin(event)
		if not begin.ok: return begin
		clear()
		_fall = staged
		_presentation = event.presentation_identity.duplicate(true)
		_token = event.transition_identity.duplicate(true)
		_started = event.duplicate(true)
		_source = source
		_target = target
		_path_offset = offset
		_phase = "FALL"
		_apply_sample(_fall.sample(0.0),_source.basis,_source.origin)
		return {"ok":true,"issues":[]}
	if event.get("phase") == "COMMITTED":
		if _phase != "FALL" or identity != _presentation or event.get("transition_identity") != _token:
			return {"ok":true,"ignored":true,"issues":[]}
		var committed := event.duplicate(true)
		if not committed.has("source_frame") and _started.has("source_frame"):
			committed.source_frame = _started.source_frame.duplicate(true)
		var begin: Dictionary = _landing.begin(committed)
		if not begin.ok: return begin
		_fall.cancel(_presentation)
		_base = _projection.call(event.target_pose.duplicate(true))
		_phase = "LANDING"
		_elapsed = 0.0
		_epoch += 1
		_apply_sample(_landing.sample(0.0),_base.basis,_base.origin)
		return {"ok":true,"issues":[]}
	return _failure("Unexpected Fall lifecycle phase.")

func _consume_roll(event: Dictionary) -> Dictionary:
	if event.get("phase") == "COMMITTED":
		if _phase != "ROLL" or event.get("presentation_identity") != _presentation or event.get("transition_identity") != _token:
			return {"ok":true,"ignored":true,"issues":[]}
		_base = _projection.call(event.target_pose.duplicate(true))
		clear()
		return {"ok":true,"issues":[]}
	if event.get("phase") != "STARTED": return _failure("Unexpected ordinary Roll lifecycle phase.")
	var result: Variant = event.get("result")
	var frame: Variant = event.get("source_frame")
	if not result is Dictionary or result.get("status") != 0 or result.get("changed") != true or not event.get("presentation_identity") is Dictionary or not event.get("transition_identity") is Dictionary or not frame is Dictionary or not frame.get("normal") is Vector3i:
		return _failure("Ordinary Roll requires an explicitly accepted native result and frame.")
	var source: Transform3D = _projection.call(event.source_pose.duplicate(true))
	var target: Transform3D = _projection.call(event.target_pose.duplicate(true))
	var normal := Vector3(frame.normal)
	var displacement := target.origin-source.origin
	if not is_equal_approx(normal.length(),1.0) or not is_equal_approx(displacement.length(),1.0) or not is_zero_approx(normal.dot(displacement)):
		return _failure("Ordinary display Roll requires adjacent coplanar formal actor centers.")
	clear()
	_source=source
	_target=target
	_roll_pivot=(source.origin+target.origin)*0.5-normal*0.5
	_roll_axis=normal.cross(displacement).normalized()
	_presentation=event.presentation_identity.duplicate(true)
	_token=event.transition_identity.duplicate(true)
	_phase="ROLL"
	_write(source)
	return {"ok":true,"issues":[]}

func tick(delta: float) -> void:
	if _paused or _phase == "IDLE" or not is_finite(delta) or delta < 0.0: return
	_elapsed += delta
	if _phase == "ROLL":
		var progress := smoothstep(0.0,ROLL_DURATION,_elapsed)
		var rotation := Basis(_roll_axis,progress*PI*0.5)
		_write(Transform3D(rotation*_source.basis,_roll_pivot+rotation*(_source.origin-_roll_pivot)))
		if _elapsed >= ROLL_DURATION and not _finish_sent:
			_write(_target)
			_finish_sent=true
			_finish.call(_token.duplicate(true))
		return
	var captured_epoch := _epoch
	var sampled: Dictionary = _fall.sample(_elapsed) if _phase == "FALL" else _landing.sample(_elapsed)
	if not sampled.active or sampled.identity != _presentation: return
	_apply_sample(sampled,_source.basis if _phase == "FALL" else _base.basis,_base.origin)
	if not sampled.motion_done: return
	if _phase == "FALL":
		if not _finish_sent:
			_finish_sent = true
			var captured_token := _token.duplicate(true)
			_finish.call(captured_token)
			# Finish may synchronously commit, Reset, unload or launch another motion.
			# Nothing from this sample may write/clear after that callback.
		return
	if _epoch == captured_epoch:
		_landing.cancel(_presentation)
		_phase = "IDLE"
		_presentation = {}
		_token = {}
		_started = {}
		_elapsed = 0.0
		_write(_base)

func _apply_sample(sampled: Dictionary, authoritative_basis: Basis, fallback_origin: Vector3) -> void:
	var origin := fallback_origin
	if sampled.position is Vector3: origin = sampled.position + _path_offset
	var basis := Basis(sampled.rotation_offset) * Basis.from_scale(sampled.scale_multiplier) * authoritative_basis
	_write(Transform3D(basis,origin))

func _write(value: Transform3D) -> void:
	if is_instance_valid(_actor): _actor.transform = value

func set_paused(paused: bool) -> void:
	_paused = paused

func clear() -> void:
	_epoch += 1
	var previous := _presentation.duplicate(true)
	_presentation = {}
	_token = {}
	_started = {}
	_phase = "IDLE"
	_elapsed = 0.0
	_finish_sent = false
	if _fall != null: _fall.cancel(previous)
	if _landing != null: _landing.cancel(previous)
	_write(_base)

func snapshot() -> Dictionary:
	return {"phase":_phase,"elapsed":_elapsed,"presentation_identity":_presentation.duplicate(true),"transition_identity":_token.duplicate(true),"finish_sent":_finish_sent,"paused":_paused}

static func _failure(message: String) -> Dictionary:
	return {"ok":false,"issues":[{"path":"presenter","message":message}]}
