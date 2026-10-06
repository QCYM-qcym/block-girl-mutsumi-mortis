extends "res://tests/foundation/authoring_integration/test_suite.gd"
var F: Script
const S = preload("res://tools/foundation/authoring_acceptance/wire_schemas.gd")
const W = preload("res://tools/foundation/authoring_acceptance/tool_wire.gd")
const E = preload("res://tools/foundation/authoring_acceptance/execution_project.gd")
var T: Script
var Service: Script
var _counter := 0

func run() -> void:
	if mode() == "Graphical":
		T = load("res://tools/foundation/authoring_acceptance/process_transport.gd")
		Service = load("res://tools/foundation/authoring_acceptance/task_service.gd")
		check(DisplayServer.get_name() != "headless","Graphical parent has a real display")
		await _real_pipeline(true)
		finish()
		return
	if mode() == "Real":
		await _real_jobs()
		finish()
		return
	if mode() != "Unit":
		failures.append("NOT_RUN: unsupported D4 test mode")
		finish()
		return
	F = load("res://tests/foundation/authoring_acceptance/owned_worker_fixture.gd")
	doubles.append("res://tests/foundation/authoring_acceptance/owned_worker_fixture.gd")
	var transport_path := "res://tools/foundation/authoring_acceptance/process_transport.gd"
	var service_path := "res://tools/foundation/authoring_acceptance/task_service.gd"
	check(ResourceLoader.exists(transport_path),"D4 transport supports approved streams")
	check(ResourceLoader.exists(service_path),"D4 service supports approved single-task lifecycle")
	if not ResourceLoader.exists(transport_path) or not ResourceLoader.exists(service_path):
		finish()
		return
	T = load(transport_path)
	Service = load(service_path)
	_final_stage_admission()
	await _replay_contract()
	_quality_accounting()
	_timeout_reason_regression()
	_worker_deadline()
	_job_capture()
	_dependencies()
	_streams()
	_lease()
	_stage_results()
	_deadline_and_restart()
	await _review_regressions()
	await _lifecycle()
	await _exit_visibility_race()
	await _editor_rebind()
	_worker_publication()
	await _owned_process_ipc()
	finish()

func _exit_visibility_race() -> void:
	var fixture = F.new()
	var service = Service.new(fixture.capture,fixture)
	get_root().add_child(service)
	var started: Dictionary = service.start(F.request())
	check(started.ok,"exit visibility race owns a launched job")
	fixture.messages_at_exit = [{"kind":"EXIT","payload_ref_or_inline":{"reason":"FINISHED"}}]
	fixture.release_all()
	var final: Dictionary = service.status(started.value.identity)
	check(final.value.lifecycle == "COMPLETED","final IPC is drained after OS exit before deciding crash versus FINISHED")
	check(service._exit_received,"durable EXIT between initial enumeration and OS observation is consumed")
	service.queue_free()
	await process_frame

func _job_capture() -> void:
	var builder: Script = E
	var capture = load("res://tools/foundation/authoring_acceptance/snapshot_capture.gd")
	check(capture.has_method("capture_saved_job"),"job capture delegates saved-source sealing to the sole D2 capture service")
	check(builder.has_method("prepare_job"),"execution builder freezes selected job entry and stage dependencies before input.ready")
	if not builder.has_method("prepare_job"): return
	var root := ProjectSettings.globalize_path("res://").replace("\\","/").trim_suffix("/")
	for stages in [["AUTHORING"],["BAKE"],["AUTHORING","BAKE"]]:
		var request: Dictionary = F.request(stages)
		var prepared: Dictionary = builder.call("prepare_job",root,request.policy)
		check(prepared.ok,"available selected job closure prepares: " + str(stages))
		if not prepared.ok: continue
		for uri in E.BASE_PROTOCOL + ["res://tools/foundation/authoring_acceptance/process_transport.gd","res://tools/foundation/authoring_acceptance/worker_entry.gd"]:
			check(prepared.value.files.has(uri) and prepared.value.files.has(uri + ".uid"),"job strictly seals dependency and UID: " + uri)
		check(not prepared.value.files.has("res://foundation/authoring/intent_binder.gd"),"unselected Binder stays outside job closure")
		check(not prepared.value.files.has("res://tools/foundation/authoring_acceptance/graphical_entry.gd"),"unselected graphical worker stays outside job closure")
	var bad: Dictionary = F.request(["BAKE","AUTHORING"])
	check(not builder.call("prepare_job",root,bad.policy).ok,"selection cannot reorder the existing formal stage plan")

func _final_stage_admission() -> void:
	var entry = load("res://tools/foundation/authoring_acceptance/worker_entry.gd")
	check(entry.supported_stages(["AUTHORING","BAKE","INTENT_BIND"]).ok,"registered A_EDIT enables the formal Binder chain")
	check(entry.supported_stages(S.ACCEPT_STAGES.slice(0,10)).ok,"all ten registered algorithm stages have a worker dispatcher")
	check(ResourceLoader.exists("res://tools/foundation/authoring_acceptance/graphical_entry.gd"),"formal graphical controlled entry exists")

func _real_jobs() -> void:
	var capture = load("res://tools/foundation/authoring_acceptance/snapshot_capture.gd")
	check(capture.has_method("capture_saved_job"),"Real jobs require formal pre-seal selected execution closure")
	if not capture.has_method("capture_saved_job"): return
	T = load("res://tools/foundation/authoring_acceptance/process_transport.gd")
	Service = load("res://tools/foundation/authoring_acceptance/task_service.gd")
	var records = load("res://tools/foundation/authoring_acceptance/run_records.gd")
	var observations: Array = []
	for stages in [["AUTHORING"],["BAKE"],["AUTHORING","BAKE"]]:
		var policy: Dictionary = records.default_execution_policy("ANALYZE_CURRENT")
		policy.stages = stages.duplicate()
		var request := {"entry_kind":"ANALYZE_CURRENT","level_ref":{"level_authoring_id":"00000000-0000-4000-8000-000000000001","level_id":&"d3_action_capable","root_source_uri":"res://tests/foundation/authoring_integration/maps/d3_action_capable/level.tscn"},"policy":policy}
		var service = Service.new()
		get_root().add_child(service)
		var started: Dictionary = service.start(request)
		check(started.ok,"real selected job starts: " + str(stages))
		if not started.ok:
			print("D_JOBS_REAL_START_FAILURE ",started.issues)
			service.queue_free()
			await process_frame
			continue
		check(not service.start(request).ok,"BUSY does not enqueue a second real job")
		var transport: RefCounted = service._transport
		var pid: int = transport._pid
		check(pid > 0 and pid != OS.get_process_id(),"real worker owns independent returned PID")
		var deadline := Time.get_ticks_msec() + 60000
		var status: Dictionary = service.status(started.value.identity)
		while status.ok and not status.value.release_confirmed and Time.get_ticks_msec() < deadline:
			await process_frame
			status = service.status(started.value.identity)
		check(status.ok and status.value.release_confirmed,"actual OS exit plus all three resource conditions release the real slot")
		check(status.ok and status.value.lifecycle == "COMPLETED","real selected work completes without claiming whole-level acceptance PASS")
		var stored: Array = transport.stored_results()
		var omitted: Array = transport.omitted_stages()
		var expected: Array = stages.filter(func(id):return omitted.filter(func(x):return x.stage_id==id).is_empty())
		check(stored.size() == expected.size(),"one immutable stage result per selected formal call")
		for index in stored.size():
			check(stored[index].stage_record.stage_id == stages[index] and stored[index].stage_record.execution == "COMPLETED","stored result preserves formal stage and successful native execution")
			check(stored[index].stage_record.native_result.ok,"native AUTHORING/BAKE result is successful")
		var messages: Array = []
		var files := DirAccess.get_files_at(transport._channel("worker_to_parent"))
		for filename in files:
			var decoded := W.decode_wire("worker_message",E.read_bytes(transport._channel("worker_to_parent").path_join(filename)).value)
			check(decoded.ok,"real filesystem IPC only uses formal WorkerMessage wire")
			if decoded.ok: messages.append(decoded.value)
		messages.sort_custom(func(a,b): return a.sequence < b.sequence)
		check(not messages.is_empty() and messages[0].kind == "HELLO" and messages[0].sequence == 0,"real worker sequence starts with HELLO zero")
		check(not messages.is_empty() and messages.back().kind == "EXIT","real EXIT is durable before observed process exit")
		var kinds: Array = []
		for message in messages: kinds.append(message.kind)
		check("STAGE_STARTED" in kinds and "HEARTBEAT" in kinds and "STAGE_RESULT" in kinds,"real stage lifecycle publishes all required worker evidence")
		for index in messages.size(): check(messages[index].sequence == index,"real worker stream has no gap or duplicate")
		var lease := W.decode_wire("worker_message",E.read_bytes(transport._channel("parent_to_worker").path_join("0.wire")).value)
		check(lease.ok and lease.value.kind == "LEASE" and lease.value.sequence == 0,"parent independently starts at LEASE zero")
		observations.append({"stages":stages,"identity":started.value.identity,"pid":pid,"launch_id":transport._launch,"status":status.value,"messages":messages,"lease":lease.value,"release":transport.release_state(started.value.identity),"exit_received":service._exit_received,"failed":service._failed,"reason":service._reason,"release_error":transport.release_error(),"exit_claim":transport._exit_claim,"transport_exit":transport._exit,"rx":transport._rx})
		service.queue_free()
		await process_frame
	E.write_new(evidence_dir().path_join("real-jobs-evidence.json"),JSON.stringify(observations,"\t").to_utf8_buffer())
	await _real_cancel_at_launch(records)
	await _real_pipeline(false)
	await _real_pipeline(false,"unconstrained")
	await _real_pipeline(false,"budget")

func _real_cancel_at_launch(records: Script) -> void:
	var policy: Dictionary = records.default_execution_policy("ANALYZE_CURRENT")
	policy.stages = ["BAKE"]
	var request := {"entry_kind":"ANALYZE_CURRENT","level_ref":{"level_authoring_id":"00000000-0000-4000-8000-000000000001","level_id":&"d3_action_capable","root_source_uri":"res://tests/foundation/authoring_integration/maps/d3_action_capable/level.tscn"},"policy":policy}
	var service = Service.new()
	get_root().add_child(service)
	var started: Dictionary = service.start(request)
	check(started.ok,"real cancellation owns a formal sealed BAKE worker")
	if not started.ok:
		service.queue_free()
		await process_frame
		return
	var cancelled: Dictionary = service.cancel(started.value.identity)
	check(cancelled.ok and cancelled.value.lifecycle == "CANCELLING","immediate real cancellation acknowledges without claiming release")
	check(not service.start(request).ok,"real cancelled slot remains BUSY until four-condition release")
	var deadline := Time.get_ticks_msec() + 60000
	var final: Dictionary = service.status(started.value.identity)
	while not final.value.release_confirmed and Time.get_ticks_msec() < deadline:
		await process_frame
		final = service.status(started.value.identity)
	check(final.value.release_confirmed and final.value.lifecycle == "CANCELLED","cancel before initial checkpoint is cooperative CANCELLED, not a crash")
	var transport: RefCounted = service._transport
	check(transport._hello and service._exit_received,"real early cancellation still publishes HELLO and EXIT")
	check(not transport.release_error(),"real cancelled EXIT claim agrees with actual OS exit")
	E.write_new(evidence_dir().path_join("real-cancel-evidence.json"),JSON.stringify({"status":final.value,"pid":transport._pid,"hello":transport._hello,"exit":service._exit_received,"release":transport.release_state(started.value.identity),"release_error":transport.release_error()},"\t").to_utf8_buffer())
	service.queue_free()
	await process_frame

func _owned_process_ipc() -> void:
	var policy: Dictionary = F.request([]).policy
	# Empty assigned stream is deliberately a transport fixture, not RunRequest.
	policy.stages = ["BAKE"]
	var identity: Dictionary = F.identity(policy)
	var root: String = evidence_dir().replace("\\","/").path_join("owned_process")
	var launch := E.uuid()
	var parent = T.new()
	check(parent.open_channels(identity,root,launch,"HEADLESS",[]).ok,"real owned-process Unit stream binds fixture identity")
	check(parent.renew_lease().ok,"actual child receives initial durable lease")
	var message := {"protocol_version":S.WORKER_PROTOCOL_VERSION,"identity":identity,"sequence":0,"kind":"HELLO","stage_id":"","payload_ref_or_inline":{"launch_id":launch,"worker_role":"HEADLESS","engine":identity.versions.engine}}
	var wire := W.encode_wire("worker_message",message)
	var context_path := root.path_join("fixture_identity.wire")
	check(wire.ok and E.write_new(context_path,wire.value).ok,"test-only child identity is explicit wire evidence")
	var script_path := root.path_join("owned_process_probe.gd")
	check(E.write_new(script_path,F.process_probe_script().to_utf8_buffer()).ok,"owned process fixture contains no algorithm substitution")
	var project_root := ProjectSettings.globalize_path("res://").replace("\\","/").trim_suffix("/")
	var args := PackedStringArray(["--headless","--path",project_root,"--script",script_path,"--",root,launch,context_path])
	var pid: int = parent._begin_owned_process(OS.get_executable_path(),args)
	check(pid > 0,"transport observes its actually returned OS PID")
	if pid <= 0: return
	var hello := false
	var deadline := Time.get_ticks_msec() + 15000
	while Time.get_ticks_msec() < deadline and OS.is_process_running(pid) and not hello:
		var polled: Dictionary = parent.poll(identity)
		if not polled.ok: break
		for item in polled.value:
			if item.kind == "HELLO": hello = true
		await process_frame
	check(hello,"actual child publishes HELLO through real filesystem transport")
	check(not parent.release_state(identity).process_exited,"HELLO cannot release a live owned process")
	check(parent.send_cancel(identity).ok,"actual owned child receives durable cooperative cancel")
	var exit_seen := false
	while Time.get_ticks_msec() < deadline:
		var polled: Dictionary = parent.poll(identity)
		if polled.ok:
			for item in polled.value:
				if item.kind == "EXIT": exit_seen = true
		if exit_seen and parent.release_state(identity).process_exited: break
		await process_frame
	check(exit_seen,"actual child acknowledges cancel through approved EXIT")
	var released: Dictionary = parent.release_state(identity)
	check(released.process_exited and released.file_handles_closed and released.callbacks_disconnected and released.preview_resources_released,"release gate observes actual OS exit and local ownership cleanup")
	check(not parent.release_error(),"actual owned process exit code matches accepted EXIT")
	check(not parent.pass_eligible(),"real process cancellation cannot publish successful run eligibility")

func _worker_publication() -> void:
	var path := "res://tools/foundation/authoring_acceptance/worker_entry.gd"
	check(ResourceLoader.exists(path),"formal worker entry provides same-run stage publication")
	if not ResourceLoader.exists(path): return
	var entry = load(path)
	check(entry.has_method("verify_execution_files"),"worker rechecks every frozen materialized module and configuration")
	if entry.has_method("verify_execution_files"):
		var project: String = evidence_dir().replace("\\","/").path_join("execution_drift")
		var frozen := {"res://foundation/module.gd":"extends RefCounted\n".to_utf8_buffer(),"res://project.godot":"config_version=5\n".to_utf8_buffer()}
		for uri in frozen: E.write_new(project.path_join(uri.substr(6)),frozen[uri])
		check(entry.verify_execution_files(frozen,project).ok,"unchanged whole materialized closure accepted")
		for uri in frozen:
			var file := FileAccess.open(project.path_join(uri.substr(6)),FileAccess.WRITE)
			file.store_string("altered after parent materialization")
			file.close()
			check(not entry.verify_execution_files(frozen,project).ok,"worker rejects post-materialization drift: " + uri)
			file = FileAccess.open(project.path_join(uri.substr(6)),FileAccess.WRITE)
			file.store_buffer(frozen[uri])
			file.close()
	check(not entry.options(PackedStringArray(["--run-dir=E:/x","--launch-id=bad"])).ok,"worker rejects malformed launch identity")
	var bind: Dictionary = entry.supported_stages(["INTENT_BIND"])
	check(not bind.ok and bind.issues[0].code == "DEPENDENCY_PENDING","selected Binder without its same-run Bake prerequisite is rejected, never skipped")
	check(entry.supported_stages(["AUTHORING","BAKE"]).ok,"available formal stages proceed without Binder/Replay")
	var fixtures = load("res://tests/foundation/authoring/authoring_fixtures.gd")
	var payload: Dictionary = fixtures.payload("minimal")
	var policy: Dictionary = F.request(["AUTHORING","BAKE"]).policy
	var identity: Dictionary = F.identity(policy)
	for uri in [S.STORAGE_OWNERS.AUTHORING[1],"res://foundation/authoring/authoring_adapter.gd"]:
		identity.versions.modules.append({"path":uri,"sha256":FileAccess.get_sha256(uri),"version":null})
	identity.versions.modules.sort_custom(func(a,b): return a.path < b.path)
	identity.execution_digest = W.digest("versions",identity.versions).value
	var snap_id := {"run_id":identity.run_id,"snapshot_id":identity.snapshot_id,"source_fingerprint":identity.source_fingerprint,"source_intent_digest":null}
	var authoring: Dictionary = entry.call_stage("AUTHORING",payload,snap_id,policy)
	check(authoring.ok and authoring.value.ok,"worker invokes formal authoring schema")
	var bake: Dictionary = entry.call_stage("BAKE",payload,snap_id,policy)
	check(bake.ok and bake.value.ok and bake.value.level != null,"worker invokes formal Reader/Baker through sole adapter")
	if not bake.ok or not bake.value.ok: return
	var root: String = evidence_dir().replace("\\","/").path_join("worker_publication")
	var bytes := W.encode_wire("authoring",payload).value as PackedByteArray
	var input := E.artifact("input/authoring.wire",bytes,"levelauthoring.v1")
	var ready := E.artifact("input.ready",bytes,"authoringinputmanifest.v1")
	check(E.write_new(root.path_join(input.relative_path),bytes).ok,"Unit publication binds real frozen authoring bytes")
	check(E.write_new(root.path_join(ready.relative_path),bytes).ok,"Unit publication supplies explicit input reference boundary only")
	var time: String = T.new().utc_now()
	var published: Dictionary = entry.publish_result(root,identity,"BAKE",bake.value,{"input_manifest":ready,"authoring_payload":input},policy,time,time,"COMPLETED","")
	check(published.ok,"worker publishes canonical attachment then closed BAKE stage_result")
	if not published.ok: return
	var result := W.decode_wire("stage_result",E.read_artifact(root,published.value).value)
	check(result.ok and result.value.stage_record.native_result.bake_provenance.run_id == identity.run_id,"published formal evidence preserves same-run provenance")
	var canonical: Dictionary = result.value.stage_record.native_result.level
	check(E.read_artifact(root,canonical).ok,"stage result never precedes its canonical attachment")
	var changed: Dictionary = bake.value.duplicate(true)
	changed.source_map.level_hash = "0".repeat(64)
	check(not entry.publish_result(root,identity,"BAKE",changed,{"input_manifest":ready,"authoring_payload":input},policy,time,time,"COMPLETED","").ok,"immutable stage publication cannot replace historical bytes")

func _editor_rebind() -> void:
	var during_capture = F.new()
	var captured_service = Service.new(during_capture.capture,during_capture)
	get_root().add_child(captured_service)
	captured_service.status_changed.connect(func(value):
		if value.lifecycle == "CAPTURING": captured_service.cancel(value.identity))
	var cancelled_start: Dictionary = captured_service.start(F.request())
	check(not cancelled_start.ok,"capture-time cancellation cannot be reset by start completion")
	check(during_capture.launch_count == 0,"capture-time cancellation never launches a new process")
	check(captured_service.status(during_capture.id).value.lifecycle == "CANCELLED","completed capture cancellation releases only the unlaunched slot")
	captured_service.queue_free()
	await process_frame
	var fixture = F.new()
	var service = Service.new(fixture.capture,fixture)
	get_root().add_child(service)
	service._editor = "44444444-4444-4444-8444-444444444444"
	var views: Array = []
	service.status_changed.connect(func(value): views.append(value.duplicate(true)))
	fixture.id = {"editor_instance_id":service._editor}
	var bound: Dictionary = service.bind_editor_context(fixture)
	check(bound.ok and bound.value == null,"editor bind preserves approved null Result value")
	check(views.size() == 1 and views.back().lifecycle == "IDLE","bind emits current value observation without private service access")
	views.clear()
	var started: Dictionary = service.start(F.request())
	check(started.ok and views.size() == 2,"start exposes capture and owned-running state through approved signal")
	if not started.ok:
		service.queue_free()
		await process_frame
		return
	check(not views.is_empty() and views.back().identity == started.value.identity,"running observation supplies exact run identity")
	service.unbind_editor_context(fixture)
	var replacement = F.new()
	replacement.id = {"editor_instance_id":service._editor}
	views.clear()
	check(service.bind_editor_context(replacement).ok,"fresh Dock can bind surviving cancelling service")
	check(views.size() == 1 and views.back().identity == started.value.identity and views.back().lifecycle == "CANCELLING","re-enabled Dock recovers exact cancelling run via signal")
	check(not service.start(F.request()).ok,"new Dock cannot bypass occupied release gate")
	fixture.release_all()
	service.status(started.value.identity)
	check(views.back().release_confirmed and views.back().lifecycle == "CANCELLED","fresh Dock sees actual release completion")
	service.unbind_editor_context(replacement)
	service.queue_free()
	await process_frame

func _pair(stages: Array = ["BAKE"]) -> Dictionary:
	_counter += 1
	var clock = F.new()
	var req = F.request(stages)
	var id = F.identity(req.policy)
	var path := evidence_dir().replace("\\","/").path_join("channels_" + str(_counter))
	var launch := E.uuid()
	var parent = T.new(clock)
	var worker = T.new(clock)
	check(parent.open_channels(id,path,launch,"HEADLESS",stages,false).ok,"parent opens run/launch-owned channels")
	check(worker.open_channels(id,path,launch,"HEADLESS",stages,true).ok,"worker opens same bound channels")
	return {"parent":parent,"worker":worker,"clock":clock,"id":id,"launch":launch,"root":path}

func _hello(p: Dictionary) -> void:
	check(p.parent.renew_lease().ok,"parent first LEASE publishes seq0")
	check(p.worker.poll(p.id).ok,"worker drains initial lease")
	check(p.worker.checkpoint().ok,"valid lease permits boundary")
	check(p.worker.send("HELLO","",{"launch_id":p.launch,"worker_role":"HEADLESS","engine":p.id.versions.engine}).ok,"worker first HELLO publishes seq0")
	check(p.parent.poll(p.id).ok,"parent verifies first HELLO")

func _message(p: Dictionary, kind: String, sequence: int, stage: String, payload: Dictionary) -> Dictionary:
	return {"protocol_version":S.WORKER_PROTOCOL_VERSION,"identity":p.id.duplicate(true),"sequence":sequence,"kind":kind,"stage_id":stage,"payload_ref_or_inline":payload}

func _dependencies() -> void:
	var bake: Dictionary = T.required_dependencies(F.request().policy)
	check(bake.ok,"BAKE selected dependency profile valid")
	if not bake.ok: return
	check(bake.value.stage_modules == ["res://foundation/authoring/authoring_adapter.gd"],"BAKE selects formal adapter only")
	check(bake.value.base_modules.size() == 7,"seven STRICT base protocol modules")
	check("res://foundation/authoring/intent_binder.gd" not in bake.value.stage_modules,"BAKE does not require Binder")
	check("res://foundation/parity/trace_replayer.gd" not in bake.value.stage_modules,"unselected Replay not required")
	var available := {}
	for uri in bake.value.base_modules + bake.value.stage_modules: available[uri] = "a".repeat(64)
	check(T.check_dependencies(F.request().policy,available).ok,"selected BAKE closure membership accepted")
	var bind: Dictionary = T.required_dependencies(F.request(["INTENT_BIND"]).policy)
	check(bind.ok and bind.value.stage_modules == ["res://foundation/authoring/intent_binder.gd"],"INTENT_BIND requires exact formal Binder")
	var missing: Dictionary = T.check_dependencies(F.request(["INTENT_BIND"]).policy,available)
	check(not missing.ok and missing.issues[0].code == "DEPENDENCY_PENDING","missing selected Binder pending, never skip")
	available["res://foundation/authoring/intent_binder.gd"] = "a".repeat(64)
	check(T.required_dependencies(F.request().policy).value == bake.value,"file availability cannot select stage")
	for uri in bake.value.base_modules:
		var bad := available.duplicate()
		bad.erase(uri)
		check(not T.check_dependencies(F.request().policy,bad).ok,"base strict: " + uri)
	var replay: Dictionary = T.required_dependencies(F.request(["GRAPHICAL_REPLAY"]).policy)
	check(replay.ok and "res://foundation/parity/trace_replayer.gd" in replay.value.stage_modules,"selected Replay requires formal producer")
	var invalid: Dictionary = F.request().policy
	invalid.stages = ["BOGUS"]
	check(not T.required_dependencies(invalid).ok,"unknown stage not guessed")

func _streams() -> void:
	var p := _pair()
	_hello(p)
	check(p.parent.poll(p.id).ok and p.parent.expected_sequence() == 1,"ordinary repeated poll is not duplicate delivery")
	var hb := _message(p,"HEARTBEAT",1,"",{"observed_at":p.parent.utc_now(),"phase":"IDLE"})
	check(p.parent.accept_message(hb,p.launch).ok,"heartbeat accepted without lease renewal")
	check(not p.parent.accept_message(hb,p.launch).ok,"duplicate delivery rejected")
	check(not p.parent.pass_eligible() and p.parent.expected_sequence() == 2,"duplicate poisons stream without cursor advance")
	check(not p.parent.accept_message(_message(p,"HEARTBEAT",2,"",hb.payload_ref_or_inline),p.launch).ok,"poison cannot heal")
	p = _pair()
	_hello(p)
	check(not p.parent.accept_message(_message(p,"HEARTBEAT",2,"",{"observed_at":p.parent.utc_now(),"phase":"IDLE"}),p.launch).ok,"sequence gap rejected")
	check(p.parent.expected_sequence() == 1,"gap retains cursor")
	p = _pair()
	_hello(p)
	check(not p.parent.accept_message(_message(p,"CANCEL",1,"",{"reason":"USER_CANCEL"}),p.launch).ok,"wrong direction rejected")
	p = _pair()
	_hello(p)
	var late := _message(p,"HEARTBEAT",1,"",{"observed_at":p.parent.utc_now(),"phase":"IDLE"})
	check(not p.parent.accept_message(late,E.uuid()).ok and p.parent.pass_eligible(),"late old-launch quarantined, no active poisoning")
	check(p.parent.expected_sequence() == 1,"late launch does not advance")
	late.identity.generation += 1
	check(not p.parent.accept_message(late,p.launch).ok and not p.parent.pass_eligible(),"current launch identity mismatch poisons")
	p = _pair()
	check(not p.worker.send("HEARTBEAT","",{"observed_at":p.worker.utc_now(),"phase":"IDLE"}).ok,"worker cannot publish before HELLO")
	check(p.worker.sent_sequence() == 0,"failed send never consumes sequence")
	p = _pair()
	_hello(p)
	check(not p.parent.accept_message(_message(p,"HELLO",1,"",{"launch_id":p.launch,"worker_role":"HEADLESS","engine":p.id.versions.engine}),p.launch).ok,"second HELLO rejected even at fresh sequence")
	p = _pair()
	_hello(p)
	var path: String = p.root.path_join("ipc/" + p.launch + "/worker_to_parent/0.wire")
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string("tampered")
	file.close()
	check(not p.parent.poll(p.id).ok,"consumed immutable file tamper detected")
	p = _pair()
	_hello(p)
	check(p.worker.send("HEARTBEAT","",{"observed_at":p.worker.utc_now(),"phase":"IDLE"}).ok,"heartbeat file publishes")
	check(p.parent.poll(p.id).ok and p.parent.expected_sequence() == 2,"ordered file polling consumes once")
	p = _pair()
	_hello(p)
	var future := _message(p,"HEARTBEAT",3,"",{"observed_at":p.worker.utc_now(),"phase":"IDLE"})
	check(E.write_new(p.root.path_join("ipc/" + p.launch + "/worker_to_parent/3.wire"),W.encode_wire("worker_message",future).value).ok,"Unit gap file injected")
	check(not p.parent.poll(p.id).ok,"missing expected file plus larger completed file is gap")

func _lease() -> void:
	var p := _pair()
	_hello(p)
	p.clock.advance(30000)
	check(not p.worker.checkpoint().ok,"lease expires at finite boundary")
	check(not p.worker.pass_eligible(),"expiry revokes PASS")
	p = _pair()
	_hello(p)
	for i in 40:
		p.clock.advance(1000)
		check(p.parent.renew_lease().ok,"continuous renewal published " + str(i))
	check(p.worker.checkpoint().ok,"over 30s synchronous call drains continuous renewal backlog without false loss")
	p = _pair()
	_hello(p)
	p.clock.advance(30001)
	var gap_lease := _message(p,"LEASE",1,"",{"issued_at":p.worker.utc_now(),"valid_for_ms":30000})
	check(E.write_new(p.root.path_join("ipc/" + p.launch + "/parent_to_worker/1.wire"),W.encode_wire("worker_message",gap_lease).value).ok,"late fresh renewal gap injected as actual wire file")
	check(not p.worker.checkpoint().ok,"actual coverage gap latches despite fresh last lease")
	p = _pair()
	_hello(p)
	p.clock.wall -= 1
	check(not p.parent.renew_lease().ok,"parent clock rollback fails closed")
	p = _pair()
	_hello(p)
	var next := _message(p,"LEASE",1,"",{"issued_at":p.worker.utc_now(1000),"valid_for_ms":30000})
	check(not p.worker.accept_message(next,p.launch).ok,"future issued_at cannot renew")
	p = _pair()
	_hello(p)
	check(p.parent.send_cancel(p.id).ok,"durable CANCEL publishes next parent sequence")
	check(not p.worker.checkpoint().ok and p.worker.cancel_observed(),"CANCEL drained at boundary prevents next call")
	check(p.parent.cancel_observed(),"parent latch precedes cancel publication")
	p = _pair()
	check(p.parent.renew_lease().ok and p.worker.poll(p.id).ok,"initial lease received before slow startup")
	p.clock.advance(30000)
	check(not p.worker.send("HELLO","",{"launch_id":p.launch,"worker_role":"HEADLESS","engine":p.id.versions.engine}).ok,"expired startup lease cannot authorize HELLO")

func _stage_results() -> void:
	var p := _pair()
	_hello(p)
	check(p.worker.send("STAGE_STARTED","BAKE",{"started_at":p.worker.utc_now()}).ok,"selected assigned stage starts")
	check(p.parent.poll(p.id).ok and p.parent.active_stage() == "BAKE","parent tracks active stage")
	check(p.worker.send("HEARTBEAT","BAKE",{"observed_at":p.worker.utc_now(),"phase":"CALLING"}).ok,"active heartbeat accepted")
	check(p.parent.poll(p.id).ok,"active heartbeat relationship passes")
	check(p.parent.send_cancel(p.id).ok,"cancel during synchronous call latches")
	# Delayed start racing parent cancel is accepted on another launch.
	var q := _pair()
	_hello(q)
	check(q.parent.send_cancel(q.id).ok,"cancel before queued start arrives")
	check(q.parent.accept_message(_message(q,"STAGE_STARTED",1,"BAKE",{"started_at":q.parent.utc_now()}),q.launch).ok,"in-flight assigned start retained under cancellation")
	check(not q.parent.pass_eligible(),"in-flight start never restores PASS")
	check(not p.parent.accept_message(_message(p,"STAGE_STARTED",3,"BAKE",{"started_at":p.parent.utc_now()}),p.launch).ok,"overlapping stage rejected")
	p = _pair()
	_hello(p)
	check(not p.parent.accept_message(_message(p,"STAGE_STARTED",1,"INTENT_BIND",{"started_at":p.parent.utc_now()}),p.launch).ok,"unassigned stage rejected")
	p = _pair()
	_hello(p)
	check(p.parent.accept_message(_message(p,"ERROR",1,"",{"code":"STORAGE_ERROR","message":"Unit storage fault"}),p.launch).ok,"ERROR retained as diagnostic")
	check(not p.parent.pass_eligible(),"ERROR revokes PASS")
	check(not p.parent.accept_message(_message(p,"STAGE_STARTED",2,"BAKE",{"started_at":p.parent.utc_now()}),p.launch).ok,"no new stage after ERROR")
	p = _pair()
	_hello(p)
	var exit_payload := {"reason":"FAILED","exit_code":1,"file_handles_closed":true,"callbacks_disconnected":true,"preview_resources_released":true}
	check(p.parent.accept_message(_message(p,"EXIT",1,"",exit_payload),p.launch).ok,"EXIT declaration validated")
	check(not p.parent.accept_message(_message(p,"HEARTBEAT",2,"",{"observed_at":p.parent.utc_now(),"phase":"IDLE"}),p.launch).ok,"no message after EXIT")
	_terminal_result()

func _terminal_result() -> void:
	var p := _pair()
	# Closed null terminal proves storage path/hash/start binding, no hand-written Level.
	var module := {"path":"res://foundation/authoring/authoring_adapter.gd","sha256":"d".repeat(64),"version":null}
	p.id.versions.modules.append(module)
	p.id.versions.modules.sort_custom(func(a,b): return a.path < b.path)
	p.id.execution_digest = W.digest("versions",p.id.versions).value
	# Reopen both before publication with the adjusted Unit execution identity.
	check(p.parent.open_channels(p.id,p.root,p.launch,"HEADLESS",["BAKE"],false).ok,"fresh unpublished parent may bind Unit module identity")
	check(p.worker.open_channels(p.id,p.root,p.launch,"HEADLESS",["BAKE"],true).ok,"fresh unpublished worker binds same module identity")
	_hello(p)
	var started: String = p.worker.utc_now()
	check(p.worker.send("STAGE_STARTED","BAKE",{"started_at":started}).ok,"terminal test starts BAKE")
	check(p.parent.poll(p.id).ok,"terminal test observes start")
	check(p.parent.send_cancel(p.id).ok,"terminal test cancels started work")
	var unit_bytes := "Unit input attachment only".to_utf8_buffer()
	var ref := E.artifact("input.ready",unit_bytes,"authoringinputmanifest.v1")
	var payload_ref := E.artifact("input/authoring.wire",unit_bytes,"levelauthoring.v1")
	check(E.write_new(p.root.path_join(ref.relative_path),unit_bytes).ok,"Unit input attachment published")
	check(E.write_new(p.root.path_join(payload_ref.relative_path),unit_bytes).ok,"Unit authoring attachment published")
	var stored := {"run_identity":p.id,"stage_record":{"stage_id":"BAKE","owner":"4A","module_ref":module.path,"applicability":"APPLICABLE","execution":"CANCELLED","reason":"cancel observed","input_refs":{"input_manifest":ref,"authoring_payload":payload_ref},"actual_policy":{"max_configurations":4096,"max_checks":100000},"actual_budget":{"max_configurations":4096,"max_checks":100000},"native_result":null,"evidence_refs":{"canonical":null},"warnings":[],"started_at":started,"finished_at":started}}
	var bytes := W.encode_wire("stage_result",stored)
	check(bytes.ok,"approved null terminal BAKE storage encodes")
	if not bytes.ok: return
	var sr := E.artifact("artifacts/stages/BAKE/stage_result.wire",bytes.value,"foundationtoolwire.v1")
	check(E.write_new(p.root.path_join(sr.relative_path),bytes.value).ok,"stage_result published before message")
	check(p.worker.send("STAGE_RESULT","BAKE",sr).ok,"ArtifactRef-only result published")
	check(p.parent.poll(p.id).ok and p.parent.active_stage() == "","terminal clears active exactly once")
	check(not p.parent.pass_eligible(),"late returned evidence after cancel never PASS")
	check(not p.parent.accept_message(_message(p,"STAGE_RESULT",3,"BAKE",sr),p.launch).ok,"second result has no active start")
	var q := _pair()
	_hello(q)
	check(q.parent.accept_message(_message(q,"STAGE_STARTED",1,"BAKE",{"started_at":started}),q.launch).ok,"bad artifact test has active stage")
	check(not q.parent.accept_message(_message(q,"STAGE_RESULT",2,"BAKE",sr),q.launch).ok,"missing or foreign stage artifact rejected")

func _lifecycle() -> void:
	var port = F.new()
	port.root = evidence_dir()
	var service = Service.new(port.capture,port)
	get_root().add_child(service)
	var req = F.request()
	var begun: Dictionary = service.start(req)
	check(begun.ok,"Unit capture/owned launch starts task")
	if not begun.ok:
		service.queue_free()
		await process_frame
		return
	var id: Dictionary = begun.value.identity
	check(not service.start(req).ok and port.capture_count == 1,"BUSY rejects without capture/queue")
	var stopped: Dictionary = service.cancel(id)
	check(stopped.ok and stopped.value.lifecycle == "CANCELLING","cancel ACK is not CANCELLED")
	check(service.cancel(id).ok,"cancel idempotent")
	check(not service.status(id).value.release_confirmed,"slot retained while resources owned")
	port.messages.append({"kind":"EXIT","payload_ref_or_inline":{"reason":"CANCELLED","exit_code":0}})
	check(service.status(id).value.lifecycle == "CANCELLING","EXIT does not prove process exit")
	port.running = false
	check(not service.status(id).value.release_confirmed,"process exit alone insufficient")
	port.handles = true
	check(not service.status(id).value.release_confirmed,"callbacks/resources still hold slot")
	port.callbacks = true
	check(not service.status(id).value.release_confirmed,"preview release required")
	port.resources = true
	var final: Dictionary = service.status(id)
	check(final.ok and final.value.lifecycle == "CANCELLED" and final.value.release_confirmed,"all four release gates open slot")
	port.running = true
	port.handles = false
	port.callbacks = false
	port.resources = false
	check(service.start(req).ok,"new run starts only after complete release")
	check(not service.cancel(id).ok,"late old-run cancel rejected")
	check(port.capture_count == 2,"new task uses new capture identity")
	port.release_all()
	service.status(port.id)
	service.queue_free()
	await process_frame

func _deadline_and_restart() -> void:
	var p := _pair()
	_hello(p)
	check(p.parent.accept_message(_message(p,"STAGE_STARTED",1,"BAKE",{"started_at":p.parent.utc_now()}),p.launch).ok,"deadline test starts assigned work")
	p.clock.advance(300000)
	check(p.parent.has_method("check_deadline"),"transport observes the approved scheduling deadline")
	if not p.parent.has_method("check_deadline"): return
	check(not p.parent.check_deadline().ok and not p.parent.pass_eligible(),"stage deadline stops scheduling and revokes PASS")
	check(p.parent.active_stage() == "BAKE","deadline does not pretend synchronous call released")
	check(not p.parent.open_channels(p.id,p.root,E.uuid(),"HEADLESS",["BAKE"]).ok,"live launch cannot reset sequence")
	var next := _pair()
	check(next.parent.expected_sequence() == 0 and next.worker.sent_sequence() == 0,"new launch starts fresh directional sequences")
	_hello(next)
	check(not next.parent.accept_message(_message(p,"HEARTBEAT",2,"BAKE",{"observed_at":p.parent.utc_now(),"phase":"CALLING"}),p.launch).ok,"old-launch message rejected after new launch")
	check(next.parent.expected_sequence() == 1 and next.parent.pass_eligible(),"old launch does not affect new cursor or eligibility")
	var illegal: Dictionary = F.request().policy
	illegal.stages = ["BAKE","BAKE"]
	check(not T.required_dependencies(illegal).ok,"duplicate stage selection rejected")
	var root := Node.new()
	get_root().add_child(root)
	var editor := "44444444-4444-4444-8444-444444444444"
	var one = Service.get_or_create(root,editor)
	check(one == Service.get_or_create(root,editor),"editor root owns unique service across plugin re-enable")
	var provider = F.new()
	provider.id = {"editor_instance_id":editor}
	check(one.bind_editor_context(provider).ok,"one valid provider binds")
	var second = F.new()
	second.id = provider.id
	check(not one.bind_editor_context(second).ok,"second live provider rejected")
	one.unbind_editor_context(provider)
	check(one.bind_editor_context(second).ok,"unload detaches provider while service survives")
	root.queue_free()
	await process_frame

func _review_regressions() -> void:
	var p := _pair()
	check(p.parent.renew_lease().ok,"startup publishes initial lease")
	p.clock.advance(1000)
	check(p.parent.poll(p.id).ok,"parent polls while worker is verifying startup")
	check(p.parent.sent_sequence() == 2,"missing inbound directory does not stop renewal")
	var port = F.new()
	var transport = T.new(port)
	check(transport.has_method("_begin_owned_process"),"transport keeps explicit owned process/resource ledger")
	if transport.has_method("_begin_owned_process"):
		transport._process_port = port
		check(transport.open_channels(p.id,p.root.path_join("cleanup"),E.uuid(),"HEADLESS",["BAKE"]).ok,"cleanup ledger bound")
		check(transport._begin_owned_process("Unit-owned-port",PackedStringArray()) > 0,"Unit port records only returned owned PID")
		var handle := FileAccess.open(p.root.path_join("held.txt"),FileAccess.WRITE)
		var callback_owner := Node.new()
		get_root().add_child(callback_owner)
		var preview := Node.new()
		get_root().add_child(preview)
		transport._own_file(handle)
		transport._own_callback(callback_owner,"tree_exiting",port.probe)
		transport._own_preview(preview)
		var release: Dictionary = transport.release_state(p.id)
		check(not release.process_exited and not release.file_handles_closed,"live PID and real held file retain cleanup gates")
		check(not release.callbacks_disconnected and not release.preview_resources_released,"actual callback/preview retain cleanup gates")
		port.running = false
		release = transport.release_state(p.id)
		check(release.process_exited and release.file_handles_closed and release.callbacks_disconnected,"owned exit triggers file close and callback disconnect")
		check(not release.preview_resources_released,"queue_free is not yet preview release confirmation")
		await process_frame
		check(transport.release_state(p.id).preview_resources_released,"nonholding preview observation confirms actual deletion")
		callback_owner.queue_free()
		await process_frame
	for reason in ["CANCELLED","FAILED","LEASE_EXPIRED"]:
		var fixture = F.new()
		fixture.root = evidence_dir()
		var service = Service.new(fixture.capture,fixture)
		get_root().add_child(service)
		var started: Dictionary = service.start(F.request())
		check(started.ok,"EXIT reason test starts " + reason)
		fixture.messages.append({"kind":"EXIT","payload_ref_or_inline":{"reason":reason,"exit_code":0 if reason == "CANCELLED" else 1}})
		fixture.release_all()
		var end: Dictionary = service.status(fixture.id)
		check(end.value.lifecycle == ("CANCELLED" if reason == "CANCELLED" else "FAILED"),"worker exit reason never becomes COMPLETED: " + reason)
		service.queue_free()
		await process_frame
	p = _pair()
	_hello(p)
	check(p.parent.accept_message(_message(p,"EXIT",1,"",{"reason":"CANCELLED","exit_code":0,"file_handles_closed":true,"callbacks_disconnected":true,"preview_resources_released":true}),p.launch).ok,"cancelled EXIT accepted without parent race assumption")
	check(not p.parent.pass_eligible(),"abnormal EXIT cannot retain PASS eligibility")
	_completed_before_cancel()
	p = _pair()
	var bad_identity: Dictionary = p.id.duplicate(true)
	bad_identity.execution_digest = "0".repeat(64)
	var fresh = T.new(p.clock)
	check(not fresh.open_channels(bad_identity,p.root.path_join("wrong_digest"),E.uuid(),"HEADLESS",["BAKE"]).ok,"channel rejects execution digest not bound to VersionsRecord wire")
	p = _pair()
	_hello(p)
	var actual_start: String = p.parent.utc_now()
	p.clock.advance(300000)
	check(p.parent.accept_message(_message(p,"STAGE_STARTED",1,"BAKE",{"started_at":actual_start}),p.launch).ok,"delayed start retains actual time evidence")
	check(not p.parent.check_deadline().ok,"delayed delivery cannot restart 300000ms scheduling deadline")
	var port_wait = F.new()
	var service_wait = Service.new(port_wait.capture,port_wait)
	get_root().add_child(service_wait)
	check(service_wait.start(F.request()).ok,"worker cancellation cleanup wait begins")
	port_wait.messages.append({"kind":"EXIT","payload_ref_or_inline":{"reason":"CANCELLED","exit_code":0}})
	check(service_wait.status(port_wait.id).value.lifecycle == "CANCELLING","worker CANCELLED exit waits in CANCELLING until process/resources released")
	port_wait.release_all()
	service_wait.status(port_wait.id)
	service_wait.queue_free()
	await process_frame

func _completed_before_cancel() -> void:
	var p := _pair(["AUTHORING"])
	var module := {"path":S.STORAGE_OWNERS.AUTHORING[1],"sha256":"d".repeat(64),"version":null}
	p.id.versions.modules.append(module)
	p.id.versions.modules.sort_custom(func(a,b): return a.path < b.path)
	p.id.execution_digest = W.digest("versions",p.id.versions).value
	check(p.parent.open_channels(p.id,p.root,p.launch,"HEADLESS",["AUTHORING"]).ok,"returned result race parent identity bound")
	check(p.worker.open_channels(p.id,p.root,p.launch,"HEADLESS",["AUTHORING"],true).ok,"returned result race worker identity bound")
	_hello(p)
	var time: String = p.worker.utc_now()
	check(p.worker.send("STAGE_STARTED","AUTHORING",{"started_at":time}).ok,"race starts assigned call")
	check(p.parent.poll(p.id).ok,"race parent sees start")
	var data := "Unit transport attachment, not authoring execution".to_utf8_buffer()
	var ir := E.artifact("input.ready",data,"authoringinputmanifest.v1")
	var ar := E.artifact("input/authoring.wire",data,"levelauthoring.v1")
	check(E.write_new(p.root.path_join(ir.relative_path),data).ok,"race Unit attachment published")
	check(E.write_new(p.root.path_join(ar.relative_path),data).ok,"race Unit payload attachment published")
	var record := {"run_identity":p.id,"stage_record":{"stage_id":"AUTHORING","owner":"4A","module_ref":module.path,"applicability":"APPLICABLE","execution":"COMPLETED","reason":"","input_refs":{"input_manifest":ir,"authoring_payload":ar},"actual_policy":{},"actual_budget":{},"native_result":{"ok":true,"issues":[]},"evidence_refs":{},"warnings":[],"started_at":time,"finished_at":time}}
	var wire := W.encode_wire("stage_result",record)
	check(wire.ok,"closed completed native value used only for transport race")
	if not wire.ok: return
	var ref := E.artifact("artifacts/stages/AUTHORING/stage_result.wire",wire.value,"foundationtoolwire.v1")
	check(E.write_new(p.root.path_join(ref.relative_path),wire.value).ok,"returned evidence published before cancellation")
	check(p.worker.send("STAGE_RESULT","AUTHORING",ref).ok,"returned message published before worker observed cancel")
	check(p.worker.send("EXIT","",{"reason":"FINISHED","exit_code":0,"file_handles_closed":true,"callbacks_disconnected":true,"preview_resources_released":true}).ok,"worker finishes before it observes parent cancellation")
	check(p.parent.send_cancel(p.id).ok,"parent cancels before polling completed message")
	check(p.parent.poll(p.id).ok,"independent stream race retains legitimate completed evidence")
	check(p.parent.stored_results().size() == 1 and not p.parent.pass_eligible(),"retained native result cannot restore PASS")
	check(p.parent._exit,"queued FINISHED is retained while parent cancellation remains latched")
	p.parent._process_port = p.clock
	check(p.parent._begin_owned_process("Unit-owned-port",PackedStringArray()) > 0,"finished race observes only its owned process")
	p.clock.running = false
	check(p.parent.release_state(p.id).process_exited and not p.parent.release_error(),"queued FINISHED reconciles actual exit under parent cancellation")
	p.clock.actual_exit_code = -1
	check(p.parent.release_state(p.id).process_exited and not p.parent.release_error(),"reaped exit-code observation cannot overwrite the first actual OS result")

func _real_pipeline(graphical: bool, variant: String = "") -> void:
	var base := "res://tests/foundation/authoring_integration/maps/d3_action_capable/"
	var fixture_root := evidence_dir().replace("\\","/").path_join("saved_pipeline" + variant)
	check(DirAccess.make_dir_recursive_absolute(fixture_root) == OK,"test-only author source is saved before real D2 capture")
	var uri_root := ProjectSettings.localize_path(fixture_root).trim_suffix("/") + "/"
	for name in ["level.tscn","surface.tscn","inner.tscn","intent.tres"]:
		var text := FileAccess.get_file_as_string(base + name).replace(base,uri_root)
		if name == "intent.tres" and variant != "unconstrained":
			text = '[gd_resource type="Resource" load_steps=4 format=3]\n[ext_resource type="Script" path="res://foundation/authoring/intent_authoring_resource.gd" id="Intent"]\n[ext_resource type="Script" path="res://foundation/authoring/milestone_authoring_resource.gd" id="Milestone"]\n[sub_resource type="Resource" id="Finish"]\nscript = ExtResource("Milestone")\nauthoring_id = "00000000-0000-4000-8000-000000000500"\nmilestone_id = &"finish"\nrequired = true\npredicate = {"kind": 4}\n' + text.substr(text.find("[resource]")).replace("required_mechanics = []","required_mechanics = [0]").replace("expected_milestones = []",'expected_milestones = [SubResource("Finish")]')
		check(E.write_new(fixture_root.path_join(name),text.to_utf8_buffer()).ok,"saved author fixture remains real source: " + name)
	var runs = load("res://tools/foundation/authoring_acceptance/run_records.gd")
	var selections: Array = [S.ACCEPT_STAGES.slice(0,10)] if graphical else [["AUTHORING","BAKE","INTENT_BIND"],S.ACCEPT_STAGES.slice(0,9)]
	if not variant.is_empty(): selections = [S.ACCEPT_STAGES.slice(0,9)]
	var evidence: Array = []
	for stages in selections:
		var case_checks := checks
		var policy: Dictionary = runs.default_execution_policy("ANALYZE_CURRENT")
		policy.stages = stages.duplicate()
		if variant == "budget": policy.search_budget.max_states = 1
		var request := {"entry_kind":"ANALYZE_CURRENT","level_ref":{"level_authoring_id":"00000000-0000-4000-8000-000000000001","level_id":&"d3_action_capable","root_source_uri":uri_root + "level.tscn"},"policy":policy}
		var service = Service.new()
		get_root().add_child(service)
		var started: Dictionary = service.start(request)
		check(started.ok,"formal selected pipeline launches: " + str(stages))
		if not started.ok:
			print("D_JOBS_PIPELINE_START_REJECTED ",started.issues)
			service.queue_free()
			await process_frame
			continue
		var transport: RefCounted = service._transport
		check(transport._pid > 0 and transport._pid != OS.get_process_id(),"pipeline has an actual owned Godot PID")
		var deadline := Time.get_ticks_msec() + 180000
		var final: Dictionary = service.status(started.value.identity)
		while not final.value.release_confirmed and Time.get_ticks_msec() < deadline:
			await process_frame
			final = service.status(started.value.identity)
		check(final.value.release_confirmed and final.value.lifecycle == "COMPLETED","formal full pipeline completes and releases")
		if not final.value.release_confirmed:
			service.cancel(started.value.identity)
			while not final.value.release_confirmed:
				await process_frame
				final = service.status(started.value.identity) # Natural return; no kill.
		var stored: Array = transport.stored_results()
		var omitted: Array = transport.omitted_stages()
		var expected: Array = stages.filter(func(id):return omitted.filter(func(x):return x.stage_id==id).is_empty())
		check(stored.size() == expected.size(),"every selected algorithm publishes exactly one formal Stage Result")
		for index in stored.size():
			var stage: Dictionary = stored[index].stage_record
			check(index < expected.size() and stage.stage_id == expected[index],"stored stage order follows the approved plan")
			check(stage.execution in (["COMPLETED","INCOMPLETE"] if variant == "budget" else ["COMPLETED"]) and stage.native_result != null,"stage retains actual successful native return: " + stage.stage_id)
			check(stage.module_ref == E.stage_module(stage.stage_id),"producer identity is the formal owner: " + stage.stage_id)
			if stage.stage_id == "INTENT_BIND":
				check(stage.native_result.ok and stage.native_result.source_intent_digest == stage.input_refs.source_intent_digest,"real Binder preserves captured authoritative digest")
			if stage.stage_id == "ORIGINAL_GRAPH":
				check(stage.native_result.status == (2 if variant == "budget" else 0) and stage.native_result.graph_archive_ref != null,"actual FULL_GRAPH search solved and produced archival graph")
				var read := E.read_artifact(transport._root,stage.evidence_refs.graph_archive)
				var graph := W.decode_wire("graph_archive",read.value) if read.ok else read
				check(graph.ok and graph.value.complete == (variant != "budget"),"formal graph_archive wire is closed; never an algorithm input")
			if stage.stage_id == "SOFTLOCK": check(stage.native_result.status == (1 if variant == "budget" else 0) and stage.native_result.softlock_count == (null if variant == "budget" else 0),"same live original graph proves the real Softlock conclusion")
			if stage.stage_id == "ABLATION": check(stage.native_result.baseline != null and stage.evidence_refs.baseline_graph_archive != null,"actual Ablation baseline has its separate archival result")
			if stage.stage_id == "TRACE_SEMANTICS": check(stage.native_result.ok,"actual formal Trace semantics succeeded")
			if stage.stage_id == "MILESTONES": check(stage.native_result.status == 0 and stage.native_result.sample_indices.has(&"finish"),"actual required Goal milestone matches selected original trace")
			if stage.stage_id == "GRAPHICAL_REPLAY":
				check(stage.actual_policy.mode == 1 and stage.native_result.status == 0 and stage.native_result.matched_steps > 0,"formal real graphical Replayer matches through natural Presenter/Tween")
				check(stage.native_result.matched_steps == stage.native_result.trace_length and stage.native_result.actual_statekey == stage.native_result.expected_statekey,"real Runtime endpoint StateKey agrees with same-run selected trace")
		var kinds: Array = []
		var sequence := 0
		for name in DirAccess.get_files_at(transport._channel("worker_to_parent")):
			var decoded := W.decode_wire("worker_message",E.read_bytes(transport._channel("worker_to_parent").path_join(name)).value)
			check(decoded.ok,"pipeline filesystem IPC uses formal WorkerMessage")
			if decoded.ok: kinds.append(decoded.value)
		kinds.sort_custom(func(a,b): return a.sequence < b.sequence)
		var starts: Array = []
		var results: Array = []
		for msg in kinds:
			check(msg.sequence == sequence,"full pipeline worker sequence remains contiguous")
			sequence += 1
			if msg.kind == "STAGE_STARTED": starts.append(msg.stage_id)
			if msg.kind == "STAGE_RESULT": results.append(msg.stage_id)
		check(starts == expected and results == expected,"each selected formal call is accounted for by start and ArtifactRef result")
		check(not kinds.is_empty() and kinds[0].kind == "HELLO" and kinds[0].payload_ref_or_inline.worker_role == ("GRAPHICAL" if graphical else "HEADLESS"),"actual HELLO role agrees with controlled entry")
		check(not kinds.is_empty() and kinds.back().kind == "EXIT" and not transport.release_error(),"formal EXIT agrees with observed OS exit")
		evidence.append({"checks":checks-case_checks,"stages":stages,"pid":transport._pid,"launch_id":transport._launch,"run_dir":transport._root,"status":final.value,"records":stored,"omitted":omitted,"messages":kinds,"release":transport.release_state(started.value.identity)})
		service.queue_free()
		await process_frame
	check(E.write_new(evidence_dir().path_join("pipeline-evidence" + variant + ".json"),JSON.stringify(evidence,"\t").to_utf8_buffer()).ok,"test observations saved separately from formal product stage_result.wire")

func _quality_accounting() -> void:
	var p := _pair(["INTENT_BIND","INTENT_VALIDATE","ORIGINAL_GRAPH","SOFTLOCK","ABLATION","TRACE_SEMANTICS","MILESTONES","GRAPHICAL_REPLAY"])
	check(p.parent.has_method("omitted_stages"),"parent accounts for genuinely unrun quality stages without fabricating IPC")
	if not p.parent.has_method("omitted_stages"): return
	# Unit protocol evidence only, not an algorithm execution claim.
	p.parent._stage_results = [{"stage_record":{"stage_id":"INTENT_BIND","execution":"COMPLETED","native_result":{"ok":true,"bound_intent":{"required_mechanics":[],"optional_mechanics":[],"forbidden_bypasses":[],"expected_milestones":[]}}}}]
	var omissions: Array = p.parent.omitted_stages()
	check(omissions.filter(func(x):return x.stage_id == "ABLATION" and x.applicability == "NOT_APPLICABLE" and x.native_result == null).size() == 1,"empty constraints are parent NOT_APPLICABLE, not STAGE_CALL_ERROR")
	check(omissions.filter(func(x):return x.stage_id == "MILESTONES" and x.applicability == "NOT_APPLICABLE").size() == 1,"empty milestones have no fabricated invocation")
	p.parent._stage_results.append({"stage_record":{"stage_id":"ORIGINAL_GRAPH","execution":"INCOMPLETE","native_result":{"solution_trace":null,"graph_archive_ref":null}}})
	omissions = p.parent.omitted_stages()
	check(omissions.filter(func(x):return x.stage_id == "TRACE_SEMANTICS" and x.execution == "NOT_RUN").size() == 1,"budget-limited graph omits unsupported consumers and preserves domain outcome")
	check(omissions.filter(func(x):return x.stage_id == "GRAPHICAL_REPLAY").size() == 1,"missing selected trace cannot start graphical work")
func _timeout_reason_regression() -> void:
	var p := _pair(["BAKE"])
	_hello(p)
	check(p.parent.send_cancel(p.id,"STAGE_TIMEOUT").ok,"approved scheduler timeout command is sent")
	var stop: Dictionary = p.worker.checkpoint()
	check(not stop.ok and stop.issues[0].code == "TIMEOUT","worker retains scheduling timeout as ERROR cause, never ordinary user cancellation")
func _replay_contract() -> void:
	var service = Service.new()
	get_root().add_child(service)
	check(service.has_method("replay_run"),"formal replay_run returns a StageRecord and uses the same heavy slot")
	if service.has_method("replay_run"):
		var rejected: Dictionary = await service.replay_run({}, {}, {}, {})
		check(rejected.stage_id == "GRAPHICAL_REPLAY" and rejected.native_result == null and rejected.execution == "NOT_RUN","invalid replay does not invent native evidence or bypass a controlled entry")
		check(service._released,"rejected replay does not take or leak the heavy slot")
	service.queue_free()
	await process_frame
func _worker_deadline() -> void:
	var p := _pair(["BAKE"])
	_hello(p)
	p.worker._stage_deadline_ms = 20
	check(p.worker.send("STAGE_STARTED","BAKE",{"started_at":p.worker.utc_now()}).ok,"worker records actual native-call start")
	p.clock.advance(20)
	var observed: Dictionary = p.worker.checkpoint()
	check(not observed.ok and observed.issues[0].code == "TIMEOUT","worker owns the per-call deadline even before parent's next frame")