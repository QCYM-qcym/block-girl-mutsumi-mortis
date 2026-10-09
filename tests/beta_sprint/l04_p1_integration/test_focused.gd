extends "res://tests/beta_sprint/l04_inner_movement_p1/test_playthrough.gd"
## 00-only checks; all puzzle actions stay in06's delivered natural-input fixture.
var integration_observations: Array = []

func enter_level(id: String) -> void:
	await super.enter_level(id)
	check(id == "mutsumi_l04" and shell.catalog.entries.size() == 5, "current formal five-level catalog starts actual L04")
	check("mutsumi_l05" not in shell.progress.unlocked and "mutsumi_l04" not in shell.progress.completed, "fresh prior-level qualification never grants L04 completion or L05 unlock")
	integration_observations.append({"case":"initial_profile", "qualification":"explicit newPID prior L01-L03 completion fixture only", "progress":shell.progress.duplicate(true)})
	var before := state_key(state())
	var settings: Dictionary = shell.progress.settings.duplicate(true)
	await tap(KEY_ESCAPE)
	check(shell.state == shell.State.PAUSED, "native Esc opens Pause")
	await click("resume")
	check(shell.state == shell.State.PLAYING and state_key(state()) == before, "native Pause Resume preserves actual gameplay state")
	await tap(KEY_ESCAPE)
	await click("settings")
	check(shell.settings_open and shell.view.screen == "settings", "actual Pause Settings page opens")
	await click("cancel")
	check(not shell.settings_open and shell.state == shell.State.PAUSED and shell.progress.settings == settings, "Settings Cancel preserves saved settings")
	await tap(KEY_ESCAPE)
	check(shell.state == shell.State.PLAYING and state_key(state()) == before, "native Esc resumes without changing authored state")
	integration_observations.append({"case":"pause_resume_settings_cancel", "state":state(), "settings":settings})

func shot(label: String) -> void:
	await super.shot(label)
	if label == "goal":
		var saved: Dictionary = shell.store.load_save()
		check(shell.store.last_error.is_empty(), "formal Goal save checksum is valid")
		check("mutsumi_l04" in saved.completed and "mutsumi_l05" in saved.unlocked, "only real L04 Goal completion unlocks and persists L05")
		check(shell.catalog.next_id("mutsumi_l04") == "mutsumi_l05" and shell.view.buttons.has("next") and not shell.view.buttons["next"].disabled, "formal Complete page offers the registered unlocked L05")
		integration_observations.append({"case":"real_goal_unlock", "route":route_name, "native_completion_count":completions, "progress":saved.duplicate(true), "state":state()})

func leave_level() -> void:
	# Parent has completed all3 natural routes and Reset; never write unlock data here.
	check(completions == 3 and "mutsumi_l05" in shell.progress.unlocked, "three actual L04 completions precede L05 formal menu entry")
	await tap(KEY_ESCAPE)
	await click("select")
	check(shell.state == shell.State.LEVEL_SELECT, "native Pause button reaches formal Level Select")
	await click("level:mutsumi_l05")
	game = shell.adapter.level
	check(shell.state == shell.State.PLAYING and shell.current_id == "mutsumi_l05", "actual native menu click enters unlocked L05")
	check_l05_start()
	route_name = "l05_unlocked_entry"
	await shot("authored_spawn")
	var saved: Dictionary = shell.store.load_save()
	check(saved.recent == "mutsumi_l05" and "mutsumi_l05" not in saved.completed and shell.store.last_error.is_empty(), "L05 entry saves recent ID without inventing L05 completion")
	integration_observations.append({"case":"formal_l05_entry", "state":state(), "progress":saved.duplicate(true)})
	await tap(KEY_ESCAPE)
	await click("main")
	check(shell.state == shell.State.MAIN_MENU and shell.view.buttons.has("continue") and not shell.view.buttons["continue"].disabled, "Main Menu offers valid Continue after actual L05 entry")
	await click("continue")
	game = shell.adapter.level
	check(shell.state == shell.State.PLAYING and shell.current_id == "mutsumi_l05", "same-process native Continue restores genuine recent L05")
	check_l05_start()
	check(shell.store.load_save() == saved, "Continue preserves actual progress and settings")
	integration_observations.append({"case":"same_process_continue_NOT_COLD_CONTINUE", "state":state(), "progress":shell.store.load_save()})
	await shot("continue_authored_spawn")
	await super.leave_level()

func check_l05_start() -> void:
	check(game != null and game.content.level_id == "mutsumi_l05" and game.mover.cell == game.content.spawn and game.mover.world == 0 and game.view.current == 0 and game.mover.phase == "idle" and game.mover.moves == 0 and not game.graph.complete, "L05 uses actual authored Spawn/world/view and original idle Runtime")

func click(name: String) -> void:
	check(shell.view.buttons.has(name), "formal UI control exists: " + name)
	if not shell.view.buttons.has(name): return
	var button: Control = shell.view.buttons[name]
	check(not button.disabled, "formal UI control enabled: " + name)
	if button.disabled: return
	button.grab_focus()
	for frame in 6: await process_frame
	var clip := root.get_visible_rect()
	var parent := button.get_parent()
	while parent != null:
		if parent is ScrollContainer: clip = clip.intersection(parent.get_global_rect())
		parent = parent.get_parent()
	check(clip.grow(1).encloses(button.get_global_rect()), "formal UI control reachable in current actual viewport: " + name)
	var point := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	Input.parse_input_event(motion)
	await process_frame
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.global_position = point
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await delay(0.35)

func finish() -> void:
	var report := {"pid":OS.get_process_id(), "observations":integration_observations, "P1":"OPEN_PENDING_08_RECHECK", "L05":"READY_FOR_FIRST_HUMAN_QA", "Human_QA":"NOT_RUN", "Cold_Continue":"NOT_RUN_THIS_FOCUSED_CASE", "doubles":[], "L04_resource_sha256":FileAccess.get_sha256("res://game/levels/mutsumi/batch_02/l04_borrowed_path.tres")}
	FileAccess.open(evidence.path_join("integration_observations.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	super.finish()
