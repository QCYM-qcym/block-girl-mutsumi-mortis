extends SceneTree
## Entry contract is tested without preloading an undelivered 3D implementation.
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label)

func run() -> void:
	var evidence := OS.get_environment("ART_VERTICAL_EVIDENCE")
	if evidence.is_empty():
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(evidence)
	var scene: PackedScene = load("res://game/levels/mutsumi/batch_01/l01_another_world.tscn")
	check(scene != null, "formal L01 scene loads")
	if scene == null:
		finish(evidence)
		return
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	check(game.content.level_id == "mutsumi_l01", "entry retains formal L01 identity")
	check(game.mover.cell == game.content.spawn, "entry retains existing gameplay Spawn")
	check(game.board != null, "Pixel regression reference remains attached")
	check(game.has_method("display_3d"), "L01 exposes presentation-only 3D/Pixel selection")
	check(not game.find_children("*", "Node3D", true, false).is_empty(), "formal L01 entry contains a real 3D Presenter")
	# Entry-only SceneTree exits immediately; drain its own ambience playback first.
	for player in game.find_children("*", "AudioStreamPlayer", true, false):
		player.stop()
	await create_timer(0.12).timeout
	root.remove_child(game)
	game.free()
	game = null
	await create_timer(0.12).timeout
	finish(evidence)

func finish(evidence: String) -> void:
	var file := FileAccess.open(evidence.path_join("report.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"pid":OS.get_process_id(),"project":ProjectSettings.globalize_path("res://"),"engine":Engine.get_version_info()}, "\t"))
	file.close()
	print("L01 ART ENTRY: ", checks, " checks; failures=", failures)
	quit(0 if failures.is_empty() else 1)
