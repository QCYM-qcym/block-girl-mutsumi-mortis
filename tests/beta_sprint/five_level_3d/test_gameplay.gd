extends "res://tests/beta_sprint/content_batch_02/test_playthrough.gd"
## Retains native InputEvents/L05 route; L04 follows accepted Spawn-Shift fixture.
## Every value comes from P01. No graph/mover/view mutation or doubles.
var save_path := ""
var head := ""
var cold_continue := false
var recording := false
var observations: Array = []
var inputs: Array = []
var parity: Array = []
var natural_samples: Array = []
var continuation: Array = []
var qualification: Dictionary = {}

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="): evidence = arg.trim_prefix("--evidence-dir=")
		elif arg.begins_with("--shell-save="): save_path = arg.trim_prefix("--shell-save=")
		elif arg.begins_with("--head="): head = arg.trim_prefix("--head=")
		elif arg == "--cold-continue": cold_continue = true
	if evidence.is_empty() or not save_path.begins_with("user://beta_sprint/five_level_3d_owner/"):
		quit(2)
		return
	graphical = DisplayServer.get_name() != "headless"
	check(graphical,"real graphical default-project-renderer process")
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://game/shell/game_shell.tscn","formal Main Scene is retained Shell")
	for path in [Save.DEFAULT_PATH,Save.DEFAULT_PATH+".bak"]: protected_save[path] = file_hash(path)
	source_hashes = source_snapshot()
	if not cold_continue:
		check(not FileAccess.file_exists(save_path),"new unique profile; no old QA save touched")
		var setup_store = Save.new(save_path,"mutsumi_l01")
		var setup: Dictionary = setup_store.defaults()
		setup.has_progress = true
		setup.completed = ["mutsumi_l01","mutsumi_l02","mutsumi_l03"]
		setup.unlocked = ["mutsumi_l01","mutsumi_l02","mutsumi_l03","mutsumi_l04"]
		setup.recent = "mutsumi_l04"
		setup.settings.muted = true
		check(setup_store.save(setup),"explicit prior L01-L03 qualification fixture uses native SaveStore")
		qualification = {"kind":"explicit prior L01-L03 fixture; not HumanQA","progress":setup.duplicate(true),"L05_initially_locked":true}
	shell = load("res://game/shell/game_shell.tscn").instantiate()
	shell.save_path = save_path
	root.add_child(shell)
	shell.adapter.completed.connect(on_completed)
	await delay(0.3)
	check(shell.save_path == save_path and shell.state == shell.State.MAIN_MENU,"native Shell opens isolated profile")
	if cold_continue:
		check(FileAccess.file_exists(save_path) and "mutsumi_l04" in shell.progress.completed and "mutsumi_l05" in shell.progress.completed,"new PID reads actual previous native completion save")
		await button("continue")
		game = shell.adapter.level
		check(shell.current_id == "mutsumi_l05" and game.content.level_id == "mutsumi_l05" and game.using_3d,"cold Continue enters shipped L05 3D attachment")
		check_reset()
		await visual_check("cold Continue")
		await shot("cold_continue_spawn")
		continuation.append({"kind":"new_PID_cold_Continue","id":shell.current_id,"save":shell.store.load_save(),"state":native_snapshot()})
	else:
		await button("select")
		check(shell.view.buttons["level:mutsumi_l05"].disabled and "mutsumi_l05" not in shell.progress.unlocked,"formal menu initially locks L05")
		await button("level:mutsumi_l04")
		game = shell.adapter.level
		for id in ["mutsumi_l04","mutsumi_l05"]:
			if id == "mutsumi_l05":
				await button("select")
				check(not shell.view.buttons["level:mutsumi_l05"].disabled,"real L04 Goal unlocked original L05 menu entry")
				await shot_menu("L05_unlocked")
				await button("level:mutsumi_l05")
				game = shell.adapter.level
			check(game.content.level_id == id and game.using_3d and game.presenter is Node3D,"formal menu enters actual 3D level "+id)
			game.mover.committed.connect(on_committed)
			route_name = id+"_probes"
			await visual_check("spawn")
			await shot("spawn")
			await reset_probes(0)
			await sample_probes()
			for mode in ["normal","reset_replay","alternate_camera"]:
				var reference: Dictionary = {}
				for presentation in ["pixel","3d"]:
					await tap(KEY_R)
					check_reset()
					game.display_3d(presentation == "3d")
					await delay(0.12)
					route_name = id+"_"+presentation+"_"+mode
					observations.clear()
					inputs.clear()
					recording = true
					record_observation("initial")
					var before := completion_events
					if mode == "reset_replay": await reset_probes(0)
					if mode == "alternate_camera":
						await tap(KEY_E,2)
						check(game.view.current == 2,"alternate route starts with actual SOUTH camera")
					if id == "mutsumi_l04": await route_l04(mode)
					else: await route_l05("alternate_views" if mode == "alternate_camera" else mode)
					await delay(0.12)
					record_observation("goal")
					recording = false
					check(game.graph.complete and game.mover.cell == game.content.goal and game.mover.world == 0,"complete natural Goal "+route_name)
					check(shell.state == shell.State.LEVEL_COMPLETE and shell.view.screen == "complete" and completion_events == before+1,"exactly one native Goal+Shell callback "+route_name)
					check(game.process_mode == Node.PROCESS_MODE_DISABLED and not shell.dirty,"native completion freezes level and saves progress")
					var saved: Dictionary = shell.store.load_save()
					check(id in saved.completed and saved.recent == id and shell.store.last_error.is_empty(),"native completion checksum and recent progress")
					if id == "mutsumi_l04": check("mutsumi_l05" in saved.unlocked,"real L04 Goal alone unlocks L05")
					var observed := {"inputs":inputs.duplicate(true),"events":observations.duplicate(true),"final":serialized_native()}
					var commits: int = observations.filter(func(row:Dictionary)->bool:return row.kind == "commit").size()
					check(commits > 0,"positive real native commits "+route_name)
					if presentation == "pixel": reference = observed
					else:
						check(reference == observed,"strict actual P01 serialized Pixel/3D per-commit parity "+id+"/"+mode)
						parity.append({"id":id,"mode":mode,"matched":reference == observed,"pixel":reference,"art3d":observed})
					await shot("goal")
					routes.append({"id":id,"presentation":presentation,"mode":mode,"goal":game.graph.complete,"formal_events":completion_events-before,"commits":commits,"state":native_snapshot()})
					var locked := serialized_native()
					await tap(KEY_E)
					await tap(KEY_S)
					check(locked == serialized_native(),"Goal locks real view/roll inputs")
			game.display_3d(true)
		check(completion_events == 12 and routes.size() == 12 and parity.size() == 6 and parity.all(func(row:Dictionary)->bool:return row.matched),"both levels complete all three Pixel/3D routes with exact parity")
		await button("main")
		game = null
		check(shell.state == shell.State.MAIN_MENU and shell.adapter.level == null,"Goal returns through actual main-menu button")
		await button("continue")
		game = shell.adapter.level
		check(shell.current_id == "mutsumi_l05" and game.content.level_id == "mutsumi_l05" and shell.state == shell.State.PLAYING,"same-process Continue enters actual most recent L05")
		check_reset()
		await visual_check("same-process Continue")
		await shot("same_process_continue_spawn")
		continuation.append({"kind":"same_process_Continue","id":shell.current_id,"state":native_snapshot(),"progress":shell.store.load_save()})
		DirAccess.copy_absolute(save_path,evidence.path_join("actual_native_progress.json"))
	for path in protected_save: check(file_hash(path) == protected_save[path],"existing default save byte protection "+path)
	check(source_snapshot() == source_hashes,"consumed frozen production bytes unchanged")
	await finish()

func button(id: String) -> void:
	check(shell.view.buttons.has(id) and not shell.view.buttons[id].disabled,"real native menu button "+id)
	if not shell.view.buttons.has(id) or shell.view.buttons[id].disabled: return
	var position: Vector2 = shell.view.buttons[id].get_global_rect().get_center()
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = position
		event.global_position = position
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await delay(0.25)

func native_snapshot() -> Dictionary:
	return {"id":game.content.level_id,"cell":[game.mover.cell.x,game.mover.cell.y],"destination":[game.mover.destination.x,game.mover.destination.y],"world":game.mover.world,"graph_world":game.graph.world,"view":game.view.current,"view_busy":game.view.busy,"orientation":game.mover.orientation.key(),"physical_face_direction":str(game.mover.orientation.face_direction()),"moves":game.mover.moves,"phase":game.mover.phase,"moving":game.mover.moving,"crossing":game.mover.crossing,"link":game.graph.link.active,"plate":game.graph.plate_pressed,"gate":game.graph.door_open,"goal":game.graph.complete}

func serialized_native() -> String:
	# JSON is the actual deterministic serialized native observation. It is
	# explicitly not Foundation's statekey.v1 and is never assigned to Runtime.
	return JSON.stringify(native_snapshot())

func record_observation(kind: String) -> void:
	if recording:
		var serialized := serialized_native()
		observations.append({"kind":kind,"state":native_snapshot(),"p01_serialized_native":serialized,"sha256":serialized.sha256_text()})

func on_committed() -> void:
	super.on_committed()
	record_observation("commit")

func key(code: int,pressed: bool) -> void:
	if recording: inputs.append({"key":code,"pressed":pressed})
	await super.key(code,pressed)

func tap(code: int,count: int=1) -> void:
	for i in count:
		await key(code,true)
		await delay(0.05)
		await key(code,false)
		await delay(0.45)
		record_observation("settled_action")

func check_reset() -> void:
	super.check_reset()
	check(game.mover.held.is_empty() and game.mover.orientation.as_basis().is_equal_approx(Basis.IDENTITY) and not game.graph.plate_pressed,"Reset restores actual held keys/identity/plate")
	check(not game.presenter.shift_active and not game.presenter.shift_committed and game.presenter.actor.basis.is_equal_approx(game.mover.orientation.as_basis()),"Reset clears inherited transient visual state")

func visual_check(label: String) -> void:
	await process_frame
	await process_frame
	var seen: Dictionary = game.presenter.debug_snapshot()
	check(seen.world == game.mover.world and seen.view == game.view.current,"visual observes actual world/view "+label)
	if not game.mover.moving: check(game.presenter.actor.basis.is_equal_approx(game.mover.orientation.as_basis()),"actual settled physical cube basis "+label)
	check(is_equal_approx(seen.camera_angle,PI/4-game.view.displayed_angle()),"inherited camera angle matches native rotation "+label)
	var connected: bool = game.graph.link.active and not game.view.busy
	check(seen.link_active == connected and seen.link_runtime_active == game.graph.link.active,"endpoint observes actual effective native permission "+label)
	check(game.presenter.link_markers.size() == 2,"both authored endpoint markers "+label)
	for row in game.presenter.link_markers:
		check(row.node.text == ("连接成立" if connected else "未连接") and row.node.visible == game.graph.can_stand(row.anchor.node,game.mover.world),"actual endpoint text/support visibility "+label)
		var point: Vector3 = game.presenter.displayed_position(row.anchor.position(),row.anchor.platform)
		check(is_equal_approx(row.node.position.x,point.x) and is_equal_approx(row.node.position.z,point.z),"endpoint follows native interpolated platform "+label)
		var screen: Vector2 = game.presenter.camera.unproject_position(row.node.global_position)
		var area: Vector2 = game.visual_viewport.get_visible_rect().size
		check(screen.x >= 0 and screen.x <= area.x and screen.y >= 0 and screen.y <= area.y,"endpoint stays in actual viewport "+label)
	if game.content.gate_enabled:
		check(seen.plate_state == ("pressed" if game.graph.plate_pressed else "inactive") and seen.gate_state == ("open" if game.graph.door_open else "closed"),"native Surface-only gate/plate visual state "+label)
	else: check(seen.plate_state == "not_authored" and seen.gate_state == "not_authored","L04 unauthored gate/plate absent "+label)

func sample_probes() -> void:
	for world in 2:
		if world == 1: await tap(KEY_SPACE)
		for direction in [Vector2i.UP,Vector2i.DOWN]:
			if world == 1 and game.content.level_id == "mutsumi_l04": direction = Vector2i.LEFT if direction == Vector2i.UP else Vector2i.RIGHT
			if world == 1 and game.content.level_id == "mutsumi_l05": continue # Inner Spawn has no adjacent support.
			var origin: Vector2i = game.mover.cell
			var pose: String = game.mover.orientation.key()
			var code := direction_key(direction)
			await key(code,true)
			await key(code,false)
			for fraction in [0.15,0.45,0.75]:
				while game.mover.moving and game.mover.fraction < fraction: await process_frame
				check(game.mover.moving and game.mover.cell == origin and game.mover.orientation.key() == pose,"actual roll keeps committed cube until native landing")
				check(game.mover.fraction > 0 and game.mover.fraction < 1 and game.presenter.actor.basis.determinant() > 0.99,"sampled physical roll uses proper in-flight cube basis")
				natural_samples.append({"kind":"roll","state":native_snapshot(),"visual":game.presenter.debug_snapshot()})
				await shot("roll_sample")
			await delay(0.2)
			check(game.mover.cell == origin+direction,"actual sampled roll commits once")
			await visual_check("sampled roll landing")
		for code in [KEY_E,KEY_Q]:
			for quarter in 4:
				var pose: String = game.mover.orientation.key()
				await key(code,true)
				await key(code,false)
				await delay(0.08)
				check(game.view.busy and pose == game.mover.orientation.key(),"natural camera preview keeps physical cube")
				await visual_check("camera preview")
				natural_samples.append({"kind":"camera_preview","state":native_snapshot(),"visual":game.presenter.debug_snapshot()})
				await delay(0.4)
				await visual_check("camera settled")
				if code == KEY_E: await shot("camera_"+str(world)+"_"+str(quarter))
	await tap(KEY_R)
	check_reset()
	await key(KEY_SPACE,true)
	await key(KEY_SPACE,false)
	var shift_cell: Vector2i = game.mover.cell
	var shift_pose: String = game.mover.orientation.key()
	for pause in [0.04,0.08,0.16,0.2]:
		await delay(pause)
		check(game.mover.cell == shift_cell and game.mover.orientation.key() == shift_pose,"natural Shift preserves actual cell and physical cube throughout")
		natural_samples.append({"kind":"world_shift","state":native_snapshot(),"visual":game.presenter.debug_snapshot()})
		await shot("shift_sample")
	check(game.mover.world == 1 and game.mover.phase == "idle","natural Shift commits target world")
	await visual_check("Shift settled")
	await tap(KEY_R)
	check_reset()

func route_l04(mode: String) -> void:
	await shot("surface_spawn")
	await tap(KEY_SPACE)
	check(game.mover.world == 1 and game.mover.cell == game.content.spawn,"L04 native Shift at Spawn")
	await shot("inner_spawn")
	await move(Vector2i.LEFT)
	check(game.mover.cell == Vector2i(0,5),"L04 preserved Inner (0,5) first movement")
	await move(Vector2i.UP,2)
	var blocked := serialized_native()
	await tap(KEY_SPACE)
	check(serialized_native() == blocked,"L04 native unsafe Shift rejects missing Surface support")
	await move(Vector2i.UP)
	await move(Vector2i.RIGHT,3)
	while game.view.current != 1: await tap(KEY_Q if mode == "alternate_camera" else KEY_E)
	check(game.graph.link.active,"L04 actual Inner EAST connection")
	await visual_check("active connection")
	await tap(KEY_SPACE)
	blocked = serialized_native()
	await move(Vector2i.RIGHT)
	check(serialized_native() == blocked and not game.graph.link.active,"L04 Surface cannot cross Inner-only link")
	await visual_check("wrong-world connection")
	await tap(KEY_SPACE)
	await crossing(Vector2i(3,2),Vector2i(9,2))
	await visual_check("connection landed")
	if mode == "alternate_camera": await tap(KEY_E)
	await move(Vector2i.RIGHT)
	blocked = serialized_native()
	await move(Vector2i.RIGHT)
	check(serialized_native() == blocked,"L04 Inner cannot take Surface Goal branch")
	await tap(KEY_SPACE)
	await move(Vector2i.RIGHT)
	await move(Vector2i.UP)

func route_l05(mode: String) -> void:
	# Original Content Batch02 route. The old fixture's fixed Q×3 assumed
	# NORTH; this route also accepts the actual alternate SOUTH starting view.
	await move(Vector2i.UP,2)
	await move(Vector2i.UP)
	check(game.mover.cell == Vector2i(0,3),"L05 Surface cannot cross first bridge")
	await tap(KEY_SPACE)
	await move(Vector2i.UP)
	await move(Vector2i.RIGHT)
	await move(Vector2i.UP)
	check(game.mover.cell == Vector2i(1,2),"L05 Inner cannot bypass Surface bridge entrance")
	await tap(KEY_SPACE)
	await move(Vector2i.UP,2)
	await move(Vector2i.RIGHT,2)
	while game.view.current != 1: await tap(KEY_Q if mode == "alternate_views" else KEY_E)
	await move(Vector2i.RIGHT)
	check(game.mover.cell == Vector2i(3,0) and not game.graph.link.active,"L05 Surface EAST cannot use Inner connection")
	await visual_check("L05 wrong-world connection")
	await tap(KEY_SPACE)
	check(game.graph.link.active,"L05 Inner EAST activates actual link")
	await visual_check("L05 active connection")
	await crossing(Vector2i(3,0),Vector2i(9,0))
	if mode == "alternate_views": await tap(KEY_E)
	await move(Vector2i.RIGHT,2)
	await move(Vector2i.RIGHT)
	check(game.mover.cell == game.graph.PLATE and not game.graph.plate_pressed and not game.graph.door_open,"L05 Inner plate cannot bypass Gate")
	await visual_check("L05 inactive Inner plate")
	await shot("inner_plate_closed")
	await tap(KEY_SPACE)
	check(game.graph.plate_pressed and game.graph.door_open,"L05 Surface occupancy opens real Gate")
	await visual_check("L05 pressed Surface plate")
	await shot("plate_open")
	var code := direction_key(Vector2i.RIGHT)
	await key(code,true)
	await key(code,false)
	await delay(0.1)
	check(game.mover.cell == game.graph.PLATE and game.graph.door_open and game.mover.moving,"Gate stays open during authorized native roll")
	natural_samples.append({"kind":"authorized_gate_roll","state":native_snapshot(),"visual":game.presenter.debug_snapshot()})
	await shot("authorized_gate_roll")
	await delay(0.35)
	check(game.mover.cell == game.graph.BEYOND_GATE and not game.graph.door_open,"Gate closes only after formal landing")
	await visual_check("L05 gate landing")
	record_observation("gate_landed")
	await move(Vector2i.RIGHT)

func crossing(start: Vector2i,target: Vector2i) -> void:
	await visual_check("before native crossing")
	await super.crossing(start,target)
	record_observation("connection_landed")

func shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var filename := "%03d_%s_%s.png" % [shots.size()+1,route_name,label]
	var path := evidence.path_join(filename)
	check(root.get_texture().get_image().save_png(path) == OK,"real rendered screenshot saved")
	shots.append({"file":filename,"sha256":FileAccess.get_sha256(path),"state":native_snapshot(),"visual":game.presenter.debug_snapshot(),"shell_state":shell.state})

func shot_menu(label: String) -> void:
	await RenderingServer.frame_post_draw
	var filename := "%03d_%s.png" % [shots.size()+1,label]
	var path := evidence.path_join(filename)
	check(root.get_texture().get_image().save_png(path) == OK,"real menu screenshot saved")
	shots.append({"file":filename,"sha256":FileAccess.get_sha256(path),"shell_state":shell.state})

func finish() -> void:
	var actual_progress: Dictionary = shell.store.load_save()
	check(shell.store.last_error.is_empty(),"final actual SaveStore checksum")
	shell.show_main_menu()
	game = null
	await delay(0.25)
	root.remove_child(shell)
	shell.free()
	shell = null
	await delay(0.25)
	var report := {"checks":checks,"failures":failures,"doubles":[],"pid":OS.get_process_id(),"head":head,"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"engine":Engine.get_version_info(),"routes":routes,"parity":parity,"completion_events":completion_events,"completion_observations":completion_observations,"natural_samples":natural_samples,"screenshots":shots,"continuation":continuation,"save_path":save_path,"save_absolute":ProjectSettings.globalize_path(save_path),"actual_progress":actual_progress,"qualification":qualification,"protected_default_save_hashes":protected_save,"source_hashes":source_hashes,"scope":{"runtime":"P01 ContentState/GridMovement/PerspectiveController; unchanged","serialization":"actual deterministic P01 native observation JSON, not Foundation statekey.v1","input":"real Input.parse_input_event key/mouse -> native controls and Shell buttons","Foundation":"NOT_RUN / unchanged","stairs_clearance":"PARTIAL_PASS preserved","stairs_traversal":"NOT_RUN","HumanQA":"NOT_RUN for new 3D package"}}
	FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("FIVE3D GRAPHICAL: ",checks," checks; goals=",routes.size(),"; parity=",parity.size(),"; failures=",failures)
	quit(0 if failures.is_empty() else 1)
