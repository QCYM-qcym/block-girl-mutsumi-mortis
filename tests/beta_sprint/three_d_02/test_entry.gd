extends SceneTree
## Native entry contract; intentionally does not preload future presentation classes.
var checks := 0
var failures: Array[String] = []
var level_id := ""
var evidence := ""

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--level="): level_id = arg.trim_prefix("--level=")
		elif arg.begins_with("--evidence-dir="): evidence = arg.trim_prefix("--evidence-dir=")
	if level_id not in ["mutsumi_l01", "mutsumi_l02", "mutsumi_l03"] or evidence.is_empty():
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(evidence)
	var names := {"mutsumi_l01":"l01_another_world", "mutsumi_l02":"l02_between_shores", "mutsumi_l03":"l03_lines_meet"}
	var scene: PackedScene = load("res://game/levels/mutsumi/batch_01/" + names[level_id] + ".tscn")
	check(scene != null, "native Content scene loads")
	if scene == null:
		finish()
		return
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	check(game.content.level_id == level_id, "native stable Content ID retained")
	check(game.mover.cell == game.content.spawn and game.mover.world == 0 and game.view.current == 0, "original Runtime Spawn retained")
	check(game.board != null, "original Pixel regression board retained")
	check(game.has_method("display_3d"), "native entry exposes presentation-only 3D/Pixel selection")
	check(not game.find_children("*", "Node3D", true, false).is_empty(), "native entry contains a real 3D Presenter")
	if game.has_method("display_3d"):
		check(game.presenter != null and game.presenter is Node3D and not game.board.visible, "native entry defaults to attached 3D presentation")
		var before = [game.mover.cell, game.mover.world, game.view.current, game.mover.orientation.key()]
		game.display_3d(false)
		check(game.board.visible and before == [game.mover.cell, game.mover.world, game.view.current, game.mover.orientation.key()], "Pixel selection preserves native gameplay")
		game.display_3d(true)
		check(not game.board.visible and before == [game.mover.cell, game.mover.world, game.view.current, game.mover.orientation.key()], "3D selection preserves native gameplay")
	for player in game.find_children("*", "AudioStreamPlayer", true, false): player.stop()
	await create_timer(0.12).timeout
	root.remove_child(game)
	game.free()
	await create_timer(0.12).timeout
	finish()

func finish() -> void:
	FileAccess.open(evidence.path_join("report.json"), FileAccess.WRITE).store_string(JSON.stringify({"checks":checks, "failures":failures, "pid":OS.get_process_id(), "level_id":level_id, "project":ProjectSettings.globalize_path("res://"), "display":DisplayServer.get_name(), "engine":Engine.get_version_info()}, "\t"))
	print("B3D02 ENTRY ", level_id, ": ", checks, " checks; failures=", failures)
	quit(0 if failures.is_empty() else 1)
