extends RefCounted
## One writer per launch/direction. No algorithm, graph recovery or verdict here.
const S = preload("res://tools/foundation/authoring_acceptance/wire_schemas.gd")
const W = preload("res://tools/foundation/authoring_acceptance/tool_wire.gd")
const E = preload("res://tools/foundation/authoring_acceptance/execution_project.gd")
const BASE_MODULES = ["res://foundation/contracts/contract_validation.gd","res://foundation/contracts/foundation_types.gd","res://foundation/solver/search_records.gd","res://foundation/solver/solver_types.gd","res://foundation/rules/rule_types.gd","res://tools/foundation/authoring_acceptance/tool_wire.gd","res://tools/foundation/authoring_acceptance/wire_schemas.gd"]
var _clock: RefCounted
var _identity: Dictionary = {}
var _root := ""
var _launch := ""
var _role := ""
var _worker := false
var _assigned: Array = []
var _rx := 0
var _tx := 0
var _consumed := {}
var _poison := false
var _cancel := false
var _hello := false
var _exit := false
var _error := false
var _active := ""
var _started_at := ""
var _terminal: Array = []
var _last_lease := -1
var _lease_deadline := -1
var _last_wall := -1
var _last_hb := -1
var _start_ticks := -1
var _pid := -1
var _renew_ticks := -1
var _stage_results: Array = []
var _stage_deadline_ms := 300000
var _timed_out := false
var _process_port: RefCounted
var _owned_files: Array[FileAccess] = []
var _owned_callbacks: Array = []
var _owned_previews: Array[Node] = []
var _preview_observers: Array[WeakRef] = []
var _cleanup_attempted := false
var _exit_claim: Variant = null
var _release_error := false

func _init(clock: RefCounted = null) -> void: _clock = clock
func _wall() -> int: return _clock.utc_msec() if _clock != null else int(Time.get_unix_time_from_system() * 1000)
func _ticks() -> int: return _clock.monotonic_msec() if _clock != null else Time.get_ticks_msec()
func utc_now(offset: int = 0) -> String:
	var now := _wall() + offset
	return Time.get_datetime_string_from_unix_time(int(now / 1000)) + ".%03dZ" % (now % 1000)
static func _utc_ms(value: String) -> int:
	return Time.get_unix_time_from_datetime_string(value.substr(0,19)) * 1000 + value.substr(20,3).to_int()

## Dependency membership only; D2 remains the sole sealing/materialization builder.
## Caller must supply actual sealed module SHA values, never active filesystem guesses.
static func required_dependencies(policy: Dictionary) -> Dictionary:
	var validated := W.encode_wire("policy",policy)
	if not validated.ok: return validated
	var modules: Array = []
	for stage in policy.stages:
		var uri := ""
		if stage == "BAKE": uri = "res://foundation/authoring/authoring_adapter.gd"
		elif S.STORAGE_OWNERS.has(stage): uri = S.STORAGE_OWNERS[stage][1]
		# MANUAL_RUNTIME/ARCHIVE are capabilities, not new storage branches.
		if not uri.is_empty() and uri not in modules: modules.append(uri)
	return S.success({"base_modules":BASE_MODULES.duplicate(),"stage_modules":modules})

static func check_dependencies(policy: Dictionary, sealed_modules: Dictionary) -> Dictionary:
	var required := required_dependencies(policy)
	if not required.ok: return required
	for uri in required.value.base_modules + required.value.stage_modules:
		if not sealed_modules.has(uri) or not S._hex(sealed_modules[uri],64):
			return S.failure("DEPENDENCY_PENDING","Selected execution dependency not sealed",uri)
	return required

## Channel binding is also used by the controlled worker after verifying input.
## It cannot reset a stream after any message has been published or accepted.
func open_channels(identity: Dictionary, run_root: String, launch_id: String, role: String, stages: Array, worker: bool = false) -> Dictionary:
	if _tx != 0 or _rx != 0: return S.failure("IPC_PROTOCOL_ERROR","Active launch cannot be reset")
	if not S.identity_shape(identity) or not S._uuid(launch_id) or role not in ["HEADLESS","GRAPHICAL"] or not E.safe_path(run_root): return S.failure("IPC_PROTOCOL_ERROR","Invalid channel binding")
	var digest := W.digest("versions",identity.versions)
	if not digest.ok or digest.value != identity.execution_digest: return S.failure("EXECUTION_IDENTITY_MISMATCH","VersionsRecord wire digest differs")
	for stage in stages:
		if stage not in S.STAGES or stages.count(stage) != 1: return S.failure("IPC_PROTOCOL_ERROR","Invalid assigned stages")
	_identity = identity.duplicate(true)
	_root = run_root
	_launch = launch_id
	_role = role
	_assigned = stages.duplicate()
	_worker = worker
	return S.success(null)

func launch(identity: Dictionary, project: Dictionary, entry: String) -> Dictionary:
	if entry not in ["HEADLESS","GRAPHICAL","MANUAL"]: return S.failure("REQUEST_INVALID","Unknown controlled entry")
	if _pid != -1 or _tx != 0: return S.failure("BUSY","Launch is already owned")
	if not project.has("snapshot_ref") or not project.has("policy"): return S.failure("DEPENDENCY_PENDING","Current sealed execution project and policy required")
	var verified := E.verify(project.snapshot_ref)
	if not verified.ok: return verified
	if verified.value.manifest.identity != identity or verified.value.policy != project.policy: return S.failure("EXECUTION_IDENTITY_MISMATCH","Project/request binding mismatch")
	var members := {}
	for module in identity.versions.modules: members[module.path] = module.sha256
	var dependencies := check_dependencies(project.policy,members)
	if not dependencies.ok: return dependencies
	_stage_deadline_ms = project.policy.stage_deadline_ms
	var materialized := E.materialize(project.snapshot_ref,"")
	if not materialized.ok: return materialized
	var script: String = {"HEADLESS":"worker_entry.gd","GRAPHICAL":"graphical_entry.gd","MANUAL":"whitebox_entry.gd"}[entry]
	var script_uri := "res://tools/foundation/authoring_acceptance/" + script
	if not members.has(script_uri): return S.failure("DEPENDENCY_PENDING","Controlled entry is not sealed",script_uri)
	# D4 entry closure must come from a new D_SAVED receipt, never post-seal copying.
	if entry == "MANUAL": return S.failure("DEPENDENCY_PENDING","Manual entry D4 launch-context integration not yet delivered")
	var opened := open_channels(identity,project.snapshot_ref.root_path,E.uuid(),"HEADLESS" if entry == "HEADLESS" else "GRAPHICAL",project.policy.stages)
	if not opened.ok: return opened
	var initial := renew_lease()
	if not initial.ok: return initial
	var engine: String = OS.get_executable_path()
	var engine_bytes := FileAccess.get_file_as_bytes(engine)
	if E.sha(engine_bytes) != identity.versions.engine.executable_sha256 or Engine.get_version_info().string != identity.versions.engine.version: return _fail("Actual engine does not match sealed identity")
	var args := PackedStringArray(["--path",materialized.value.project_root,"--script",script_uri])
	if entry == "HEADLESS": args.insert(0,"--headless")
	args.append_array(PackedStringArray(["--","--run-dir",_root,"--launch-id",_launch]))
	_pid = _begin_owned_process(engine,args)
	if _pid <= 0: return _fail("Owned process launch failed")
	return S.success({"identity":_identity.duplicate(true),"pid":_pid,"hello_verified":false,"exited":false})

func _incoming() -> String: return "parent_to_worker" if _worker else "worker_to_parent"
func _outgoing() -> String: return "worker_to_parent" if _worker else "parent_to_worker"
func _channel(direction: String) -> String: return _root.path_join("ipc/" + _launch + "/" + direction)
func expected_sequence() -> int: return _rx
func sent_sequence() -> int: return _tx
func active_stage() -> String: return _active
func cancel_observed() -> bool: return _cancel
func pass_eligible() -> bool: return not (_poison or _cancel or _error)
func stored_results() -> Array: return _stage_results.duplicate(true)

func _fail(message: String) -> Dictionary:
	_poison = true
	return S.failure("IPC_PROTOCOL_ERROR",message)

func send(kind: String, stage: String, payload: Dictionary) -> Dictionary:
	if _identity.is_empty(): return S.failure("IPC_PROTOCOL_ERROR","Channels not bound")
	var msg := {"protocol_version":S.WORKER_PROTOCOL_VERSION,"identity":_identity.duplicate(true),"sequence":_tx,"kind":kind,"stage_id":stage,"payload_ref_or_inline":payload.duplicate(true)}
	var direction := "WORKER_TO_PARENT" if _worker else "PARENT_TO_WORKER"
	var checked := _validate(msg,direction,_tx)
	if not checked.ok: return checked
	var encoded := W.encode_wire("worker_message",msg)
	if not encoded.ok: return encoded
	var path := _channel(_outgoing()).path_join(str(_tx) + ".wire")
	if FileAccess.file_exists(path): return _fail("Published sequence cannot be overwritten")
	var tmp := path + ".tmp"
	if FileAccess.file_exists(tmp): return S.failure("IO_ERROR","Unfinished publication retained for diagnosis",tmp)
	var written := E.write_new(tmp,encoded.value)
	if not written.ok: return written
	if DirAccess.rename_absolute(tmp,path) != OK: return S.failure("IO_ERROR","Atomic message publication failed",path)
	_apply(msg,checked.value)
	if _tx == 9223372036854775807: return _fail("Sequence exhausted")
	_tx += 1
	return S.success(msg)

func renew_lease() -> Dictionary:
	if _worker or _exit or _poison: return S.failure("IPC_PROTOCOL_ERROR","Lease writer unavailable")
	var now := _wall()
	if _last_wall >= 0 and now < _last_wall:
		_cancel = true
		return _fail("Parent clock rollback")
	_last_wall = now
	var result := send("LEASE","",{"issued_at":utc_now(),"valid_for_ms":30000})
	if result.ok: _renew_ticks = _ticks()
	return result

func send_cancel(identity: Dictionary, reason: String = "USER_CANCEL") -> Dictionary:
	if identity != _identity: return S.failure("IDENTITY_MISMATCH","Cancel belongs to another run")
	_cancel = true # Revocation precedes publication, including publication failure.
	return send("CANCEL","",{"reason":reason})

func accept_message(message: Dictionary, launch_id: String) -> Dictionary:
	if launch_id != _launch: return S.failure("LATE_MESSAGE","Obsolete launch quarantined")
	if message.get("identity",{}).get("run_id","") != _identity.run_id: return S.failure("LATE_MESSAGE","Foreign run quarantined")
	if message.identity != _identity: return _fail("Current launch identity mismatch")
	if _poison: return S.failure("IPC_PROTOCOL_ERROR","Receive stream poisoned")
	var checked := _validate(message,"PARENT_TO_WORKER" if _worker else "WORKER_TO_PARENT",_rx)
	if not checked.ok: return _fail(checked.issues[0].message)
	_apply(message,checked.value)
	if _rx == 9223372036854775807: return _fail("Sequence exhausted")
	_rx += 1
	return S.success(message.duplicate(true))

func _validate(msg: Dictionary, direction: String, cursor: int) -> Dictionary:
	var checked := S.validate_worker_context(msg,_active,direction,cursor)
	if not checked.ok: return checked
	if _exit and direction == "WORKER_TO_PARENT": return S.failure("IPC_PROTOCOL_ERROR","Message after EXIT")
	var p: Dictionary = msg.payload_ref_or_inline
	match msg.kind:
		"HELLO":
			if _hello or p.launch_id != _launch or p.worker_role != _role: return S.failure("IPC_PROTOCOL_ERROR","HELLO launch/role/repetition")
			if direction == "WORKER_TO_PARENT" and _worker and not _lease_valid(): return S.failure("IPC_PROTOCOL_ERROR","HELLO requires verified unexpired initial lease")
		"STAGE_STARTED":
			if _error or msg.stage_id not in _assigned or msg.stage_id in _terminal: return S.failure("IPC_PROTOCOL_ERROR","Unassigned/repeated/failed stage")
			if _terminal.size() >= _assigned.size() or msg.stage_id != _assigned[_terminal.size()]: return S.failure("IPC_PROTOCOL_ERROR","Stage order differs from assigned formal plan")
			if _worker and (_cancel or not _lease_valid()): return S.failure("IPC_PROTOCOL_ERROR","Boundary stop forbids a new call")
		"STAGE_RESULT":
			var stage := _read_stage(msg)
			if not stage.ok: return stage
			if stage.value.stage_record.started_at != _started_at: return S.failure("IPC_PROTOCOL_ERROR","Result/start timestamp mismatch")
			# Independent streams cannot tell whether this file preceded parent cancel.
			# Preserve exact immutable native evidence; run cancellation remains latched.
			return stage # Retain this exact verified value; never reread after cursor advance.
		"HEARTBEAT":
			if _utc_ms(p.observed_at) < _last_hb: return S.failure("IPC_PROTOCOL_ERROR","Heartbeat clock rollback")
		"EXIT":
			if p.reason == "FINISHED" and (_active != "" or _terminal.size() != _assigned.size() or _error or _cancel): return S.failure("IPC_PROTOCOL_ERROR","FINISHED with unresolved/stopped work")
		"LEASE":
			var issued := _utc_ms(p.issued_at)
			if issued > _wall() or (_last_lease >= 0 and issued <= _last_lease): return S.failure("IPC_PROTOCOL_ERROR","Lease future/rollback/repeated timestamp")
			if _last_lease >= 0 and issued > _last_lease + 30000: return S.failure("IPC_PROTOCOL_ERROR","Lease coverage gap")
	return S.success(msg)

func _apply(msg: Dictionary, verified: Dictionary) -> void:
	var p: Dictionary = msg.payload_ref_or_inline
	match msg.kind:
		"HELLO": _hello = true
		"STAGE_STARTED":
			_active = msg.stage_id
			_started_at = p.started_at
			_start_ticks = _ticks() - maxi(0,_wall() - _utc_ms(p.started_at))
		"STAGE_RESULT":
			_stage_results.append(verified.duplicate(true))
			_terminal.append(_active)
			_active = ""
			_start_ticks = -1
		"HEARTBEAT": _last_hb = _utc_ms(p.observed_at)
		"EXIT":
			_exit = true
			_exit_claim = p.exit_code
			if p.reason == "CANCELLED": _cancel = true
			elif p.reason in ["FAILED","LEASE_EXPIRED"]: _error = true
		"ERROR": _error = true
		"CANCEL": _cancel = true
		"LEASE":
			_last_lease = _utc_ms(p.issued_at)
			_lease_deadline = _ticks() + maxi(0,_last_lease + 30000 - _wall())

func _artifact(ref: Dictionary) -> Dictionary:
	if not S._artifact(ref): return S.failure("IPC_PROTOCOL_ERROR","Invalid ArtifactRef")
	var read := E.read_bytes(_root.path_join(ref.relative_path))
	if not read.ok: return read
	if read.value.size() != ref.byte_length or E.sha(read.value) != ref.sha256: return S.failure("IPC_PROTOCOL_ERROR","Artifact length/SHA mismatch")
	return read

func _attachments(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		if value.has("relative_path"):
			return _artifact(value)
		for field in value:
			var result := _attachments(value[field])
			if not result.ok: return result
	elif typeof(value) == TYPE_ARRAY:
		for child in value:
			var result := _attachments(child)
			if not result.ok: return result
	return S.success(null)

func _read_stage(msg: Dictionary) -> Dictionary:
	var bytes := _artifact(msg.payload_ref_or_inline)
	if not bytes.ok: return bytes
	var decoded := W.verify_stage_result(msg,bytes.value)
	if not decoded.ok: return decoded
	var attached := _attachments(decoded.value.stage_record)
	if not attached.ok: return attached
	return decoded

func poll(identity: Dictionary) -> Dictionary:
	if identity != _identity: return S.failure("IDENTITY_MISMATCH","Poll belongs to another run")
	if _poison: return S.failure("IPC_PROTOCOL_ERROR","Receive stream poisoned")
	var directory := _channel(_incoming())
	if not E.safe_path(directory): return _fail("Linked or escaped channel")
	if not DirAccess.dir_exists_absolute(directory):
		if not _consumed.is_empty(): return _fail("Consumed channel directory disappeared")
		return _renew_if_due([])
	for consumed in _consumed:
		if not FileAccess.file_exists(directory.path_join(consumed)): return _fail("Consumed message disappeared")
	var files := DirAccess.get_files_at(directory)
	var numbered := {}
	for filename in files:
		if filename.ends_with(".tmp"): continue
		if not filename.ends_with(".wire"): return _fail("Unexpected completed channel file")
		var text := filename.trim_suffix(".wire")
		if not text.is_valid_int() or text != str(text.to_int()) or text.to_int() < 0: return _fail("Noncanonical sequence filename")
		var read := E.read_bytes(directory.path_join(filename))
		if not read.ok: return _fail("Unsafe/unreadable IPC file")
		var digest := E.sha(read.value)
		if _consumed.has(filename):
			if _consumed[filename] != digest: return _fail("Consumed message was replaced")
			continue
		numbered[text.to_int()] = {"filename":filename,"bytes":read.value,"sha":digest}
	var keys: Array = numbered.keys()
	keys.sort()
	var messages: Array = []
	for sequence in keys:
		if sequence != _rx: return _fail("Gap or duplicate completed file")
		var item: Dictionary = numbered[sequence]
		var decoded := W.decode_wire("worker_message",item.bytes)
		if not decoded.ok: return _fail("Invalid message wire")
		var accepted := accept_message(decoded.value,_launch)
		if not accepted.ok: return accepted
		_consumed[item.filename] = item.sha
		messages.append(accepted.value)
	if not _worker:
		var deadline := check_deadline()
		if not deadline.ok: return deadline
	return _renew_if_due(messages)

func _renew_if_due(messages: Array) -> Dictionary:
	if not _worker and not _exit and _renew_ticks >= 0 and _ticks() - _renew_ticks >= 1000:
		var renewed := renew_lease()
		if not renewed.ok: return renewed
	return S.success(messages)

func check_deadline() -> Dictionary:
	if _timed_out: return S.failure("TIMEOUT","Stage scheduling deadline already latched")
	if _active != "" and _ticks() - _start_ticks >= _stage_deadline_ms:
		_timed_out = true
		_cancel = true
		if not _worker: send_cancel(_identity,"STAGE_TIMEOUT")
		return S.failure("TIMEOUT","Stage scheduling deadline; await natural return and release")
	return S.success(null)

func _lease_valid() -> bool:
	return _last_lease >= 0 and _ticks() < _lease_deadline and _wall() < _last_lease + 30000

func checkpoint() -> Dictionary:
	if not _worker: return S.failure("IPC_PROTOCOL_ERROR","Worker boundary only")
	var drained := poll(_identity)
	if not drained.ok: return drained
	if _last_wall >= 0 and _wall() < _last_wall: return _fail("Worker clock rollback")
	_last_wall = _wall()
	if not _lease_valid():
		_cancel = true
		return S.failure("LEASE_EXPIRED","Lease lost at cooperative boundary")
	if _cancel or _poison or _error: return S.failure("CANCELLED","Stop chain at boundary")
	return S.success(null)

## These ownership ports are private to the transport/task implementation. Unit
## fixtures may inject OS observations; production always queries its returned PID.
func _begin_owned_process(engine: String, args: PackedStringArray) -> int:
	if _pid > 0: return -1
	_pid = _process_port.create_process(engine,args) if _process_port != null else OS.create_process(engine,args,false)
	return _pid

func _own_file(file: FileAccess) -> void:
	if file != null and file not in _owned_files: _owned_files.append(file)

func _own_callback(owner: Object, signal_name: String, callback: Callable) -> Dictionary:
	if not is_instance_valid(owner) or not owner.has_signal(signal_name) or not callback.is_valid(): return S.failure("RESOURCE_RELEASE_ERROR","Invalid owned callback")
	if not owner.is_connected(signal_name,callback):
		if owner.connect(signal_name,callback) != OK: return S.failure("RESOURCE_RELEASE_ERROR","Cannot connect owned callback")
	_owned_callbacks.append({"owner":weakref(owner),"signal":signal_name,"callback":callback})
	return S.success(null)

func _own_preview(preview: Node) -> void:
	if is_instance_valid(preview) and preview not in _owned_previews: _owned_previews.append(preview)

func _cleanup_owned() -> void:
	if _cleanup_attempted: return
	_cleanup_attempted = true
	for file in _owned_files:
		if file.is_open(): file.close()
	for connection in _owned_callbacks:
		var owner: Object = connection.owner.get_ref()
		if is_instance_valid(owner) and owner.is_connected(connection.signal,connection.callback): owner.disconnect(connection.signal,connection.callback)
	_owned_callbacks.clear()
	for preview in _owned_previews:
		if is_instance_valid(preview):
			_preview_observers.append(weakref(preview))
			preview.queue_free()
	_owned_previews.clear()

func release_error() -> bool: return _release_error

func release_state(identity: Dictionary) -> Dictionary:
	var exited := false
	if identity == _identity and _pid > 0:
		exited = not (_process_port.is_process_running(_pid) if _process_port != null else OS.is_process_running(_pid))
	if exited:
		var code: Variant = null
		if _process_port != null: code = _process_port.get_process_exit_code(_pid)
		elif OS.has_method("get_process_exit_code"): code = OS.call("get_process_exit_code",_pid)
		_release_error = _exit_claim == null or code == null or code != _exit_claim
		_cleanup_owned() # Actual local cleanup, not worker assertions or EXIT alone.
	var handles_closed := _cleanup_attempted
	for file in _owned_files:
		if file.is_open(): handles_closed = false
	var resources_released := _cleanup_attempted and _owned_previews.is_empty()
	for observer in _preview_observers:
		if observer.get_ref() != null: resources_released = false
	return {"process_exited":exited,"file_handles_closed":handles_closed,"callbacks_disconnected":_cleanup_attempted and _owned_callbacks.is_empty(),"preview_resources_released":resources_released}
