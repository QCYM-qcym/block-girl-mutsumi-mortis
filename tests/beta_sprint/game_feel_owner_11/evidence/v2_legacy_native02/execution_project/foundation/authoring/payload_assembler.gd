extends RefCounted
const Schema = preload("res://foundation/authoring/authoring_schema.gd")

static func assemble_payload(documents: Array[Dictionary], level_ref: Dictionary) -> Dictionary:
	if not Schema.pure(documents) or not Schema.pure(level_ref):
		return Schema.failure("INVALID_AUTHORING", "documents", "Expected acyclic values without live references.")
	var resources := {}
	for doc in documents:
		if not Schema.exact(doc, Schema.DOCUMENT_FIELDS) or not doc.resources is Array:
			return Schema.failure("INVALID_DOCUMENT", "documents", "Incomplete document.")
		for resource in doc.resources:
			if not Schema.exact(resource, Schema.RESOURCE_FIELDS) or not resource.authoring_id is String:
				return Schema.failure("INVALID_RESOURCE", "resources", "Incomplete resource entry.")
			var id: String = resource.authoring_id
			if resources.has(id) and resources[id] != resource:
				return Schema.failure("RESOURCE_VERSION_CONFLICT", id, "One resource identity has multiple versions.")
			resources[id] = resource.duplicate(true)
	var payload := {"authoring_version": "levelauthoring.v1", "level_ref": level_ref.duplicate(true), "documents": documents.duplicate(true), "resource_table": resources.values()}
	var checked := Schema.validate_authoring(payload)
	return {"ok": checked.ok, "value": payload if checked.ok else null, "issues": checked.issues}
