extends "res://tests/foundation/authoring_integration/test_suite.gd"
const F = preload("res://tests/foundation/authoring_acceptance/owned_worker_fixture.gd")
const S = preload("res://tools/foundation/authoring_acceptance/wire_schemas.gd")
const W = preload("res://tools/foundation/authoring_acceptance/tool_wire.gd")
const E = preload("res://tools/foundation/authoring_acceptance/execution_project.gd")
var T: Script
var Service: Script
var _counter := 0

func run() -> void:
	if mode() != "Unit":
		check(false,"DEPENDENCY_PENDING: current 8f7 D_SAVED closure receipt and Real stage/entry delivery required")
		finish()
		return
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
	_dependencies()
	_streams()
	_lease()
	_stage_results()
	_deadline_and_restart()
	await _review_regressions()
	await _lifecycle()
	await _editor_rebind()
	_worker_publication()
	await _owned_process_ipc()
	finish()

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
	check(not bind.ok and bind.issues[0].code == "DEPENDENCY_PENDING","unimplemented selected Binder is pending, never skipped")
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
	var during_capture := F.new()
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
	var fixture := F.new()
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
	var replacement := F.new()
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
	var clock := F.new()
	var req := F.request(stages)
	var id := F.identity(req.policy)
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
	var port := F.new()
	port.root = evidence_dir()
	var service = Service.new(port.capture,port)
	get_root().add_child(service)
	var req := F.request()
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
	var provider := F.new()
	provider.id = {"editor_instance_id":editor}
	check(one.bind_editor_context(provider).ok,"one valid provider binds")
	var second := F.new()
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
	var port := F.new()
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
		var fixture := F.new()
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
	var port_wait := F.new()
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
	check(p.parent.send_cancel(p.id).ok,"parent cancels before polling completed message")
	check(p.parent.poll(p.id).ok,"independent stream race retains legitimate completed evidence")
	check(p.parent.stored_results().size() == 1 and not p.parent.pass_eligible(),"retained native result cannot restore PASS")
