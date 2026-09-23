extends "res://tests/foundation/authoring_acceptance/test_tool_wire.gd"
## D2 real file boundaries, frozen projection and sealed execution. Unit shares
## the structural checks; Real additionally consumes registered A_BAKE + Codec.
## Inherited helpers are declaration fixtures only, never substitute Bake data.

func run() -> void:
	_source_fingerprint_structure()
	_package_structure()
	_saved_package()
	finish()

func _saved_package() -> void:
	var capture_service = load("res://tools/foundation/authoring_acceptance/snapshot_capture.gd")
	var execution = load("res://tools/foundation/authoring_acceptance/execution_project.gd")
	var request := {"entry_kind":"ACCEPT_SAVED", "level_ref":{"level_authoring_id":"00000000-0000-4000-8000-000000000001", "level_id":&"authoring_minimal", "root_source_uri":"res://tests/foundation/authoring/fixtures/minimal/level.tscn"}, "policy":Records.default_execution_policy("ACCEPT_SAVED")}
	var source_root := ProjectSettings.globalize_path("res://").trim_suffix("/")
	var captured: Dictionary = capture_service.capture_saved(request, source_root)
	if not captured.ok: print("CAPTURE_DIAGNOSTIC ", captured.issues)
	if not captured.ok: print("ENGINE_DIAGNOSTIC ", Engine.get_version_info(), " ", FileAccess.get_sha256(OS.get_executable_path()))
	check(captured.ok, "saved disk source produces sealed SnapshotRef")
	if not captured.ok: return
	var sealed: Dictionary = captured.value
	var repeated: Dictionary = capture_service.capture_saved(request, source_root)
	check(repeated.ok, "repeated saved capture succeeds")
	if repeated.ok:
		check(sealed.identity.run_id != repeated.value.identity.run_id, "each capture allocates unique run_id")
		check(sealed.identity.source_fingerprint == repeated.value.identity.source_fingerprint, "same disk source fingerprint stable across runs")
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
	_package_negatives(sealed,source_root,execution)
	_capture_negatives(request,source_root,capture_service,execution)
	if mode() == "Real":
		var payload_path: String = sealed.root_path.path_join(manifest.authoring_payload.relative_path)
		var payload_result := Wire.decode_wire("authoring", FileAccess.get_file_as_bytes(payload_path))
		var adapter = load("res://foundation/authoring/authoring_adapter.gd")
		var baked: Dictionary = adapter.bake_authoring(payload_result.value, request.policy.bake_options, sealed.identity)
		check(baked.ok, "real registered A_BAKE consumes sealed authoring payload")
		if baked.ok:
			var codec = load("res://foundation/level/level_codec.gd")
			var canonical: Dictionary = codec.encode(baked.level)
			check(canonical.ok and codec.decode(canonical.text).level.content_hash == baked.level.content_hash, "real canonical Codec roundtrip retains A_BAKE content hash")

func _package_negatives(sealed: Dictionary, source_root: String, execution) -> void:
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
	var active_path := source_root.path_join("tests/foundation/authoring/fixtures/minimal/level.tscn")
	DirAccess.rename_absolute(active_path,active_path + ".held")
	check(execution.materialize(sealed,source_root).ok,"sealed execution no longer reads active saved source")
	DirAccess.rename_absolute(active_path + ".held",active_path)
	check(FileAccess.get_file_as_bytes(ready_path) == bytes,"negative cases restore test package ready bytes")
	print("D2_EVIDENCE ", JSON.stringify({"snapshot_ref":sealed,"modules":manifest.identity.versions.modules.size(),"execution_digest":sealed.execution_digest,"source_fingerprint":sealed.identity.source_fingerprint}))

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
		_write_bytes(active,original.get_string_from_utf8().replace('level_id = &"authoring_minimal"','level_id = &"changed_during_projection"').to_utf8_buffer())
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
