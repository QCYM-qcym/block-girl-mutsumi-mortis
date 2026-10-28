extends "res://tests/beta_sprint/spatial_formal/graphical.gd"
## Owned native renderer; no OS input, no user save, no Human QA claim.
func frames(count: int = 4) -> void:
	for frame in count: await process_frame

func click(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	print(JSON.stringify({"ui_click":str(control.get_path()),"rect":str(control.get_global_rect()),"settings_before":shell.settings_open,"frame":Engine.get_process_frames()}))
	var motion := InputEventMouseMotion.new()
	motion.position = point
	Input.parse_input_event(motion)
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		Input.parse_input_event(event)
		await process_frame
	await frames()
	print(JSON.stringify({"settings_after":shell.settings_open,"state":shell.state}))

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shell-save="): save_path = arg.trim_prefix("--shell-save=")
		elif arg.begins_with("--evidence-dir="): evidence = arg.trim_prefix("--evidence-dir=")
	check(DisplayServer.get_name() != "headless", "actual Windows graphical renderer")
	check(not FileAccess.file_exists(save_path), "fresh isolated native profile")
	shell = load("res://game/shell/game_feel_shell.tscn").instantiate()
	shell.save_path = save_path
	root.add_child(shell)
	await frames(8)
	check(shell.view.backdrop.debug_state().active, "real menu character enabled")
	check(shell.view.buttons.continue.disabled, "actual fresh-save Continue remains locked")
	for size in [Vector2i(1920,1080),Vector2i(1280,720),Vector2i(960,720)]:
		root.size = size
		await frames(6)
		for layer in [0,1]:
			await click(shell.view.world_buttons[layer])
			check(shell.view.backdrop.debug_state().world_layer == layer, "mouse world selector updates actual character")
			for id in ["new","continue","select","settings","quit"]:
				check(root.get_visible_rect().encloses(shell.view.buttons[id].get_global_rect()), "main button fits actual viewport: " + id)
			await shot("main_%s_%dx%d" % ["surface" if layer == 0 else "inner",size.x,size.y])
			if size.x == 1280 and layer == 0:
				shell.view.buttons.quit.grab_focus()
				await key(KEY_TAB,true)
				await key(KEY_TAB,false)
				check(shell.view.world_buttons[0].has_focus(), "actual Tab reaches world toolbar with focus outline")
				await click(shell.view._toolbar.get_child(2))
				await create_timer(0.3).timeout
				await shot("character_turn")
				await click(shell.view._toolbar.get_child(3))
				await create_timer(0.3).timeout
				await shot("character_lean")
			await click(shell.view.buttons.settings)
			check(shell.settings_open, "native mouse opens real Settings transaction")
			check(shell.game_feel.ui._presentation_world == layer, "settings palette agrees with character")
			var ui = shell.game_feel.ui
			for control in [ui.settings_panel,ui.buttons.apply,ui.buttons.cancel]:
				check(root.get_visible_rect().encloses(control.get_global_rect()), "settings panel and fixed footer fit viewport")
			await shot("settings_%s_%dx%d" % ["surface" if layer == 0 else "inner",size.x,size.y])
			await click(ui.buttons.cancel)
			check(not shell.settings_open and shell.state == shell.State.MAIN_MENU, "native mouse cancels and restores menu")
			if shell.settings_open:
				print(JSON.stringify({"applying":ui._applying,"cancel_disabled":ui.buttons.cancel.disabled,"focus":str(root.gui_get_focus_owner())}))
				quit(1)
				return
		await click(shell.view.buttons.select)
		check(shell.view.buttons.has("level:spatial_rubik_spatial_puzzle_01"), "real ten-level chapter catalog remains visible")
		var last = shell.view.buttons.get("level:spatial_rubik_spatial_puzzle_01")
		if last: last.grab_focus()
		await frames(6)
		await shot("level_select_%dx%d" % [size.x,size.y])
		shell.view.buttons.main.grab_focus()
		await frames(6)
		for id in ["main","settings"]:
			var row = shell.view.buttons[id]
			check(row._title.get_theme_font("font").get_string_size(row.display_text,HORIZONTAL_ALIGNMENT_LEFT,-1,row._title.get_theme_font_size("font_size")).x <= row._title.size.x, "catalog footer title fits: " + id)
		await shot("catalog_footer_%dx%d" % [size.x,size.y])
		await action("main")
	# Actual saved options and real legacy level; no fake completion/unlock.
	await click(shell.view.world_buttons[0])
	await click(shell.view.buttons.settings)
	var ui = shell.game_feel.ui
	ui.sliders.master.value = 37
	ui.buttons.reduced_motion.button_pressed = true
	await frames()
	check(shell.view.backdrop.debug_state().reduced_motion, "actual reduced-motion preview reaches character")
	var pose: Transform3D = shell.view.backdrop.debug_state().pose
	await create_timer(0.15).timeout
	check(shell.view.backdrop.debug_state().pose.is_equal_approx(pose), "reduced motion holds actual visual pose")
	await click(ui.buttons.apply)
	check(not shell.settings_open and is_equal_approx(float(shell.store.load_save().settings.master),0.37), "real settings Apply persists master volume")
	await click(shell.view.buttons.new)
	check(shell.current_id == "mutsumi_l01" and shell.state == shell.State.PLAYING, "native mouse New enters actual L01")
	check(not shell.view.backdrop.debug_state().active, "gameplay disables avatar rendering")
	await frames(6)
	await shot("real_L01_gameplay")
	shell.pause_game()
	await frames()
	await shot("real_L01_pause")
	check(not shell.view.backdrop.debug_state().active, "pause retains actual gameplay scene")
	shell.open_settings()
	await frames()
	await shot("real_L01_pause_settings")
	shell.cancel_settings()
	shell.resume_game()
	check(shell.state == shell.State.PLAYING, "Resume restores actual gameplay")
	shell.reset_current()
	await frames()
	check(shell.adapter.level.get_presentation_world() == 0, "legacy Reset retains authoritative Surface")
	shell.show_main_menu()
	await frames()
	check(shell.view.backdrop.debug_state().active, "return menu restores avatar")
	var report := {"checks":checks,"failures":failures,"captures":captures,"display":DisplayServer.get_name(),"human_qa":"NOT_RUN","input_scope":"engine-local synthetic UI events, no OS keyboard/mouse","progression_scope":"fresh ten-level catalog and L01 entry/pause/reset, no new full-playthrough claim"}
	FileAccess.open(evidence.path_join("native_graphical_report.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	if failures.is_empty(): shell.call_deferred("request_quit")
	else: quit(1)
