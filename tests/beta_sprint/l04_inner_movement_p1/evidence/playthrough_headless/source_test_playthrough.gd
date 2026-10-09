extends "res://tests/beta_sprint/l04_inner_movement_p1/test_l04.gd"
## Three native-input completions, each shifting at the authored Spawn first.

func playthroughs() -> void:
	await reset_during_actions()
	var pose: String = game.mover.orientation.key()
	for code in [KEY_E,KEY_Q]:
		for i in 4:
			var previous: int = game.view.current
			await tap(code)
			check(game.view.current == posmod(previous+(1 if code == KEY_E else -1),4),"original adjacent view order")
			check(is_equal_approx(game.view.displayed_angle(),game.view.current*PI/2) and not game.view.busy,"exact settled 90 degree view")
			check(game.mover.orientation.key() == pose,"view preserves physical cube identity")
	for mode in ["normal","reset_replay","alternate_camera"]:
		route_name = mode
		await tap(KEY_R)
		check_reset()
		var events_before := completions
		if mode == "alternate_camera":
			await tap(KEY_E)
			await tap(KEY_E)
		await shot("surface_spawn")
		var before_shift := state()
		await tap(KEY_SPACE)
		check(game.mover.world == 1 and game.graph.world == 1 and game.mover.cell == game.content.spawn,"Spawn Shift reaches actual Inner landing")
		check(game.mover.orientation.key() == before_shift.orientation and game.view.current == before_shift.view,"World Shift preserves grid pose and view")
		await shot("inner_spawn")
		await move(Vector2i.LEFT)
		check(game.mover.cell == Vector2i(0,5),"50ms short input at Inner Spawn commits the authored approach")
		await shot("first_inner_move")
		await move(Vector2i.UP,2)
		var before_reject := state()
		await tap(KEY_SPACE)
		check(state_key(state()) == state_key(before_reject),"original Shift still rejects absent Surface support at (0,3)")
		await move(Vector2i.UP)
		await move(Vector2i.RIGHT,3)
		while game.view.current != 1:
			await tap(KEY_Q if mode == "alternate_camera" else KEY_E)
		check(game.graph.link.active,"existing Inner EAST connection activates")
		await tap(KEY_SPACE)
		var endpoint: Vector2i = game.mover.cell
		await blocked_move(Vector2i.RIGHT)
		check(game.mover.cell == endpoint and not game.graph.link.active,"Surface cannot bypass original Inner connection condition")
		await tap(KEY_SPACE)
		await cross_connection()
		if mode == "alternate_camera": await tap(KEY_E)
		await move(Vector2i.RIGHT)
		await blocked_move(Vector2i.RIGHT)
		check(game.mover.cell == Vector2i(10,2) and game.mover.world == 1,"Inner still cannot take Surface Goal branch")
		await tap(KEY_SPACE)
		await move(Vector2i.RIGHT)
		await move(Vector2i.UP)
		await delay(0.1)
		check(game.graph.complete and game.mover.phase == "complete" and game.mover.world == 0 and game.mover.cell == game.content.goal,"natural input committed Surface Goal")
		check(shell.state == shell.State.LEVEL_COMPLETE and completions == events_before+1,"formal Shell callback once per complete route")
		check(game.mover.order.is_empty() and game.mover.orientation.valid(),"Goal clears held input and keeps valid cube pose")
		await shot("goal")
		routes.append({"mode":mode,"kind":"natural_InputEvent_from_Spawn_Shift","goal":game.graph.complete,"cell":str(game.mover.cell),"world":game.mover.world,"view":game.view.current,"moves":game.mover.moves,"formal_completion_events":completions-events_before,"state_key":state_key(state())})
		await tap(KEY_R)
		check_reset()
		check(shell.state == shell.State.PLAYING and not shell.adapter.reported,"Goal Reset uses original Shell and rearms original adapter")
	check(completions == 3,"three routes produce three formal Goal events")

func direction_key(direction: Vector2i) -> int:
	var directions := [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]
	return KEYS[posmod(directions.find(direction)-game.view.current,4)]

func move(direction: Vector2i,count: int=1) -> void:
	for i in count:
		var before := state()
		var start: Vector2i = game.mover.cell
		var commits_before := total_commits
		var code := direction_key(direction)
		await key(code,true)
		check(game.mover.held.has(code) and game.mover.moving,"50ms route press enters actual Runtime and starts roll")
		await delay(0.05)
		await key(code,false)
		await delay(0.4)
		check(game.mover.cell == start+direction and total_commits == commits_before+1,"one short press commits exactly one supported adjacent roll")
		check(game.mover.orientation.valid() and game.presenter.actor.basis.is_equal_approx(game.mover.orientation.as_basis()),"settled Presenter physical basis matches real cube orientation")
		rows.append({"action":"route "+OS.get_keycode_string(code),"press_seconds":0.05,"before_state_key":state_key(before),"after_state_key":state_key(state()),"transition_started":true,"commit_count":total_commits-commits_before,"kind":"actual short InputEvent roll"})

func blocked_move(direction: Vector2i) -> void:
	var before := state()
	var count_before := total_commits
	await tap(direction_key(direction))
	check(state_key(state()) == state_key(before) and total_commits == count_before,"original native guard rejects unsupported world edge")

func cross_connection() -> void:
	var actor_start: Vector3 = game.presenter.actor.position
	var count_before := total_commits
	await shot("inner_east_connection")
	var code := direction_key(Vector2i.RIGHT)
	await key(code,true)
	await delay(0.05)
	await key(code,false)
	await delay(0.06)
	check(game.mover.crossing and game.mover.moving and game.mover.cell == Vector2i(3,2) and total_commits == count_before,"original timed connection starts without early commit")
	check(not game.presenter.actor.position.is_equal_approx(actor_start),"existing 3D Presenter observes and displays native in-flight roll")
	await key(KEY_Q,true)
	await key(KEY_Q,false)
	check(game.view.current == 1 and not game.view.busy,"crossing retains original action lock")
	await delay(0.35)
	check(game.mover.cell == Vector2i(9,2) and total_commits == count_before+1 and game.mover.orientation.valid(),"original connection completes through native committed landing")
	await shot("connection_landed")

func reset_during_actions() -> void:
	for code in [KEY_W,KEY_SPACE,KEY_E]:
		await key(code,true)
		await key(code,false)
		await delay(0.08)
		check(game.mover.phase != "idle" or game.view.busy,"real action begins before Reset probe")
		await tap(KEY_R)
		check_reset()
	await tap(KEY_SPACE)
	await key(KEY_A,true)
	await delay(0.08)
	await tap(KEY_R)
	await key(KEY_A,false)
	check_reset()
	check(game.mover.order.is_empty() and game.mover.held.is_empty(),"Reset clears actual held direction during Inner roll")

func check_reset() -> void:
	check(game.mover.cell == game.content.spawn and game.mover.destination == game.content.spawn and game.mover.world == 0 and game.graph.world == 0 and game.view.current == 0 and not game.view.busy and game.mover.phase == "idle" and game.mover.moves == 0 and not game.graph.complete and game.mover.order.is_empty(),"Reset restores authored Spawn/world/view/phase/Goal/input")
	check(not game.presenter.shift_active and game.presenter.actor.basis.is_equal_approx(game.mover.orientation.as_basis()),"Reset synchronizes existing Presenter and native physical state")

func shot(label: String) -> void:
	if not graphical: return
	await RenderingServer.frame_post_draw
	var folder := evidence.path_join("screenshots")
	DirAccess.make_dir_recursive_absolute(folder)
	var filename := "%02d_%s_%s.png" % [shots.size()+1,route_name,label]
	var path := folder.path_join(filename)
	check(root.get_texture().get_image().save_png(path) == OK,"real rendered screenshot saved")
	shots.append({"path":"screenshots/"+filename,"sha256":FileAccess.get_sha256(path),"state":state(),"presenter":presenter_state()})
