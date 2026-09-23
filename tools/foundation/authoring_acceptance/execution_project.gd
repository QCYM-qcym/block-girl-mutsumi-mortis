extends SceneTree
## File boundary for sealed input. No active source reads occur in materialize.
const S = preload("res://tools/foundation/authoring_acceptance/wire_schemas.gd")
const Wire = preload("res://tools/foundation/authoring_acceptance/tool_wire.gd")
const DEPENDENCIES := "res://tools/foundation/authoring_acceptance/execution_dependencies.json"
const LIMIT := 134217728
const CONFIG := 'config_version=5\n\n[application]\nconfig/name="Foundation Controlled Execution"\nconfig/features=PackedStringArray("4.7", "GL Compatibility")\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="foundation-authoring"\n\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n'

static func sha(bytes: PackedByteArray) -> String:
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(bytes)
	return hash.finish().hex_encode()

static func uuid() -> String:
	var bytes := Crypto.new().generate_random_bytes(16)
	bytes[6] = (bytes[6] & 15) | 64
	bytes[8] = (bytes[8] & 63) | 128
	var hex := bytes.hex_encode()
	return "%s-%s-%s-%s-%s" % [hex.substr(0,8),hex.substr(8,4),hex.substr(12,4),hex.substr(16,4),hex.substr(20,12)]

# Reject every linked ancestor, including Windows directory junctions. This is
# conservative: even a link that currently stays in the root is not accepted.
static func safe_path(path: String) -> bool:
	var normalized := path.replace("\\", "/")
	if not normalized.begins_with("E:/") or normalized.simplify_path() != normalized: return false
	var current := "E:/"
	for segment in normalized.substr(3).split("/", false):
		if not S._package_path(segment): return false
		var dir := DirAccess.open(current)
		if dir == null: return false
		if dir.is_link(segment): return false
		current = current.path_join(segment)
		if not DirAccess.dir_exists_absolute(current) and not FileAccess.file_exists(current):
			# Remaining not-yet-created path is lexical only; callers recheck after mkdir.
			return true
	return true

static func read_bytes(path: String, limit: int = LIMIT) -> Dictionary:
	if not safe_path(path) or not FileAccess.file_exists(path): return S.failure("INPUT_INCOMPLETE", "Missing file or unsafe path", path)
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return S.failure("INPUT_INCOMPLETE", "Cannot open file", path)
	var length := file.get_length()
	if length > limit:
		file.close()
		return S.failure("WIRE_SIZE_EXCEEDED", "File exceeds size budget", path)
	var bytes := file.get_buffer(length)
	file.close()
	if bytes.size() != length: return S.failure("INPUT_INCOMPLETE", "Short file read", path)
	return S.success(bytes)

static func write_new(path: String, bytes: PackedByteArray) -> Dictionary:
	if not safe_path(path): return S.failure("PATH_INVALID", "Unsafe output path", path)
	if FileAccess.file_exists(path):
		var existing := read_bytes(path)
		return S.success(null) if existing.ok and existing.value == bytes else S.failure("IMMUTABLE_PACKAGE", "Existing bytes differ", path)
	if DirAccess.make_dir_recursive_absolute(path.get_base_dir()) != OK or not safe_path(path): return S.failure("IO_ERROR", "Cannot create safe parent", path)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return S.failure("IO_ERROR", "Cannot create file", path)
	file.store_buffer(bytes)
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK: return S.failure("IO_ERROR", "Write failed", path)
	var checked := read_bytes(path)
	return S.success(null) if checked.ok and checked.value == bytes else S.failure("IO_ERROR", "Readback differs", path)

static func artifact(path: String, bytes: PackedByteArray, format: String) -> Dictionary:
	return {"relative_path":path,"byte_length":bytes.size(),"sha256":sha(bytes),"format_version":format}

static func read_artifact(root: String, ref: Dictionary) -> Dictionary:
	if not S._artifact(ref) or ref.byte_length > LIMIT: return S.failure("ARTIFACT_INVALID", "Invalid artifact reference")
	var result := read_bytes(root.path_join(ref.relative_path))
	if not result.ok: return result
	if result.value.size() != ref.byte_length or sha(result.value) != ref.sha256: return S.failure("ARTIFACT_DIGEST_MISMATCH", "Artifact bytes do not match", ref.relative_path)
	return result

static func _engine_matches(engine: Dictionary) -> bool:
	var info := Engine.get_version_info()
	var full := "%d.%d.%d.%s.%s.%s" % [info.major,info.minor,info.patch,info.status,info.build,info.hash.substr(0,9)]
	return engine.version == full and engine.executable_sha256 == FileAccess.get_sha256(OS.get_executable_path())

static func _valid_uid(text: String) -> bool:
	if not text.begins_with("uid://") or text.length() <= 6: return false
	for c in text.substr(6):
		if c not in "abcdefghijklmnopqrstuvwxyz0123456789": return false
	var id := ResourceUID.text_to_id(text)
	return id >= 0 and ResourceUID.id_to_text(id) == text

static func prepare(source_root: String) -> Dictionary:
	if not safe_path(source_root): return S.failure("PATH_INVALID", "An E-drive project root is required")
	var declaration_path := source_root.path_join(DEPENDENCIES.substr(6))
	var declared := read_bytes(declaration_path)
	if not declared.ok: return declared
	var config: Variant = JSON.parse_string(declared.value.get_string_from_utf8())
	if not S._fields(config,["version","engine","modules","dynamic"]) or config.version != 1 or not config.modules is Array or not config.dynamic is Array or not S._fields(config.engine,["version","executable_sha256"]): return S.failure("EXECUTION_DEPENDENCY_INVALID", "Invalid dependency declaration")
	if not _engine_matches(config.engine): return S.failure("EXECUTION_VERSION_MISMATCH", "Actual engine differs from approved engine")
	var paths: Array = config.modules.duplicate()
	for path in config.dynamic:
		if path not in paths: return S.failure("DEPENDENCY_PENDING", "Dynamic dependency is not in whitelist", str(path))
	paths.append(DEPENDENCIES)
	for path in config.modules:
		if typeof(path) != TYPE_STRING or not S._resource_path(path) or not path.ends_with(".gd"): return S.failure("EXECUTION_DEPENDENCY_INVALID", "Invalid module path")
		paths.append(path + ".uid")
	paths.sort()
	var files := {}
	var modules: Array = []
	var ids := {}
	for path in paths:
		if files.has(path): return S.failure("EXECUTION_DEPENDENCY_INVALID", "Duplicate module path", path)
		var read := read_bytes(source_root.path_join(path.substr(6)))
		if not read.ok: return S.failure("DEPENDENCY_PENDING", "Missing module or UID", path)
		files[path] = read.value
		if path.ends_with(".uid"):
			var uid: String = read.value.get_string_from_utf8().strip_edges()
			if not _valid_uid(uid) or ids.has(uid): return S.failure("EXECUTION_DEPENDENCY_INVALID", "Missing or ambiguous UID", path)
			ids[uid] = path
		modules.append({"path":path,"sha256":sha(read.value),"version":null})
	var closure := _closure(files, config)
	if not closure.ok: return closure
	var bytes := CONFIG.to_utf8_buffer()
	files["res://project.godot"] = bytes
	var versions := {"record_version":"foundationversions.v1","tool_version":"authoringrun.v1","schemas":S.SCHEMA_VERSIONS.duplicate(),"contracts":S.CONTRACT_VERSIONS.duplicate(),"engine":config.engine,"modules":modules,"configuration":[{"path":"res://project.godot","sha256":sha(bytes),"version":null}]}
	var digest := Wire.digest("versions", versions)
	if not digest.ok: return digest
	return S.success({"versions":versions,"execution_digest":digest.value,"files":files})

static func _closure(files: Dictionary, declaration: Dictionary) -> Dictionary:
	var declared: Array = declaration.modules.duplicate()
	declared.append(DEPENDENCIES)
	for module in declaration.modules: declared.append(module + ".uid")
	for path in files:
		if path != "res://project.godot" and path not in declared: return S.failure("EXECUTION_DEPENDENCY_INVALID", "File outside explicit whitelist", path)
	for path in declared:
		if not files.has(path): return S.failure("DEPENDENCY_PENDING", "Missing declared dependency", path)
	for path in declaration.dynamic:
		if path not in declaration.modules or not files.has(path): return S.failure("DEPENDENCY_PENDING", "Missing dynamic dependency", path)
	var pattern := RegEx.new()
	pattern.compile('res://[A-Za-z0-9_./-]+\\.(?:gd|tscn|tres)')
	for path in files:
		if not path.ends_with(".gd"): continue
		var text: String = files[path].get_string_from_utf8()
		for found in pattern.search_all(text):
			if not files.has(found.get_string()): return S.failure("DEPENDENCY_PENDING", "Static/literal dependency is not frozen", found.get_string())
	return S.success(null)

static func snapshot_shape(value: Variant) -> bool:
	if not S._fields(value,["identity","level_ref","input_mode","input_manifest","execution_digest","root_path"]): return false
	if typeof(value.input_mode) != TYPE_STRING: return false
	if not S._fields(value.identity,["run_id","snapshot_id","source_fingerprint","source_intent_digest"]): return false
	var id: Dictionary = value.identity
	return S._uuid(id.run_id) and S._uuid(id.snapshot_id) and S._hex(id.source_fingerprint,64) and (id.source_intent_digest == null or S._hex(id.source_intent_digest,64)) and S._level_ref(value.level_ref) and value.input_mode in ["ACCEPT_SAVED","ANALYZE_CURRENT"] and S._artifact(value.input_manifest) and S._hex(value.execution_digest,64) and typeof(value.root_path) == TYPE_STRING and safe_path(value.root_path)

static func verify(snapshot_ref: Dictionary) -> Dictionary:
	if not snapshot_shape(snapshot_ref): return S.failure("SNAPSHOT_INVALID", "Invalid closed SnapshotRef")
	var ref: Dictionary = snapshot_ref.input_manifest
	if ref.relative_path != "input.ready" or ref.format_version != "authoringinputmanifest.v1": return S.failure("INPUT_INCOMPLETE", "Expected final input.ready")
	var read := read_artifact(snapshot_ref.root_path, ref)
	if not read.ok: return read
	var decoded := Wire.decode_wire("input_manifest", read.value)
	if not decoded.ok: return decoded
	var manifest: Dictionary = decoded.value
	var id: Dictionary = manifest.identity
	if id.run_id != snapshot_ref.identity.run_id or id.snapshot_id != snapshot_ref.identity.snapshot_id or id.source_fingerprint != snapshot_ref.identity.source_fingerprint or id.level_ref != snapshot_ref.level_ref or id.execution_digest != snapshot_ref.execution_digest or manifest.input_mode != snapshot_ref.input_mode: return S.failure("SNAPSHOT_IDENTITY_MISMATCH", "Snapshot and sealed identity differ")
	if not _engine_matches(id.versions.engine): return S.failure("EXECUTION_VERSION_MISMATCH", "Actual engine differs from sealed identity")
	var artifacts := {}
	for attachment in manifest.attachments:
		var bytes := read_artifact(snapshot_ref.root_path,attachment)
		if not bytes.ok: return bytes
		artifacts[attachment.relative_path] = bytes.value
	var source := Wire.decode_wire("source_manifest", artifacts[manifest.source_manifest.relative_path])
	var authoring := Wire.decode_wire("authoring", artifacts[manifest.authoring_payload.relative_path])
	var policy := Wire.decode_wire("policy", artifacts[manifest.execution_policy.relative_path])
	for result in [source,authoring,policy]:
		if not result.ok: return result
	if source.value.authoring_payload_digest != manifest.authoring_payload.sha256 or policy.value.entry_kind != manifest.input_mode or authoring.value.level_ref != id.level_ref: return S.failure("SNAPSHOT_IDENTITY_MISMATCH", "Input artifact bindings differ")
	for attachment in manifest.attachments:
		if attachment.byte_length > policy.value.max_wire_bytes: return S.failure("WIRE_SIZE_EXCEEDED", "Policy attachment limit exceeded")
	for dependency in source.value.dependencies:
		if manifest.input_mode == "ACCEPT_SAVED" and (dependency.origin != "SAVED" or dependency.disk_digest == null or not dependency.source_uri.begins_with("res://")): return S.failure("SNAPSHOT_INVALID", "Saved package contains unsaved source")
		if dependency.disk_digest != null:
			var source_blob: String = "input/source/" + dependency.disk_digest + ".blob"
			if not artifacts.has(source_blob) or sha(artifacts[source_blob]) != dependency.disk_digest: return S.failure("INPUT_INCOMPLETE", "Missing frozen source bytes", dependency.source_uri)
	var files := {}
	for item in id.versions.modules + id.versions.configuration:
		files[item.path] = artifacts["input/execution/" + item.sha256 + ".blob"]
	if not files.has(DEPENDENCIES) or files.get("res://project.godot") != CONFIG.to_utf8_buffer(): return S.failure("EXECUTION_DEPENDENCY_INVALID", "Missing whitelist or uncontrolled configuration")
	var declaration: Variant = JSON.parse_string(files[DEPENDENCIES].get_string_from_utf8())
	if not S._fields(declaration,["version","engine","modules","dynamic"]) or declaration.version != 1 or not declaration.modules is Array or not declaration.dynamic is Array or declaration.engine != id.versions.engine: return S.failure("EXECUTION_DEPENDENCY_INVALID", "Invalid frozen whitelist")
	var closure := _closure(files,declaration)
	if not closure.ok: return closure
	var uids := {}
	for path in files:
		if path.ends_with(".gd") and not files.has(path + ".uid"): return S.failure("DEPENDENCY_PENDING", "Script has no frozen UID", path)
		if path.ends_with(".uid"):
			var uid: String = files[path].get_string_from_utf8().strip_edges()
			if not _valid_uid(uid) or uids.has(uid): return S.failure("EXECUTION_DEPENDENCY_INVALID", "Invalid/duplicate frozen UID", path)
			uids[uid] = path
	return S.success({"manifest":manifest,"files":files,"authoring":authoring.value,"source":source.value,"policy":policy.value})

static func materialize(snapshot_ref: Dictionary, source_root: String) -> Dictionary:
	# source_root is provenance context only. No fallback reads, even on failure.
	if not safe_path(source_root): return S.failure("PATH_INVALID", "Expected E-drive source context")
	var checked := verify(snapshot_ref)
	if not checked.ok: return checked
	var project: String = snapshot_ref.root_path.path_join("execution/project")
	var inventory := _existing_files(project,project,checked.value.files)
	if not inventory.ok: return inventory
	for path in checked.value.files:
		var destination: String = project.path_join(path.substr(6))
		if FileAccess.file_exists(destination):
			var existing := read_bytes(destination)
			if not existing.ok or existing.value != checked.value.files[path]: return S.failure("IMMUTABLE_PACKAGE", "Existing execution bytes differ", destination)
	for path in checked.value.files:
		var written := write_new(project.path_join(path.substr(6)),checked.value.files[path])
		if not written.ok: return written
	return S.success({"project_root":project,"execution_digest":snapshot_ref.execution_digest,"manifest":snapshot_ref.input_manifest.duplicate(true)})

static func _existing_files(root: String, directory: String, allowed: Dictionary) -> Dictionary:
	if not safe_path(directory): return S.failure("PATH_INVALID", "Linked execution directory",directory)
	if not DirAccess.dir_exists_absolute(directory): return S.success(null)
	var dir := DirAccess.open(directory)
	if dir == null: return S.failure("IO_ERROR", "Cannot inspect execution directory",directory)
	for name in dir.get_files():
		var path := directory.path_join(name)
		if dir.is_link(name) or not allowed.has("res://" + path.substr(root.length()+1)): return S.failure("EXECUTION_DEPENDENCY_INVALID", "Unexpected execution file",path)
	for name in dir.get_directories():
		# Godot's generated import/cache directory is never a source fallback.
		if name == ".godot" and directory == root and not dir.is_link(name): continue
		var child := _existing_files(root,directory.path_join(name),allowed)
		if not child.ok: return child
	return S.success(null)

func _initialize() -> void:
	# Private D2 one-shot frozen projection entry, not a task service or wrapper.
	var args := OS.get_cmdline_user_args()
	if args.size() != 5 or args[0] != "--project-frozen":
		quit(2)
		return
	var level_ref := {"root_source_uri":args[1],"level_id":StringName(args[2]),"level_authoring_id":args[3]}
	var current := ProjectSettings.globalize_path("res://").trim_suffix("/")
	if not safe_path(OS.get_user_data_dir().replace("\\","/")):
		quit(2)
		return
	print("FROZEN_STORAGE ",OS.get_user_data_dir())
	if not S._level_ref(level_ref) or not safe_path(current) or not safe_path(args[4]) or args[4] != current.get_base_dir().path_join("authoring.wire"):
		quit(2)
		return
	var schema = load("res://foundation/authoring/authoring_schema.gd")
	var trusted := {}
	for kind in schema.SCRIPTS:
		var script: String = schema.script_path(kind)
		trusted[script] = FileAccess.get_sha256(script)
	var capture_service = load("res://tools/foundation/authoring_acceptance/snapshot_capture.gd").new()
	var frozen: Dictionary = capture_service._freeze_sources(level_ref.root_source_uri,current,trusted)
	if not frozen.ok:
		print(frozen.issues)
		quit(1)
		return
	var projected: Dictionary = capture_service._project_current(level_ref,frozen.value,trusted)
	if not projected.ok:
		print(projected.issues)
		quit(1)
		return
	var encoded := Wire.encode_wire("authoring",projected.value)
	if not encoded.ok:
		print(encoded.issues)
		quit(1)
		return
	var written := write_new(args[4],encoded.value)
	quit(0 if written.ok else 1)
