extends RefCounted
## One writer for the real actor. Never grants movement or changes Runtime state.
const State = preload("res://game/feel/animation/fall_landing/fall_visual_state.gd")
const EdgeEvent = preload("res://game/feel/animation/edge_recoil/edge_event.gd")
var _actor: Node3D
var _fall: RefCounted
var _landing: RefCounted
var _edge: RefCounted
var _edge_reduced := false
var _edge_pivot := Vector3.ZERO
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
var _scope: Dictionary = {}
var _roll_pivot := Vector3.ZERO
var _roll_axis := Vector3.ZERO
var _reduced_motion := false
const ROLL_DURATION := 0.24

func set_reduced_motion(value: bool) -> void:
	# Select the next accepted motion; never mutate the active frozen sampler.
	_reduced_motion=value

func reduced_motion_enabled() -> bool: return _reduced_motion

func bind_edge(edge: RefCounted) -> void:
	if _edge != null: _edge.clear()
	_edge=edge

func release_edge_intent() -> void:
	if _edge != null: _edge.set_intent(null)

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

func bind_scope(scope: Dictionary) -> void:
	var next: Dictionary={}
	if scope.has_all(["session_id","level_run_id","generation"]):
		for key in ["session_id","level_run_id","generation"]: next[key]=scope[key]
	if next!=_scope:
		clear()
		if _edge != null: _edge.clear()
	_scope=next

func sync_pose(pose: Dictionary) -> Dictionary:
	var projected: Dictionary=_project(pose)
	if not projected.ok: return projected
	_base = projected.transform
	if _phase == "IDLE": _write(_base)
	return {"ok":true,"issues":[]}

func _project(pose: Dictionary) -> Dictionary:
	if not State.pose_valid(pose): return _failure("Invalid formal pose.")
	var value: Variant=_projection.call(pose.duplicate(true))
	if not value is Dictionary or value.get("ok")!=true or not value.get("transform") is Transform3D:
		return _failure("Formal projection failed; existing actor pose preserved.")
	return value

func _current(identity: Variant) -> bool:
	if not identity is Dictionary or _scope.is_empty(): return false
	for key in ["session_id","level_run_id","generation"]:
		if identity.get(key)!=_scope[key]: return false
	return true

func consume_event(event: Dictionary) -> Dictionary:
	if event.get("schema_version") != 1 or event.get("contract_version") != "game_feel.event.v1":
		return _failure("Expected versioned Runtime presentation event.")
	if event.get("phase") in ["STARTED","COMMITTED","REJECTED"] and not _current(event.get("presentation_identity")):
		return {"ok":true,"ignored":true,"issues":[]}
	var key := str([event.get("session_id"),event.get("level_run_id"),event.get("event_id")])
	if _seen.has(key): return {"ok":true,"ignored":true,"issues":[]}
	_seen[key] = true
	var identity: Variant = event.get("presentation_identity")
	if event.get("semantic") == "ANIMATION_INTERRUPTED":
		if identity is Dictionary and identity == _presentation: clear()
		return {"ok":true,"issues":[]}
	if event.get("semantic") == "MOVE_APPLIED_NORMAL": return _consume_roll(event)
	if event.get("semantic") == "MOVE_REJECTED_EDGE": return _consume_edge(event)
	if event.get("semantic") != "PERSPECTIVE_FALL_APPLIED":
		return {"ok":true,"ignored":true,"issues":[]}
	if event.get("phase") == "STARTED":
		# Validate with the same Owner sampler before projecting/replacing motion.
		var staged: RefCounted = _fall.get_script().new()
		staged.parameters = _fall.parameters.duplicate(true)
		staged.parameters.reduced_motion = _reduced_motion
		var begin: Dictionary = staged.begin(event)
		if not begin.ok: return begin
		var source_result: Dictionary=_project(event.source_pose)
		var target_result: Dictionary=_project(event.target_pose)
		if not source_result.ok or not target_result.ok: return _failure("Missing formal source or target projection.")
		var source: Transform3D = source_result.transform
		var target: Transform3D = target_result.transform
		var points: Variant = event.get("authorized_path_points2")
		if not points is Array or points.size() < 2 or not points[0] is Vector3i or not points[-1] is Vector3i:
			return _failure("Missing canonical actor-center path.")
		if not (Vector3(points[0])*0.5).is_equal_approx(source.origin) or not (Vector3(points[-1])*0.5).is_equal_approx(target.origin):
			return _failure("Canonical path endpoints must equal independently projected formal centers.")
		clear()
		_fall = staged
		_presentation = event.presentation_identity.duplicate(true)
		_token = event.transition_identity.duplicate(true)
		_started = event.duplicate(true)
		_source = source
		_target = target
		_path_offset = Vector3.ZERO
		_phase = "FALL"
		_apply_sample(_fall.sample(0.0),_source.basis,_source.origin)
		return {"ok":true,"issues":[]}
	if event.get("phase") == "COMMITTED":
		if _phase != "FALL" or identity != _presentation or event.get("transition_identity") != _token:
			return {"ok":true,"ignored":true,"issues":[]}
		if event.get("source_pose")!=_started.source_pose or event.get("target_pose")!=_started.target_pose: return _failure("Committed Fall endpoints differ from captured STARTED.")
		_landing.parameters.reduced_motion = _fall.parameters.reduced_motion
		var target_result: Dictionary=_project(event.target_pose)
		if not target_result.ok: return target_result
		var committed := event.duplicate(true)
		if not committed.has("source_frame") and _started.has("source_frame"):
			committed.source_frame = _started.source_frame.duplicate(true)
		var begin: Dictionary = _landing.begin(committed)
		if not begin.ok: return begin
		_fall.cancel(_presentation)
		_base = target_result.transform
		_phase = "LANDING"
		_elapsed = 0.0
		_epoch += 1
		_apply_sample(_landing.sample(0.0),_base.basis,_base.origin)
		return {"ok":true,"issues":[]}
	return _failure("Unexpected Fall lifecycle phase.")

func _consume_edge(event: Dictionary) -> Dictionary:
	if _edge == null or _phase in ["ROLL","FALL","LANDING"]:
		return {"ok":true,"ignored":true,"issues":[]}
	var issues: Array=EdgeEvent.validate(event)
	if not issues.is_empty(): return {"ok":false,"issues":issues}
	var projected: Dictionary=_project(event.source_pose)
	if not projected.ok: return projected
	var begin: Dictionary=_edge.begin(event)
	# The Owner's admission/latch retains active progress and rejects held repeats.
	if not begin.ok: return {"ok":true,"ignored":true,"issues":[]}
	clear()
	_base=projected.transform
	_source=_base
	_presentation=event.presentation_identity.duplicate(true)
	_edge_pivot=_edge.support_pivot_offset()
	_edge_reduced=_reduced_motion
	_phase="EDGE"
	_write(_base)
	return {"ok":true,"issues":[]}

func _consume_roll(event: Dictionary) -> Dictionary:
	if event.get("phase") == "COMMITTED":
		if _phase != "ROLL" or event.get("presentation_identity") != _presentation or event.get("transition_identity") != _token:
			return {"ok":true,"ignored":true,"issues":[]}
		if event.get("source_pose")!=_started.source_pose or event.get("target_pose")!=_started.target_pose: return _failure("Committed Roll endpoints differ from captured STARTED.")
		var projected: Dictionary=_project(event.target_pose)
		if not projected.ok: return projected
		_base = projected.transform
		clear()
		return {"ok":true,"issues":[]}
	if event.get("phase") != "STARTED": return _failure("Unexpected ordinary Roll lifecycle phase.")
	var result: Variant = event.get("result")
	var frame: Variant = event.get("source_frame")
	var identity: Variant=event.get("presentation_identity")
	var token: Variant=event.get("transition_identity")
	if not result is Dictionary or result.get("status") != 0 or result.get("changed") != true or not State.identity_valid(identity) or not token is Dictionary or not State.frame_valid(frame) or not State.pose_valid(event.get("source_pose")) or not State.pose_valid(event.get("target_pose")):
		return _failure("Ordinary Roll requires an explicitly accepted native result and frame.")
	if not token.get("transaction_id") is int or token.transaction_id<1 or not token.get("is_global") is bool or result.get("previous_state",{}).get("player")!=event.source_pose or result.get("next_state",{}).get("player")!=event.target_pose:
		return _failure("Ordinary Roll native snapshots/token do not match.")
	for key in ["session_id","level_run_id","generation"]:
		if token.get(key)!=identity[key]: return _failure("Ordinary token identity mismatch.")
	var source_result: Dictionary=_project(event.source_pose)
	var target_result: Dictionary=_project(event.target_pose)
	if not source_result.ok or not target_result.ok: return _failure("Ordinary projection failed.")
	var source: Transform3D = source_result.transform
	var target: Transform3D = target_result.transform
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
	_started=event.duplicate(true)
	_phase="ROLL"
	_write(source)
	return {"ok":true,"issues":[]}

func tick(delta: float) -> void:
	if _paused or _phase == "IDLE" or not is_finite(delta) or delta < 0.0: return
	_elapsed += delta
	if _phase == "EDGE":
		var captured_epoch := _epoch
		var sample: Dictionary=_edge.sample(_elapsed)
		if captured_epoch != _epoch or sample.identity != _presentation: return
		if sample.motion_done:
			clear()
		elif sample.active:
			var rotation := Basis.IDENTITY if _edge_reduced else Basis(sample.rotation_offset)
			_write(Transform3D(rotation*_source.basis,_source.origin+_edge_pivot-rotation*_edge_pivot))
		return
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
	if _edge != null: _edge.cancel(previous)
	_write(_base)

func dispose() -> void:
	clear()
	if _edge != null: _edge.clear()
	_actor=null
	_projection=Callable()
	_finish=Callable()

func snapshot() -> Dictionary:
	return {"phase":_phase,"elapsed":_elapsed,"presentation_identity":_presentation.duplicate(true),"transition_identity":_token.duplicate(true),"finish_sent":_finish_sent,"paused":_paused}

static func _failure(message: String) -> Dictionary:
	return {"ok":false,"issues":[{"path":"presenter","message":message}]}
