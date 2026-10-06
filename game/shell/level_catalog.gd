extends RefCounted
## Owner 06 can register accepted levels here; the Shell never authors puzzles.
const DEFAULT_ENTRIES := [{"id": "p01", "title": "P-01 · 另一个世界", "scene": "res://game/levels/mutsumi/p01_another_world.tscn", "adapter": "p01"}]
var entries: Array[Dictionary] = []

func _init(source: Array[Dictionary] = []) -> void:
	entries.assign(DEFAULT_ENTRIES if source.is_empty() else source)

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
