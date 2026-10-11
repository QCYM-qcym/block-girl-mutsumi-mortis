@tool
extends Resource
## Presence-preserving exported declarations; no runtime gameplay callbacks.
const Schema = preload("res://foundation/authoring/authoring_schema.gd")
const AUTHORING_KIND := "MECHANISM_CONFIG"
var _declarations: Dictionary = {}

func _get_property_list() -> Array[Dictionary]:
	return Schema.property_list(AUTHORING_KIND, _declarations)

func _get(property: StringName) -> Variant:
	return _declarations.get(String(property))

func _set(property: StringName, value: Variant) -> bool:
	var key := String(property)
	if key == "authoring_id" or key in ["rotation_delta", "celestial_op"] or Schema.FIELDS[AUTHORING_KIND].has(key) or Schema.LOCK_CONFIG_TYPES.has(key):
		_declarations[key] = value
		notify_property_list_changed()
		return true
	return false

func declared_fields() -> Dictionary:
	return _declarations.duplicate()
