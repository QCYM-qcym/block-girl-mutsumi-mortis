extends "res://tests/playtest/test_batch_01_runtime.gd"
## Real routes, no save seeding, no emitted completion signal, no assigned gameplay state.
const Factory = preload("res://experiments/spatial_puzzle_batch_01/maps/map_factory.gd")
const Goal = preload("res://foundation/rules/goal_evaluator.gd")
const Store = preload("res://game/shell/save_store.gd")
var shell
var phase := ""
var save_path := ""
var evidence := ""
var completions: Array[Dictionary] = []
var expected: Array[String] = ["mutsumi_l01", "mutsumi_l02", "mutsumi_l03", "mutsumi_l04", "mutsumi_l05"]

func run() -> void:
	create_timer(180).timeout.connect(func(): printerr("SHELL_LIFECYCLE_TIMEOUT"); quit(2))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--phase="): phase = arg.trim_prefix("--phase=")
		elif arg.begins_with("--shell-save="): save_path = arg.trim_prefix("--shell-save=")
		elif arg.begins_with("--evidence-dir="): evidence = arg.trim_prefix("--evidence-dir=")
	check(phase in ["fresh", "continue"] and save_path.begins_with("user://beta_sprint/spatial_formal/") and not evidence.is_empty(), "explicit isolated phase/save/evidence")
	if not failures.is_empty(): quit(1); return
	check(FileAccess.file_exists(save_path) == (phase == "continue"), "independent process save generation")
	for id in Factory.ids(): expected.append("spatial_" + str(id))
	shell = load("res://game/shell/game_feel_shell.tscn").instantiate()
	shell.save_path = save_path
	root.add_child(shell)
	shell.adapter.completed.connect(observe_completion)
	await process_frame
	check(shell.catalog.entries.size() == 10, "ten formal entries available")
	if not failures.is_empty(): await finish(); return
	if phase == "fresh": await fresh_process()
	else: await continue_process()
	await finish()

func observe_completion() -> void:
	var level = shell.adapter.level
	var goal: bool = level.graph.complete if shell.adapter.kind == "p01" else Goal.is_goal(level.host.runtime.get_level(), level.host.runtime.get_state()).is_goal
	completions.append({"id":shell.current_id, "real_goal":goal})

func action(id: String) -> void:
	check(shell.view.buttons.has(id) and not shell.view.buttons[id].disabled, "menu action enabled: " + id)
	if shell.view.buttons.has(id) and not shell.view.buttons[id].disabled: shell.view.buttons[id].pressed.emit()
	await process_frame

func fresh_process() -> void:
	check(shell.state == shell.State.MAIN_MENU and shell.view.buttons.continue.disabled, "first boot disables Continue")
	check(shell.progress.unlocked == [expected[0]] and shell.progress.completed.is_empty(), "fresh save unlocks only L01")
	await action("select")
	for index in expected.size():
		check(shell.view.buttons.has("level:" + expected[index]), "selection displays formal entry: " + expected[index])
		check(shell.view.buttons["level:" + expected[index]].disabled == (index > 0), "selection honors progression: " + expected[index])
	shell.start_level(expected[5])
	check(shell.adapter.level == null, "locked first spatial level rejected")
	await action("main")
	await action("new")
	var recipes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/beta_sprint/shell_batch_02/delivered_routes.json"))
	for index in 5:
		game = shell.adapter.level
		check(shell.current_id == expected[index] and game.mover.cell == game.content.spawn, "legacy native start: " + expected[index])
		if index == 0: await route_l01("normal")
		elif index == 1: await route_l02("normal")
		elif index == 2: await route_l03("alternate_views")
		else: await delivered_route(recipes.routes[expected[index]])
		await process_frame
		check(shell.state == shell.State.LEVEL_COMPLETE and game.graph.complete, "legacy actual goal reaches Shell Complete: " + expected[index])
		check(shell.progress.completed == expected.slice(0, index + 1), "legacy progress is naturally earned: " + expected[index])
		check(shell.store.load_save().unlocked == expected.slice(0, index + 2), "real goal persists next unlock: " + expected[index])
		await action("next")
	# This is specifically the real L05 completion -> first spatial transition.
	check(shell.current_id == expected[5] and shell.adapter.kind == "signal", "L05 actual completion Next enters formal spatial chapter")
	for index in range(5, 10):
		check(shell.current_id == expected[index], "spatial sequential entry: " + expected[index])
		if index == 5: await spatial_pause_reset()
		await spatial_route()
		check(shell.state == shell.State.LEVEL_COMPLETE, "spatial natural goal reaches Shell Complete: " + expected[index])
		check(shell.progress.completed == expected.slice(0, index + 1), "spatial real completion persists exactly once: " + expected[index])
		check(shell.store.load_save().unlocked == expected.slice(0, mini(index + 2, 10)), "spatial real goal persists next unlock: " + expected[index])
		if index == 5:
			var before: int = completions.size()
			await action("replay")
			await spatial_route()
			check(completions.size() == before + 1 and shell.progress.completed == expected.slice(0, 6), "replay produces one fresh completion without duplicate progress")
		if index < 9: await action("next")
	check(shell.view.buttons.next.disabled, "final spatial level ends progression")
	check(completions.size() == 11, "five legacy plus five spatial plus one replay actual completions")
	for item in completions: check(item.real_goal, "all completion signals backed by actual goal: " + item.id)
	await menu_capacity()
	shell.show_main_menu()
	check(shell._can_continue(), "completed run preserves Continue")

func delivered_route(actions: Array) -> void:
	for step in actions:
		match str(step.action):
			"move":
				var directions := {"UP":Vector2i.UP,"RIGHT":Vector2i.RIGHT,"DOWN":Vector2i.DOWN,"LEFT":Vector2i.LEFT}
				await move(directions[step.direction], int(step.get("count", 1)))
			"view": await tap(KEY_E if step.direction == "E" else KEY_Q, int(step.get("count", 1)))
			"shift": await tap(KEY_SPACE)

func spatial_route() -> void:
	var level = shell.adapter.level
	var recipes: Dictionary = Factory.witnesses(level.map_id)
	var route: Array = recipes.get("solution", recipes.get("solution_a", recipes.get("solution_east", [])))
	check(not route.is_empty(), "published tested witness exists: " + str(level.map_id))
	for step in route:
		var result: Dictionary = level.host.runtime.request_action(step)
		check(result.status == 0, "actual Runtime accepts witness: " + str(step))
		await settle(level.host)
	await process_frame

func settle(lab: Node) -> void:
	var deadline := Time.get_ticks_msec() + 5000
	while Time.get_ticks_msec() < deadline:
		if lab.runtime.is_idle() and lab.presenter.snapshot().phase == "IDLE": return
		await process_frame
	check(false, "natural Host/Presenter completion timeout: " + str(shell.current_id) + " idle=" + str(lab.runtime.is_idle()) + " phase=" + str(lab.presenter.snapshot().phase))

func spatial_pause_reset() -> void:
	var level = shell.adapter.level
	var lab = level.host
	await settings_checks()
	var initial: Dictionary = lab.runtime.get_state()
	var result: Dictionary = lab.runtime.request_action(Factory.witnesses(level.map_id).solution[0])
	check(result.status == 0 and not lab.runtime.is_idle(), "real transition pending before pause")
	shell.pause_game()
	var count: int = lab.runtime.get_commit_count()
	await key(KEY_W, true)
	await key(KEY_W, false)
	await delay(0.4)
	check(shell.state == shell.State.PAUSED and lab.paused and lab.runtime.get_commit_count() == count, "pause freezes real transition and rejects gameplay input")
	check(lab.audio_bridge.director.snapshot().paused, "pause reaches actual spatial AudioDirector")
	check(not level.hud.visible, "pause hides gameplay HUD behind Shell")
	for player in level.find_children("*", "AudioStreamPlayer", true, false):
		check(not player.playing or player.stream_paused, "pause suspends every active actual audio player")
	shell.resume_game()
	await settle(lab)
	check(level.hud.visible, "resume restores actual spatial HUD")
	check(lab.runtime.get_commit_count() == count + 1, "resume naturally commits pending transition once")
	shell.pause_game()
	shell.reset_current()
	await process_frame
	check(shell.state == shell.State.PLAYING and lab.runtime.get_state() == initial, "reset restores actual spatial initial state")
	# Reset during a real in-flight transition; wait beyond its duration for stale callbacks.
	lab.runtime.request_action(Factory.witnesses(level.map_id).solution[0])
	shell.pause_game()
	shell.reset_current()
	var reset_count: int = lab.runtime.get_commit_count()
	await delay(0.65)
	check(lab.runtime.get_state() == initial and lab.runtime.get_commit_count() == reset_count, "in-flight reset fences late transition callbacks")
	check(completions.size() == 5, "pause/reset never invents spatial completion")

func continue_process() -> void:
	check(shell.state == shell.State.MAIN_MENU and shell._can_continue(), "independent cold process offers Continue")
	check(shell.progress.completed == expected and shell.progress.unlocked == expected, "independent cold process restores all naturally earned progress")
	await action("continue")
	check(shell.current_id == expected[-1] and shell.state == shell.State.PLAYING, "Continue enters exact recent formal level")
	var host = shell.adapter.level.host
	check(not Goal.is_goal(host.runtime.get_level(), host.runtime.get_state()).is_goal, "Continue starts spatial map at fresh spawn")
	check(shell.progress.settings.game_feel.reduced_motion and host._reduced_motion, "cold Continue routes saved reduced motion into actual spatial Host")
	check(not shell.adapter.level.hud.footer.visible and shell.adapter.level.hud.title_label.has_theme_color_override("font_color"), "cold Continue restores hidden input hints and contrast in actual spatial HUD")
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")), "cold process restores saved Master mute")
	await spatial_route()
	check(shell.state == shell.State.LEVEL_COMPLETE and completions.size() == 1, "cold Continue can complete genuine route again")
	check(shell.store.load_save().completed == expected, "cold replay keeps completion IDs unique")

func shot(_label: String) -> void:
	pass # Explicitly headless logical/runtime evidence; no screenshots or Human QA claim.

func settings_checks() -> void:
	var host = shell.adapter.level.host
	var before: Dictionary = shell.progress.settings.duplicate(true)
	shell.open_settings()
	shell.game_feel.ui.buttons.reduced_motion.button_pressed = true
	shell.game_feel.ui.buttons.muted.button_pressed = true
	shell.game_feel.extra_controls.input_hints.button_pressed = false
	shell.game_feel.extra_controls.contrast.button_pressed = true
	await process_frame
	check(host._reduced_motion, "settings preview reaches spatial Host reduced motion")
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")), "settings preview reaches actual audio bus")
	check(not shell.adapter.level.hud.footer.visible and shell.adapter.level.hud.title_label.has_theme_color_override("font_color"), "settings preview controls spatial HUD hints and contrast")
	shell.cancel_settings()
	await process_frame
	check(not host._reduced_motion and shell.progress.settings == before, "settings cancel restores spatial motion and saved settings")
	check(not AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")), "settings cancel restores actual audio bus")
	check(shell.adapter.level.hud.footer.visible and shell.adapter.level.hud.title_label.get_theme_color("font_color") == load("res://game/shell/visual_01/tokens.gd").COLORS.ink, "settings cancel restores approved ink color and HUD hints")
	shell.open_settings()
	shell.game_feel.ui.buttons.reduced_motion.button_pressed = true
	shell.game_feel.ui.buttons.muted.button_pressed = true
	shell.game_feel.extra_controls.input_hints.button_pressed = false
	shell.game_feel.extra_controls.contrast.button_pressed = true
	shell.save_settings()
	await process_frame
	check(host._reduced_motion and shell.store.load_save().settings.game_feel.reduced_motion, "settings apply persists and routes spatial reduced motion")
	shell.resume_game()

func menu_capacity() -> void:
	for size in [Vector2i(1280, 900), Vector2i(960, 720)]:
		shell.show_level_select()
		root.size = size
		for frame in 4: await process_frame
		shell.view.buttons["level:" + expected[0]].grab_focus()
		for index in expected.size():
			if index > 0:
				await key(KEY_DOWN, true)
				await key(KEY_DOWN, false)
			for frame in 3: await process_frame
			var row: Control = shell.view.buttons["level:" + expected[index]]
			var clip := root.get_visible_rect()
			var parent := row.get_parent()
			while parent != null:
				if parent is ScrollContainer: clip = clip.intersection(parent.get_global_rect())
				parent = parent.get_parent()
			check(row.has_focus() and clip.grow(1).encloses(row.get_global_rect()), "ten-row keyboard scroll reaches " + expected[index] + " at " + str(size))

func finish() -> void:
	var report := {"phase":phase,"pid":OS.get_process_id(),"checks":checks,"failures":failures,"completions":completions,"save_path":save_path,"progress":shell.progress,"evidence_type":"HEADLESS_REAL_RUNTIME_NATURAL_HOST_AND_LEGACY_NATIVE_INPUT","human_acceptance":"NOT_RUN","save_fixture":"none; fresh process earns every unlock through actual goals"}
	if DisplayServer.get_name() != "headless":
		report.evidence_type = "GRAPHICAL_REAL_RUNTIME_NATURAL_HOST_AND_LEGACY_NATIVE_INPUT"
	if phase.ends_with("_seam"):
		report.evidence_type = "HEADLESS_REAL_" + phase.to_upper() + "_INJECTED_SINGLE_ENTRY_CATALOG"
		report.save_fixture = "fresh isolated save with one-entry catalog; does not claim progression/unlock evidence"
	DirAccess.make_dir_recursive_absolute(evidence)
	FileAccess.open(evidence.path_join("shell_" + phase + "_report.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print(JSON.stringify(report))
	shell.show_main_menu()
	game = null
	if failures.is_empty():
		shell.call_deferred("request_quit")
	else:
		shell.queue_free()
		await process_frame
		await delay(0.15)
		quit(1)
