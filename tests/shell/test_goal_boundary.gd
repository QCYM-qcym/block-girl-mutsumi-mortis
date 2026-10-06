extends SceneTree
## Real P-01 actions at the Goal boundary; no graph.complete assignment.
var shell
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		printerr("FAIL: ", label)

func step(game, direction: int, count: int = 1) -> void:
	for i in count:
		game.mover.press(900, direction)
		game.mover.release(900)
		game.mover.tick(0.33)

func solve(game) -> void:
	step(game, 0, 3)
	game.mover.shift()
	game.mover.tick(0.26)
	step(game, 0, 2)
	step(game, 1, 3)
	game.view.request_rotate_right()
	game.view.tick(0.41)
	game.graph.recalculate(game.view, game.mover.world)
	step(game, 0)
	game.mover.shift()
	game.mover.tick(0.26)
	step(game, 0, 4)

func run() -> void:
	for action in ["reset", "leave"]:
		var path: String = "user://shell_tests/goal_" + action + "_" + str(Time.get_ticks_usec()) + "/progress.json"
		shell = load("res://game/shell/game_shell.tscn").instantiate()
		shell.save_path = path
		root.add_child(shell)
		shell.new_game()
		var game = shell.adapter.level
		game.set_process(false)
		solve(game)
		check(game.graph.complete and game.mover.cell == Vector2i(13, 0), "real actions reach authored Goal " + action)
		check(shell.state == shell.State.LEVEL_COMPLETE and shell.progress.completed == ["p01"], "Goal is recorded immediately before presentation delay " + action)
		if action == "reset":
			var event := InputEventKey.new()
			event.keycode = KEY_R
			event.physical_keycode = KEY_R
			event.pressed = true
			Input.parse_input_event(event)
			await process_frame
			check(game.mover.cell == Vector2i(0, 5) and not game.graph.complete, "immediate R calls formal Reset")
		else:
			shell.show_main_menu()
		var Store = load("res://game/shell/save_store.gd")
		var saved: Dictionary = Store.new(path, "p01").load_save()
		check(saved.completed == ["p01"], "completion survives immediate " + action)
		shell.queue_free()
		await create_timer(0.15).timeout
	print("SHELL GOAL BOUNDARY: ", checks, " checks, failures=", failures)
	quit(0 if failures.is_empty() else 1)
