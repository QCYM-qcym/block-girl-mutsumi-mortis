extends "res://tests/playtest/test_batch_01_runtime.gd"
## Native input/Goal observer; explicit legacy-unlocked save fixture, no Runtime assignments.
const Store = preload("res://game/shell/save_store.gd")
const LEGACY := ["mutsumi_l01", "mutsumi_l02", "mutsumi_l03"]
const SETTINGS := {"master":0.42,"music":0.23,"sfx":0.67,"muted":true,"fullscreen":false}
const RECIPES := "res://tests/beta_sprint/shell_batch_02/delivered_routes.json"
var shell
var phase := ""
var save_path := ""
var evidence := ""
var pending: Array[String] = []
var completions: Array[Dictionary] = []
var cases: Array[String] = []
var input_recipe_source := ""

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--phase="): phase = arg.trim_prefix("--phase=")
		elif arg.begins_with("--shell-save="): save_path = arg.trim_prefix("--shell-save=")
		elif arg.begins_with("--evidence-dir="): evidence = arg.trim_prefix("--evidence-dir=")
	check(DisplayServer.get_name() == "headless", "real Runtime process is headless")
	check(phase in ["seed", "restore", "legacy_restore"] and save_path.begins_with("user://beta_sprint/") and ".." not in save_path and not evidence.is_empty(), "explicit isolated Runtime phase/save/evidence")
	if not failures.is_empty():
		quit(1)
		return
	if phase == "seed":
		check(not FileAccess.file_exists(save_path), "fresh isolated Runtime slot")
		var store = Store.new(save_path, LEGACY[0])
		var fixture: Dictionary = store.defaults()
		fixture.has_progress = true
		fixture.unlocked = LEGACY.duplicate()
		fixture.completed = LEGACY.slice(0, 2)
		fixture.recent = LEGACY[2]
		fixture.settings = SETTINGS.duplicate()
		check(store.save(fixture), "explicit setup fixture: original L01/L02 completed, L03 unlocked")
	else:
		check(FileAccess.file_exists(save_path), "independent restore process reads preceding seed save")
	shell = load("res://game/shell/game_shell.tscn").instantiate()
	shell.save_path = save_path
	root.add_child(shell)
	shell.adapter.completed.connect(observe_completion)
	await delay(0.15)
	var registered: Array = []
	for entry in shell.catalog.entries: registered.append(entry.id)
	check(registered.slice(0, 3) == LEGACY, "formal menu retains original stable-ID prefix")
	check(shell.state == shell.State.MAIN_MENU and shell._can_continue(), "formal menu can Continue isolated progress")
	check(shell.progress.settings == (Store.new(save_path, LEGACY[0]).load_save().settings if phase == "legacy_restore" else SETTINGS), "saved settings unchanged by catalog expansion")
	if not failures.is_empty():
		await finish()
		return
	if phase == "seed":
		await seed_process()
		await real_menu_reachability()
	else: await restore_process()
	await finish()

func action(id: String) -> void:
	check(shell.view.buttons.has(id) and not shell.view.buttons[id].disabled, "formal menu button enabled " + id)
	if not shell.view.buttons.has(id) or shell.view.buttons[id].disabled: return
	shell.view.buttons[id].pressed.emit()
	await delay(0.10)

func observe_completion() -> void:
	var level = shell.adapter.level
	completions.append({"id":shell.current_id,"goal":level.graph.complete,"cell":str(level.mover.cell),"authored_goal":str(level.content.goal),"phase":level.mover.phase,"moves":level.mover.moves})

func at_spawn(label: String) -> void:
	game = shell.adapter.level
	check(shell.state == shell.State.PLAYING and game != null, "real level active " + label)
	if game == null: return
	check(game.mover.cell == game.content.spawn and game.mover.destination == game.content.spawn and game.mover.moves == 0 and game.mover.world == 0 and game.view.current == 0 and game.mover.phase == "idle" and not game.graph.complete, "Continue/entry uses original native spawn " + label)

func seed_process() -> void:
	await action("continue")
	at_spawn("L03")
	check(shell.current_id == LEGACY[2], "formal Continue enters actual L03")
	await route_l03("alternate_views")
	await delay(0.10)
	check(shell.state == shell.State.LEVEL_COMPLETE and game.graph.complete and game.mover.cell == game.content.goal, "real native input reaches L03 Goal and Shell Complete")
	check(completions.size() == 1 and completions[0].goal and completions[0].phase == "complete", "L03 completion comes from exactly one genuine native Goal event")
	check(shell.progress.completed == LEGACY and shell.store.load_save().completed == LEGACY, "real L03 completion persisted with existing algorithm")
	cases.append("REAL L03 native route and completion")
	var next: String = shell.catalog.next_id(LEGACY[2])
	if next.is_empty():
		check(shell.view.buttons["next"].disabled, "no unavailable successor invented")
		pending.append("REAL L03->L04 unlock/menu: playable Content dependency not registered")
		pending.append("REAL L04->L05 unlock: playable Content dependency not registered")
		return
	check(next == "mutsumi_l04" and shell.catalog.is_available(next), "actual registered successor is delivered playable L04")
	check(next in shell.progress.unlocked and next in shell.store.load_save().unlocked, "real L03 Goal unlocks and saves L04")
	await action("next")
	at_spawn("L04 via Next")
	await menu_reenter(next)
	cases.append("REAL L03->L04 unlock, Next and formal selection")
	if not FileAccess.file_exists(RECIPES):
		pending.append("REAL L04->L05 Goal unlock: 06 validated native input recipe not yet delivered")
		return
	var recipes: Variant = JSON.parse_string(FileAccess.get_file_as_string(RECIPES))
	if not recipes is Dictionary or not recipes.get("routes") is Dictionary or not recipes.routes.has(next):
		pending.append("REAL L04->L05 Goal unlock: no delivered L04 input recipe")
		return
	input_recipe_source = str(recipes.get("content_commit", ""))
	check(not input_recipe_source.is_empty(), "native input recipe names its exact Content dependency commit")
	await delivered_route(recipes.routes[next])
	await delay(0.10)
	check(shell.state == shell.State.LEVEL_COMPLETE and game.graph.complete and game.mover.cell == game.content.goal, "delivered native L04 route reaches its authored Goal")
	check(completions.size() == 2 and completions[1].id == next and completions[1].goal and completions[1].phase == "complete", "L04 completion comes from genuine native Goal event")
	var following: String = shell.catalog.next_id(next)
	if following.is_empty():
		check(shell.view.buttons["next"].disabled, "unavailable L05 is not offered after L04")
		pending.append("REAL L04->L05 unlock: L05 playable dependency not registered")
	else:
		check(following == "mutsumi_l05" and shell.catalog.is_available(following) and following in shell.progress.unlocked and following in shell.store.load_save().unlocked, "real L04 Goal unlocks and saves delivered L05")
		await action("next")
		at_spawn("L05 via Next")
		await menu_reenter(following)
		cases.append("REAL L04->L05 unlock, Next and formal selection")
		if recipes.routes.has(following):
			await delivered_route(recipes.routes[following])
			await delay(0.10)
			check(shell.state == shell.State.LEVEL_COMPLETE and game.graph.complete and game.mover.cell == game.content.goal, "delivered native L05 route reaches authored final Goal")
			check(completions.size() == 3 and completions[2].id == following and completions[2].goal and completions[2].phase == "complete", "L05 completion comes from genuine native Goal event")
			check(shell.catalog.next_id(following).is_empty() and shell.view.buttons["next"].disabled, "last delivered level has no invented successor")
			check(shell.store.load_save().completed == LEGACY + [next, following] and shell.store.load_save().recent == following, "all original/new completion metadata persisted without schema change")
			cases.append("REAL L05 final completion and saved progress")
		else:
			pending.append("REAL L05 final completion: validated native input recipe not delivered")

func menu_reenter(id: String) -> void:
	shell.pause_game()
	await action("select")
	check(shell.view.buttons.has("level:" + id) and not shell.view.buttons["level:" + id].disabled, "new delivered level selectable in formal menu " + id)
	await action("level:" + id)
	check(shell.current_id == id, "formal select enters actual delivered scene " + id)
	at_spawn(id + " via Select")

func real_menu_reachability() -> void:
	for size in [Vector2i(1920,1080), Vector2i(1280,720), Vector2i(960,720)]:
		for id in ["mutsumi_l04", "mutsumi_l05"]:
			if shell.catalog.find(id).is_empty() or id not in shell.progress.unlocked:
				continue
			shell.show_level_select()
			# Native scene startup restores its default window size; reset each measurement.
			root.size = size
			for frame in 5: await process_frame
			check(root.size == size and root.get_visible_rect().size == Vector2(size), "measured headless logical viewport matches requested size " + id + " " + str(size))
			var index := 0
			for entry in shell.catalog.entries:
				if entry.id == id: break
				index += 1
			for step in index: await tap(KEY_DOWN)
			var button: Control = shell.view.buttons["level:" + id]
			var visible_area := root.get_visible_rect()
			var parent := button.get_parent()
			while parent != null:
				if parent is ScrollContainer: visible_area = visible_area.intersection(parent.get_global_rect())
				parent = parent.get_parent()
			check(button.has_focus() and visible_area.grow(1).encloses(button.get_global_rect()), "actual new menu row keyboard-reachable in headless logical layout " + id + " " + str(size))
			checkpoints.append({"case":"HEADLESS_LOGICAL_LAYOUT_NOT_HUMAN_SIZE_PASS","id":id,"requested":str(size),"viewport":str(root.get_visible_rect()),"row":str(button.get_global_rect()),"clip":str(visible_area)})
			var at := button.get_global_rect().get_center()
			var motion := InputEventMouseMotion.new()
			motion.position = at
			motion.global_position = at
			Input.parse_input_event(motion)
			await process_frame
			for pressed in [true,false]:
				var event := InputEventMouseButton.new()
				event.button_index = MOUSE_BUTTON_LEFT
				event.position = at
				event.global_position = at
				event.pressed = pressed
				Input.parse_input_event(event)
				await process_frame
			await delay(0.10)
			check(shell.state == shell.State.PLAYING and shell.current_id == id, "native mouse event enters actual new level from formal select " + id + " " + str(size))
			at_spawn(id + " via headless mouse")
			shell.pause_game()
			await action("select")
			shell.view.buttons["main"].grab_focus()
			for frame in 5: await process_frame
			await tap(KEY_ENTER)
			check(shell.state == shell.State.MAIN_MENU, "actual expanded menu retains keyboard return " + str(size))
	cases.append("actual L04/L05 native GUI-event reachability in three headless logical layouts; not Human QA")

func delivered_route(actions: Array) -> void:
	for step in actions:
		match str(step.get("action", "")):
			"move":
				var directions := {"UP":Vector2i.UP,"RIGHT":Vector2i.RIGHT,"DOWN":Vector2i.DOWN,"LEFT":Vector2i.LEFT}
				var direction := str(step.get("direction", ""))
				check(directions.has(direction), "delivered native movement direction is explicit")
				if directions.has(direction): await move(directions[direction], int(step.get("count", 1)))
			"view":
				await tap(KEY_E if step.get("direction") == "E" else KEY_Q, int(step.get("count", 1)))
			"shift": await tap(KEY_SPACE)
			_: check(false, "unknown delivered input recipe action")

func restore_process() -> void:
	var before: Dictionary = shell.progress.duplicate(true)
	var recent: String = before.recent
	await action("continue")
	check(shell.current_id == recent, "independent process Continue restores exact recent stable level")
	at_spawn(recent + " after process restart")
	check(shell.progress.unlocked == before.unlocked and shell.progress.completed == before.completed and shell.progress.settings == before.settings, "Continue preserves existing progression and settings")
	cases.append("OWNER copied real archived-save Continue at native start" if phase == "legacy_restore" else "OWNER independent-process Continue at native start; not Human Cold Continue")

func shot(label: String) -> void:
	checkpoints.append({"name":label,"id":game.content.level_id,"cell":str(game.mover.cell),"world":game.mover.world,"view":game.view.current,"goal":game.graph.complete})

func finish() -> void:
	var report := {"phase":phase,"pid":OS.get_process_id(),"checks":checks,"failures":failures,"pending":pending,"cases":cases,"completion_events":completions,"checkpoints":checkpoints,"progress":shell.progress,"save_path":save_path,"input_recipe_content_commit":input_recipe_source,"evidence_type":"OWNER_HEADLESS_REAL_RUNTIME_INPUT","human_acceptance":"NOT_RUN","fixture":"only prior L01/L02 completed and L03-unlocked save setup; no Runtime state assigned"}
	if phase == "legacy_restore": report.fixture = "byte-exact copy of inactive old 08 real progress; original archive never written; no Runtime state assigned"
	var arguments := OS.get_cmdline_args()
	var driver_at := arguments.find("--audio-driver")
	report.audio_driver_argument = arguments[driver_at + 1] if driver_at >= 0 and driver_at + 1 < arguments.size() else "NOT_EXPOSED_BY_OS_ARGS_SEE_RUNNER_STAGE_ARGS"
	for argument in arguments:
		if argument.begins_with("--audio-driver="):
			report.audio_driver_argument = argument.trim_prefix("--audio-driver=")
	report.shell_quit_requested = failures.is_empty()
	shell.show_main_menu()
	game = null
	await process_frame
	await process_frame
	DirAccess.make_dir_recursive_absolute(evidence)
	var file := FileAccess.open(evidence.path_join("real_runtime_report.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print(JSON.stringify(report))
	if failures.is_empty(): shell.call_deferred("request_quit")
	else:
		shell.queue_free()
		await process_frame
		call_deferred("quit", 1)
