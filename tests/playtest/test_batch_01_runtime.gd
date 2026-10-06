extends SceneTree
const ROOT = "res://game/levels/mutsumi/batch_01/"
const EVIDENCE = "res://tests/playtest/evidence/batch_01"
const NAMES = ["l01_another_world", "l02_between_shores", "l03_lines_meet"]
var game
var checks := 0
var failures: Array[String] = []
var checkpoints: Array = []
var playthroughs: Array = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		printerr("FAIL: ", label)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EVIDENCE))
	check(DisplayServer.get_name() != "headless", "real graphical display required")
	for index in 3:
		game = load(ROOT + NAMES[index] + ".tscn").instantiate()
		root.add_child(game)
		await delay(0.45)
		check(game.mover.cell == game.content.spawn and game.mover.phase == "idle", "scene startup and Spawn " + NAMES[index])
		check(not game.debug.visible and game.objective_label.text == game.content.intent, "clean player-facing start " + NAMES[index])
		check(game.board.player.visible and game.board.goal.visible, "character and Goal present")
		check(game.board.plate.visible == game.content.gate_enabled and game.board.door.visible == game.content.gate_enabled, "only authored mechanisms visible")
		check(game.completion.title.text.begins_with(game.content.display_title), "content-specific completion title")
		await shot(NAMES[index] + "_start")
		await view_checks()
		await transition_resets()
		if index == 0:
			await key(KEY_W, true)
			await delay(0.8)
			check(game.mover.moves == 2 and game.mover.moving, "continuous W starts third timed roll")
			await key(KEY_W, false)
			await delay(0.4)
			check(game.mover.cell == Vector2i(0,2) and game.mover.moves == 3, "release finishes current roll only")
			await reset_check()
		for mode in (["normal","reset_replay","alternate_views"] if index == 0 else ["normal","alternate_views"]):
			await reset_check()
			if mode == "alternate_views":
				await tap(KEY_Q,4)
				check(game.view.current == 0, "alternate route starts after reverse full orbit")
			if index == 0: await route_l01(mode)
			elif index == 1: await route_l02(mode)
			else: await route_l03(mode)
			check(game.graph.complete and game.mover.cell == game.content.goal and game.mover.world == 0, "complete playthrough " + NAMES[index] + "/" + mode)
			await delay(1.85)
			check(game.completion.visible and game.completion.title.modulate.a > 0.99, "completion presentation finishes")
			await shot(NAMES[index] + "_" + mode + "_complete")
			playthroughs.append({"id":game.content.level_id,"mode":mode,"complete":game.graph.complete,"moves":game.mover.moves,"world":game.mover.world,"view":game.view.current,"cell":str(game.mover.cell)})
			var before = [game.mover.cell,game.mover.world,game.view.current,game.mover.orientation.key()]
			await tap(KEY_SPACE)
			await tap(KEY_E)
			await tap(KEY_S)
			check(before == [game.mover.cell,game.mover.world,game.view.current,game.mover.orientation.key()], "Goal locks movement, Shift and rotation")
		await reset_check()
		await layout_checks(NAMES[index])
		game.queue_free()
		await process_frame
	print("BATCH01 RUNTIME: ", checks, " checks, playthroughs=",playthroughs.size(),", failures=", failures)
	var report = {"checks":checks,"failures":failures,"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"version":Engine.get_version_info(),"playthroughs":playthroughs,"checkpoints":checkpoints}
	var file = FileAccess.open(EVIDENCE + "/runtime_report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	quit(0 if failures.is_empty() else 1)

func route_l01(mode: String) -> void:
	await move(Vector2i.UP,3)
	await move(Vector2i.UP)
	check(game.mover.cell == Vector2i(0,2), "L01 gap cannot walk across")
	await tap(KEY_SPACE)
	await move(Vector2i.UP)
	var pose = game.mover.orientation.key()
	await tap(KEY_SPACE)
	check(game.mover.world == 1 and game.mover.orientation.key() == pose and game.feedback.visible, "L01 unsafe shift visibly rejected")
	await shot("l01_inner_bridge_" + mode)
	await move(Vector2i.UP)
	await move(Vector2i.RIGHT)
	await move(Vector2i.LEFT)
	await move(Vector2i.RIGHT,3)
	check(game.mover.cell == Vector2i(3,0) and not game.graph.link.active, "L01 middle gap needs view decision")
	if mode == "alternate_views": await tap(KEY_Q,3)
	else: await tap(KEY_E)
	check(game.view.current == 1 and game.graph.link.active, "L01 EAST+Inner link active")
	await shot("l01_aligned_" + mode)
	var code = direction_key(Vector2i.RIGHT)
	await key(code,true)
	await key(code,false)
	await delay(0.1)
	check(game.mover.crossing and game.mover.cell == Vector2i(3,0), "L01 connection is timed cube roll")
	await key(KEY_Q,true)
	await key(KEY_Q,false)
	check(not game.view.busy, "L01 crossing rejects rotation")
	await delay(0.35)
	check(game.mover.cell == Vector2i(9,0), "L01 actual connection arrival")
	pose = game.mover.orientation.key()
	await tap(KEY_SPACE)
	check(game.mover.world == 0 and game.view.current == 1 and game.mover.orientation.key() == pose, "L01 return Surface preserves pose and view")
	await move(Vector2i.RIGHT,2)
	check(game.graph.door_open and game.board.plate.state == "pressed", "L01 real plate opens visible door")
	await shot("l01_plate_" + mode)
	await key(code,true)
	await key(code,false)
	await delay(0.1)
	check(game.graph.door_open and game.board.door.state == "open", "L01 door remains open during accepted crossing")
	await delay(0.35)
	check(game.mover.cell == Vector2i(12,0) and not game.graph.door_open, "L01 door closes after committed landing")
	await move(Vector2i.RIGHT)

func route_l02(mode: String) -> void:
	await move(Vector2i.UP,2)
	await move(Vector2i.UP)
	check(game.mover.cell == Vector2i(0,3), "L02 Surface blocks bridge")
	await tap(KEY_SPACE)
	await move(Vector2i.UP)
	await tap(KEY_SPACE)
	check(game.mover.world == 1 and game.feedback.visible, "L02 unsafe shift is recoverable")
	await shot("l02_bridge_" + mode)
	await move(Vector2i.UP)
	await move(Vector2i.RIGHT)
	await move(Vector2i.RIGHT)
	check(game.mover.cell == Vector2i(1,1), "L02 second shift required")
	await tap(KEY_SPACE)
	if mode == "alternate_views": await tap(KEY_E,2)
	await move(Vector2i.RIGHT,3)

func route_l03(mode: String) -> void:
	await move(Vector2i.RIGHT,3)
	await move(Vector2i.RIGHT)
	check(game.mover.cell == Vector2i(3,2), "L03 real logical gap blocks NORTH")
	if mode == "alternate_views":
		await tap(KEY_Q,3)
	else:
		await mouse_drag()
	check(game.view.current == 1 and game.graph.link.active, "L03 authored pair aligns EAST")
	await shot("l03_aligned_" + mode)
	await move(Vector2i.RIGHT)
	check(game.mover.cell == Vector2i(9,2), "L03 real link crossing arrives")
	if mode == "alternate_views":
		await tap(KEY_E)
		check(not game.graph.link.active and game.graph.can_stand(game.mover.cell,0), "L03 disconnected destination remains supported")
	await move(Vector2i.RIGHT,2)

func view_checks() -> void:
	var pose = game.mover.orientation.key()
	for code in [KEY_E,KEY_Q]:
		for i in 4:
			var old: int = game.view.current
			await tap(code)
			check(game.view.current == posmod(old+(1 if code == KEY_E else -1),4), "adjacent 90-degree view index")
			check(is_equal_approx(game.view.displayed_angle(),game.view.current*PI/2), "settled angle is exact quarter turn")
			check(game.mover.orientation.key() == pose and game.mover.cell == game.content.spawn, "view preserves physical orientation and cell")

func transition_resets() -> void:
	var move_code = KEY_D if game.content.level_id == "mutsumi_l03" else KEY_W
	for code in [move_code,KEY_SPACE,KEY_E]:
		await key(code,true)
		await key(code,false)
		await delay(0.08)
		check(game.mover.phase != "idle" or game.view.busy, "transition really started before Reset")
		await reset_check()

func reset_check() -> void:
	await tap(KEY_R)
	check(game.mover.cell == game.content.spawn and game.mover.destination == game.content.spawn and game.mover.world == 0 and game.view.current == 0 and game.mover.phase == "idle" and not game.view.busy and game.mover.order.is_empty() and not game.graph.complete and not game.graph.door_open and not game.completion.visible and game.mover.moves == 0, "R restores complete playable state")

func layout_checks(name: String) -> void:
	for window_size in [Vector2i(1280,900),Vector2i(900,700)]:
		root.size = window_size
		await delay(0.2)
		for v in 4:
			for tile in game.board.tiles.values():
				if tile.visible:
					# Atlas cells include transparent padding; check the painted footprint.
					var used: Rect2i = tile.texture.get_image().get_used_rect()
					var origin: Vector2 = tile.global_position + (Vector2(used.position)-tile.texture.get_size()/2)*game.board.scale_factor
					var end: Vector2 = origin + Vector2(used.size)*game.board.scale_factor
					check(origin.x >= 0 and end.x <= window_size.x and origin.y >= 170 and end.y <= window_size.y-140, "painted tile footprint fits below objective and above hints")
			check(game.objective_label.size.x == window_size.x-66, "objective resizes with viewport")
			await shot(name + "_layout_" + str(window_size.y) + "_view_" + str(v))
			await tap(KEY_E)

func direction_key(direction: Vector2i) -> int:
	var directions = [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]
	return [KEY_W,KEY_D,KEY_S,KEY_A][posmod(directions.find(direction)-game.view.current,4)]

func move(direction: Vector2i, count: int = 1) -> void:
	await tap(direction_key(direction),count)

func delay(seconds: float) -> void:
	await create_timer(seconds).timeout

func key(code: int, pressed: bool) -> void:
	var event = InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	await process_frame

func tap(code: int, count: int = 1) -> void:
	for i in count:
		await key(code,true)
		await key(code,false)
		await delay(0.48)

func mouse_drag() -> void:
	var press = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(450,400)
	Input.parse_input_event(press)
	await process_frame
	var motion = InputEventMouseMotion.new()
	motion.position = Vector2(610,400)
	Input.parse_input_event(motion)
	await process_frame
	press.pressed = false
	press.position = motion.position
	Input.parse_input_event(press)
	await delay(0.5)

func shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(EVIDENCE + "/" + label + ".png")
	checkpoints.append({"name":label,"id":game.content.level_id,"cell":str(game.mover.cell),"world":game.mover.world,"view":game.view.current,"complete":game.graph.complete})
