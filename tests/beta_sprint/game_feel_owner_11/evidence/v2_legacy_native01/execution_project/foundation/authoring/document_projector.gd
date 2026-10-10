extends RefCounted
## Reads only the supported scripts and frozen SceneState declarations; never instantiates a scene.
const Schema = preload("res://foundation/authoring/authoring_schema.gd")
const CONTEXT_FIELDS := ["document_uri", "document_authoring_id", "origin", "allowed_script_digests", "instance_role"]

static func project_document(source: Variant, document_context: Dictionary) -> Dictionary:
	if not Schema.exact(document_context, CONTEXT_FIELDS) or not document_context.document_uri is String or not Schema.valid_uuid(document_context.document_authoring_id) or document_context.origin not in ["SAVED", "EDITOR_BUFFER"] or not document_context.allowed_script_digests is Dictionary or not (document_context.instance_role == null or document_context.instance_role is String):
		return Schema.failure("INVALID_CONTEXT", "document_context", "Expected closed document context.")
	var worker := new()
	return worker._project(source, document_context)

var _context: Dictionary
var _document: Dictionary
var _resources := {}
var _issues: Array[Dictionary] = []
var _world_instances := {}
var _gameplay_paths: Array[String] = []

func _fail(code: String, path: String, message: String) -> void:
	_issues.append(Schema.issue(code, path, message))

func _trusted_kind(script: Variant, path: String) -> String:
	var kind := Schema.kind_of(script)
	if kind.is_empty() or not script is GDScript or _context.allowed_script_digests.get(script.resource_path, "") != FileAccess.get_sha256(script.resource_path) or script.source_code != FileAccess.get_file_as_string(script.resource_path):
		_fail("UNSUPPORTED_SCRIPT", path, "Script must match the supported version-bound whitelist.")
		return ""
	return kind

func _project(source: Variant, context: Dictionary) -> Dictionary:
	_context = context
	_document = {"authoring_version": "levelauthoring.v1", "document_uri": context.document_uri, "document_authoring_id": context.document_authoring_id, "kind": "", "root_transform": Transform3D.IDENTITY, "records": [], "resources": [], "dependencies": [], "override_paths": []}
	if source is SceneState:
		_scene(source)
	elif source is Node3D:
		if not source.scene_file_path.is_empty():
			var provenance := ResourceLoader.load(source.scene_file_path, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
			if provenance == null or provenance.get_state().get_base_scene_state() != null:
				return Schema.failure("UNSUPPORTED_AUTHORING_OVERRIDE", ".", "Live source inheritance cannot be accepted.")
		_document.root_transform = source.transform
		_nodes(source, source)
	elif source is Resource:
		var kind := _trusted_kind(source.get_script(), ".")
		if kind in Schema.RESOURCE_KINDS:
			_document.kind = "INTENT" if kind == "INTENT" else "CONFIG"
			var value: Variant = _resource(source, [], true)
			if value == null or value.resource_ref != context.document_authoring_id:
				_fail("INVALID_DOCUMENT", ".", "Resource root identity does not match context.")
		else:
			_fail("INVALID_DOCUMENT", ".", "Resource root must belong to the semantic whitelist.")
	else:
		_fail("INVALID_DOCUMENT", ".", "Expected supported Node3D, frozen SceneState or semantic Resource.")
	if _issues.is_empty():
		if _document.kind == "LEVEL" and _world_instances.size() != 2:
			_fail("MISSING_WORLD", ".", "Level requires exactly two independent World instances.")
		_document.resources = _resources.values()
		if _document.kind in ["LEVEL", "WORLD"]:
			if _document.records.is_empty() or _document.records[0].authoring_id != context.document_authoring_id:
				_fail("INVALID_DOCUMENT", ".", "Root identity does not match context.")
		if _document.kind != "LEVEL" and _document.root_transform != Transform3D.IDENTITY:
			_fail("INVALID_HIERARCHY", ".", "World and resource root transforms must be identity.")
	return {"ok": _issues.is_empty(), "value": _document if _issues.is_empty() else null, "issues": _issues}

func _add_dependency(uri: String) -> void:
	if uri != _context.document_uri and uri not in _document.dependencies:
		_document.dependencies.append(uri)

func _resource(source: Resource, stack: Array, document_root: bool = false, owner_uri: String = "") -> Variant:
	var pointer := source.get_instance_id()
	if pointer in stack:
		_fail("RESOURCE_CYCLE", "resources", "Semantic Resource cycle.")
		return null
	var kind := _trusted_kind(source.get_script(), "resources")
	if kind not in Schema.RESOURCE_KINDS:
		_fail("UNSUPPORTED_RESOURCE_TYPE", "resources", "Resource is outside the semantic whitelist.")
		return null
	var data: Dictionary = source.declared_fields()
	var id: Variant = data.get("authoring_id")
	if not Schema.valid_uuid(id):
		_fail("INVALID_ID", "resources", "Resource requires a persistent authoring UUID.")
		return null
	data.erase("authoring_id")
	var uri: String = _context.document_uri if owner_uri.is_empty() else owner_uri
	if document_root:
		uri = _context.document_uri
	elif source.resource_path.begins_with("res://"):
		uri = source.resource_path.split("::")[0]
	var next := stack.duplicate()
	next.append(pointer)
	var fields: Variant = _value(data, next, [], uri)
	if not Schema.fields_valid(kind, fields):
		_fail("INVALID_RESOURCE", id, "Resource declaration is missing, unknown or mistyped.")
		return null
	var entry := {"authoring_id": id, "kind": kind, "document_uri": uri, "resource_uid": null, "fields": fields}
	if _resources.has(id) and _resources[id] != entry:
		_fail("RESOURCE_VERSION_CONFLICT", id, "Resource identity has conflicting declarations.")
		return null
	_resources[id] = entry
	_add_dependency(uri)
	return {"resource_ref": id}

func _value(value: Variant, stack: Array, containers: Array = [], owner_uri: String = "") -> Variant:
	if value is Resource:
		return _resource(value, stack, false, owner_uri)
	if value is Array or value is Dictionary:
		for parent in containers:
			if is_same(parent, value):
				_fail("RESOURCE_CYCLE", "fields", "Cyclic declaration collection.")
				return null
		var next := containers.duplicate()
		next.append(value)
		if value is Array:
			var result: Array = []
			for item in value:
				result.append(_value(item, stack, next, owner_uri))
			return result
		var result := {}
		for key in value:
			if typeof(key) != TYPE_STRING:
				_fail("INVALID_FIELD", "fields", "Declaration keys must be String.")
				return null
			result[key] = _value(value[key], stack, next, owner_uri)
		return result
	if not Schema.pure(value):
		_fail("INVALID_FIELD", "fields", "Active objects and callbacks cannot be projected.")
		return null
	return value

func _record(kind: String, properties: Dictionary, transform: Transform3D, path: String, label: String) -> void:
	var data := properties.duplicate()
	var id: Variant = data.get("authoring_id")
	data.erase("authoring_id")
	if kind in ["CUBE", "SLOT"]:
		data["transform"] = transform
	elif kind != "MECHANISM" and path != "." and transform != Transform3D.IDENTITY:
		_fail("INVALID_HIERARCHY", path, "Organizational author nodes require identity transform.")
		return
	var fields: Variant = _value(data, [])
	if not Schema.valid_uuid(id) or not Schema.fields_valid(kind, fields):
		_fail("INVALID_RECORD", path, "Node declaration is missing, unknown or mistyped.")
		return
	if path == ".":
		if kind not in ["LEVEL", "WORLD"]:
			_fail("INVALID_DOCUMENT", path, "Scene root must be Level or World.")
			return
		_document.kind = kind
	if path != ".":
		for parent in _gameplay_paths:
			if path.begins_with(parent + "/"):
				_fail("INVALID_HIERARCHY", path, "Gameplay nodes cannot inherit transforms from other gameplay nodes.")
				return
		_gameplay_paths.append(path)
	if kind == "LEVEL":
		_add_dependency(fields.surface_source)
		_add_dependency(fields.inner_source)
	_document.records.append({"kind": kind, "authoring_id": id, "node_path": path, "label": label, "fields": fields})

func _nodes(node: Node, root: Node3D) -> void:
	var path := String(root.get_path_to(node))
	if not node is Node3D or node.top_level:
		_fail("INVALID_HIERARCHY", path, "Only inherited Node3D author nodes are supported.")
		return
	if node != root and _document.kind == "LEVEL":
		_live_world_instance(node, path)
		return
	if node != root and not node.scene_file_path.is_empty():
		_fail("UNSUPPORTED_AUTHORING_OVERRIDE", path, "Nested scene instances inside World are unsupported.")
		return
	var script: Variant = node.get_script()
	if script == null and node != root:
		if node.transform != Transform3D.IDENTITY:
			_fail("INVALID_HIERARCHY", path, "Organizational containers require identity.")
			return
	else:
		var kind := _trusted_kind(script, path)
		if kind.is_empty() or kind in Schema.RESOURCE_KINDS:
			return
		_record(kind, node.declared_fields(), node.transform, path, String(node.name))
	for child in node.get_children():
		_nodes(child, root)

func _live_world_instance(node: Node3D, path: String) -> void:
	if _document.records.is_empty():
		return
	var fields: Dictionary = _document.records[0].fields
	if node.scene_file_path not in [fields.surface_source, fields.inner_source] or node.transform != Transform3D.IDENTITY:
		_fail("UNSUPPORTED_AUTHORING_OVERRIDE", path, "Level children must be identity World source instances.")
		return
	if _world_instances.has(node.scene_file_path):
		_fail("DUPLICATE_WORLD", path, "World source cannot be instantiated twice.")
		return
	_world_instances[node.scene_file_path] = true
	# Compare with its frozen source; uncertainty fails closed. Never use this
	# instance as the authoritative World document in the assembled payload.
	var packed := ResourceLoader.load(node.scene_file_path, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if packed == null:
		_fail("MISSING_DOCUMENT", path, "World source cannot be loaded.")
		return
	var context := _context.duplicate(true)
	context.document_uri = node.scene_file_path
	context.document_authoring_id = node.get("authoring_id")
	var baseline := project_document(packed.get_state(), context)
	var current := project_document(node, context)
	if baseline.ok and current.ok:
		current.value.records[0].label = baseline.value.records[0].label
	if not baseline.ok or not current.ok or baseline.value != current.value:
		_fail("UNSUPPORTED_AUTHORING_OVERRIDE", path, "Instance gameplay differs from its independent World source.")

func _scene(state: SceneState) -> void:
	if state.get_base_scene_state() != null:
		_fail("UNSUPPORTED_AUTHORING_OVERRIDE", ".", "Inherited gameplay scenes are unsupported.")
		return
	for index in range(state.get_node_count()):
		var path := String(state.get_node_path(index)).trim_prefix("./")
		var properties := {}
		for p in range(state.get_node_property_count(index)):
			properties[String(state.get_node_property_name(index, p))] = state.get_node_property_value(index, p)
		var instance := state.get_node_instance(index)
		if instance != null:
			if _document.kind != "LEVEL" or _document.records.is_empty():
				_fail("UNSUPPORTED_AUTHORING_OVERRIDE", path, "Only independent World instances in Level are supported.")
				continue
			var fields: Dictionary = _document.records[0].fields
			if instance.resource_path not in [fields.surface_source, fields.inner_source]:
				_fail("UNSUPPORTED_AUTHORING_OVERRIDE", path, "Unexpected scene instance.")
			if _world_instances.has(instance.resource_path):
				_fail("DUPLICATE_WORLD", path, "World source cannot be instantiated twice.")
			_world_instances[instance.resource_path] = true
			for key in properties:
				if key == "transform" and properties[key] == Transform3D.IDENTITY:
					continue
				if _is_native_property(key) and key not in ["script", "transform", "position", "rotation", "rotation_degrees", "quaternion", "scale", "basis", "top_level"]:
					continue
				_fail("UNSUPPORTED_AUTHORING_OVERRIDE", path, "Instance gameplay overrides are unsupported.")
			continue
		if state.get_node_instance_placeholder(index) != "":
			_fail("UNSUPPORTED_AUTHORING_OVERRIDE", path, "Unresolved instance placeholder.")
			continue
		if state.get_node_type(index) != &"Node3D" or properties.get("top_level", false):
			_fail("INVALID_HIERARCHY", path, "Only inherited plain Node3D nodes are supported.")
			continue
		var transform: Variant = properties.get("transform", Transform3D.IDENTITY)
		if not transform is Transform3D:
			_fail("INVALID_HIERARCHY", path, "Expected original Transform3D.")
			continue
		if properties.has("position"):
			if not properties.position is Vector3:
				_fail("INVALID_HIERARCHY", path, "Expected original position Vector3.")
				continue
			transform.origin = properties.position
		if properties.has("scale") or properties.has("rotation") or properties.has("rotation_degrees") or properties.has("quaternion") or properties.has("basis"):
			_fail("INVALID_HIERARCHY", path, "Use the stored original Transform3D; split rotation or scale properties are unsupported.")
			continue
		if index == 0:
			_document.root_transform = transform
		var script: Variant = properties.get("script")
		if script == null and index > 0:
			if _document.kind == "LEVEL" or transform != Transform3D.IDENTITY:
				_fail("UNSUPPORTED_AUTHORING_OVERRIDE", path, "Unsupported gameplay instance or container.")
			continue
		var kind := _trusted_kind(script, path)
		if kind.is_empty() or kind in Schema.RESOURCE_KINDS:
			continue
		var declared := {}
		for key in properties:
			if key == "authoring_id" or Schema.FIELDS[kind].has(key):
				declared[key] = properties[key]
			elif not _is_native_property(key):
				_fail("INVALID_FIELD", path + "." + key, "Unsupported stored node property.")
		_record(kind, declared, transform, path, String(state.get_node_name(index)))

static func _is_native_property(property: String) -> bool:
	if property == "script" or property.begins_with("metadata/"):
		return true
	for entry in ClassDB.class_get_property_list("Node3D"):
		if String(entry.name) == property:
			return true
	return false
