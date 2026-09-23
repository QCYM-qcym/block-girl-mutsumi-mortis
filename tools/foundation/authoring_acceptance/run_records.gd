extends RefCounted

const Wire = preload("res://tools/foundation/authoring_acceptance/tool_wire.gd")
const Schemas = preload("res://tools/foundation/authoring_acceptance/wire_schemas.gd")

static func default_execution_policy(entry_kind: String) -> Dictionary:
	if entry_kind not in ["ACCEPT_SAVED","ANALYZE_CURRENT"]: return {}
	return {"entry_kind":entry_kind,
		"stages":Schemas.ACCEPT_STAGES.duplicate() if entry_kind == "ACCEPT_SAVED" else ["AUTHORING","BAKE","MANUAL_RUNTIME"],
		"bake_options":{"max_configurations":4096,"max_checks":100000},"search_mode":1,
		"search_budget":{"max_states":10000,"max_edges":100000,"max_depth":-1,"max_runtime_ms":30000,"max_action_evaluations":200000},
		"softlock_budget":{"max_nodes":10000,"max_edges":100000,"max_runtime_ms":30000},
		"replay_options":{"mode":1,"max_steps":10000,"max_runtime_ms":60000,"step_timeout_ms":5000},
		"stage_deadline_ms":300000,"lease_interval_ms":1000,"lease_timeout_ms":30000,
		"max_wire_bytes":134217728,"max_wire_depth":64}

static func make_identity(editor_id: String, generation: int, level_ref: Dictionary, snapshot: Dictionary, policy_digest: String, execution_digest: String, versions: Dictionary) -> Dictionary:
	if not _uuid(editor_id) or generation < 0 or not Schemas.validate("versions",versions).ok or not _digest(policy_digest) or not _digest(execution_digest): return {}
	var bound_digest: Dictionary = Wire.digest("versions",versions)
	if not bound_digest.ok or bound_digest.value != execution_digest: return {}
	if not Schemas._level_ref(level_ref): return {}
	if typeof(level_ref.level_authoring_id) != TYPE_STRING or level_ref.level_authoring_id.is_empty() or typeof(level_ref.level_id) != TYPE_STRING_NAME or String(level_ref.level_id).is_empty() or typeof(level_ref.root_source_uri) != TYPE_STRING or level_ref.root_source_uri.is_empty(): return {}
	var identity: Variant = snapshot.get("identity")
	if not Schemas._fields(identity, ["run_id","snapshot_id","source_fingerprint","source_intent_digest"]): return {}
	for field in ["run_id","snapshot_id"]:
		if typeof(identity[field]) != TYPE_STRING or not _uuid(identity[field]): return {}
	if not _digest(identity.source_fingerprint) or (identity.source_intent_digest != null and not _digest(identity.source_intent_digest)): return {}
	return {"editor_instance_id":editor_id,"run_id":identity.run_id,"generation":generation,
		"level_ref":level_ref.duplicate(true),"snapshot_id":identity.snapshot_id,
		"source_fingerprint":identity.source_fingerprint,"policy_digest":policy_digest,
		"execution_digest":execution_digest,"versions":versions.duplicate(true)}

## Unrun stage skeleton: callers preserve real native results and actual budgets.
static func make_stage_record(stage_id: String, owner: String, module_ref: String) -> Dictionary:
	if stage_id not in Schemas.STAGES or owner.is_empty() or module_ref.is_empty(): return {}
	return {"stage_id":stage_id,"owner":owner,"module_ref":module_ref,"applicability":"APPLICABLE",
		"execution":"NOT_RUN","reason":"","input_refs":{},"actual_policy":{},"actual_budget":{},
		"native_result":null,"evidence_refs":[],"warnings":[],"started_at":null,"finished_at":null}

static func _digest(value: Variant) -> bool:
	if typeof(value) != TYPE_STRING or value.length() != 64: return false
	for c in value:
		if c not in "0123456789abcdef": return false
	return true

static func _uuid(value: String) -> bool:
	if value.length() != 36: return false
	for i in 36:
		if i in [8,13,18,23]:
			if value[i] != "-": return false
		elif value[i] not in "0123456789abcdef": return false
	return true
