extends "res://tests/beta_sprint/three_d_02/test_gameplay.gd"
## Limited integration regression: real menu, old three3D scenes and native transitions.
var cases: Array = []

func menu_press(id: String) -> void:
	check(shell.view.buttons.has(id) and not shell.view.buttons[id].disabled, "formal menu entry enabled: " + id)
	if not shell.view.buttons.has(id) or shell.view.buttons[id].disabled:
		return
	var control: Control = shell.view.buttons[id]
	control.grab_focus()
	await delay(0.15)
	var rect := control.get_global_rect()
	check(root.get_visible_rect().grow(1).encloses(rect), "focused formal menu control within viewport: " + id)
	var at := rect.get_center()
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = at
		event.global_position = at
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await delay(0.25)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="): evidence = arg.trim_prefix("--evidence-dir=")
		elif arg.begins_with("--shell-save="): save_path = arg.trim_prefix("--shell-save=")
		elif arg.begins_with("--head="): head = arg.trim_prefix("--head=")
	if evidence.is_empty() or not save_path.begins_with("user://beta_sprint/b3d02_"):
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(evidence)
	check(DisplayServer.get_name() != "headless", "real graphical regression")
	check(not FileAccess.file_exists(save_path), "fresh isolated old-three already-unlocked fixture")
	var store := SaveStore.new(save_path,"mutsumi_l01")
	var fixture := store.defaults()
	fixture.has_progress = true
	fixture.unlocked = ["mutsumi_l01","mutsumi_l02","mutsumi_l03"]
	fixture.settings.muted = true
	check(store.save(fixture), "explicit fixture uses original SaveStore")
	shell = load("res://game/shell/game_shell.tscn").instantiate()
	shell.save_path = save_path
	root.add_child(shell)
	shell.adapter.completed.connect(on_completion)
	await delay(0.35)
	for id in ["mutsumi_l01","mutsumi_l02","mutsumi_l03"]:
		level_id = id
		current_run = id
		var before := checks
		await menu_press("select")
		await menu_press("level:" + id)
		game = shell.adapter.level
		check(game != null and shell.state == shell.State.PLAYING and shell.current_id == id, "actual formal menu loads " + id)
		if game == null:
			break
		check(game.presenter is Node3D and game.using_3d and not game.board.visible, "original approved3D entry " + id)
		await shot("spawn")
		await visual_check("entry")
		var pose: String = game.mover.orientation.key()
		for quarter in 4:
			await tap(KEY_E)
			check(game.view.current == posmod(quarter+1,4) and game.mover.orientation.key() == pose, "native four-quarter camera preserves cube " + id)
			await visual_check("camera")
		if id == "mutsumi_l01":
			await move(Vector2i.UP,3)
			await shift_probe()
			await move(Vector2i.UP)
			await visual_check("existing Inner bridge")
		elif id == "mutsumi_l02":
			await move(Vector2i.UP,2)
			await shift_probe()
			await move(Vector2i.UP,2)
			await move(Vector2i.RIGHT)
			await visual_check("existing Inner roll")
		else:
			await connection_probes()
			await route_l03("focused")
			check(game.graph.complete and shell.state == shell.State.LEVEL_COMPLETE, "native L03 Goal reaches formal Shell")
		await reset_check()
		await shot("reset")
		await tap(KEY_ESCAPE)
		check(shell.state == shell.State.PAUSED, "native Esc Pause " + id)
		await menu_press("resume")
		check(shell.state == shell.State.PLAYING, "actual mouse Resume " + id)
		await tap(KEY_ESCAPE)
		await menu_press("main")
		check(shell.state == shell.State.MAIN_MENU and shell.adapter.level == null, "native return Main " + id)
		game = null
		cases.append({"id":id,"checks":checks-before,"coverage":"formal mouse menu entry, four views, cube/world visual parity, Reset, Pause/Resume/Main", "goal":"PASS" if id == "mutsumi_l03" else "PREVIOUS_PASS_PRESERVED_NOT_RERUN"})
	var report := {"checks":checks,"failures":failures,"pid":OS.get_process_id(),"head":head,"project":ProjectSettings.globalize_path("res://"),"display":DisplayServer.get_name(),"level_id":"old_three_focused","save_path":save_path,"cases":cases,"screenshots":checkpoints,"doubles":[],"scope":"limited current integrated3D regression; L01/L02 full playthroughs and new Daily Human QA not claimed"}
	FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	shell.show_main_menu()
	root.remove_child(shell)
	shell.free()
	await process_frame
	print("PHASE2 OLD THREE FOCUSED: ",checks," checks; failures=",failures)
	quit(0 if failures.is_empty() else 1)
