extends SceneTree
## Regression boundary: removing/reordering a formal entry must fail this contract.
const Catalog = preload("res://game/shell/level_catalog.gd")
const Factory = preload("res://experiments/spatial_puzzle_batch_01/maps/map_factory.gd")
var checks := 0
var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message)

func _initialize() -> void:
	var catalog := Catalog.new()
	var legacy: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/beta_sprint/spatial_formal/shell_legacy_rows.json"))
	check(legacy.size() == 5, "original five-entry contract fixture")
	check(catalog.entries.size() == 10, "formal catalog contains original five plus five spatial levels")
	var original_document: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Catalog.DEFAULT_CATALOG))
	check(original_document.levels == legacy, "original five raw registry rows remain exact")
	for index in mini(5, catalog.entries.size()):
		var expected_row: Dictionary = legacy[index].duplicate()
		expected_row.title = load(expected_row.resource).get("display_title")
		check(catalog.entries[index] == expected_row, "original entry unchanged: " + str(index + 1))
	var expected: Array[String] = []
	for row in legacy: expected.append(row.id)
	for map_id in Factory.ids(): expected.append("spatial_" + str(map_id))
	for index in expected.size():
		var id: String = expected[index]
		var entry: Dictionary = catalog.find(id)
		check(not entry.is_empty(), "formal stable ID registered: " + id)
		check(catalog.next_id(id) == (expected[index + 1] if index + 1 < expected.size() else ""), "natural next-level ordering: " + id)
		if entry.is_empty(): continue
		check(catalog.entries[index].id == id, "formal order: " + id)
		check(catalog.is_available(id), "formal scene available: " + id)
		if index < 5: continue
		check(entry.adapter == "signal", "spatial level uses completion adapter: " + id)
		check(entry.scene.begins_with("res://game/levels/mutsumi/spatial_chapter/"), "spatial scene is a formal entry: " + id)
		check(entry.resource.begins_with("res://game/levels/mutsumi/spatial_chapter/"), "spatial metadata is a formal entry: " + id)
		var metadata: Resource = load(entry.resource)
		check(metadata != null and str(metadata.get("level_id")) == id, "formal metadata identity: " + id)
		var packed: PackedScene = load(entry.scene)
		var level: Node = packed.instantiate()
		check(str(level.get("map_id")) == str(Factory.ids()[index - 5]), "formal scene selects intended tested map: " + id)
		check(level.has_signal("completed") and level.has_method("reset_level") and level.has_method("set_level_paused"), "formal lifecycle contract: " + id)
		level.free()
	check(catalog.find("mutsumi_l06").is_empty(), "reserved L06 is not renamed or registered")
	print(JSON.stringify({"scope":"SPATIAL_FORMAL_CATALOG", "checks":checks, "failures":failures, "evidence_type":"HEADLESS_RESOURCE_CONTRACT", "human_acceptance":"NOT_RUN"}))
	quit(0 if failures.is_empty() else 1)
