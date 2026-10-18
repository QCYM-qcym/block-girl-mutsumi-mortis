extends RefCounted
## Integration consumes the delivered Content registry; Shell does not author maps.
const DEFAULT_CATALOG := "res://game/levels/mutsumi/batch_01/level_order.json"
const SPATIAL_CATALOG := "res://game/levels/mutsumi/spatial_chapter/level_order.json"
var entries: Array[Dictionary] = []

func _init(source: Array[Dictionary] = []) -> void:
	entries.assign(_default_entries() if source.is_empty() else source)

static func _default_entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for source in [DEFAULT_CATALOG, SPATIAL_CATALOG]:
		var document: Variant = JSON.parse_string(FileAccess.get_file_as_string(source))
		if not document is Dictionary:
			push_error("Beta Content catalog is unavailable")
			return []
		for row in document.get("levels", []):
			var entry: Dictionary = row.duplicate()
			var metadata: Resource = load(str(entry.resource))
			if metadata == null or str(metadata.get("level_id")) != entry.id:
				push_error("Beta Content metadata identity mismatch")
				return []
			entry.title = metadata.get("display_title")
			result.append(entry)
	return result

func first_id() -> String:
	return str(entries[0].id) if not entries.is_empty() else ""

func find(id: String) -> Dictionary:
	for entry in entries:
		if entry.id == id:
			return entry
	return {}

func is_available(id: String) -> bool:
	var entry := find(id)
	return not entry.is_empty() and ResourceLoader.exists(entry.scene, "PackedScene")

func next_id(id: String) -> String:
	for i in range(entries.size() - 1):
		if entries[i].id == id:
			return entries[i + 1].id
	return ""
