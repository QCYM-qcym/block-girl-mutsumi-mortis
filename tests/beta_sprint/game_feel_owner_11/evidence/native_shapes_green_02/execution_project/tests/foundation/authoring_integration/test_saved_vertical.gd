extends "res://tests/foundation/authoring_integration/test_suite.gd"
## I1 saved-only vertical integration. No gameplay substitute or product rules.
const Capture = preload("res://tools/foundation/authoring_acceptance/snapshot_capture.gd")
const Execution = preload("res://tools/foundation/authoring_acceptance/execution_project.gd")
const Records = preload("res://tools/foundation/authoring_acceptance/run_records.gd")
const Adapter = preload("res://foundation/authoring/authoring_adapter.gd")
const Codec = preload("res://foundation/level/level_codec.gd")
const Wire = preload("res://tools/foundation/authoring_acceptance/tool_wire.gd")
const Loader = preload("res://tools/foundation/authoring_acceptance/canonical_loader.gd")
const HostScene = preload("res://tools/foundation/authoring_acceptance/whitebox_host.tscn")
const Types = preload("res://foundation/contracts/foundation_types.gd")
const Safety = preload("res://foundation/validation/safety_queries.gd")
const SOURCE = "res://tests/foundation/authoring_integration/maps/a_empty/"
const MOVE = {"kind":Types.PuzzleActionKind.MOVE,"face_axis":0}
var baseline := PackedByteArray()
var hosts: Array[Node] = []
var unchanged_sources: Dictionary = {}
var evidence: Dictionary = {}

func run() -> void:
	check(mode()=="Graphical" and DisplayServer.get_name()!="headless","I1 executes on real Graphical display")
	baseline=FileAccess.get_file_as_bytes(SOURCE+"surface.tscn")
	for name in ["level.tscn","inner.tscn","intent.tres"]:
		unchanged_sources[name]=FileAccess.get_file_as_bytes(SOURCE+name)
	check(not baseline.is_empty(),"saved Surface source exists")
	# Every normal failure path returns to this one cleanup, even failed capture/load.
	await _vertical()
	_restore()
	for host in hosts:
		if is_instance_valid(host): host.queue_free()
	hosts.clear()
	await process_frame
	var restored: Dictionary = _capture_bake("restored")
	check(restored.get("ok",false),"restored saved fixture passes formal capture and Bake")
	if restored.get("ok",false) and evidence.has("before"):
		check(restored.baked.level.content_hash==evidence.before.content_hash,"restored canonical returns to baseline content hash")
	evidence["fixture_restored"]=FileAccess.get_file_as_bytes(SOURCE+"surface.tscn")==baseline
	check(evidence.fixture_restored,"fixture baseline bytes restored")
	for name in unchanged_sources:
		check(FileAccess.get_file_as_bytes(SOURCE+name)==unchanged_sources[name],"other author source unchanged: "+name)
	_write(evidence_dir().path_join("vertical-evidence.json"),JSON.stringify(evidence,"\t").to_utf8_buffer())
	finish()

func _vertical() -> void:
	var before: Dictionary = _capture_bake("before")
	if not before.get("ok",false): return
	var first: Dictionary = _load_host(before,"before")
	if not first.get("ok",false): return
	var moved: Dictionary = await _move(first.host,true,"before",before.baked.level)
	evidence.before=_summary(before,first.host,moved)
	_edit_middle()
	var after: Dictionary = _capture_bake("after")
	if not after.get("ok",false): return
	check(before.snapshot.identity.run_id!=after.snapshot.identity.run_id,"after has a fresh run_id")
	check(before.snapshot.identity.snapshot_id!=after.snapshot.identity.snapshot_id,"after has a fresh snapshot_id")
	check(before.snapshot.identity.source_fingerprint!=after.snapshot.identity.source_fingerprint,"saved author field changes source fingerprint")
	check(before.baked.level.content_hash!=after.baked.level.content_hash,"saved author field changes canonical content hash")
	var second: Dictionary = _load_host(after,"after")
	if not second.get("ok",false): return
	check(first.host!=second.host,"after uses a new Host and independently installed Session")
	var rejected: Dictionary = await _move(second.host,false,"after",after.baked.level)
	evidence.after=_summary(after,second.host,rejected)
	# A real valid previous ref is offered to the new SnapshotRef. It must fail,
	# clear current state, and never retain/reload the last successful candidate.
	var stale: Dictionary = second.host.load_artifact(after.snapshot,before.canonical_ref)
	check(not stale.ok,"after snapshot refuses the previous canonical ArtifactRef")
	check(not second.host.is_ready() and second.host.loaded_hash().is_empty(),"failed current load clears candidate instead of historical fallback")
	var recovery: Dictionary = second.host.load_run(after.snapshot.root_path)
	check(recovery.ok and second.host.loaded_hash()==after.baked.level.content_hash,"recovery consumes only after run formal publication")
	evidence.historical_fallback="REJECTED"

func _capture_bake(label: String) -> Dictionary:
	var request := {"entry_kind":"ACCEPT_SAVED","level_ref":{"level_authoring_id":"00000000-0000-4000-8000-000000000001","level_id":&"a_empty","root_source_uri":SOURCE+"level.tscn"},"policy":Records.default_execution_policy("ACCEPT_SAVED")}
	var captured: Dictionary = Capture.capture_saved(request,ProjectSettings.globalize_path("res://").trim_suffix("/"))
	check(captured.ok,label+" formal D_SAVED captures actual saved authoring")
	if not captured.ok:
		print("I1_CAPTURE_FAILURE ",label," ",captured)
		return {"ok":false}
	var snapshot: Dictionary = captured.value
	var verified: Dictionary = Execution.verify(snapshot)
	check(verified.ok,label+" sealed package verifies")
	if not verified.ok: return {"ok":false}
	var intents: Array = verified.value.authoring.resource_table.filter(func(item): return item.kind=="INTENT")
	check(intents.size()==1,label+" explicit author Intent exists in captured payload")
	if intents.size()==1:
		for field in ["required_mechanics","optional_mechanics","expected_milestones","forbidden_bypasses"]:
			check(intents[0].fields.has(field) and intents[0].fields[field].is_empty(),label+" explicit empty Intent collection: "+field)
	var started := _utc()
	var baked: Dictionary = Adapter.bake_authoring(verified.value.authoring,request.policy.bake_options,snapshot.identity)
	check(baked.ok,label+" current A_BAKE uses formal Reader/Baker")
	if not baked.ok:
		print("I1_BAKE_FAILURE ",label," ",baked)
		return {"ok":false}
	check(baked.bake_provenance=={"run_id":snapshot.identity.run_id,"snapshot_id":snapshot.identity.snapshot_id,"source_fingerprint":snapshot.identity.source_fingerprint},label+" Bake provenance is same-run")
	var encoded: Dictionary = Codec.encode(baked.level)
	check(encoded.ok,label+" formal Codec canonical serialization")
	if not encoded.ok: return {"ok":false}
	var bytes: PackedByteArray = encoded.text.to_utf8_buffer()
	var canonical: Dictionary = Execution.artifact("artifacts/stages/BAKE/canonical.level",bytes,"levelcanonical.v1")
	check(_publish(snapshot.root_path,canonical.relative_path,bytes),label+" canonical published first")
	var native: Dictionary = baked.duplicate(true)
	native.level=canonical.duplicate(true)
	var stored := {"run_identity":verified.value.manifest.identity.duplicate(true),"stage_record":{
		"stage_id":"BAKE","owner":"4A","module_ref":"res://foundation/authoring/authoring_adapter.gd","applicability":"APPLICABLE","execution":"COMPLETED","reason":"",
		"input_refs":{"input_manifest":snapshot.input_manifest.duplicate(true),"authoring_payload":verified.value.manifest.authoring_payload.duplicate(true)},
		"actual_policy":request.policy.bake_options.duplicate(true),"actual_budget":request.policy.bake_options.duplicate(true),"native_result":native,
		"evidence_refs":{"canonical":canonical.duplicate(true)},"warnings":[],"started_at":started,"finished_at":_utc()}}
	var wire: Dictionary = Wire.encode_wire("stage_result",stored)
	check(wire.ok,label+" closed formal BAKE storage schema")
	if not wire.ok: return {"ok":false}
	var stage: Dictionary = Execution.artifact(Loader.BAKE_STAGE_PATH,wire.value,"foundationtoolwire.v1")
	check(_publish(snapshot.root_path,stage.relative_path,wire.value),label+" stage_result published after canonical")
	# Sample message sequence for test publication only; no D4 lifecycle claim.
	var message: Dictionary = Wire.encode_wire("worker_message",{"protocol_version":Wire.Schemas.WORKER_PROTOCOL_VERSION,"identity":stored.run_identity,"sequence":0,"kind":"STAGE_RESULT","stage_id":"BAKE","payload_ref_or_inline":stage})
	check(message.ok,label+" formal WorkerMessage ArtifactRef")
	if not message.ok: return {"ok":false}
	check(_publish(snapshot.root_path,"ipc/i1-bake.wire",message.value),label+" publication message last")
	return {"ok":true,"snapshot":snapshot,"baked":baked,"canonical_ref":canonical,"stage_ref":stage}

func _load_host(run_data: Dictionary, label: String) -> Dictionary:
	var host = HostScene.instantiate()
	root.add_child(host)
	hosts.append(host)
	var loaded: Dictionary = host.load_run(run_data.snapshot.root_path)
	check(loaded.ok,label+" D_HOST loads formal same-run BAKE publication")
	if not loaded.ok:
		print("I1_LOAD_FAILURE ",label," ",loaded)
		return {"ok":false}
	check(host.loaded_hash()==run_data.baked.level.content_hash,label+" loaded_hash equals exact new canonical")
	check(loaded.value.snapshot_identity==run_data.snapshot.identity,label+" loaded snapshot identity exact")
	return {"ok":true,"host":host}

func _move(host: Variant, expect_applied: bool, label: String, level: Dictionary) -> Dictionary:
	var initial: String = host.current_state_key().key
	var count: int = host.commit_count()
	var starts: int = host.runtime_observation().transition_starts
	var result: Dictionary = host.submit_action(MOVE.duplicate(true))
	check(result.get("status",-1)==(0 if expect_applied else 1),label+" same floor-to-middle MOVE is "+("APPLIED" if expect_applied else "REJECTED"))
	var safety: Dictionary = {}
	if result.get("status",-1)==0:
		safety=Safety.validate_motion(level,result.previous_state,result.next_state,result.action)
		check(safety.status==0 and safety.issues.is_empty(),label+" formal Safety SAFE")
	var ticket: Dictionary = host.transition_status()
	var finished := [false]
	if host.has_active_transition():
		var tweens := get_processed_tweens().filter(func(tween): return tween.is_valid() and tween.is_running())
		check(tweens.size()==1,label+" actual Presenter Tween running")
		if tweens.size()==1: tweens[0].finished.connect(func(): finished[0]=true,CONNECT_ONE_SHOT)
	var frames := 0
	var deadline := Time.get_ticks_msec()+10000
	while host.has_active_transition() and Time.get_ticks_msec()<deadline:
		frames+=1
		await process_frame
	check(not host.has_active_transition(),label+" reaches idle within test failure boundary")
	if expect_applied:
		check(host.runtime_observation().transition_starts==starts+1 and not ticket.get("is_global",true),label+" local transition_started observed")
		check(finished[0] and frames>0,label+" natural Tween.finished observed")
		check(host.commit_count()-count==1,label+" natural completion commits once")
		check(host.current_state_key().key!=initial,label+" StateKey advances")
	else:
		check(host.runtime_observation().transition_starts==starts,label+" rejected action starts no transition")
		check(host.commit_count()==count,label+" rejected action has no commit")
		check(host.current_state_key().key==initial,label+" rejected action preserves StateKey")
	return {"initial_statekey":initial,"after_statekey":host.current_state_key().key,"status":result.get("status",-1),"safety":safety,"ticket":ticket,"natural_tween":finished[0],"frames":frames,"commit_delta":host.commit_count()-count}

func _summary(data: Dictionary, host: Variant, movement: Dictionary) -> Dictionary:
	return {"run_id":data.snapshot.identity.run_id,"snapshot_id":data.snapshot.identity.snapshot_id,"source_fingerprint":data.snapshot.identity.source_fingerprint,"content_hash":data.baked.level.content_hash,"loaded_hash":host.loaded_hash(),"snapshot_ref":data.snapshot,"canonical_ref":data.canonical_ref,"stage_ref":data.stage_ref,"move":movement}

func _edit_middle() -> void:
	var original := baseline.get_string_from_utf8()
	var marker := '[sub_resource type="Resource" id="MiddleFace4"]'
	var start := original.find(marker)
	check(start>=0,"unique authored middle TOP resource located")
	if start<0: return
	var end := original.find("[",start+marker.length())
	var block := original.substr(start,end-start)
	check(block.count("walkable = true")==1,"middle TOP starts walkable")
	var updated := original.substr(0,start)+block.replace("walkable = true","walkable = false")+original.substr(end)
	check(_write(SOURCE+"surface.tscn",updated.to_utf8_buffer()),"single author field changed and actually saved")
	var before_lines := original.split("\n")
	var after_lines := updated.split("\n")
	var differences := 0
	for index in before_lines.size():
		if before_lines[index]!=after_lines[index]:
			differences+=1
			check(before_lines[index].trim_suffix("\r")=="walkable = true" and after_lines[index].trim_suffix("\r")=="walkable = false","only walkable line changed")
	check(differences==1,"exactly one saved author line differs")
	for name in unchanged_sources:
		check(FileAccess.get_file_as_bytes(SOURCE+name)==unchanged_sources[name],"author edit preserves "+name)
	evidence["only_gameplay_edit"]="middle.TOP.walkable true->false"

func _restore() -> void:
	if not baseline.is_empty(): _write(SOURCE+"surface.tscn",baseline)

func _finalize() -> void:
	# Best effort when the SceneTree exits unexpectedly; wrapper isolates source copies.
	_restore()

func _write(path: String, bytes: PackedByteArray) -> bool:
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_buffer(bytes)
	file.flush()
	file.close()
	return FileAccess.get_file_as_bytes(path)==bytes

func _publish(run_root: String, path: String, bytes: PackedByteArray) -> bool:
	var temporary := run_root.path_join("staging/"+Execution.uuid()+".tmp")
	var destination := run_root.path_join(path)
	if FileAccess.file_exists(destination): return false
	if not Execution.write_new(temporary,bytes).ok: return false
	if DirAccess.make_dir_recursive_absolute(destination.get_base_dir())!=OK: return false
	return DirAccess.rename_absolute(temporary,destination)==OK and FileAccess.get_file_as_bytes(destination)==bytes

func _utc() -> String:
	var now := Time.get_unix_time_from_system()
	return Time.get_datetime_string_from_unix_time(int(now))+".%03dZ" % int((now-floor(now))*1000)
