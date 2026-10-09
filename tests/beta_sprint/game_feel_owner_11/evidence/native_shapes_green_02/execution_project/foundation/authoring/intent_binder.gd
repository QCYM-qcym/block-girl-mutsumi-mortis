extends RefCounted
## Pure same-capture binding. The caller supplies a 4D-verified identity and
## both author values from the same Payload; format checks do not authenticate it.
const Schema = preload("res://foundation/authoring/authoring_schema.gd")
const Data = preload("res://foundation/contracts/contract_validation.gd")
const Geometry = preload("res://foundation/spatial/surface_geometry.gd")
const IntentTypes = preload("res://foundation/quality/intent/intent_types.gd")
const IntentValidation = preload("res://foundation/quality/intent/intent_validation.gd")
const ValidationTypes = preload("res://foundation/validation/validation_types.gd")

static func bind_intent(authoring_intent: Dictionary, resource_table: Array[Dictionary], successful_bake: Dictionary, snapshot_identity: Dictionary) -> Dictionary:
	if not Schema.exact(snapshot_identity, ["run_id", "snapshot_id", "source_fingerprint", "source_intent_digest"]) or not _provenance(snapshot_identity, false) or not _digest(snapshot_identity.source_intent_digest):
		return _failure("SNAPSHOT_IDENTITY_INVALID", "snapshot_identity", "Present Intent requires explicit same-capture identity and source digest.")
	if not Schema.pure(successful_bake) or not Schema.exact(successful_bake, ["ok", "level", "issues", "validation", "source_map", "bake_provenance"]) or typeof(successful_bake.ok) != TYPE_BOOL or not successful_bake.ok or not successful_bake.level is Dictionary or not successful_bake.issues is Array or not successful_bake.issues.is_empty():
		return _failure("BAKE_INVALID", "successful_bake", "Expected the current successful six-field Bake result.")
	if not Data.validate_level_shape(successful_bake.level).is_empty():
		return _failure("BAKE_INVALID", "successful_bake.level", "Expected a formal LevelDefinition.")
	var validation: Variant = successful_bake.validation
	if not Schema.exact(validation, ["status", "issues", "configurations_checked", "checks_performed"]) or typeof(validation.status) != TYPE_INT or validation.status != ValidationTypes.ValidationStatus.VALID or not validation.issues is Array or not validation.issues.is_empty():
		return _failure("BAKE_INVALID", "successful_bake.validation", "Expected formal VALID validation with no issues.")
	for field in ["configurations_checked", "checks_performed"]:
		if typeof(validation[field]) != TYPE_INT or validation[field] < 0:
			return _failure("BAKE_INVALID", "successful_bake.validation." + field, "Expected a nonnegative execution count.")
	var provenance: Variant = successful_bake.bake_provenance
	if not _provenance(provenance):
		return _failure("BAKE_PROVENANCE_INVALID", "bake_provenance", "Expected the producer's closed three-field provenance.")
	for field in ["run_id", "snapshot_id", "source_fingerprint"]:
		if provenance[field] != snapshot_identity[field]:
			return _failure("BAKE_PROVENANCE_MISMATCH", "bake_provenance." + field, "Bake and snapshot identities differ.")
	var source_map: Variant = successful_bake.source_map
	if not Schema.exact(source_map, ["map_version", "snapshot_id", "source_fingerprint", "level_hash", "entries"]) or source_map.map_version != "authoringsourcemap.v1" or not source_map.entries is Array or source_map.level_hash != successful_bake.level.content_hash:
		return _failure("SOURCE_MAP_INVALID", "source_map", "Expected this Bake's source map and level hash.")
	for field in ["snapshot_id", "source_fingerprint"]:
		if typeof(source_map[field]) != TYPE_STRING or source_map[field] != provenance[field]:
			return _failure("BAKE_PROVENANCE_MISMATCH", "source_map." + field, "Source map and producer identities differ.")
	if not Schema.fields_valid("INTENT", authoring_intent):
		return _failure("INVALID_INTENT", "authoring_intent", "Expected a complete explicit author Intent.")
	var resources := {}
	var semantic_ids := {}
	var matching_roots := 0
	for entry in resource_table:
		if not Schema.exact(entry, Schema.RESOURCE_FIELDS) or not entry.kind is String or entry.kind not in Schema.RESOURCE_KINDS or not Schema.valid_uuid(entry.authoring_id) or not entry.document_uri is String or not (entry.resource_uid == null or entry.resource_uid is String) or not Schema.fields_valid(entry.kind, entry.fields):
			return _failure("INVALID_RESOURCE", "resource_table", "Expected closed author ResourceEntry values.")
		if resources.has(entry.authoring_id):
			return _failure("RESOURCE_VERSION_CONFLICT", entry.authoring_id, "Author identity must occur exactly once.")
		resources[entry.authoring_id] = entry
		if entry.kind == "INTENT" and entry.fields == authoring_intent:
			matching_roots += 1
		for field in ["intent_id", "milestone_id", "bypass_id"]:
			if entry.fields.has(field):
				var key: String = field + ":" + String(entry.fields[field])
				if semantic_ids.has(key):
					return _failure("DUPLICATE_ID", entry.authoring_id, "Semantic resource identities must be unique.")
				semantic_ids[key] = true
	if matching_roots != 1:
		return _failure("INVALID_INTENT", "authoring_intent", "Author declaration must match exactly one INTENT in this table.")
	# Existing closed MILESTONE/BYPASS fields contain no further resource refs;
	# checking every INTENT edge exhausts the allowed semantic reference graph.
	for entry in resource_table:
		if entry.kind != "INTENT":
			continue
		for field in ["expected_milestones", "forbidden_bypasses"]:
			var expected := "MILESTONE" if field == "expected_milestones" else "BYPASS"
			var seen := {}
			for ref in entry.fields[field]:
				if not Schema.exact(ref, ["resource_ref"]) or not ref.resource_ref is String or not resources.has(ref.resource_ref) or resources[ref.resource_ref].kind != expected or seen.has(ref.resource_ref):
					return _failure("INVALID_REFERENCE", entry.authoring_id + "." + field, "References require distinct resources of the declared kind.")
				seen[ref.resource_ref] = true
	var intent := {"intent_version": "puzzleintent.v1", "intent_id": authoring_intent.intent_id, "level_hash": successful_bake.level.content_hash, "rule_version": successful_bake.level.rule_version, "required_mechanics": _tags(authoring_intent.required_mechanics), "optional_mechanics": _tags(authoring_intent.optional_mechanics), "expected_milestones": [], "forbidden_bypasses": []}
	for ref in authoring_intent.expected_milestones:
		var fields: Dictionary = resources[ref.resource_ref].fields
		var predicate: Dictionary = fields.predicate.duplicate(true)
		if predicate.kind == IntentTypes.PredicateKind.AT_FACE:
			predicate = {"kind": predicate.kind, "face_id": Geometry.face_id(predicate.face_ref.cube_id, predicate.face_ref.face)}
		intent.expected_milestones.append({"milestone_id": fields.milestone_id, "required": fields.required, "predicate": predicate})
	for ref in authoring_intent.forbidden_bypasses:
		var fields: Dictionary = resources[ref.resource_ref].fields
		intent.forbidden_bypasses.append({"bypass_id": fields.bypass_id, "disabled_mechanics": _tags(fields.disabled_mechanics)})
	var checked := IntentValidation.validate(successful_bake.level, intent)
	if not checked.ok:
		return {"ok": false, "bound_intent": null, "source_intent_digest": null, "issues": [Schema.issue("INVALID_INTENT", "bound_intent", "Converted constraints fail formal IntentValidation.").merged({"upstream": checked.issues}, true)]}
	return {"ok": true, "bound_intent": intent, "source_intent_digest": snapshot_identity.source_intent_digest, "issues": []}

static func _provenance(value: Variant, closed: bool = true) -> bool:
	if not value is Dictionary or (closed and not Schema.exact(value, ["run_id", "snapshot_id", "source_fingerprint"])):
		return false
	return value.get("run_id") is String and not value.run_id.is_empty() and value.get("snapshot_id") is String and not value.snapshot_id.is_empty() and _digest(value.get("source_fingerprint"))

static func _digest(value: Variant) -> bool:
	if typeof(value) != TYPE_STRING or value.length() != 64:
		return false
	for character in value:
		if character not in "0123456789abcdef":
			return false
	return true

static func _tags(value: Array) -> Array:
	var result := value.duplicate()
	result.sort()
	return result

static func _failure(code: String, path: String, message: String) -> Dictionary:
	return {"ok": false, "bound_intent": null, "source_intent_digest": null, "issues": [Schema.issue(code, path, message)]}


