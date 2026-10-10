extends Node
## Owns one isolated Runtime per replay. It never executes rule logic itself.
const Types = preload("res://foundation/parity/parity_types.gd")
const Session = preload("res://foundation/runtime/runtime_session.gd")
const Presenter = preload("res://foundation/runtime/prototype_presenter.gd")
const Records = preload("res://foundation/contracts/contract_records.gd")
const Key = preload("res://foundation/contracts/state_key.gd")
const Goal = preload("res://foundation/rules/goal_evaluator.gd")
const Codec = preload("res://foundation/level/level_codec.gd")
const Feel = preload("res://foundation/game_feel/schema.gd")
const Facade = preload("res://foundation/game_feel/runtime_facade.gd")
const Validator = preload("res://foundation/validation/static_validator.gd")
const Status = Types.ParityStatus
const Mode = Types.ReplayMode
const _DEFAULTS = {"mode": 0, "max_steps": 10000, "max_runtime_ms": 0, "step_timeout_ms": 5000}
const _BRIDGE_PATH = "res://game/feel/graphical_completion_bridge.gd"
class FrameRelay extends RefCounted:
	signal advanced
	func forward_frame() -> void:
		# Keep the emitter alive if an awaiting consumer frees its driver.
		var retained: RefCounted = self
		retained.advanced.emit()
var _frame_relay := FrameRelay.new()
# Numeric analysis wire codes below consume the frozen contract; 3A owns the enum.
var _active := false
var _run_serial := 0
var _session: Variant
var _presenter: Node3D
var _bridge: Node3D
var _game_feel_graphical := false
var _completion_evidence: Dictionary = {}
var _completion_snapshot: Dictionary = {}
var _step_evidence: Array = []
var _token: Dictionary = {}
var _options: Dictionary = {}
var _level: Dictionary = {}
var _started_at := 0
var _step_active := false
var _commit_signals := 0
var _completion_received := false
var _runtime_issues: Array = []
var _transition: Dictionary = {}
var _tweens: Array[Tween] = []
var _connections: Array = []

func _trace_api() -> Variant:
	var path := "res://foundation/solver/solution_trace.gd"
	return load(path) if ResourceLoader.exists(path) else null

func _make_session() -> Variant:
	return Session.new()

func _make_bridge() -> Variant:
	# Fixed production dependency. Public options cannot replace this module.
	if not ResourceLoader.exists(_BRIDGE_PATH): return null
	var api: Variant = load(_BRIDGE_PATH)
	if not api is Script: return null
	var value: Variant = api.new()
	if value is Node3D: return value
	if value is Node: value.free()
	return null

func get_step_evidence() -> Array:
	return _freeze_evidence(_step_evidence.duplicate(true))

static func _freeze_evidence(value: Variant) -> Variant:
	if value is Dictionary:
		for key in value: value[key] = _freeze_evidence(value[key])
		value.make_read_only()
	elif value is Array:
		for i in value.size(): value[i] = _freeze_evidence(value[i])
		value.make_read_only()
	return value

func replay(level: Dictionary, trace: Dictionary, options: Dictionary) -> Dictionary:
	var length := _trace_length(trace)
	if _active:
		return _result(Status.ERROR, length, 0, null, "", "", null,
			[_issue(3016, "replay", "This driver already has an active replay.")])
	_active = true
	_run_serial += 1
	var serial := _run_serial
	_started_at = Time.get_ticks_msec()
	_step_evidence.clear()
	_runtime_issues.clear()
	_token.clear()
	_transition.clear()
	_step_active = false
	_dispose_presenter()
	_session = null
	_game_feel_graphical = false
	_options = _DEFAULTS.duplicate(true)
	for field in options:
		if typeof(field) != TYPE_STRING or not _DEFAULTS.has(field) or typeof(options[field]) != TYPE_INT:
			return _end(_result(Status.ERROR, length, 0, null, "", "", null,
				[_issue(3016, "options." + str(field), "Unknown option or non-integer value.")]))
		_options[field] = options[field]
	if not _options.mode in [Mode.LOGICAL_SESSION, Mode.GRAPHICAL] or _options.max_steps < 0 or _options.max_runtime_ms < 0 or _options.step_timeout_ms <= 0:
		return _end(_result(Status.ERROR, length, 0, null, "", "", null,
			[_issue(3016, "options", "Invalid replay mode or budget.")]))
	_game_feel_graphical = Feel.enabled(level) and _options.mode == Mode.GRAPHICAL
	if _game_feel_graphical:
		_bridge = _make_bridge()
		if _bridge == null:
			return _end(_result(Status.ERROR,length,0,null,"","",null,[_issue(3016,"dependencies.GameFeelPresenter","CASE_DEPENDENCY_PENDING: GAME_FEEL_GRAPHICAL_COMPLETION_BRIDGE",{"owner":"00+10A","required":"authorized path sampling + natural completion bridge"})]))
		if not _bridge.has_method("bind_runtime") or not _bridge.has_method("snapshot") or not _bridge.has_signal("motion_completed") or not _bridge.has_signal("motion_cancelled"):
			return _end(_result(Status.ERROR,length,0,null,"","",null,[_issue(3014,"bridge.interface","Completion Bridge does not provide the formal interface.")]))
	if not is_inside_tree():
		return _end(_result(Status.ERROR, length, 0, null, "", "", null,
			[_issue(3016, "replay", "Asynchronous replay requires a SceneTree.")]))
	# Preserve SceneTree frame timing, but own the await signal. On exit we can
	# resolve waiting coroutines while this script instance is still alive.
	_connect_owned(get_tree().process_frame, _frame_relay.forward_frame)
	_level = level.duplicate(true)
	var owned_trace := trace.duplicate(true)
	var api: Variant = _trace_api()
	if api == null:
		return _end(_result(Status.ERROR, length, 0, null, "", "", null,
			[_issue(3016, "dependencies.Trace", "DEPENDENCY_PENDING: real 3A SolutionTrace is unavailable.")]))
	var encoded: Dictionary = Codec.encode(_level)
	if not encoded.ok:
		return _end(_result(Status.ERROR, length, 0, null, "", "", null,
			[_issue(3000, "level", "Level identity or data is invalid.", {}, encoded.issues)]))
	if _expired():
		return _end(_result(Status.INCOMPLETE, length))
	var validation: Dictionary = Validator.validate(_level, {"max_configurations": 4096, "max_checks": 100000})
	if validation.status != 0:
		return _end(_result(Status.ERROR, length, 0, null, "", "", null,
			[_issue(3011 if validation.status == 2 else 3000, "level", "Static level validation did not establish VALID.", {}, validation.issues)]))
	if _expired():
		return _end(_result(Status.INCOMPLETE, length))
	var valid_trace: Dictionary = api.validate(_level, owned_trace)
	if not valid_trace.ok:
		return _end(_result(Status.ERROR, length, 0, null, "", "", null, valid_trace.issues))
	if _expired():
		return _end(_result(Status.INCOMPLETE, length))
	var spawn: Dictionary = Records.initial_state(_level)
	var spawn_key: Dictionary = Key.build(_level, spawn)
	if not spawn_key.ok:
		return _end(_result(Status.ERROR, length, 0, 0, "", "", null,
			[_issue(3006, "initial_state", "Cannot identify spawn.", {}, spawn_key.issues)]))
	if spawn_key.key != owned_trace.initial_statekey:
		return _end(_result(Status.ERROR, length, 0, 0, owned_trace.initial_statekey, spawn_key.key, null,
			[_issue(3013, "trace.initial_state", "Runtime supports only the official spawn state.", _differences(owned_trace.initial_state, spawn))]))
	if _expired():
		return _end(_result(Status.INCOMPLETE, length))
	_session = Facade.new() if _game_feel_graphical else _make_session()
	if _game_feel_graphical:
		var owned: RefCounted = _session
		_connect_owned(owned.transition_started, func(result: Dictionary, id: int, generation: int, is_global: bool) -> void:
			if _active and serial == _run_serial and _session == owned: _on_transition_started(result,id,generation,is_global))
		_connect_owned(owned.committed, func(state: Dictionary) -> void:
			if _active and serial == _run_serial and _session == owned: _on_committed(state))
		_connect_owned(owned.feedback, func(result: Dictionary) -> void:
			if _active and serial == _run_serial and _session == owned: _on_feedback(result))
	else:
		_connect_owned(_session.transition_started, _on_transition_started)
		_connect_owned(_session.committed, _on_committed)
		_connect_owned(_session.feedback, _on_feedback)
	var loaded: Dictionary = _session.load_level(_level)
	if not loaded.ok:
		return _end(_result(Status.ERROR, length, 0, 0, owned_trace.initial_statekey, "", null,
			[_issue(3014, "runtime.load_level", "Runtime failed to load the validated level.", {}, loaded.issues)]))
	var initial: Dictionary = Key.build(_level, _state_snapshot())
	if not initial.ok:
		return _end(_result(Status.ERROR, length, 0, 0, owned_trace.initial_statekey, "", null,
			[_issue(3006, "runtime.initial_state", "Cannot identify Runtime initial state.", {}, initial.issues)]))
	if initial.key != owned_trace.initial_statekey or _state_snapshot() != owned_trace.initial_state:
		return _end(_result(Status.DIVERGED, length, 0, 0, owned_trace.initial_statekey, initial.key, null,
			[_issue(3015, "runtime.initial_state", "Runtime initial state differs.", _differences(owned_trace.initial_state, _state_snapshot()))]))
	if _game_feel_graphical:
		var owned_bridge: Node3D = _bridge
		_connect_owned(owned_bridge.motion_completed, func(identity: Dictionary, evidence: Dictionary) -> void:
			if _active and serial == _run_serial and is_instance_valid(owned_bridge) and _bridge == owned_bridge: _on_bridge_completed(identity,evidence))
		_connect_owned(owned_bridge.motion_cancelled, func(identity: Dictionary, reason: String) -> void:
			if _active and serial == _run_serial and is_instance_valid(owned_bridge) and _bridge == owned_bridge: _on_bridge_cancelled(identity,reason))
		add_child(owned_bridge)
		var scope: Dictionary = _session.get_presentation_scope()
		var bound: Variant = owned_bridge.bind_runtime(_session,_level.duplicate(true))
		if not bound is Dictionary or typeof(bound.get("ok")) != TYPE_BOOL or not bound.get("issues") is Array:
			return _end(_result(Status.ERROR,length,0,null,"","",null,[_issue(3014,"bridge.bind_runtime","Completion Bridge returned an invalid binding result.")]))
		if not bound.ok:
			return _end(_result(Status.ERROR,length,0,null,"","",null,[_issue(3014,"bridge.bind_runtime","Completion Bridge could not bind the validated Runtime.",{},bound.issues)]))
		if _session.get_presentation_scope() != scope or _state_snapshot() != owned_trace.initial_state or _commit_count() != 0:
			return _end(_result(Status.ERROR,length,0,null,"","",null,[_issue(3014,"bridge.bind_runtime","Binding changed the owned Runtime identity or initial state.")]))
	elif _options.mode == Mode.GRAPHICAL:
		_presenter = Presenter.new()
		add_child(_presenter)
		var synced: Dictionary = _presenter.sync_state(_level, _session.state)
		if not synced.ok:
			return _end(_result(Status.ERROR, length, 0, 0, owned_trace.initial_statekey, initial.key, null,
				[_issue(3014, "presenter.sync_state", "Presenter could not display the initial state.", {}, synced.issues)]))
	if _expired():
		return _end(_result(Status.INCOMPLETE, length))
	var matched := 0
	for step in owned_trace.steps:
		if matched >= _options.max_steps or _expired():
			return _end(_result(Status.INCOMPLETE, length, matched))
		var outcome: Dictionary = await _replay_step(step, length, matched)
		# A removed/re-added driver may already own a new replay when this await
		# resumes. The obsolete coroutine must not clean up that newer session.
		if serial != _run_serial or not _active:
			return _result(Status.INCOMPLETE, length, matched)
		if outcome.status != Status.MATCH:
			return _end(outcome)
		matched += 1
	var goal: Dictionary = Goal.is_goal(_level, _state_snapshot())
	if not goal.ok:
		return _end(_result(Status.ERROR, length, matched, null, "", "", null,
			[_issue(3005, "runtime.goal", "Final Goal evaluation failed.", {}, goal.issues)]))
	if not goal.is_goal:
		var final_key: Dictionary = Key.build(_level, _state_snapshot())
		return _end(_result(Status.DIVERGED, length, matched, length, owned_trace.goal_statekey, final_key.key, null,
			[_issue(3015, "runtime.goal", "Runtime endpoint is not a Goal.")]))
	if _expired():
		return _end(_result(Status.INCOMPLETE, length, matched))
	var endpoint: Dictionary = Key.build(_level, _state_snapshot())
	if not endpoint.ok:
		return _end(_result(Status.ERROR, length, matched, null, owned_trace.goal_statekey, "", null,
			[_issue(3006, "runtime.goal_statekey", "Cannot identify final Runtime state.", {}, endpoint.issues)]))
	if _expired():
		return _end(_result(Status.INCOMPLETE, length, matched))
	return _end(_result(Status.MATCH, length, matched, null, owned_trace.goal_statekey, endpoint.key))

func _replay_step(step: Dictionary, length: int, matched: int) -> Dictionary:
	var serial := _run_serial
	_step_active = true
	_commit_signals = 0
	_completion_received = false
	_completion_evidence.clear()
	_completion_snapshot.clear()
	_token.clear()
	_transition.clear()
	_runtime_issues.clear()
	var baseline := _commit_count()
	var generation := _generation()
	var step_started := Time.get_ticks_msec()
	var requested: Dictionary = _session.request_action(step.action.duplicate(true))
	if requested.status == 2:
		_runtime_issues.append(_issue(3014, "runtime.request_action", "Runtime rejected execution with ERROR.", {}, requested.issues))
	# Signals and finish callbacks may run synchronously inside request_action.
	var settled := false
	while true:
		if serial != _run_serial or not _active or not is_inside_tree():
			return _result(Status.INCOMPLETE, length, matched)
		var actual: Dictionary = Key.build(_level, _state_snapshot())
		var delta := _commit_count() - baseline
		var details := {"commit_count_before": baseline, "commit_count_after": _commit_count(),
			"commit_delta": delta, "commit_signals": _commit_signals, "generation_before": generation,
			"generation_after": _generation(), "state_differences": _differences(step.expected_state, _state_snapshot())}
		var status := -1
		var issues: Array = []
		if not _runtime_issues.is_empty():
			status = Status.ERROR
			issues = _runtime_issues.duplicate(true)
		elif not actual.ok:
			status = Status.ERROR
			issues = [_issue(3006, "runtime.state", "Runtime state identity failed.", details, actual.issues)]
		elif _generation() != generation:
			status = Status.ERROR
			issues = [_issue(3014, "runtime.generation", "Replay session was reset during a step.", details)]
		elif requested.status == 1:
			status = Status.DIVERGED
			issues = [_issue(3015, "runtime.request_action", "Runtime rejected the trace action.", details, requested.issues)]
		elif delta > 1 or _commit_signals > 1 or (_commit_signals > 0 and delta != 1) or (_completion_received and delta != 1) or not requested.changed:
			status = Status.DIVERGED
			issues = [_issue(3015, "runtime.commit_count", "Each trace step must commit exactly once.", details)]
		elif _expired() or Time.get_ticks_msec() - step_started >= _options.step_timeout_ms:
			status = Status.INCOMPLETE
		elif _completion_received and delta == 1 and _commit_signals == 1 and _is_idle():
			# Observe a full idle frame before allowing another trace action.
			if settled:
				if actual.key != step.resulting_statekey or _state_snapshot() != step.expected_state or _transition.get("global_kind", -1) != step.global_kind:
					status = Status.DIVERGED
					details["expected_global_kind"] = step.global_kind
					details["actual_global_kind"] = _transition.get("global_kind", -1)
					issues = [_issue(3015, "trace.steps[%d]" % (step.index - 1), "Runtime endpoint differs from the trace.", details)]
				else:
					status = Status.MATCH
			else:
				settled = true
		else:
			settled = false
		if status != -1:
			_step_active = false
			_step_evidence.append({"index": step.index, "action": step.action.duplicate(true),
				"expected_statekey": step.resulting_statekey, "actual_statekey": actual.get("key", ""),
				"actual_state": _state_snapshot().duplicate(true),
				"commit_delta": delta, "commit_signals": _commit_signals, "commit_count_before": baseline,
				"commit_count_after": _commit_count(), "is_global": _token.get("is_global", false),
				"transition_identity": _token.duplicate(true), "completion_received": _completion_received,
				"completion_evidence": _completion_evidence.duplicate(true),
				"bridge_snapshot": _completion_snapshot.duplicate(true),
				"global_kind": _transition.get("global_kind", -1), "state_differences": details.state_differences,
				"status": status})
			return _result(status, length, matched, step.index if status != Status.MATCH else null,
				step.resulting_statekey if status != Status.MATCH else "", actual.get("key", "") if status != Status.MATCH else "",
				step.action if status != Status.MATCH else null, issues)
		await _frame_relay.advanced
	return _result(Status.ERROR, length, matched)

func _on_transition_started(result: Dictionary, id: int, generation: int, is_global: bool) -> void:
	if not _active or not _step_active:
		return
	_token = {"id": id, "generation": generation, "is_global": is_global}
	_transition = result.duplicate(true)
	if _game_feel_graphical:
		# Capture before COMMITTED clears Facade pending authority. No finish here.
		_token = _session.get_pending_identity(id,generation,is_global).duplicate(true)
		if _token.is_empty(): _runtime_issues.append(_issue(3014,"runtime.transition_started","No matching full native completion identity."))
		return
	if _options.mode == Mode.LOGICAL_SESSION:
		_finish_token(id, generation, is_global)
		return
	var animation: Dictionary = _presenter.animate_transition(_level, result, 0.30)
	if not animation.ok:
		_runtime_issues.append(_issue(3014, "presenter.animate_transition", "Presenter could not animate the step.", {}, animation.issues))
		return
	var tween: Tween = animation.tween
	_tweens.append(tween)
	var serial := _run_serial
	_connect_owned(tween.finished, func() -> void:
		if _active and serial == _run_serial:
			_finish_token(id, generation, is_global))

func _finish_token(id: int, generation: int, is_global: bool) -> void:
	if _game_feel_graphical: return
	if not _active or not _step_active or _session == null or _token.get("id", 0) != id or _token.get("generation", -1) != generation or _session.generation != generation:
		return
	var serial := _run_serial
	var owned: RefCounted = _session
	var completed: Dictionary = owned.finish_global(id, generation) if is_global else owned.finish_local(id, generation)
	if serial != _run_serial or not _active or _session != owned:
		return
	_completion_received = true
	var transition: Variant = completed.get("transition")
	if transition is Dictionary and transition.get("status", 2) == 2:
		_runtime_issues.append(_issue(3014, "runtime.finish", "Runtime completion returned ERROR.", {}, transition.get("issues", [])))

func _on_committed(_state: Dictionary) -> void:
	if not _active or not _step_active:
		return
	_commit_signals += 1
	if is_instance_valid(_presenter):
		var synced: Dictionary = _presenter.sync_state(_level, _session.state)
		if not synced.ok:
			_runtime_issues.append(_issue(3014, "presenter.sync_state", "Presenter could not display the committed state.", {}, synced.issues))
		_presenter.clear_previews()

func _on_feedback(result: Dictionary) -> void:
	if _active and _step_active and result.get("status", 2) == 2:
		_runtime_issues.append(_issue(3014, "runtime.feedback", "Runtime reported ERROR.", {}, result.get("issues", [])))

func _same_bridge_token(identity: Dictionary) -> bool:
	if not _active or not _step_active or not _game_feel_graphical or _token.is_empty(): return false
	if identity.size() != 5 or not identity.has_all(["session_id","level_run_id","generation","transaction_id","is_global"]): return false
	if typeof(identity.session_id) != TYPE_STRING or typeof(identity.level_run_id) != TYPE_STRING or typeof(identity.generation) != TYPE_INT or typeof(identity.transaction_id) != TYPE_INT or typeof(identity.is_global) != TYPE_BOOL: return false
	return identity == _token

func _on_bridge_completed(identity: Dictionary, evidence: Dictionary) -> void:
	if not _same_bridge_token(identity) or _completion_received: return
	var scope: Dictionary = _session.get_presentation_scope()
	for key in ["session_id","level_run_id","generation"]:
		if identity.get(key) != scope.get(key): return
	var snapshot: Variant = _bridge.snapshot()
	if not snapshot is Dictionary:
		_runtime_issues.append(_issue(3014,"bridge.snapshot","Completion Bridge returned an invalid evidence snapshot."))
		return
	_completion_received = true
	_completion_evidence = evidence.duplicate(true)
	_completion_snapshot = snapshot.duplicate(true)

func _on_bridge_cancelled(identity: Dictionary, reason: String) -> void:
	if not _same_bridge_token(identity) or _completion_received: return
	_runtime_issues.append(_issue(3014,"bridge.motion_cancelled","Graphical motion was cancelled before completion.",{"reason":reason,"identity":identity.duplicate(true)}))

func _state_snapshot() -> Dictionary:
	return _session.get_state() if _game_feel_graphical else _session.state

func _commit_count() -> int:
	return _session.get_commit_count() if _game_feel_graphical else _session.commit_count

func _generation() -> int:
	return _session.get_generation() if _game_feel_graphical else _session.generation

func _is_idle() -> bool:
	if _game_feel_graphical: return _session.is_idle()
	return _session.context == {"global_transition_state": 0, "ticket": null, "local_moves": []}

func _expired() -> bool:
	return _options.max_runtime_ms > 0 and Time.get_ticks_msec() - _started_at >= _options.max_runtime_ms

func _connect_owned(signal_value: Signal, callback: Callable) -> void:
	signal_value.connect(callback)
	_connections.append([signal_value, callback])

func _end(result: Dictionary) -> Dictionary:
	_step_active = false
	for connection in _connections:
		var signal_value: Signal = connection[0]
		if is_instance_valid(signal_value.get_object()) and signal_value.is_connected(connection[1]):
			signal_value.disconnect(connection[1])
	_connections.clear()
	for tween in _tweens:
		if tween.is_valid():
			tween.kill()
	_tweens.clear()
	if is_instance_valid(_presenter):
		_presenter.clear_previews()
	if is_instance_valid(_bridge):
		_bridge.free()
	_bridge = null
	if result.status != Status.MATCH and _session != null and (not _game_feel_graphical or _session.is_loaded()):
		_session.reset()
	_active = false
	return result.duplicate(true)

func _dispose_presenter() -> void:
	if is_instance_valid(_bridge): _bridge.free()
	_bridge = null
	if is_instance_valid(_presenter):
		_presenter.free()
	_presenter = null

func _exit_tree() -> void:
	if _active:
		_end(_result(Status.INCOMPLETE, 0))
		_frame_relay.forward_frame()

static func _trace_length(trace: Dictionary) -> int:
	return trace.steps.size() if trace.get("steps") is Array else 0

static func _result(status: int, length: int, matched: int = 0, divergence: Variant = null, expected: String = "", actual: String = "", action: Variant = null, issues: Array = []) -> Dictionary:
	return {"status": status, "trace_length": length, "matched_steps": matched,
		"divergence_step": divergence, "expected_statekey": expected, "actual_statekey": actual,
		"action": action.duplicate(true) if action is Dictionary else null, "issues": issues.duplicate(true)}

static func _issue(code: int, path: String, message: String, details: Dictionary = {}, upstream: Array = []) -> Dictionary:
	return {"code": code, "severity": 0, "path": path, "message": message,
		"details": details.duplicate(true), "upstream": upstream.duplicate(true)}

static func _differences(expected: Variant, actual: Variant, path: String = "state") -> Dictionary:
	var differences: Dictionary = {}
	if typeof(expected) != typeof(actual):
		differences[path] = {"expected": expected, "actual": actual}
	elif expected is Dictionary:
		for field in expected:
			if not actual.has(field):
				differences[path + "." + str(field)] = {"expected": expected[field], "actual": null}
			else:
				differences.merge(_differences(expected[field], actual[field], path + "." + str(field)))
		for field in actual:
			if not expected.has(field):
				differences[path + "." + str(field)] = {"expected": null, "actual": actual[field]}
	elif expected is Array:
		if expected.size() != actual.size():
			differences[path] = {"expected": expected, "actual": actual}
		else:
			for index in expected.size():
				differences.merge(_differences(expected[index], actual[index], "%s[%d]" % [path, index]))
	elif expected != actual:
		differences[path] = {"expected": expected, "actual": actual}
	return differences

