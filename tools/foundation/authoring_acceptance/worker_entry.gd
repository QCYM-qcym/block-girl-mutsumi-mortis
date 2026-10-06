extends SceneTree
## Controlled headless stage caller. No capture, graph recovery or algorithm double.
const S = preload("res://tools/foundation/authoring_acceptance/wire_schemas.gd")
const W = preload("res://tools/foundation/authoring_acceptance/tool_wire.gd")
const E = preload("res://tools/foundation/authoring_acceptance/execution_project.gd")
const R = preload("res://tools/foundation/authoring_acceptance/run_records.gd")
const T = preload("res://tools/foundation/authoring_acceptance/process_transport.gd")
const Codec = preload("res://foundation/level/level_codec.gd")
var _transport: RefCounted
var _job: Dictionary = {}

func _initialize() -> void: call_deferred("_start")

static func options(args: PackedStringArray) -> Dictionary:
	if args.size() != 4 or args[0] != "--run-dir" or args[2] != "--launch-id" or not E.safe_path(args[1]) or not S._uuid(args[3]):
		return S.failure("ENTRY_ARGUMENT_INVALID","Expected exact run-dir and launch-id arguments")
	return S.success({"run_root":args[1],"launch_id":args[3]})

static func supported_stages(stages: Array) -> Dictionary:
	if stages.is_empty(): return S.failure("REQUEST_INVALID","No selected stage")
	var previous := -1
	for stage in stages:
		if stage not in ["AUTHORING","BAKE"]: return S.failure("DEPENDENCY_PENDING","Selected formal stage dispatcher not delivered",str(stage))
		var index: int = S.STAGES.find(stage)
		if index <= previous: return S.failure("REQUEST_INVALID","Selection differs from formal stage order")
		previous = index
	return S.success(null)

static func context(run_root: String) -> Dictionary:
	var snapshot := E.snapshot_from_run(run_root)
	if not snapshot.ok: return snapshot
	var verified := E.verify(snapshot.value)
	if not verified.ok: return verified
	var actual_root := ProjectSettings.globalize_path("res://").replace("\\","/").trim_suffix("/")
	if actual_root != run_root.path_join("execution/project"): return S.failure("EXECUTION_IDENTITY_MISMATCH","Worker must execute inside its sealed project")
	var unchanged := verify_execution_files(verified.value.files,actual_root)
	if not unchanged.ok: return unchanged
	var identity: Dictionary = verified.value.manifest.identity
	var modules := {}
	for module in identity.versions.modules: modules[module.path] = module.sha256
	var checked := T.check_dependencies(verified.value.policy,modules)
	if not checked.ok: return checked
	for uri in ["res://tools/foundation/authoring_acceptance/worker_entry.gd","res://tools/foundation/authoring_acceptance/process_transport.gd"]:
		if not modules.has(uri) or FileAccess.get_sha256(uri) != modules[uri]: return S.failure("EXECUTION_IDENTITY_MISMATCH","Controlled worker/transport not sealed",uri)
	var supported := supported_stages(verified.value.policy.stages)
	if not supported.ok: return supported
	return S.success({"snapshot":snapshot.value,"identity":identity,"manifest":verified.value.manifest,"policy":verified.value.policy,"authoring":verified.value.authoring})

static func verify_execution_files(frozen_files: Dictionary, project_root: String) -> Dictionary:
	# Parent materialization is not a substitute for this process's boundary.
	# Compare every already-verified blob, including project.godot, before load.
	for uri in frozen_files:
		var bytes := E.read_bytes(project_root.path_join(uri.substr(6)))
		if not bytes.ok or bytes.value != frozen_files[uri]: return S.failure("EXECUTION_IDENTITY_MISMATCH","Materialized execution bytes drifted",uri)
	return S.success(null)

static func call_stage(stage: String, payload: Dictionary, snapshot_identity: Dictionary, policy: Dictionary) -> Dictionary:
	var supported := supported_stages([stage])
	if not supported.ok: return supported
	# The selected formal owner is the only interpreter of authoring values.
	var uri: String = E.stage_module(stage)
	if not ResourceLoader.exists(uri): return S.failure("DEPENDENCY_PENDING","Selected formal module missing",uri)
	var module: Script = load(uri)
	if module == null: return S.failure("DEPENDENCY_PENDING","Selected formal module cannot load",uri)
	if stage == "AUTHORING": return S.success(module.validate_authoring(payload))
	return S.success(module.bake_authoring(payload,policy.bake_options,snapshot_identity))

static func publish_result(run_root: String, identity: Dictionary, stage_id: String, native: Dictionary, inputs: Dictionary, policy: Dictionary, started: String, finished: String, execution: String, reason: String) -> Dictionary:
	var supported := supported_stages([stage_id])
	if not supported.ok: return supported
	var uri: String = E.stage_module(stage_id)
	var record := R.make_stage_record(stage_id,"4A",uri)
	record.execution = execution
	record.reason = reason
	record.input_refs = inputs.duplicate(true)
	record.actual_policy = policy.bake_options.duplicate(true) if stage_id == "BAKE" else {}
	record.actual_budget = record.actual_policy.duplicate(true)
	record.native_result = native.duplicate(true)
	record.evidence_refs = {"canonical":null} if stage_id == "BAKE" else {}
	record.started_at = started
	record.finished_at = finished
	var attachment: Dictionary = {}
	if stage_id == "BAKE" and native.ok:
		var encoded := Codec.encode(native.level)
		if not encoded.ok: return S.failure("CANONICAL_INVALID","Formal Codec rejected Bake output")
		var bytes: PackedByteArray = encoded.text.to_utf8_buffer()
		attachment = {"bytes":bytes,"ref":E.artifact("artifacts/stages/BAKE/canonical.level",bytes,"levelcanonical.v1")}
		record.native_result.level = attachment.ref.duplicate(true)
		record.evidence_refs.canonical = attachment.ref.duplicate(true)
	var wire := W.encode_wire("stage_result",{"run_identity":identity,"stage_record":record})
	if not wire.ok: return wire
	# Validate the entire closed branch before publishing anything. Attachments
	# precede the immutable stage record; transport publishes its message last.
	if not attachment.is_empty():
		var written := E.write_new(run_root.path_join(attachment.ref.relative_path),attachment.bytes)
		if not written.ok: return written
	var path := "artifacts/stages/" + stage_id + "/stage_result.wire"
	var written := E.write_new(run_root.path_join(path),wire.value)
	if not written.ok: return written
	return S.success(E.artifact(path,wire.value,"foundationtoolwire.v1"))

func _start() -> void:
	var args := options(OS.get_cmdline_user_args())
	if not args.ok: quit(2); return
	var checked := context(args.value.run_root)
	if not checked.ok:
		print("D_JOBS_ENTRY_REJECTED ",JSON.stringify(checked.issues))
		quit(2)
		return
	_job = checked.value
	_transport = T.new()
	var bound: Dictionary = _transport.open_channels(_job.identity,args.value.run_root,args.value.launch_id,"HEADLESS",_job.policy.stages,true)
	if not bound.ok: quit(2); return
	var boundary: Dictionary = _transport.checkpoint()
	if not boundary.ok and boundary.issues[0].code != "CANCELLED": quit(2); return
	var hello: Dictionary = _transport.send("HELLO","",{"launch_id":args.value.launch_id,"worker_role":"HEADLESS","engine":_job.identity.versions.engine})
	if not hello.ok: quit(2); return
	if not boundary.ok:
		_end("CANCELLED") # Valid initial lease plus queued cancel: no stage starts.
		return
	for stage in _job.policy.stages:
		boundary = _transport.checkpoint()
		if not boundary.ok:
			_end("LEASE_EXPIRED" if boundary.issues[0].code == "LEASE_EXPIRED" else "CANCELLED")
			return
		var started: String = _transport.utc_now()
		if not _transport.send("STAGE_STARTED",stage,{"started_at":started}).ok: _end("FAILED"); return
		if not _transport.send("HEARTBEAT",stage,{"observed_at":_transport.utc_now(),"phase":"CALLING"}).ok: _end("FAILED"); return
		# Synchronous official calls are allowed to return naturally. Poll the
		# independent cancellation/lease stream only at the following boundary.
		var called := call_stage(stage,_job.authoring,_job.snapshot.identity,_job.policy)
		if not called.ok:
			_transport.send("ERROR",stage,{"code":"STAGE_CALL_ERROR","message":"Selected formal stage call unavailable"})
			_end("FAILED")
			return
		var native: Dictionary = called.value
		boundary = _transport.checkpoint()
		var execution := "COMPLETED" if native.ok else "ERROR"
		if stage == "BAKE" and not native.ok and native.validation != null and native.validation.status == 2: execution = "INCOMPLETE"
		if not boundary.ok and execution != "ERROR": execution = "CANCELLED"
		var inputs := {"input_manifest":_job.snapshot.input_manifest,"authoring_payload":_job.manifest.authoring_payload}
		var finished: String = _transport.utc_now()
		if finished < started: finished = started
		var stored := publish_result(args.value.run_root,_job.identity,stage,native,inputs,_job.policy,started,finished,execution,"" if execution == "COMPLETED" else execution)
		if not stored.ok or not _transport.send("STAGE_RESULT",stage,stored.value if stored.ok else {}).ok: _end("FAILED"); return
		if not boundary.ok:
			_end("LEASE_EXPIRED" if boundary.issues[0].code == "LEASE_EXPIRED" else "CANCELLED")
			return
		if execution != "COMPLETED": _end("FAILED"); return
	_end("FINISHED")

func _end(reason: String) -> void:
	var code := 0 if reason in ["FINISHED","CANCELLED"] else 1
	_job.clear() # No live scene, callbacks or FileAccess are retained by this headless caller.
	var sent: Dictionary = _transport.send("EXIT","",{"reason":reason,"exit_code":code,"file_handles_closed":true,"callbacks_disconnected":true,"preview_resources_released":true})
	quit(code if sent.ok else 1)
