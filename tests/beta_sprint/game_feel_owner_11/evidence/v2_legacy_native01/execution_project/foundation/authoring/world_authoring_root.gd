@tool
extends Node3D
## Presence-preserving exported declarations; no runtime gameplay callbacks.
const Schema = preload("res://foundation/authoring/authoring_schema.gd")
const AUTHORING_KIND := "WORLD"
var _declarations: Dictionary = {}

func _get_property_list() -> Array[Dictionary]:
	return Schema.property_list(AUTHORING_KIND, _declarations)

func _get(property: StringName) -> Variant:
	return _declarations.get(String(property))

func _set(property: StringName, value: Variant) -> bool:
	var key := String(property)
	if key == "authoring_id" or (Schema.FIELDS[AUTHORING_KIND].has(key) and key != "transform"):
		_declarations[key] = value
		return true
	return false

func declared_fields() -> Dictionary:
	return _declarations.duplicate()
