extends "res://tests/foundation/authoring_acceptance/test_tool_wire.gd"
## D2 real file boundaries, frozen projection and sealed execution. Unit shares
## the structural checks; Real additionally consumes registered A_BAKE + Codec.
## Inherited helpers are declaration fixtures only, never substitute Bake data.

func run() -> void:
	_source_fingerprint_structure()
	_package_structure()
	_saved_package()
	_saved_intent_digest()
	finish()

func _saved_package() -> void:
	var capture_service = load("res://tools/foundation/authoring_acceptance/snapshot_capture.gd")
	var execution = load("res://tools/foundation/authoring_acceptance/execution_project.gd")
	var real_fixture := mode() == "Real"
	var root_uri := "res://tests/foundation/authoring_integration/maps/d3_action_capable/level.tscn" if real_fixture else "res://tests/foundation/authoring/fixtures/minimal/level.tscn"
	var level_id: StringName = &"d3_action_capable" if real_fixture else &"authoring_minimal"
	var request := {"entry_kind":"ACCEPT_SAVED", "level_ref":{"level_authoring_id":"00000000-0000-4000-8000-000000000001", "level_id":level_id, "root_source_uri":root_uri}, "policy":Records.default_execution_policy("ACCEPT_SAVED")}
	var source_root := ProjectSettings.globalize_path("res://").trim_suffix("/")
	var captured: Dictionary = capture_service.capture_saved(request, source_root)
	if not captured.ok: print("CAPTURE_DIAGNOSTIC ", captured.issues)
	if not captured.ok: print("ENGINE_DIAGNOSTIC ", Engine.get_version_info(), " ", FileAccess.get_sha256(OS.get_executable_path()))
	check(captured.ok, "saved disk source produces sealed SnapshotRef")
	if not captured.ok: return
	var sealed: Dictionary = captured.value
	check(Schemas._hex(sealed.identity.source_intent_digest,64),"saved explicit empty Intent has nonnull digest")
	check(Schemas._fields(sealed.identity,["run_id","snapshot_id","source_fingerprint","source_intent_digest"]),"SnapshotIdentity remains exact four fields")
	for digest in [null,"0".repeat(64)]:
		var tampered := sealed.duplicate(true)
		tampered.identity.source_intent_digest = digest
		check(not execution.verify(tampered).ok,"sealed present Intent rejects null or tampered digest")

	var reconstructed: Dictionary = execution.snapshot_from_run(sealed.root_path)
	check(reconstructed.ok and reconstructed.value == sealed,"D2 reconstructs exact SnapshotRef from sealed run")
	var repeated: Dictionary = capture_service.capture_saved(request, source_root)
	check(repeated.ok, "repeated saved capture succeeds")
	if repeated.ok:
		check(sealed.identity.run_id != repeated.value.identity.run_id, "each capture allocates unique run_id")
		check(sealed.identity.source_fingerprint == repeated.value.identity.source_fingerprint, "same disk source fingerprint stable across runs")
		check(sealed.identity.source_intent_digest != null and sealed.identity.source_intent_digest == repeated.value.identity.source_intent_digest,"empty Intent digest deterministic across captures")
	check(sealed.keys().size() == 6, "SnapshotRef has exactly six fields")
	check(sealed.root_path.begins_with("E:/"), "run package resides on E drive")
	check(FileAccess.file_exists(sealed.root_path.path_join("input.ready")), "returned snapshot is sealed by input.ready")
	var project: Dictionary = execution.materialize(sealed, source_root)
	check(project.ok, "sealed snapshot materializes controlled project")
	if not project.ok: return
	check(project.value.execution_digest == sealed.execution_digest, "execution identity remains bound")
	check(project.value.manifest == sealed.input_manifest, "materialize returns existing input.ready reference")
	check(not FileAccess.file_exists(project.value.project_root.path_join("tests/foundation/authoring/fixtures/minimal/level.tscn")), "controlled project excludes authoring fixture and whole active project")
	check(execution.materialize(sealed, source_root).ok, "identical existing execution files accepted without rewrite")
	var extra_path: String = project.value.project_root.path_join("unlisted.gd")
	var extra := FileAccess.open(extra_path,FileAccess.WRITE)
	extra.store_string("extends RefCounted\n")
	extra.close()
	check(not execution.materialize(sealed,source_root).ok, "unlisted execution file is rejected rather than inherited")
	DirAccess.remove_absolute(extra_path)
	var bad: Dictionary = sealed.duplicate(true)
	bad.input_mode = &"ACCEPT_SAVED"
	check(not execution.materialize(bad,source_root).ok, "SnapshotRef StringName is not a String mode")
	bad = sealed.duplicate(true)
	bad.extra = true
	check(not execution.materialize(bad, source_root).ok, "unknown SnapshotRef field rejected")
	bad = sealed.duplicate(true)
	bad.identity.source_fingerprint = "f".repeat(64)
	check(not execution.materialize(bad, source_root).ok, "snapshot source digest mismatch rejected")
	bad = sealed.duplicate(true)
	bad.input_manifest.relative_path = "../input.ready"
	check(not execution.materialize(bad, source_root).ok, "reference cannot escape package")
	var ready_path: String = sealed.root_path.path_join("input.ready")
	var ready_bytes := FileAccess.get_file_as_bytes(ready_path)
	DirAccess.rename_absolute(ready_path, ready_path + ".held")
	check(not execution.materialize(sealed, source_root).ok, "half package without input.ready rejected")
	DirAccess.rename_absolute(ready_path + ".held", ready_path)
	check(FileAccess.get_file_as_bytes(ready_path) == ready_bytes, "materialize never changes input.ready")
	var config_path: String = project.value.project_root.path_join("project.godot")
	var original := FileAccess.get_file_as_bytes(config_path)
	var file := FileAccess.open(config_path, FileAccess.WRITE)
	file.store_string("corrupted")
	file.close()
	check(not execution.materialize(sealed, source_root).ok, "existing destination corruption rejected without overwrite")
	check(FileAccess.get_file_as_string(config_path) == "corrupted", "immutable destination is never repaired silently")
	file = FileAccess.open(config_path, FileAccess.WRITE)
	file.store_buffer(original)
	file.close()
	var manifest: Dictionary = Wire.decode_wire("input_manifest",ready_bytes).value
	var blob_path: String = sealed.root_path.path_join("input/execution/" + manifest.identity.versions.modules[0].sha256 + ".blob")
	DirAccess.rename_absolute(blob_path, blob_path + ".held")
	check(not execution.materialize(sealed, source_root).ok, "missing frozen blob stops despite active project and existing destination")
	DirAccess.rename_absolute(blob_path + ".held", blob_path)
	_package_negatives(sealed,source_root,execution,request.level_ref.root_source_uri)
	_capture_negatives(request,source_root,capture_service,execution)
	_formal_host_closure(execution,sealed,source_root)
	_scene_resource_closure(capture_service,execution,request,source_root,sealed)
	if mode() == "Real":
		var payload_path: String = sealed.root_path.path_join(manifest.authoring_payload.relative_path)
		var payload_result := Wire.decode_wire("authoring", FileAccess.get_file_as_bytes(payload_path))
		var adapter = load("res://foundation/authoring/authoring_adapter.gd")
		var started_at := _utc_milliseconds_now()
		var baked: Dictionary = adapter.bake_authoring(payload_result.value, request.policy.bake_options, sealed.identity)
		check(baked.ok, "real registered A_BAKE consumes sealed authoring payload")
		if baked.ok:
			var codec = load("res://foundation/level/level_codec.gd")
			var canonical: Dictionary = codec.encode(baked.level)
			check(canonical.ok and codec.decode(canonical.text).level.content_hash == baked.level.content_hash, "real canonical Codec roundtrip retains A_BAKE content hash")
			check(sealed.identity.source_fingerprint == "45464787575bac5db6563352b21635910455cebaafe32a12e4a0cb77d342f8b5","new action-capable D3 capture retains the approved source fingerprint")
			check(baked.level.content_hash == "51aa7a4cf9b9328ed533434bf579b4ab9ae8393687f33fcc39a982f3f6d8a72e","new formal Bake retains the approved canonical content hash")
			if sealed.identity.source_fingerprint != "45464787575bac5db6563352b21635910455cebaafe32a12e4a0cb77d342f8b5" or baked.level.content_hash != "51aa7a4cf9b9328ed533434bf579b4ab9ae8393687f33fcc39a982f3f6d8a72e": return
			check(sealed.identity.run_id != "4286c860-a388-42c9-ab64-d892553e747a","new action-capable execution is a distinct run")
			check(sealed.execution_digest != "e1882cf51fc2165bf5a809f9c7410c15c22b1049855c86d67a78669b25f4b5ea","new run binds the consumed D_PROTOCOL closure rather than reusing old preflight")
			_publish_bake_stage(execution,sealed,manifest,request,baked,canonical,started_at,repeated.value)

func _utc_milliseconds_now() -> String:
	var unix_time := Time.get_unix_time_from_system()
	var whole_seconds := int(floor(unix_time))
	var date := Time.get_datetime_dict_from_unix_time(whole_seconds)
	var milliseconds := int((unix_time - float(whole_seconds)) * 1000.0)
	return "%04d-%02d-%02dT%02d:%02d:%02d.%03dZ" % [date.year,date.month,date.day,date.hour,date.minute,date.second,milliseconds]

func _publish_bake_stage(execution, sealed: Dictionary, input_manifest: Dictionary, request: Dictionary, baked: Dictionary, canonical: Dictionary, started_at: String, other_snapshot: Dictionary) -> void:
	var canonical_bytes: PackedByteArray = canonical.text.to_utf8_buffer()
	var canonical_ref: Dictionary = execution.artifact("artifacts/stages/BAKE/canonical.level",canonical_bytes,"levelcanonical.v1")
	var stale_ref := {"relative_path":"canonical.level","byte_length":4171,"sha256":"22f63447bc282029190d0c8b29a2016630c176b8dcce91dc2b1c94a9677484f9","format_version":"levelcanonical.v1"}
	check(not execution.read_artifact(sealed.root_path,stale_ref).ok,"previous-run ArtifactRef cannot resolve outside the new run root")
	var identity: Dictionary = input_manifest.identity.duplicate(true)
	check(not identity.is_empty(),"formal Stage Result identity binds the new SnapshotRef and execution versions")
	if identity.is_empty(): return
	var records = load("res://tools/foundation/authoring_acceptance/run_records.gd")
	var stage: Dictionary = records.make_stage_record("BAKE","4A","res://foundation/authoring/authoring_adapter.gd")
	stage.execution = "COMPLETED"
	stage.reason = ""
	stage.input_refs = {"input_manifest":sealed.input_manifest.duplicate(true),"authoring_payload":input_manifest.authoring_payload.duplicate(true)}
	stage.actual_policy = request.policy.bake_options.duplicate(true)
	stage.actual_budget = request.policy.bake_options.duplicate(true)
	stage.native_result = baked.duplicate(true)
	stage.native_result.level = canonical_ref.duplicate(true)
	stage.evidence_refs = {"canonical":canonical_ref.duplicate(true)}
	stage.warnings = []
	stage.started_at = started_at
	stage.finished_at = _utc_milliseconds_now()
	if stage.finished_at < stage.started_at: stage.finished_at = stage.started_at
	var stage_result := {"run_identity":identity,"stage_record":stage}
	var encoded_result: Dictionary = Wire.encode_wire("stage_result",stage_result)
	check(encoded_result.ok,"registered D_PROTOCOL encodes the real D3 fixture BAKE result")
	if not encoded_result.ok:
		print("BAKE_STAGE_RESULT_DIAGNOSTIC ",JSON.stringify(encoded_result.issues))
		return
	var canonical_path: String = sealed.root_path.path_join(canonical_ref.relative_path)
	var published_canonical: Dictionary = execution.write_new(canonical_path,canonical_bytes)
	check(published_canonical.ok,"new run publishes canonical.level before its stage receipt")
	if not published_canonical.ok: return
	var stage_result_path: String = sealed.root_path.path_join("artifacts/stages/BAKE/stage_result.wire")
	var published_result: Dictionary = execution.write_new(stage_result_path,encoded_result.value)
	check(published_result.ok,"new run publishes formal stage_result.wire")
	if not published_result.ok: return
	var stage_bytes: PackedByteArray = FileAccess.get_file_as_bytes(stage_result_path)
	var stage_ref: Dictionary = execution.artifact("artifacts/stages/BAKE/stage_result.wire",stage_bytes,"foundationtoolwire.v1")
	var message := {"protocol_version":Schemas.WORKER_PROTOCOL_VERSION,"identity":identity.duplicate(true),"sequence":0,"kind":"STAGE_RESULT","stage_id":"BAKE","payload_ref_or_inline":stage_ref}
	var verified: Dictionary = Wire.verify_stage_result(message,stage_bytes)
	check(verified.ok and verified.value.stage_record.native_result.bake_provenance.run_id == sealed.identity.run_id,"formal STAGE_RESULT binds the exact new-run identity and stored bytes")
	var readback: Dictionary = execution.read_artifact(sealed.root_path,canonical_ref)
	check(readback.ok and readback.value == canonical_bytes,"canonical ArtifactRef resolves and verifies only in its owning new run")
	var encoded_message: Dictionary = Wire.encode_wire("worker_message",message)
	check(encoded_message.ok and execution.write_new(sealed.root_path.path_join("ipc/bake-result.wire"),encoded_message.value).ok,"formal WorkerMessage publishes the exact BAKE stage ArtifactRef")
	var loader = load("res://tools/foundation/authoring_acceptance/canonical_loader.gd").new()
	var loaded: Dictionary = loader.load_run(sealed.root_path)
	check(loaded.ok,"formal Host consumer accepts published BAKE with exact input.ready identity")
	if not loaded.ok:
		print("D2_HOST_CONSUMER_DIAGNOSTIC ",loaded.issues)
		return
	# A different captured run has the same source/canonical content. Transplant
	# complete bytes, not just a missing filename, to prove identity rejection.
	check(execution.write_new(other_snapshot.root_path.path_join(canonical_ref.relative_path),canonical_bytes).ok,"cross-run negative contains identical canonical bytes")
	check(execution.write_new(other_snapshot.root_path.path_join(stage_ref.relative_path),stage_bytes).ok,"cross-run negative contains the actual foreign stage bytes")
	check(execution.write_new(other_snapshot.root_path.path_join("ipc/bake-result.wire"),encoded_message.value).ok,"cross-run negative publishes the actual foreign ArtifactRef")
	var foreign: Dictionary = loader.load_run(other_snapshot.root_path)
	check(not foreign.ok and foreign.issues[0].code == "SNAPSHOT_IDENTITY_MISMATCH" and loader.loaded_hash().is_empty(),"foreign run ArtifactRef is rejected despite identical canonical bytes")
	var source_root := ProjectSettings.globalize_path("res://").trim_suffix("/")
	var controlled: Dictionary = execution.materialize(sealed,source_root)
	check(controlled.ok,"final BAKE run materializes its complete formal Host closure")
	if not controlled.ok: return
	# Only wrapper-owned active paths are hidden. The sealed child has its own
	# resource namespace and cannot borrow active tools, runtime or project config.
	var moved: Array = []
	for relative in ["tools","foundation","project.godot"]:
		var active_path := source_root.path_join(relative)
		var held_path := active_path+".d2-isolation-held"
		var moved_ok := DirAccess.rename_absolute(active_path,held_path) == OK
		check(moved_ok,"active source unavailable during formal Host launch: "+relative)
		if moved_ok: moved.append([active_path,held_path])
	var output: Array = []
	var child_exit := -1
	if moved.size() == 3:
		var import_output: Array = []
		var import_exit := OS.execute(OS.get_executable_path(),["--headless","--path",controlled.value.project_root,"--editor","--import"],import_output,true)
		var import_text := "\n".join(import_output)
		_write_bytes(evidence_dir().path_join("controlled-host-import.log"),import_text.to_utf8_buffer())
		check(import_exit == 0 and not import_text.contains("ERROR:") and not import_text.contains("WARNING:"),"controlled project builds its own class/UID import cache without active sources")
		child_exit = OS.execute(OS.get_executable_path(),["--headless","--path",controlled.value.project_root,"--quit-after","2","--script","res://tools/foundation/authoring_acceptance/whitebox_entry.gd","--","--run-dir="+sealed.root_path],output,true)
	for pair in moved:
		check(DirAccess.rename_absolute(pair[1],pair[0]) == OK,"active source restored after formal Host launch")
	var child_text := "\n".join(output)
	_write_bytes(evidence_dir().path_join("controlled-host-output.log"),child_text.to_utf8_buffer())
	check(child_exit == 0 and child_text.contains("D_HOST_READY") and not child_text.contains("ERROR:") and not child_text.contains("WARNING:"),"whitebox_entry and Host scene independently start in controlled project; no Tween action issued")
	if child_exit != 0 or not child_text.contains("D_HOST_READY"): print("D2_CONTROLLED_HOST_DIAGNOSTIC ",child_exit," ",child_text)
	check(execution.materialize(sealed,source_root).ok,"controlled import and Host startup preserve exact sealed execution bytes")
	var evidence := {"snapshot_ref":sealed,"run_id":sealed.identity.run_id,"snapshot_id":sealed.identity.snapshot_id,"source_fingerprint":sealed.identity.source_fingerprint,"execution_digest":sealed.execution_digest,"content_hash":baked.level.content_hash,"canonical_ref":canonical_ref,"stage_result_ref":stage_ref,"worker_message":message,"controlled_project":controlled.value.project_root,"controlled_host_exit":child_exit,"cross_run_rejected":not foreign.ok,"final_local_tween":"NOT_RUN","final_global_tween":"NOT_RUN"}
	_write_bytes(evidence_dir().path_join("d2-delivery.json"),JSON.stringify(evidence,"\t").to_utf8_buffer())
	print("D2_BAKE_STAGE_EVIDENCE ",JSON.stringify(evidence))

func _package_negatives(sealed: Dictionary, source_root: String, execution, source_uri: String) -> void:
	var root: String = sealed.root_path
	var ready_path := root.path_join("input.ready")
	var bytes := FileAccess.get_file_as_bytes(ready_path)
	var manifest: Dictionary = Wire.decode_wire("input_manifest",bytes).value
	for field in sealed:
		var missing := sealed.duplicate(true)
		missing.erase(field)
		check(not execution.materialize(missing,source_root).ok,"SnapshotRef missing " + field + " fails closed")
	var foreign := sealed.duplicate(true)
	foreign.root_path = "C:/unapproved/run"
	check(not execution.materialize(foreign,source_root).ok,"non-E run root rejected before IO")
	for field in ["version","executable_sha256"]:
		var altered := manifest.duplicate(true)
		altered.identity.versions.engine[field] = "different-engine" if field == "version" else "0".repeat(64)
		altered.identity.execution_digest = Wire.digest("versions",altered.identity.versions).value
		var encoded := Wire.encode_wire("input_manifest",altered)
		check(encoded.ok,"engine negative has a valid re-bound manifest")
		if encoded.ok:
			_write_bytes(ready_path,encoded.value)
			var alternate := sealed.duplicate(true)
			alternate.execution_digest = altered.identity.execution_digest
			alternate.input_manifest = execution.artifact("input.ready",encoded.value,"authoringinputmanifest.v1")
			var rejected: Dictionary = execution.materialize(alternate,source_root)
			check(not rejected.ok and rejected.issues[0].code == "EXECUTION_VERSION_MISMATCH","actual engine " + field + " mismatch stops chain")
			_write_bytes(ready_path,bytes)
	for path in ["res://foundation/runtime/runtime_session.gd.uid","res://foundation/validation/safety_queries.gd","res://foundation/solver/solution_trace.gd"]:
		var altered := manifest.duplicate(true)
		for i in range(altered.identity.versions.modules.size()-1,-1,-1):
			if altered.identity.versions.modules[i].path == path: altered.identity.versions.modules.remove_at(i)
		altered.identity.execution_digest = Wire.digest("versions",altered.identity.versions).value
		var encoded := Wire.encode_wire("input_manifest",altered)
		check(encoded.ok,"missing dependency negative is a structurally valid manifest")
		if encoded.ok:
			_write_bytes(ready_path,encoded.value)
			var alternate := sealed.duplicate(true)
			alternate.execution_digest = altered.identity.execution_digest
			alternate.input_manifest = execution.artifact("input.ready",encoded.value,"authoringinputmanifest.v1")
			check(not execution.materialize(alternate,source_root).ok,"missing UID/dynamic dependency stops: " + path)
			_write_bytes(ready_path,bytes)
	var entry: Dictionary = manifest.identity.versions.modules[0]
	var frozen_path: String = root.path_join("input/execution/" + entry.sha256 + ".blob")
	var original := FileAccess.get_file_as_bytes(frozen_path)
	_write_bytes(frozen_path,"changed module".to_utf8_buffer())
	check(not execution.materialize(sealed,source_root).ok,"changed frozen dependency fails digest before execution")
	_write_bytes(frozen_path,original)
	var config: String = FileAccess.get_file_as_string(root.path_join("execution/project/project.godot"))
	check(not config.contains("autoload") and not config.contains("editor_plugins"),"controlled config excludes active autoload and editor plugins")
	# Move only this wrapper's disposable saved source, never the owner's fixture.
	var active_path := source_root.path_join(source_uri.substr(6))
	DirAccess.rename_absolute(active_path,active_path + ".held")
	check(execution.materialize(sealed,source_root).ok,"sealed execution no longer reads active saved source")
	DirAccess.rename_absolute(active_path + ".held",active_path)
	check(FileAccess.get_file_as_bytes(ready_path) == bytes,"negative cases restore test package ready bytes")
	print("D2_EVIDENCE ", JSON.stringify({"snapshot_ref":sealed,"modules":manifest.identity.versions.modules.size(),"execution_digest":sealed.execution_digest,"source_fingerprint":sealed.identity.source_fingerprint}))

func _scene_resource_closure(capture_service, execution, request: Dictionary, source_root: String, original_snapshot: Dictionary) -> void:
	# A disposable D3-shaped scene fixture proves the real D2 dependency closure
	# accepts a manifest-declared PackedScene and packages every referenced script.
	# It contains no runtime rules and never leaves the wrapper's throwaway project.
	var dependency_path := source_root.path_join("tools/foundation/authoring_acceptance/execution_dependencies.json")
	var original_dependencies := FileAccess.get_file_as_bytes(dependency_path)
	var parsed: Variant = JSON.parse_string(original_dependencies.get_string_from_utf8())
	check(typeof(parsed) == TYPE_DICTIONARY,"execution closure declaration is readable before scene fixture")
	if typeof(parsed) != TYPE_DICTIONARY: return
	var host_path := "res://tools/foundation/authoring_acceptance/closure_sample_host.gd"
	var loader_path := "res://tools/foundation/authoring_acceptance/closure_sample_loader.gd"
	var scene_path := "res://tools/foundation/authoring_acceptance/closure_sample_host.tscn"
	var nested_scene_path := "res://tools/foundation/authoring_acceptance/whitebox_child.tscn"
	var probe_path := "res://tools/foundation/authoring_acceptance/closure_probe.gd"
	var fixture_paths := [host_path,host_path+".uid",loader_path,loader_path+".uid",scene_path,nested_scene_path,nested_scene_path+".uid",probe_path,probe_path+".uid"]
	for resource_path in fixture_paths:
		check(not FileAccess.file_exists(source_root.path_join(resource_path.substr(6))),"scene fixture path is available: " + resource_path)
		if FileAccess.file_exists(source_root.path_join(resource_path.substr(6))): return
	var generated_uids: Array[String] = []
	for _index in 4:
		var generated_uid := ResourceUID.id_to_text(ResourceUID.create_id())
		while generated_uid in generated_uids: generated_uid = ResourceUID.id_to_text(ResourceUID.create_id())
		generated_uids.append(generated_uid)
	var host_uid: String = generated_uids[0]
	var loader_uid: String = generated_uids[1]
	var probe_uid: String = generated_uids[2]
	var nested_uid: String = generated_uids[3]
	var updated: Dictionary = parsed.duplicate(true)
	for path in [host_path,loader_path,scene_path,nested_scene_path,probe_path]:
		if path not in updated.modules: updated.modules.append(path)
	updated.modules.sort()
	_write_bytes(dependency_path,JSON.stringify(updated,"\t",true).to_utf8_buffer())
	_write_bytes(source_root.path_join(host_path.substr(6)),("extends Node3D\nconst CanonicalLoader = preload(\"" + loader_path + "\")\n").to_utf8_buffer())
	_write_bytes(source_root.path_join(host_path.substr(6)+".uid"),(host_uid+"\n").to_utf8_buffer())
	_write_bytes(source_root.path_join(loader_path.substr(6)),"extends RefCounted\n".to_utf8_buffer())
	_write_bytes(source_root.path_join(loader_path.substr(6)+".uid"),(loader_uid+"\n").to_utf8_buffer())
	_write_bytes(source_root.path_join(scene_path.substr(6)),("[gd_scene load_steps=3 format=3]\n\n[ext_resource type=\"Script\" path=\"" + host_path + "\" id=\"1_host\"]\n[ext_resource type=\"PackedScene\" uid=\"" + nested_uid + "\" path=\"" + nested_scene_path + "\" id=\"2_child\"]\n\n[node name=\"WhiteboxHost\" type=\"Node3D\"]\nscript = ExtResource(\"1_host\")\n\n[node name=\"WhiteboxChild\" parent=\".\" instance=ExtResource(\"2_child\")]\n").to_utf8_buffer())
	_write_bytes(source_root.path_join(nested_scene_path.substr(6)),("[gd_scene load_steps=2 format=3]\n\n[ext_resource type=\"Script\" path=\"" + host_path + "\" id=\"1_host\"]\n\n[node name=\"WhiteboxChild\" type=\"Node3D\"]\nscript = ExtResource(\"1_host\")\n").to_utf8_buffer())
	_write_bytes(source_root.path_join(nested_scene_path.substr(6)+".uid"),(nested_uid+"\n").to_utf8_buffer())
	var probe := "extends SceneTree\nconst HostScene = preload(\"" + scene_path + "\")\nfunc _initialize() -> void:\n\tvar instance = HostScene.instantiate()\n\tprint(\"D2_RESOURCE_CLOSURE_LOAD_PASS\")\n\tinstance.free()\n\tquit(0)\n"
	_write_bytes(source_root.path_join(probe_path.substr(6)),probe.to_utf8_buffer())
	_write_bytes(source_root.path_join(probe_path.substr(6)+".uid"),(probe_uid+"\n").to_utf8_buffer())
	var prepared: Dictionary = execution.prepare(source_root)
	check(prepared.ok,"manifest-declared TSCN and its static script dependencies enter execution closure")
	if not prepared.ok: print("SCENE_CLOSURE_PREPARE_DIAGNOSTIC ",JSON.stringify(prepared.issues))
	if prepared.ok:
		var scene_bytes := FileAccess.get_file_as_bytes(source_root.path_join(scene_path.substr(6)))
		for embedded_type in ["GDScript","StandardMaterial3D"]:
			var embedded_text := '[gd_scene format=3]\n[sub_resource type="%s" id="embedded"]\n[node name="Unapproved" type="Node3D"]\n' % embedded_type
			_write_bytes(source_root.path_join(scene_path.substr(6)),embedded_text.to_utf8_buffer())
			var embedded: Dictionary = execution.prepare(source_root)
			check(not embedded.ok and embedded.issues[0].code == "EXECUTION_DEPENDENCY_INVALID","unapproved embedded scene resource is rejected: "+embedded_type)
		var unsupported_scene := scene_bytes.get_string_from_utf8().replace('type="PackedScene"', 'type="Texture2D"')
		_write_bytes(source_root.path_join(scene_path.substr(6)),unsupported_scene.to_utf8_buffer())
		check(not execution.prepare(source_root).ok,"unknown TSCN external resource type is rejected")
		var escaped_scene := scene_bytes.get_string_from_utf8().replace(host_path, "res://../escaped.gd")
		_write_bytes(source_root.path_join(scene_path.substr(6)),escaped_scene.to_utf8_buffer())
		check(not execution.prepare(source_root).ok,"TSCN resource path escape is rejected")
		var missing_scene := scene_bytes.get_string_from_utf8().replace(nested_scene_path, "res://tools/foundation/authoring_acceptance/not_declared.tscn")
		_write_bytes(source_root.path_join(scene_path.substr(6)),missing_scene.to_utf8_buffer())
		check(not execution.prepare(source_root).ok,"undeclared nested PackedScene dependency is rejected")
		var missing_ext_id := scene_bytes.get_string_from_utf8().replace('ExtResource("2_child")','ExtResource("not_declared")')
		_write_bytes(source_root.path_join(scene_path.substr(6)),missing_ext_id.to_utf8_buffer())
		check(not execution.prepare(source_root).ok,"TSCN use of an undeclared external resource id is rejected")
		var uid_mismatch := scene_bytes.get_string_from_utf8().replace('type="Script" path="' + host_path + '"', 'type="Script" uid="' + loader_uid + '" path="' + host_path + '"')
		_write_bytes(source_root.path_join(scene_path.substr(6)),uid_mismatch.to_utf8_buffer())
		check(not execution.prepare(source_root).ok,"TSCN UID must identify its declared resource path")
		_write_bytes(source_root.path_join(scene_path.substr(6)),scene_bytes)
		var host_uid_path := source_root.path_join(host_path.substr(6)+".uid")
		var host_uid_bytes := FileAccess.get_file_as_bytes(host_uid_path)
		_write_bytes(host_uid_path,(loader_uid+"\n").to_utf8_buffer())
		check(not execution.prepare(source_root).ok,"duplicate UID mapping is rejected across execution resources")
		_write_bytes(host_uid_path,host_uid_bytes)
		var nested_bytes := FileAccess.get_file_as_bytes(source_root.path_join(nested_scene_path.substr(6)))
		_write_bytes(source_root.path_join(nested_scene_path.substr(6)),("[gd_scene load_steps=2 format=3]\n\n[ext_resource type=\"PackedScene\" path=\"" + scene_path + "\" id=\"1_parent\"]\n\n[node name=\"Cycle\" instance=ExtResource(\"1_parent\")]\n").to_utf8_buffer())
		check(not execution.prepare(source_root).ok,"cyclic PackedScene dependency is rejected")
		_write_bytes(source_root.path_join(nested_scene_path.substr(6)),nested_bytes)
		var duplicate_path_config: Dictionary = updated.duplicate(true)
		duplicate_path_config.modules.append(host_path.to_upper())
		_write_bytes(dependency_path,JSON.stringify(duplicate_path_config,"\t",true).to_utf8_buffer())
		check(not execution.prepare(source_root).ok,"case-insensitive duplicate resource paths are rejected")
		_write_bytes(dependency_path,JSON.stringify(updated,"\t",true).to_utf8_buffer())
	if not prepared.ok:
		_write_bytes(dependency_path,original_dependencies)
		for resource_path in fixture_paths: DirAccess.remove_absolute(source_root.path_join(resource_path.substr(6)))
		return
	var captured: Dictionary = capture_service.capture_saved(request,source_root)
	check(captured.ok,"saved capture seals the complete scene resource closure")
	if not captured.ok:
		print("SCENE_CLOSURE_CAPTURE_DIAGNOSTIC ",JSON.stringify(captured.issues))
		_write_bytes(dependency_path,original_dependencies)
		for resource_path in fixture_paths: DirAccess.remove_absolute(source_root.path_join(resource_path.substr(6)))
		return
	var sealed: Dictionary = captured.value
	check(sealed.identity.source_fingerprint == original_snapshot.identity.source_fingerprint,"execution resource closure does not alter source fingerprint")
	check(sealed.execution_digest != original_snapshot.execution_digest,"additional scene/script closure changes execution digest")
	check(sealed.keys().size() == 6,"expanded execution closure preserves the closed SnapshotRef shape")
	var captured_manifest := Wire.decode_wire("input_manifest",FileAccess.get_file_as_bytes(sealed.root_path.path_join("input.ready")))
	check(captured_manifest.ok,"expanded execution closure preserves the input.ready wire schema")
	if captured_manifest.ok:
		var versioned_paths := {}
		for module in captured_manifest.value.identity.versions.modules: versioned_paths[module.path] = module.sha256
		for resource_path in [host_path,host_path+".uid",loader_path,loader_path+".uid",scene_path,nested_scene_path,nested_scene_path+".uid",probe_path,probe_path+".uid","res://tools/foundation/authoring_acceptance/execution_dependencies.json"]:
			var source_bytes := FileAccess.get_file_as_bytes(source_root.path_join(resource_path.substr(6)))
			check(versioned_paths.get(resource_path,"") == execution.sha(source_bytes),"execution digest records exact bytes for " + resource_path)
	var materialized: Dictionary = execution.materialize(sealed,source_root)
	check(materialized.ok,"sealed scene resource closure materializes without active-source fallback")
	if materialized.ok:
		for resource_path in [host_path,loader_path,scene_path,nested_scene_path,probe_path]:
			check(FileAccess.file_exists(materialized.value.project_root.path_join(resource_path.substr(6))),"controlled project contains declared resource: " + resource_path)
		var moved: Array[Array] = []
		for resource_path in fixture_paths + ["res://tools/foundation/authoring_acceptance/execution_dependencies.json"]:
			var active_path := source_root.path_join(resource_path.substr(6))
			var held_path := active_path + ".closure-test-held"
			var move_ok := DirAccess.rename_absolute(active_path,held_path) == OK
			check(move_ok,"active resource removed from source project before isolated launch: " + resource_path)
			if move_ok: moved.append([active_path,held_path])
		var all_active_sources_moved := moved.size() == fixture_paths.size() + 1
		if all_active_sources_moved:
			var output: Array = []
			var launch: int = OS.execute(OS.get_executable_path(),["--headless","--path",materialized.value.project_root,"--script",probe_path],output,true)
			var output_text := "\n".join(output)
			check(launch == 0 and output_text.contains("D2_RESOURCE_CLOSURE_LOAD_PASS"),"isolated execution project loads the scene after active sources are unavailable")
			if launch != 0 or not output_text.contains("D2_RESOURCE_CLOSURE_LOAD_PASS"):
				print("SCENE_CLOSURE_CHILD_DIAGNOSTIC ",launch," ",output_text)
		else:
			check(false,"all active closure resources are unavailable to the execution project")
		for pair in moved:
			check(DirAccess.rename_absolute(pair[1],pair[0]) == OK,"active fixture restored after isolated load probe")
	_write_bytes(dependency_path,original_dependencies)
	for resource_path in fixture_paths: DirAccess.remove_absolute(source_root.path_join(resource_path.substr(6)))
	var run_prefix := source_root.path_join(".godot/foundation-authoring/runs/")
	if sealed.root_path.begins_with(run_prefix) and sealed.identity.run_id in sealed.root_path:
		_remove_test_tree(sealed.root_path)

func _remove_test_tree(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		DirAccess.remove_absolute(path)
		return
	var directory := DirAccess.open(path)
	if directory == null: return
	for file in directory.get_files(): DirAccess.remove_absolute(path.path_join(file))
	for child in directory.get_directories(): _remove_test_tree(path.path_join(child))
	DirAccess.remove_absolute(path)

func _write_bytes(path: String, bytes: PackedByteArray) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_buffer(bytes)
	file.close()

func _capture_negatives(request: Dictionary, source_root: String, capture_service, execution) -> void:
	var escaped := request.duplicate(true)
	escaped.level_ref.root_source_uri = "res://../outside.tscn"
	check(not capture_service.capture_saved(escaped,source_root).ok,"source path escape stops capture")
	var uid_path := source_root.path_join("foundation/runtime/runtime_session.gd.uid")
	DirAccess.rename_absolute(uid_path,uid_path + ".held")
	check(not capture_service.capture_saved(request,source_root).ok,"missing actual UID stops capture before sealing")
	DirAccess.rename_absolute(uid_path + ".held",uid_path)
	var uid_bytes := FileAccess.get_file_as_bytes(uid_path)
	_write_bytes(uid_path,"uid://\n".to_utf8_buffer())
	check(not capture_service.capture_saved(request,source_root).ok,"malformed actual UID stops capture")
	_write_bytes(uid_path,uid_bytes)
	var frozen_probe = capture_service.new()
	var probe_path := source_root.path_join("relative_probe.tres")
	_write_bytes(probe_path,'[gd_resource type="Resource" load_steps=2 format=3]\n[ext_resource type="Script" path="unknown_resource.gd" id="1"]\n[resource]\nscript = ExtResource("1")\n'.to_utf8_buffer())
	check(not frozen_probe._freeze_sources("res://relative_probe.tres",source_root,{}).ok,"relative script reference rejected before ResourceLoader")
	DirAccess.remove_absolute(probe_path)
	var active := source_root.path_join(request.level_ref.root_source_uri.substr(6))
	var original := FileAccess.get_file_as_bytes(active)
	var script_uid := FileAccess.get_file_as_string("res://foundation/authoring/level_authoring_root.gd.uid").strip_edges()
	var with_uid := original.get_string_from_utf8().replace('[ext_resource type="Script" path=', '[ext_resource type="Script" uid="' + script_uid + '" path=')
	_write_bytes(active,with_uid.to_utf8_buffer())
	check(capture_service.capture_saved(request,source_root).ok,"normal saved path plus valid script UID remains supported")
	_write_bytes(active,original)
	var prepared: Dictionary = execution.prepare(source_root)
	var schema = load("res://foundation/authoring/authoring_schema.gd")
	var trusted := {}
	for kind in schema.SCRIPTS:
		var path: String = schema.script_path(kind)
		trusted[path] = FileAccess.get_sha256(path)
	var frozen: Dictionary = frozen_probe._freeze_sources(request.level_ref.root_source_uri,source_root,trusted)
	check(prepared.ok and frozen.ok,"isolation probe freezes real source and production modules")
	if prepared.ok and frozen.ok:
		var environment := {}
		for key in ["TEMP","TMP","APPDATA","LOCALAPPDATA"]: environment[key] = OS.get_environment(key)
		var declared_level_id := "level_id = &\"" + String(request.level_ref.level_id) + "\""
		check(original.get_string_from_utf8().contains(declared_level_id),"saved fixture has the requested LevelRef before mutation")
		_write_bytes(active,original.get_string_from_utf8().replace(declared_level_id,"level_id = &\"changed_during_projection\"").to_utf8_buffer())
		var live: Dictionary = frozen_probe._project_current(request.level_ref,frozen.value,trusted)
		check(not live.ok,"counterexample: reloading active source violates the captured LevelRef")
		var isolated: Dictionary = frozen_probe._project_frozen(request.level_ref,frozen.value,prepared.value.files,source_root.path_join(".godot/foundation-authoring/isolation-" + execution.uuid()))
		check(isolated.ok and isolated.value.level_ref == request.level_ref,"frozen 4A projection ignores changed active source in an independent ResourceLoader namespace")
		check(environment.keys().all(func(key): return OS.get_environment(key) == environment[key]),"child capture restores caller process environment")
		_write_bytes(active,original)
	var changed := original.duplicate()
	changed.append(10)
	_write_bytes(active,changed)
	var after_change: Dictionary = capture_service.capture_saved(request,source_root)
	check(after_change.ok,"changed saved source can form a new independent snapshot")
	_write_bytes(active,original)
	var restored: Dictionary = capture_service.capture_saved(request,source_root)
	check(restored.ok and after_change.ok and restored.value.identity.source_fingerprint != after_change.value.identity.source_fingerprint,"source disk digest change changes fingerprint even with identical declarations")
	var runs := source_root.path_join(".godot/foundation-authoring/runs")
	var existing := DirAccess.get_directories_at(runs)
	var mutator := Thread.new()
	var started := mutator.start(func():
		var until := Time.get_ticks_msec() + 15000
		while Time.get_ticks_msec() < until:
			for run in DirAccess.get_directories_at(runs):
				if run in existing: continue
				var run_root := runs.path_join(run)
				if DirAccess.dir_exists_absolute(run_root.path_join("input")):
					var was_ready := FileAccess.file_exists(run_root.path_join("input.ready"))
					_write_bytes(active,changed)
					return {"mutated":true,"ready_before":was_ready,"root":run_root}
			OS.delay_usec(1000)
		return {"mutated":false})
	check(started == OK,"real filesystem mutation observer started")
	var during: Dictionary = capture_service.capture_saved(request,source_root)
	var observed: Dictionary = mutator.wait_to_finish()
	_write_bytes(active,original)
	check(observed.mutated,"source mutation occurred during physical package preparation")
	check(observed.mutated and not observed.ready_before,"input.ready was absent while attachments were being written")
	check(not during.ok and during.issues[0].code == "CAPTURE_CHANGED","source changed during capture stops with CAPTURE_CHANGED")
	if observed.mutated: check(not FileAccess.file_exists(observed.root.path_join("input.ready")),"changed capture never publishes input.ready")
	# A real junction in the wrapper's disposable E-drive project, never owner files.
	var link := source_root.path_join("test_source_junction")
	var output: Array = []
	var expression := "New-Item -ItemType Junction -Path '%s' -Target '%s' | Out-Null" % [link.replace("'","''"),active.get_base_dir().replace("'","''")]
	var code := OS.execute("pwsh",["-NoProfile","-Command",expression],output,true)
	check(code == 0,"junction negative fixture created")
	if code == 0:
		check(not execution.safe_path(link.path_join("level.tscn")),"physical junction path cannot bypass root confinement")
		DirAccess.remove_absolute(link)

func _source_fingerprint_structure() -> void:
	var fixtures = load("res://tests/foundation/authoring/authoring_fixtures.gd")
	var payload: Dictionary = fixtures.payload("minimal")
	var payload_digest: Dictionary = Wire.digest("authoring", payload)
	check(payload_digest.ok, "source declarations are validated by actual A_SCHEMA")
	if not payload_digest.ok: return
	var source := _source()
	source.authoring_payload_digest = payload_digest.value
	source.dependencies[0].content_digest = payload_digest.value
	var first: Dictionary = Wire.digest("source_manifest", source)
	check(first.ok, "source manifest accepts real authoring wire identity")
	var reordered := {}
	for key in ["source_locations","dependencies","authoring_payload_digest"]:
		reordered[key] = source[key]
	check(Wire.digest("source_manifest", reordered).value == first.value, "same source content stable across map insertion order")
	var changed: Dictionary = source.duplicate(true)
	changed.dependencies[0].disk_digest = "2".repeat(64)
	check(Wire.digest("source_manifest", changed).value != first.value, "frozen disk bytes participate in source identity")
	changed = source.duplicate(true)
	changed.source_locations[0].label = "renamed"
	check(Wire.digest("source_manifest", changed).value != first.value, "source location labels participate in identity")
	changed = source.duplicate(true)
	changed.run_id = "11111111-1111-4111-8111-111111111111"
	check(not Wire.digest("source_manifest", changed).ok, "run identity cannot enter source fingerprint projection")
	for uri in ["res://../outside.tscn","res://maps/../test.tscn","res://maps\\test.tscn","res://maps//test.tscn"]:
		changed = source.duplicate(true)
		changed.dependencies[0].source_uri = uri
		check(not Wire.encode_wire("source_manifest", changed).ok, "source traversal/ambiguity rejected structurally: " + uri)

func _package_structure() -> void:
	var input := _input()
	check(Wire.encode_wire("input_manifest", input).ok, "complete declarative input manifest shape is valid")
	for field in input:
		var missing: Dictionary = input.duplicate(true)
		missing.erase(field)
		check(not Wire.encode_wire("input_manifest", missing).ok, "half manifest missing " + field + " rejected")
	for path in ["../outside.blob","/absolute.blob","C:/outside.blob","input/../outside.blob","input\\outside.blob"]:
		var escaped: Dictionary = input.duplicate(true)
		escaped.attachments[0].relative_path = path
		check(not Wire.encode_wire("input_manifest", escaped).ok, "attachment path cannot escape package: " + path)
	var incomplete: Dictionary = input.duplicate(true)
	for i in range(incomplete.attachments.size()-1,-1,-1):
		if incomplete.attachments[i].relative_path.begins_with("input/execution/"):
			incomplete.attachments.remove_at(i)
			break
	check(not Wire.encode_wire("input_manifest", incomplete).ok, "declared execution file requires a frozen blob reference")
	var cyclic: Dictionary = input.duplicate(true)
	cyclic.attachments.append(_ref("input.ready", "9".repeat(64), "authoringinputmanifest.v1"))
	cyclic.attachments.sort_custom(func(a,b): return a.relative_path < b.relative_path)
	check(not Wire.encode_wire("input_manifest", cyclic).ok, "input.ready cannot self-certify an unfinished package")
	var changed_engine: Dictionary = input.duplicate(true)
	changed_engine.identity.versions.engine.executable_sha256 = "f".repeat(64)
	check(not Wire.encode_wire("input_manifest", changed_engine).ok, "changed engine declaration invalidates execution digest")
	var empty_closure: Dictionary = input.duplicate(true)
	empty_closure.identity.versions.modules.clear()
	check(not Wire.encode_wire("input_manifest", empty_closure).ok, "empty execution closure is not a valid package declaration")

func _formal_host_closure(execution, sealed: Dictionary, source_root: String) -> void:
	var verified: Dictionary = execution.verify(sealed)
	check(verified.ok,"formal Host package verifies before closure assertions")
	if not verified.ok: return
	var files: Dictionary = verified.value.files
	for path in ["whitebox_host.tscn","whitebox_host.gd","whitebox_entry.gd","canonical_loader.gd"]:
		var uri: String = "res://tools/foundation/authoring_acceptance/"+path
		check(files.has(uri),"formal Host manifest contains "+path)
		if path.ends_with(".gd"):
			check(files.has(uri+".uid"),"formal Host script UID mapping exists: "+path)
	var scene_uri := "res://tools/foundation/authoring_acceptance/whitebox_host.tscn"
	if not files.has(scene_uri): return
	var destination: String = sealed.root_path.path_join("execution/project/"+scene_uri.substr(6))
	var bytes: PackedByteArray = files[scene_uri]
	check(FileAccess.get_file_as_bytes(destination)==bytes,"controlled Host scene bytes equal sealed manifest")
	var blob: String = sealed.root_path.path_join("input/execution/"+execution.sha(bytes)+".blob")
	DirAccess.rename_absolute(blob,blob+".held")
	check(not execution.materialize(sealed,source_root).ok,"missing sealed Host resource rejects despite available active Host")
	DirAccess.rename_absolute(blob+".held",blob)
	var modules: Array = verified.value.manifest.identity.versions.modules
	var altered: Dictionary = verified.value.manifest.identity.versions.duplicate(true)
	for item in altered.modules:
		if item.path == scene_uri: item.sha256 = "0".repeat(64)
	check(Wire.digest("versions",altered).value != sealed.execution_digest,"execution digest binds the Host scene bytes")
	check(modules.any(func(item): return item.path == scene_uri),"VersionsRecord covers the formal scene resource")

# Actual saved files in the harness disposable project; restore every fixture.
func _saved_intent_digest() -> void:
	var capture_service = load("res://tools/foundation/authoring_acceptance/snapshot_capture.gd")
	var execution = load("res://tools/foundation/authoring_acceptance/execution_project.gd")
	var base := "res://tests/foundation/authoring/fixtures/minimal/"
	var source_root := ProjectSettings.globalize_path("res://").trim_suffix("/")
	var request := {"entry_kind":"ACCEPT_SAVED","level_ref":{"level_authoring_id":"00000000-0000-4000-8000-000000000001","level_id":&"authoring_minimal","root_source_uri":base+"level.tscn"},"policy":Records.default_execution_policy("ACCEPT_SAVED")}
	var original := {}
	for name in ["level.tscn","intent.tres","surface.tscn"]: original[name] = FileAccess.get_file_as_bytes(base+name)
	var observations := {}
	var source: String = original["intent.tres"].get_string_from_utf8()
	var prefix := '[gd_resource type="Resource" load_steps=6 format=3]\n[ext_resource type="Script" path="res://foundation/authoring/intent_authoring_resource.gd" id="Intent"]\n[ext_resource type="Script" path="res://foundation/authoring/milestone_authoring_resource.gd" id="Milestone"]\n[ext_resource type="Script" path="res://foundation/authoring/bypass_authoring_resource.gd" id="Bypass"]\n'
	prefix += '[sub_resource type="Resource" id="Milestone"]\nscript = ExtResource("Milestone")\nauthoring_id = "00000000-0000-4000-8000-000000000005"\nmilestone_id = &"goal"\nrequired = true\npredicate = {"kind": 4}\n'
	prefix += '[sub_resource type="Resource" id="Bypass"]\nscript = ExtResource("Bypass")\nauthoring_id = "00000000-0000-4000-8000-000000000006"\nbypass_id = &"no_move"\ndisabled_mechanics = [0]\n'
	var referenced: String = prefix + source.substr(source.find("[resource]")).replace("expected_milestones = []",'expected_milestones = [SubResource("Milestone")]').replace("forbidden_bypasses = []",'forbidden_bypasses = [SubResource("Bypass")]')
	for variant in ["empty","missing","referenced","milestone_changed","bypass_changed","unrelated","missing_ref","wrong_kind","duplicate_id"]:
		for name in original: _write_bytes(base+name,original[name])
		var text: String = source if variant in ["empty","missing","unrelated"] else referenced
		match variant:
			"missing": _write_bytes(base+"level.tscn",original["level.tscn"].get_string_from_utf8().replace('intent = ExtResource("Intent")','intent = null').to_utf8_buffer())
			"milestone_changed": text = referenced.replace("required = true","required = false")
			"bypass_changed": text = referenced.replace("disabled_mechanics = [0]","disabled_mechanics = [1]")
			"unrelated": _write_bytes(base+"surface.tscn",original["surface.tscn"].get_string_from_utf8().replace("walkable = true","walkable = false").to_utf8_buffer())
			"missing_ref": text = source.replace("expected_milestones = []",'expected_milestones = [{"resource_ref":"00000000-0000-4000-8000-000000000099"}]')
			"wrong_kind": text = referenced.replace('expected_milestones = [SubResource("Milestone")]', 'expected_milestones = [SubResource("Bypass")]')
			"duplicate_id": text = referenced.replace('00000000-0000-4000-8000-000000000006','00000000-0000-4000-8000-000000000005')
		_write_bytes(base+"intent.tres",text.to_utf8_buffer())
		var runs := source_root.path_join(".godot/foundation-authoring/runs")
		var before := DirAccess.get_directories_at(runs)
		var captured: Dictionary = capture_service.capture_saved(request,source_root)
		var invalid: bool = variant in ["missing_ref","wrong_kind","duplicate_id"]
		check(captured.ok != invalid,"saved Intent capture " + variant)
		if invalid:
			check(captured.value == null,"invalid capture publishes no SnapshotRef " + variant)
			for run_id in DirAccess.get_directories_at(runs):
				if run_id not in before: check(not FileAccess.file_exists(runs.path_join(run_id).path_join("input.ready")),"invalid capture publishes no input.ready " + variant)
		elif captured.ok:
			observations[variant] = captured.value
			var verified: Dictionary = execution.verify(captured.value)
			check(verified.ok,"sealed captured Intent verifies " + variant)
			if variant == "missing": check(captured.value.identity.source_intent_digest == null,"missing Intent alone has null digest")
			else: check(Schemas._hex(captured.value.identity.source_intent_digest,64),"present saved Intent has 64 hex digest " + variant)
			if verified.ok:
				var closure := Schemas.project_source_intent(verified.value.authoring)
				var expected: Variant = null if closure.value == null else Wire.digest("source_intent",closure.value).value
				check(captured.value.identity.source_intent_digest == expected,"digest binds same sealed authoring " + variant)
				check(verified.value.manifest.identity.versions.schemas.has("source_intent"),"current VersionsRecord has source_intent")
				var old: Dictionary = verified.value.manifest.identity.versions.duplicate(true)
				old.schemas.erase("source_intent")
				check(not Wire.encode_wire("versions",old).ok,"old VersionsRecord rejected without fallback")
	for name in original: _write_bytes(base+name,original[name])
	for variant in ["milestone_changed","bypass_changed"]:
		check(observations.has("referenced") and observations.has(variant) and observations.referenced.identity.source_intent_digest != null and observations.referenced.identity.source_intent_digest != observations[variant].identity.source_intent_digest,"referenced content changes saved digest " + variant)
	check(observations.has("empty") and observations.has("unrelated") and observations.empty.identity.source_intent_digest != null and observations.empty.identity.source_intent_digest == observations.unrelated.identity.source_intent_digest,"unrelated Resource excluded from saved digest")
	if observations.has("empty"):
		var sealed: Dictionary = observations.empty
		_write_bytes(base+"intent.tres",referenced.to_utf8_buffer())
		check(execution.verify(sealed).ok,"sealed digest verification ignores changed active Intent source")
		var reconstructed: Dictionary = execution.snapshot_from_run(sealed.root_path)
		check(reconstructed.ok and reconstructed.value == sealed,"run reconstruction ignores active Intent source")
		_write_bytes(base+"intent.tres",original["intent.tres"])
	_write_bytes(evidence_dir().path_join("source-intent-evidence.json"),JSON.stringify(observations,"\t").to_utf8_buffer())
