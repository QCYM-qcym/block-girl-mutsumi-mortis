extends "res://tests/foundation/authoring_integration/test_suite.gd"
## D3 graphical integration. Consumes the same sealed saved capture, registered
## A_BAKE provenance, canonical Codec bytes, RuntimeSession and Presenter.
const Capture = preload("res://tools/foundation/authoring_acceptance/snapshot_capture.gd")
const Execution = preload("res://tools/foundation/authoring_acceptance/execution_project.gd")
const Records = preload("res://tools/foundation/authoring_acceptance/run_records.gd")
const Adapter = preload("res://foundation/authoring/authoring_adapter.gd")
const Codec = preload("res://foundation/level/level_codec.gd")
const Host = preload("res://tools/foundation/authoring_acceptance/whitebox_host.gd")
const Types = preload("res://foundation/contracts/foundation_types.gd")
const StateKey = preload("res://foundation/contracts/state_key.gd")
const Goal = preload("res://foundation/rules/goal_evaluator.gd")
const WhiteboxEntry = preload("res://tools/foundation/authoring_acceptance/whitebox_entry.gd")
const Wire = preload("res://tools/foundation/authoring_acceptance/tool_wire.gd")
const Loader = preload("res://tools/foundation/authoring_acceptance/canonical_loader.gd")

func run() -> void:
	check(mode() == "Graphical" and DisplayServer.get_name() != "headless", "D3 uses a real graphical SceneTree")
	check(WhiteboxEntry != null,"manual same-run entry script parses")
	var project_root := ProjectSettings.globalize_path("res://").trim_suffix("/")
	var request := {"entry_kind":"ACCEPT_SAVED","level_ref":{"level_authoring_id":"00000000-0000-4000-8000-000000000001","level_id":&"authoring_minimal","root_source_uri":"res://tests/foundation/authoring/fixtures/minimal/level.tscn"},"policy":Records.default_execution_policy("ACCEPT_SAVED")}
	var captured := Capture.capture_saved(request,project_root)
	check(captured.ok,"real saved capture supplies this graphical run")
	if not captured.ok:
		finish()
		return
	var checked := Execution.verify(captured.value)
	check(checked.ok,"sealed input verified before Bake")
	if not checked.ok:
		finish()
		return
	var bake_started := _utc_now()
	var baked := Adapter.bake_authoring(checked.value.authoring,request.policy.bake_options,captured.value.identity)
	var bake_finished := _utc_now()
	check(baked.ok,"registered A_BAKE supplies the same captured level")
	if not baked.ok:
		finish()
		return
	check(baked.bake_provenance == {"run_id":captured.value.identity.run_id,"snapshot_id":captured.value.identity.snapshot_id,"source_fingerprint":captured.value.identity.source_fingerprint},"R5 A_BAKE provenance binds this exact saved snapshot")
	var encoded := Codec.encode(baked.level)
	check(encoded.ok,"formal Codec produces this run canonical")
	if not encoded.ok:
		finish()
		return
	var bytes: PackedByteArray = encoded.text.to_utf8_buffer()
	var ref := Execution.artifact("artifacts/stages/BAKE/canonical.level",bytes,"levelcanonical.v1")
	check(_publish_bytes(captured.value.root_path,ref.relative_path,bytes),"same-run canonical artifact persisted")
	var native := baked.duplicate(true)
	native.level = ref.duplicate(true)
	var stored := {"run_identity":checked.value.manifest.identity.duplicate(true),"stage_record":{
		"stage_id":"BAKE","owner":"4A","module_ref":"res://foundation/authoring/authoring_adapter.gd","applicability":"APPLICABLE","execution":"COMPLETED","reason":"",
		"input_refs":{"input_manifest":captured.value.input_manifest.duplicate(true),"authoring_payload":checked.value.manifest.authoring_payload.duplicate(true)},
		"actual_policy":request.policy.bake_options.duplicate(true),"actual_budget":request.policy.bake_options.duplicate(true),"native_result":native,
		"evidence_refs":{"canonical":ref.duplicate(true)},"warnings":[],"started_at":bake_started,"finished_at":bake_finished}}
	var encoded_stage := Wire.encode_wire("stage_result",stored)
	check(encoded_stage.ok,"real BAKE return has the formal closed storage shape")
	if not encoded_stage.ok:
		print("STORAGE_DIAGNOSTIC ",encoded_stage.issues)
		finish()
		return
	var stage_ref := Execution.artifact(Loader.BAKE_STAGE_PATH,encoded_stage.value,"foundationtoolwire.v1")
	check(_publish_bytes(captured.value.root_path,stage_ref.relative_path,encoded_stage.value),"formal BAKE stage published after canonical")
	# Test-only filename and sample sequence; this does not establish D4 stream semantics.
	var message := {"protocol_version":Wire.Schemas.WORKER_PROTOCOL_VERSION,"identity":stored.run_identity.duplicate(true),"sequence":7,"kind":"STAGE_RESULT","stage_id":"BAKE","payload_ref_or_inline":stage_ref}
	var encoded_message := Wire.encode_wire("worker_message",message)
	check(encoded_message.ok and _publish_bytes(captured.value.root_path,"ipc/test-bake.wire",encoded_message.value),"actual R5 Bake provenance and canonical ref sealed together")
	var packed: PackedScene = load("res://tools/foundation/authoring_acceptance/whitebox_host.tscn")
	check(packed != null,"D3 graphical host scene is loadable")
	if packed == null:
		finish()
		return
	var host: Variant = packed.instantiate()
	root.add_child(host)
	check(get_root().get_viewport().get_camera_3d() != null,"host runs under the real graphical viewport")
	var loaded: Dictionary = host.load_artifact(captured.value,ref)
	check(loaded.ok,"canonical artifact installs into the real whitebox host")
	check(host.loaded_hash() == baked.level.content_hash,"loaded hash equals current canonical content hash")
	if not loaded.ok:
		print("D3_LOAD_DIAGNOSTIC ",loaded.issues)
		host.queue_free()
		await process_frame
		finish()
		return
	check(host.is_ready() and host.runtime_observation().presenter_ready,"host owns the formal Session and Presenter instances")
	check(host.get("session") == null,"source delivery must not expose a writable RuntimeSession")
	var loader_api := Loader.new()
	check(loader_api.has_method("load_run"),"source delivery reads formal BAKE publication from run root")
	check(not loader_api.has_method("decode_bake_receipt"),"custom JSON receipt is not a product decode interface")
	var initial_key: Dictionary = host.current_state_key()
	check(initial_key.ok,"initial loaded runtime has a canonical StateKey")
	var initial_statekey: String = initial_key.key
	var loaded_hash: String = host.loaded_hash()
	var initial_commit_count: int = host.commit_count()

	# Rejections and errors must come from the actual runtime. These actions are
	# submitted unchanged; the host neither predicts nor reproduces their rules.
	var mapped_move: Dictionary = host.request_move(Vector2.RIGHT,Basis.IDENTITY)
	check(mapped_move.has("status"),"MOVE reaches RuntimeSession as a semantic action")
	check(await _wait_until_idle(host),"MOVE transition reaches formal IDLE or is rejected")
	var actions_before_rotation_map: int = host.action_records().size()
	var rotation_mapping: Dictionary = host.request_rotation(Types.RotationIntent.TURN_LEFT,Basis.IDENTITY)
	check(not rotation_mapping.ok and host.action_records().size() == actions_before_rotation_map,"InputMapper respects this saved world's rotation authorization")
	var rotation: Dictionary = host.submit_action({"kind":Types.PuzzleActionKind.ROTATE_SURFACE,"rotation_delta":22})
	check(rotation.has("status"),"ROTATION semantic action reaches RuntimeSession")
	check(await _wait_until_idle(host),"ROTATION reaches formal IDLE or is rejected")
	var shift: Dictionary = host.submit_action({"kind":Types.PuzzleActionKind.SHIFT_WORLD})
	check(shift.has("status"),"SHIFT semantic action reaches RuntimeSession")
	check(await _wait_until_idle(host),"SHIFT reaches formal IDLE or is rejected")
	var use: Dictionary = host.submit_action({"kind":Types.PuzzleActionKind.USE_FACE_TRANSITION,"transition_id":&"missing_transition"})
	check(use.has("status"),"USE semantic action reaches RuntimeSession")
	check(await _wait_until_idle(host),"USE reaches formal IDLE or is rejected")
	var goal: Dictionary = host.evaluate_goal()
	check(goal.ok and goal.is_goal,"GOAL is evaluated by the formal GoalEvaluator")
	var before_reset: Dictionary = host.current_state_key()
	var reset: Dictionary = host.reset_run()
	check(reset.ok and reset.value.statekey == initial_statekey,"RESET restores the formal initial RuntimeSession state")
	check(host.current_state_key().key == initial_statekey,"RESET restores the identical StateKey")
	check(host.commit_count() == 0,"RESET uses official RuntimeSession commit reset semantics")
	check(host.action_records().size() == 5,"action evidence records MOVE, ROTATION, SHIFT, USE and RESET")
	check(host.action_records().all(func(row: Dictionary) -> bool: return not row.before_statekey.is_empty() and not row.after_statekey.is_empty()),"every action record contains before/after StateKey")
	check(host.action_records()[0].action.kind == Types.PuzzleActionKind.MOVE and host.action_records()[1].action.kind == Types.PuzzleActionKind.ROTATE_SURFACE and host.action_records()[2].action.kind == Types.PuzzleActionKind.SHIFT_WORLD and host.action_records()[3].action.kind == Types.PuzzleActionKind.USE_FACE_TRANSITION,"Runtime log preserves the four semantic action kinds")
	check(host.action_records().slice(0,4).all(func(row: Dictionary) -> bool: return row.result.status in [0,1,2]),"each semantic action records the formal RuntimeSession status")
	check(host.action_records()[0].result.status == 1 and host.action_records()[1].result.status == 1 and host.action_records()[2].result.status == 1 and host.action_records()[3].result.status == 2,"sealed minimal D_SAVED content yields formal MOVE/ROTATION/SHIFT rejection and USE error")
	check(host.action_records().slice(0,4).all(func(row: Dictionary) -> bool: return row.before_statekey == row.after_statekey and row.commit_count == 0),"rejected/error operations keep logical state and commit count unchanged")
	check(host.runtime_observation().transition_starts == 0 and not host.has_active_transition(),"the saved minimal level proposes no visual transition for its rejected/error actions")
	check(initial_commit_count == 0 and before_reset.ok,"initial/reset boundary is recorded without synthetic commits")

	var state_before_stale: String = host.current_state_key().key
	var commits_before_stale: int = host.commit_count()
	var generation_now: int = host.runtime_observation().generation
	host.on_visual_finished(701,generation_now,false)
	host.on_visual_finished(701,generation_now-1,true)
	host.on_visual_finished(701,generation_now,false)
	check(host.runtime_observation().ignored_visual_callbacks == 3,"old token, old generation and duplicate finished callbacks are ignored")
	check(host.commit_count() == commits_before_stale and host.current_state_key().key == state_before_stale,"late callbacks cannot commit or replace StateKey")
	check(host.loaded_hash() == loaded_hash,"failed/stale operations preserve the loaded canonical hash")
	print("D3_ACTION_EVIDENCE ",JSON.stringify({"loaded_hash":loaded_hash,"initial_statekey":initial_statekey,"goal":goal,"reset":reset,"actions":host.action_records(),"transition_starts":host.runtime_observation().transition_starts,"late_callbacks":{"ignored":host.runtime_observation().ignored_visual_callbacks,"commit_count":host.commit_count()}}))

	# Negative fixtures mutate only this disposable test run, never a product run.
	var run_root: String = captured.value.root_path
	var stage_path := run_root.path_join(Loader.BAKE_STAGE_PATH)
	var message_path := run_root.path_join("ipc/test-bake.wire")
	check(Wire.decode_wire("stage_result",encoded_stage.value).ok,"same-run Bake receipt has a closed canonical ArtifactRef")
	var foreign := stored.duplicate(true)
	foreign.run_identity.snapshot_id = Execution.uuid()
	foreign.stage_record.native_result.bake_provenance.snapshot_id = foreign.run_identity.snapshot_id
	foreign.stage_record.native_result.source_map.snapshot_id = foreign.run_identity.snapshot_id
	_replace_test_publication(run_root,foreign)
	var provenance_failure: Dictionary = host.load_run(run_root)
	check(not provenance_failure.ok and host.loaded_hash().is_empty() and not host.is_ready(),"foreign Bake provenance cannot be reused with this snapshot")
	_write_bytes(stage_path,encoded_stage.value)
	_write_bytes(message_path,encoded_message.value)
	check(host.load_run(run_root).ok,"restoring same-run Bake provenance restores valid loading")
	var wrong_snapshot: Dictionary = captured.value.duplicate(true)
	wrong_snapshot.identity.snapshot_id = Execution.uuid()
	var identity_failure: Dictionary = host.load_artifact(wrong_snapshot,ref)
	check(not identity_failure.ok and host.loaded_hash().is_empty() and not host.is_ready(),"snapshot mismatch clears the earlier loaded candidate")
	var bad_ref: Dictionary = ref.duplicate(true)
	bad_ref.sha256 = "0".repeat(64)
	var digest_failure: Dictionary = host.load_artifact(captured.value,bad_ref)
	check(not digest_failure.ok and host.loaded_hash().is_empty() and not host.is_ready(),"canonical digest mismatch fails closed")
	var malformed_bytes := "{malformed".to_utf8_buffer()
	_write_bytes(run_root.path_join(ref.relative_path),malformed_bytes)
	check(FileAccess.get_file_as_bytes(run_root.path_join(ref.relative_path)) == malformed_bytes,"malformed canonical negative is stored only in this run")
	var malformed := stored.duplicate(true)
	malformed.stage_record.native_result.level = Execution.artifact(ref.relative_path,malformed_bytes,ref.format_version)
	malformed.stage_record.evidence_refs.canonical = malformed.stage_record.native_result.level.duplicate(true)
	_replace_test_publication(run_root,malformed)
	var decode_failure: Dictionary = host.load_run(run_root)
	check(not decode_failure.ok and host.loaded_hash().is_empty() and not host.is_ready(),"formal Codec failure leaves candidate null")
	_write_bytes(run_root.path_join(ref.relative_path),bytes)
	_write_bytes(stage_path,encoded_stage.value)
	_write_bytes(message_path,encoded_message.value)
	var recovered: Dictionary = host.load_run(run_root)
	check(recovered.ok and host.loaded_hash() == baked.level.content_hash,"a fresh valid artifact loads after clearing failures")
	check(recovered.ok and recovered.value.input_refs == {"bake_stage_result":stage_ref,"canonical_content_hash":baked.level.content_hash,"snapshot_id":stored.run_identity.snapshot_id,"source_fingerprint":stored.run_identity.source_fingerprint},"formal runtime input binding has exactly the approved four fields")
	_source_delivery_checks(host,run_root,stored,encoded_stage.value,encoded_message.value)
	print("D3_SOURCE_STAGING_ONLY: REJECTION_AND_ERROR_PATH_GREEN; FINAL_LOCAL_GLOBAL_TWEEN_NOT_RUN; UPDATED_D_SAVED_EXECUTION_CLOSURE_PENDING")
	host.queue_free()
	await process_frame
	finish()


func _wait_until_idle(host: Variant, timeout_ms: int = 5000) -> bool:
	var started := Time.get_ticks_msec()
	while host.has_active_transition():
		if Time.get_ticks_msec()-started >= timeout_ms:
			return false
		await process_frame
	return true

func _write_bytes(path: String, bytes: PackedByteArray) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_buffer(bytes)
	file.flush()
	file.close()

func _utc_now() -> String:
	var now := Time.get_unix_time_from_system()
	return Time.get_datetime_string_from_unix_time(int(now)) + ".%03dZ" % int((now-floor(now))*1000)

func _publish_bytes(run_root: String, relative: String, bytes: PackedByteArray) -> bool:
	var temporary := run_root.path_join("staging/" + Execution.uuid() + ".tmp")
	var destination := run_root.path_join(relative)
	if FileAccess.file_exists(destination): return false
	if not Execution.write_new(temporary,bytes).ok: return false
	if DirAccess.make_dir_recursive_absolute(destination.get_base_dir()) != OK: return false
	return DirAccess.rename_absolute(temporary,destination) == OK and FileAccess.get_file_as_bytes(destination) == bytes

func _replace_test_publication(run_root: String, stored: Dictionary) -> void:
	var encoded := Wire.encode_wire("stage_result",stored)
	check(encoded.ok,"negative fixture remains a formal schema-valid stage")
	if not encoded.ok:
		print("NEGATIVE_SCHEMA_DIAGNOSTIC ",encoded.issues)
		return
	var ref := Execution.artifact(Loader.BAKE_STAGE_PATH,encoded.value,"foundationtoolwire.v1")
	var message := Wire.encode_wire("worker_message",{"protocol_version":Wire.Schemas.WORKER_PROTOCOL_VERSION,"identity":stored.run_identity.duplicate(true),"sequence":7,"kind":"STAGE_RESULT","stage_id":"BAKE","payload_ref_or_inline":ref})
	check(message.ok,"negative fixture has a formal publication message")
	if not message.ok: return
	_write_bytes(run_root.path_join(Loader.BAKE_STAGE_PATH),encoded.value)
	_write_bytes(run_root.path_join("ipc/test-bake.wire"),message.value)

func _source_delivery_checks(host: Variant, run_root: String, stored: Dictionary, stage_bytes: PackedByteArray, message_bytes: PackedByteArray) -> void:
	var exposed := false
	for property in host.get_property_list():
		var value: Variant = host.get(property.name)
		if value is RefCounted and not value is Script:
			if value.get_script() == Host.Session or value.get_script() == preload("res://foundation/runtime/kernel_port.gd"): exposed = true
	check(not exposed,"reflection properties expose neither RuntimeSession nor Kernel")
	var capabilities: Dictionary = host.get("_runtime")
	var keys: Array = capabilities.keys()
	keys.sort()
	check(capabilities.is_read_only() and keys == ["action","close","input_frame","observe","reset"],"reflection exposes only fixed capabilities without finish or arbitrary dispatch")
	var host_source := FileAccess.get_file_as_string("res://tools/foundation/authoring_acceptance/whitebox_host.gd")
	var action_capability := host_source.substr(host_source.find('"action": func'))
	action_capability = action_capability.get_slice('"input_frame":',0)
	check(action_capability.contains('"HOST_BUSY"') and action_capability.find('"HOST_BUSY"') < action_capability.find("owned_session.request_action"),"static admission contract: reflected action gates busy before Session request; concurrent Tween behavior NOT_RUN")
	var original_frame: Dictionary = capabilities.input_frame.call()
	var mutated_presenter := false
	for child in host.get_children(true):
		if child.get_script() == Host.Presenter:
			mutated_presenter = true
			child.frame = {"u":Vector3i.ZERO,"v":Vector3i.ZERO,"normal":Vector3i.ZERO}
	check(mutated_presenter and capabilities.input_frame.call() == original_frame,"engine child reflection cannot change the authoritative input frame")
	var reflected_move: Dictionary = host.request_move(Vector2.RIGHT,Basis.IDENTITY)
	check(reflected_move.has("status"),"presenter display mutation cannot redirect semantic input mapping")
	var before: String = host.current_state_key().key
	var observation: Dictionary = capabilities.observe.call()
	observation.state.clear()
	observation.level.clear()
	var logs: Array = host.action_records()
	logs.clear()
	var last: Dictionary = host.last_result()
	last.clear()
	var frame: Dictionary = capabilities.input_frame.call()
	frame.clear()
	check(host.current_state_key().key == before and not capabilities.observe.call().state.is_empty() and not capabilities.input_frame.call().is_empty(),"all observed runtime and presenter data are detached value copies")
	check(WhiteboxEntry._options(PackedStringArray(["--run-dir="+run_root])).ok,"entry accepts only the canonical E-drive run directory")
	for args in [[],["--run-dir="+run_root,"--run-dir="+run_root],["--canonical=x"],["--level=x"],["--json=x"],["--artifact=x"],["--handoff=x"],["--run-dir=C:/run"],["--run-dir=relative"],["--run-dir="+run_root+"/../other"]]:
		check(not WhiteboxEntry._options(PackedStringArray(args)).ok,"entry rejects alternate, duplicate or unsafe arguments: "+str(args))
	var context := WhiteboxEntry.execution_context(run_root,stored.run_identity)
	check(not context.ok and context.issues[0].code == "DEPENDENCY_PENDING","source staging does not claim updated D_SAVED execution closure")
	var stage_path := run_root.path_join(Loader.BAKE_STAGE_PATH)
	var message_path := run_root.path_join("ipc/test-bake.wire")
	check(_publish_bytes(run_root,"artifacts/bake/d3-bake-receipt.json","{}".to_utf8_buffer()),"legacy JSON exists only as a negative fixture")
	DirAccess.rename_absolute(stage_path,stage_path+".held")
	check(not host.load_run(run_root).ok and not host.is_ready() and host.loaded_hash().is_empty(),"missing formal stage never falls back to JSON or earlier success")
	check(capabilities.observe.call().is_empty(),"failed reload revokes retained observation capability")
	var revoked_action: Dictionary = capabilities.action.call({"kind":Types.PuzzleActionKind.SHIFT_WORLD})
	check(not revoked_action.get("ok",true) and not revoked_action.has("status"),"failed reload revokes retained Session action authority")
	DirAccess.rename_absolute(stage_path+".held",stage_path)
	DirAccess.rename_absolute(message_path,message_path+".held")
	check(not host.load_run(run_root).ok and not host.is_ready(),"unpublished stage bytes are not a trusted ArtifactRef")
	DirAccess.rename_absolute(message_path+".held",message_path)
	var message: Dictionary = Wire.decode_wire("worker_message",message_bytes).value
	message.payload_ref_or_inline.sha256 = "0".repeat(64)
	_write_bytes(message_path,Wire.encode_wire("worker_message",message).value)
	check(not host.load_run(run_root).ok and not host.is_ready(),"published stage digest is verified before decoding")
	_write_bytes(message_path,message_bytes)
	var altered := stored.duplicate(true)
	altered.stage_record.actual_policy.max_checks += 1
	altered.stage_record.actual_budget.max_checks += 1
	_replace_test_publication(run_root,altered)
	check(not host.load_run(run_root).ok and not host.is_ready(),"schema-valid BAKE policy must match sealed input policy")
	altered = stored.duplicate(true)
	altered.stage_record.native_result.source_map.level_hash = "0".repeat(64)
	_replace_test_publication(run_root,altered)
	check(not host.load_run(run_root).ok and not host.is_ready(),"decoded canonical content hash must match formal SourceMap")
	_write_bytes(stage_path,stage_bytes)
	_write_bytes(message_path,message_bytes)
	check(host.load_run(run_root).ok,"formal publication recovers after all fail-closed negatives")
