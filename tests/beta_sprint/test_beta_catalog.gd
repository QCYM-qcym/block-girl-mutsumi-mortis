extends SceneTree
const Catalog = preload("res://game/shell/level_catalog.gd")
var checks := 0
var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)

func _initialize() -> void:
	var catalog := Catalog.new()
	var ids := ["mutsumi_l01", "mutsumi_l02", "mutsumi_l03"]
	check(catalog.entries.size() == 3, "Beta default catalog contains the three delivered levels")
	check(catalog.first_id() == ids[0], "Beta begins with formal L-01")
	for id in ids:
		var entry: Dictionary = catalog.find(id)
		check(not entry.is_empty(), "stable level ID registered: " + id)
		if entry.is_empty():
			continue
		check(catalog.is_available(id), "delivered scene can be loaded: " + id)
		check(entry.scene.begins_with("res://") and entry.resource.begins_with("res://"), "catalog uses project resources")
		var data: Resource = load(entry.resource)
		check(data != null and str(data.get("level_id")) == id, "catalog matches formal Content metadata ID")
		check(data != null and entry.title == data.get("display_title"), "Shell displays formal Content metadata title")
	check(catalog.next_id(ids[0]) == ids[1] and catalog.next_id(ids[1]) == ids[2], "Beta ordering is L-01 then L-02 then L-03")
	check(catalog.next_id(ids[2]).is_empty(), "last delivered level does not invent L-04")
	var custom: Array[Dictionary] = [{"id":"fixture", "title":"Fixture", "scene":"res://tests/shell/fixture_level.tscn", "adapter":"signal"}]
	check(Catalog.new(custom).entries == custom, "explicit catalog injection remains supported")
	check(str(ProjectSettings.get_setting("application/run/main_scene")) == "res://game/shell/game_shell.tscn", "default main scene is Shell")
	print(JSON.stringify({"checks":checks, "failures":failures, "scope":"BETA_DEFAULT_CATALOG"}))
	quit(0 if failures.is_empty() else 1)
