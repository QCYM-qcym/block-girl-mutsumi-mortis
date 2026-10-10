extends RefCounted
## Paths are captured at profile construction, then joined to canonical entities by ID.
const Schema = preload("res://foundation/authoring/authoring_schema.gd")
const IntentTypes = preload("res://foundation/quality/intent/intent_types.gd")
const COLLECTIONS := {"CUBE": ["cubes", "cube_id"], "FACE": ["faces", "face_id"], "SLOT": ["celestial.slots", "slot_id"], "GROUP": ["groups", "group_id"], "MECHANISM": ["mechanisms", "mechanism_id"], "TRANSITION": ["face_transitions", "transition_id"]}

static func capture(map: Dictionary, doc: Dictionary, record: Dictionary, kind: String, id: Variant, path: String) -> void:
	_append(map, record.authoring_id, doc.document_uri, record.node_path, null, null, null, kind, id, "", path)
	if kind == "LEVEL":
		_append(map, record.authoring_id, doc.document_uri, record.node_path, null, null, null, kind, id, "root_transform", "root.transform")
	for field in record.fields:
		if field in ["faces", "config", "surface_source", "inner_source", "intent", "authoring_version"]:
			continue
		if field == "transform":
			_append(map, record.authoring_id, doc.document_uri, record.node_path, null, null, null, kind, id, field, path + ".position")
			_append(map, record.authoring_id, doc.document_uri, record.node_path, null, null, null, kind, id, field, path + ".basis")
		else:
			var suffix := _formal_field(kind, field, "")
			_append(map, record.authoring_id, doc.document_uri, record.node_path, null, null, null, kind, id, field, _join(path, suffix))

static func capture_resource(map: Dictionary, resource: Dictionary, _host: Dictionary, kind: String, id: Variant, path: String, face: Variant) -> void:
	# No resource subpath was captured by the projector. Never invent one from an
	# array position or attach a host NodePath to a different resource document.
	for field in [""] + resource.fields.keys():
		_append(map, resource.authoring_id, resource.document_uri, null, resource.resource_uid, null, face, kind, id, field, _join(path, _formal_field(kind, field, "")))

static func _append(map: Dictionary, authoring_id: String, uri: String, node_path: Variant, uid: Variant, subpath: Variant, face: Variant, kind: String, id: Variant, field: String, reader_path: String) -> void:
	map.entries.append({"authoring_id": authoring_id, "document_uri": uri, "node_path_at_capture": node_path, "resource_uid": uid, "resource_subpath": subpath, "local_face": face, "entity_kind": kind, "entity_id": id, "field": field, "reader_path": reader_path if not reader_path.is_empty() else null, "canonical_path": null})

static func complete(map: Dictionary, level: Dictionary, payload: Dictionary) -> void:
	map.level_hash = level.content_hash
	var world_layers := {}
	for doc in payload.documents:
		for record in doc.records:
			if record.kind == "WORLD":
				world_layers[record.authoring_id] = record.fields.layer
	for entry in map.entries:
		if entry.field == "root_transform":
			continue # Root placement is not a formal Level field.
		var prefix: Variant = null
		if entry.entity_kind == "LEVEL":
			prefix = ""
		elif entry.entity_kind == "WORLD":
			for i in range(level.worlds.size()):
				if level.worlds[i].layer == world_layers.get(entry.authoring_id):
					prefix = "worlds[%d]" % i
		elif COLLECTIONS.has(entry.entity_kind):
			var pair: Array = COLLECTIONS[entry.entity_kind]
			var entities: Array = level.celestial.slots if entry.entity_kind == "SLOT" else level[pair[0]]
			for i in range(entities.size()):
				if entities[i][pair[1]] == entry.entity_id:
					prefix = "%s[%d]" % [pair[0], i]
		if prefix != null:
			entry.canonical_path = _join(prefix, _formal_field(entry.entity_kind, entry.field, entry.reader_path if entry.reader_path != null else ""))

static func _formal_field(kind: String, field: String, reader_path: String) -> String:
	if field == "transform":
		if kind == "SLOT":
			return "position2" if reader_path.ends_with(".position") else ""
		return "orientation" if reader_path.ends_with(".basis") else "center2"
	if kind == "MECHANISM":
		if field == "host_face":
			return "face_id"
		if field == "target_bindings":
			return "action"
		if field in ["kind", "rotation_delta", "celestial_op"]:
			return "action." + field
	if kind == "TRANSITION" and field in ["source", "target"]:
		return field + "_face_id"
	return field

static func _join(prefix: String, field: String) -> String:
	return prefix + "." + field if not prefix.is_empty() and not field.is_empty() else prefix + field

static func locate(map: Dictionary, issue: Dictionary, phase: String) -> Dictionary:
	if not _valid_map(map) or not Schema.pure(issue) or phase not in ["READER", "CANONICAL", "VALIDATION", "ANALYSIS", "QUALITY"]:
		return _missing("SOURCE_MAP_INVALID", "Unknown map or diagnostic phase.")
	var path_field := "reader_path" if phase == "READER" else "canonical_path"
	var paths := _by_path(map.entries, issue.get("path", ""), path_field)
	if _ambiguous(paths):
		return _missing("SOURCE_MAP_AMBIGUOUS", "Captured path identifies conflicting author objects.")
	var ids: Variant = issue.get("entity_ids", issue.get("subject_ids", []))
	var subject_kinds: Array = []
	if issue.has("subject_ids"):
		# A QualityFinding is not a ValidationIssue: its code defines the ID namespace.
		match issue.get("code"):
			IntentTypes.QualityCode.UNUSED_MECHANISM: subject_kinds = ["MECHANISM"]
			IntentTypes.QualityCode.MILESTONE_BYPASS: subject_kinds = ["MILESTONE"]
			IntentTypes.QualityCode.MECHANIC_BYPASS: subject_kinds = ["INTENT", "BYPASS"]
			_: return _missing("SOURCE_MAP_UNLOCATED", "Unknown QualityFinding subject namespace.")
	if ids is Array and not ids.is_empty():
		var selected: Array = []
		for id in ids:
			var matches: Array = []
			var kinds := {}
			for entry in map.entries:
				if entry.entity_id != null and entry.entity_id == id and (subject_kinds.is_empty() or entry.entity_kind in subject_kinds):
					matches.append(entry)
					kinds[entry.entity_kind] = true
			if kinds.size() > 1:
				matches = matches.filter(func(entry: Dictionary) -> bool: return entry in paths)
				if matches.is_empty():
					return _missing("SOURCE_MAP_AMBIGUOUS", "Entity ID belongs to multiple entity kinds.")
			if matches.is_empty():
				return _missing("SOURCE_MAP_UNLOCATED", "No source for an explicit subject ID.")
			if _ambiguous(matches):
				return _missing("SOURCE_MAP_AMBIGUOUS", "Entity identifies conflicting author objects.")
			for entry in matches:
				if entry not in selected:
					selected.append(entry)
		return {"ok": true, "value": selected.duplicate(true), "issues": []}
	if not paths.is_empty():
		return {"ok": true, "value": paths.duplicate(true), "issues": []}
	var upstream_matches: Array = []
	if issue.get("upstream") is Array:
		for upstream in issue.upstream:
			if upstream is Dictionary:
				var found := locate(map, upstream, phase)
				if found.ok:
					for entry in found.value:
						if entry not in upstream_matches:
							upstream_matches.append(entry)
	if not upstream_matches.is_empty():
		return {"ok": true, "value": upstream_matches, "issues": []}
	return _missing("SOURCE_MAP_UNLOCATED", "No exact entity or captured phase path; show a level diagnostic.")

static func _valid_map(map: Dictionary) -> bool:
	if not Schema.pure(map) or not Schema.exact(map, ["map_version", "snapshot_id", "source_fingerprint", "level_hash", "entries"]) or map.map_version != "authoringsourcemap.v1" or not map.entries is Array:
		return false
	if not map.snapshot_id is String or not map.source_fingerprint is String or (map.level_hash != null and not map.level_hash is String):
		return false
	for entry in map.entries:
		if not Schema.exact(entry, ["authoring_id", "document_uri", "node_path_at_capture", "resource_uid", "resource_subpath", "local_face", "entity_kind", "entity_id", "field", "reader_path", "canonical_path"]):
			return false
		for field in ["authoring_id", "document_uri", "entity_kind", "field"]:
			if not entry[field] is String:
				return false
		for field in ["node_path_at_capture", "resource_uid", "resource_subpath", "reader_path", "canonical_path"]:
			if entry[field] != null and not entry[field] is String:
				return false
		if entry.entity_id != null and typeof(entry.entity_id) != TYPE_STRING_NAME:
			return false
		if entry.local_face != null and (typeof(entry.local_face) != TYPE_INT or entry.local_face not in range(6)):
			return false
	return true

static func _ambiguous(entries: Array) -> bool:
	for i in range(entries.size()):
		var a: Dictionary = entries[i]
		for j in range(i):
			var b: Dictionary = entries[j]
			# A mechanism node and its config can both explain the same diagnostic.
			# Two nodes (or two resources) cannot claim one entity field.
			if a.entity_kind == b.entity_kind and a.entity_id == b.entity_id and a.field == b.field and (a.node_path_at_capture == null) == (b.node_path_at_capture == null) and a.authoring_id != b.authoring_id:
				return true
	return false

static func _by_path(entries: Array, path: Variant, field: String) -> Array:
	var matches: Array = []
	var length := -1
	if not path is String or path.is_empty():
		return matches
	for entry in entries:
		var captured: Variant = entry.get(field)
		if not captured is String or captured.is_empty():
			continue
		if path == captured or path.begins_with(captured + ".") or path.begins_with(captured + "["):
			if captured.length() > length:
				matches.clear()
				length = captured.length()
			if captured.length() == length and entry not in matches:
				matches.append(entry)
	return matches

static func _missing(code: String, message: String) -> Dictionary:
	var diagnostic := Schema.issue(code, "source_map", message)
	diagnostic.stage = "SOURCE_MAP"
	return {"ok": false, "value": [], "issues": [diagnostic]}
