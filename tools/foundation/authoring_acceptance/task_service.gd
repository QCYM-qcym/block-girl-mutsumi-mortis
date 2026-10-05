extends Node
## Root-owned single heavy slot. UI unload never destroys a cancelling service.
const S = preload("res://tools/foundation/authoring_acceptance/wire_schemas.gd")
const W = preload("res://tools/foundation/authoring_acceptance/tool_wire.gd")
const Capture = preload("res://tools/foundation/authoring_acceptance/snapshot_capture.gd")
const E = preload("res://tools/foundation/authoring_acceptance/execution_project.gd")
const Transport = preload("res://tools/foundation/authoring_acceptance/process_transport.gd")
signal status_changed(status: Dictionary)
signal result_ready(report_ref: Dictionary)
var _editor := ""
var _provider: RefCounted
var _capture_port: Callable
var _transport: RefCounted
var _identity: Dictionary = {}
var _lifecycle := "IDLE"
var _released := true
var _cancelled := false
var _failed := false
var _reason := ""
var _stage := ""
var _exit_received := false

func _init(capture_port: Callable = Callable(), transport: RefCounted = null) -> void:
	_capture_port = capture_port
	_transport = transport

static func get_or_create(editor_root: Node, editor_instance_id: String) -> Node:
	if not S._uuid(editor_instance_id): return null
	if editor_root.has_meta("foundation_task_service"):
		var service: Node = editor_root.get_meta("foundation_task_service")
		return service if is_instance_valid(service) and service._editor == editor_instance_id else null
	var service := new()
	service._editor = editor_instance_id
	editor_root.add_child(service)
	editor_root.set_meta("foundation_task_service",service)
	return service

func bind_editor_context(provider: RefCounted) -> Dictionary:
	if _provider != null and _provider != provider: return S.failure("BUSY","Another editor provider is bound")
	for method in ["describe","current_generation","set_capture_lock"]:
		if not provider.has_method(method): return S.failure("CONTEXT_INVALID","Missing provider capability")
	var desc: Variant = provider.describe()
	if typeof(desc) != TYPE_DICTIONARY or desc.get("editor_instance_id","") != _editor: return S.failure("IDENTITY_MISMATCH","Editor context identity mismatch")
	_provider = provider
	status_changed.emit(_view())
	return S.success(null)

func unbind_editor_context(provider: RefCounted) -> void:
	if provider != _provider: return
	if not _released: _request_cancel("PLUGIN_UNLOAD")
	_provider.set_capture_lock(false)
	_provider = null

func _capture(request: Dictionary) -> Dictionary:
	if _capture_port.is_valid(): return _capture_port.call(request)
	if request.entry_kind != "ACCEPT_SAVED": return S.failure("DEPENDENCY_PENDING","D5 current-buffer capture not delivered")
	var captured := Capture.capture_saved(request,ProjectSettings.globalize_path("res://").replace("\\","/").trim_suffix("/"))
	if not captured.ok: return captured
	var checked := E.verify(captured.value)
	if not checked.ok: return checked
	return S.success({"identity":checked.value.manifest.identity,"project":{"snapshot_ref":captured.value,"policy":request.policy.duplicate(true)}})

func start(request: Dictionary) -> Dictionary:
	if not _released: return S.failure("BUSY","Single heavy slot is occupied; no queue")
	if not S._fields(request,["entry_kind","level_ref","policy"]) or not S._level_ref(request.level_ref) or request.entry_kind != request.policy.get("entry_kind",""): return S.failure("REQUEST_INVALID","Invalid RunRequest")
	var policy := W.encode_wire("policy",request.policy)
	if not policy.ok: return policy
	if _provider != null: _provider.set_capture_lock(true)
	_released = false
	_cancelled = false
	_failed = false
	_reason = ""
	_stage = ""
	_exit_received = false
	_lifecycle = "CAPTURING"
	_identity = {}
	status_changed.emit(_view())
	var captured := _capture(request)
	if _provider != null: _provider.set_capture_lock(false)
	if not captured.ok:
		_released = true
		_lifecycle = "FAILED"
		status_changed.emit(_view())
		return captured
	_identity = captured.value.identity.duplicate(true)
	if _cancelled:
		_released = true # Capture returned; no process was launched for this run.
		_lifecycle = "CANCELLED"
		set_process(false)
		status_changed.emit(_view())
		return S.failure("CANCELLED","Capture completed after cancellation; worker not launched")
	if _transport == null or not _capture_port.is_valid(): _transport = Transport.new()
	var launched: Dictionary = _transport.launch(_identity,captured.value.project,"HEADLESS")
	if not launched.ok:
		# No owned PID exists on dependency rejection. Capture files remain evidence.
		_released = true
		_lifecycle = "FAILED"
		status_changed.emit(_view())
		return launched
	_lifecycle = "RUNNING"
	set_process(true)
	status_changed.emit(_view())
	return S.success(_view())

func _request_cancel(reason: String) -> Dictionary:
	var capture_pending := _lifecycle == "CAPTURING"
	_cancelled = true
	if _reason.is_empty(): _reason = reason
	_lifecycle = "CANCELLING"
	if capture_pending:
		status_changed.emit(_view())
		return S.success(null) # No owned launch/channel exists until capture returns.
	var sent: Dictionary = _transport.send_cancel(_identity,reason)
	if not sent.ok: _failed = true
	status_changed.emit(_view())
	return sent

func cancel(identity: Dictionary) -> Dictionary:
	if identity != _identity: return S.failure("IDENTITY_MISMATCH","Cancel belongs to another run")
	if _released or _cancelled: return S.success(_view())
	_request_cancel("USER_CANCEL")
	return S.success(_view())

func _view() -> Dictionary:
	return {"identity":_identity.duplicate(true),"lifecycle":_lifecycle,"stage_id":_stage,"release_confirmed":_released}

func status(identity: Dictionary) -> Dictionary:
	if identity != _identity: return S.failure("IDENTITY_MISMATCH","Status belongs to another run")
	_poll_owned()
	return S.success(_view())

func _process(_delta: float) -> void: _poll_owned()

func _poll_owned() -> void:
	if _released or _transport == null: return
	var previous := _view()
	var messages: Dictionary = _transport.poll(_identity)
	if not messages.ok:
		_failed = true
		if not _cancelled: _request_cancel("STAGE_TIMEOUT" if messages.issues[0].code == "TIMEOUT" else "PROTOCOL_ERROR")
	else:
		for message in messages.value:
			match message.kind:
				"STAGE_STARTED": _stage = message.stage_id
				"STAGE_RESULT": _stage = ""
				"ERROR":
					_failed = true
					if not _cancelled: _request_cancel("PROTOCOL_ERROR")
				"EXIT":
					_exit_received = true
					_lifecycle = "FINALIZING"
					if message.payload_ref_or_inline.reason == "CANCELLED":
						_cancelled = true
						_lifecycle = "CANCELLING"
					if message.payload_ref_or_inline.reason in ["FAILED","LEASE_EXPIRED"]: _failed = true
	var release: Dictionary = _transport.release_state(_identity)
	for field in ["process_exited","file_handles_closed","callbacks_disconnected","preview_resources_released"]:
		if release.get(field,false) != true:
			if _view() != previous: status_changed.emit(_view())
			return
	if _transport.has_method("release_error") and _transport.release_error(): _failed = true
	if not _exit_received and not _cancelled: _failed = true # Confirmed crash is not successful EXIT.
	_released = true
	_lifecycle = "FAILED" if _failed else ("CANCELLED" if _cancelled else "COMPLETED")
	_stage = ""
	set_process(false)
	status_changed.emit(_view())
