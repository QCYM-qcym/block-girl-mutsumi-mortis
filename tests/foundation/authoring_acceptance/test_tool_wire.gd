extends "res://tests/foundation/authoring_integration/test_suite.gd"

const Wire = preload("res://tools/foundation/authoring_acceptance/tool_wire.gd")
const Records = preload("res://tools/foundation/authoring_acceptance/run_records.gd")
const Boundary = preload("res://tools/foundation/authoring_acceptance/boundary_control.gd")
const Reader = preload("res://foundation/level/authoring_reader.gd")
const Schemas = preload("res://tools/foundation/authoring_acceptance/wire_schemas.gd")

func run() -> void:
	var policy: Dictionary = Records.default_execution_policy("ACCEPT_SAVED")
	check(not policy.is_empty(), "approved policy is available")
	if not policy.is_empty(): _policy(policy)
	_primitives()
	_invalid()
	_limits()
	_records()
	_closed_records()
	_source_uri_review()
	_boundary()
	_reader_precision()
	_authoring_compatibility()
	_stage_protocol()
	_stage_protocol_edges()
	finish()

# Protocol fixtures are values, not substitute Bake/Session implementations.
func _bake_stage() -> Dictionary:
	var identity: Dictionary = _input().identity
	identity.versions.modules.append({"path":"res://foundation/authoring/authoring_adapter.gd","sha256":"d".repeat(64),"version":null})
	identity.versions.modules.sort_custom(func(a,b): return a.path < b.path)
	identity.execution_digest = _raw_digest("versions",identity.versions)
	var canonical := _ref("artifacts/stages/BAKE/canonical.level","b".repeat(64),"levelcanonical.v1")
	var entry := {"authoring_id":"33333333-3333-4333-8333-333333333333","document_uri":"res://maps/test.tscn","node_path_at_capture":"Root/Cube","resource_uid":null,"resource_subpath":null,"local_face":0,"entity_kind":"CUBE","entity_id":&"cube","field":"transform","reader_path":"cubes[0].position","canonical_path":"cubes[0].center2"}
	return {"run_identity":identity,"stage_record":{
		"stage_id":"BAKE","owner":"4A","module_ref":"res://foundation/authoring/authoring_adapter.gd","applicability":"APPLICABLE",
		"execution":"COMPLETED","reason":"","input_refs":{"input_manifest":_ref("input.ready","1".repeat(64),"authoringinputmanifest.v1"),"authoring_payload":_input().authoring_payload},
		"actual_policy":{"max_configurations":4096,"max_checks":100000},"actual_budget":{"max_configurations":4096,"max_checks":100000},
		"native_result":{"ok":true,"level":canonical,"issues":[],"validation":{"status":0,"issues":[],"configurations_checked":1,"checks_performed":2},
			"source_map":{"map_version":"authoringsourcemap.v1","snapshot_id":identity.snapshot_id,"source_fingerprint":identity.source_fingerprint,"level_hash":"c".repeat(64),"entries":[entry]},
			"bake_provenance":{"run_id":identity.run_id,"snapshot_id":identity.snapshot_id,"source_fingerprint":identity.source_fingerprint}},
		"evidence_refs":{"canonical":canonical.duplicate(true)},"warnings":[],"started_at":"2026-09-27T05:00:00.000Z","finished_at":"2026-09-27T05:00:01.000Z"}}

func _worker(stage: Dictionary) -> Dictionary:
	# Legal message construction consumes the unique production version registry.
	return {"protocol_version":Schemas.WORKER_PROTOCOL_VERSION,"identity":stage.run_identity.duplicate(true),"sequence":-9223372036854775807-1,"kind":"STAGE_RESULT","stage_id":"BAKE","payload_ref_or_inline":_ref("artifacts/stages/BAKE/stage_result.wire",_raw_digest("stage_result",stage),"foundationtoolwire.v1")}

func _invalid_schema(kind: String, value: Dictionary, label: String) -> void:
	for result in [Wire.encode_wire(kind,value),Wire.decode_wire(kind,_raw_wire(kind,value))]:
		check(not result.ok and result.value == null and not result.issues.is_empty() and result.issues[0].code == "WIRE_SCHEMA_INVALID",label)

func _stage_protocol() -> void:
	var stage := _bake_stage()
	var message := _worker(stage)
	message.payload_ref_or_inline.byte_length = _raw_wire("stage_result",stage).size()
	for kind in ["stage_result","worker_message"]:
		var value: Dictionary = stage if kind == "stage_result" else message
		var encoded := Wire.encode_wire(kind,value)
		check(encoded.ok,kind + " approved branch encodes")
		if encoded.ok:
			var decoded := Wire.decode_wire(kind,encoded.value)
			check(decoded.ok and decoded.value == value,kind + " exact roundtrip")
			check(encoded.value == _raw_wire(kind,value),kind + " deterministic canonical bytes")
			check(Wire.digest(kind,value).value == _raw_digest(kind,value),kind + " canonical digest")
		for field in value:
			var bad: Dictionary = value.duplicate(true)
			bad.erase(field)
			_invalid_schema(kind,bad,kind + " missing " + field)
		var extra: Dictionary = value.duplicate(true)
		extra.extra = true
		_invalid_schema(kind,extra,kind + " unknown top field")
	for field in stage.stage_record:
		var bad := stage.duplicate(true)
		bad.stage_record.erase(field)
		_invalid_schema("stage_result",bad,"stored stage missing " + field)
	for execution in ["INCOMPLETE","ERROR","CANCELLED"]:
		var terminal := stage.duplicate(true)
		terminal.stage_record.execution = execution
		terminal.stage_record.reason = "formal call interrupted"
		check(Wire.encode_wire("stage_result",terminal).ok,"terminal preserves real result " + execution)
		terminal.stage_record.native_result = null
		terminal.stage_record.evidence_refs.canonical = null
		check(Wire.encode_wire("stage_result",terminal).ok,"terminal without return permits null " + execution)
		terminal.stage_record.evidence_refs.canonical = stage.stage_record.evidence_refs.canonical
		_invalid_schema("stage_result",terminal,"null cannot reference historic canonical")
	for row in [["execution","RUNNING"],["execution","NOT_RUN"],["native_result",null],["stage_id","UNKNOWN"],["owner","4D"],["reason","unexpected"],["extra",true],["warnings",["lost warning"]],["finished_at","2026-09-27T04:59:59.999Z"],["started_at","2026-02-30T00:00:00.000Z"]]:
		var bad := stage.duplicate(true)
		bad.stage_record[row[0]] = row[1]
		_invalid_schema("stage_result",bad,"invalid stored field " + row[0] + " " + str(row[1]))
	for key in ["graph","live_graph","graph_archive_ref","unexpected"]:
		var bad := stage.duplicate(true)
		bad.stage_record.native_result[key] = {}
		_invalid_schema("stage_result",bad,"BAKE forbids " + key)
	var wrong := stage.duplicate(true)
	wrong.stage_record.native_result = {"kind":"invented"}
	_invalid_schema("stage_result",wrong,"unknown native branch")
	for path in ["../canonical.level","E:/secret/canonical.level","/tmp/canonical.level","artifacts/stages/bake/canonical.level","canonical.level"]:
		var bad := stage.duplicate(true)
		bad.stage_record.native_result.level.relative_path = path
		bad.stage_record.evidence_refs.canonical.relative_path = path
		_invalid_schema("stage_result",bad,"canonical path rejected " + path)
	for path in ["E:/temp/file","C:\\cache\\file","/tmp/file","failed reading E:/run/input.ready","failed at /tmp/file","res://../secret","res://E:/secret"]:
		var bad := stage.duplicate(true)
		bad.stage_record.execution = "ERROR"
		bad.stage_record.reason = path
		_invalid_schema("stage_result",bad,"whole payload path " + path)
	for key in ["snapshot_id","source_fingerprint","run_id"]:
		var bad := stage.duplicate(true)
		bad.stage_record.native_result.bake_provenance[key] = "0".repeat(64)
		_invalid_schema("stage_result",bad,"provenance mismatch " + key)
	wrong = stage.duplicate(true)
	wrong.run_identity.execution_digest = "0".repeat(64)
	_invalid_schema("stage_result",wrong,"digest must bind actual versions")
	for sequence in [-9223372036854775807-1,0,1,9223372036854775807]:
		var good := message.duplicate(true)
		good.sequence = sequence
		var encoded := Wire.encode_wire("worker_message",good)
		check(encoded.ok,"sequence wire integer, no invented start/range rule")
		if encoded.ok: check(Wire.decode_wire("worker_message",encoded.value).value.sequence == sequence,"sequence int64 exact")
	for key in ["sequence","stage_id","kind"]:
		var bad := message.duplicate(true)
		bad[key] = null
		_invalid_schema("worker_message",bad,"worker type " + key)
	for payload in [stage.stage_record,stage.stage_record.native_result,"canonical text",null,{"json":"sidecar"}]:
		var bad := message.duplicate(true)
		bad.payload_ref_or_inline = payload
		_invalid_schema("worker_message",bad,"STAGE_RESULT inline payload rejected")
	for path in ["../stage_result.wire","artifacts/stages/BAKE/other.wire","artifacts/stages/MANUAL_RUNTIME/stage_result.wire"]:
		var bad := message.duplicate(true)
		bad.payload_ref_or_inline.relative_path = path
		_invalid_schema("worker_message",bad,"STAGE_RESULT exact path")
	for kind in ["HELLO","STAGE_STARTED","STAGE_RESULT","HEARTBEAT","EXIT","ERROR","CANCEL","LEASE"]:
		var candidate := message.duplicate(true)
		candidate.kind = kind
		for version in [null,"","foundationtoolwire.v1","foundationworkeripc.v2","unknown","Foundationworkeripc.v1"," foundationworkeripc.v1","foundationworkeripc.v1 ",&"foundationworkeripc.v1",1]:
			var bad := candidate.duplicate(true)
			bad.protocol_version = version
			_invalid_schema("worker_message",bad,"strict version for " + kind + " " + str(version))
		var missing := candidate.duplicate(true)
		missing.erase("protocol_version")
		_invalid_schema("worker_message",missing,"missing worker version " + kind)
		if kind != "STAGE_RESULT":
			for payload in [null,{},message.payload_ref_or_inline]:
				candidate.payload_ref_or_inline = payload
				var result := Wire.encode_wire("worker_message",candidate)
				check(not result.ok and result.issues[0].code == "DEPENDENCY_PENDING" and result.issues[0].message == "WORKER_MESSAGE_" + kind + "_PAYLOAD_SCHEMA","unregistered payload remains pending " + kind)
	var schema_api = Schemas.new()
	var wire_api = Wire.new()
	var has_version_validator: bool = schema_api.has_method("validate_worker_version")
	check(has_version_validator,"public worker version validator available")
	if has_version_validator:
		check(schema_api.call("validate_worker_version",message).ok,"exact v1 accepted by version-only validator")
		check(not schema_api.call("validate_worker_version",{}).ok,"version-only validator rejects missing version")
	check(wire_api.has_method("verify_stage_result"),"stateless message/bytes binding verifier available")
	if wire_api.has_method("verify_stage_result"):
		var bytes := _raw_wire("stage_result",stage)
		check(wire_api.call("verify_stage_result",message,bytes).ok,"full STAGE_RESULT byte binding succeeds")
		for field in ["byte_length","sha256"]:
			var bad := message.duplicate(true)
			bad.payload_ref_or_inline[field] = 0 if field == "byte_length" else "0".repeat(64)
			check(not wire_api.call("verify_stage_result",bad,bytes).ok,"binding rejects wrong " + field)
		var stale := message.duplicate(true)
		stale.identity.generation += 1
		check(not wire_api.call("verify_stage_result",stale,bytes).ok,"binding rejects stale complete identity")
		stale = message.duplicate(true)
		stale.stage_id = "MANUAL_RUNTIME"
		stale.payload_ref_or_inline.relative_path = "artifacts/stages/MANUAL_RUNTIME/stage_result.wire"
		check(not wire_api.call("verify_stage_result",stale,bytes).ok,"binding rejects message/stored stage mismatch")
		check(not wire_api.call("verify_stage_result",message,'{}'.to_utf8_buffer()).ok,"binding rejects sidecar bytes")

func _stage_protocol_edges() -> void:
	var stage := _bake_stage()
	for text in ["failed:/tmp/file","错误：/tmp/file","[/tmp/file]","failed:E:/tmp/file","prefix；/tmp/file","path=/tmp/file"]:
		var bad := stage.duplicate(true)
		bad.stage_record.execution = "ERROR"
		bad.stage_record.reason = text
		_invalid_schema("stage_result",bad,"diagnostic punctuation cannot hide absolute path " + text)
	for field in ["node_path_at_capture","resource_subpath","reader_path","canonical_path","field","entity_id"]:
		var bad := stage.duplicate(true)
		bad.stage_record.native_result.source_map.entries[0][field] = StringName("/tmp/file") if field == "entity_id" else "/tmp/file"
		_invalid_schema("stage_result",bad,"SourceMap absolute path in " + field)
	for row in [["entity_id","cube"],["local_face",6],["local_face",0.0],["resource_uid",1],["extra",true],["document_uri","file:///E:/maps/test.tscn"]]:
		var bad := stage.duplicate(true)
		bad.stage_record.native_result.source_map.entries[0][row[0]] = row[1]
		_invalid_schema("stage_result",bad,"SourceMap exact types/fields " + row[0])
	for row in [["status",1],["status",0.0],["configurations_checked",-1],["checks_performed",-1],["issues",[{}]],["extra",true]]:
		var bad := stage.duplicate(true)
		bad.stage_record.native_result.validation[row[0]] = row[1]
		_invalid_schema("stage_result",bad,"Bake validation boundary " + row[0])
	for row in [["max_checks",0],["max_configurations",1.0],["extra",true]]:
		var bad := stage.duplicate(true)
		bad.stage_record.actual_budget[row[0]] = row[1]
		_invalid_schema("stage_result",bad,"Bake budget boundary " + row[0])
	for field in ["stage_result","worker_message"]:
		var old := _versions()
		old.schemas.erase(field)
		_invalid_schema("versions",old,"old versions registry missing " + field + " cannot certify new code")
	for stage_id in ["AUTHORING","ORIGINAL_GRAPH","MANUAL_RUNTIME"]:
		var other := stage.duplicate(true)
		other.stage_record.stage_id = stage_id
		var encoded := Wire.encode_wire("stage_result",other)
		check(not encoded.ok and encoded.issues[0].code == "DEPENDENCY_PENDING","unregistered stage has no generic storage " + stage_id)
	var graph := Wire.encode_wire("graph_archive",{"graph_archive_ref":{}})
	check(not graph.ok and graph.issues[0].code == "DEPENDENCY_PENDING","no graph archive reconstruction or unregistered storage")
	var failed := stage.duplicate(true)
	failed.stage_record.execution = "ERROR"
	failed.stage_record.reason = "Baker rejected input"
	failed.stage_record.native_result.ok = false
	failed.stage_record.native_result.level = null
	var failure := Wire.encode_wire("stage_result",failed)
	check(not failure.ok and failure.issues[0].code == "DEPENDENCY_PENDING" and failed.stage_record.native_result != null,"unsupported failure preserved, never rewritten to null")
	var message := _worker(stage)
	for kind in ["HELLO","STAGE_STARTED","HEARTBEAT","EXIT","ERROR","CANCEL","LEASE"]:
		for stage_id in ["","IPC","not_a_stage"]:
			var pending := message.duplicate(true)
			pending.kind = kind
			pending.stage_id = stage_id
			check(Schemas.validate_worker_version(pending).ok,"version-only accepts exact v1 independently of payload " + kind)
			var result := Wire.decode_wire("worker_message",_raw_wire("worker_message",pending))
			check(not result.ok and result.issues[0].code == "DEPENDENCY_PENDING","non-stage sentinel semantics not invented " + kind)
	var bytes := _raw_wire("stage_result",stage)
	message.payload_ref_or_inline.byte_length = bytes.size()
	var malformed := stage.duplicate(true)
	malformed.stage_record.extra = true
	var corrupt_bytes := _raw_wire("stage_result",malformed)
	var corrupt_message := message.duplicate(true)
	corrupt_message.payload_ref_or_inline.byte_length = corrupt_bytes.size()
	corrupt_message.payload_ref_or_inline.sha256 = _raw_digest("stage_result",malformed)
	check(not Wire.verify_stage_result(corrupt_message,corrupt_bytes).ok,"matching hash does not bypass decode schema")
	var sidecar := '{}'.to_utf8_buffer()
	corrupt_message.payload_ref_or_inline.byte_length = sidecar.size()
	corrupt_message.payload_ref_or_inline.sha256 = '{}'.sha256_text()
	check(not Wire.verify_stage_result(corrupt_message,sidecar).ok,"matching hash does not authorize JSON sidecar")
	_real_bake_storage()

func _real_bake_storage() -> void:
	var fixtures = load("res://tests/foundation/authoring/authoring_fixtures.gd")
	var adapter = load("res://foundation/authoring/authoring_adapter.gd")
	var codec = load("res://foundation/level/level_codec.gd")
	var stage := _bake_stage()
	var payload: Dictionary = fixtures.payload("minimal")
	stage.run_identity.level_ref = payload.level_ref.duplicate(true)
	var id: Dictionary = stage.run_identity
	var snapshot := {"run_id":id.run_id,"snapshot_id":id.snapshot_id,"source_fingerprint":id.source_fingerprint,"source_intent_digest":null}
	var baked: Dictionary = adapter.bake_authoring(payload,stage.stage_record.actual_policy,snapshot)
	check(baked.ok,"real A_BAKE result for storage compatibility")
	if not baked.ok: return
	var encoded_level: Dictionary = codec.encode(baked.level)
	check(encoded_level.ok,"formal LevelCodec provides canonical bytes")
	if not encoded_level.ok: return
	var canonical := _ref("artifacts/stages/BAKE/canonical.level",encoded_level.text.sha256_text(),"levelcanonical.v1")
	canonical.byte_length = encoded_level.text.to_utf8_buffer().size()
	stage.stage_record.native_result = baked.duplicate(true)
	stage.stage_record.native_result.level = canonical
	stage.stage_record.evidence_refs.canonical = canonical.duplicate(true)
	var encoded := Wire.encode_wire("stage_result",stage)
	check(encoded.ok,"real SourceMap/provenance fits approved BAKE storage unchanged")
	if encoded.ok:
		var decoded := Wire.decode_wire("stage_result",encoded.value)
		check(decoded.ok and decoded.value.stage_record.native_result.source_map == baked.source_map,"real SourceMap preserves all entries and exact types")
		check(decoded.value.stage_record.native_result.bake_provenance == baked.bake_provenance,"real BakeProvenance preserved")
		check(codec.decode(encoded_level.text).level.content_hash == baked.level.content_hash,"canonical content identity unchanged")

func _authoring_compatibility() -> void:
	# This follow-up consumes the registered A_SCHEMA checkout, never another
	# worktree. All field ownership and validation remain in A.
	var schema = load("res://foundation/authoring/authoring_schema.gd")
	var projector = load("res://foundation/authoring/document_projector.gd")
	var assembler = load("res://foundation/authoring/payload_assembler.gd")
	var fixtures = load("res://tests/foundation/authoring/authoring_fixtures.gd")
	check(schema.field_types("CUBE").cube_id == TYPE_STRING_NAME and schema.field_types("CUBE").transform == TYPE_TRANSFORM3D, "A owns real Cube field types")
	var whitelist := {}
	for kind in schema.SCRIPTS:
		var path: String = schema.script_path(kind)
		whitelist[path] = FileAccess.get_sha256(path)
	var docs: Array[Dictionary] = []
	var sources := ["level.tscn","surface.tscn","inner.tscn","intent.tres"]
	for i in sources.size():
		var uri: String = fixtures.BASE + sources[i]
		var resource: Resource = ResourceLoader.load(uri, "", ResourceLoader.CACHE_MODE_IGNORE)
		var source: Variant = resource.get_state() if resource is PackedScene else resource
		var context := {"document_uri":uri,"document_authoring_id":fixtures.uuid(i+1),"origin":"SAVED","allowed_script_digests":whitelist,"instance_role":null}
		var projected: Dictionary = projector.project_document(source, context)
		check(projected.ok, "real A document projects: " + sources[i])
		if projected.ok: docs.append(projected.value)
	if docs.size() != 4: return
	var level_ref: Dictionary = fixtures.payload("minimal").level_ref
	var assembled: Dictionary = assembler.assemble_payload(docs, level_ref)
	check(assembled.ok, "real A assembler validates saved source closure")
	if not assembled.ok: return
	var payload: Dictionary = assembled.value
	var encoded: Dictionary = Wire.encode_wire("authoring", payload)
	check(encoded.ok, "D registry consumes A authoring contract without copied fields")
	if encoded.ok:
		var decoded: Dictionary = Wire.decode_wire("authoring", encoded.value)
		check(decoded.ok, "real authoring wire decodes")
		if decoded.ok:
			check(decoded.value == payload and schema.validate_authoring(decoded.value).ok, "roundtrip remains A-valid and unchanged")
			for doc in decoded.value.documents:
				for record in doc.records:
					if record.kind == "CUBE":
						check(typeof(record.fields.cube_id) == TYPE_STRING_NAME, "real Cube ID remains StringName")
						check(typeof(record.fields.transform) == TYPE_TRANSFORM3D, "real Cube transform remains Transform3D")
			check(Wire.encode_wire("authoring", decoded.value).value == encoded.value, "authoring canonical bytes stable")
	for case_name in ["missing_face","duplicate_face","duplicate_id","shared_alias","resource_conflict","unsupported_override"]:
		var invalid: Dictionary = fixtures.payload(case_name)
		var formal: Dictionary = schema.validate_authoring(invalid)
		var result: Dictionary = Wire.encode_wire("authoring", invalid)
		check(not result.ok and result.value == null and result.issues == formal.issues, "A diagnostics preserved: " + case_name)
	for offset in [0.00000049,0.00000051]:
		var precise: Dictionary = fixtures.payload("minimal")
		precise.documents[1].records[1].fields.transform.origin.x = offset
		var wire: Dictionary = Wire.encode_wire("authoring", precise)
		check(wire.ok, "A raw transform near Reader threshold encodes")
		if wire.ok:
			var recovered: Dictionary = Wire.decode_wire("authoring", wire.value)
			check(recovered.ok and Wire._encode_value(recovered.value).value == Wire._encode_value(precise).value, "full author payload preserves exact transform bits")
	check(not Wire.encode_wire("authoring", []).ok, "non-Dictionary authoring fails without invoking A on wrong type")
	var pending: Dictionary = Wire.encode_wire("source_map", {})
	check(not pending.ok and pending.issues[0].code == "DEPENDENCY_PENDING", "source_map remains A2-owned pending; no D substitute")

func _policy(policy: Dictionary) -> void:
	var expected := {"bake_options":{"max_configurations":4096,"max_checks":100000},
		"search_budget":{"max_states":10000,"max_edges":100000,"max_depth":-1,"max_runtime_ms":30000,"max_action_evaluations":200000},
		"softlock_budget":{"max_nodes":10000,"max_edges":100000,"max_runtime_ms":30000},
		"replay_options":{"mode":1,"max_steps":10000,"max_runtime_ms":60000,"step_timeout_ms":5000},
		"search_mode":1,"stage_deadline_ms":300000,"lease_interval_ms":1000,"lease_timeout_ms":30000,"max_wire_bytes":134217728,"max_wire_depth":64}
	for key in expected:
		check(policy.get(key) == expected[key], "approved default: " + key)
	check(policy.stages == ["AUTHORING","BAKE","INTENT_BIND","INTENT_VALIDATE","ORIGINAL_GRAPH","SOFTLOCK","ABLATION","TRACE_SEMANTICS","MILESTONES","GRAPHICAL_REPLAY","ARCHIVE"], "complete acceptance cannot omit gates")
	check(Records.default_execution_policy("bad").is_empty(), "unknown entry fails closed")
	var local: Dictionary = Records.default_execution_policy("ANALYZE_CURRENT")
	check(local.get("stages") == ["AUTHORING","BAKE","MANUAL_RUNTIME"], "early local scope has no quality dependency")
	var encoded: Dictionary = Wire.encode_wire("policy", policy)
	check(encoded.ok, "real policy encodes")
	if not encoded.ok: return
	check(encoded.value.get_string_from_utf8().begins_with('["foundationtoolwire.v1","policy",'), "wire envelope")
	var decoded: Dictionary = Wire.decode_wire("policy", encoded.value)
	check(decoded.ok and decoded.value == policy, "closed policy exact roundtrip")
	var reversed := {}
	var keys: Array = policy.keys()
	keys.reverse()
	for key in keys: reversed[key] = policy[key]
	check(Wire.encode_wire("policy", reversed).value == encoded.value, "map insertion order canonical")
	var digest: Dictionary = Wire.digest("policy", policy)
	check(digest.ok, "digest returns success")
	var hashing := HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	hashing.update(encoded.value)
	check(digest.value == hashing.finish().hex_encode(), "digest is canonical bytes SHA256")
	for field in policy:
		var bad: Dictionary = policy.duplicate(true)
		bad.erase(field)
		check(not Wire.encode_wire("policy", bad).ok, "missing policy field " + field)
	var bad: Dictionary = policy.duplicate(true)
	bad.extra = true
	check(not Wire.encode_wire("policy", bad).ok, "unknown policy field")
	bad = policy.duplicate(true)
	bad.lease_timeout_ms = 1
	check(not Wire.encode_wire("policy", bad).ok, "protocol lease is fixed")
	bad = policy.duplicate(true)
	bad.stages.erase("SOFTLOCK")
	check(not Wire.encode_wire("policy", bad).ok, "acceptance cannot drop required stage")
	bad = policy.duplicate(true)
	bad.search_budget.max_states = 0
	check(not Wire.encode_wire("policy", bad).ok, "search domain checked")
	bad = policy.duplicate(true)
	bad.search_budget.max_runtime_ms = 0
	check(Wire.encode_wire("policy", bad).ok, "explicit zero module wallclock allowed")
	bad = policy.duplicate(true)
	bad.replay_options.mode = 0
	check(not Wire.encode_wire("policy", bad).ok, "logical replay cannot certify acceptance")
	bad = policy.duplicate(true)
	bad.replay_options.step_timeout_ms = 0
	check(not Wire.encode_wire("policy", bad).ok, "zero step timeout rejected per real Replayer")
	bad.replay_options.step_timeout_ms = 1
	check(Wire.encode_wire("policy", bad).ok, "positive step timeout accepted per real Replayer")
	bad = policy.duplicate(true)
	bad.search_budget.extra = 0
	check(not Wire.encode_wire("policy", bad).ok, "unknown nested budget field")
	bad = policy.duplicate(true)
	bad.search_budget.max_states = 10000.0
	check(not Wire.encode_wire("policy", bad).ok, "integer budget cannot silently accept float")
	var tagged: Dictionary = Wire._encode_value(bad)
	if tagged.ok:
		var raw: PackedByteArray = '["foundationtoolwire.v1","policy",'.to_utf8_buffer()
		raw.append_array(tagged.value)
		raw.append(93)
		check(not Wire.decode_wire("policy", raw).ok, "decode also enforces schema")
	check(not Wire.decode_wire("policy", (encoded.value.get_string_from_utf8()+"\n").to_utf8_buffer()).ok, "public envelope rejects trailing whitespace")
	for kind in ["bogus","level","authoring","source_map"]:
		check(not Wire.encode_wire(kind, policy).ok, "no invented/fallback schema " + kind)
	var changed: Dictionary = policy.duplicate(true)
	changed.search_budget.max_states = 9999
	check(Wire.digest("policy", changed).value != digest.value, "policy change changes digest")

func _round(value: Variant, literal: String = "") -> void:
	var encoded: Dictionary = Wire._encode_value(value)
	check(encoded.ok, "primitive encodes: " + type_string(typeof(value)))
	if not encoded.ok: return
	if not literal.is_empty(): check(encoded.value.get_string_from_utf8() == literal, "independent canonical literal " + literal)
	var decoded: Dictionary = Wire._decode_value(encoded.value)
	check(decoded.ok, "primitive decodes")
	if decoded.ok:
		check(typeof(decoded.value) == typeof(value) and decoded.value == value, "value and exact type preserved")
		check(Wire._encode_value(decoded.value).value == encoded.value, "canonical bytes stable")

func _primitives() -> void:
	_round(null, '["null"]')
	_round(true, '["bool",true]')
	_round(-9223372036854775807 - 1, '["int","-9223372036854775808"]')
	_round(9223372036854775807, '["int","9223372036854775807"]')
	_round(0, '["int","0"]')
	_round("a", '["string","a"]')
	_round(&"a", '["name","a"]')
	_round(-0.0, '["f64","8000000000000000"]')
	_round(1.0, '["f64","3ff0000000000000"]')
	_round(1.0000000000000002, '["f64","3ff0000000000001"]')
	_round(Vector3i(-2147483648,2147483647,0), '["v3i","-2147483648","2147483647","0"]')
	_round(Vector3(0.5,-0.25,2.0))
	_round(Basis(Vector3(0,1,0),Vector3(-1,0,0),Vector3(0,0,1)))
	_round(Transform3D(Basis.IDENTITY,Vector3(0.00000049,0.5,-2.0)))
	_round(Transform3D(Basis.IDENTITY,Vector3(0.00000051,0.5,-2.0)))
	_round("\n\t\r\"\\/少女é", '["string","\u005cu000a\u005cu0009\u005cu000d\u005c\"\u005c\u005c/少女é"]')
	_round([&"a",1,false,null])
	_round({"z":1,"a":2}, '["dict",[[["string","a"],["int","2"]],[["string","z"],["int","1"]]]]')
	check(Wire._encode_value("é").value != Wire._encode_value("é").value, "Unicode not normalized")

func _invalid() -> void:
	for value in [NAN,INF,-INF,Vector3(INF,0,0),Callable(),RefCounted.new()]:
		var result: Dictionary = Wire._encode_value(value)
		check(not result.ok and result.value == null and not result.issues.is_empty(), "unsafe native value fails without partial value")
	for text in ['["int","9223372036854775808"]','["int","-9223372036854775809"]','["int","01"]','["int","-0"]','["int","+1"]','["int",1]',
		'["v3i","2147483648","0","0"]','["v3i","-2147483649","0","0"]','["f64","7ff0000000000000"]','["f64","7ff8000000000000"]',
		'["f64","3FF0000000000000"]','["null",null]','{}','["object","foo"]','["null",]',' ["null"]','["null"]\n',
		'["string","\u005cu0061"]','["string","\u005c/"]', '["string","\u005cuD800"]',
		'["string","\u005cu0000"]',
		'["dict",[[["string","b"],["null"]],[["string","a"],["null"]]]]',
		'["dict",[[["string","a"],["null"]],[["string","a"],["null"]]]]',
		'["dict",[[["name","a"],["null"]],[["string","a"],["null"]]]]',
		'["dict",[[["bool",true],["null"]]]]']:
		var result: Dictionary = Wire._decode_value(text.to_utf8_buffer())
		check(not result.ok and result.value == null, "reject malformed wire: " + text)
	check(not Wire._decode_value(PackedByteArray([0xff,0xfe])).ok, "invalid UTF8")
	check(not Wire._decode_value(PackedByteArray([0xed,0xa0,0x80])).ok, "encoded surrogate")
	for bad in [PackedByteArray([0xc0,0x80]),PackedByteArray([0xf4,0x90,0x80,0x80]),PackedByteArray([0xe2,0x82]),PackedByteArray([0x80]),PackedByteArray([0])]:
		check(not Wire._decode_value(bad).ok, "invalid UTF8 scalar/length")
	var narrowed := '["v3",["f64","3ff0000000000001"],["f64","0000000000000000"],["f64","0000000000000000"]]'
	var narrowing: Dictionary = Wire._decode_value(narrowed.to_utf8_buffer())
	if Vector3(1.0000000000000002,0,0).x == 1.0:
		check(not narrowing.ok and narrowing.issues[0].code == "WIRE_PRECISION_UNSUPPORTED", "component rounding explicitly rejected")
	else:
		check(narrowing.ok, "double engine retains exact component")
	check(not Wire.decode_wire("policy", '["foundationtoolwire.v2","policy",["null"]]'.to_utf8_buffer()).ok, "unknown wire version")
	check(not Wire.decode_wire("policy", '["foundationtoolwire.v1","report",["null"]]'.to_utf8_buffer()).ok, "envelope kind mismatch")
	var cycle: Array = []
	cycle.append(cycle)
	check(not Wire._encode_value(cycle).ok, "cyclic array rejected")
	cycle.clear()

func _limits() -> void:
	var value: Variant = null
	for i in 63: value = [value]
	var at: Dictionary = Wire._encode_value(value)
	check(at.ok, "depth64 accepted")
	if at.ok:
		check(Wire._decode_value(at.value).ok, "depth64 decoded")
		var over: String = '["array",[' + at.value.get_string_from_utf8() + ']]'
		check(not Wire._decode_value(over.to_utf8_buffer()).ok, "depth65 decoded rejected")
	check(not Wire._encode_value([value]).ok, "depth65 encoded rejected")
	var large: String = "x".repeat(134217728 - 13)
	var encoded: Dictionary = Wire._encode_value(large)
	check(encoded.ok and encoded.value.size() == 134217728, "128MiB exact accepted")
	if encoded.ok:
		check(Wire._decode_value(encoded.value).ok, "128MiB exact read")
		encoded.value.append(32)
		check(not Wire._decode_value(encoded.value).ok, "128MiB plus one read rejected")
	encoded.clear()
	check(not Wire._encode_value(large + "x").ok, "128MiB plus one write rejected")
	# The envelope counts toward the public limit, even when the value fits.
	var huge: Dictionary = Records.default_execution_policy("ANALYZE_CURRENT")
	huge.stages = [large]
	check(not Wire.encode_wire("policy", huge).ok, "invalid huge policy cannot escape schema/limit")

func _boundary() -> void:
	var control = Boundary.new()
	check(control.stop_requested(), "unbound boundary fails closed")
	check(not control.checkpoint("ORIGINAL_GRAPH"), "unbound boundary cannot launch formal call")
	doubles.append("in-memory BoundaryControl status provider (no algorithm double)")
	var identity := {"run_id":"run-one","generation":7}
	var status := {"identity":identity.duplicate(true),"cancelled":false,"lease_deadline_msec":Time.get_ticks_msec()+30000,"stage_deadline_msec":Time.get_ticks_msec()+300000}
	var bound = Boundary.new(identity, func(): return status)
	check(bound.checkpoint("ORIGINAL_GRAPH"), "live boundary permits call")
	identity.generation = 8
	check(bound.checkpoint("SOFTLOCK"), "control owns immutable identity binding")
	status.cancelled = true
	check(bound.stop_requested() and bound.reason() == "CANCELLED", "cancel observed at boundary")
	status.cancelled = false
	check(not bound.checkpoint("ABLATION"), "cancel latched; later stages remain blocked")
	var timed = Boundary.new(status.identity, func(): return status)
	status.stage_deadline_msec = 0
	check(not timed.checkpoint("ORIGINAL_GRAPH") and timed.reason() == "TIMEOUT", "deadline stops next call")
	status.stage_deadline_msec = Time.get_ticks_msec()+300000
	status.lease_deadline_msec = 0
	var leased = Boundary.new(status.identity, func(): return status)
	check(leased.stop_requested() and leased.reason() == "LEASE_EXPIRED", "expired parent lease stops next boundary")
	status.lease_deadline_msec = Time.get_ticks_msec()+30000
	var stale = Boundary.new(status.identity, func(): return status)
	status.identity.generation = 9
	check(stale.stop_requested() and stale.reason() == "IDENTITY_MISMATCH", "stale status rejected")
	var unknown = Boundary.new(status.identity, func(): return status)
	check(not unknown.checkpoint("INVENTED") and unknown.reason() == "INVALID_STAGE", "unknown stage cannot pass boundary")
	var broken = Boundary.new(status.identity, func(): return {})
	check(broken.stop_requested() and broken.reason() == "CONTROL_INVALID", "missing status is not a live lease")

func _records() -> void:
	var snapshot := {"identity":{"run_id":"11111111-1111-4111-8111-111111111111","snapshot_id":"22222222-2222-4222-8222-222222222222","source_fingerprint":"a".repeat(64),"source_intent_digest":null}}
	var level_ref := {"level_authoring_id":"33333333-3333-4333-8333-333333333333","level_id":&"test","root_source_uri":"res://maps/test.tscn"}
	var versions := _versions()
	var execution_digest := _raw_digest("versions", versions)
	var identity: Dictionary = Records.make_identity("44444444-4444-4444-8444-444444444444", 7, level_ref, snapshot, "c".repeat(64), execution_digest, versions)
	check(identity.size() == 9, "RunIdentity exact nine fields")
	if not identity.is_empty():
		check(identity.run_id == snapshot.identity.run_id and identity.snapshot_id == snapshot.identity.snapshot_id, "identity preserves capture UUIDs")
		check(identity.source_fingerprint == "a".repeat(64) and identity.policy_digest == "c".repeat(64) and identity.execution_digest == execution_digest, "identity binds three independent digests")
		check(identity.generation == 7 and identity.level_ref == level_ref and identity.versions == versions, "identity binds source versions and generation")
		identity.level_ref.level_id = &"other"
		check(level_ref.level_id == &"test", "identity owns its value snapshot")
	check(Records.make_identity("44444444-4444-4444-8444-444444444444", -1, level_ref, snapshot, "c".repeat(64), execution_digest, versions).is_empty(), "negative generation rejected")
	check(Records.make_identity("44444444-4444-4444-8444-444444444444", 1, level_ref, snapshot, "bad", execution_digest, versions).is_empty(), "bad digest rejected")
	check(Records.make_identity("44444444-4444-4444-8444-444444444444", 1, level_ref, snapshot, "c".repeat(64), execution_digest, {}).is_empty(), "missing versions rejected")
	check(Records.make_identity("44444444-4444-4444-8444-444444444444", 1, level_ref, snapshot, "c".repeat(64), execution_digest, {"bogus":true}).is_empty(), "identity cannot certify versions without tool/contracts/engine/module/configuration identities")
	var stage: Dictionary = Records.make_stage_record("ORIGINAL_GRAPH", "3A", "res://foundation/solver/bfs_solver.gd")
	check(stage.size() == 14, "StageRecord exact fourteen fields")
	if not stage.is_empty():
		check(stage.execution == "NOT_RUN" and stage.native_result == null and stage.started_at == null, "factory cannot fabricate native result or execution")
	check(Records.make_stage_record("invented", "3A", "module").is_empty(), "unknown stage rejected")

func _reader_precision() -> void:
	# Existing, unmodified plain Reader fixture; this is not A_SCHEMA proof.
	for row in [[0.00000049,true],[0.00000051,false]]:
		var fixture: Node3D = load("res://tools/foundation/level/minimal_authoring.tscn").instantiate()
		var cube: Node3D = fixture.get_node("Cubes/Floor")
		cube.transform = Transform3D(Basis.IDENTITY, Vector3(row[0],0,0))
		var before: Dictionary = Reader.read_scene(fixture)
		check(before.ok == row[1], "Reader threshold fixture has independent expected outcome")
		var encoded: Dictionary = Wire._encode_value(cube.transform)
		check(encoded.ok, "raw transform encodes without quantization")
		if encoded.ok:
			var decoded: Dictionary = Wire._decode_value(encoded.value)
			check(decoded.ok, "raw transform recovers exactly")
			if decoded.ok:
				cube.transform = decoded.value
				check(Reader.read_scene(fixture) == before, "wire preserves full real Reader outcome near threshold")
		fixture.free()

# Plain protocol values, not a real execution-project or package delivery.
func _versions() -> Dictionary:
	return {"record_version":"foundationversions.v1","tool_version":"authoringrun.v1",
		"schemas":{"wire":"foundationtoolwire.v1","authoring":"levelauthoring.v1","intent_authoring":"puzzleintentauthoring.v1","snapshot":"authoringsnapshot.v1","source_map":"authoringsourcemap.v1","report":"levelacceptance.v1","source_manifest":"authoringsourcemanifest.v1","input_manifest":"authoringinputmanifest.v1","archive_manifest":"authoringarchivemanifest.v1","stage_result":"foundationtoolwire.v1","worker_message":Schemas.WORKER_PROTOCOL_VERSION},
		"contracts":{"schema_version":1,"contract_version":"foundation.contract.v1","contract_revision":"v1.1","orientation_version":"cube24.v1","rule_version":"foundation.rules.v1","execution_version":"foundation.execution.v1","analysis_version":"foundation.analysis.v1","intent_version":"puzzleintent.v1","trace_version":"solutiontrace.v1"},
		"engine":{"version":"4.7.2.stable.steam.ed1daf0bf","executable_sha256":"e".repeat(64)},
		"modules":[{"path":"res://foundation/a.gd","sha256":"a".repeat(64),"version":"foundation.contract.v1"},{"path":"res://foundation/b.gd.uid","sha256":"b".repeat(64),"version":null}],
		"configuration":[{"path":"res://project.godot","sha256":"c".repeat(64),"version":null}]}

func _raw_wire(kind: String, value: Dictionary) -> PackedByteArray:
	var encoded: Dictionary = Wire._encode_value(value)
	var bytes := ('["foundationtoolwire.v1","' + kind + '",').to_utf8_buffer()
	bytes.append_array(encoded.value)
	bytes.append(93)
	return bytes

func _raw_digest(kind: String, value: Dictionary) -> String:
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(_raw_wire(kind, value))
	return hash.finish().hex_encode()

func _ref(path: String, hash: String, version: String) -> Dictionary:
	return {"relative_path":path,"byte_length":10,"sha256":hash,"format_version":version}

func _source() -> Dictionary:
	return {"authoring_payload_digest":"f".repeat(64),"dependencies":[{"source_uri":"res://maps/test.tscn","resource_uid":null,"kind":"SCENE","origin":"SAVED","content_digest":"f".repeat(64),"disk_digest":"1".repeat(64),"declared_version":"levelauthoring.v1","authoring_ids":["33333333-3333-4333-8333-333333333333"]}],
		"source_locations":[{"document_uri":"res://maps/test.tscn","authoring_id":"33333333-3333-4333-8333-333333333333","node_path":".","label":"test"}]}

func _input() -> Dictionary:
	var versions := _versions()
	var source := _source()
	var policy := Records.default_execution_policy("ACCEPT_SAVED")
	var identity := {"editor_instance_id":"44444444-4444-4444-8444-444444444444","run_id":"11111111-1111-4111-8111-111111111111","generation":0,"level_ref":{"level_authoring_id":"33333333-3333-4333-8333-333333333333","level_id":&"test","root_source_uri":"res://maps/test.tscn"},"snapshot_id":"22222222-2222-4222-8222-222222222222","source_fingerprint":_raw_digest("source_manifest",source),"policy_digest":_raw_digest("policy",policy),"execution_digest":_raw_digest("versions",versions),"versions":versions}
	var payload := _ref("input/authoring.wire",source.authoring_payload_digest,"levelauthoring.v1")
	var policy_ref := _ref("input/policy.wire",identity.policy_digest,"authoringpolicy.v1")
	var source_ref := _ref("input/source.wire",identity.source_fingerprint,"authoringsourcemanifest.v1")
	var attachments := [payload,policy_ref,source_ref]
	for file in versions.modules + versions.configuration:
		attachments.append(_ref("input/execution/" + file.sha256 + ".blob",file.sha256,"rawbytes.v1"))
	attachments.sort_custom(func(a,b): return a.relative_path.to_utf8_buffer().hex_encode() < b.relative_path.to_utf8_buffer().hex_encode())
	return {"manifest_version":"authoringinputmanifest.v1","identity":identity,"input_mode":"ACCEPT_SAVED","source_manifest":source_ref,"authoring_payload":payload,"execution_policy":policy_ref,"attachments":attachments,"source_metadata":{"git_head":null,"engine_path":null}}

func _archive(input: Dictionary) -> Dictionary:
	var input_ref := _ref("input.ready",_raw_digest("input_manifest",input),"authoringinputmanifest.v1")
	var report := _ref("report.wire","9".repeat(64),"levelacceptance.v1")
	var attachments: Array = input.attachments.duplicate(true)
	attachments.append(input_ref)
	attachments.append(report)
	attachments.sort_custom(func(a,b): return a.relative_path.to_utf8_buffer().hex_encode() < b.relative_path.to_utf8_buffer().hex_encode())
	return {"manifest_version":"authoringarchivemanifest.v1","identity":input.identity.duplicate(true),"input_manifest":input_ref,"report":report,"attachments":attachments}

func _reject_record(kind: String, value: Dictionary, label: String) -> void:
	var encoded := Wire.encode_wire(kind,value)
	check(not encoded.ok and encoded.value == null, label + " encode rejects")
	check(not Wire.decode_wire(kind,_raw_wire(kind,value)).ok, label + " decode rejects")

func _closed_records() -> void:
	var versions := _versions()
	var source := _source()
	var input := _input()
	var archive := _archive(input)
	var records := {"versions":versions,"source_manifest":source,"input_manifest":input,"archive_manifest":archive}
	for kind in records:
		var value: Dictionary = records[kind]
		var encoded := Wire.encode_wire(kind,value)
		check(encoded.ok,"closed " + kind + " encodes")
		if encoded.ok:
			var decoded := Wire.decode_wire(kind,encoded.value)
			check(decoded.ok and decoded.value == value,"closed " + kind + " roundtrip")
			check(Wire.digest(kind,value).value == _raw_digest(kind,value),kind + " exact canonical SHA")
			for other in records:
				if other != kind: check(not Wire.decode_wire(other,encoded.value).ok,kind + " cannot masquerade as " + other)
		for field in value:
			var missing: Dictionary = value.duplicate(true)
			missing.erase(field)
			_reject_record(kind,missing,kind + " missing " + field)
			missing = value.duplicate(true)
			missing[field] = null
			_reject_record(kind,missing,kind + " null " + field)
		var unknown: Dictionary = value.duplicate(true)
		unknown.bogus = true
		_reject_record(kind,unknown,kind + " unknown field")
	_reject_record("manifest",source,"ambiguous manifest removed")
	_reject_record("versions",{"bogus":true},"bogus versions")
	for field in ["schemas","contracts","engine"]:
		var nested: Dictionary = versions.duplicate(true)
		nested[field].extra = true
		_reject_record("versions",nested,"unknown nested " + field)
		for key in versions[field]:
			nested = versions.duplicate(true)
			nested[field].erase(key)
			_reject_record("versions",nested,"missing nested " + key)
			nested = versions.duplicate(true)
			nested[field][key] = null
			_reject_record("versions",nested,"null nested " + key)
	var bad: Dictionary = versions.duplicate(true)
	bad.engine.executable_path = "C:/Godot/godot.exe"
	_reject_record("versions",bad,"engine path outside canonical versions")
	bad = versions.duplicate(true); bad.schemas.wire = "foundationtoolwire.v2"
	_reject_record("versions",bad,"unknown schema version")
	bad = versions.duplicate(true); bad.record_version = "foundationversions.v2"
	_reject_record("versions",bad,"unknown record version")
	bad = versions.duplicate(true); bad.engine.executable_sha256 = "X".repeat(64)
	_reject_record("versions",bad,"illegal hash")
	for field in ["modules","configuration"]:
		bad = versions.duplicate(true); bad[field] = []
		_reject_record("versions",bad,"empty closure " + field)
		bad = versions.duplicate(true); bad[field][0].extra = 1
		_reject_record("versions",bad,"unknown execution file field " + field)
	bad = versions.duplicate(true); bad.modules.reverse()
	_reject_record("versions",bad,"unsorted modules")
	bad = versions.duplicate(true); bad.modules.append(bad.modules[0].duplicate(true))
	_reject_record("versions",bad,"duplicate module path")
	bad = versions.duplicate(true); bad.modules[0].path = "res://project.godot"
	_reject_record("versions",bad,"cross collection path duplicate")
	bad = versions.duplicate(true); bad.modules[0].version = "unregistered.v1"
	_reject_record("versions",bad,"unknown module version")
	for path in ["res://../bad.gd","res://a//b.gd","C:/bad.gd","res://a\\b.gd"]:
		bad = versions.duplicate(true); bad.modules[0].path = path
		_reject_record("versions",bad,"invalid module path " + path)
	var identity: Dictionary = input.identity
	var snapshot := {"identity":{"run_id":identity.run_id,"snapshot_id":identity.snapshot_id,"source_fingerprint":identity.source_fingerprint,"source_intent_digest":null}}
	check(Records.make_identity(identity.editor_instance_id,0,identity.level_ref,snapshot,identity.policy_digest,"0".repeat(64),versions).is_empty(),"execution digest must match full versions wire")
	for field in ["engine","modules","configuration"]:
		bad = versions.duplicate(true)
		if field == "engine": bad.engine.executable_sha256 = "0".repeat(64)
		else: bad[field][0].sha256 = "0".repeat(64)
		var changed := Wire.digest("versions",bad)
		check(changed.ok and changed.value != identity.execution_digest,"execution identity covers " + field)
	bad = source.duplicate(true); bad.manifest_version = "authoringsourcemanifest.v1"
	_reject_record("source_manifest",bad,"no inner source version")
	for field in ["run_id","snapshot_id","captured_at","capture_generation"]:
		bad = source.duplicate(true); bad[field] = "forbidden"
		_reject_record("source_manifest",bad,"source excludes " + field)
	bad = source.duplicate(true); bad.dependencies[0].disk_digest = null
	_reject_record("source_manifest",bad,"saved source needs disk digest")
	bad = source.duplicate(true); bad.dependencies[0].content_digest = "0".repeat(64)
	_reject_record("source_manifest",bad,"source selected closure digest equality")
	bad = source.duplicate(true); bad.dependencies.append(bad.dependencies[0].duplicate(true))
	_reject_record("source_manifest",bad,"duplicate source URI")
	bad = source.duplicate(true); bad.dependencies[0].authoring_ids.append(bad.dependencies[0].authoring_ids[0])
	_reject_record("source_manifest",bad,"duplicate authoring ID")
	bad = source.duplicate(true); bad.source_locations.append(bad.source_locations[0].duplicate(true))
	_reject_record("source_manifest",bad,"duplicate location tuple")
	bad = source.duplicate(true); bad.dependencies[0].origin = "EDITOR_BUFFER"; bad.dependencies[0].disk_digest = null
	check(Wire.encode_wire("source_manifest",bad).ok,"explicit nullable unsaved disk metadata")
	for kind in ["input_manifest","archive_manifest"]:
		for path in ["/absolute","C:/escape","../escape","input/../escape","input//bad","input\\bad"]:
			bad = records[kind].duplicate(true); bad.attachments[0].relative_path = path
			_reject_record(kind,bad,"invalid package path " + path)
		bad = records[kind].duplicate(true); bad.attachments.reverse()
		_reject_record(kind,bad,"unsorted attachments")
		bad = records[kind].duplicate(true); bad.attachments.append(bad.attachments[0].duplicate(true))
		_reject_record(kind,bad,"duplicate attachment path")
		bad = records[kind].duplicate(true); bad.attachments[0].role = "invented"
		_reject_record(kind,bad,"ArtifactRef remains four fields")
		bad = records[kind].duplicate(true); bad.attachments[0].byte_length = -1
		_reject_record(kind,bad,"negative length")
		bad = records[kind].duplicate(true); bad.attachments[0].format_version = "unknown.v1"
		_reject_record(kind,bad,"unknown attachment format")
		bad = records[kind].duplicate(true); bad.identity.execution_digest = "0".repeat(64)
		_reject_record(kind,bad,"identity digest disagreement")
		bad = records[kind].duplicate(true); bad.identity.versions.bogus = true
		_reject_record(kind,bad,"embedded versions closed")
	bad = input.duplicate(true); bad.source_manifest.sha256 = "0".repeat(64)
	_reject_record("input_manifest",bad,"source fingerprint mismatch")
	bad = input.duplicate(true); bad.attachments.pop_front()
	_reject_record("input_manifest",bad,"explicit reference missing from attachments")
	bad = input.duplicate(true); bad.attachments[1].relative_path = "input.ready"
	_reject_record("input_manifest",bad,"input cannot reference itself")
	bad = input.duplicate(true); bad.source_metadata.extra = true
	_reject_record("input_manifest",bad,"closed source metadata")
	bad = input.duplicate(true); bad.source_metadata.git_head = "not-a-sha"
	_reject_record("input_manifest",bad,"Git source metadata domain")
	bad = input.duplicate(true); bad.source_metadata.engine_path = "relative/godot.exe"
	_reject_record("input_manifest",bad,"local engine path must be absolute")
	bad = input.duplicate(true); bad.source_metadata.engine_path = "D:/another/Godot.exe"
	var moved := Wire.encode_wire("input_manifest",bad)
	check(moved.ok and bad.identity.execution_digest == identity.execution_digest,"local engine install path leaves execution identity unchanged")
	bad = archive.duplicate(true); bad.attachments[0].relative_path = "manifest.wire"
	_reject_record("archive_manifest",bad,"archive cannot reference itself")
	bad = archive.duplicate(true); bad.report.format_version = "rawbytes.v1"
	_reject_record("archive_manifest",bad,"report role binds formal format")

func _source_uri_review() -> void:
	for uri in ["file:///C:foo.tscn","file:///1:/maps/test.tscn","file:///E:/maps/%2e%2e/secret.tscn","file:///E:/maps/%2E%2E/secret.tscn","file:///E:/maps/%2Fsecret.tscn","file:///E:/maps/%5Csecret.tscn","file:///E:/maps/%00bad.tscn","file:///E:/maps/%FFbad.tscn","file:///E:/maps/%61lias.tscn","file:///E:/maps/bad%.tscn","file:///E:/maps/raw space.tscn"]:
		var bad := _source()
		bad.dependencies[0].source_uri = uri
		bad.source_locations[0].document_uri = uri
		_reject_record("source_manifest",bad,"noncanonical external URI " + uri)
	for uri in ["file:///E:/maps/test.tscn","file:///home/maps/test.tscn","file:///E:/maps/my%20level.tscn","file:///E:/maps/%E5%B0%91%E5%A5%B3.tscn"]:
		var good := _source()
		good.dependencies[0].source_uri = uri
		good.source_locations[0].document_uri = uri
		var encoded := Wire.encode_wire("source_manifest",good)
		check(encoded.ok,"canonical external URI accepted " + uri)
		if encoded.ok: check(Wire.decode_wire("source_manifest",encoded.value).ok,"external URI roundtrip " + uri)
