extends "res://tests/playtest/test_batch_01_runtime.gd"
## Exact native P01 inputs and observations. No Foundation Runtime or state assignment.
const SaveStore = preload("res://game/shell/save_store.gd")
const UITokens = preload("res://game/shell/visual_01/tokens.gd")
var shell
var level_id := ""
var evidence := ""
var save_path := ""
var head := ""
var completion_events := 0
var completion_goals: Array = []
var recording := false
var observations: Array = []
var input_actions: Array = []
var parity: Array = []
var roll_samples: Array = []
var shift_samples: Array = []
var view_samples: Array = []
var physical_faces: Array[String] = []
var current_run := "probes"
var screenshots := 0

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--level="): level_id = arg.trim_prefix("--level=")
		elif arg.begins_with("--evidence-dir="): evidence = arg.trim_prefix("--evidence-dir=")
		elif arg.begins_with("--shell-save="): save_path = arg.trim_prefix("--shell-save=")
		elif arg.begins_with("--head="): head = arg.trim_prefix("--head=")
	if level_id not in ["mutsumi_l01", "mutsumi_l02", "mutsumi_l03"] or evidence.is_empty() or not save_path.begins_with("user://beta_sprint/b3d02_"):
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(evidence)
	check(DisplayServer.get_name() != "headless", "real graphical Runtime required")
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://game/shell/game_shell.tscn", "native Main Scene remains Shell")
	check(not FileAccess.file_exists(save_path), "fresh isolated save fixture")
	var store := SaveStore.new(save_path, "mutsumi_l01")
	var fixture := store.defaults()
	fixture.has_progress = true
	fixture.unlocked = ["mutsumi_l01", "mutsumi_l02", "mutsumi_l03"]
	fixture.recent = level_id
	fixture.settings.muted = true
	check(store.save(fixture), "existing SaveStore writes explicit already-unlocked fixture")
	shell = load("res://game/shell/game_shell.tscn").instantiate()
	root.add_child(shell)
	shell.adapter.completed.connect(on_completion)
	await delay(0.35)
	check(shell.save_path == save_path and shell.progress.unlocked == fixture.unlocked, "native Shell consumes isolated existing save fixture")
	await button("select")
	await button("level:" + level_id)
	game = shell.adapter.level
	check(game != null and shell.current_id == level_id and shell.state == shell.State.PLAYING, "native Level Select loads requested stable ID")
	if game == null:
		await finish()
		return
	check(game.has_method("display_3d"), "native entry exposes retained Pixel / 3D selection")
	if not game.has_method("display_3d"):
		await finish()
		return
	check(game.presenter != null and game.presenter is Node3D and not game.board.visible, "native entry defaults to real 3D Presenter")
	game.mover.committed.connect(on_commit)
	await delay(0.25)
	await shot("spawn")
	await visual_check("spawn")
	await camera_probes()
	await reset_probes()
	await pause_probe()
	if level_id == "mutsumi_l02": await l02_roll_probes()
	elif level_id == "mutsumi_l03": await connection_probes()
	await reset_check()
	var modes: Array = ["normal"] if level_id == "mutsumi_l01" else ["normal", "reset_replay", "alternate_views"]
	for mode in modes:
		var reference: Dictionary = {}
		for presentation in ["pixel", "3d"]:
			await reset_check()
			game.display_3d(presentation == "3d")
			await delay(0.12)
			current_run = presentation + "_" + mode
			observations.clear()
			input_actions.clear()
			recording = true
			record_observation("initial")
			var completed_before := completion_events
			if mode == "alternate_views": await tap(KEY_Q, 4)
			if level_id == "mutsumi_l01": await route_l01(mode)
			elif level_id == "mutsumi_l02": await route_l02(mode)
			else: await route_l03(mode)
			await delay(0.2)
			record_observation("goal")
			recording = false
			check(game.graph.complete and game.mover.cell == game.content.goal and game.mover.world == 0, "actual Goal " + current_run)
			check(shell.state == shell.State.LEVEL_COMPLETE and shell.view.screen == "complete" and completion_events == completed_before + 1, "exactly one native Shell completion " + current_run)
			check(game.process_mode == Node.PROCESS_MODE_DISABLED and not shell.dirty, "native completed level suspends and progression saves " + current_run)
			var persisted: Dictionary = shell.store.load_save()
			check(level_id in persisted.completed and persisted.recent == level_id, "actual existing SaveStore records native completion")
			var observed := {"inputs":input_actions.duplicate(true), "events":observations.duplicate(true), "final":native_snapshot()}
			var commits := observations.filter(func(row:Dictionary)->bool:return row.kind == "commit").size()
			if level_id == "mutsumi_l02":
				check(commits == 10 and game.mover.moves == 8 and game.mover.orientation.as_basis().is_equal_approx(Basis.IDENTITY), "L02 original solution keeps eight rolls, two shifts and final physical identity")
			elif level_id == "mutsumi_l03":
				check(commits == 6 and game.mover.moves == 6 and game.mover.orientation.as_basis().is_equal_approx(Basis(Vector3.LEFT,Vector3.DOWN,Vector3(0,0,1))), "L03 original solution keeps six physical east rolls")
			if presentation == "pixel": reference = observed
			else:
				check(reference == observed and not observations.is_empty(), "Pixel / 3D exact input and per-commit plus settled-view observation parity " + mode)
				parity.append({"mode":mode, "pixel":reference, "art3d":observed, "matched":reference == observed})
			await shot("complete")
			var locked := native_snapshot()
			# Space is GUI accept on the focused native Complete button. Query the
			# original Runtime phase guard without activating Shell navigation.
			check(not game.mover.shift(), "native completed Runtime rejects Shift")
			await tap(KEY_E)
			await tap(KEY_S)
			check(game.process_mode == Node.PROCESS_MODE_DISABLED and locked == native_snapshot(), "Goal locks native movement and view inputs " + current_run)
	check(completion_goals.all(func(row:Dictionary)->bool:return row.goal and row.phase == "complete" and row.id == level_id), "all native completion events correspond to committed Goal")
	if level_id == "mutsumi_l01": check(physical_faces.size() == 6, "actual L01 route visits all six marked-face directions")
	if level_id == "mutsumi_l02": check(physical_faces.size() == 4, "actual L02 tree route visits its four reachable marked-face directions")
	await reset_check()
	game.display_3d(true)
	await visual_check("final reset")
	await shot("final_reset")
	await finish()

func button(id: String) -> void:
	check(shell.view.buttons.has(id) and not shell.view.buttons[id].disabled, "native Shell button available: " + id)
	if not shell.view.buttons.has(id) or shell.view.buttons[id].disabled: return
	shell.view.buttons[id].pressed.emit()
	await process_frame
	await delay(0.1)

func on_completion() -> void:
	completion_events += 1
	completion_goals.append({"id":shell.current_id, "goal":shell.adapter.level.graph.complete, "phase":shell.adapter.level.mover.phase})

func native_snapshot() -> Dictionary:
	return {"id":game.content.level_id, "cell":[game.mover.cell.x,game.mover.cell.y], "world":game.mover.world, "orientation":game.mover.orientation.key(), "face":str(game.mover.orientation.face_direction()), "view":game.view.current, "link_active":game.graph.link.active, "plate":game.graph.plate_pressed, "gate":game.graph.door_open, "goal":game.graph.complete, "moves":game.mover.moves, "phase":game.mover.phase}

func record_observation(kind: String) -> void:
	if not recording: return
	var value := native_snapshot()
	observations.append({"kind":kind, "state":value, "native_gameplay_observation_sha256":JSON.stringify(value).sha256_text()})

func on_commit() -> void:
	record_observation("commit")
	var face: String = str(game.mover.orientation.face_direction())
	if face not in physical_faces: physical_faces.append(face)

func key(code: int, pressed: bool) -> void:
	if recording: input_actions.append({"key":code, "pressed":pressed})
	await super.key(code, pressed)

func tap(code: int, count: int = 1) -> void:
	for i in count:
		if not is_instance_valid(game):
			check(false, "native level unexpectedly unloaded before input")
			await finish()
			await process_frame
			return
		var previous_view: int = game.view.current
		await super.tap(code)
		if not is_instance_valid(game):
			check(false, "native level unexpectedly unloaded during input")
			await finish()
			await process_frame
			return
		if game.view.current != previous_view: record_observation("view_settled")

func mouse_drag() -> void:
	if recording: input_actions.append({"mouse_drag":[450,400,610,400]})
	var previous_view: int = game.view.current
	await super.mouse_drag()
	if game.view.current != previous_view: record_observation("view_settled")

func visual_check(label: String) -> void:
	await process_frame
	await process_frame
	var seen: Dictionary = game.presenter.debug_snapshot()
	check(game.presenter.actor.basis.is_equal_approx(game.mover.orientation.as_basis()), label + " visual cube basis equals actual native physical orientation")
	check(seen.world == game.mover.world and seen.view == game.view.current, label + " visual world/view observes actual Runtime")
	check(is_equal_approx(seen.camera_angle, PI/4-game.view.displayed_angle()), label + " actual 3D camera consumes native displayed quarter-turn angle")
	if level_id != "mutsumi_l01":
		check(seen.gate_state == "not_authored" and seen.plate_state == "not_authored", label + " unauthored gate/plate remain absent")
		check(game.presenter.mechanisms.all(func(pair:Dictionary)->bool:return not pair.has("gate") and not pair.has("plate")), label + " no false optional mechanism nodes")
		var expected_exit := "complete" if game.graph.complete else "available" if game.mover.world == 0 else "locked"
		if not game.graph.can_stand(game.content.goal, game.mover.world): expected_exit = "not_authored"
		check(seen.exit_state == expected_exit, label + " exit presentation follows actual world support and Goal")
		if level_id == "mutsumi_l03":
			var effective: bool = game.graph.link.active and not game.view.busy
			check(seen.link_active == effective, label + " 3D endpoint status observes effective native connection")
			check(seen.link_runtime_active == game.graph.link.active, label + " debug retains original Runtime connection observation")
			check(seen.link_status == ("active" if effective else "inactive"), label + " explicit active/inactive connection status")
			await marker_check(label, seen, effective)
	else:
		check(seen.gate_state == ("open" if game.graph.door_open else "closed") and seen.plate_state == ("pressed" if game.graph.plate_pressed else "inactive"), label + " original L01 plate/gate mapping preserved")
	check(game.approved_hud.world_label.text.contains("Mortis" if game.mover.world == 1 else "若叶睦"), label + " approved HUD world follows Runtime")

func marker_check(label: String, seen: Dictionary, effective: bool) -> void:
	check(game.presenter.link_markers.size() == 2 and seen.link_markers.size() == 2, label + " exactly two actual authored endpoint markers")
	if game.presenter.link_markers.size() != 2 or seen.link_markers.size() != 2: return
	var expected_anchors: Array = [game.graph.link.a, game.graph.link.b]
	for index in 2:
		var row: Dictionary = game.presenter.link_markers[index]
		var observed: Dictionary = seen.link_markers[index]
		check(row.anchor == expected_anchors[index], label + " marker uses original Runtime anchor identity")
		check(row.node is Label3D and observed.text == row.node.text and observed.visible == row.node.is_visible_in_tree(), label + " debug text/visibility observes real Label3D")
		check(row.node.text == ("连接成立" if effective else "未连接"), label + " physical endpoint text follows effective native permission")
		check(row.node.is_visible_in_tree() == game.graph.can_stand(row.anchor.node,game.mover.world), label + " endpoint visibility observes actual current-world support")
		check(row.node.get_parent() == game.presenter and row.node.font == UITokens.font(false,600), label + " endpoint uses direct presentation child and approved shared font")
		check(observed.position == row.node.position, label + " debug position observes physical endpoint marker")
		var point: Vector3 = game.presenter.displayed_position(row.anchor.position(), row.anchor.platform)
		check(is_equal_approx(row.node.position.x,point.x) and is_equal_approx(row.node.position.z,point.z), label + " marker follows native endpoint and actual interpolated platform offset")
		var screen: Vector2 = game.presenter.camera.unproject_position(row.node.global_position)
		var area: Vector2 = game.visual_viewport.get_visible_rect().size
		check(screen.x >= 0 and screen.x <= area.x and screen.y >= 0 and screen.y <= area.y, label + " endpoint marker stays within real 3D viewport")

func l03_topology_check() -> void:
	for world in 2:
		var authored = game.content.surface_cells if world == 0 else game.content.inner_cells
		var floors: Array = game.presenter.assets.filter(func(row:Dictionary)->bool:return row.world == world and row.walkable)
		check(floors.size() == authored.size(), "L03 each world has exact authored walkable visual footprint count")
		var observed_cells: Array = []
		for row in floors:
			var cell := Vector2i(row.cell)
			observed_cells.append(cell)
			check(cell in authored and row.cell == Vector2(cell) and row.platform == game.graph.nodes[cell], "L03 floor maps exact native integer cell and platform")
			check(str(row.node.get_meta("approved_asset_id")).ends_with("_FLOOR_001"), "L03 existing approved floors add no visual bridge across native gap")
		check(observed_cells.size() == authored.size() and authored.all(func(cell:Vector2i)->bool:return cell in observed_cells), "L03 both worlds preserve each original support cell")
		check(not floors.any(func(row:Dictionary)->bool:return row.cell.x > 3.0 and row.cell.x < 9.0), "L03 authored 3 to 9 gap remains visually unsupported")

func reset_check() -> void:
	await tap(KEY_R)
	check(shell.state == shell.State.PLAYING and game.mover.cell == game.content.spawn and game.mover.destination == game.content.spawn and game.mover.world == 0 and game.view.current == 0 and game.mover.phase == "idle" and not game.view.busy and game.mover.order.is_empty() and game.mover.held.is_empty() and not game.graph.complete and not game.graph.door_open and not game.graph.plate_pressed and not game.completion.visible and game.mover.moves == 0, "actual R restores full native state")
	check(game.mover.orientation.as_basis().is_equal_approx(Basis.IDENTITY), "Reset restores actual physical identity")
	await visual_check("Reset")
	check(not game.presenter.shift_active and not game.presenter.shift_committed and is_equal_approx(game.presenter.transition_progress,1.0), "Reset clears reconstruction transient state")

func camera_probes() -> void:
	for world in 2:
		if world == 1:
			if level_id == "mutsumi_l01": await move(Vector2i.UP,3)
			await shift_probe()
		for code in [KEY_E,KEY_Q]:
			var pose = game.mover.orientation.key()
			var cell: Vector2i = game.mover.cell
			for quarter in 4:
				var previous: int = game.view.current
				await key(code,true)
				await key(code,false)
				await delay(0.08)
				check(game.view.busy and game.mover.orientation.key() == pose and game.mover.cell == cell, "camera preview preserves native physical cube")
				await delay(0.4)
				check(game.view.current == posmod(previous + (1 if code == KEY_E else -1),4) and not game.view.busy, "both camera directions settle exact adjacent quarter")
				check(game.mover.orientation.key() == pose and game.mover.cell == cell, "settled camera preserves native cell/orientation")
				await visual_check("camera quarter")
				view_samples.append({"world":world,"code":code,"state":native_snapshot(),"visual":game.presenter.debug_snapshot()})
				await shot("camera_" + str(world) + "_" + str(code) + "_" + str(quarter))
		check(game.view.current == 0, "both complete camera orbits return NORTH")
	await reset_check()

func shift_probe() -> void:
	var cell: Vector2i = game.mover.cell
	var pose: String = game.mover.orientation.key()
	var world: int = game.mover.world
	await key(KEY_SPACE,true)
	await key(KEY_SPACE,false)
	for pause in [0.04,0.08,0.16,0.2]:
		await delay(pause)
		var seen: Dictionary = game.presenter.debug_snapshot()
		shift_samples.append({"state":native_snapshot(),"visual":seen})
		check(game.mover.cell == cell and game.mover.orientation.key() == pose, "actual world shift preserves cell and physical pose throughout")
		await shot("shift_sample")
	check(game.mover.world == 1-world and game.mover.phase == "idle", "actual Shift commits target world")
	await visual_check("Shift committed")
	check(not game.presenter.shift_active and game.presenter.world_roots[game.mover.world].visible and not game.presenter.world_roots[1-game.mover.world].visible, "committed shift finishes with correct actual Surface / Inner display")

func reset_probes() -> void:
	var motion := KEY_D if level_id == "mutsumi_l03" else KEY_W
	for code in [motion, KEY_E]:
		await key(code,true)
		await key(code,false)
		await delay(0.08)
		check(game.mover.phase != "idle" or game.view.busy, "actual transition began before Reset")
		await reset_check()
		await delay(0.45)
		check(game.mover.cell == game.content.spawn and game.view.current == 0 and game.mover.moves == 0, "old transition cannot commit after Reset")
	if level_id == "mutsumi_l01": await move(Vector2i.UP,3)
	await key(KEY_SPACE,true)
	await key(KEY_SPACE,false)
	await delay(0.08)
	check(game.mover.phase == "shift" and game.presenter.shift_active, "actual Shift and reconstruction began before Reset")
	await reset_check()
	await delay(0.45)
	check(game.mover.world == 0 and not game.presenter.shift_active, "old Shift cannot commit after Reset")

func pause_probe() -> void:
	var motion := KEY_D if level_id == "mutsumi_l03" else KEY_W
	await key(motion,true)
	await delay(0.08)
	await key(KEY_ESCAPE,true)
	await key(KEY_ESCAPE,false)
	var frozen := native_snapshot()
	var elapsed: float = game.mover.elapsed
	var actor: Transform3D = game.presenter.actor.transform
	await key(motion,false)
	await delay(0.3)
	check(shell.state == shell.State.PAUSED and native_snapshot() == frozen and game.mover.elapsed == elapsed and game.presenter.actor.transform == actor and game.mover.order.is_empty(), "actual Shell Pause freezes native roll and presentation and clears held input")
	await button("resume")
	await delay(0.38)
	check(shell.state == shell.State.PLAYING and game.mover.moves == 1 and game.mover.phase == "idle", "actual Resume completes the original pending roll once")
	await reset_check()

func sample_roll(direction: Vector2i) -> void:
	var origin: Vector2i = game.mover.cell
	var pose: String = game.mover.orientation.key()
	var moves: int = game.mover.moves
	var code := direction_key(direction)
	await key(code,true)
	await key(code,false)
	for target_fraction in [0.10,0.40,0.70]:
		while game.mover.moving and game.mover.fraction < target_fraction: await process_frame
		check(game.mover.moving and game.mover.cell == origin and game.mover.orientation.key() == pose and game.mover.moves == moves, "early/mid/late roll keeps native committed pose until landing")
		var seen: Dictionary = game.presenter.debug_snapshot()
		check(seen.fraction > 0.0 and seen.fraction < 1.0 and game.presenter.actor.basis.determinant() > 0.99, "roll uses real proper cube interpolation")
		roll_samples.append({"direction":str(direction),"state":native_snapshot(),"visual":seen})
		await shot("roll_sample")
	await delay(0.16)
	check(game.mover.phase == "idle" and game.mover.cell == origin+direction and game.mover.moves == moves+1 and game.mover.orientation.key() != pose, "native roll lands and commits exactly one physical quarter turn")
	await visual_check("roll landing")

func l02_roll_probes() -> void:
	await sample_roll(Vector2i.UP)
	await sample_roll(Vector2i.DOWN)
	await move(Vector2i.UP,2)
	await shift_probe()
	await move(Vector2i.UP,2)
	await sample_roll(Vector2i.RIGHT)
	await sample_roll(Vector2i.LEFT)
	check(roll_samples.size() == 12, "four native roll directions have early/mid/late actual samples")
	await reset_check()

func connection_probes() -> void:
	l03_topology_check()
	await move(Vector2i.RIGHT,3)
	var blocked := native_snapshot()
	await move(Vector2i.RIGHT)
	check(native_snapshot() == blocked and not game.graph.link.active, "before alignment the real authored gap blocks crossing")
	await visual_check("before connection")
	await shot("before_connection")
	await tap(KEY_E)
	check(game.graph.link.active and game.view.current == 1, "Surface EAST activates exact native authored pair")
	await visual_check("active connection")
	await shot("connection_active")
	await shift_probe()
	check(not game.graph.link.active and game.mover.world == 1 and game.view.current == 1, "Inner EAST never activates Surface-only connection")
	blocked = native_snapshot()
	await move(Vector2i.RIGHT)
	check(native_snapshot() == blocked, "wrong-world actual input cannot cross")
	await shot("wrong_world_blocked")
	await shift_probe()
	check(game.graph.link.active, "return Surface restores actual connection")
	await key(KEY_E,true)
	await key(KEY_E,false)
	await delay(0.08)
	check(game.view.busy, "actual view transition started at connected endpoint")
	await visual_check("rotation pending")
	await reset_check()
	await move(Vector2i.RIGHT,3)
	await mouse_drag()
	var pose: String = game.mover.orientation.key()
	var count: int = game.mover.moves
	await key(direction_key(Vector2i.RIGHT),true)
	await key(direction_key(Vector2i.RIGHT),false)
	await delay(0.1)
	check(game.mover.crossing and game.mover.cell == Vector2i(3,2) and game.mover.destination == Vector2i(9,2) and game.mover.orientation.key() == pose, "real connection is timed cube roll from original 3 to 9")
	await shot("crossing_pending")
	await tap(KEY_Q)
	check(game.mover.cell == Vector2i(9,2) and game.mover.moves == count+1 and game.view.current == 1 and not game.view.busy, "crossing lands once and rejects concurrent rotation")
	await visual_check("connection crossed")
	await shot("connection_crossed")
	await tap(KEY_E)
	check(not game.graph.link.active and game.graph.can_stand(game.mover.cell,0), "disconnection preserves supported native destination")
	await visual_check("connection disconnected")
	await shot("connection_disconnected")
	blocked = native_snapshot()
	await move(Vector2i.LEFT)
	check(native_snapshot() == blocked, "disconnected actual return-crossing input blocks")
	await reset_check()

func shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	screenshots += 1
	var name := "%03d_%s_%s" % [screenshots,current_run,label]
	root.get_texture().get_image().save_png(evidence.path_join(name+".png"))
	checkpoints.append({"name":name,"state":native_snapshot(),"visual":game.presenter.debug_snapshot(),"shell_state":shell.state,"hint":game.hints.text,"objective":game.hints.objective(game.mover,game.view)})

func finish() -> void:
	var report := {"checks":checks,"failures":failures,"pid":OS.get_process_id(),"head":head,"project":ProjectSettings.globalize_path("res://"),"level_id":level_id,"save_path":save_path,"save_absolute":ProjectSettings.globalize_path(save_path),"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"engine":Engine.get_version_info(),"parity":parity,"completion_events":completion_events,"completion_goals":completion_goals,"roll_samples":roll_samples,"shift_samples":shift_samples,"views":view_samples,"physical_face_directions":physical_faces,"screenshots":checkpoints,"scope":{"runtime":"Existing native ContentLevel/P01 GridMovement/PerspectiveController","state_key":"Native Gameplay observation SHA256, not Foundation statekey.v1","fixture":"Already-unlocked isolated SaveStore; no new unlock or Cold Continue gates","six_face_directions":"L01 actual authored route only; L02 has four reachable marked-face directions; L03 straight path retains marked +Z","stairs_clearance":"PARTIAL_PASS preserved","stairs_traversal":"NOT_RUN","hint_content":"Owner 06 stale L03 hint remains pending; exact text recorded, no hint production edits"}}
	FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	if shell != null:
		shell.show_main_menu()
		game = null
		await delay(0.15)
		root.remove_child(shell)
		shell.free()
		await process_frame
	print("B3D02 GAMEPLAY ",level_id,": ",checks," checks; failures=",failures)
	quit(0 if failures.is_empty() else 1)
