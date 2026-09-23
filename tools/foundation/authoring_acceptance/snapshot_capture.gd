extends RefCounted
## Saved-only capture. Authoring interpretation belongs exclusively to 4A.
const S = preload("res://tools/foundation/authoring_acceptance/wire_schemas.gd")
const Wire = preload("res://tools/foundation/authoring_acceptance/tool_wire.gd")
const Records = preload("res://tools/foundation/authoring_acceptance/run_records.gd")
const Execution = preload("res://tools/foundation/authoring_acceptance/execution_project.gd")
const Schema = preload("res://foundation/authoring/authoring_schema.gd")
const Projector = preload("res://foundation/authoring/document_projector.gd")
const Assembler = preload("res://foundation/authoring/payload_assembler.gd")

static func capture(_request: Dictionary, _editor_context: Dictionary) -> Dictionary:
	return S.failure("DEPENDENCY_PENDING", "Editor buffer capture and save reconciliation belong to D5")

static func capture_saved(request: Dictionary, project_root: String) -> Dictionary:
	return new()._saved(request, project_root)

func _saved(request: Dictionary, project_root: String) -> Dictionary:
	if not S._fields(request,["entry_kind","level_ref","policy"]) or request.entry_kind != "ACCEPT_SAVED" or not S._level_ref(request.level_ref): return S.failure("REQUEST_INVALID", "Expected saved RunRequest")
	var policy_wire := Wire.encode_wire("policy",request.policy)
	if not policy_wire.ok: return policy_wire
	if request.policy.entry_kind != request.entry_kind: return S.failure("REQUEST_INVALID", "Policy mode differs")
	var actual_root := ProjectSettings.globalize_path("res://").replace("\\","/").trim_suffix("/")
	if project_root != actual_root or not Execution.safe_path(project_root): return S.failure("PATH_INVALID", "Capture must run inside the explicit E-drive source project")
	var prepared := Execution.prepare(project_root)
	if not prepared.ok: return prepared
	var trusted := {}
	for kind in Schema.SCRIPTS:
		var script: String = Schema.script_path(kind)
		if not prepared.value.files.has(script): return S.failure("DEPENDENCY_PENDING", "Authoring script is not frozen", script)
		trusted[script] = Execution.sha(prepared.value.files[script])
	var frozen := _freeze_sources(request.level_ref.root_source_uri,project_root,trusted)
	if not frozen.ok: return frozen
	var run_id := Execution.uuid()
	var root := project_root.path_join(".godot/foundation-authoring/runs/" + run_id)
	var assembled := _project_frozen(request.level_ref, frozen.value, prepared.value.files, root)
	if not assembled.ok: return assembled
	var documents: Array = assembled.value.documents
	var payload_wire := Wire.encode_wire("authoring",assembled.value)
	if not payload_wire.ok: return payload_wire
	var payload_digest := Execution.sha(payload_wire.value)
	var source_manifest := {"authoring_payload_digest":payload_digest,"dependencies":[],"source_locations":[]}
	for doc in documents:
		var ids: Array = []
		for record in doc.records:
			ids.append(record.authoring_id)
			source_manifest.source_locations.append({"document_uri":doc.document_uri,"authoring_id":record.authoring_id,"node_path":record.node_path,"label":record.label})
		for resource in doc.resources:
			if resource.document_uri != doc.document_uri: continue
			if resource.authoring_id not in ids:
				ids.append(resource.authoring_id)
				source_manifest.source_locations.append({"document_uri":doc.document_uri,"authoring_id":resource.authoring_id,"node_path":null,"label":""})
		ids.sort()
		var uid: Variant = _header_uid(frozen.value[doc.document_uri].get_string_from_utf8())
		source_manifest.dependencies.append({"source_uri":doc.document_uri,"resource_uid":uid,"kind":"SCENE" if doc.kind in ["LEVEL","WORLD"] else "RESOURCE","origin":"SAVED","content_digest":payload_digest,"disk_digest":Execution.sha(frozen.value[doc.document_uri]),"declared_version":"puzzleintentauthoring.v1" if doc.kind == "INTENT" else "levelauthoring.v1","authoring_ids":ids})
	source_manifest.source_locations.sort_custom(func(a,b):
		for field in ["document_uri","authoring_id","node_path","label"]:
			if a[field] != b[field]:
				if a[field] == null: return true
				if b[field] == null: return false
				return a[field].to_utf8_buffer().hex_encode() < b[field].to_utf8_buffer().hex_encode()
		return false)
	var source_wire := Wire.encode_wire("source_manifest",source_manifest)
	if not source_wire.ok: return source_wire
	var snapshot := {"identity":{"run_id":run_id,"snapshot_id":Execution.uuid(),"source_fingerprint":Execution.sha(source_wire.value),"source_intent_digest":null},"level_ref":request.level_ref.duplicate(true),"input_mode":"ACCEPT_SAVED","input_manifest":{},"execution_digest":prepared.value.execution_digest,"root_path":root}
	# Standalone saved capture is its own editor-instance equivalent, generation 0.
	# D5/service will provide an actual editor identity for its capture path.
	var identity := Records.make_identity(Execution.uuid(),0,request.level_ref,snapshot,Execution.sha(policy_wire.value),prepared.value.execution_digest,prepared.value.versions)
	if identity.is_empty(): return S.failure("IDENTITY_INVALID", "Cannot bind snapshot identity")
	var pending := {}
	var refs := {}
	for pair in [["authoring_payload",payload_wire.value,"levelauthoring.v1"],["source_manifest",source_wire.value,"authoringsourcemanifest.v1"],["execution_policy",policy_wire.value,"authoringpolicy.v1"]]:
		var path: String = "input/" + Execution.sha(pair[1]) + ".wire"
		pending[path] = pair[1]
		refs[pair[0]] = Execution.artifact(path,pair[1],pair[2])
	for uri in frozen.value:
		pending["input/source/" + Execution.sha(frozen.value[uri]) + ".blob"] = frozen.value[uri]
	for uri in prepared.value.files:
		pending["input/execution/" + Execution.sha(prepared.value.files[uri]) + ".blob"] = prepared.value.files[uri]
	var attachments: Array = refs.values()
	for path in pending:
		if path.ends_with(".blob"): attachments.append(Execution.artifact(path,pending[path],"rawbytes.v1"))
	attachments.sort_custom(func(a,b): return a.relative_path < b.relative_path)
	var manifest := {"manifest_version":"authoringinputmanifest.v1","identity":identity,"input_mode":"ACCEPT_SAVED","source_manifest":refs.source_manifest,"authoring_payload":refs.authoring_payload,"execution_policy":refs.execution_policy,"attachments":attachments,"source_metadata":{"git_head":null,"engine_path":OS.get_executable_path()}}
	var ready := Wire.encode_wire("input_manifest",manifest)
	if not ready.ok: return ready
	for path in pending:
		if pending[path].size() > request.policy.max_wire_bytes: return S.failure("WIRE_SIZE_EXCEEDED", "Attachment exceeds policy",path)
		var written := Execution.write_new(root.path_join(path),pending[path])
		if not written.ok: return written
	# Last consistency boundary precedes publication. Never retry a changed source.
	var stable := _unchanged(frozen.value,prepared.value.files,project_root)
	if not stable.ok: return stable
	var sealed := Execution.write_new(root.path_join("input.ready"),ready.value)
	if not sealed.ok: return sealed
	snapshot.input_manifest = Execution.artifact("input.ready",ready.value,"authoringinputmanifest.v1")
	return S.success(snapshot)

func _unchanged(sources: Dictionary, modules: Dictionary, root: String) -> Dictionary:
	for collection in [sources,modules]:
		for uri in collection:
			if uri == "res://project.godot": continue # generated effective configuration
			var read := Execution.read_bytes(root.path_join(uri.substr(6)))
			if not read.ok or read.value != collection[uri]: return S.failure("CAPTURE_CHANGED", "Source or execution dependency changed during capture",uri)
	return S.success(null)

func _freeze_sources(first: String, root: String, trusted: Dictionary) -> Dictionary:
	var queue: Array = [first]
	var frozen := {}
	var dependency_pattern := RegEx.new()
	dependency_pattern.compile('res://[^"\\s]+')
	while not queue.is_empty():
		var uri: String = queue.pop_front()
		if frozen.has(uri): continue
		if not S._resource_path(uri) or uri.get_extension() not in ["tscn","tres"]: return S.failure("SOURCE_INVALID", "Only canonical saved scene/resource sources are supported",uri)
		var read := Execution.read_bytes(root.path_join(uri.substr(6)))
		if not read.ok: return read
		frozen[uri] = read.value
		var text: String = read.value.get_string_from_utf8()
		# Explicit paths own loading. UID metadata must agree with those frozen
		# path targets; it never grants a second lookup or fallback location.
		for line in text.split("\n"):
			var header := line.strip_edges()
			if header.begins_with("[ext_resource "):
				if not header.contains('path="res://'): return S.failure("SOURCE_INVALID", "Resource references require explicit project paths",uri)
				if not (header.contains('type="Script"') or header.contains('type="PackedScene"') or header.contains('type="Resource"')): return S.failure("SOURCE_INVALID", "Unsupported external resource type",uri)
				var path := _attribute(header,"path")
				var uid := _attribute(header,"uid")
				if not S._resource_path(path): return S.failure("PATH_INVALID", "Noncanonical external resource path",uri)
				if not uid.is_empty():
					if not Execution._valid_uid(uid): return S.failure("EXECUTION_DEPENDENCY_INVALID", "Invalid resource UID",uri)
					var target := Execution.read_bytes(root.path_join(path.substr(6) + (".uid" if path.ends_with(".gd") else "")))
					if not target.ok: return target
					var expected: Variant = target.value.get_string_from_utf8().strip_edges() if path.ends_with(".gd") else _header_uid(target.value.get_string_from_utf8())
					if uid != expected: return S.failure("EXECUTION_DEPENDENCY_INVALID", "UID does not identify the frozen path",uri)
			if header.begins_with("[sub_resource ") and not header.contains('type="Resource"'): return S.failure("SOURCE_INVALID", "Unsupported embedded resource type",uri)
		# Preflight all resource script paths before ResourceLoader can construct a
		# custom Resource. Unknown scripts never get to execute as a side effect.
		for found in dependency_pattern.search_all(read.value.get_string_from_utf8()):
			var dependency := found.get_string()
			if not S._resource_path(dependency): return S.failure("PATH_INVALID", "Noncanonical source dependency",dependency)
			if dependency.ends_with(".gd"):
				if not trusted.has(dependency): return S.failure("UNSUPPORTED_SCRIPT", "Source script is outside 4A whitelist",dependency)
			elif dependency.get_extension() in ["tscn","tres"]:
				if dependency not in queue: queue.append(dependency)
			else: return S.failure("SOURCE_INVALID", "Undeclared source dependency type",dependency)
	return S.success(frozen)

static func _attribute(line: String, key: String) -> String:
	var pattern := RegEx.new()
	pattern.compile('(?:^|\\s)' + key + '="([^"]*)"')
	var found := pattern.search(line)
	return found.get_string(1) if found != null else ""

static func _header_uid(text: String) -> Variant:
	var uid := _attribute(text.get_slice("\n",0),"uid")
	return uid if Execution._valid_uid(uid) else null

func _project_frozen(level_ref: Dictionary, frozen: Dictionary, modules: Dictionary, run_root: String) -> Dictionary:
	# Separate ResourceLoader namespace preserves original res:// identities while
	# making every load resolve to the frozen bytes, including nested Resources.
	var project := run_root.path_join("capture/project")
	for collection in [modules,frozen]:
		for uri in collection:
			var written := Execution.write_new(project.path_join(uri.substr(6)),collection[uri])
			if not written.ok: return written
	var output_path := run_root.path_join("capture/authoring.wire")
	var output: Array = []
	var imported := _execute_capture(["--headless","--path",project,"--editor","--import"],run_root,output)
	var import_log := "\n".join(output)
	Execution.write_new(run_root.path_join("capture/import.log"),import_log.to_utf8_buffer())
	if imported != 0 or import_log.contains("SCRIPT ERROR:") or import_log.contains("ERROR:"): return S.failure("EXECUTION_DEPENDENCY_INVALID", "Frozen project import failed; see capture/import.log")
	output.clear()
	var code := _execute_capture(["--headless","--path",project,"--quit","--script","res://tools/foundation/authoring_acceptance/execution_project.gd","--","--project-frozen",level_ref.root_source_uri,String(level_ref.level_id),level_ref.level_authoring_id,output_path],run_root,output)
	Execution.write_new(run_root.path_join("capture/projection.log"),"\n".join(output).to_utf8_buffer())
	if code != 0 or "\n".join(output).contains("ERROR:"): return S.failure("SOURCE_INVALID", "Frozen 4A projection failed; see capture/projection.log")
	var bytes := Execution.read_bytes(output_path)
	if not bytes.ok: return bytes
	return Wire.decode_wire("authoring",bytes.value)

static func _execute_capture(args: Array, run_root: String, output: Array) -> int:
	var environment_root := run_root.path_join("capture/environment")
	if not Execution.safe_path(environment_root) or DirAccess.make_dir_recursive_absolute(environment_root) != OK: return -1
	# Scoped process-local inheritance only; no registry, user, system or global
	# environment changes. Saved capture is synchronous and restores every value.
	var saved := {}
	for key in ["TEMP","TMP","APPDATA","LOCALAPPDATA"]:
		saved[key] = OS.get_environment(key) if OS.has_environment(key) else null
		OS.set_environment(key,environment_root)
	var code := OS.execute(OS.get_executable_path(),args,output,true)
	for key in saved:
		if saved[key] == null: OS.unset_environment(key)
		else: OS.set_environment(key,saved[key])
	return code

func _project_current(level_ref: Dictionary, frozen: Dictionary, trusted: Dictionary) -> Dictionary:
	var documents: Array[Dictionary] = []
	for uri in frozen:
		# CACHE_MODE_IGNORE_DEEP prevents prior editor-loaded Resource values from
		# substituting saved dependencies. Nothing is instantiated from PackedScene.
		var resource := ResourceLoader.load(uri,"",ResourceLoader.CACHE_MODE_IGNORE_DEEP)
		if resource == null: return S.failure("SOURCE_INVALID", "Cannot read frozen saved source", uri)
		var source: Variant = resource.get_state() if resource is PackedScene else resource
		var id := ""
		if source is SceneState:
			for index in source.get_node_property_count(0):
				if source.get_node_property_name(0,index) == &"authoring_id": id = str(source.get_node_property_value(0,index))
		elif resource is Resource:
			id = str(resource.get("authoring_id"))
		var projected := Projector.project_document(source,{"document_uri":uri,"document_authoring_id":id,"origin":"SAVED","allowed_script_digests":trusted,"instance_role":null})
		if not projected.ok: return projected
		documents.append(projected.value)
	documents.sort_custom(func(a,b): return a.document_uri < b.document_uri)
	var assembled := Assembler.assemble_payload(documents,level_ref)
	if not assembled.ok: return assembled
	return assembled
