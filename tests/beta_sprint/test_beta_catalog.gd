extends SceneTree
const Catalog = preload("res://game/shell/level_catalog.gd")
const LEGACY_ROWS := "res://tests/beta_sprint/shell_batch_02/legacy_catalog_rows.json"
const BATCH02 := "res://game/levels/mutsumi/batch_02/level_order.json"
const SPATIAL := "res://game/levels/mutsumi/spatial_chapter/level_order.json"
var checks := 0
var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)

func _initialize() -> void:
	var catalog := Catalog.new()
	var source: Variant = JSON.parse_string(FileAccess.get_file_as_string(Catalog.DEFAULT_CATALOG))
	var legacy: Variant = JSON.parse_string(FileAccess.get_file_as_string(LEGACY_ROWS))
	check(source is Dictionary and source.get("levels") is Array, "formal catalog has a level list")
	check(legacy is Array and legacy.size() == 3, "explicit original-three metadata contract fixture")
	if not source is Dictionary or not source.get("levels") is Array or not legacy is Array:
		finish()
		return
	var rows: Array = source.levels
	check(rows.size() >= legacy.size(), "all original three levels remain registered")
	for index in mini(rows.size(), legacy.size()):
		check(rows[index] == legacy[index], "original row/order/metadata unchanged " + str(index + 1))
	var ids: Array = []
	var delivered: Array = []
	if FileAccess.file_exists(BATCH02):
		var batch: Variant = JSON.parse_string(FileAccess.get_file_as_string(BATCH02))
		check(batch is Dictionary and batch.get("levels") is Array, "delivered Batch02 catalog has a level list")
		if batch is Dictionary and batch.get("levels") is Array:
			delivered = batch.levels
	var spatial: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SPATIAL))
	check(catalog.entries.size() == rows.size() + spatial.levels.size(), "Shell loads every formally registered level across both catalogs")
	check(catalog.first_id() == "mutsumi_l01", "Beta begins with formal L-01")
	for index in rows.size():
		var row: Dictionary = rows[index]
		var id: String = str(row.get("id", ""))
		check(not id.is_empty() and id not in ids, "registered stable IDs are nonempty and unique: " + id)
		ids.append(id)
		var entry: Dictionary = catalog.find(id)
		check(not entry.is_empty(), "stable level ID registered: " + id)
		if entry.is_empty():
			continue
		check(catalog.is_available(id), "delivered scene can be loaded: " + id)
		check(entry.scene.begins_with("res://") and entry.resource.begins_with("res://"), "catalog uses project resources")
		var data: Resource = load(entry.resource)
		check(data != null and str(data.get("level_id")) == id, "catalog matches formal Content metadata ID")
		check(data != null and entry.title == data.get("display_title"), "Shell displays formal Content metadata title")
		check(data != null and row.quality == data.get("quality"), "formal quality matches Content metadata " + id)
		check(load(entry.scene) is PackedScene, "registered resource is a loadable PackedScene " + id)
		if index >= legacy.size():
			check(row in delivered, "appended metadata is an actual playable Batch02 row " + id)
			check(row.get("registration_allowed", false) == true and row.get("status", "") == "GREYBOX_PLAYABLE", "Content explicitly authorizes playable registration " + id)
			check(entry.scene.begins_with("res://game/levels/mutsumi/batch_02/") and entry.resource.begins_with("res://game/levels/mutsumi/batch_02/"), "new entries use delivered Batch02 resources " + id)
	var all_ids: Array = ids.duplicate()
	for row in spatial.levels: all_ids.append(row.id)
	for index in ids.size():
		check(catalog.entries[index].id == ids[index], "Shell preserves formal ordering " + str(index))
		check(catalog.next_id(ids[index]) == (all_ids[index + 1] if index + 1 < all_ids.size() else ""), "one next hop or end of delivered catalog " + ids[index])
	check(catalog.find("unregistered_batch02").is_empty() and not catalog.is_available("unregistered_batch02") and catalog.next_id("unregistered_batch02").is_empty(), "unknown levels remain unavailable without an invented successor")
	var custom: Array[Dictionary] = [{"id":"fixture", "title":"Fixture", "scene":"res://tests/shell/fixture_level.tscn", "adapter":"signal"}]
	check(Catalog.new(custom).entries == custom, "explicit catalog injection remains supported")
	check(str(ProjectSettings.get_setting("application/run/main_scene")) == "res://game/shell/game_feel_shell.tscn", "default main scene is formal GameFeel Shell")
	finish()

func finish() -> void:
	print(JSON.stringify({"checks":checks, "failures":failures, "scope":"BETA_DEFAULT_CATALOG", "evidence_type":"OWNER_HEADLESS_CATALOG_CONTRACT", "human_acceptance":"NOT_RUN"}))
	quit(0 if failures.is_empty() else 1)
