extends "res://tests/playtest/test_batch_01_runtime.gd"
## Integration fixture: production Shell navigation + original Content input routes.
## Only menu/select/complete screenshots are exported; route screenshots are omitted.
const LEVEL_IDS := ["mutsumi_l01", "mutsumi_l02", "mutsumi_l03"]
const SAVED_SETTINGS := {"master": 0.42, "music": 0.23, "sfx": 0.67, "muted": true, "fullscreen": false}
var shell
var phase := ""
var evidence := ""
var isolated_save := ""
var metadata: Dictionary = {}
var cases: Array[String] = []
var completion_events := 0
var last_completion_id := ""
var last_completion_was_goal := false

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--phase="): phase = arg.trim_prefix("--phase=")
		elif arg.begins_with("--evidence-dir="): evidence = arg.trim_prefix("--evidence-dir=")
		elif arg.begins_with("--shell-save="): isolated_save = arg.trim_prefix("--shell-save=")
		elif arg.begins_with("--head="): metadata.head = arg.trim_prefix("--head=")
		elif arg.begins_with("--branch="): metadata.branch = arg.trim_prefix("--branch=")
		elif arg.begins_with("--content-sha="): metadata.content_sha = arg.trim_prefix("--content-sha=")
		elif arg.begins_with("--shell-sha="): metadata.shell_sha = arg.trim_prefix("--shell-sha=")
	if evidence.is_empty() or not isolated_save.begins_with("user://beta_sprint/") or phase not in ["seed", "restore"]:
		printerr("FAIL: require explicit isolated beta_sprint save, evidence path and phase")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(evidence)
	check(DisplayServer.get_name() != "headless", "graphical display required")
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://game/shell/game_shell.tscn", "production F5 entry is Shell")
	check(not FileAccess.file_exists(isolated_save) if phase == "seed" else FileAccess.file_exists(isolated_save), "phase has expected isolated save generation")
	shell = load("res://game/shell/game_shell.tscn").instantiate()
	root.add_child(shell)
	shell.adapter.completed.connect(observe_completion)
	await delay(0.45)
	check(shell.save_path == isolated_save, "Shell uses explicit isolated save")
	var ids: Array = []
	for entry in shell.catalog.entries:
		ids.append(entry.id)
		check(entry.adapter == "p01" and shell.catalog.is_available(entry.id), "registered Content Scene loads through p01 " + entry.id)
	check(ids == LEVEL_IDS, "Content catalog has exact three stable ids in order")
	if not failures.is_empty():
		await finish(false)
		return
	if phase == "seed": await seed_process()
	else: await restored_process()

func observe_completion() -> void:
	completion_events += 1
	last_completion_id = shell.current_id
	last_completion_was_goal = shell.adapter.level.graph.complete and shell.adapter.level.mover.phase == "complete"

func button(id: String) -> void:
	check(shell.view.buttons.has(id), "Shell button exists " + id)
	if not shell.view.buttons.has(id): return
	check(not shell.view.buttons[id].disabled, "Shell button enabled " + id)
	if shell.view.buttons[id].disabled: return
	shell.view.buttons[id].pressed.emit()
	await process_frame
	await delay(0.08)

func seed_process() -> void:
	check(shell.state == shell.State.MAIN_MENU and shell.view.buttons["continue"].disabled, "CASE1 no-save first menu disables Continue")
	check(not shell.progress.has_progress and shell.progress.unlocked == [LEVEL_IDS[0]], "CASE1 no-save unlocks only L01")
	await shot("ui_01_main_menu_cold")
	cases.append("CASE1 cold menu")
	await button("select")
	check(shell.state == shell.State.LEVEL_SELECT and shell.view.buttons.has("level:" + LEVEL_IDS[0]) and shell.view.buttons.has("level:" + LEVEL_IDS[1]) and shell.view.buttons.has("level:" + LEVEL_IDS[2]), "CASE2 three Content entries visible")
	check(not shell.view.buttons["level:" + LEVEL_IDS[0]].disabled and shell.view.buttons["level:" + LEVEL_IDS[1]].disabled and shell.view.buttons["level:" + LEVEL_IDS[2]].disabled, "CASE2 only L01 selectable")
	shell.start_level(LEVEL_IDS[1])
	check(shell.state == shell.State.LEVEL_SELECT and shell.adapter.level == null, "CASE2 locked L02 rejected by Shell")
	shell.start_level(LEVEL_IDS[2])
	check(shell.state == shell.State.LEVEL_SELECT and shell.adapter.level == null, "CASE2 locked L03 rejected by Shell")
	await button("main")
	await button("select")
	await shot("ui_02_select_locked")
	cases.append("CASE2 locked selection")
	await button("main")
	await button("settings")
	for key_name in ["master", "music", "sfx"]:
		shell.view.sliders[key_name].value = SAVED_SETTINGS[key_name] * 100.0
	shell.view.buttons["muted"].button_pressed = true
	await button("apply")
	check(settings_match(shell.progress.settings), "settings committed through Shell controls")
	await button("new")
	game = shell.adapter.level
	check(shell.state == shell.State.PLAYING and shell.current_id == LEVEL_IDS[0], "CASE3 New Game enters formal L01")
	check(game.content.quality == "FORMAL", "CASE3 L01 retains formal quality")
	var original_instance: int = game.get_instance_id()
	await key(KEY_W, true)
	await delay(0.10)
	await key(KEY_ESCAPE, true)
	await key(KEY_ESCAPE, false)
	var frozen_cell: Vector2i = game.mover.cell
	var frozen_elapsed: float = game.mover.elapsed
	await key(KEY_W, false)
	await delay(0.45)
	check(shell.state == shell.State.PAUSED and game.mover.cell == frozen_cell and game.mover.elapsed == frozen_elapsed and game.mover.order.is_empty(), "CASE3 Pause freezes real roll and clears held input")
	await button("resume")
	await delay(0.45)
	check(shell.state == shell.State.PLAYING and game.get_instance_id() == original_instance and game.mover.moves == 1, "CASE3 Resume retains instance and completes existing roll")
	await tap(KEY_E)
	await key(KEY_ESCAPE, true)
	await key(KEY_ESCAPE, false)
	await button("reset")
	check(game.get_instance_id() == original_instance and shell.state == shell.State.PLAYING, "CASE3 Pause Reset retains level instance")
	check_at_spawn("CASE3 formal reset")
	cases.append("CASE3 pause resume reset")
	await route_l01("normal")
	await delay(0.25)
	check_completion(LEVEL_IDS[0], 1)
	check(shell.progress.completed == [LEVEL_IDS[0]] and shell.progress.unlocked == [LEVEL_IDS[0], LEVEL_IDS[1]], "CASE4 L01 unlocks L02 through completion event")
	var persisted: Dictionary = shell.store.load_save()
	check(persisted.completed == [LEVEL_IDS[0]] and persisted.unlocked == [LEVEL_IDS[0], LEVEL_IDS[1]], "CASE4 completion saved to actual isolated store")
	await shot("ui_03_complete_l01")
	await button("select")
	check(shell.view.buttons["level:" + LEVEL_IDS[0]].text.ends_with("已通关") and not shell.view.buttons["level:" + LEVEL_IDS[1]].disabled and shell.view.buttons["level:" + LEVEL_IDS[2]].disabled, "CASE4 select reflects cleared L01 and unlocked L02")
	await shot("ui_04_select_l02_unlocked")
	await button("level:" + LEVEL_IDS[1])
	game = shell.adapter.level
	check(shell.current_id == LEVEL_IDS[1] and shell.state == shell.State.PLAYING, "CASE4 select enters L02")
	check_at_spawn("CASE4 L02 entry")
	cases.append("CASE4 L01 completion and L02 entry")
	await finish(true)

func restored_process() -> void:
	check(shell.state == shell.State.MAIN_MENU and not shell.view.buttons["continue"].disabled, "CASE5 independent process restores Continue")
	check(shell.progress.recent == LEVEL_IDS[1] and shell.progress.completed == [LEVEL_IDS[0]] and shell.progress.unlocked == [LEVEL_IDS[0], LEVEL_IDS[1]], "CASE5 disk restores exact progression")
	check(settings_match(shell.progress.settings), "CASE5 settings persisted across OS process")
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")), "CASE5 persisted mute applied to actual Master bus")
	for key_name in ["master", "music", "sfx"]:
		var settings_script = load("res://game/shell/settings.gd")
		var index: int = AudioServer.get_bus_index(settings_script.BUS_MAP[key_name])
		check(is_equal_approx(AudioServer.get_bus_volume_db(index), linear_to_db(SAVED_SETTINGS[key_name]) + settings_script.BASE_DB[key_name]), "CASE5 real audio gain restored " + key_name)
	await shot("ui_05_main_menu_restored")
	await button("continue")
	game = shell.adapter.level
	check(shell.current_id == LEVEL_IDS[1] and shell.state == shell.State.PLAYING, "CASE5 Continue resumes recent L02")
	check_at_spawn("CASE5 Continue starts at L02 spawn")
	cases.append("CASE5 restart Continue and settings")
	await route_l02("normal")
	await delay(0.25)
	check_completion(LEVEL_IDS[1], 1)
	check(shell.progress.completed == [LEVEL_IDS[0], LEVEL_IDS[1]] and shell.progress.unlocked == LEVEL_IDS, "CASE6 L02 completion unlocks L03")
	await shot("ui_06_complete_l02")
	await button("next")
	game = shell.adapter.level
	check(shell.current_id == LEVEL_IDS[2] and shell.state == shell.State.PLAYING, "CASE6 Next enters L03")
	check_at_spawn("CASE6 L03 entry")
	await route_l03("normal")
	await delay(0.25)
	check_completion(LEVEL_IDS[2], 2)
	check(shell.progress.completed == LEVEL_IDS and shell.view.buttons["next"].disabled and shell.catalog.next_id(LEVEL_IDS[2]).is_empty(), "CASE6 final completion has no Next")
	await shot("ui_07_complete_final")
	var saved: Dictionary = shell.store.load_save()
	check(saved.completed == LEVEL_IDS and saved.unlocked == LEVEL_IDS and saved.recent == LEVEL_IDS[2], "CASE6 all completion progress persisted")
	await button("select")
	for id in LEVEL_IDS:
		check(not shell.view.buttons["level:" + id].disabled and shell.view.buttons["level:" + id].text.ends_with("已通关"), "CASE6 select shows completed playable entry " + id)
	await shot("ui_08_select_all_completed")
	cases.append("CASE6 L02 L03 completion and final selection")
	await finish(false)

func check_at_spawn(label: String) -> void:
	check(game.mover.cell == game.content.spawn and game.mover.destination == game.content.spawn and game.mover.world == 0 and game.view.current == 0 and game.mover.phase == "idle" and not game.view.busy and game.mover.order.is_empty() and not game.graph.complete and not game.graph.door_open and not game.completion.visible and game.mover.moves == 0, label)

func check_completion(id: String, expected_events: int) -> void:
	check(shell.state == shell.State.LEVEL_COMPLETE and shell.current_id == id and game.graph.complete, "real Goal enters Shell LEVEL_COMPLETE " + id)
	check(completion_events == expected_events and last_completion_id == id and last_completion_was_goal, "real adapter completion event exactly once " + id)
	check(game.process_mode == Node.PROCESS_MODE_DISABLED and not shell.dirty and shell.view.screen == "complete", "completed level suspended and save succeeded " + id)

func settings_match(values: Dictionary) -> bool:
	for key_name in SAVED_SETTINGS:
		if typeof(SAVED_SETTINGS[key_name]) == TYPE_FLOAT:
			if not is_equal_approx(values[key_name], SAVED_SETTINGS[key_name]): return false
		elif values[key_name] != SAVED_SETTINGS[key_name]: return false
	return true

func shot(label: String) -> void:
	if not label.begins_with("ui_"): return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(evidence.path_join(label + ".png"))
	checkpoints.append({"name": label, "screen": shell.view.screen, "current_id": shell.current_id})

func finish(request_exit: bool) -> void:
	var report := {"phase": phase, "pid": OS.get_process_id(), "checks": checks, "failures": failures, "cases": cases, "display": DisplayServer.get_name(), "renderer": RenderingServer.get_current_rendering_method(), "engine": Engine.get_version_info(), "save_path": isolated_save, "save_absolute": ProjectSettings.globalize_path(isolated_save), "metadata": metadata, "completion_events": completion_events, "progress": shell.progress, "screenshots": checkpoints, "shell_quit_requested": request_exit and failures.is_empty()}
	# Leave through production navigation before exiting; allow queued old levels to die.
	shell.show_main_menu()
	game = null
	await process_frame
	await process_frame
	report.exit_after_level_unloaded = shell.adapter.level == null
	if not request_exit or not failures.is_empty():
		shell.queue_free()
		await process_frame
		await process_frame
		shell = null
	var file := FileAccess.open(evidence.path_join("report.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("CONTENT SHELL ", phase, ": ", checks, " checks, failures=", failures, ", PID=", OS.get_process_id())
	if not failures.is_empty(): quit(1)
	elif request_exit: shell.request_quit()
	else: quit(0)
