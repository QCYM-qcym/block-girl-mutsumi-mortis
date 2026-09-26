extends RefCounted
## In-process proposals only. The caller owns application, confirmation and UndoRedo.
const Schema = preload("res://foundation/authoring/authoring_schema.gd")
const IDs = preload("res://foundation/authoring/id_registry.gd")
const Projector = preload("res://foundation/authoring/document_projector.gd")
const Assembler = preload("res://foundation/authoring/payload_assembler.gd")
const EDITABLE_NODES := ["CUBE", "SLOT", "GROUP", "MECHANISM", "TRANSITION"]
var _issues: Array[Dictionary] = []
var _visited := {}
var _clones := {}
var _used_authors := {}
var _proposal: Dictionary
var _context: Dictionary
var _uri: String

static func prepare_edit(operation: String, object_ref: Dictionary, context: Dictionary) -> Dictionary:
	var worker := new()
	return worker._prepare(operation, object_ref, context)

static func discard_proposal(proposal: Dictionary) -> void:
	# Nodes need explicit destruction. RefCounted graphs release by dropping all
	# proposal-owned references, never by forcibly freeing a Resource still held elsewhere.
	for object in proposal.get("created_objects", []):
		if is_instance_valid(object) and object is Node and object.get_parent() == null:
			object.free()
	for field in ["created_objects", "assigned_ids", "before", "after", "hierarchy_changes"]:
		if proposal.get(field) is Array:
			proposal[field].clear()

func _fail(code: String, path: String, message: String) -> void:
	_issues.append(Schema.issue(code, path, message))

func _result() -> Dictionary:
	if not _issues.is_empty():
		discard_proposal(_proposal)
		return {"ok": false, "value": null, "issues": _issues}
	return {"ok": true, "value": _proposal, "issues": []}

func _prepare(operation: String, object_ref: Dictionary, context: Dictionary) -> Dictionary:
	if operation not in ["COPY", "DELETE", "MAKE_UNIQUE"] or not Schema.exact(object_ref, ["object", "authoring_id", "document_uri"]) or not Schema.exact(context, ["document_root", "documents", "existing_ids"]):
		return Schema.failure("INVALID_EDIT_REQUEST", "edit", "Expected closed edit request and context.")
	if not is_instance_valid(object_ref.object) or not object_ref.object is Object or not is_instance_valid(context.document_root) or not context.document_root is Node or not context.documents is Array or not context.existing_ids is Dictionary or not Schema.pure(context.documents) or not Schema.pure(context.existing_ids):
		return Schema.failure("INVALID_EDIT_CONTEXT", "edit", "Expected live author objects and pure declaration context.")
	if not object_ref.document_uri is String or not object_ref.document_uri.begins_with("res://") or not Schema.valid_uuid(object_ref.authoring_id) or object_ref.object.get("authoring_id") != object_ref.authoring_id:
		return Schema.failure("STALE_OBJECT_REFERENCE", "object_ref", "Object author identity and document must match.")
	_context = context
	_uri = object_ref.document_uri
	_proposal = {"operation": operation, "document_uri": _uri, "target_authoring_id": object_ref.authoring_id, "created_objects": [], "assigned_ids": [], "before": [], "after": [], "hierarchy_changes": [], "retained_targets": [], "reference_impacts": [], "requires_confirmation": operation == "DELETE"}
	var document_index := -1
	for i in range(context.documents.size()):
		var doc: Variant = context.documents[i]
		if not Schema.exact(doc, Schema.DOCUMENT_FIELDS):
			return Schema.failure("INVALID_EDIT_CONTEXT", "documents", "Expected complete author documents.")
		if doc.document_uri == _uri:
			if document_index != -1 or doc.document_authoring_id != context.document_root.get("authoring_id"):
				return Schema.failure("CROSS_DOCUMENT_EDIT", _uri, "Exactly one owning document root is required.")
			document_index = i
		for item in doc.records + doc.resources:
			_used_authors[item.authoring_id] = true
	if document_index == -1:
		return Schema.failure("MISSING_DOCUMENT", _uri, "Owner document is absent from the context.")
	var object: Object = object_ref.object
	var kind := _kind(object)
	if kind.is_empty():
		return _result()
	if operation == "MAKE_UNIQUE":
		if not object is Resource or kind not in Schema.RESOURCE_KINDS:
			return Schema.failure("UNSUPPORTED_RESOURCE_TYPE", _uri, "MAKE_UNIQUE requires a semantic Resource.")
		_inspect(object, [])
		if not _issues.is_empty():
			return _result()
		var bindings: Array[Dictionary] = []
		_find_bindings(context.document_root, object, bindings, {})
		if bindings.is_empty():
			_fail("UNRESOLVED_RESOURCE_OWNER", _uri, "Resource must be referenced within the supplied document.")
		if not _issues.is_empty():
			return _result()
		var copy: Variant = _clone_value(object)
		for binding in bindings:
			_proposal.before.append(binding)
			_proposal.after.append({"object": binding.object, "property": binding.property, "value": _replace(binding.value, object, copy)})
		_resource_targets(object, {})
		return _result()
	if not object is Node3D or kind not in EDITABLE_NODES or object == context.document_root or not context.document_root.is_ancestor_of(object) or object.owner != context.document_root:
		return Schema.failure("UNSUPPORTED_EDIT_TARGET", _uri, "Edit one directly owned author node within one document.")
	if object.get_child_count() != 0:
		return Schema.failure("UNSUPPORTED_COMPOSITE_EDIT", _uri, "Single-object edits do not clone or delete a subtree.")
	var projected := _project(context.document_root, context.documents[document_index])
	if not projected.ok:
		return projected
	var documents: Array[Dictionary] = []
	documents.assign(context.documents.duplicate(true))
	documents[document_index] = projected.value
	var source := {}
	for record in projected.value.records:
		if record.authoring_id == object_ref.authoring_id:
			source = record
	if source.is_empty():
		return Schema.failure("STALE_OBJECT_REFERENCE", _uri, "Object is not in this source projection.")
	var target_fields: Dictionary = source.fields.duplicate(true)
	target_fields.erase(IDs.NAMED[kind])
	_targets(target_fields)
	if operation == "DELETE":
		_impacts(documents, kind, source.fields[IDs.NAMED[kind]], source.authoring_id)
		_proposal.hierarchy_changes.append({"action": "REMOVE", "node": object, "parent": object.get_parent(), "index": object.get_index(), "owner": object.owner})
		return _result()
	var original_check := _assemble(documents)
	if not original_check.ok:
		return original_check
	var assigned := _allocate(kind, documents)
	if assigned.is_empty():
		return _result()
	var clone: Node3D = load(Schema.script_path(kind)).new()
	clone.name = String(assigned.entity_id)
	clone.transform = object.transform
	_proposal.created_objects.append(clone)
	clone.set("authoring_id", assigned.authoring_id)
	var fields: Dictionary = object.declared_fields()
	fields.erase("authoring_id")
	for field in fields:
		clone.set(field, _clone_value(fields[field]) if kind == "CUBE" else _copy_containers(fields[field]))
	clone.set(IDs.NAMED[kind], assigned.entity_id)
	var new_record: Dictionary = source.duplicate(true)
	new_record.authoring_id = assigned.authoring_id
	new_record.label = String(clone.name)
	new_record.node_path = source.node_path.get_base_dir().path_join(String(clone.name))
	new_record.fields[IDs.NAMED[kind]] = assigned.entity_id
	if kind == "CUBE":
		new_record.fields.faces = []
		for face in clone.get("faces"):
			var face_fields: Dictionary = face.declared_fields()
			face_fields.erase("authoring_id")
			new_record.fields.faces.append({"resource_ref": face.get("authoring_id")})
			documents[document_index].resources.append({"authoring_id": face.get("authoring_id"), "kind": "FACE", "document_uri": _uri, "resource_uid": null, "fields": face_fields})
	documents[document_index].records.append(new_record)
	var candidate := _assemble(documents)
	if not candidate.ok:
		_issues.append_array(candidate.issues)
		return _result()
	_proposal.hierarchy_changes.append({"action": "ADD", "node": clone, "parent": object.get_parent(), "index": object.get_index() + 1, "owner": context.document_root})
	return _result()

func _kind(object: Object) -> String:
	var script: Variant = object.get_script()
	var kind := Schema.kind_of(script)
	if kind.is_empty() or not script is GDScript or script.source_code != FileAccess.get_file_as_string(script.resource_path):
		_fail("UNSUPPORTED_RESOURCE_TYPE", _uri, "Only unmodified approved authoring scripts are supported.")
		return ""
	return kind

func _project(root: Node, document: Dictionary) -> Dictionary:
	var digests := {}
	for kind in Schema.SCRIPTS:
		var path: String = Schema.script_path(kind)
		digests[path] = FileAccess.get_sha256(path)
	return Projector.project_document(root, {"document_uri": _uri, "document_authoring_id": document.document_authoring_id, "origin": "EDITOR_BUFFER", "allowed_script_digests": digests, "instance_role": null})

func _assemble(documents: Array[Dictionary]) -> Dictionary:
	for doc in documents:
		if doc.kind == "LEVEL":
			for record in doc.records:
				if record.kind == "LEVEL":
					return Assembler.assemble_payload(documents, {"level_authoring_id": record.authoring_id, "level_id": record.fields.level_id, "root_source_uri": doc.document_uri})
	return Schema.failure("MISSING_DOCUMENT", "documents", "A complete level closure is required for COPY reference checks.")

func _allocate(kind: String, documents: Array = []) -> Dictionary:
	var occupied: Array[StringName] = []
	if IDs.NAMED.has(kind):
		for doc in documents:
			for item in doc.records + doc.resources:
				if item.kind == kind and item.fields[IDs.NAMED[kind]] not in occupied:
					occupied.append(item.fields[IDs.NAMED[kind]])
		var supplied: Variant = _context.existing_ids.get(kind, [])
		if not supplied is Array:
			_fail("INVALID_ID_REGISTRY", kind, "Occupied identity lists must contain StringName IDs.")
			return {}
		for id in supplied:
			if typeof(id) != TYPE_STRING_NAME:
				_fail("INVALID_ID_REGISTRY", kind, "Occupied identity lists must contain StringName IDs.")
				return {}
			occupied.append(id)
	var allocated := IDs.allocate(kind, occupied)
	if not allocated.ok:
		_issues.append_array(allocated.issues)
		return {}
	while _used_authors.has(allocated.value.authoring_id):
		allocated = IDs.allocate(kind, occupied)
		if not allocated.ok:
			_issues.append_array(allocated.issues)
			return {}
	_used_authors[allocated.value.authoring_id] = true
	_proposal.assigned_ids.append(allocated.value.duplicate())
	return allocated.value

func _inspect(value: Variant, stack: Array) -> Variant:
	if value is Resource:
		if value in stack:
			_fail("RESOURCE_CYCLE", _uri, "Semantic Resource cycles cannot be specialized.")
			return null
		if _visited.has(value):
			return {"resource_ref": value.get("authoring_id")}
		var kind := _kind(value)
		if kind not in Schema.RESOURCE_KINDS:
			return null
		var fields: Dictionary = value.declared_fields()
		if not Schema.valid_uuid(fields.get("authoring_id")):
			_fail("INVALID_ID", _uri, "Every semantic Resource needs a valid author identity.")
		fields.erase("authoring_id")
		var normalized: Variant = _inspect(fields, stack + [value])
		if not normalized is Dictionary or not Schema.fields_valid(kind, normalized):
			_fail("INVALID_AUTHORING_FIELDS", kind, "Resource fields must follow the approved closed schema.")
		if kind == "INTENT":
			for field in ["expected_milestones", "forbidden_bypasses"]:
				var expected := "MILESTONE" if field == "expected_milestones" else "BYPASS"
				if fields.get(field) is Array:
					for child in fields[field]:
						if not child is Resource or Schema.kind_of(child.get_script()) != expected:
							_fail("INVALID_RESOURCE_REFERENCE", field, "Intent edges require their declared semantic Resource kind.")
		_visited[value] = true
		return {"resource_ref": value.get("authoring_id")}
	if value is Array or value is Dictionary:
		for ancestor in stack:
			if is_same(value, ancestor):
				_fail("RESOURCE_CYCLE", _uri, "Semantic collection cycles are unsupported.")
				return null
		var next := stack + [value]
		if value is Array:
			var array: Array = []
			for item in value:
				array.append(_inspect(item, next))
			return array
		var result := {}
		for key in value:
			if typeof(key) != TYPE_STRING:
				_fail("INVALID_AUTHORING_FIELDS", _uri, "Semantic dictionary keys must be String.")
			result[key] = _inspect(value[key], next)
		return result
	if not Schema.pure(value):
		_fail("UNSUPPORTED_RESOURCE_TYPE", _uri, "Objects and callbacks are not semantic values.")
	return value

func _clone_value(value: Variant) -> Variant:
	if value is Resource:
		if _clones.has(value):
			return _clones[value]
		var kind := Schema.kind_of(value.get_script())
		var assigned := _allocate(kind)
		if assigned.is_empty():
			return null
		# Specialization changes author identity, not the semantic self ID. Record
		# the actual preserved ID instead of an unused allocation candidate.
		if IDs.NAMED.has(kind):
			assigned.entity_id = value.get(IDs.NAMED[kind])
			_proposal.assigned_ids[-1].entity_id = assigned.entity_id
		var copy: Resource = load(Schema.script_path(kind)).new()
		_clones[value] = copy
		_proposal.created_objects.append(copy)
		copy.set("authoring_id", assigned.authoring_id)
		var fields: Dictionary = value.declared_fields()
		fields.erase("authoring_id")
		for field in fields:
			copy.set(field, _clone_value(fields[field]))
		return copy
	if value is Array:
		var copy: Array = []
		for item in value:
			copy.append(_clone_value(item))
		return copy
	if value is Dictionary:
		var copy := {}
		for key in value:
			copy[key] = _clone_value(value[key])
		return copy
	return value

func _find_bindings(node: Node, target: Resource, bindings: Array[Dictionary], visited: Dictionary) -> void:
	if node != _context.document_root and node.owner != _context.document_root:
		return
	var kind := Schema.kind_of(node.get_script())
	if not kind.is_empty():
		_scan_fields(node, target, bindings, visited)
	for child in node.get_children():
		_find_bindings(child, target, bindings, visited)

func _scan_fields(object: Object, target: Resource, bindings: Array[Dictionary], visited: Dictionary) -> void:
	if visited.has(object):
		return
	visited[object] = true
	if _kind(object).is_empty():
		return
	var fields: Dictionary = object.declared_fields()
	for field in fields:
		var value: Variant = fields[field]
		if _contains(value, target):
			if object is Resource and not object.resource_path.is_empty() and object.resource_path.split("::")[0] != _uri:
				_fail("CROSS_DOCUMENT_EDIT", _uri, "Specializing this nested reference would edit another source resource.")
			else:
				bindings.append({"object": object, "property": StringName(field), "value": value})
		else:
			_scan_resources(value, target, bindings, visited)

func _scan_resources(value: Variant, target: Resource, bindings: Array[Dictionary], visited: Dictionary) -> void:
	if value is Resource:
		_scan_fields(value, target, bindings, visited)
	elif value is Array:
		for item in value:
			_scan_resources(item, target, bindings, visited)
	elif value is Dictionary:
		for item in value.values():
			_scan_resources(item, target, bindings, visited)

static func _contains(value: Variant, target: Resource) -> bool:
	if value is Resource:
		return value == target
	if value is Array:
		return value.any(func(item: Variant) -> bool: return _contains(item, target))
	if value is Dictionary:
		return value.values().any(func(item: Variant) -> bool: return _contains(item, target))
	return false

static func _replace(value: Variant, target: Resource, copy: Resource) -> Variant:
	if value is Resource:
		return copy if value == target else value
	if value is Array:
		var result: Array = []
		for item in value:
			result.append(_replace(item, target, copy))
		return result
	if value is Dictionary:
		var result := {}
		for key in value:
			result[key] = _replace(value[key], target, copy)
		return result
	return value

static func _copy_containers(value: Variant) -> Variant:
	return value.duplicate(true) if value is Array or value is Dictionary else value

func _targets(value: Variant, field: String = "") -> void:
	if value is Dictionary:
		for key in value:
			_targets(value[key], String(key))
	elif value is Array:
		for item in value:
			_targets(item, field)
	elif typeof(value) == TYPE_STRING_NAME and value != &"" and field in ["cube_id", "cube_ids", "group_id", "target_slot_id", "alternate_slot_id", "transition_id", "slot_order", "initial_slot_id", "from_slot_id", "to_slot_id", "required_flags"]:
		if value not in _proposal.retained_targets:
			_proposal.retained_targets.append(value)

func _resource_targets(value: Variant, visited: Dictionary) -> void:
	if value is Resource:
		if visited.has(value):
			return
		visited[value] = true
		_resource_targets(value.declared_fields(), visited)
	elif value is Dictionary:
		_targets(value)
		for item in value.values():
			_resource_targets(item, visited)
	elif value is Array:
		for item in value:
			_resource_targets(item, visited)

func _impacts(documents: Array, kind: String, id: StringName, author_id: String) -> void:
	var fields: Array = {"CUBE": ["cube_id", "cube_ids"], "GROUP": ["group_id"], "SLOT": ["target_slot_id", "alternate_slot_id", "slot_order", "initial_slot_id", "from_slot_id", "to_slot_id"], "TRANSITION": ["transition_id"], "MECHANISM": []}[kind]
	var uris: Array = []
	for doc in documents:
		uris.append(doc.document_uri)
		for item in doc.records + doc.resources:
			if item.authoring_id != author_id:
				_reference_paths(item.fields, "", fields, id, doc.document_uri, item.authoring_id)
	for doc in documents:
		for dependency in doc.dependencies:
			if dependency not in uris:
				_proposal.reference_impacts.append({"document_uri": dependency, "authoring_id": null, "field": "", "target_id": id, "status": "UNRESOLVED_DEPENDENCY"})

func _reference_paths(value: Variant, path: String, fields: Array, id: StringName, uri: String, author: String, field: String = "") -> void:
	if value is Dictionary:
		for key in value:
			_reference_paths(value[key], path + "." + String(key) if not path.is_empty() else String(key), fields, id, uri, author, String(key))
	elif value is Array:
		for i in range(value.size()):
			_reference_paths(value[i], path + "[%d]" % i, fields, id, uri, author, field)
	elif typeof(value) == TYPE_STRING_NAME and value == id and field in fields:
		_proposal.reference_impacts.append({"document_uri": uri, "authoring_id": author, "field": path, "target_id": id, "status": "DANGLING_AFTER_DELETE"})
