extends "res://tests/shell/pause_text/test_pause_text.gd"
## Coordinator automated focused input/render check; never Human acceptance.
var cases: Array[Dictionary] = []
var completion_events := 0
var tested_head := ""

func record(label: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var name := "%s_%dx%d.png" % [label, root.size.x, root.size.y]
	image.save_png(evidence.path_join(name))
	cases.append({"case":label, "window":str(root.size), "screen":shell.view.screen,
		"state":shell.state, "settings_open":shell.settings_open,
		"backing_visible":shell.view.get("_pause_surface").is_visible_in_tree(), "screenshot":name})
	check(shell.view.get("_pause_surface").is_visible_in_tree() == (shell.state == shell.State.PLAYING and not shell.settings_open),
		"pause backing visibility follows actual screen: " + label)

func state_of(level: Node) -> Dictionary:
	return {"cell":str(level.mover.cell), "moves":level.mover.moves, "world":level.mover.world,
		"view":level.view.current, "phase":level.mover.phase, "complete":level.graph.complete,
		"hint":level.hints.text, "hint_alpha":level.hints.alpha}

func hint_presentation(level: Node, label: String) -> void:
	check(level.hint_label.text == level.hints.text and not level.hints.text.is_empty(), label + " existing hint text is presented")
	check(level.hint_label.is_visible_in_tree() and level.hint_label.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		label + " hint is visible and does not intercept input")
	check(is_equal_approx(level.hint_label.modulate.a, level.hints.alpha), label + " original hint alpha is preserved")
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	var position: Vector2 = level.hint_label.global_position
	var region := Rect2i(Vector2i(root.size.x / 2 - 80, int(position.y) - 30), Vector2i(160, 64))
	region = region.intersection(Rect2i(Vector2i.ZERO, frame.get_size()))
	var strokes := 0
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			if contrast(frame.get_pixel(x, y), Color("172327")) >= 3.0:
				strokes += 1
	check(strokes > 40, label + " actual Hint keycaps are rendered")

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--head="): tested_head = arg.trim_prefix("--head=")
	DirAccess.make_dir_recursive_absolute(evidence)
	check(DisplayServer.get_name() != "headless", "focused case uses graphical rendering")
	shell = load("res://game/shell/game_shell.tscn").instantiate()
	shell.save_path = "user://beta_sprint/ui_08_001_focused_" + str(Time.get_ticks_usec()) + "/progress.json"
	root.add_child(shell)
	shell.adapter.completed.connect(func(): completion_events += 1)
	await create_timer(0.35).timeout
	check(shell.state == shell.State.MAIN_MENU and shell.view.screen == "main", "actual Main Menu entry")
	check(shell.view.buttons["continue"].disabled, "fresh isolated profile keeps Continue disabled")
	await key(KEY_TAB)
	check(root.gui_get_focus_owner() == shell.view.buttons["select"], "Main Tab skips disabled Continue")
	# Fixture only: already-unlocked L02 avoids rerunning Goal/unlock/Cold Continue.
	shell.progress.has_progress = true
	shell.progress.recent = "mutsumi_l02"
	shell.progress.unlocked = ["mutsumi_l01", "mutsumi_l02"]
	shell.progress.completed = ["mutsumi_l01"]
	await key(KEY_ENTER)
	check(shell.state == shell.State.LEVEL_SELECT, "Main keyboard action opens Level Select")
	check(not shell.view.buttons["level:mutsumi_l02"].disabled, "existing unlocked fixture displays L02 as available")
	check(shell.view.buttons["level:mutsumi_l03"].disabled, "unrelated locked L03 remains disabled")
	await record("level_select")
	await click(shell.view.buttons["level:mutsumi_l02"].get_global_rect().get_center())
	check(shell.state == shell.State.PLAYING and shell.current_id == "mutsumi_l02", "actual Level Select mouse enters L02")
	var level: Node = shell.adapter.level
	await create_timer(0.3).timeout
	for requested in SIZES:
		root.size = requested
		await create_timer(0.3).timeout
		# Resizing a Windows launch may trigger the existing focus-loss Pause.
		# Record that state and use its real Escape action to establish PLAYING.
		if shell.state == shell.State.PAUSED:
			await record("resize_focus_loss_pause")
			await key(KEY_ESCAPE)
		check(shell.state == shell.State.PLAYING, "actual PLAYING precondition after native resize")
		check(root.content_scale_mode == Window.CONTENT_SCALE_MODE_DISABLED, "native pixel mode retained")
		await move_mouse(Vector2(20, requested.y / 2.0))
		await inspect_label(requested, "focused_playing")
		await hint_presentation(level, "Hint " + str(requested))
		var before := state_of(level)
		await click(shell.view.pause_button.get_global_rect().get_center())
		check(shell.state == shell.State.PAUSED and shell.view.screen == "pause", "L02 mouse Pause " + str(requested))
		await record("pause")
		await create_timer(0.25).timeout
		check(state_of(level) == before and level.process_mode == Node.PROCESS_MODE_DISABLED, "Pause freezes existing gameplay/Hint state")
		await click(shell.view.buttons["resume"].get_global_rect().get_center())
		check(shell.state == shell.State.PLAYING and shell.adapter.level == level, "Pause native Resume retains same L02")
		check(state_of(level) == before, "Resume causes no extra movement or Hint reset")
		await key(KEY_ESCAPE)
		check(shell.state == shell.State.PAUSED, "Escape opens actual Pause")
		await key(KEY_ESCAPE)
		check(shell.state == shell.State.PLAYING and state_of(level) == before, "Escape resumes same state")
		await move_mouse(Vector2(20, requested.y / 2.0))
		await inspect_label(requested, "focused_resumed")
		await key(KEY_ESCAPE)
		await click(shell.view.buttons["settings"].get_global_rect().get_center())
		check(shell.settings_open and shell.view.screen == "settings", "Pause mouse Settings remains operable")
		check(root.gui_get_focus_owner() == shell.view.sliders["master"], "Settings keeps original approved focus order")
		var saved_master: float = shell.progress.settings.master
		var saved_bus := AudioServer.get_bus_volume_db(0)
		await key(KEY_LEFT)
		check(shell.preview_settings.master < saved_master and AudioServer.get_bus_volume_db(0) < saved_bus,
			"Settings native slider previews original audio mapping")
		await record("settings")
		await key(KEY_ESCAPE)
		check(not shell.settings_open and shell.state == shell.State.PAUSED, "Settings Escape Cancel returns to Pause")
		check(is_equal_approx(AudioServer.get_bus_volume_db(0), saved_bus), "Cancel restores existing saved settings")
		check(state_of(level) == before, "Settings navigation does not leak gameplay input")
		await click(shell.view.buttons["settings"].get_global_rect().get_center())
		await click(shell.view.buttons["apply"].get_global_rect().get_center())
		check(not shell.settings_open and shell.state == shell.State.PAUSED, "Settings native Apply returns to Pause")
		check(shell.store.last_error.is_empty(), "original isolated settings save remains usable")
		await key(KEY_ESCAPE)
		await record("hint_and_resumed")
		await hint_presentation(level, "Resumed Hint " + str(requested))
	check(completion_events == 0 and not level.graph.complete, "focused scope has no Goal or unlock rerun")
	await key(KEY_ESCAPE)
	await click(shell.view.buttons["main"].get_global_rect().get_center())
	check(shell.state == shell.State.MAIN_MENU and shell.adapter.level == null, "Pause Main returns to existing menu")
	await record("main_menu_return")
	await click(shell.view.buttons["settings"].get_global_rect().get_center())
	check(shell.settings_open and shell.view.screen == "settings", "Main Menu mouse Settings works")
	await click(shell.view.buttons["cancel"].get_global_rect().get_center())
	check(shell.view.screen == "main" and not shell.settings_open, "Main Settings Cancel returns to menu")
	await click(shell.view.buttons["select"].get_global_rect().get_center())
	check(shell.view.screen == "select", "Main mouse Level Select remains operable")
	await key(KEY_ESCAPE)
	check(shell.view.screen == "main", "Level Select Escape returns to menu")
	var report := {"issue":"UI-08-001", "checks":checks, "failures":failures, "head":tested_head,
		"pid":OS.get_process_id(), "project":ProjectSettings.globalize_path("res://"), "display":DisplayServer.get_name(),
		"renderer":RenderingServer.get_current_rendering_method(), "device":RenderingServer.get_video_adapter_name(),
		"cases":cases, "pause_observations":observations, "completion_events":completion_events,
		"save_path":shell.save_path, "human_qa":"NOT_RUN", "issue_status":"OPEN / READY_FOR_08_RECHECK",
		"scope":"Seven focused interactions only; explicit unlocked L02 fixture; no full playthrough/unlock/Cold Continue"}
	var file := FileAccess.open(evidence.path_join("report.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	shell.queue_free()
	await create_timer(0.3).timeout
	print("UI_08_001_FOCUSED: ", checks, " checks, failures=", failures)
	quit(0 if failures.is_empty() else 1)
