extends RefCounted
## Private composition: consumers receive snapshots and identity-checked completion.
const Session = preload("res://foundation/runtime/runtime_session.gd")
const Codec = preload("res://foundation/level/level_codec.gd")
const Schema = preload("res://foundation/game_feel/schema.gd")
const Rules = preload("res://foundation/rules/rule_records.gd")
const Types = preload("res://foundation/contracts/foundation_types.gd")
const Mapper = preload("res://foundation/runtime/input_mapper.gd")
const View = preload("res://foundation/game_feel/view_contract.gd")
const Derived = preload("res://foundation/rules/derived_state_resolver.gd")
const Geometry = preload("res://foundation/spatial/surface_geometry.gd")
signal game_feel_event(event: Dictionary)
signal transition_started(result: Dictionary, transaction_id: int, generation: int, is_global: bool)
signal committed(state: Dictionary)
signal feedback(result: Dictionary)
var _session = Session.new()
var _session_id := Crypto.new().generate_random_bytes(16).hex_encode()
var _run_id := ""
var _event_serial := 0
var _attempt_serial := 0
var _attempt: Dictionary = {}
var _pending: Dictionary = {}
var _decoration: Dictionary = {}
var _paused := false
var _lifecycle := false

func _init() -> void:
	_session.transition_started.connect(_on_started)
	_session.committed.connect(_on_committed)
	_session.feedback.connect(_on_feedback)

func load_level(level: Dictionary) -> Dictionary:
	var old := _take_presentations()
	_lifecycle = true
	_run_id = Crypto.new().generate_random_bytes(16).hex_encode()
	var loaded: Dictionary
	if not Schema.enabled(level):
		loaded = {"ok":false,"issues":[Rules.issue(Types.ValidationCode.VERSION_MISMATCH,"level","Facade requires explicit game-feel opt-in version.")]}
	else:
		var encoded := Codec.encode(level)
		loaded = _session.load_level(level) if encoded.ok else {"ok":false,"issues":encoded.issues}
	if not loaded.ok: _session.unload()
	_lifecycle = false
	_emit_interruptions(old,"RELOAD")
	return loaded

func get_state() -> Dictionary: return _session.state.duplicate(true) if _session.ready else {}
func get_level() -> Dictionary: return _session.level.duplicate(true) if _session.ready else {}
func get_commit_count() -> int: return _session.commit_count
func get_generation() -> int: return _session.generation
func is_idle() -> bool: return _session.ready and _pending.is_empty()
func is_loaded() -> bool: return _session.ready
func is_paused() -> bool: return _paused
func set_paused(value: bool) -> void: _paused = value

func get_presentation_scope() -> Dictionary:
	var scope := {"session_id":_session_id,"level_run_id":_run_id,"generation":_session.generation}
	scope.make_read_only()
	return scope

func get_pending_identity(token: int, generation: int, is_global: bool) -> Dictionary:
	# Resolve only a captured native start signal, never an action/global-kind guess.
	var key := str(generation)+":"+str(token)
	if not _pending.has(key): return {}
	var identity: Dictionary = _pending[key].transition_identity
	if identity.is_global != is_global or not _valid_identity(identity): return {}
	var copy := identity.duplicate(true)
	copy.make_read_only()
	return copy

func request_action(action: Dictionary) -> Dictionary:
	_attempt_serial += 1
	if not _session.ready: return _session.request_action(action)
	var attempt := {"id":_attempt_serial,"before":get_state(),"action":action.duplicate(true),"sent":false}
	_attempt = attempt
	var result: Dictionary
	if _paused or _lifecycle:
		result = Rules.rejected(get_state(),action,Types.ValidationCode.GLOBAL_TRANSITION_BUSY)
		_on_feedback(result)
	else:
		result = _session.request_action(action)
	if _attempt.get("id") == attempt.id: _attempt = {}
	return result.duplicate(true)

func request_move(screen_direction: Vector2) -> Dictionary:
	# Fixed-view cardinal adaptation is observation only; Runtime grants permission.
	var state := get_state()
	var snapshot := Derived.snapshot(get_level(),state)
	if snapshot.ok:
		var face := Geometry.face_id(state.player.location.cube_id,state.player.location.face)
		for anchor in snapshot.value.anchors:
			if anchor.face_id == face:
				var mapped := _map_fixed_move(anchor.frame,state.camera_quadrant,screen_direction)
				if mapped.ok: return request_action(mapped.action)
	return request_action({})

static func _map_fixed_move(frame: Dictionary, quadrant: int, direction: Vector2) -> Dictionary:
	var basis := View.basis(quadrant)
	var mapped := Mapper.map_move(frame,basis,direction)
	# Retain generic validation, analog/diagonal input and horizontal tie semantics.
	if not mapped.ok or direction.x != 0.0: return mapped
	var horizontal := Mapper.map_move(frame,basis,Vector2.RIGHT)
	var vertical := Mapper.map_move(frame,basis,Vector2.DOWN)
	if horizontal.action.face_axis % 2 != vertical.action.face_axis % 2: return mapped
	# Independently quantized diagonal ties can give both keyboard pairs one axis
	# family. Keep A/D; W/S use the remaining family, signed by exact View projection.
	var axes := [frame.u,frame.v,-frame.u,-frame.v]
	var down: int = (horizontal.action.face_axis + 1) % 4
	if View.project(axes[down],quadrant).y < 0: down = (down + 2) % 4
	mapped.action.face_axis = down if direction.y > 0.0 else (down + 2) % 4
	return mapped

func finish_transition(identity: Dictionary) -> Dictionary:
	if _paused or _lifecycle or not _valid_identity(identity): return {"ignored":true,"transition":null}
	var key := _identity_key(identity)
	if not _pending.has(key) or _pending[key].transition_identity != identity: return {"ignored":true,"transition":null}
	return _session.finish_global(identity.transaction_id,identity.generation) if identity.is_global else _session.finish_local(identity.transaction_id,identity.generation)

func reset() -> void:
	var old := _take_presentations()
	_lifecycle = true
	_session.reset()
	_lifecycle = false
	_emit_interruptions(old,"RESET")

func interrupt(reason: String) -> void:
	if not reason in ["CANCEL","UNLOAD","QUIT"]: return
	var old := _take_presentations()
	_lifecycle = true
	if reason == "CANCEL": _session.cancel_pending()
	else: _session.unload()
	_lifecycle = false
	_emit_interruptions(old,reason)

func _on_started(result: Dictionary, token: int, generation: int, global: bool) -> void:
	var desc: Dictionary = _session.game_feel_description(result.previous_state,result.action,result)
	var presentation: Variant = null
	if desc.get("semantic") in ["MOVE_APPLIED_NORMAL","PERSPECTIVE_FALL_APPLIED"]:
		presentation = _presentation(generation,_attempt.id)
	var identity := {"session_id":_session_id,"level_run_id":_run_id,"generation":generation,"transaction_id":token,"is_global":global}
	var event := _event(result,desc,"STARTED" if presentation != null else "FEEDBACK",presentation,identity)
	var old := _decoration
	_decoration = {}
	_pending[_identity_key(identity)] = event.duplicate(true)
	_attempt.sent = true
	if not old.is_empty(): _emit_interruptions([old],"CANCEL")
	# An interruption observer may reset/reload. Do not publish an obsolete start.
	if not _pending.has(_identity_key(identity)): return
	var published := event.duplicate(true)
	# Non-movement proposals remain neutral FEEDBACK. Their completion bridge
	# consumes native transition_started, not a presentation event.
	if presentation == null: published.transition_identity = null
	_emit(published)
	if _pending.has(_identity_key(identity)): transition_started.emit(result.duplicate(true),token,generation,global)

func _on_committed(state: Dictionary) -> void:
	var captured_generation: int = _session.generation
	var captured_run := _run_id
	# Local accepted result is the exact immutable native commit proposal. It
	# cannot be changed while pending. Load/reset have no matching identity.
	var completed: Dictionary = {}
	for key in _pending.keys():
		var event: Dictionary = _pending[key]
		if event.transition_identity.generation == _session.generation and (event.result.next_state == state or (event.transition_identity.is_global and _session.context.global_transition_state == Types.GlobalTransitionState.IDLE)):
			completed = event.duplicate(true)
			_pending.erase(key)
			break
	if not completed.is_empty() and completed.presentation_identity != null:
		completed.phase = "COMMITTED"
		_emit(completed)
	if _run_id == captured_run and _session.generation == captured_generation and _session.state == state:
		committed.emit(state.duplicate(true))

func _on_feedback(result: Dictionary) -> void:
	var captured_generation: int = _session.generation
	var captured_run := _run_id
	var captured_state := get_state()
	if not _attempt.is_empty() and not _attempt.sent:
		# Applied no-op is feedback; changed acceptance already emitted STARTED.
		var desc: Dictionary = _session.game_feel_description(_attempt.before,_attempt.action,result)
		var edge: bool = desc.get("semantic") == "MOVE_REJECTED_EDGE"
		var event := _event(result,desc,"REJECTED" if edge else "FEEDBACK",_presentation(_session.generation,_attempt.id) if edge else null,null)
		_attempt.sent = true
		if edge: _decoration = event.duplicate(true)
		_emit(event)
	if _run_id == captured_run and _session.generation == captured_generation and get_state() == captured_state:
		feedback.emit(result.duplicate(true))

func _event(result: Dictionary, desc: Dictionary, phase: String, presentation: Variant, identity: Variant) -> Dictionary:
	var before: Dictionary = result.get("previous_state",{})
	var source: Variant = before.get("player")
	var target: Variant = result.next_state.get("player") if result.status == 0 and result.next_state is Dictionary else null
	var event := {"schema_version":1,"contract_version":"game_feel.event.v1","semantic":desc.get("semantic","ACTION_FEEDBACK"),"phase":phase,"event_id":0,"session_id":_session_id,"level_run_id":_run_id,"attempt_id":_attempt.get("id",_attempt_serial),"presentation_identity":presentation,"transition_identity":identity,"result":result.duplicate(true),"reason_category":desc.get("reason_category","UNCLASSIFIED_REJECTION"),"source_pose":source,"target_pose":target,"source_face":source.location if source != null else null,"target_face":target.location if target != null else null,"world_id":source.location.layer if source != null else null,"camera_quadrant":before.get("camera_quadrant"),"authoritative_final_orientation":target.orientation if target != null else null,"intended_move_direction":result.action.face_axis if result.action.get("kind") == 0 and result.action.get("face_axis") in range(4) else null,"interruption_reason":null}
	# Version only the newly authorized geometry. Completion/interruption copy
	# this captured envelope; ordinary Roll and neutral feedback remain v1.
	if event.semantic == "PERSPECTIVE_FALL_APPLIED" and Schema.curved(_session.level):
		event.schema_version = 2
		event.contract_version = "game_feel.event.v2"
	if desc.has("source_frame"): event["source_frame"] = desc.source_frame.duplicate(true)
	for field in desc.get("motion",{}): event[field] = desc.motion[field].duplicate(true) if desc.motion[field] is Dictionary or desc.motion[field] is Array else desc.motion[field]
	return event.duplicate(true)

func _presentation(generation: int, attempt: int) -> Dictionary:
	return {"session_id":_session_id,"level_run_id":_run_id,"generation":generation,"attempt_id":attempt}
func _identity_key(identity: Dictionary) -> String:
	return str(identity.generation)+":"+str(identity.transaction_id)
func _valid_identity(identity: Dictionary) -> bool:
	if identity.size() != 5: return false
	for field in ["session_id","level_run_id","generation","transaction_id","is_global"]:
		if not identity.has(field): return false
	return typeof(identity.session_id) == TYPE_STRING and typeof(identity.level_run_id) == TYPE_STRING and typeof(identity.generation) == TYPE_INT and typeof(identity.transaction_id) == TYPE_INT and typeof(identity.is_global) == TYPE_BOOL and identity.session_id == _session_id and identity.level_run_id == _run_id and identity.generation == _session.generation
func _take_presentations() -> Array:
	var old: Array = []
	for event in _pending.values():
		if event.presentation_identity != null: old.append(event.duplicate(true))
	_pending.clear()
	if not _decoration.is_empty(): old.append(_decoration.duplicate(true))
	_decoration = {}
	return old
func _emit_interruptions(old: Array, reason: String) -> void:
	for event in old:
		event.semantic = "ANIMATION_INTERRUPTED"
		event.phase = "INTERRUPTED"
		event.interruption_reason = reason
		event.target_pose = null
		event.target_face = null
		event.authoritative_final_orientation = null
		_emit(event)
func _emit(event: Dictionary) -> void:
	_event_serial += 1
	event.event_id = _event_serial
	_freeze(event)
	game_feel_event.emit(event)
static func _freeze(value: Variant) -> void:
	if value is Dictionary:
		for child in value.values(): _freeze(child)
		value.make_read_only()
	elif value is Array:
		for child in value: _freeze(child)
		value.make_read_only()
