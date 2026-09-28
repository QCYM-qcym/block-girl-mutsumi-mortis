extends Node3D
## Thin manual host: semantic input is submitted to RuntimeSession, and every
## pose is synchronized from committed state through PrototypePresenter.
const S = preload("res://tools/foundation/authoring_acceptance/wire_schemas.gd")
const Loader = preload("res://tools/foundation/authoring_acceptance/canonical_loader.gd")
const Session = preload("res://foundation/runtime/runtime_session.gd")
const Presenter = preload("res://foundation/runtime/prototype_presenter.gd")
const InputMapper = preload("res://foundation/runtime/input_mapper.gd")
const StateKey = preload("res://foundation/contracts/state_key.gd")
const Types = preload("res://foundation/contracts/foundation_types.gd")
const Goal = preload("res://foundation/rules/goal_evaluator.gd")

const TRANSITION_SECONDS := 0.22

var _runtime: Dictionary = {}
var _loader := Loader.new()
var _action_records: Array[Dictionary] = []
var _ignored_visual_callbacks := 0
var _transition_starts := 0
var _last_visual_issues: Array = []
var _last_input_result: Dictionary = {}
var _active_transition: Dictionary = {}
var _pending_record_index := -1

func load_artifact(snapshot_ref: Dictionary, canonical_ref: Dictionary) -> Dictionary:
	_clear_installed()
	return _install(_loader.load_artifact(snapshot_ref,canonical_ref))

func load_run(run_root: String) -> Dictionary:
	_clear_installed()
	return _install(_loader.load_run(run_root))

func _install(loaded: Dictionary) -> Dictionary:
	if not loaded.ok:
		return loaded
	var new_session = Session.new()
	var initialized: Dictionary = new_session.load_level(loaded.value.level)
	if not initialized.ok:
		_loader._clear()
		return {"ok": false, "value": null, "issues": initialized.issues.duplicate(true)}
	var view = Presenter.new()
	add_child(view, false, Node.INTERNAL_MODE_BACK)
	var synchronized: Dictionary = view.sync_state(new_session.level, new_session.state)
	if not synchronized.ok:
		view.queue_free()
		new_session.reset()
		_loader._clear()
		return {"ok": false, "value": null, "issues": synchronized.issues.duplicate(true)}
	_runtime = _encapsulate(new_session, view)
	_action_records.clear()
	return S.success({"loaded_hash": loaded.value.loaded_hash,
		"snapshot_identity": loaded.value.snapshot_identity.duplicate(true),
		"canonical_digest": loaded.value.canonical_digest, "run_identity":loaded.value.run_identity.duplicate(true), "input_refs":loaded.value.input_refs.duplicate(true)})

func submit_action(action: Dictionary) -> Dictionary:
	if not is_ready():
		return S.failure("HOST_NOT_READY", "A verified canonical level must be loaded first")
	var before := StateKey.build(_observe().level, _observe().state)
	var index := _action_records.size()
	_action_records.append({"before_statekey": before.key if before.ok else "",
		"action": action.duplicate(true), "result": null, "token": 0, "generation": _observe().generation,
		"is_global": false, "after_statekey": "", "commit_count": commit_count(),
		"completion": null})
	_pending_record_index = index
	var result: Dictionary = _runtime.action.call(action.duplicate(true))
	_pending_record_index = -1
	if not result.has("status"):
		_action_records.remove_at(index)
		_last_input_result = result.duplicate(true)
		return result
	var record: Dictionary = _action_records[index]
	record.result = result.duplicate(true)
	if _active_transition.is_empty():
		_record_committed_endpoint(index)
	_last_input_result = result.duplicate(true)
	return result

func request_move(screen_direction: Vector2, camera_basis: Basis) -> Dictionary:
	if not is_ready():
		return S.failure("HOST_NOT_READY", "A verified canonical level must be loaded first")
	var mapped: Dictionary = InputMapper.map_move(_runtime.input_frame.call(), camera_basis, screen_direction)
	if not mapped.ok:
		return mapped
	return submit_action(mapped.action)

func request_rotation(intent: int, camera_basis: Basis) -> Dictionary:
	if not is_ready():
		return S.failure("HOST_NOT_READY", "A verified canonical level must be loaded first")
	var layer: int = _observe().state.player.location.layer
	var target: Dictionary = {}
	for world in _observe().level.worlds:
		if world.layer == layer:
			target = world.duplicate(true)
			break
	if target.is_empty():
		return S.failure("RUNTIME_STATE_INVALID", "Current player world is absent from the canonical level")
	var mapped: Dictionary = InputMapper.map_rotation(intent, camera_basis, target)
	if not mapped.ok:
		return mapped
	return submit_action(mapped.action)

func reset_run() -> Dictionary:
	if not is_ready():
		return S.failure("HOST_NOT_READY", "A verified canonical level must be loaded first")
	var before := StateKey.build(_observe().level, _observe().state)
	_runtime.reset.call()
	var key := StateKey.build(_observe().level, _observe().state)
	var after_key: String = key.key if key.ok else ""
	var result := {"ok": key.ok, "statekey": after_key, "commit_count": commit_count()}
	_action_records.append({"before_statekey": before.key if before.ok else "",
		"action": {"kind": "RESET"}, "result": result.duplicate(true), "token": 0,
		"generation": _observe().generation, "is_global": false, "after_statekey": after_key,
		"commit_count": commit_count(), "completion": null})
	return S.success(result)

func evaluate_goal() -> Dictionary:
	if not is_ready():
		return S.failure("HOST_NOT_READY", "A verified canonical level must be loaded first")
	return Goal.is_goal(_observe().level.duplicate(true), _observe().state.duplicate(true))

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or not is_ready():
		return
	var camera := get_viewport().get_camera_3d()
	var camera_basis: Basis = camera.global_basis if camera != null else Basis.IDENTITY
	var direction := Vector2.ZERO
	match event.physical_keycode:
		KEY_W: direction = Vector2(0, -1)
		KEY_A: direction = Vector2(-1, 0)
		KEY_S: direction = Vector2(0, 1)
		KEY_D: direction = Vector2(1, 0)
		KEY_Q:
			_last_input_result = request_rotation(Types.RotationIntent.TURN_LEFT, camera_basis)
			return
		KEY_E:
			_last_input_result = request_rotation(Types.RotationIntent.TURN_RIGHT, camera_basis)
			return
		KEY_SPACE:
			_last_input_result = submit_action({"kind": Types.PuzzleActionKind.SHIFT_WORLD})
			return
		KEY_F:
			var transition_id: StringName = &""
			if not _observe().level.face_transitions.is_empty():
				transition_id = _observe().level.face_transitions[0].transition_id
			_last_input_result = submit_action({"kind": Types.PuzzleActionKind.USE_FACE_TRANSITION,
				"transition_id": transition_id})
			return
		KEY_R:
			_last_input_result = reset_run()
			return
	if direction != Vector2.ZERO:
		_last_input_result = request_move(direction, camera_basis)

# Each closure has one fixed capability. Session and the live Tween ticket are
# captured values, never properties, return values, or a string dispatcher.
func _encapsulate(owned_session, view: Node) -> Dictionary:
	var activity := {}
	var lifetime := {"open":true,"frame":view.frame.duplicate(true)}
	var cancel := func() -> void:
		if not lifetime.open: return
		if activity.has("tween") and is_instance_valid(activity.tween):
			activity.tween.kill()
		activity.clear()
		_active_transition.clear()
		view.clear_previews()
	var committed := func(_state: Dictionary) -> void:
		if not lifetime.open: return
		var synced: Dictionary = view.sync_state(owned_session.level, owned_session.state)
		_last_visual_issues = synced.issues.duplicate(true) if not synced.ok else []
		if synced.ok: lifetime.frame = view.frame.duplicate(true)
	var started := func(result: Dictionary, token: int, generation: int, is_global: bool) -> void:
		if not lifetime.open or not activity.is_empty(): return
		_on_transition_started(result, token, generation, is_global)
		var record_index := _pending_record_index
		activity.token = token
		activity.generation = generation
		var animated: Dictionary = view.animate_transition(owned_session.level, result, TRANSITION_SECONDS)
		if not animated.ok:
			_last_visual_issues = animated.issues.duplicate(true)
			return
		activity.tween = animated.tween
		# The completion capability exists only on the actual Tween signal.
		animated.tween.finished.connect(func() -> void:
			if not lifetime.open or activity.is_empty() or activity.token != token or activity.generation != generation or owned_session.generation != generation or activity.tween.is_running():
				_ignored_visual_callbacks += 1
				return
			activity.clear()
			_active_transition.clear()
			view.clear_previews()
			var completion: Dictionary = owned_session.finish_global(token,generation) if is_global else owned_session.finish_local(token,generation)
			if record_index >= 0 and record_index < _action_records.size():
				_action_records[record_index].completion = completion.duplicate(true)
				_record_committed_endpoint(record_index)
		, CONNECT_ONE_SHOT)
	owned_session.transition_started.connect(started)
	owned_session.committed.connect(committed)
	var capabilities := {
		"observe": func() -> Dictionary:
			if not lifetime.open: return {}
			return {"ready":owned_session.ready,"level":owned_session.level.duplicate(true),"state":owned_session.state.duplicate(true),"generation":owned_session.generation,"commit_count":owned_session.commit_count},
		"action": func(action: Dictionary) -> Dictionary:
			if not lifetime.open: return S.failure("HOST_NOT_READY","Runtime capability has been revoked")
			# Host serializes visual presentation; it does not invent a runtime status.
			if not activity.is_empty(): return S.failure("HOST_BUSY","Wait for natural visual completion or reset")
			return owned_session.request_action(action.duplicate(true)).duplicate(true),
		"input_frame": func() -> Dictionary: return lifetime.frame.duplicate(true) if lifetime.open else {},
		"reset": func() -> void:
			if not lifetime.open: return
			cancel.call()
			owned_session.reset(),
		"close": func() -> void:
			if not lifetime.open: return
			cancel.call()
			lifetime.open = false
			lifetime.frame.clear()
			owned_session.transition_started.disconnect(started)
			owned_session.committed.disconnect(committed)
			owned_session.reset()
			view.queue_free()
	}
	capabilities.make_read_only()
	return capabilities

func _observe() -> Dictionary:
	return _runtime.observe.call() if not _runtime.is_empty() else {}

func is_ready() -> bool:
	return not _runtime.is_empty() and _observe().get("ready",false)

func current_state_key() -> Dictionary:
	if not is_ready(): return S.failure("HOST_NOT_READY","No loaded runtime")
	var observed := _observe()
	return StateKey.build(observed.level,observed.state)

func commit_count() -> int:
	return _observe().get("commit_count",0)

func last_result() -> Dictionary:
	return _last_input_result.duplicate(true)

func action_records() -> Array:
	return _action_records.duplicate(true)

func runtime_observation() -> Dictionary:
	return {"ready":is_ready(),"generation":_observe().get("generation",0),
		"transition_starts":_transition_starts,"ignored_visual_callbacks":_ignored_visual_callbacks,
		"presenter_ready":is_ready(),"visual_issues":_last_visual_issues.duplicate(true)}

func _exit_tree() -> void:
	_clear_installed()

func loaded_hash() -> String:
	return _loader.loaded_hash()

func has_active_transition() -> bool:
	return not _active_transition.is_empty()

func transition_status() -> Dictionary:
	if _active_transition.is_empty():
		return {}
	return {"token": _active_transition.token, "generation": _active_transition.generation,
		"is_global": _active_transition.is_global}

func _on_transition_started(_result: Dictionary, token: int, generation: int, is_global: bool) -> void:
	_transition_starts += 1
	_active_transition = {"token":token,"generation":generation,"is_global":is_global}
	if _pending_record_index >= 0:
		var record: Dictionary = _action_records[_pending_record_index]
		record.token = token
		record.generation = generation
		record.is_global = is_global

func on_visual_finished(_token: int, _generation: int, _is_global: bool) -> void:
	# An externally supplied notification is never a completion authority.
	_ignored_visual_callbacks += 1

func _record_committed_endpoint(index: int) -> void:
	if not is_ready() or index < 0 or index >= _action_records.size():
		return
	var key := StateKey.build(_observe().level, _observe().state)
	var record: Dictionary = _action_records[index]
	record.after_statekey = key.key if key.ok else ""
	record.commit_count = commit_count()

func _clear_installed() -> void:
	if not _runtime.is_empty(): _runtime.close.call()
	_active_transition.clear()
	_runtime = {}
	_loader._clear()
	_last_visual_issues.clear()
	_last_input_result.clear()
	_action_records.clear()
	_pending_record_index = -1
