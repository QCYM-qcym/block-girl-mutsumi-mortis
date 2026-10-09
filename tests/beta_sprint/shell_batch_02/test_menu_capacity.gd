extends SceneTree
## Five artificial signal levels. This is Unit/UI layout evidence, never Real Content/Human QA.
const Store = preload("res://game/shell/save_store.gd")
const SIZES := [Vector2i(1920, 1080), Vector2i(1280, 720), Vector2i(960, 720)]
var shell
var checks := 0
var failures: Array[String] = []
var observations: Array[Dictionary] = []
var ids: Array[String] = []
var save_path := ""
var evidence := ""

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shell-save="): save_path = arg.trim_prefix("--shell-save=")
		elif arg.begins_with("--evidence-dir="): evidence = arg.trim_prefix("--evidence-dir=")
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		printerr("FAIL: ", label)

func settle() -> void:
	for frame in 5: await process_frame

func key(code: int) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await settle()

func mouse(button: Control) -> void:
	var at := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	Input.parse_input_event(motion)
	await process_frame
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = at
		event.global_position = at
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await settle()

func action(id: String) -> void:
	check(shell.view.buttons.has(id) and not shell.view.buttons[id].disabled, "fixture flow button enabled " + id)
	if not shell.view.buttons.has(id) or shell.view.buttons[id].disabled: return
	shell.view.buttons[id].pressed.emit()
	await settle()

func reachable(button: Control, label: String) -> void:
	var rect := button.get_global_rect()
	var viewport := root.get_visible_rect()
	var visible_area := viewport
	var parent := button.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			visible_area = visible_area.intersection(parent.get_global_rect())
		parent = parent.get_parent()
	observations.append({"case":label,"viewport":str(viewport),"button":str(rect),"visible_area":str(visible_area),"focused":button.has_focus()})
	check(button.is_visible_in_tree() and visible_area.grow(1).encloses(rect), "focused fixture control reachable within visible area " + label)

func run() -> void:
	check(DisplayServer.get_name() == "headless", "headless-only menu capacity Unit")
	check(save_path.begins_with("user://beta_sprint/") and ".." not in save_path and not evidence.is_empty(), "explicit isolated Unit save/evidence")
	if not failures.is_empty():
		quit(1)
		return
	check(not FileAccess.file_exists(save_path), "fresh Unit fixture slot")
	var entries: Array[Dictionary] = []
	for index in 5:
		var id := "fixture_shell_batch02_%02d" % (index + 1)
		ids.append(id)
		entries.append({"id":id,"title":"Unit fixture %02d / capacity" % (index + 1),"scene":"res://tests/shell/fixture_level.tscn","adapter":"signal"})
	var store = Store.new(save_path, ids[0])
	var seeded: Dictionary = store.defaults()
	seeded.has_progress = true
	seeded.unlocked = ids.slice(0, 3)
	seeded.completed = ids.slice(0, 2)
	seeded.recent = ids[2]
	check(store.save(seeded), "explicit artificial first-three-unlocked fixture saved")
	shell = load("res://game/shell/game_shell.tscn").instantiate()
	shell.catalog_entries = entries
	shell.save_path = save_path
	root.add_child(shell)
	await settle()
	check(shell.state == shell.State.MAIN_MENU and shell._can_continue(), "fixture Continue available from formal menu")
	await action("select")
	check(shell.view.buttons["level:" + ids[3]].disabled and shell.view.buttons["level:" + ids[4]].disabled, "artificial fourth/fifth levels start locked")
	shell.start_level(ids[4])
	check(shell.state == shell.State.LEVEL_SELECT and shell.adapter.level == null, "locked fixture rejected by existing Shell")
	await action("main")
	await action("continue")
	for index in [2, 3]:
		check(shell.state == shell.State.PLAYING and shell.current_id == ids[index], "fixture enters through existing navigation " + ids[index])
		shell.adapter.level.finish()
		await settle()
		check(shell.state == shell.State.LEVEL_COMPLETE and ids[index + 1] in shell.progress.unlocked, "artificial completion signal unlocks next fixture " + ids[index])
		check(ids[index + 1] in store.load_save().unlocked, "fixture next unlock uses real unchanged SaveStore")
		await action("next")
	await key(KEY_ESCAPE)
	check(shell.state == shell.State.PAUSED, "native Escape pauses fixture")
	await action("settings")
	await action("cancel")
	check(shell.state == shell.State.PAUSED, "fixture Settings returns to Pause")
	await action("reset")
	check(shell.state == shell.State.PLAYING and shell.adapter.level.resets == 1, "existing Reset resumes current fixture")
	await key(KEY_ESCAPE)
	await action("select")
	for size in SIZES:
		root.size = size
		shell.show_level_select()
		await settle()
		shell.view.buttons["level:" + ids[0]].grab_focus()
		for index in ids.size():
			var button: Control = shell.view.buttons["level:" + ids[index]]
			check(button.has_focus(), "native Down focus reaches fixture row " + ids[index] + " at " + str(size))
			reachable(button, ids[index] + " at " + str(size))
			await key(KEY_DOWN)
		check(shell.view.buttons["main"].has_focus(), "native Down reaches return navigation " + str(size))
		reachable(shell.view.buttons["main"], "return at " + str(size))
		await mouse(shell.view.buttons["main"])
		check(shell.state == shell.State.MAIN_MENU, "mouse return remains reachable " + str(size))
		for id in ids:
			shell.show_level_select()
			await settle()
			var button: Control = shell.view.buttons["level:" + id]
			button.grab_focus()
			await settle()
			await mouse(button)
			check(shell.state == shell.State.PLAYING and shell.current_id == id, "mouse enters focused fixture " + id + " at " + str(size))
			shell.pause_game()
			await action("select")
	var report := {"checks":checks,"failures":failures,"observations":observations,"evidence_type":"OWNER_HEADLESS_UNIT_AND_LOGICAL_LAYOUT","human_acceptance":"NOT_RUN","fixtures":ids,"scope":"five artificial signal levels; not real Batch02 Goal/unlock or Human window-size/input acceptance"}
	DirAccess.make_dir_recursive_absolute(evidence)
	var file := FileAccess.open(evidence.path_join("menu_capacity_report.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	shell.show_main_menu()
	shell.queue_free()
	await settle()
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
