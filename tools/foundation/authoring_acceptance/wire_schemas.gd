extends RefCounted
## Closed D-owned records. Unavailable record schemas fail closed, never use a
## generic Dictionary fallback. A owns authoring/source_map registration.

const KINDS = ["source_intent","authoring","snapshot","source_map","intent","trace","state_inspection","graph_archive","quality_result","stage_result","report","worker_message","versions","source_manifest","input_manifest","archive_manifest","policy"]
const STAGES = ["AUTHORING","BAKE","INTENT_BIND","INTENT_VALIDATE","ORIGINAL_GRAPH","SOFTLOCK","ABLATION","TRACE_SEMANTICS","MILESTONES","GRAPHICAL_REPLAY","MANUAL_RUNTIME","ARCHIVE"]
const ACCEPT_STAGES = ["AUTHORING","BAKE","INTENT_BIND","INTENT_VALIDATE","ORIGINAL_GRAPH","SOFTLOCK","ABLATION","TRACE_SEMANTICS","MILESTONES","GRAPHICAL_REPLAY","ARCHIVE"]
const POLICY_FIELDS = ["entry_kind","stages","bake_options","search_mode","search_budget","softlock_budget","replay_options","stage_deadline_ms","lease_interval_ms","lease_timeout_ms","max_wire_bytes","max_wire_depth"]
const WORKER_PROTOCOL_VERSION = "foundationworkeripc.v1"
const WORKER_KINDS = ["HELLO","STAGE_STARTED","STAGE_RESULT","HEARTBEAT","EXIT","ERROR","CANCEL","LEASE"]
const STORED_STAGE_FIELDS = ["stage_id","owner","module_ref","applicability","execution","reason","input_refs","actual_policy","actual_budget","native_result","evidence_refs","warnings","started_at","finished_at"]

static func validate(kind: String, value: Variant) -> Dictionary:
	if kind not in KINDS: return failure("WIRE_SCHEMA_INVALID", "Unknown record kind")
	if kind == "source_intent": return _source_intent(value)
	if kind == "worker_message": return _worker_message(value)
	if kind == "stage_result": return _stage_result(value)
	if kind in ["intent","trace","graph_archive"]:
		var valid := _portable_tree(value) and (_ss_intent(value) if kind == "intent" else (_ss_trace(value) if kind == "trace" else _ss_graph(value)))
		return success(value) if valid else failure("WIRE_SCHEMA_INVALID","Invalid closed " + kind)
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
const SCHEMA_VERSIONS = {"stage_storage":"foundationstagestorage.v1","graph_archive":"stategraph.v1","intent":"puzzleintent.v1","trace":"solutiontrace.v1","source_intent":"foundationtoolwire.v1","wire":"foundationtoolwire.v1","authoring":"levelauthoring.v1","intent_authoring":"puzzleintentauthoring.v1","snapshot":"authoringsnapshot.v1","source_map":"authoringsourcemap.v1","report":"levelacceptance.v1","source_manifest":"authoringsourcemanifest.v1","input_manifest":"authoringinputmanifest.v1","archive_manifest":"authoringarchivemanifest.v1","stage_result":"foundationtoolwire.v1","worker_message":WORKER_PROTOCOL_VERSION}
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
	if not identity_shape(value.identity) or not valid_worker_sequence(value.sequence) or not _string(value.kind) or value.kind not in WORKER_KINDS or not _string(value.stage_id,true):
		return failure("WIRE_SCHEMA_INVALID", "Invalid WorkerMessage common fields")
	if value.kind != "STAGE_RESULT":
		if not _inline_payload(value): return failure("WIRE_SCHEMA_INVALID", "Invalid closed inline payload or stage relation")
		return success(value)
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
	if stage.stage_id != "BAKE": return _storage_stage(value)
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
	# Preserve the actual failure object under the approved storage profile.
	if not native.ok: return _bake_failure_storage(value)
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

# Stateless contract data. D4 owns cursors, process state, publication and effects.
const WORKER_SEQUENCE_FIRST = 0
const WORKER_SEQUENCE_LAST_INITIAL = -1
const WORKER_SEQUENCE_MAX = 9223372036854775807
const LEASE_VALID_FOR_MS = 30000
const LEASE_RENEW_INTERVAL_MS = 1000
const WORKER_ROLES = ["HEADLESS","GRAPHICAL"]
const HEARTBEAT_PHASES = ["IDLE","CALLING","CANCELLING","FINALIZING"]
const EXIT_REASONS = ["FINISHED","CANCELLED","FAILED","LEASE_EXPIRED"]
const WORKER_ERROR_CODES = ["EXECUTION_IDENTITY_MISMATCH","IPC_PROTOCOL_ERROR","STAGE_CALL_ERROR","STORAGE_ERROR","RESOURCE_RELEASE_ERROR"]
const CANCEL_REASONS = ["USER_CANCEL","PLUGIN_UNLOAD","EDITOR_SHUTDOWN","STAGE_TIMEOUT","PROTOCOL_ERROR"]
const WORKER_DIRECTIONS = {"PARENT_TO_WORKER":["CANCEL","LEASE"],"WORKER_TO_PARENT":["HELLO","STAGE_STARTED","STAGE_RESULT","HEARTBEAT","EXIT","ERROR"]}
const WORKER_FIRST_KINDS = {"PARENT_TO_WORKER":"LEASE","WORKER_TO_PARENT":"HELLO"}
const WORKER_PROTOCOL_ERROR = "IPC_PROTOCOL_ERROR"
const WORKER_PROTOCOL_ERROR_EFFECTS = {"advance_cursor":false,"stop_chain":true,"revoke_pass_eligibility":true}

static func valid_worker_sequence(value: Variant) -> bool:
	return typeof(value) == TYPE_INT and value >= WORKER_SEQUENCE_FIRST

static func _enum_string(value: Variant, allowed: Array) -> bool:
	return typeof(value) == TYPE_STRING and value in allowed

static func _inline_payload(message: Dictionary) -> bool:
	var p: Variant = message.payload_ref_or_inline
	var stage: String = message.stage_id
	match message.kind:
		"HELLO":
			return stage == "" and _fields(p,["launch_id","worker_role","engine"]) and _uuid(p.launch_id) and _enum_string(p.worker_role,WORKER_ROLES) and _fields(p.engine,["version","executable_sha256"]) and _string(p.engine.version) and _hex(p.engine.executable_sha256,64) and p.engine == message.identity.versions.engine
		"STAGE_STARTED":
			return stage in STAGES and _fields(p,["started_at"]) and typeof(p.started_at) == TYPE_STRING and _utc_milliseconds(p.started_at)
		"HEARTBEAT":
			if not _fields(p,["observed_at","phase"]) or typeof(p.observed_at) != TYPE_STRING or not _utc_milliseconds(p.observed_at) or not _enum_string(p.phase,HEARTBEAT_PHASES): return false
			if p.phase == "CALLING": return stage in STAGES
			if p.phase in ["IDLE","FINALIZING"]: return stage == ""
			return stage == "" or stage in STAGES
		"EXIT":
			if stage != "" or not _fields(p,["reason","exit_code","file_handles_closed","callbacks_disconnected","preview_resources_released"]) or not _enum_string(p.reason,EXIT_REASONS) or typeof(p.exit_code) != TYPE_INT: return false
			for field in ["file_handles_closed","callbacks_disconnected","preview_resources_released"]:
				if typeof(p[field]) != TYPE_BOOL or not p[field]: return false
			return p.exit_code == (0 if p.reason in ["FINISHED","CANCELLED"] else 1)
		"ERROR":
			return (stage == "" or stage in STAGES) and _fields(p,["code","message"]) and _enum_string(p.code,WORKER_ERROR_CODES) and typeof(p.message) == TYPE_STRING and not p.message.strip_edges().is_empty() and (p.code != "STAGE_CALL_ERROR" or stage in STAGES)
		"CANCEL":
			return stage == "" and _fields(p,["reason"]) and _enum_string(p.reason,CANCEL_REASONS)
		"LEASE":
			return stage == "" and _fields(p,["issued_at","valid_for_ms"]) and typeof(p.issued_at) == TYPE_STRING and _utc_milliseconds(p.issued_at) and typeof(p.valid_for_ms) == TYPE_INT and p.valid_for_ms == LEASE_VALID_FOR_MS
	return false

## Pure comparison against caller-owned context, never retains/advances a cursor.
## D4 must additionally verify identity, artifacts, lifecycle and actual process.
static func validate_worker_context(message: Variant, active_stage: Variant, direction: Variant, expected_sequence: Variant) -> Dictionary:
	var checked := _worker_message(message)
	if not checked.ok: return checked
	if typeof(active_stage) != TYPE_STRING or (active_stage != "" and active_stage not in STAGES) or typeof(direction) != TYPE_STRING or not WORKER_DIRECTIONS.has(direction) or not valid_worker_sequence(expected_sequence):
		return failure(WORKER_PROTOCOL_ERROR,"Invalid receive context")
	if message.kind not in WORKER_DIRECTIONS[direction]: return failure(WORKER_PROTOCOL_ERROR,"Wrong direction")
	if message.sequence != expected_sequence: return failure(WORKER_PROTOCOL_ERROR,"Duplicate" if message.sequence < expected_sequence else "Gap")
	if expected_sequence == WORKER_SEQUENCE_FIRST and message.kind != WORKER_FIRST_KINDS[direction]: return failure(WORKER_PROTOCOL_ERROR,"Invalid first message")
	if message.kind in ["HEARTBEAT","ERROR","STAGE_RESULT"] and message.stage_id != active_stage: return failure(WORKER_PROTOCOL_ERROR,"Active stage mismatch")
	if message.kind == "STAGE_STARTED" and active_stage != "": return failure(WORKER_PROTOCOL_ERROR,"Overlapping stage")
	return success(message)

static func _source_intent(value: Variant) -> Dictionary:
	var invalid := failure("WIRE_SCHEMA_INVALID","Invalid closed source_intent")
	if not _fields(value,["root_authoring_id","resources"]) or not _uuid(value.root_authoring_id) or typeof(value.resources) != TYPE_ARRAY: return invalid
	var schema = load("res://foundation/authoring/authoring_schema.gd")
	var resources := {}
	var previous := ""
	var semantic_ids := {}
	for entry in value.resources:
		if not _fields(entry,schema.RESOURCE_FIELDS) or not _enum_string(entry.kind,["INTENT","MILESTONE","BYPASS"]) or not schema.valid_uuid(entry.authoring_id) or typeof(entry.document_uri) != TYPE_STRING or (entry.resource_uid != null and typeof(entry.resource_uid) != TYPE_STRING) or not schema.fields_valid(entry.kind,entry.fields): return invalid
		# UUIDs are ASCII: lexical order is exactly UTF-8 byte order.
		if entry.authoring_id <= previous: return invalid
		previous = entry.authoring_id
		resources[entry.authoring_id] = entry
		var id_field: String = {"INTENT":"intent_id","MILESTONE":"milestone_id","BYPASS":"bypass_id"}[entry.kind]
		var semantic_id: String = entry.kind + ":" + String(entry.fields[id_field])
		if semantic_ids.has(semantic_id): return invalid
		semantic_ids[semantic_id] = true
	if not resources.has(value.root_authoring_id) or resources[value.root_authoring_id].kind != "INTENT": return invalid
	var reached := {value.root_authoring_id:true}
	var root: Dictionary = resources[value.root_authoring_id]
	for field in ["expected_milestones","forbidden_bypasses"]:
		var expected := "MILESTONE" if field == "expected_milestones" else "BYPASS"
		var seen := {}
		for ref in root.fields[field]:
			if not _fields(ref,["resource_ref"]) or not _uuid(ref.resource_ref) or not resources.has(ref.resource_ref) or resources[ref.resource_ref].kind != expected or seen.has(ref.resource_ref): return invalid
			seen[ref.resource_ref] = true
			reached[ref.resource_ref] = true
	if reached.size() != resources.size(): return invalid
	return success(value)

## Validate the entire captured authoring input before selecting its Level intent.
## Missing returns a null value, never a synthetic source_intent record or digest.
static func project_source_intent(payload: Variant) -> Dictionary:
	var checked := validate("authoring",payload)
	if not checked.ok: return checked
	var intent_ref: Variant = null
	for document in payload.documents:
		for record in document.records:
			if record.kind == "LEVEL" and record.authoring_id == payload.level_ref.level_authoring_id:
				intent_ref = record.fields.intent
	if intent_ref == null: return success(null)
	var resources := {}
	for entry in payload.resource_table: resources[entry.authoring_id] = entry
	var root: Dictionary = resources[intent_ref.resource_ref]
	var selected := {root.authoring_id:root}
	for field in ["expected_milestones","forbidden_bypasses"]:
		for ref in root.fields[field]: selected[ref.resource_ref] = resources[ref.resource_ref]
	var ids: Array = selected.keys()
	ids.sort()
	var entries: Array = []
	for id in ids: entries.append(selected[id].duplicate(true))
	return _source_intent({"root_authoring_id":root.authoring_id,"resources":entries})

# Approved foundationstagestorage.v1 storage profile. Native algorithms remain
# with their existing Owners; these checks validate representation and binding.
const STORAGE_OWNERS = {
	"AUTHORING":["4A","res://foundation/authoring/authoring_schema.gd"],
	"INTENT_BIND":["4A","res://foundation/authoring/intent_binder.gd"],
	"INTENT_VALIDATE":["3C","res://foundation/quality/intent/intent_validation.gd"],
	"ORIGINAL_GRAPH":["3A","res://foundation/solver/state_explorer.gd"],
	"SOFTLOCK":["3B","res://foundation/quality/softlock/softlock_analyzer.gd"],
	"ABLATION":["3C","res://foundation/quality/intent/ablation_analyzer.gd"],
	"TRACE_SEMANTICS":["3A","res://foundation/solver/solution_trace.gd"],
	"MILESTONES":["3C","res://foundation/quality/intent/milestone_analyzer.gd"],
	"GRAPHICAL_REPLAY":["3D","res://foundation/parity/trace_replayer.gd"]}

static func _storage_stage(value: Dictionary) -> Dictionary:
	var stage: Dictionary = value.stage_record
	var id: String = stage.stage_id
	if not STORAGE_OWNERS.has(id): return failure("DEPENDENCY_PENDING","STAGE_RESULT_" + id + "_STORAGE_SCHEMA")
	var invalid := failure("WIRE_SCHEMA_INVALID","Invalid closed " + id + " storage")
	if stage.owner != STORAGE_OWNERS[id][0] or stage.module_ref != STORAGE_OWNERS[id][1] or stage.applicability != "APPLICABLE": return invalid
	var found := false
	for module in value.run_identity.versions.modules:
		if module.path == stage.module_ref: found = true
	if not found or not _storage_inputs(id,stage.input_refs) or not _storage_budgets(stage) or not _ss_tool_issues(stage.warnings): return invalid
	for warning in stage.warnings:
		if warning.stage != id: return invalid
	if not _storage_evidence(stage): return invalid
	if stage.native_result == null: return success(value)
	if not _ss_native(id,stage.native_result) or not _storage_terminal(id,stage.native_result,stage.execution): return invalid
	if not _storage_native_binding(stage): return invalid
	return success(value)

static func _storage_inputs(id: String, refs: Variant) -> bool:
	var fields := ["input_manifest","authoring_payload"] if id in ["AUTHORING","INTENT_BIND"] else ["input_manifest","bake_result","canonical","level_hash","rule_version","initial_statekey"]
	match id:
		"INTENT_BIND": fields.append_array(["bake_result","canonical","source_intent_digest"])
		"INTENT_VALIDATE","ABLATION": fields.append("bound_intent")
		"SOFTLOCK": fields.append("original_graph_result")
		"TRACE_SEMANTICS","GRAPHICAL_REPLAY": fields.append_array(["selected_trace","selected_trace_digest"])
		"MILESTONES": fields.append_array(["bound_intent","selected_trace","selected_trace_digest"])
	if not _fields(refs,fields) or not _stage_ref(refs.input_manifest,"input.ready","authoringinputmanifest.v1"): return false
	if refs.has("authoring_payload"):
		if not _artifact(refs.authoring_payload) or refs.authoring_payload.format_version != "levelauthoring.v1" or not refs.authoring_payload.relative_path.begins_with("input/"): return false
	if refs.has("bake_result") and not _stage_ref(refs.bake_result,"artifacts/stages/BAKE/stage_result.wire","foundationtoolwire.v1"): return false
	if refs.has("canonical") and not _stage_ref(refs.canonical,"artifacts/stages/BAKE/canonical.level","levelcanonical.v1"): return false
	if refs.has("level_hash") and (not _hex(refs.level_hash,64) or not _string(refs.rule_version) or refs.rule_version != CONTRACT_VERSIONS.rule_version or not _string(refs.initial_statekey)): return false
	if refs.has("source_intent_digest") and not _hex(refs.source_intent_digest,64): return false
	if refs.has("bound_intent") and not _stage_ref(refs.bound_intent,"artifacts/stages/INTENT_BIND/bound_intent.wire","puzzleintent.v1"): return false
	if refs.has("original_graph_result") and not _stage_ref(refs.original_graph_result,"artifacts/stages/ORIGINAL_GRAPH/stage_result.wire","foundationtoolwire.v1"): return false
	if refs.has("selected_trace"):
		if not _stage_ref(refs.selected_trace,"artifacts/stages/ORIGINAL_GRAPH/selected_trace.wire","solutiontrace.v1") or not _hex(refs.selected_trace_digest,64) or refs.selected_trace_digest != refs.selected_trace.sha256: return false
	return true

static func _storage_budgets(stage: Dictionary) -> bool:
	var id: String = stage.stage_id
	var policy: Variant = stage.actual_policy
	var budget: Variant = stage.actual_budget
	if id in ["ORIGINAL_GRAPH","SOFTLOCK","ABLATION"]:
		if not _ss_policy(policy) or policy.filter_descriptor != {"filter_id":&"UNFILTERED","filter_version":"1","disabled_mechanics":[]} or policy.mode != (0 if id == "ABLATION" else 1): return false
		if id == "SOFTLOCK": return _ints(budget,{"max_nodes":1,"max_edges":0,"max_runtime_ms":0})
		return _ints(budget,{"max_states":1,"max_edges":0,"max_depth":-1,"max_runtime_ms":0,"max_action_evaluations":1})
	if id == "GRAPHICAL_REPLAY":
		if not _ints(policy,{"mode":1,"max_steps":0,"max_runtime_ms":0,"step_timeout_ms":1}) or policy.mode != 1: return false
		if not _fields(budget,["max_steps","max_runtime_ms","step_timeout_ms","validation_options"]): return false
		if not _ints(budget.validation_options,{"max_configurations":1,"max_checks":1}) or budget.validation_options != {"max_configurations":4096,"max_checks":100000}: return false
		for key in ["max_steps","max_runtime_ms","step_timeout_ms"]:
			if typeof(budget[key]) != TYPE_INT or budget[key] != policy[key]: return false
		return true
	return _fields(policy,[]) and _fields(budget,[])

static func _storage_evidence(stage: Dictionary) -> bool:
	var evidence: Variant = stage.evidence_refs
	var native: Variant = stage.native_result
	match stage.stage_id:
		"INTENT_BIND":
			if not _fields(evidence,["bound_intent"]): return false
			if native == null: return evidence.bound_intent == null
			if not _ss_native(stage.stage_id,native): return false
			return _stage_ref(evidence.bound_intent,"artifacts/stages/INTENT_BIND/bound_intent.wire","puzzleintent.v1") if native.ok else evidence.bound_intent == null
		"ORIGINAL_GRAPH":
			if not _fields(evidence,["graph_archive","selected_trace_ref"]): return false
			if native == null: return evidence.graph_archive == null and evidence.selected_trace_ref == null
			if not _ss_native(stage.stage_id,native) or evidence.graph_archive != native.graph_archive_ref: return false
			if native.solution_trace == null: return evidence.selected_trace_ref == null
			return _fields(evidence.selected_trace_ref,["trace","origin"]) and _string(evidence.selected_trace_ref.origin) and evidence.selected_trace_ref.origin == "ORIGINAL_GRAPH" and _stage_ref(evidence.selected_trace_ref.trace,"artifacts/stages/ORIGINAL_GRAPH/selected_trace.wire","solutiontrace.v1")
		"ABLATION":
			if not _fields(evidence,["baseline_graph_archive"]): return false
			if native == null: return evidence.baseline_graph_archive == null
			if not _ss_native(stage.stage_id,native): return false
			return evidence.baseline_graph_archive == (null if native.baseline == null else native.baseline.graph_archive_ref)
	return _fields(evidence,[])

# Only compatibility, never rewriting a domain status into a transport verdict.
static func _storage_terminal(id: String, native: Dictionary, execution: String) -> bool:
	var ordinary := "COMPLETED"
	match id:
		"AUTHORING","INTENT_BIND","INTENT_VALIDATE","TRACE_SEMANTICS": ordinary = "COMPLETED" if native.ok else "ERROR"
		"BAKE": ordinary = "COMPLETED" if native.ok else ("INCOMPLETE" if native.validation != null and native.validation.status == 2 else "ERROR")
		"ORIGINAL_GRAPH": ordinary = ["COMPLETED","COMPLETED","INCOMPLETE","ERROR"][native.status]
		"SOFTLOCK": ordinary = ["COMPLETED","INCOMPLETE","ERROR"][native.status]
		"ABLATION": ordinary = ["COMPLETED","INCOMPLETE","ERROR","COMPLETED"][native.status]
		"MILESTONES": ordinary = ["COMPLETED","COMPLETED","INCOMPLETE","ERROR"][native.status]
		"GRAPHICAL_REPLAY": ordinary = ["COMPLETED","COMPLETED","ERROR","INCOMPLETE"][native.status]
	if ordinary == "ERROR": return execution == "ERROR"
	if ordinary == "INCOMPLETE": return execution in ["INCOMPLETE","ERROR","CANCELLED"]
	return true # Actual tool overrides retain the completed native return.

static func _storage_native_binding(stage: Dictionary) -> bool:
	var native: Dictionary = stage.native_result
	var refs: Dictionary = stage.input_refs
	match stage.stage_id:
		"INTENT_BIND":
			return not native.ok or native.source_intent_digest == refs.source_intent_digest
		"ORIGINAL_GRAPH":
			return native.solution_trace == null or _storage_trace_binding(native.solution_trace,refs,stage.actual_policy)
		"SOFTLOCK":
			return native.initial_key.is_empty() or native.initial_key == refs.initial_statekey
		"ABLATION":
			if native.intent.level_hash != refs.level_hash or native.intent.rule_version != refs.rule_version: return false
			if native.baseline != null and native.baseline.solution_trace != null and not _storage_trace_binding(native.baseline.solution_trace,refs,stage.actual_policy): return false
			for item in native.ablations:
				if item.solution_trace_if_any != null and not _storage_trace_binding(item.solution_trace_if_any,refs,null): return false
	return true

static func _storage_trace_binding(trace: Dictionary, refs: Dictionary, policy: Variant) -> bool:
	return trace.level_hash == refs.level_hash and trace.rule_version == refs.rule_version and trace.initial_statekey == refs.initial_statekey and (policy == null or trace.policy_descriptor == policy)

static func _bake_failure_storage(value: Dictionary) -> Dictionary:
	var stage: Dictionary = value.stage_record
	var native: Dictionary = stage.native_result
	var invalid := failure("WIRE_SCHEMA_INVALID","Invalid BAKE failure storage")
	if native.level != null or native.bake_provenance != null or stage.evidence_refs.canonical != null: return invalid
	if typeof(native.issues) != TYPE_ARRAY or native.issues.is_empty(): return invalid
	for issue in native.issues:
		if not _ss_tool_issue(issue) and not _ss_validation_issue(issue): return invalid
	if native.validation != null:
		if not _ss_validation(native.validation) or native.validation.status not in [1,2] or native.validation.issues != native.issues: return invalid
	var source: Variant = native.source_map
	if not _fields(source,["map_version","snapshot_id","source_fingerprint","level_hash","entries"]): return invalid
	if not _string(source.map_version) or source.map_version != "authoringsourcemap.v1" or source.snapshot_id != value.run_identity.snapshot_id or source.source_fingerprint != value.run_identity.source_fingerprint or source.level_hash != null or typeof(source.entries) != TYPE_ARRAY: return invalid
	if not _uuid(source.snapshot_id) or not _hex(source.source_fingerprint,64): return invalid
	for entry in source.entries:
		if not _ss_source_entry(entry) or entry.canonical_path != null: return invalid
	if not _storage_terminal("BAKE",native,stage.execution): return invalid
	return success(value)
# Stage-storage projections validate shape only; original Owners retain semantics.
const SS_DATA = preload("res://foundation/contracts/contract_validation.gd")
const SS_SEARCH = preload("res://foundation/solver/search_records.gd")
const SS_CORE_TYPES = preload("res://foundation/contracts/foundation_types.gd")
const SS_SOLVER_TYPES = preload("res://foundation/solver/solver_types.gd")
const SS_RULE_TYPES = preload("res://foundation/rules/rule_types.gd")

static func _ss_enum(v: Variant, values: Array) -> bool:
	return typeof(v) == TYPE_INT and v in values

static func _ss_count(v: Variant) -> bool:
	return typeof(v) == TYPE_INT and v >= 0

static func _ss_core(v: Variant, descriptor: String) -> bool:
	var issues: Array[Dictionary] = []
	SS_DATA._check_value(v,descriptor,"",issues)
	return issues.is_empty()

static func _ss_state(v: Variant) -> bool:
	return _ss_core(v,"state") and v.world_orientations.size() == 2

static func _ss_policy(v: Variant) -> bool:
	return SS_SEARCH._valid_descriptor(v)

static func _ss_array(v: Variant, type: int) -> bool:
	if typeof(v) != TYPE_ARRAY: return false
	for item in v:
		if typeof(item) != type: return false
	return true

static func _ss_tags(v: Variant, allow_empty: bool = true) -> bool:
	if not _ss_array(v,TYPE_INT) or (not allow_empty and v.is_empty()): return false
	var previous := -1
	for item in v:
		if item not in range(8) or item <= previous: return false
		previous = item
	return true

static func _ss_intent(v: Variant) -> bool:
	if not _fields(v,["intent_version","intent_id","level_hash","rule_version","required_mechanics","optional_mechanics","expected_milestones","forbidden_bypasses"]) or not _portable_tree(v): return false
	if not _string(v.intent_version) or v.intent_version != "puzzleintent.v1" or not _ss_core(v.intent_id,"id") or not _hex(v.level_hash,64) or not _string(v.rule_version) or v.rule_version != "foundation.rules.v1": return false
	if not _ss_tags(v.required_mechanics) or not _ss_tags(v.optional_mechanics) or typeof(v.expected_milestones) != TYPE_ARRAY or typeof(v.forbidden_bypasses) != TYPE_ARRAY: return false
	for tag in v.required_mechanics:
		if tag in v.optional_mechanics: return false
	var seen := {}
	for item in v.expected_milestones:
		if not _fields(item,["milestone_id","required","predicate"]) or not _ss_core(item.milestone_id,"id") or typeof(item.required) != TYPE_BOOL or not _ss_predicate(item.predicate) or seen.has(item.milestone_id): return false
		seen[item.milestone_id] = true
	seen.clear()
	for item in v.forbidden_bypasses:
		if not _fields(item,["bypass_id","disabled_mechanics"]) or not _ss_core(item.bypass_id,"id") or not _ss_tags(item.disabled_mechanics,false) or seen.has(item.bypass_id): return false
		seen[item.bypass_id] = true
	return true

static func _ss_predicate(v: Variant) -> bool:
	if typeof(v) != TYPE_DICTIONARY or not v.has("kind") or not _ss_enum(v.kind,range(5)): return false
	match v.kind:
		0: return _fields(v,["kind","face_id"]) and _ss_core(v.face_id,"face_id")
		1: return _fields(v,["kind","layer"]) and _ss_enum(v.layer,[0,1])
		2: return _fields(v,["kind","light_state"]) and _ss_enum(v.light_state,[0,1])
		3: return _fields(v,["kind","mechanic"]) and _ss_enum(v.mechanic,range(8))
	return _fields(v,["kind"])

static func _ss_trace(v: Variant) -> bool:
	if not _fields(v,["trace_version","level_hash","rule_version","policy_descriptor","initial_state","initial_statekey","steps","goal_statekey","total_actions","shortest"]) or not _portable_tree(v): return false
	if not _string(v.trace_version) or v.trace_version != "solutiontrace.v1" or not _hex(v.level_hash,64) or not _string(v.rule_version) or v.rule_version != "foundation.rules.v1" or not _ss_policy(v.policy_descriptor): return false
	if not _ss_state(v.initial_state) or not _string(v.initial_statekey) or not _string(v.goal_statekey) or not _ss_count(v.total_actions) or typeof(v.shortest) != TYPE_BOOL or typeof(v.steps) != TYPE_ARRAY or v.total_actions != v.steps.size(): return false
	var final_key: String = v.initial_statekey
	for index in v.steps.size():
		var step: Variant = v.steps[index]
		if not _fields(step,["index","action","expected_state","resulting_statekey","global_kind"]): return false
		if not _ss_count(step.index) or step.index != index+1 or not _ss_core(step.action,"action") or not _ss_state(step.expected_state) or not _string(step.resulting_statekey) or not _ss_enum(step.global_kind,range(6)): return false
		final_key = step.resulting_statekey
	return final_key == v.goal_statekey

static func _ss_graph(v: Variant) -> bool:
	if not _fields(v,["graph_version","level_hash","rule_version","initial_key","policy_descriptor","nodes","edges","forward","reverse","complete","stop_reason"]) or not _portable_tree(v): return false
	if not _string(v.graph_version) or v.graph_version != "stategraph.v1" or not _hex(v.level_hash,64) or not _string(v.rule_version) or v.rule_version != "foundation.rules.v1" or not _string(v.initial_key) or not _ss_policy(v.policy_descriptor): return false
	if typeof(v.nodes) != TYPE_DICTIONARY or typeof(v.edges) != TYPE_ARRAY or typeof(v.forward) != TYPE_DICTIONARY or typeof(v.reverse) != TYPE_DICTIONARY or typeof(v.complete) != TYPE_BOOL or not _ss_enum(v.stop_reason,range(4)): return false
	if v.nodes.is_empty() or not v.nodes.has(v.initial_key) or v.forward.size() != v.nodes.size() or v.reverse.size() != v.nodes.size(): return false
	for key in v.nodes:
		var node: Variant = v.nodes[key]
		if not _string(key) or not _fields(node,["state_key","state","depth","is_goal","expanded","predecessor_edge"]): return false
		if not _string(node.state_key) or node.state_key != key or not _ss_state(node.state) or not _ss_count(node.depth) or typeof(node.is_goal) != TYPE_BOOL or typeof(node.expanded) != TYPE_BOOL: return false
		if node.predecessor_edge != null and (not _ss_count(node.predecessor_edge) or node.predecessor_edge >= v.edges.size()): return false
		if not v.forward.has(key) or not v.reverse.has(key): return false
		if not _ss_array(v.forward[key],TYPE_INT) or not _ss_array(v.reverse[key],TYPE_INT): return false
		for edge_id in v.forward[key]:
			if edge_id < 0 or edge_id >= v.edges.size(): return false
		for edge_id in v.reverse[key]:
			if edge_id < 0 or edge_id >= v.edges.size(): return false
	for index in v.edges.size():
		var edge: Variant = v.edges[index]
		if not _fields(edge,["edge_id","from_key","to_key","action","global_kind"]): return false
		if not _ss_count(edge.edge_id) or edge.edge_id != index or not _string(edge.from_key) or not _string(edge.to_key) or not v.nodes.has(edge.from_key) or not v.nodes.has(edge.to_key) or not _ss_core(edge.action,"action") or not _ss_enum(edge.global_kind,range(6)): return false
	# This archive is not a trusted graph: no reachability, Goal or StateKey calls.
	return true

static func _ss_diagnostic(v: Variant, depth: int = 1) -> bool:
	if depth > 64 or not _portable_tree(v): return false
	match typeof(v):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_STRING, TYPE_STRING_NAME, TYPE_VECTOR3I: return true
		TYPE_FLOAT: return is_finite(v)
		TYPE_VECTOR3: return v.is_finite()
		TYPE_BASIS: return v.is_finite()
		TYPE_TRANSFORM3D: return v.is_finite()
		TYPE_ARRAY:
			for item in v:
				if not _ss_diagnostic(item,depth+1): return false
			return true
		TYPE_DICTIONARY:
			for key in v:
				if typeof(key) not in [TYPE_STRING,TYPE_STRING_NAME,TYPE_INT] or not _ss_diagnostic(key,depth+1) or not _ss_diagnostic(v[key],depth+1): return false
			return true
	return false

static func _ss_validation_issue(v: Variant) -> bool:
	if not _fields(v,["code","severity","path","message","details","entity_ids"]): return false
	return _ss_enum(v.code,SS_CORE_TYPES.ValidationCode.values()) and _ss_enum(v.severity,[0,1,2]) and _string(v.path,true) and _string(v.message,true) and typeof(v.details) == TYPE_DICTIONARY and _ss_diagnostic(v.details) and _ss_array(v.entity_ids,TYPE_STRING_NAME)

static func _ss_analysis_issue(v: Variant) -> bool:
	if not _fields(v,["code","severity","path","message","details","upstream"]): return false
	if not _ss_enum(v.code,SS_SOLVER_TYPES.AnalysisCode.values()) or not _ss_enum(v.severity,[0,1,2]) or not _string(v.path,true) or not _string(v.message,true) or typeof(v.details) != TYPE_DICTIONARY or not _ss_diagnostic(v.details) or typeof(v.upstream) != TYPE_ARRAY: return false
	for item in v.upstream:
		if not _ss_validation_issue(item): return false
	return true

static func _ss_source_entry(v: Variant) -> bool:
	if not _fields(v,["authoring_id","document_uri","node_path_at_capture","resource_uid","resource_subpath","local_face","entity_kind","entity_id","field","reader_path","canonical_path"]): return false
	if not _uuid(v.authoring_id) or not _stage_source_uri(v.document_uri) or not _string(v.entity_kind) or not _string(v.field,true) or not _portable_tree(v): return false
	for field in ["node_path_at_capture","resource_uid","resource_subpath","reader_path","canonical_path"]:
		if v[field] != null and not _string(v[field],true): return false
	return (v.entity_id == null or typeof(v.entity_id) == TYPE_STRING_NAME) and (v.local_face == null or _ss_enum(v.local_face,range(6)))

static func _ss_tool_issue(v: Variant) -> bool:
	if not _fields(v,["code","stage","path","message","source_refs","upstream"]): return false
	if not _string(v.code) or not _string(v.stage) or not _string(v.path,true) or not _string(v.message,true) or typeof(v.source_refs) != TYPE_ARRAY or typeof(v.upstream) != TYPE_ARRAY or not _portable_tree(v): return false
	for item in v.source_refs:
		if not _ss_source_entry(item): return false
	for item in v.upstream:
		if not _ss_validation_issue(item) and not _ss_analysis_issue(item): return false
	return true

static func _ss_tool_issues(v: Variant) -> bool:
	if typeof(v) != TYPE_ARRAY: return false
	for item in v:
		if not _ss_tool_issue(item): return false
	return true

static func _ss_analysis_issues(v: Variant) -> bool:
	if typeof(v) != TYPE_ARRAY: return false
	for item in v:
		if not _ss_analysis_issue(item): return false
	return true

static func _ss_validation(v: Variant) -> bool:
	if not _fields(v,["status","issues","configurations_checked","checks_performed"]) or not _ss_enum(v.status,[0,1,2]) or not _ss_count(v.configurations_checked) or not _ss_count(v.checks_performed) or typeof(v.issues) != TYPE_ARRAY: return false
	for item in v.issues:
		if not _ss_validation_issue(item): return false
	return true

static func _ss_metrics(v: Variant) -> bool:
	if not _fields(v,["explored_states","visited_states","generated_edges","duplicate_states","goal_states","max_depth_reached","solution_length","action_evaluations","rejected_actions","no_op_actions","filtered_edges","safety_unproven_rejections","elapsed_ms","shortest_solution_count","shortest_solution_count_complete"]): return false
	for key in ["explored_states","visited_states","generated_edges","duplicate_states","goal_states","max_depth_reached","action_evaluations","rejected_actions","no_op_actions","filtered_edges","safety_unproven_rejections","elapsed_ms"]:
		if not _ss_count(v[key]): return false
	return (v.solution_length == null or _ss_count(v.solution_length)) and v.shortest_solution_count == null and typeof(v.shortest_solution_count_complete) == TYPE_BOOL and not v.shortest_solution_count_complete

static func _ss_search(v: Variant, graph_path: String) -> bool:
	if not _fields(v,["status","graph_archive_ref","solution_trace","metrics","budget_reason","issues","validation"]): return false
	if not _ss_enum(v.status,range(4)) or not _ss_enum(v.budget_reason,range(6)) or not _ss_metrics(v.metrics) or not _ss_analysis_issues(v.issues): return false
	if v.graph_archive_ref != null and not _stage_ref(v.graph_archive_ref,graph_path,"foundationtoolwire.v1"): return false
	if v.solution_trace != null and not _ss_trace(v.solution_trace): return false
	if v.validation != null and not _ss_validation(v.validation): return false
	if (v.status == 2) != (v.budget_reason != 0): return false
	if v.status == 0 and v.solution_trace == null: return false
	if v.status == 1 and (v.solution_trace != null or v.graph_archive_ref == null): return false
	if v.solution_trace == null: return v.metrics.solution_length == null
	return v.metrics.solution_length == v.solution_trace.total_actions

static func _ss_transition(v: Variant) -> bool:
	if not _fields(v,["status","previous_state","next_state","action","changed","rejection_code","issues","global_kind"]): return false
	if not _ss_state(v.previous_state) or not _ss_core(v.action,"action") or (v.next_state != null and not _ss_state(v.next_state)): return false
	if typeof(v.issues) != TYPE_ARRAY: return false
	for item in v.issues:
		if not _ss_validation_issue(item): return false
	if not SS_SEARCH._valid_transition(v,v.previous_state,v.action): return false
	return v.status != 1 or _ss_enum(v.rejection_code,SS_RULE_TYPES.ActionRejectionCode.values() + SS_CORE_TYPES.ValidationCode.values())

static func _ss_samples(v: Variant) -> bool:
	if typeof(v) != TYPE_DICTIONARY: return false
	for key in v:
		if not _ss_core(key,"id") or (v[key] != null and not _ss_count(v[key])): return false
	return true

static func _ss_finding(v: Variant) -> bool:
	if not _fields(v,["code","severity","subject_ids","scope","trace","details"]): return false
	if not _ss_enum(v.code,[4000,4001,4002]) or not _ss_enum(v.severity,[0,1,2]) or not _ss_array(v.subject_ids,TYPE_STRING_NAME) or typeof(v.scope) != TYPE_STRING_NAME or (v.trace != null and not _ss_trace(v.trace)): return false
	if v.severity != (1 if v.code == 4002 else 0): return false
	match v.code:
		4000:
			return v.scope == &"MECHANIC_ABLATION" and _fields(v.details,["disabled_mechanics","required_mechanics","bypass_ids"]) and _ss_tags(v.details.disabled_mechanics,false) and _ss_tags(v.details.required_mechanics) and _ss_array(v.details.bypass_ids,TYPE_STRING_NAME)
		4001:
			return v.scope == &"SINGLE_TRACE" and _fields(v.details,["sample_indices"]) and _ss_samples(v.details.sample_indices)
		4002:
			return v.scope in [&"DISCOVERED_WITNESS",&"RETURNED_SHORTEST_TRACE"] and _fields(v.details,["mechanism_id","required_mechanics","optional_mechanics","observed_used"]) and _ss_core(v.details.mechanism_id,"id") and _ss_tags(v.details.required_mechanics) and _ss_tags(v.details.optional_mechanics) and typeof(v.details.observed_used) == TYPE_BOOL and not v.details.observed_used
	return false

static func _ss_findings(v: Variant) -> bool:
	if typeof(v) != TYPE_ARRAY: return false
	for item in v:
		if not _ss_finding(item): return false
	return true

static func _ss_milestone(v: Variant) -> bool:
	if not _fields(v,["status","scope","matched_milestones","missing_required","sample_indices","findings","issues"]): return false
	return _ss_enum(v.status,range(4)) and _string(v.scope) and v.scope == "SINGLE_TRACE" and _ss_array(v.matched_milestones,TYPE_STRING_NAME) and _ss_array(v.missing_required,TYPE_STRING_NAME) and _ss_samples(v.sample_indices) and _ss_findings(v.findings) and _ss_analysis_issues(v.issues)

static func _ss_softlock(v: Variant) -> bool:
	if not _fields(v,["status","initial_key","reachable_states","goal_reachable_states","softlock_states","softlock_count","unknown_states","reset_classification","reset_recoverable_count","witnesses","metrics","issues"]): return false
	if not _ss_enum(v.status,[0,1,2]) or not _string(v.initial_key,true) or not _ss_array(v.reachable_states,TYPE_STRING) or not _ss_array(v.goal_reachable_states,TYPE_STRING) or not _ss_array(v.unknown_states,TYPE_STRING) or not _ss_enum(v.reset_classification,[0,1,2]): return false
	if not _ints(v.metrics,{"nodes_checked":0,"edges_checked":0,"elapsed_ms":0}) or not _ss_analysis_issues(v.issues) or typeof(v.witnesses) != TYPE_ARRAY: return false
	for witness in v.witnesses:
		if not _fields(witness,["target_key","edge_ids"]) or not _string(witness.target_key) or not _ss_array(witness.edge_ids,TYPE_INT): return false
		for edge in witness.edge_ids:
			if edge < 0: return false
	if v.status != 0:
		return v.softlock_states == null and v.softlock_count == null and v.reset_classification == 2 and v.reset_recoverable_count == null and v.witnesses.is_empty()
	if not _ss_array(v.softlock_states,TYPE_STRING) or not _ss_count(v.softlock_count) or v.softlock_count != v.softlock_states.size() or not v.unknown_states.is_empty(): return false
	if v.reset_classification == 2: return v.reset_recoverable_count == null
	return _ss_count(v.reset_recoverable_count) and v.reset_recoverable_count == (v.softlock_count if v.reset_classification == 0 else 0)

static func _ss_ablation_item(v: Variant) -> bool:
	if not _fields(v,["status","disabled_mechanics","baseline_status","ablated_status","essential","bypass_detected","findings","solution_trace_if_any","metrics","issues"]): return false
	if not _ss_enum(v.status,range(4)) or not _ss_tags(v.disabled_mechanics,false) or not _ss_enum(v.baseline_status,range(4)) or (v.ablated_status != null and not _ss_enum(v.ablated_status,range(4))): return false
	if (v.essential != null and typeof(v.essential) != TYPE_BOOL) or (v.bypass_detected != null and typeof(v.bypass_detected) != TYPE_BOOL) or not _ss_findings(v.findings) or not _ss_analysis_issues(v.issues): return false
	if (v.solution_trace_if_any != null and not _ss_trace(v.solution_trace_if_any)) or not _fields(v.metrics,["baseline","ablated"]) or not _ss_metrics(v.metrics.baseline) or (v.metrics.ablated != null and not _ss_metrics(v.metrics.ablated)): return false
	if v.status in [1,2] and (v.essential != null or v.bypass_detected != null): return false
	if v.status == 0:
		if v.ablated_status == 0: return v.essential == false and typeof(v.bypass_detected) == TYPE_BOOL and v.solution_trace_if_any != null
		if v.ablated_status == 1: return v.essential == true and v.bypass_detected == false and v.solution_trace_if_any == null
		return false
	return true

static func _ss_ablation(v: Variant) -> bool:
	if not _fields(v,["status","intent","baseline","ablations","milestone_analysis","advisories","issues"]): return false
	if not _ss_enum(v.status,range(4)) or not _ss_intent(v.intent) or typeof(v.ablations) != TYPE_ARRAY or not _ss_findings(v.advisories) or not _ss_analysis_issues(v.issues): return false
	if v.baseline != null and not _ss_search(v.baseline,"artifacts/stages/ABLATION/baseline_graph.wire"): return false
	if v.milestone_analysis != null and not _ss_milestone(v.milestone_analysis): return false
	for item in v.ablations:
		if not _ss_ablation_item(item): return false
	return true

static func _ss_replay(v: Variant) -> bool:
	if not _fields(v,["status","trace_length","matched_steps","divergence_step","expected_statekey","actual_statekey","action","issues"]): return false
	if not _ss_enum(v.status,range(4)) or not _ss_count(v.trace_length) or not _ss_count(v.matched_steps) or v.matched_steps > v.trace_length or not _string(v.expected_statekey,true) or not _string(v.actual_statekey,true) or not _ss_analysis_issues(v.issues): return false
	if v.divergence_step != null and (not _ss_count(v.divergence_step) or v.divergence_step > v.trace_length): return false
	if v.action != null and not _ss_core(v.action,"action"): return false
	if v.status == 0 and (v.matched_steps != v.trace_length or v.divergence_step != null): return false
	return v.status != 1 or v.divergence_step != null

static func _ss_native(stage_id: String, v: Variant) -> bool:
	if not _portable_tree(v): return false
	match stage_id:
		"AUTHORING":
			return _fields(v,["ok","issues"]) and typeof(v.ok) == TYPE_BOOL and _ss_tool_issues(v.issues)
		"INTENT_BIND":
			if not _fields(v,["ok","bound_intent","source_intent_digest","issues"]) or typeof(v.ok) != TYPE_BOOL or not _ss_tool_issues(v.issues): return false
			return (_ss_intent(v.bound_intent) and _hex(v.source_intent_digest,64)) if v.ok else (v.bound_intent == null and v.source_intent_digest == null)
		"INTENT_VALIDATE":
			return _fields(v,["ok","issues"]) and typeof(v.ok) == TYPE_BOOL and _ss_analysis_issues(v.issues)
		"ORIGINAL_GRAPH": return _ss_search(v,"artifacts/stages/ORIGINAL_GRAPH/graph.wire")
		"SOFTLOCK": return _ss_softlock(v)
		"ABLATION": return _ss_ablation(v)
		"TRACE_SEMANTICS":
			if not _fields(v,["ok","transitions","issues"]) or typeof(v.ok) != TYPE_BOOL or typeof(v.transitions) != TYPE_ARRAY or not _ss_analysis_issues(v.issues): return false
			if not v.ok and not v.transitions.is_empty(): return false
			for item in v.transitions:
				if not _ss_transition(item) or item.status != 0 or not item.changed: return false
			return true
		"MILESTONES": return _ss_milestone(v)
		"GRAPHICAL_REPLAY": return _ss_replay(v)
	return false
