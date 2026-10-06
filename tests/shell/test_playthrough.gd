extends SceneTree
var shell
var checks := 0
var failures: Array[String] = []
var evidence := "res://tests/shell/evidence/playthrough"
var saves := "user://shell_tests/playthrough_" + str(Time.get_ticks_usec()) + "/progress.json"

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		printerr("FAIL: ", label)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="):
			evidence = arg.trim_prefix("--evidence-dir=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(evidence))
	shell = load("res://game/shell/game_shell.tscn").instantiate()
	shell.save_path = saves
	root.add_child(shell)
	await delay(0.4)
	check(DisplayServer.get_name() != "headless", "real graphical renderer for keyboard/mouse acceptance")
	check(shell.state == shell.State.MAIN_MENU and shell.view.buttons["continue"].disabled, "CASE A cold menu")
	await shot("01_main_menu")
	# Keyboard focus/Enter enters New Game (no direct button signal call).
	shell.view.buttons["new"].grab_focus()
	await tap(KEY_ENTER, 0.5)
	check(shell.state == shell.State.PLAYING and shell.current_id == "p01", "keyboard Enter starts actual P-01")
	var game = shell.adapter.level
	await key(KEY_W, true)
	await delay(0.1)
	await tap(KEY_ESCAPE, 0.04)
	var cell: Vector2i = game.mover.cell
	var elapsed: float = game.mover.elapsed
	await key(KEY_W, false)
	await delay(0.5)
	check(shell.state == shell.State.PAUSED and game.mover.cell == cell and game.mover.elapsed == elapsed, "Pause freezes a real in-flight roll")
	check(game.mover.order.is_empty(), "Pause clears held movement")
	await shot("02_pause")
	await click_button("resume")
	await delay(0.5)
	check(shell.state == shell.State.PLAYING and game.mover.cell == Vector2i(0, 4) and game.mover.phase == "idle", "resume completes one roll without ghost held input")
	# Click on the actual pause HUD must not also start a game drag.
	await click_at(shell.view.pause_button.get_global_rect().get_center())
	check(shell.state == shell.State.PAUSED and not game.view.dragging, "mouse Pause is intercepted before gameplay drag")
	await click_button("reset")
	await delay(0.2)
	check(shell.state == shell.State.PLAYING and game.mover.cell == Vector2i(0, 5) and game.mover.moves == 0, "CASE D mouse Pause/Reset uses formal level reset")
	for mode in ["keyboard", "mouse"]:
		if mode == "mouse":
			await tap(KEY_ESCAPE)
			await click_button("reset")
		await tap(KEY_W, 0.4, 3)
		await tap(KEY_SPACE, 0.3)
		await tap(KEY_W, 0.4, 2)
		await tap(KEY_D, 0.4, 3)
		check(game.mover.cell == Vector2i(3, 0) and game.mover.world == 1, "actual authored bridge route " + mode)
		if mode == "keyboard":
			await tap(KEY_E, 0.5)
		else:
			await drag(Vector2(500, 450), Vector2(660, 450))
		check(game.view.current == 1 and game.graph.link.active, "authored Perspective Connection " + mode)
		await tap(KEY_W, 0.4)
		await tap(KEY_SPACE, 0.3)
		await tap(KEY_W, 0.4, 4)
		await delay(2.1)
		check(game.graph.complete and game.mover.cell == Vector2i(13, 0), "real Goal completes " + mode)
		check(shell.state == shell.State.LEVEL_COMPLETE and shell.progress.completed == ["p01"], "formal Shell completion and recorded progress " + mode)
		check(shell.view.buttons["next"].disabled, "last available production level has no invented next level " + mode)
		await shot("03_complete_" + mode)
		if mode == "keyboard":
			await tap(KEY_R)
			check(shell.state == shell.State.PLAYING and not game.graph.complete, "completion R replay works with suspended subtree")
	# Navigation and settings are mouse-operated and use real GUI events.
	await click_button("select")
	check(shell.state == shell.State.LEVEL_SELECT and not shell.view.buttons["level:p01"].disabled, "CASE A completion returns to selectable completed level")
	await shot("04_level_select")
	await click_button("settings")
	var slider: HSlider = shell.view.sliders["master"]
	await click_at(slider.get_global_rect().position + Vector2(slider.size.x * 0.4, slider.size.y * 0.5))
	check(shell.preview_settings.master > 0.2 and shell.preview_settings.master < 0.6, "mouse slider previews Master Volume")
	await shot("05_settings")
	await click_button("fullscreen")
	await delay(0.3)
	check(root.mode == Window.MODE_FULLSCREEN, "fullscreen toggle affects actual display")
	await click_button("fullscreen")
	await delay(0.3)
	check(root.mode == Window.MODE_WINDOWED, "windowed toggle returns to actual window")
	await click_button("apply")
	check(shell.state == shell.State.LEVEL_SELECT and shell.view.screen == "select", "CASE C settings apply returns to correct source screen")
	var persisted_master: float = shell.progress.settings.master
	await tap(KEY_ESCAPE)
	check(shell.state == shell.State.MAIN_MENU and not shell.view.buttons["continue"].disabled, "CASE E select/back reaches Main with Continue")
	await click_button("continue")
	await delay(0.3)
	game = shell.adapter.level
	check(shell.current_id == "p01" and game.mover.cell == Vector2i(0, 5), "CASE B Continue restarts recent authored level")
	await tap(KEY_M)
	check(shell.progress.settings.get("muted", false) and is_equal_approx(shell.progress.settings.master, persisted_master) and AudioServer.is_bus_mute(0), "M mute is persisted while chosen gain is preserved")
	await tap(KEY_M)
	check(not shell.progress.settings.muted and is_equal_approx(shell.progress.settings.master, persisted_master) and not AudioServer.is_bus_mute(0), "M restores the previous volume")
	# Pause during drag and cancel via existing focus-loss lifecycle.
	await mouse(true, Vector2(500, 450))
	await motion(Vector2(530, 450))
	await tap(KEY_ESCAPE, 0.1)
	await mouse(false, Vector2(660, 450))
	await tap(KEY_ESCAPE, 0.4)
	check(shell.state == shell.State.PLAYING and not game.view.busy and game.view.current == 0, "pause cancels drag without release ghost (state=%s busy=%s view=%s screen=%s)" % [shell.state, game.view.busy, game.view.current, shell.view.screen])
	await tap(KEY_ESCAPE)
	await click_button("settings")
	await tap(KEY_ESCAPE)
	check(shell.state == shell.State.PAUSED and shell.view.screen == "pause", "Pause/settings/Escape retains suspended gameplay")
	await click_button("main")
	for size in [Vector2i(900, 700), Vector2i(1280, 900)]:
		root.size = size
		await delay(0.15)
		for button in shell.view.buttons.values():
			var bounds: Rect2 = button.get_global_rect()
			check(bounds.position.x >= 0 and bounds.position.y >= 0 and bounds.end.x <= size.x and bounds.end.y <= size.y, "menu button remains reachable at " + str(size))
		await shot("06_menu_" + str(size.y))
	var Store = load("res://game/shell/save_store.gd")
	var reopened: Dictionary = Store.new(saves, "p01").load_save()
	check(reopened.completed == ["p01"] and is_equal_approx(reopened.settings.master, persisted_master), "disk contains exact completed progress and applied settings")
	var report := {"checks": checks, "failures": failures, "display": DisplayServer.get_name(), "renderer": RenderingServer.get_current_rendering_method(), "save_path": saves, "master": persisted_master, "human_operated": false}
	var f := FileAccess.open(evidence.path_join("report.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "\t"))
	f.close()
	shell.queue_free()
	await delay(0.25)
	print("SHELL GRAPHICAL: ", checks, " checks, failures=", failures)
	quit(0 if failures.is_empty() else 1)

func delay(seconds: float) -> void:
	await create_timer(seconds).timeout

func key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	await process_frame

func tap(code: int, wait: float = 0.1, count: int = 1) -> void:
	for i in count:
		await key(code, true)
		await key(code, false)
		await delay(wait)

func mouse(pressed: bool, at: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = at
	Input.parse_input_event(event)
	await process_frame

func motion(at: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = at
	Input.parse_input_event(event)
	await process_frame

func click_at(at: Vector2) -> void:
	await mouse(true, at)
	await mouse(false, at)
	await delay(0.15)

func click_button(id: String) -> void:
	await click_at(shell.view.buttons[id].get_global_rect().get_center())

func drag(from: Vector2, to: Vector2) -> void:
	await mouse(true, from)
	await motion(to)
	await mouse(false, to)
	await delay(0.5)

func shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(evidence.path_join(label + ".png"))
