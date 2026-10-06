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
var _baked: Dictionary = {}
var _bound: Dictionary = {}
var _quality: Dictionary = {}
var _refs: Dictionary = {}
var _quality_control: RefCounted
var _original: Dictionary = {}

func worker_role() -> String: return "HEADLESS"


func _initialize() -> void: call_deferred("_start")

static func options(args: PackedStringArray) -> Dictionary:
	if args.size() != 4 or args[0] != "--run-dir" or args[2] != "--launch-id" or not E.safe_path(args[1]) or not S._uuid(args[3]):
		return S.failure("ENTRY_ARGUMENT_INVALID","Expected exact run-dir and launch-id arguments")
	return S.success({"run_root":args[1],"launch_id":args[3]})

static func supported_stages(stages: Array) -> Dictionary:
	if stages.is_empty(): return S.failure("REQUEST_INVALID","No selected stage")
	var requirements := {
		"INTENT_BIND":["BAKE"],"INTENT_VALIDATE":["BAKE","INTENT_BIND"],
		"ORIGINAL_GRAPH":["BAKE"],"SOFTLOCK":["ORIGINAL_GRAPH"],
		"ABLATION":["INTENT_VALIDATE"],"TRACE_SEMANTICS":["ORIGINAL_GRAPH"],
		"MILESTONES":["INTENT_VALIDATE","TRACE_SEMANTICS"],
		"GRAPHICAL_REPLAY":["TRACE_SEMANTICS"]}
	var previous := -1
	for stage in stages:
		var index: int = S.STAGES.find(stage)
		if index < 0 or index <= previous: return S.failure("REQUEST_INVALID","Selection differs from formal stage order")
		if index >= 10: return S.failure("DEPENDENCY_PENDING","Selected non-algorithm entry belongs to its own phase",stage)
		for upstream in requirements.get(stage,[]):
			if upstream not in stages: return S.failure("DEPENDENCY_PENDING","Required same-run producer not selected",upstream)
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
	if stage == "BAKE": return S.success(module.bake_authoring(payload,policy.bake_options,snapshot_identity))
	return S.failure("DEPENDENCY_PENDING","This stage requires the same-run instance context",stage)

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

func _call_selected(stage: String) -> Dictionary:
	if stage in ["AUTHORING","BAKE"]:
		var called := call_stage(stage,_job.authoring,_job.snapshot.identity,_job.policy)
		if stage == "BAKE" and called.ok and called.value.ok: _baked = called.value
		return called
	if _baked.is_empty(): return S.failure("MISSING_INPUT","Current successful Bake is required",stage)
	if stage == "INTENT_BIND":
		var table: Array[Dictionary] = []
		table.assign(_job.authoring.resource_table)
		var author := {}
		for entry in table:
			if entry.kind == "INTENT": author = entry.fields
		if author.is_empty(): return S.failure("MISSING_INPUT","Captured Intent missing",stage)
		var binder: Script = load(E.stage_module(stage))
		_bound = binder.bind_intent(author,table,_baked,_job.snapshot.identity)
		return S.success(_bound)
	if stage == "GRAPHICAL_REPLAY":
		if worker_role() != "GRAPHICAL" or DisplayServer.get_name() == "headless": return S.failure("DISPLAY_REQUIRED","Actual graphical execution required")
		var bake := _read_result("BAKE")
		var original := _read_result("ORIGINAL_GRAPH")
		if not bake.ok: return bake
		if not original.ok: return original
		var path := "res://tools/foundation/authoring_acceptance/" + "task_service.gd"
		var service: Node = load(path).new()
		get_root().add_child(service)
		_transport._own_preview(service)
		var record: Dictionary = await service.replay_run(_job.identity,bake.value.stage_record.evidence_refs.canonical,original.value.stage_record.evidence_refs.selected_trace_ref.trace,_job.policy.replay_options)
		service.queue_free()
		await process_frame
		if record.native_result != null and not W.encode_wire("stage_result",{"run_identity":_job.identity,"stage_record":record}).ok: return S.failure("STAGE_RECORD_INVALID","Public replay API returned invalid formal StageRecord",stage)
		return S.success(record.native_result) if record.native_result != null else S.failure("EXECUTION_IDENTITY_MISMATCH",record.reason,stage)
	# One formal native call per accepted IPC start/result boundary. The original
	# live graph stays in this worker; archival graph bytes are never imported.
	if _quality_control == null:
		var guard := "res://tools/foundation/authoring_acceptance/" + "boundary_control.gd"
		_quality_control = load(guard).new(_job.identity,_boundary_status)
	if not _quality_control.checkpoint(stage): return S.failure(_quality_control.reason(),"Stopped before native call",stage)
	var producer: Script = load(E.stage_module(stage))
	var native: Dictionary
	var policy: Dictionary = {}
	var budget: Dictionary = {}
	if stage in ["ORIGINAL_GRAPH","SOFTLOCK","ABLATION"]:
		var search := "res://foundation/solver/" + "search_records.gd"
		policy = load(search).default_policy(0 if stage == "ABLATION" else _job.policy.search_mode)
		policy.validation_options = _job.policy.bake_options.duplicate(true)
		budget = _job.policy.softlock_budget if stage == "SOFTLOCK" else _job.policy.search_budget
	var records := "res://foundation/contracts/" + "contract_records.gd"
	var initial: Dictionary = load(records).initial_state(_baked.level)
	match stage:
		"INTENT_VALIDATE": native = producer.validate(_baked.level,_bound.bound_intent)
		"ORIGINAL_GRAPH":
			_original = producer.explore(_baked.level,initial,policy,budget)
			native = _original
		"SOFTLOCK": native = producer.analyze(_baked.level,_original.graph,budget)
		"ABLATION": native = producer.analyze(_baked.level,initial,_bound.bound_intent,policy,budget)
		"TRACE_SEMANTICS":
			var selected := _read_helper("ORIGINAL_GRAPH","selected_trace.wire","trace","solutiontrace.v1")
			if not selected.ok: return selected
			var key := "res://foundation/contracts/" + "state_key.gd"
			if selected.value.initial_statekey != load(key).build(_baked.level,initial).key: return S.failure("IDENTITY_MISMATCH","Selected trace is not spawn-bound",stage)
			native = producer.validate_semantics(_baked.level,selected.value)
		"MILESTONES":
			var selected := _read_helper("ORIGINAL_GRAPH","selected_trace.wire","trace","solutiontrace.v1")
			if not selected.ok: return selected
			native = producer.analyze_trace(_baked.level,_bound.bound_intent,selected.value)
		_: return S.failure("DEPENDENCY_PENDING","No formal caller",stage)
	var adapter := "res://tools/foundation/" + "authoring_quality/quality_stage_records.gd"
	_quality[stage] = load(adapter).from_native(stage,native,{},policy,budget)
	# The outer return boundary drains lease/cancel before consulting D1.
	# Keep the actual native result intact until that boundary.
	return S.success(native)

func _boundary_status() -> Dictionary:
	return {"identity":_transport._identity,"cancelled":_transport.cancel_observed(),"lease_deadline_msec":_transport._lease_deadline,"stage_deadline_msec":_transport._start_ticks + _job.policy.stage_deadline_ms}
func _read_helper(stage: String, name: String, kind: String, version: String) -> Dictionary:
	var producer := _read_result(stage)
	if not producer.ok: return producer
	var ref: Variant = producer.value.stage_record.evidence_refs.get("selected_trace_ref")
	if stage == "ORIGINAL_GRAPH":
		if ref == null: return S.failure("MISSING_INPUT","No original selected trace")
		ref = ref.trace
	else: ref = producer.value.stage_record.evidence_refs.get("bound_intent")
	if ref == null or ref.relative_path != "artifacts/stages/" + stage + "/" + name or ref.format_version != version: return S.failure("MISSING_INPUT","Helper binding invalid")
	var bytes := E.read_artifact(_job.snapshot.root_path,ref)
	return W.decode_wire(kind,bytes.value) if bytes.ok else bytes

func _read_result(stage: String) -> Dictionary:
	if not _refs.has(stage): return S.failure("MISSING_INPUT","Same-run stage result missing",stage)
	var bytes := E.read_artifact(_job.snapshot.root_path,_refs[stage])
	if not bytes.ok: return bytes
	var decoded := W.decode_wire("stage_result",bytes.value)
	if not decoded.ok: return decoded
	if decoded.value.run_identity != _job.identity or decoded.value.stage_record.stage_id != stage: return S.failure("IDENTITY_MISMATCH","Same-run result identity mismatch")
	return decoded

func _read_canonical() -> Dictionary:
	var bake := _read_result("BAKE")
	if not bake.ok: return bake
	var bytes := E.read_artifact(_job.snapshot.root_path,bake.value.stage_record.evidence_refs.canonical)
	if not bytes.ok: return bytes
	var decoded := Codec.decode(bytes.value.get_string_from_utf8())
	return S.success(decoded.level) if decoded.ok else S.failure("CANONICAL_INVALID","Formal Codec rejected canonical", "BAKE")

func _attachment(stage: String, name: String, kind: String, version: String, value: Dictionary) -> Dictionary:
	var bytes := W.encode_wire(kind,value)
	if not bytes.ok: return bytes
	var path := "artifacts/stages/" + stage + "/" + name
	var written := E.write_new(_job.snapshot.root_path.path_join(path),bytes.value)
	return S.success(E.artifact(path,bytes.value,version)) if written.ok else written

func _stored_search(stage: String, name: String, native: Dictionary) -> Dictionary:
	var stored := native.duplicate(true)
	stored.erase("graph")
	stored["graph_archive_ref"] = null
	if native.graph != null:
		var archive := _attachment(stage,name,"graph_archive","foundationtoolwire.v1",native.graph)
		if not archive.ok: return archive
		stored["graph_archive_ref"] = archive.value
	return S.success(stored)

func _publish_selected(id: String, native: Dictionary, started: String, finished: String, execution: String, reason: String = "") -> Dictionary:
	var bake := _read_result("BAKE")
	if not bake.ok: return bake
	var refs := {"input_manifest":_job.snapshot.input_manifest,"bake_result":_refs.BAKE,"canonical":bake.value.stage_record.evidence_refs.canonical,"level_hash":_baked.level.content_hash,"rule_version":_baked.level.rule_version}
	var records := "res://foundation/contracts/" + "contract_records.gd"
	var key := "res://foundation/contracts/" + "state_key.gd"
	refs["initial_statekey"] = load(key).build(_baked.level,load(records).initial_state(_baked.level)).key
	var item: Dictionary
	if _quality.has(id): item = _quality[id].duplicate(true)
	else: item = R.make_stage_record(id,"4A" if id == "INTENT_BIND" else "3D",E.stage_module(id))
	item.applicability = "APPLICABLE"
	item.execution = execution
	item.reason = "" if execution == "COMPLETED" else (reason if not reason.is_empty() else (item.reason if not item.reason.is_empty() else execution))
	item.started_at = started
	item.finished_at = finished
	item.native_result = native.duplicate(true)
	item.evidence_refs = {}
	if not _quality.has(id):
		item.actual_policy = {}
		item.actual_budget = {}
	else: item.actual_policy.erase("transition_filter") # Public storage descriptor.
	match id:
		"INTENT_BIND":
			refs = {"input_manifest":_job.snapshot.input_manifest,"authoring_payload":_job.manifest.authoring_payload,"bake_result":_refs.BAKE,"canonical":refs.canonical,"source_intent_digest":_job.snapshot.identity.source_intent_digest}
			item.evidence_refs = {"bound_intent":null}
			if native.ok:
				var bound := _attachment(id,"bound_intent.wire","intent","puzzleintent.v1",native.bound_intent)
				if not bound.ok: return bound
				item.evidence_refs["bound_intent"] = bound.value
		"INTENT_VALIDATE","ABLATION","MILESTONES":
			var binding := _read_result("INTENT_BIND")
			if not binding.ok: return binding
			refs["bound_intent"] = binding.value.stage_record.evidence_refs.bound_intent
		"SOFTLOCK": refs["original_graph_result"] = _refs.ORIGINAL_GRAPH
	if id == "ORIGINAL_GRAPH":
		var stored := _stored_search(id,"graph.wire",native)
		if not stored.ok: return stored
		item.native_result = stored.value
		item.evidence_refs = {"graph_archive":stored.value.graph_archive_ref,"selected_trace_ref":null}
		if native.solution_trace != null:
			var trace := _attachment(id,"selected_trace.wire","trace","solutiontrace.v1",native.solution_trace)
			if not trace.ok: return trace
			item.evidence_refs.selected_trace_ref = {"trace":trace.value,"origin":"ORIGINAL_GRAPH"}
	if id == "ABLATION":
		item.evidence_refs = {"baseline_graph_archive":null}
		if native.baseline != null:
			var baseline := _stored_search(id,"baseline_graph.wire",native.baseline)
			if not baseline.ok: return baseline
			item.native_result.baseline = baseline.value
			item.evidence_refs.baseline_graph_archive = baseline.value.graph_archive_ref
	if id in ["TRACE_SEMANTICS","MILESTONES","GRAPHICAL_REPLAY"]:
		var original := _read_result("ORIGINAL_GRAPH")
		if not original.ok: return original
		refs["selected_trace"] = original.value.stage_record.evidence_refs.selected_trace_ref.trace
		refs["selected_trace_digest"] = refs.selected_trace.sha256
	if id == "GRAPHICAL_REPLAY":
		item.actual_policy = _job.policy.replay_options.duplicate(true)
		item.actual_budget = item.actual_policy.duplicate(true)
		item.actual_budget.erase("mode")
		item.actual_budget["validation_options"] = {"max_configurations":4096,"max_checks":100000}
		# Preserve the parity native status; the formal storage projection owns
		# its execution compatibility, not an acceptance verdict.
		item.execution = "INCOMPLETE" if native.status == 3 else ("ERROR" if native.status == 2 else execution)
		item.reason = "" if item.execution == "COMPLETED" else item.execution
	item.input_refs = refs
	var wire := W.encode_wire("stage_result",{"run_identity":_job.identity,"stage_record":item})
	if not wire.ok: return wire
	var path := "artifacts/stages/" + id + "/stage_result.wire"
	var written := E.write_new(_job.snapshot.root_path.path_join(path),wire.value)
	return S.success(E.artifact(path,wire.value,"foundationtoolwire.v1")) if written.ok else written

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
	var bound: Dictionary = _transport.open_channels(_job.identity,args.value.run_root,args.value.launch_id,worker_role(),_job.policy.stages,true)
	if not bound.ok: quit(2); return
	var boundary: Dictionary = _transport.checkpoint()
	if not boundary.ok and boundary.issues[0].code != "CANCELLED": quit(2); return
	var hello: Dictionary = _transport.send("HELLO","",{"launch_id":args.value.launch_id,"worker_role":worker_role(),"engine":_job.identity.versions.engine})
	if not hello.ok: quit(2); return
	if not boundary.ok:
		_end("CANCELLED") # Valid initial lease plus queued cancel: no stage starts.
		return
	for stage in _job.policy.stages:
		if not _transport._skip_reason(stage).is_empty(): continue
		boundary = _transport.checkpoint()
		if not boundary.ok:
			_end("LEASE_EXPIRED" if boundary.issues[0].code == "LEASE_EXPIRED" else ("CANCELLED" if boundary.issues[0].code == "CANCELLED" else "FAILED"))
			return
		var started: String = _transport.utc_now()
		if not _transport.send("STAGE_STARTED",stage,{"started_at":started}).ok: _end("FAILED"); return
		if not _transport.send("HEARTBEAT",stage,{"observed_at":_transport.utc_now(),"phase":"CALLING"}).ok: _end("FAILED"); return
		# Synchronous official calls are allowed to return naturally. Poll the
		# independent cancellation/lease stream only at the following boundary.
		var called: Dictionary = await _call_selected(stage)
		if not called.ok:
			if called.issues[0].code in ["CANCELLED","LEASE_EXPIRED"]:
				_end(called.issues[0].code); return
			_transport.send("ERROR",stage,{"code":"STAGE_CALL_ERROR","message":"Selected formal stage call unavailable"})
			_end("FAILED")
			return
		var native: Dictionary = called.value
		boundary = _transport.checkpoint()
		if _quality.has(stage) and boundary.ok and not _quality_control.checkpoint(stage):
			boundary = S.failure(_quality_control.reason(),"Formal return boundary stopped",stage)
		var execution: String = _quality[stage].execution if _quality.has(stage) else ("COMPLETED" if native.get("ok",true) else "ERROR")
		if stage == "GRAPHICAL_REPLAY": execution = "INCOMPLETE" if native.status == 3 else ("ERROR" if native.status == 2 else "COMPLETED")
		if stage == "BAKE" and not native.ok and native.validation != null and native.validation.status == 2: execution = "INCOMPLETE"
		if not boundary.ok and execution != "ERROR": execution = "CANCELLED" if boundary.issues[0].code == "CANCELLED" else "ERROR"
		var inputs := {"input_manifest":_job.snapshot.input_manifest,"authoring_payload":_job.manifest.authoring_payload}
		var finished: String = _transport.utc_now()
		if finished < started: finished = started
		var stored: Dictionary
		if stage in ["AUTHORING","BAKE"]:
			stored = publish_result(args.value.run_root,_job.identity,stage,native,inputs,_job.policy,started,finished,execution,"" if execution == "COMPLETED" else execution)
		else:
			stored = _publish_selected(stage,native,started,finished,execution,"" if boundary.ok else boundary.issues[0].code)
		if stored.ok: _refs[stage] = stored.value
		if not stored.ok:
			print("D_JOBS_STORAGE_REJECTED ",stage," ",stored.issues)
			_transport.send("ERROR",stage,{"code":"STORAGE_ERROR","message":"Formal Stage Result publication rejected"})
			_end("FAILED"); return
		if not _transport.send("STAGE_RESULT",stage,stored.value).ok: _end("FAILED"); return
		if not boundary.ok:
			_end("LEASE_EXPIRED" if boundary.issues[0].code == "LEASE_EXPIRED" else ("CANCELLED" if boundary.issues[0].code == "CANCELLED" else "FAILED"))
			return
	_end("FINISHED")

func _end(reason: String) -> void:
	var code := 0 if reason in ["FINISHED","CANCELLED"] else 1
	_transport._cleanup_owned()
	_job.clear() # Headless calls hold no scene; graphical replay was naturally disposed.
	var sent: Dictionary = _transport.send("EXIT","",{"reason":reason,"exit_code":code,"file_handles_closed":true,"callbacks_disconnected":true,"preview_resources_released":true})
	quit(code if sent.ok else 1)
