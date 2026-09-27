extends RefCounted
## Closed D-owned records. Unavailable record schemas fail closed, never use a
## generic Dictionary fallback. A owns authoring/source_map registration.

const KINDS = ["authoring","snapshot","source_map","intent","trace","state_inspection","graph_archive","quality_result","stage_result","report","worker_message","versions","source_manifest","input_manifest","archive_manifest","policy"]
const STAGES = ["AUTHORING","BAKE","INTENT_BIND","INTENT_VALIDATE","ORIGINAL_GRAPH","SOFTLOCK","ABLATION","TRACE_SEMANTICS","MILESTONES","GRAPHICAL_REPLAY","MANUAL_RUNTIME","ARCHIVE"]
const ACCEPT_STAGES = ["AUTHORING","BAKE","INTENT_BIND","INTENT_VALIDATE","ORIGINAL_GRAPH","SOFTLOCK","ABLATION","TRACE_SEMANTICS","MILESTONES","GRAPHICAL_REPLAY","ARCHIVE"]
const POLICY_FIELDS = ["entry_kind","stages","bake_options","search_mode","search_budget","softlock_budget","replay_options","stage_deadline_ms","lease_interval_ms","lease_timeout_ms","max_wire_bytes","max_wire_depth"]
const WORKER_PROTOCOL_VERSION = "foundationworkeripc.v1"
const WORKER_KINDS = ["HELLO","STAGE_STARTED","STAGE_RESULT","HEARTBEAT","EXIT","ERROR","CANCEL","LEASE"]
const STORED_STAGE_FIELDS = ["stage_id","owner","module_ref","applicability","execution","reason","input_refs","actual_policy","actual_budget","native_result","evidence_refs","warnings","started_at","finished_at"]

static func validate(kind: String, value: Variant) -> Dictionary:
	if kind not in KINDS: return failure("WIRE_SCHEMA_INVALID", "Unknown record kind")
	if kind == "worker_message": return _worker_message(value)
	if kind == "stage_result": return _stage_result(value)
	if kind == "authoring":
		# A owns the entire authoring schema, including nested field/ref rules.
		# Resolve only from this controlled checkout; early D-only consumers keep
		# their explicit dependency failure until the registered A delivery exists.
		var path := "res://foundation/authoring/authoring_schema.gd"
		if not ResourceLoader.exists(path): return failure("DEPENDENCY_PENDING", "A_SCHEMA is not installed")
		if typeof(value) != TYPE_DICTIONARY: return failure("WIRE_SCHEMA_INVALID", "Authoring payload must be a Dictionary")
		var schema = load(path)
		if schema == null or not schema.has_method("validate_authoring"): return failure("CONTRACT_MISMATCH", "A_SCHEMA lacks validate_authoring(payload)")
		var checked: Dictionary = schema.validate_authoring(value)
		return success(value) if checked.ok else {"ok":false,"value":null,"issues":checked.issues}
	if kind in ["versions","source_manifest","input_manifest","archive_manifest"]:
		var valid := false
		match kind:
			"versions": valid = _versions(value)
			"source_manifest": valid = _source_manifest(value)
			"input_manifest": valid = _input_manifest(value)
			"archive_manifest": valid = _archive_manifest(value)
		return success(value) if valid else failure("WIRE_SCHEMA_INVALID", "Invalid closed " + kind)
	if kind != "policy": return failure("DEPENDENCY_PENDING", "Record schema not delivered: " + kind)
	if not _fields(value, POLICY_FIELDS): return failure("WIRE_SCHEMA_INVALID", "Closed policy fields required")
	if typeof(value.entry_kind) != TYPE_STRING or value.entry_kind not in ["ACCEPT_SAVED","ANALYZE_CURRENT"]:
		return failure("WIRE_SCHEMA_INVALID", "Unknown entry kind")
	if typeof(value.stages) != TYPE_ARRAY or value.stages.is_empty(): return failure("WIRE_SCHEMA_INVALID", "Stages required")
	var seen := {}
	for stage in value.stages:
		if typeof(stage) != TYPE_STRING or stage not in STAGES or seen.has(stage): return failure("WIRE_SCHEMA_INVALID", "Invalid stage list")
		seen[stage] = true
	if value.entry_kind == "ACCEPT_SAVED" and value.stages != ACCEPT_STAGES: return failure("WIRE_SCHEMA_INVALID", "Acceptance stages are mandatory and ordered")
	if not _ints(value.bake_options, {"max_configurations":1,"max_checks":1}): return failure("WIRE_SCHEMA_INVALID", "Invalid bake budget")
	if not _ints(value.search_budget, {"max_states":1,"max_edges":0,"max_depth":-1,"max_runtime_ms":0,"max_action_evaluations":1}): return failure("WIRE_SCHEMA_INVALID", "Invalid search budget")
	if not _ints(value.softlock_budget, {"max_nodes":1,"max_edges":0,"max_runtime_ms":0}): return failure("WIRE_SCHEMA_INVALID", "Invalid softlock budget")
	if not _ints(value.replay_options, {"mode":0,"max_steps":0,"max_runtime_ms":0,"step_timeout_ms":1}): return failure("WIRE_SCHEMA_INVALID", "Invalid replay options")
	if value.replay_options.mode not in [0,1] or (value.entry_kind == "ACCEPT_SAVED" and value.replay_options.mode != 1): return failure("WIRE_SCHEMA_INVALID", "Graphical acceptance required")
	for field in ["stage_deadline_ms","max_wire_bytes","max_wire_depth"]:
		if typeof(value[field]) != TYPE_INT or value[field] <= 0: return failure("WIRE_SCHEMA_INVALID", "Positive limit required: " + field)
	if typeof(value.search_mode) != TYPE_INT or value.search_mode not in [0,1] or (value.entry_kind == "ACCEPT_SAVED" and value.search_mode != 1): return failure("WIRE_SCHEMA_INVALID", "Full graph required")
	if typeof(value.lease_interval_ms) != TYPE_INT or value.lease_interval_ms != 1000 or typeof(value.lease_timeout_ms) != TYPE_INT or value.lease_timeout_ms != 30000: return failure("WIRE_SCHEMA_INVALID", "Fixed lease protocol")
	return success(value)

static func _fields(value: Variant, fields: Array) -> bool:
	if typeof(value) != TYPE_DICTIONARY or value.size() != fields.size(): return false
	for key in value:
		if typeof(key) != TYPE_STRING or key not in fields: return false
	return true

static func _ints(value: Variant, minima: Dictionary) -> bool:
	if not _fields(value, minima.keys()): return false
	for key in minima:
		if typeof(value[key]) != TYPE_INT or value[key] < minima[key]: return false
	return true

static func success(value: Variant) -> Dictionary:
	return {"ok":true,"value":value,"issues":[]}

static func failure(code: String, message: String, path: String = "") -> Dictionary:
	return {"ok":false,"value":null,"issues":[{"code":code,"stage":"AUTHORING","path":path,"message":message,"source_refs":[],"upstream":[]}]}

# Hashes here are declarations. ToolWire checks canonical execution identity;
# D2/D6 must verify actual bytes, links and cross-artifact capture/publication.
const SCHEMA_VERSIONS = {"wire":"foundationtoolwire.v1","authoring":"levelauthoring.v1","intent_authoring":"puzzleintentauthoring.v1","snapshot":"authoringsnapshot.v1","source_map":"authoringsourcemap.v1","report":"levelacceptance.v1","source_manifest":"authoringsourcemanifest.v1","input_manifest":"authoringinputmanifest.v1","archive_manifest":"authoringarchivemanifest.v1","stage_result":"foundationtoolwire.v1","worker_message":WORKER_PROTOCOL_VERSION}
const CONTRACT_VERSIONS = {"schema_version":1,"contract_version":"foundation.contract.v1","contract_revision":"v1.1","orientation_version":"cube24.v1","rule_version":"foundation.rules.v1","execution_version":"foundation.execution.v1","analysis_version":"foundation.analysis.v1","intent_version":"puzzleintent.v1","trace_version":"solutiontrace.v1"}
const IDENTITY_FIELDS = ["editor_instance_id","run_id","generation","level_ref","snapshot_id","source_fingerprint","policy_digest","execution_digest","versions"]
const ARTIFACT_FORMATS = ["rawbytes.v1","authoringpolicy.v1","foundationversions.v1","authoringrun.v1","foundationtoolwire.v1","levelauthoring.v1","puzzleintentauthoring.v1","authoringsnapshot.v1","authoringsourcemap.v1","levelacceptance.v1","authoringsourcemanifest.v1","authoringinputmanifest.v1","authoringarchivemanifest.v1","foundation.contract.v1","puzzleintent.v1","solutiontrace.v1","levelcanonical.v1"]

## Version-only check is deliberately not a certificate for a complete message.
static func validate_worker_version(message: Variant) -> Dictionary:
	if typeof(message) != TYPE_DICTIONARY or not message.has("protocol_version") or typeof(message.protocol_version) != TYPE_STRING or message.protocol_version != WORKER_PROTOCOL_VERSION:
		return failure("WIRE_SCHEMA_INVALID", "Missing or unsupported protocol_version", "protocol_version")
	return success(message.protocol_version)

static func _worker_message(value: Variant) -> Dictionary:
	var version := validate_worker_version(value)
	if not version.ok: return version
	if not _fields(value,["protocol_version","identity","sequence","kind","stage_id","payload_ref_or_inline"]):
		return failure("WIRE_SCHEMA_INVALID", "Closed WorkerMessage fields required")
	if not identity_shape(value.identity) or typeof(value.sequence) != TYPE_INT or not _string(value.kind) or value.kind not in WORKER_KINDS or not _string(value.stage_id,true):
		return failure("WIRE_SCHEMA_INVALID", "Invalid WorkerMessage common fields")
	# No sequence lower bound or non-stage sentinel is frozen. No payload is
	# accepted for these branches, including null; D4 must freeze them first.
	if value.kind != "STAGE_RESULT":
		return failure("DEPENDENCY_PENDING", "WORKER_MESSAGE_" + value.kind + "_PAYLOAD_SCHEMA")
	if value.stage_id not in STAGES or not _stage_ref(value.payload_ref_or_inline,"artifacts/stages/" + value.stage_id + "/stage_result.wire","foundationtoolwire.v1") or not _portable_tree(value):
		return failure("WIRE_SCHEMA_INVALID", "STAGE_RESULT requires its exact run-relative ArtifactRef")
	return success(value)

static func _stage_ref(value: Variant, path: String, version: String) -> bool:
	return _artifact(value) and value.relative_path == path and value.format_version == version

static func _stage_result(value: Variant) -> Dictionary:
	if not _fields(value,["run_identity","stage_record"]) or not identity_shape(value.run_identity) or not _portable_tree(value):
		return failure("WIRE_SCHEMA_INVALID", "Invalid stage_result identity, fields or paths")
	var stage: Variant = value.stage_record
	if not _fields(stage,STORED_STAGE_FIELDS): return failure("WIRE_SCHEMA_INVALID", "Closed StoredStageRecord fields required")
	for field in ["stage_id","owner","module_ref","applicability","execution","reason","started_at","finished_at"]:
		if not _string(stage[field],field == "reason"): return failure("WIRE_SCHEMA_INVALID", "Invalid StoredStageRecord type",field)
	if stage.stage_id not in STAGES: return failure("WIRE_SCHEMA_INVALID", "Unknown stage_id")
	if stage.execution not in ["COMPLETED","INCOMPLETE","ERROR","CANCELLED"] or (stage.execution == "COMPLETED" and stage.native_result == null):
		return failure("WIRE_SCHEMA_INVALID", "Only executed terminal stages may be stored")
	if (stage.execution == "COMPLETED") != stage.reason.is_empty(): return failure("WIRE_SCHEMA_INVALID", "Terminal reason mismatch")
	if not _utc_milliseconds(stage.started_at) or not _utc_milliseconds(stage.finished_at) or stage.finished_at < stage.started_at:
		return failure("WIRE_SCHEMA_INVALID", "Invalid stage timestamps")
	if stage.stage_id != "BAKE": return failure("DEPENDENCY_PENDING", "STAGE_RESULT_" + stage.stage_id + "_STORAGE_SCHEMA")
	return _bake_storage(value)

static func _bake_storage(value: Dictionary) -> Dictionary:
	var stage: Dictionary = value.stage_record
	var identity: Dictionary = value.run_identity
	if stage.owner != "4A" or stage.module_ref != "res://foundation/authoring/authoring_adapter.gd" or stage.applicability != "APPLICABLE":
		return failure("WIRE_SCHEMA_INVALID", "Invalid BAKE owner, module or applicability")
	var module_found := false
	for module in identity.versions.modules:
		if module.path == stage.module_ref: module_found = true
	if not module_found: return failure("WIRE_SCHEMA_INVALID", "BAKE module absent from execution versions")
	if not _fields(stage.input_refs,["input_manifest","authoring_payload"]) or not _stage_ref(stage.input_refs.input_manifest,"input.ready","authoringinputmanifest.v1"):
		return failure("WIRE_SCHEMA_INVALID", "Invalid BAKE input references")
	if not _artifact(stage.input_refs.authoring_payload) or stage.input_refs.authoring_payload.format_version != "levelauthoring.v1" or not stage.input_refs.authoring_payload.relative_path.begins_with("input/"):
		return failure("WIRE_SCHEMA_INVALID", "Invalid BAKE authoring reference")
	if not _ints(stage.actual_policy,{"max_configurations":1,"max_checks":1}) or not _ints(stage.actual_budget,{"max_configurations":1,"max_checks":1}) or stage.actual_budget != stage.actual_policy:
		return failure("WIRE_SCHEMA_INVALID", "Invalid BAKE policy/budget")
	if not _fields(stage.evidence_refs,["canonical"]) or typeof(stage.warnings) != TYPE_ARRAY or not stage.warnings.is_empty():
		return failure("WIRE_SCHEMA_INVALID", "Invalid BAKE evidence or unsupported warnings")
	var native: Variant = stage.native_result
	if native == null:
		if stage.evidence_refs.canonical != null: return failure("WIRE_SCHEMA_INVALID", "No return cannot reference canonical")
		return success(value)
	if not _fields(native,["ok","level","issues","validation","source_map","bake_provenance"]) or typeof(native.ok) != TYPE_BOOL:
		return failure("WIRE_SCHEMA_INVALID", "Unknown BAKE native_result branch or fields")
	# The real failed/incomplete Baker return has no approved storage branch.
	# Never erase it or manufacture a successful/null result to encode it.
	if not native.ok: return failure("DEPENDENCY_PENDING", "BAKE_FAILURE_STORAGE_SCHEMA")
	if not _stage_ref(native.level,"artifacts/stages/BAKE/canonical.level","levelcanonical.v1") or not _stage_ref(stage.evidence_refs.canonical,"artifacts/stages/BAKE/canonical.level","levelcanonical.v1") or native.level != stage.evidence_refs.canonical:
		return failure("WIRE_SCHEMA_INVALID", "BAKE canonical references differ or are invalid")
	if typeof(native.issues) != TYPE_ARRAY or not native.issues.is_empty() or not _fields(native.validation,["status","issues","configurations_checked","checks_performed"]):
		return failure("WIRE_SCHEMA_INVALID", "Invalid successful BAKE validation")
	var validation: Dictionary = native.validation
	if typeof(validation.status) != TYPE_INT or validation.status != 0 or typeof(validation.issues) != TYPE_ARRAY or not validation.issues.is_empty() or typeof(validation.configurations_checked) != TYPE_INT or validation.configurations_checked < 0 or typeof(validation.checks_performed) != TYPE_INT or validation.checks_performed < 0:
		return failure("WIRE_SCHEMA_INVALID", "Invalid successful BAKE validation values")
	if not _fields(native.bake_provenance,["run_id","snapshot_id","source_fingerprint"]): return failure("WIRE_SCHEMA_INVALID", "Invalid BakeProvenance")
	for key in native.bake_provenance:
		if typeof(native.bake_provenance[key]) != TYPE_STRING or native.bake_provenance[key] != identity[key]: return failure("WIRE_SCHEMA_INVALID", "BakeProvenance identity mismatch")
	if not _stored_source_map(native.source_map,identity): return failure("WIRE_SCHEMA_INVALID", "Invalid stored SourceMap")
	return success(value)

static func _stored_source_map(value: Variant, identity: Dictionary) -> bool:
	if not _fields(value,["map_version","snapshot_id","source_fingerprint","level_hash","entries"]): return false
	if not _string(value.map_version) or value.map_version != "authoringsourcemap.v1" or not _uuid(value.snapshot_id) or not _hex(value.source_fingerprint,64) or not _hex(value.level_hash,64): return false
	if value.snapshot_id != identity.snapshot_id or value.source_fingerprint != identity.source_fingerprint or typeof(value.entries) != TYPE_ARRAY: return false
	for entry in value.entries:
		if not _fields(entry,["authoring_id","document_uri","node_path_at_capture","resource_uid","resource_subpath","local_face","entity_kind","entity_id","field","reader_path","canonical_path"]): return false
		if not _uuid(entry.authoring_id) or not _stage_source_uri(entry.document_uri) or not _string(entry.entity_kind) or not _string(entry.field,true): return false
		for field in ["node_path_at_capture","resource_uid","resource_subpath","reader_path","canonical_path"]:
			if entry[field] != null and not _string(entry[field],true): return false
		if entry.entity_id != null and typeof(entry.entity_id) != TYPE_STRING_NAME: return false
		if entry.local_face != null and (typeof(entry.local_face) != TYPE_INT or entry.local_face not in range(6)): return false
	return true

static func _stage_source_uri(value: Variant) -> bool:
	return _string(value) and (value.begins_with("res://") or value.begins_with("editor://")) and _source_uri(value)

static func _utc_milliseconds(value: String) -> bool:
	var pattern := RegEx.new()
	pattern.compile("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\\.[0-9]{3}Z$")
	if pattern.search(value) == null: return false
	var year := value.substr(0,4).to_int()
	var month := value.substr(5,2).to_int()
	var day := value.substr(8,2).to_int()
	if month < 1 or month > 12: return false
	var days := [31,29 if year % 4 == 0 and (year % 100 != 0 or year % 400 == 0) else 28,31,30,31,30,31,31,30,31,30,31]
	return day >= 1 and day <= days[month-1] and value.substr(11,2).to_int() < 24 and value.substr(14,2).to_int() < 60 and value.substr(17,2).to_int() < 60

## Scan every key and value, including diagnostic text and StringName IDs.
## This does not authorize filesystem reads; consumers still verify containment,
## links, actual artifacts, source mode, canonical content and sealed policy.
static func _portable_tree(value: Variant, depth: int = 1) -> bool:
	if depth > 64: return false
	if typeof(value) == TYPE_DICTIONARY:
		for key in value:
			if not _portable_tree(key,depth+1) or not _portable_tree(value[key],depth+1): return false
	elif typeof(value) == TYPE_ARRAY:
		for item in value:
			if not _portable_tree(item,depth+1): return false
	elif typeof(value) in [TYPE_STRING,TYPE_STRING_NAME]:
		var text := String(value)
		var uris := RegEx.new()
		uris.compile("(?:res|editor)://[^\\s\"']+")
		for found in uris.search_all(text):
			if not _stage_source_uri(found.get_string()): return false
		# Validate then mask logical URIs before identifying filesystem roots.
		# Punctuation (including Unicode punctuation) is a path boundary too.
		text = uris.sub(text,"logical_uri",true)
		var absolute := RegEx.new()
		absolute.compile("(?i)([a-z]:[/\\\\]|file://|\\\\\\\\|(^|[^\\p{L}\\p{N}_./-])[/\\\\]|(^|[/\\\\])\\.\\.([/\\\\]|$))")
		if absolute.search(text) != null: return false
	return true

static func _string(value: Variant, allow_empty: bool = false) -> bool:
	return typeof(value) == TYPE_STRING and (allow_empty or not value.is_empty())

static func _hex(value: Variant, length: int) -> bool:
	if not _string(value) or value.length() != length: return false
	for c in value:
		if c not in "0123456789abcdef": return false
	return true

static func _uuid(value: Variant) -> bool:
	if not _string(value) or value.length() != 36: return false
	for i in 36:
		if i in [8,13,18,23]:
			if value[i] != "-": return false
		elif value[i] not in "0123456789abcdef": return false
	return true

static func _fixed(value: Variant, expected: Dictionary) -> bool:
	if not _fields(value, expected.keys()): return false
	for key in expected:
		if typeof(value[key]) != typeof(expected[key]) or value[key] != expected[key]: return false
	return true

static func _package_path(value: Variant) -> bool:
	if not _string(value) or value.begins_with("/"): return false
	for c in value:
		if c.unicode_at(0) < 32 or c in ["\\",":","*","?",'"',"<",">","|"]: return false
	for part in value.split("/",true):
		if part in ["",".",".."] or part.ends_with(".") or part.ends_with(" "): return false
		var stem: String = part.get_slice(".",0).to_upper()
		if stem in ["CON","PRN","AUX","NUL","COM1","COM2","COM3","COM4","COM5","COM6","COM7","COM8","COM9","LPT1","LPT2","LPT3","LPT4","LPT5","LPT6","LPT7","LPT8","LPT9"]: return false
	return true

static func _resource_path(value: Variant) -> bool:
	return _string(value) and value.begins_with("res://") and _package_path(value.substr(6))

static func _source_uri(value: Variant) -> bool:
	if _resource_path(value): return true
	if not _string(value): return false
	if value.begins_with("editor://"):
		var parts: PackedStringArray = value.substr(9).split("/",true)
		return parts.size() == 2 and _uuid(parts[0]) and _uuid(parts[1])
	# A file URI is not a raw filesystem string. Require an absolute drive
	# when present and canonical component escapes before accepting identity.
	if not value.begins_with("file:///"): return false
	var path: String = value.substr(8)
	if path.length() > 1 and path[1] == ":":
		if path.length() < 4 or path[0].to_lower() not in "abcdefghijklmnopqrstuvwxyz" or path[2] != "/": return false
		path = path.substr(3)
	for component in path.split("/",true):
		if not _file_uri_component(component): return false
	return true

static func _file_uri_component(component: String) -> bool:
	var bytes := PackedByteArray()
	var i := 0
	while i < component.length():
		if component[i] == "%":
			if i + 2 >= component.length(): return false
			var hex: String = component.substr(i+1,2)
			if not _hex(hex.to_lower(),2): return false
			bytes.append(hex.hex_to_int())
			i += 3
		else:
			var code: int = component.unicode_at(i)
			if code > 127: return false
			bytes.append(code)
			i += 1
	# Validate escaped UTF-8 before asking Godot to decode: malformed byte
	# sequences must fail quietly rather than emit decoder errors or narrow.
	i = 0
	while i < bytes.size():
		var lead: int = bytes[i]
		if lead < 128:
			i += 1
			continue
		var count := 0
		var cp := 0
		if lead >= 0xc2 and lead <= 0xdf: count = 2; cp = lead & 31
		elif lead >= 0xe0 and lead <= 0xef: count = 3; cp = lead & 15
		elif lead >= 0xf0 and lead <= 0xf4: count = 4; cp = lead & 7
		else: return false
		if i + count > bytes.size(): return false
		for offset in range(1,count):
			var part: int = bytes[i+offset]
			if part < 0x80 or part > 0xbf: return false
			cp = (cp << 6) | (part & 63)
		if (count == 3 and cp < 0x800) or (count == 4 and cp < 0x10000) or cp > 0x10ffff or (cp >= 0xd800 and cp <= 0xdfff): return false
		i += count
	if bytes.has(0): return false
	var decoded := bytes.get_string_from_utf8()
	return not decoded.contains("/") and _package_path(decoded) and decoded.uri_encode() == component

static func _absolute_path(value: Variant) -> bool:
	if not _string(value): return false
	var path: String = value.replace("\\","/")
	if path.begins_with("//"): return _package_path(path.substr(2))
	if path.begins_with("/"): return _package_path(path.substr(1))
	return path.length() > 3 and path[0].to_lower() in "abcdefghijklmnopqrstuvwxyz" and path.substr(1,2) == ":/" and _package_path(path.substr(3))

static func _ordered_text(previous: String, current: String) -> bool:
	return previous.is_empty() or previous.to_utf8_buffer().hex_encode() < current.to_utf8_buffer().hex_encode()

static func _versions(value: Variant) -> bool:
	if not _fields(value,["record_version","tool_version","schemas","contracts","engine","modules","configuration"]): return false
	if not _fixed({"record_version":value.record_version,"tool_version":value.tool_version},{"record_version":"foundationversions.v1","tool_version":"authoringrun.v1"}): return false
	if not _fixed(value.schemas,SCHEMA_VERSIONS) or not _fixed(value.contracts,CONTRACT_VERSIONS): return false
	if not _fields(value.engine,["version","executable_sha256"]) or not _string(value.engine.version) or not _hex(value.engine.executable_sha256,64): return false
	var known_versions: Array = SCHEMA_VERSIONS.values() + CONTRACT_VERSIONS.values() + ["foundationversions.v1","authoringrun.v1"]
	var seen := {}
	for entries in [value.modules,value.configuration]:
		if typeof(entries) != TYPE_ARRAY or entries.is_empty(): return false
		var previous := ""
		for file in entries:
			if not _fields(file,["path","sha256","version"]) or not _resource_path(file.path) or not _hex(file.sha256,64): return false
			if file.version != null and (not _string(file.version) or file.version not in known_versions): return false
			if not _ordered_text(previous,file.path) or seen.has(file.path.to_lower()): return false
			seen[file.path.to_lower()] = true
			previous = file.path
	var project_found := false
	for file in value.configuration:
		if file.path == "res://project.godot": project_found = true
	return project_found

static func _level_ref(value: Variant) -> bool:
	return _fields(value,["level_authoring_id","level_id","root_source_uri"]) and _uuid(value.level_authoring_id) and typeof(value.level_id) == TYPE_STRING_NAME and not String(value.level_id).is_empty() and _source_uri(value.root_source_uri)

static func identity_shape(value: Variant) -> bool:
	if not _fields(value,IDENTITY_FIELDS): return false
	if not _uuid(value.editor_instance_id) or not _uuid(value.run_id) or not _uuid(value.snapshot_id): return false
	if typeof(value.generation) != TYPE_INT or value.generation < 0 or not _level_ref(value.level_ref): return false
	for key in ["source_fingerprint","policy_digest","execution_digest"]:
		if not _hex(value[key],64): return false
	return _versions(value.versions)

static func _source_manifest(value: Variant) -> bool:
	if not _fields(value,["authoring_payload_digest","dependencies","source_locations"]) or not _hex(value.authoring_payload_digest,64): return false
	if typeof(value.dependencies) != TYPE_ARRAY or typeof(value.source_locations) != TYPE_ARRAY: return false
	var previous := ""
	var sources := {}
	var source_cases := {}
	for dep in value.dependencies:
		if not _fields(dep,["source_uri","resource_uid","kind","origin","content_digest","disk_digest","declared_version","authoring_ids"]): return false
		if not _source_uri(dep.source_uri) or not _ordered_text(previous,dep.source_uri) or source_cases.has(dep.source_uri.to_lower()): return false
		previous = dep.source_uri
		source_cases[dep.source_uri.to_lower()] = true
		if dep.resource_uid != null and not _string(dep.resource_uid): return false
		if not _string(dep.kind) or dep.kind not in ["SCENE","RESOURCE"] or not _string(dep.origin) or dep.origin not in ["SAVED","EDITOR_BUFFER"]: return false
		if not _hex(dep.content_digest,64) or dep.content_digest != value.authoring_payload_digest: return false
		if dep.disk_digest != null and not _hex(dep.disk_digest,64): return false
		if dep.origin == "SAVED" and (dep.disk_digest == null or dep.source_uri.begins_with("editor://")): return false
		if not _string(dep.declared_version) or dep.declared_version not in ["levelauthoring.v1","puzzleintentauthoring.v1"] or (dep.kind == "SCENE" and dep.declared_version != "levelauthoring.v1"): return false
		if typeof(dep.authoring_ids) != TYPE_ARRAY or dep.authoring_ids.is_empty(): return false
		var previous_id := ""
		for id in dep.authoring_ids:
			if not _uuid(id) or not _ordered_text(previous_id,id): return false
			previous_id = id
		sources[dep.source_uri] = dep.authoring_ids
	var prior: Array = []
	for location in value.source_locations:
		if not _fields(location,["document_uri","authoring_id","node_path","label"]): return false
		if not _source_uri(location.document_uri) or not _uuid(location.authoring_id) or not _string(location.label,true): return false
		if location.node_path != null and not _string(location.node_path,true): return false
		if not sources.has(location.document_uri) or location.authoring_id not in sources[location.document_uri]: return false
		var tuple: Array = [location.document_uri,location.authoring_id,location.node_path,location.label]
		if not prior.is_empty() and not _tuple_less(prior,tuple): return false
		prior = tuple
	return true

static func _tuple_less(a: Array, b: Array) -> bool:
	for i in a.size():
		if a[i] == b[i]: continue
		if a[i] == null: return true
		if b[i] == null: return false
		return _ordered_text(a[i],b[i])
	return false

static func _artifact(value: Variant) -> bool:
	return _fields(value,["relative_path","byte_length","sha256","format_version"]) and _package_path(value.relative_path) and typeof(value.byte_length) == TYPE_INT and value.byte_length >= 0 and _hex(value.sha256,64) and _string(value.format_version) and value.format_version in ARTIFACT_FORMATS

static func _attachments(value: Variant, forbidden_path: String) -> bool:
	if typeof(value) != TYPE_ARRAY: return false
	var previous := ""
	var seen := {}
	for artifact in value:
		if not _artifact(artifact) or artifact.relative_path.to_lower() == forbidden_path: return false
		if not _ordered_text(previous,artifact.relative_path) or seen.has(artifact.relative_path.to_lower()): return false
		seen[artifact.relative_path.to_lower()] = true
		previous = artifact.relative_path
	return true

static func _has_ref(attachments: Array, ref: Dictionary) -> bool:
	for artifact in attachments:
		if artifact == ref: return true
	return false

static func _input_manifest(value: Variant) -> bool:
	if not _fields(value,["manifest_version","identity","input_mode","source_manifest","authoring_payload","execution_policy","attachments","source_metadata"]): return false
	if not _string(value.manifest_version) or value.manifest_version != "authoringinputmanifest.v1" or not identity_shape(value.identity): return false
	if not _string(value.input_mode) or value.input_mode not in ["ACCEPT_SAVED","ANALYZE_CURRENT"]: return false
	if not _attachments(value.attachments,"input.ready"): return false
	for field in ["source_manifest","authoring_payload","execution_policy"]:
		if not _artifact(value[field]) or not _has_ref(value.attachments,value[field]): return false
	if value.source_manifest.format_version != "authoringsourcemanifest.v1" or value.source_manifest.sha256 != value.identity.source_fingerprint: return false
	if value.authoring_payload.format_version != "levelauthoring.v1": return false
	if value.execution_policy.format_version != "authoringpolicy.v1" or value.execution_policy.sha256 != value.identity.policy_digest: return false
	if not _fields(value.source_metadata,["git_head","engine_path"]): return false
	if value.source_metadata.git_head != null and not _hex(value.source_metadata.git_head,40): return false
	if value.source_metadata.engine_path != null and not _absolute_path(value.source_metadata.engine_path): return false
	for file in value.identity.versions.modules + value.identity.versions.configuration:
		var found := false
		for artifact in value.attachments:
			if artifact.relative_path == "input/execution/" + file.sha256 + ".blob" and artifact.sha256 == file.sha256 and artifact.format_version == "rawbytes.v1": found = true
		if not found: return false
	return true

static func _archive_manifest(value: Variant) -> bool:
	if not _fields(value,["manifest_version","identity","input_manifest","report","attachments"]): return false
	if not _string(value.manifest_version) or value.manifest_version != "authoringarchivemanifest.v1" or not identity_shape(value.identity): return false
	if not _attachments(value.attachments,"manifest.wire"): return false
	for field in ["input_manifest","report"]:
		if not _artifact(value[field]) or not _has_ref(value.attachments,value[field]): return false
	return value.input_manifest.format_version == "authoringinputmanifest.v1" and value.report.format_version == "levelacceptance.v1"
