extends RefCounted
const Schema = preload("res://foundation/authoring/authoring_schema.gd")
const NAMED := {"LEVEL": "level_id", "CUBE": "cube_id", "SLOT": "slot_id", "GROUP": "group_id", "MECHANISM": "mechanism_id", "TRANSITION": "transition_id", "INTENT": "intent_id", "MILESTONE": "milestone_id", "BYPASS": "bypass_id"}

static func allocate(entity_kind: String, existing_ids: Array[StringName]) -> Dictionary:
	if not NAMED.has(entity_kind) and entity_kind not in ["FACE", "MECHANISM_CONFIG", "WORLD"]:
		return Schema.failure("UNSUPPORTED_ENTITY_KIND", "entity_kind", "Unknown authoring identity kind.")
	for occupied in existing_ids:
		if not Schema.valid_id(occupied):
			return Schema.failure("INVALID_ID", "existing_ids", "Occupied identities must satisfy the formal ID grammar.")
	var id: StringName = &""
	if NAMED.has(entity_kind):
		var suffix := 1
		id = StringName(entity_kind.to_lower() + "_" + str(suffix))
		while id in existing_ids:
			suffix += 1
			id = StringName(entity_kind.to_lower() + "_" + str(suffix))
	var bytes := Crypto.new().generate_random_bytes(16)
	if bytes.size() != 16:
		return Schema.failure("IDENTITY_ALLOCATION_FAILED", "authoring_id", "Could not allocate author identity.")
	bytes[6] = (bytes[6] & 15) | 64
	bytes[8] = (bytes[8] & 63) | 128
	var hex := bytes.hex_encode()
	var uuid := "%s-%s-%s-%s-%s" % [hex.substr(0, 8), hex.substr(8, 4), hex.substr(12, 4), hex.substr(16, 4), hex.substr(20, 12)]
	return {"ok": true, "value": {"authoring_id": uuid, "entity_id": id}, "issues": []}
