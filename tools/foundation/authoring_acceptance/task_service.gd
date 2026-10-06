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
var _replay_owned: Node

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
	if request.entry_kind == "ANALYZE_CURRENT" and _provider != null: return S.failure("DEPENDENCY_PENDING","D5 current-buffer capture not delivered")
	var captured := Capture.capture_saved_job(request,ProjectSettings.globalize_path("res://").replace("\\","/").trim_suffix("/"))
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
	var launched: Dictionary = _transport.launch(_identity,captured.value.project,"GRAPHICAL" if "GRAPHICAL_REPLAY" in request.policy.stages else "HEADLESS")
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
	if _replay_owned != null: return S.success(null) # No native cancel API; retain slot until natural return.
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
	_consume_messages(_transport.poll(_identity))
	var release: Dictionary = _transport.release_state(_identity)
	if release.get("process_exited",false):
		# EXIT can become durable after the first directory enumeration but before
		# OS exit observation. With the writer gone, drain its final stream once
		# more before deciding whether this was a crash or a graceful exit.
		_consume_messages(_transport.poll(_identity))
		release = _transport.release_state(_identity)
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

func _consume_messages(messages: Dictionary) -> void:
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

## Worker-side whole graphical replay inside the current sealed execution entry.
## Same service slot/lifecycle; no alternate stage selection or history restore.
func replay_run(identity: Dictionary, canonical_ref: Dictionary, trace_ref: Dictionary, options: Dictionary) -> Dictionary:
	var records: Script = load("res://tools/foundation/authoring_acceptance/run_records.gd")
	var record: Dictionary = records.make_stage_record("GRAPHICAL_REPLAY",E.stage_owner("GRAPHICAL_REPLAY"),E.stage_module("GRAPHICAL_REPLAY"))
	record.actual_policy = options.duplicate(true)
	record.actual_budget = options.duplicate(true)
	record.actual_budget.erase("mode")
	record.actual_budget["validation_options"] = {"max_configurations":4096,"max_checks":100000}
	record.evidence_refs = {}
	record.reason = "CONTROLLED_ENTRY_REQUIRED"
	if not _released:
		record.reason = "BUSY"
		return record
	var project_root := ProjectSettings.globalize_path("res://").replace("\\","/").trim_suffix("/")
	if not project_root.ends_with("/execution/project") or DisplayServer.get_name() == "headless": return record
	var run_root := project_root.trim_suffix("/execution/project")
	var snapshot := E.snapshot_from_run(run_root)
	if not snapshot.ok: return record
	var verified := E.verify(snapshot.value)
	if not verified.ok or identity != verified.value.manifest.identity: return record
	if "GRAPHICAL_REPLAY" not in verified.value.policy.stages or options != verified.value.policy.replay_options or options.mode != 1: return record
	# Confirm this controlled process still uses every sealed byte, not active source.
	for uri in verified.value.files:
		var bytes := E.read_bytes(project_root.path_join(uri.substr(6)))
		if not bytes.ok or bytes.value != verified.value.files[uri]: return record
	var producers := {}
	var producer_refs := {}
	for id in ["BAKE","ORIGINAL_GRAPH"]:
		var raw := E.read_bytes(run_root.path_join("artifacts/stages/" + id + "/stage_result.wire"))
		if not raw.ok: return record
		var decoded := W.decode_wire("stage_result",raw.value)
		if not decoded.ok or decoded.value.run_identity != identity or decoded.value.stage_record.stage_id != id: return record
		producers[id] = decoded.value.stage_record
		producer_refs[id] = E.artifact("artifacts/stages/" + id + "/stage_result.wire",raw.value,"foundationtoolwire.v1")
	if producers.BAKE.evidence_refs.canonical != canonical_ref or producers.ORIGINAL_GRAPH.evidence_refs.selected_trace_ref == null or producers.ORIGINAL_GRAPH.evidence_refs.selected_trace_ref.trace != trace_ref: return record
	var canonical := E.read_artifact(run_root,canonical_ref)
	var trace_bytes := E.read_artifact(run_root,trace_ref)
	if not canonical.ok or not trace_bytes.ok: return record
	var codec := "res://foundation/level/" + "level_codec.gd"
	var level: Dictionary = load(codec).decode(canonical.value.get_string_from_utf8())
	var trace := W.decode_wire("trace",trace_bytes.value)
	if not level.ok or not trace.ok or trace.value != producers.ORIGINAL_GRAPH.native_result.solution_trace: return record
	var states := "res://foundation/contracts/" + "contract_records.gd"
	var key := "res://foundation/contracts/" + "state_key.gd"
	record.input_refs = {"input_manifest":snapshot.value.input_manifest,"bake_result":producer_refs.BAKE,"canonical":canonical_ref,"level_hash":level.level.content_hash,"rule_version":level.level.rule_version,"initial_statekey":load(key).build(level.level,load(states).initial_state(level.level)).key,"selected_trace":trace_ref,"selected_trace_digest":trace_ref.sha256}
	_identity = identity.duplicate(true)
	_released = false
	_cancelled = false
	_failed = false
	_lifecycle = "RUNNING"
	_stage = "GRAPHICAL_REPLAY"
	status_changed.emit(_view())
	_replay_owned = load(E.stage_module("GRAPHICAL_REPLAY")).new()
	add_child(_replay_owned)
	var clock := Transport.new()
	record.started_at = clock.utc_now()
	record.native_result = await _replay_owned.replay(level.level,trace.value,options)
	_replay_owned.queue_free()
	await get_tree().process_frame # Natural owned SceneTree disposal, no sleep/seek.
	_replay_owned = null
	record.finished_at = clock.utc_now()
	record.execution = "INCOMPLETE" if record.native_result.status == 3 else ("ERROR" if record.native_result.status == 2 else ("CANCELLED" if _cancelled else "COMPLETED"))
	record.reason = "" if record.execution == "COMPLETED" else "NATIVE_" + record.execution
	_released = true
	_stage = ""
	_lifecycle = "CANCELLED" if _cancelled else "COMPLETED"
	status_changed.emit(_view())
	return record