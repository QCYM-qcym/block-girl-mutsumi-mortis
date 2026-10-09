extends "res://tests/beta_sprint/game_feel_owner_07/test_ui.gd"
## Actual Control/input checks at three logical viewports; no graphical integrated-build claim.
var observations: Array[Dictionary] = []

func key(code: int) -> void:
	for pressed in [true,false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await settle()

func click(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	Input.parse_input_event(motion)
	await process_frame
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await settle()

func run() -> void:
	check(DisplayServer.get_name() == "headless", "isolated owner headless input run")
	ui = load(UI_PATH).new()
	root.add_child(ui)
	await settle()
	var saved := {"master":0.5,"music":0.5,"sfx":0.5,"fullscreen":false,"muted":false}
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for area in [Vector2i(1920,1080),Vector2i(1280,720),Vector2i(960,720)]:
		root.size = area
		await settle()
		ui.open_settings(saved)
		await settle()
		check(root.size == area and root.get_visible_rect().size == Vector2(area), "measured requested logical viewport "+str(area))
		check(root.get_visible_rect().encloses(ui.settings_panel.get_global_rect()), "Settings panel contained by viewport "+str(area))
		for control in ui.focus_order:
			check(control.has_focus(), "native Tab visits control "+str(control.name)+" "+str(area))
			if control == ui.sliders.master:
				var initial: float = control.value
				await key(KEY_LEFT)
				check(control.value == initial-1, "native arrow changes real audio slider "+str(area))
			var row: Control = control.get_parent() if control is HSlider else control
			var clip: Rect2 = ui.settings_scroll.get_global_rect() if row.is_inside_tree() and ui.settings_scroll.is_ancestor_of(row) else ui.settings_panel.get_global_rect()
			check(clip.grow(1).encloses(row.get_global_rect()), "focused row/label readable inside scroll or panel "+str(area))
			await key(KEY_TAB)
		check(ui.focus_order[0].has_focus(), "native Tab wraps to first control "+str(area))
		await click(ui.buttons.cancel)
		check(not ui.settings_open and root.gui_get_focus_owner() == null, "native mouse Cancel returns without hidden focus "+str(area))
		ui.open_settings(saved)
		await settle()
		await key(KEY_ESCAPE)
		check(not ui.settings_open, "native Esc cancels lab overlay "+str(area))
		ui.bind_context("unit_session","unit_run")
		ui.consume_event(cue(1,"PERSPECTIVE_FALL_APPLIED","STARTED"))
		await settle()
		check(root.get_visible_rect().encloses(ui.feedback_panel.get_global_rect()), "passive feedback fits viewport "+str(area))
		observations.append({"requested":str(area),"measured":str(root.get_visible_rect()),"settings":str(ui.settings_panel.get_global_rect()),"scroll":str(ui.settings_scroll.get_global_rect()),"feedback":str(ui.feedback_panel.get_global_rect())})
	var report := {"checks":checks,"failures":failures,"observations":observations,"pid":OS.get_process_id(),"display":DisplayServer.get_name(),"input":"native Input.parse_input_event; keyboard and mouse", "fixture_kind":"PRESENTATION_CONTRACT_UNIT","authoritative_runtime":false,"doubles":["immutable cue DTO fixtures","standalone lab UI"],"fresh_integrated_build_graphical":"PENDING_00","human_acceptance":"NOT_RUN","user_data_dir":OS.get_user_data_dir()}
	DirAccess.make_dir_recursive_absolute(evidence)
	var file := FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t")); file.close()
	ui.queue_free()
	await settle()
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
