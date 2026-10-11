extends RefCounted
const Types = preload("res://foundation/contracts/foundation_types.gd")
const Math = preload("res://foundation/orientation/discrete_orientation.gd")
const Feel = preload("res://foundation/game_feel/schema.gd")
const IntentTypes = preload("res://foundation/quality/intent/intent_types.gd")
## Closed author declarations. Spatial legality, rules and hashes belong to existing modules.
const SCRIPTS := {
	"LEVEL": "level_authoring_root.gd", "WORLD": "world_authoring_root.gd",
	"CUBE": "cube_authoring_node.gd", "SLOT": "slot_authoring_node.gd",
	"GROUP": "group_authoring_node.gd", "MECHANISM": "mechanism_authoring_node.gd",
	"TRANSITION": "transition_authoring_node.gd", "FACE": "face_authoring_resource.gd",
	"MECHANISM_CONFIG": "mechanism_config.gd", "INTENT": "intent_authoring_resource.gd",
	"MILESTONE": "milestone_authoring_resource.gd", "BYPASS": "bypass_authoring_resource.gd"
}
const RESOURCE_KINDS := ["FACE", "MECHANISM_CONFIG", "INTENT", "MILESTONE", "BYPASS"]
const FIELDS := {
	"LEVEL": {"authoring_version": TYPE_STRING, "level_id": TYPE_STRING_NAME, "schema_version": TYPE_INT, "contract_version": TYPE_STRING, "orientation_version": TYPE_STRING, "rule_version": TYPE_STRING, "cell_size": TYPE_INT, "shift_compatibilities": TYPE_ARRAY, "flag_definitions": TYPE_ARRAY, "build_info": TYPE_DICTIONARY, "surface_source": TYPE_STRING, "inner_source": TYPE_STRING, "intent": TYPE_NIL, "spawn": TYPE_DICTIONARY, "goal": TYPE_DICTIONARY, "celestial": TYPE_DICTIONARY},
	"WORLD": {"layer": TYPE_INT, "pivot2": TYPE_VECTOR3I, "initial_orientation": TYPE_INT, "allowed_states": TYPE_ARRAY, "allowed_rotation_deltas": TYPE_ARRAY, "allowed_rotation_intents": TYPE_ARRAY},
	"CUBE": {"cube_id": TYPE_STRING_NAME, "occludes_light": TYPE_BOOL, "tags": TYPE_ARRAY, "transform": TYPE_TRANSFORM3D, "faces": TYPE_ARRAY},
	"SLOT": {"slot_id": TYPE_STRING_NAME, "transform": TYPE_TRANSFORM3D},
	"GROUP": {"group_id": TYPE_STRING_NAME, "cube_ids": TYPE_ARRAY, "pivot2": TYPE_VECTOR3I, "initial_orientation": TYPE_INT, "allowed_states": TYPE_ARRAY, "allowed_rotation_deltas": TYPE_ARRAY, "edges": TYPE_ARRAY},
	"MECHANISM": {"mechanism_id": TYPE_STRING_NAME, "host_face": TYPE_DICTIONARY, "trigger": TYPE_STRING_NAME, "priority": TYPE_INT, "config": TYPE_DICTIONARY, "target_bindings": TYPE_DICTIONARY},
	"TRANSITION": {"transition_id": TYPE_STRING_NAME, "source": TYPE_DICTIONARY, "target": TYPE_DICTIONARY, "entry_axis": TYPE_INT, "exit_axis": TYPE_INT, "rotation_steps": TYPE_ARRAY, "required_flags": TYPE_ARRAY},
	"FACE": {"face": TYPE_INT, "walkable": TYPE_BOOL, "shift_exit_blocked": TYPE_BOOL, "shift_entry_blocked": TYPE_BOOL},
	"MECHANISM_CONFIG": {"kind": TYPE_INT, "initial_state": TYPE_STRING_NAME, "allowed_states": TYPE_ARRAY},
	"INTENT": {"authoring_version": TYPE_STRING, "intent_id": TYPE_STRING_NAME, "required_mechanics": TYPE_ARRAY, "optional_mechanics": TYPE_ARRAY, "expected_milestones": TYPE_ARRAY, "forbidden_bypasses": TYPE_ARRAY},
	"MILESTONE": {"milestone_id": TYPE_STRING_NAME, "required": TYPE_BOOL, "predicate": TYPE_DICTIONARY},
	"BYPASS": {"bypass_id": TYPE_STRING_NAME, "disabled_mechanics": TYPE_ARRAY}
}
const SPATIAL_LEVEL_TYPES := {"camera_initial_quadrant":TYPE_INT,"perspective_falls":TYPE_ARRAY,"shift_gates":TYPE_ARRAY}
const LOCK_CONFIG_TYPES := {"required_local_face":TYPE_INT,"activation_mode":TYPE_STRING_NAME,"latched_state":TYPE_STRING_NAME}
const DOCUMENT_FIELDS := ["authoring_version", "document_uri", "document_authoring_id", "kind", "root_transform", "records", "resources", "dependencies", "override_paths"]
const RESOURCE_FIELDS := ["authoring_id", "kind", "document_uri", "resource_uid", "fields"]
const RECORD_FIELDS := ["kind", "authoring_id", "node_path", "label", "fields"]

static func issue(code: String, path: String, message: String) -> Dictionary:
	return {"code": code, "stage": "AUTHORING", "path": path, "message": message, "source_refs": [], "upstream": []}

static func failure(code: String, path: String, message: String) -> Dictionary:
	return {"ok": false, "value": null, "issues": [issue(code, path, message)]}

static func exact(value: Variant, keys: Array) -> bool:
	if not value is Dictionary or value.size() != keys.size():
		return false
	for key in value:
		if typeof(key) != TYPE_STRING or key not in keys:
			return false
	return true

static func valid_id(value: Variant) -> bool:
	if typeof(value) != TYPE_STRING_NAME:
		return false
	var pattern := RegEx.new()
	pattern.compile("\\A[a-z][a-z0-9_]*\\z")
	return pattern.search(String(value)) != null

static func valid_uuid(value: Variant) -> bool:
	if typeof(value) != TYPE_STRING:
		return false
	var pattern := RegEx.new()
	pattern.compile("\\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\\z")
	return pattern.search(value) != null

static func script_path(kind: String) -> String:
	return "res://foundation/authoring/" + SCRIPTS[kind] if SCRIPTS.has(kind) else ""

static func kind_of(script: Variant) -> String:
	if not script is Script:
		return ""
	for kind in SCRIPTS:
		if script.resource_path == script_path(kind):
			return kind
	return ""

static func field_types(kind: String, declarations: Dictionary = {}) -> Dictionary:
	var fields: Dictionary = FIELDS[kind].duplicate()
	if kind == "LEVEL" and Feel.spatial(declarations): fields.merge(SPATIAL_LEVEL_TYPES)
	if kind == "MECHANISM_CONFIG":
		if declarations.get("kind") == Types.PuzzleActionKind.TRIGGER_MECHANISM: fields.merge(LOCK_CONFIG_TYPES)
		if declarations.get("kind") == Types.PuzzleActionKind.LOCAL_GROUP_ROTATE:
			fields["rotation_delta"] = TYPE_INT
		elif declarations.get("kind") == Types.PuzzleActionKind.MOVE_CELESTIAL:
			fields["celestial_op"] = TYPE_INT
	return fields

static func property_list(kind: String, declarations: Dictionary = {}) -> Array[Dictionary]:
	# Dynamic exported properties retain presence: absent is not a false/empty default.
	var result: Array[Dictionary] = [{"name": "authoring_id", "type": TYPE_STRING, "usage": PROPERTY_USAGE_DEFAULT}]
	var fields := field_types(kind, declarations)
	if kind == "MECHANISM_CONFIG":
		for key in ["rotation_delta", "celestial_op"]:
			if declarations.has(key):
				fields[key] = TYPE_INT
	if kind == "LEVEL":
		for key in SPATIAL_LEVEL_TYPES:
			if declarations.has(key): fields[key]=SPATIAL_LEVEL_TYPES[key]
	if kind == "MECHANISM_CONFIG":
		for key in LOCK_CONFIG_TYPES:
			if declarations.has(key): fields[key]=LOCK_CONFIG_TYPES[key]
	for key in fields:
		if key == "transform":
			continue
		var type: int = fields[key]
		if key in ["intent", "config"]:
			type = TYPE_OBJECT
		result.append({"name": key, "type": type, "usage": PROPERTY_USAGE_DEFAULT})
	return result

static func pure(value: Variant, ancestors: Array = []) -> bool:
	if value is Array or value is Dictionary:
		for ancestor in ancestors:
			if is_same(value, ancestor):
				return false
		var next := ancestors.duplicate()
		next.append(value)
		if value is Dictionary:
			for key in value:
				if typeof(key) != TYPE_STRING or not pure(value[key], next):
					return false
		else:
			for item in value:
				if not pure(item, next):
					return false
		return true
	return typeof(value) in [TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_STRING_NAME, TYPE_VECTOR3I, TYPE_VECTOR3, TYPE_BASIS, TYPE_TRANSFORM3D]

static func fields_valid(kind: String, fields: Variant) -> bool:
	if not FIELDS.has(kind) or not fields is Dictionary or not pure(fields):
		return false
	var types := field_types(kind, fields)
	if not exact(fields, types.keys()):
		return false
	for key in types:
		var type: int = types[key]
		if type != TYPE_NIL and typeof(fields[key]) != type:
			return false
		if key.ends_with("_id") and not valid_id(fields[key]):
			return false
	if kind == "LEVEL":
		var spatial := Feel.spatial(fields)
		if fields.authoring_version != "levelauthoring.v1" or fields.orientation_version != "cube24.v1" or fields.cell_size <= 0 or (not spatial and (fields.schema_version != 1 or fields.contract_version != "foundation.contract.v1" or fields.rule_version != "foundation.rules.v1")):
			return false
		if spatial and fields.camera_initial_quadrant not in range(4): return false
		if not exact(fields.spawn, ["face_ref", "orientation"]) or not face_ref(fields.spawn.face_ref) or not orientation(fields.spawn.orientation) or not exact(fields.goal, ["face_ref", "required_flags"]) or not face_ref(fields.goal.face_ref) or not id_array(fields.goal.required_flags):
			return false
		if not exact(fields.celestial, ["slot_order", "wrap", "initial_slot_id", "edges"]) or not id_array(fields.celestial.slot_order) or typeof(fields.celestial.wrap) != TYPE_BOOL or not valid_id(fields.celestial.initial_slot_id) or not fields.celestial.edges is Array:
			return false
		for edge in fields.celestial.edges:
			if not exact(edge, ["from_slot_id", "to_slot_id"]) or not valid_id(edge.from_slot_id) or not valid_id(edge.to_slot_id):
				return false
		for flag in fields.flag_definitions:
			if not exact(flag, ["flag_id", "initial_value"]) or not valid_id(flag.flag_id) or typeof(flag.initial_value) != TYPE_BOOL:
				return false
		return enum_array(fields.shift_compatibilities, Types.FaceCompatibility.values()) and (fields.intent == null or exact(fields.intent, ["resource_ref"]))
	if kind == "FACE":
		return fields.face >= 0 and fields.face < 6
	if kind in ["WORLD", "GROUP"]:
		if not orientation(fields.initial_orientation) or not enum_array(fields.allowed_states, range(24)) or not enum_array(fields.allowed_rotation_deltas, quarter_values()):
			return false
		if kind == "WORLD":
			return fields.layer in Types.WorldLayer.values() and enum_array(fields.allowed_rotation_intents, Types.RotationIntent.values())
		if not id_array(fields.cube_ids):
			return false
		for edge in fields.edges:
			if not exact(edge, ["from_orientation", "rotation_delta", "to_orientation"]) or not orientation(edge.from_orientation) or not orientation(edge.to_orientation) or not quarter(edge.rotation_delta):
				return false
		return true
	if kind == "CUBE":
		for tag in fields.tags:
			if typeof(tag) != TYPE_STRING_NAME:
				return false
	if kind == "MECHANISM":
		return face_ref(fields.host_face) and fields.trigger in [&"ENTER", &"USE"] and exact(fields.config, ["resource_ref"])
	if kind == "TRANSITION":
		return face_ref(fields.source) and face_ref(fields.target) and fields.entry_axis in Types.FaceAxis.values() and fields.exit_axis in Types.FaceAxis.values() and id_array(fields.required_flags) and enum_array(fields.rotation_steps, quarter_values(), false)
	if kind == "MECHANISM_CONFIG":
		if fields.kind == Types.PuzzleActionKind.TRIGGER_MECHANISM:
			return fields.initial_state != &"" and fields.latched_state != &"" and fields.initial_state != fields.latched_state and fields.allowed_states.size() == 2 and fields.initial_state in fields.allowed_states and fields.latched_state in fields.allowed_states and fields.required_local_face in range(6) and fields.activation_mode == &"LATCH_ON_SUCCESS"
		if fields.initial_state == &"" or fields.allowed_states.size() != 1 or typeof(fields.allowed_states[0]) != TYPE_STRING_NAME or fields.allowed_states[0] != fields.initial_state:
			return false
		match fields.kind:
			Types.PuzzleActionKind.LOCAL_GROUP_ROTATE: return quarter(fields.rotation_delta)
			Types.PuzzleActionKind.MOVE_CELESTIAL: return fields.celestial_op in Types.CelestialOp.values()
			Types.PuzzleActionKind.USE_FACE_TRANSITION: return true
		return false
	if kind == "INTENT":
		if fields.authoring_version != "puzzleintentauthoring.v1" or not enum_array(fields.required_mechanics, IntentTypes.MechanicTag.values()) or not enum_array(fields.optional_mechanics, IntentTypes.MechanicTag.values()):
			return false
		for tag in fields.required_mechanics:
			if tag in fields.optional_mechanics:
				return false
	if kind == "MILESTONE":
		return predicate(fields.predicate)
	if kind == "BYPASS":
		return not fields.disabled_mechanics.is_empty() and enum_array(fields.disabled_mechanics, IntentTypes.MechanicTag.values())
	return true

static func enum_array(value: Variant, allowed: Array, unique: bool = true) -> bool:
	if not value is Array:
		return false
	var seen := {}
	for item in value:
		if typeof(item) != TYPE_INT or item not in allowed or (unique and seen.has(item)):
			return false
		seen[item] = true
	return true

static func id_array(value: Variant) -> bool:
	if not value is Array:
		return false
	var seen := {}
	for id in value:
		if not valid_id(id) or seen.has(id):
			return false
		seen[id] = true
	return true

static func orientation(value: Variant) -> bool:
	return typeof(value) == TYPE_INT and value >= 0 and value < 24

static func quarter(value: Variant) -> bool:
	return typeof(value) == TYPE_INT and value in quarter_values()

static func quarter_values() -> Array:
	var values: Array = []
	for axis in [0, 1, 2]:
		for sign_value in [-1, 1]:
			values.append(Math.quarter_turn(axis, sign_value))
	return values

static func face_ref(value: Variant) -> bool:
	return exact(value, ["cube_id", "face"]) and valid_id(value.cube_id) and typeof(value.face) == TYPE_INT and value.face in Types.FaceDirection.values()

static func predicate(value: Variant) -> bool:
	if not value is Dictionary or typeof(value.get("kind")) != TYPE_INT:
		return false
	match value.kind:
		IntentTypes.PredicateKind.AT_FACE:
			return exact(value, ["kind", "face_ref"]) and face_ref(value.face_ref)
		IntentTypes.PredicateKind.IN_LAYER:
			return exact(value, ["kind", "layer"]) and typeof(value.layer) == TYPE_INT and value.layer in Types.WorldLayer.values()
		IntentTypes.PredicateKind.FACE_LIGHT:
			return exact(value, ["kind", "light_state"]) and typeof(value.light_state) == TYPE_INT and value.light_state in Types.LightState.values()
		IntentTypes.PredicateKind.MECHANIC_USED:
			return exact(value, ["kind", "mechanic"]) and typeof(value.mechanic) == TYPE_INT and value.mechanic in IntentTypes.MechanicTag.values()
		IntentTypes.PredicateKind.GOAL:
			return exact(value, ["kind"])
	return false

static func validate_authoring(payload: Dictionary) -> Dictionary:
	var result := _validate(payload)
	return {"ok": result.ok, "issues": result.issues}

static func _validate(payload: Dictionary) -> Dictionary:
	if not pure(payload) or not exact(payload, ["authoring_version", "level_ref", "documents", "resource_table"]):
		return failure("INVALID_AUTHORING", "payload", "Expected closed pure authoring payload.")
	if payload.authoring_version != "levelauthoring.v1" or not payload.documents is Array or not payload.resource_table is Array:
		return failure("INVALID_AUTHORING", "payload", "Unknown version or collection type.")
	if not exact(payload.level_ref, ["level_authoring_id", "level_id", "root_source_uri"]) or not valid_uuid(payload.level_ref.level_authoring_id) or not valid_id(payload.level_ref.level_id) or not payload.level_ref.root_source_uri is String:
		return failure("INVALID_AUTHORING", "level_ref", "Expected explicit level identity.")
	var resources := {}
	for resource in payload.resource_table:
		if not exact(resource, RESOURCE_FIELDS) or not resource.kind is String or resource.kind not in RESOURCE_KINDS or not valid_uuid(resource.authoring_id) or not resource.document_uri is String or not (resource.resource_uid == null or resource.resource_uid is String) or not fields_valid(resource.kind, resource.fields):
			return failure("INVALID_RESOURCE", "resource_table", "Unknown resource kind or incomplete fields.")
		if resources.has(resource.authoring_id):
			return failure("RESOURCE_VERSION_CONFLICT", resource.authoring_id, "Resource identity must be unique.")
		resources[resource.authoring_id] = resource
	for id in resources:
		var refs := _references(resources[id].fields, resources, [id])
		if not refs.ok:
			return refs
	var uris := {}
	var identities := {}
	var entities := {}
	var cubes := {}
	var face_owners := {}
	var world_layers := {}
	var level_fields := {}
	for doc in payload.documents:
		if not exact(doc, DOCUMENT_FIELDS) or doc.authoring_version != "levelauthoring.v1" or not doc.document_uri is String or not valid_uuid(doc.document_authoring_id) or doc.kind not in ["LEVEL", "WORLD", "INTENT", "CONFIG"] or not doc.root_transform is Transform3D or not doc.records is Array or not doc.resources is Array or not doc.dependencies is Array or not doc.override_paths is Array:
			return failure("INVALID_DOCUMENT", "documents", "Incomplete closed document.")
		if not doc.override_paths.is_empty():
			return failure("UNSUPPORTED_AUTHORING_OVERRIDE", doc.document_uri, "Gameplay instance overrides are unsupported.")
		if uris.has(doc.document_uri):
			return failure("DUPLICATE_DOCUMENT", doc.document_uri, "Document URI appears twice.")
		uris[doc.document_uri] = doc
		if doc.kind != "LEVEL" and doc.root_transform != Transform3D.IDENTITY:
			return failure("INVALID_HIERARCHY", doc.document_uri, "World and resource roots require identity.")
		if doc.kind in ["LEVEL", "WORLD"]:
			if doc.records.is_empty() or not doc.records[0] is Dictionary or doc.records[0].get("kind") != doc.kind or doc.records[0].get("authoring_id") != doc.document_authoring_id:
				return failure("INVALID_DOCUMENT", doc.document_uri, "Document root record must match its identity.")
		elif not doc.records.is_empty() or not resources.has(doc.document_authoring_id):
			return failure("INVALID_DOCUMENT", doc.document_uri, "Resource documents have no spatial records.")
		for r in doc.resources:
			if not r is Dictionary or not resources.has(r.get("authoring_id")) or resources[r.authoring_id] != r:
				return failure("RESOURCE_VERSION_CONFLICT", doc.document_uri, "Document resource disagrees with resource table.")
		var node_paths := {}
		for record in doc.records:
			if not record is Dictionary or not record.get("node_path") is String:
				return failure("INVALID_RECORD", doc.document_uri, "Node path is missing.")
			var path: String = record.node_path
			if path.is_empty() or path.begins_with("/") or path.begins_with("./") or ".." in path.split("/") or node_paths.has(path):
				return failure("INVALID_HIERARCHY", path, "Node paths must be distinct and root relative.")
			node_paths[path] = true
		for path in node_paths:
			for parent in node_paths:
				if parent != "." and path.begins_with(parent + "/"):
					return failure("INVALID_HIERARCHY", path, "Gameplay records cannot be spatial ancestors.")
		for record in doc.records:
			if not exact(record, RECORD_FIELDS) or not record.kind is String or not valid_uuid(record.authoring_id) or not record.node_path is String or not record.label is String or record.kind in RESOURCE_KINDS or not fields_valid(record.kind, record.fields):
				return failure("INVALID_RECORD", doc.document_uri, "Unknown or incomplete node declaration.")
			if identities.has(record.authoring_id) or resources.has(record.authoring_id):
				return failure("DUPLICATE_ID", record.authoring_id, "Author identity appears twice.")
			identities[record.authoring_id] = true
			var f: Dictionary = record.fields
			var refs := _references(f, resources, [])
			if not refs.ok:
				return refs
			for field in ["cube_id", "slot_id", "group_id", "mechanism_id", "transition_id", "level_id"]:
				if f.has(field):
					var key: String = field + ":" + String(f[field])
					if entities.has(key):
						return failure("DUPLICATE_ID", key, "Formal identity appears twice.")
					entities[key] = true
			if record.kind == "LEVEL":
				if doc.document_uri != payload.level_ref.root_source_uri or record.authoring_id != payload.level_ref.level_authoring_id or f.level_id != payload.level_ref.level_id or not level_fields.is_empty():
					return failure("INVALID_DOCUMENT", doc.document_uri, "Level reference does not identify one root.")
				level_fields = f
			elif doc.kind != "WORLD":
				return failure("INVALID_HIERARCHY", doc.document_uri, "Gameplay nodes belong to independent worlds.")
			if record.kind == "WORLD":
				if world_layers.has(f.layer):
					return failure("DUPLICATE_WORLD", doc.document_uri, "Each layer has one independent source.")
				world_layers[f.layer] = doc.document_uri
			if record.kind == "CUBE":
				cubes[f.cube_id] = doc
				if f.faces.size() != 6:
					return failure("INVALID_FACES", record.authoring_id, "Exactly six explicit faces are required.")
				var directions := {}
				for ref in f.faces:
					if not exact(ref, ["resource_ref"]) or not resources.has(ref.resource_ref) or resources[ref.resource_ref].kind != "FACE":
						return failure("INVALID_FACES", record.authoring_id, "Cube requires Face resources.")
					var face: Dictionary = resources[ref.resource_ref]
					if directions.has(face.fields.face) or face_owners.has(ref.resource_ref):
						return failure("INVALID_FACES", record.authoring_id, "Faces cannot repeat or share mutable ownership.")
					directions[face.fields.face] = true
					face_owners[ref.resource_ref] = record.authoring_id
	if level_fields.is_empty() or world_layers.size() != 2 or level_fields.surface_source != world_layers.get(0) or level_fields.inner_source != world_layers.get(1):
		return failure("MISSING_WORLD", "documents", "Level must reference both unique source worlds.")
	if not cubes.has(level_fields.spawn.face_ref.cube_id) or not cubes.has(level_fields.goal.face_ref.cube_id):
		return failure("INVALID_REFERENCE", "spawn/goal", "Player and exit require existing Cube faces.")
	var flags := {}
	for flag in level_fields.flag_definitions:
		if flags.has(flag.flag_id):
			return failure("DUPLICATE_ID", "flag_definitions", "Flag identity must be unique.")
		flags[flag.flag_id] = true
	for id in level_fields.goal.required_flags:
		if not flags.has(id):
			return failure("INVALID_REFERENCE", "goal.required_flags", "Goal requires a declared flag.")
	for id in level_fields.celestial.slot_order:
		if not entities.has("slot_id:" + String(id)):
			return failure("INVALID_REFERENCE", "celestial.slot_order", "Celestial slot does not exist.")
	if level_fields.celestial.initial_slot_id not in level_fields.celestial.slot_order:
		return failure("INVALID_REFERENCE", "celestial.initial_slot_id", "Initial slot is absent from declared order.")
	for edge in level_fields.celestial.edges:
		if edge.from_slot_id not in level_fields.celestial.slot_order or edge.to_slot_id not in level_fields.celestial.slot_order:
			return failure("INVALID_REFERENCE", "celestial.edges", "Celestial edge requires declared slots.")
	if level_fields.intent != null and resources[level_fields.intent.resource_ref].kind != "INTENT":
		return failure("INVALID_REFERENCE", "intent", "Level Intent reference requires Intent resource.")
	var resource_ids := {}
	for id in resources:
		var resource: Dictionary = resources[id]
		if not uris.has(resource.document_uri):
			return failure("MISSING_DOCUMENT", resource.document_uri, "Semantic resource belongs outside the closure.")
		var owner: Dictionary = uris[resource.document_uri]
		if owner.kind in ["INTENT", "CONFIG"] and resources.has(owner.document_authoring_id):
			var root_resource: Dictionary = resources[owner.document_authoring_id]
			if resource.kind == root_resource.kind and id != owner.document_authoring_id:
				return failure("RESOURCE_VERSION_CONFLICT", resource.document_uri, "One external resource document has conflicting root identities.")
		for field in ["intent_id", "milestone_id", "bypass_id"]:
			if resource.fields.has(field):
				var key: String = field + ":" + String(resource.fields[field])
				if resource_ids.has(key):
					return failure("DUPLICATE_ID", key, "Semantic identity is not unique.")
				resource_ids[key] = true
		if resource.kind == "INTENT":
			for field in ["expected_milestones", "forbidden_bypasses"]:
				var expected := "MILESTONE" if field == "expected_milestones" else "BYPASS"
				var seen := {}
				for ref in resource.fields[field]:
					if not exact(ref, ["resource_ref"]) or not resources.has(ref.resource_ref) or resources[ref.resource_ref].kind != expected or seen.has(ref.resource_ref):
						return failure("INVALID_REFERENCE", field, "Intent requires unique resources of the declared kind.")
					seen[ref.resource_ref] = true
		if resource.kind == "MILESTONE" and resource.fields.predicate.kind == IntentTypes.PredicateKind.AT_FACE and not cubes.has(resource.fields.predicate.face_ref.cube_id):
			return failure("INVALID_REFERENCE", id, "Milestone face requires an existing Cube.")
	var grouped := {}
	for doc in payload.documents:
		for uri in doc.dependencies:
			if not uri is String or not uris.has(uri):
				return failure("MISSING_DOCUMENT", doc.document_uri, "Dependency is absent from this closure.")
		for record in doc.records:
			if record.kind == "GROUP":
				var seen := {}
				for id in record.fields.cube_ids:
					if not valid_id(id) or not cubes.has(id) or cubes[id].document_uri != doc.document_uri or seen.has(id) or grouped.has(id):
						return failure("INVALID_REFERENCE", record.authoring_id, "Group members must be unique cubes in the same world.")
					seen[id] = true
					grouped[id] = true
			if record.kind == "MECHANISM":
				var f: Dictionary = record.fields
				if not cubes.has(f.host_face.cube_id) or cubes[f.host_face.cube_id].document_uri != doc.document_uri or resources[f.config.resource_ref].kind != "MECHANISM_CONFIG":
					return failure("INVALID_REFERENCE", record.authoring_id, "Mechanism host and config must resolve.")
				var kind: int = resources[f.config.resource_ref].fields.kind
				if kind == Types.PuzzleActionKind.TRIGGER_MECHANISM and (not Feel.spatial(level_fields) or f.trigger != &"ENTER"):
					return failure("INVALID_REFERENCE",record.authoring_id,"Face Lock requires the opt-in Level and ENTER trigger.")
				var target_fields: Array = {Types.PuzzleActionKind.TRIGGER_MECHANISM:[],Types.PuzzleActionKind.LOCAL_GROUP_ROTATE: ["group_id"], Types.PuzzleActionKind.MOVE_CELESTIAL: ["target_slot_id", "alternate_slot_id"], Types.PuzzleActionKind.USE_FACE_TRANSITION: ["transition_id"]}[kind]
				if not exact(f.target_bindings, target_fields):
					return failure("INVALID_REFERENCE", record.authoring_id, "Instance target fields do not match config kind.")
				for field in target_fields:
					var target: Variant = f.target_bindings[field]
					var entity_field: String = "slot_id" if field in ["target_slot_id", "alternate_slot_id"] else field
					if entity_field == "slot_id" and typeof(target) == TYPE_STRING_NAME and target == &"":
						continue
					if not valid_id(target) or not entities.has(entity_field + ":" + String(target)):
						return failure("INVALID_REFERENCE", record.authoring_id, "Mechanism target does not resolve.")
			if record.kind == "TRANSITION":
				if not cubes.has(record.fields.source.cube_id) or not cubes.has(record.fields.target.cube_id):
					return failure("INVALID_REFERENCE", record.authoring_id, "Transition faces must resolve.")
				for id in record.fields.required_flags:
					if not flags.has(id):
						return failure("INVALID_REFERENCE", record.authoring_id, "Transition requires declared flags.")
	return {"ok": true, "value": null, "issues": []}

static func _references(value: Variant, resources: Dictionary, stack: Array) -> Dictionary:
	if value is Dictionary:
		if value.has("resource_ref"):
			if not exact(value, ["resource_ref"]) or not value.resource_ref is String or not resources.has(value.resource_ref):
				return failure("MISSING_RESOURCE", "resource_ref", "Resource reference is unresolved.")
			if value.resource_ref in stack:
				return failure("RESOURCE_CYCLE", value.resource_ref, "Semantic resource cycle.")
			var next := stack.duplicate()
			next.append(value.resource_ref)
			return _references(resources[value.resource_ref].fields, resources, next)
		for key in value:
			var result := _references(value[key], resources, stack)
			if not result.ok:
				return result
	elif value is Array:
		for item in value:
			var result := _references(item, resources, stack)
			if not result.ok:
				return result
	return {"ok": true, "value": null, "issues": []}
