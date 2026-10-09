extends SceneTree
## Observe the real Beta Shell / GridInput / mover. Never select gameplay state.
const ShellScene = preload("res://game/shell/game_shell.tscn")
const SaveStore = preload("res://game/shell/save_store.gd")
const L04Scene = preload("res://game/levels/mutsumi/batch_02/l04_borrowed_path.tscn")
const IDS = ["mutsumi_l01","mutsumi_l02","mutsumi_l03","mutsumi_l04"]
const KEYS = [KEY_W,KEY_D,KEY_S,KEY_A]
var shell
var game
var evidence := ""
var case_name := "probe"
var entry := "shell"
var graphical := false
var checks := 0
var failures: Array[String] = []
var rows: Array = []
var routes: Array = []
var commits: Array = []
var shots: Array = []
var total_commits := 0
var completions := 0
var profiles: Array = []
var route_name := "diagnosis"

func _initialize() -> void:
	call_deferred("run")

func check(value: bool,label: String) -> void:
	checks += 1
	if not value:
		failures.append(label)
		printerr("FAIL [L04-P1]: ",label)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="): evidence=arg.trim_prefix("--evidence-dir=")
		elif arg.begins_with("--case="): case_name=arg.trim_prefix("--case=")
		elif arg.begins_with("--entry="): entry=arg.trim_prefix("--entry=")
		elif arg == "--graphical": graphical=true
	if evidence.is_empty():
		quit(2)
		return
	check((DisplayServer.get_name() != "headless") == graphical,"explicit display mode")
	if case_name == "controls":
		for id in IDS.slice(0,3):
			await enter_level(id)
			for world in [0,1]:
				for keycode in KEYS:
					for duration in [0.05,0.75]:
						await probe(world,keycode,duration)
			await leave_level()
	elif case_name == "playthrough":
		await enter_level("mutsumi_l04")
		await playthroughs()
		await leave_level()
	else:
		await enter_level("mutsumi_l04")
		await probe(0,KEY_W,0.05)
		await probe(0,KEY_W,0.75)
		for keycode in KEYS:
			for duration in [0.05,0.75]:
				await probe(1,keycode,duration)
		var short_inner_moves := 0
		var held_inner_moves := 0
		for row in rows:
			if row.before.world == 1 and row.commit_count > 0:
				if row.press_seconds < 0.1: short_inner_moves += 1
				else: held_inner_moves += 1
		check(short_inner_moves > 0,"exact QA regression: a short direction press after Spawn Shift can move in Inner")
		check(held_inner_moves > 0,"held input after Spawn Shift can move in Inner")
		await leave_level()
	finish()

func enter_level(id: String) -> void:
	if entry == "standalone":
		game = L04Scene.instantiate()
		root.add_child(game)
	else:
		# Explicit test setup in a NEW PID-owned save. No human-QA unlock edits.
		var path := "user://l04_inner_movement_p1/%s_%s_%s/progress.json" % [OS.get_process_id(),case_name,id]
		check(not FileAccess.file_exists(path),"isolated profile is fresh")
		var store = SaveStore.new(path,IDS[0])
		var setup: Dictionary = store.defaults()
		setup.unlocked = IDS.duplicate()
		setup.completed = IDS.slice(0,3)
		setup.has_progress = true
		setup.recent = id
		check(store.save(setup),"existing SaveStore writes valid isolated fixture setup")
		profiles.append({"path":path,"absolute":ProjectSettings.globalize_path(path),"setup":"seeded test profile, not human progression QA"})
		shell = ShellScene.instantiate()
		shell.save_path = path
		root.add_child(shell)
		await delay(0.15)
		check(shell.catalog.find(id).adapter == "p01","actual shipped catalog adapter")
		shell.adapter.completed.connect(on_completed)
		shell.show_level_select()
		shell.view.action_requested.emit("level",id)
		await delay(0.15)
		game = shell.adapter.level
	await delay(0.35)
	check(game != null and game.mover.cell == game.content.spawn,"actual authored Spawn")
	game.mover.committed.connect(on_committed)
	check(game.controls.mover == game.mover,"actual GridInput is bound to authoritative mover")

func leave_level() -> void:
	if shell:
		var save: Dictionary = shell.store.load_save()
		check(shell.store.last_error.is_empty(),"isolated save checksum remains valid")
		if case_name == "playthrough":
			check("mutsumi_l04" in save.completed and "mutsumi_l05" in save.unlocked,"formal Shell completion saves progress and unlocks next level")
		shell.show_main_menu()
		root.remove_child(shell)
		shell.free()
		shell = null
	else:
		root.remove_child(game)
		game.free()
	game = null
	await delay(0.05)

func state() -> Dictionary:
	return {"id":game.content.level_id,"cell":[game.mover.cell.x,game.mover.cell.y],"destination":[game.mover.destination.x,game.mover.destination.y],"world":game.mover.world,"graph_world":game.graph.world,"view":game.view.current,"view_busy":game.view.busy,"orientation":game.mover.orientation.key(),"physical_face_direction":str(game.mover.orientation.face_direction()),"phase":game.mover.phase,"moving":game.mover.moving,"moves":game.mover.moves,"goal":game.graph.complete,"link":game.graph.link.active}

func state_key(snapshot: Dictionary) -> String:
	return "p01|%s|cell=%s|world=%s|view=%s|pose=%s|phase=%s" % [snapshot.id,str(snapshot.cell),snapshot.world,snapshot.view,snapshot.orientation,snapshot.phase]

func presenter_state() -> Dictionary:
	var snapshot: Dictionary = game.presenter.debug_snapshot()
	return {"world":snapshot.world,"phase":snapshot.phase,"displayed_worlds":snapshot.displayed_worlds,"shift_progress":snapshot.shift_progress,"shift_committed":snapshot.shift_committed,"actor_position":str(game.presenter.actor.position),"actor_basis":str(game.presenter.actor.basis),"physical_basis":str(game.mover.orientation.as_basis())}

func probe(world: int,keycode: int,duration: float) -> void:
	await tap(KEY_R)
	if world == 1: await tap(KEY_SPACE)
	var before := state()
	check(before.phase == "idle" and not before.view_busy and before.world == world and before.graph_world == world,"probe starts settled in requested world")
	var direction: Vector2i = game.view.world_direction(KEYS.find(keycode))
	var neighbor: Vector2i = game.graph.neighbor(game.mover.cell,direction,game.view)
	var target: Vector2i = game.mover.cell+direction
	var before_display := presenter_state()
	var commits_before := total_commits
	await key(keycode,true)
	var received: bool = game.mover.held.has(keycode) and keycode in game.mover.order
	var started: bool = game.mover.phase == "roll"
	var pressed := state()
	var message: String = game.mover.message
	await delay(duration)
	await key(keycode,false)
	await delay(0.4)
	var after := state()
	var count := total_commits-commits_before
	check(received,"direction InputEvent entered native mover.held/order")
	check(started == (neighbor != Vector2i(before.cell[0],before.cell[1])),"real Runtime starts only native graph-supported moves")
	check((count > 0) == started,"accepted native roll commits; rejected edge does not commit")
	check(game.mover.orientation.valid(),"cube remains a valid physical orientation")
	var classification := "A_INPUT_NOT_DELIVERED" if not received else "B_NATIVE_NEIGHBOR_GUARD_REJECTED" if not started else "C_APPLIED_NO_COMMIT" if count == 0 else "APPLIED_AND_COMMITTED"
	rows.append({"action":OS.get_keycode_string(keycode),"press_seconds":duration,"entry":entry,"before_state_key":state_key(before),"before":before,"world_direction":str(direction),"native_neighbor":str(neighbor),"adjacent_target":str(target),"target_has_native_support":game.graph.can_stand(target,world),"input_entered_runtime":received,"runtime_status_published":null,"observed_runtime_status":"roll" if started else pressed.phase,"classification":classification,"published_rejection_code":null,"observed_guard":"neighbor == current cell" if not started else "native supported neighbor","runtime_message":message,"safety_issue":"NOT_APPLICABLE: p01 path does not call Foundation Safety Queries","face_cube_identity":{"mover_instance_id":game.mover.get_instance_id(),"orientation":before.orientation,"physical_face_direction":before.physical_face_direction},"transition_started":started,"commit_count":count,"pressed":pressed,"before_presenter":before_display,"after_presenter":presenter_state(),"after_state_key":state_key(after),"after":after})
	print("[L04-P1] ",before.id," world=",world," ",OS.get_keycode_string(keycode)," seconds=",duration," input=",received," neighbor=",neighbor," started=",started," commits=",count," after=",after.cell)

func on_committed() -> void:
	total_commits += 1
	commits.append({"event":"native mover.committed","route":route_name,"state":state()})

func on_completed() -> void:
	completions += 1
	check(game.graph.complete and game.mover.phase == "complete" and game.mover.world == 0 and game.mover.cell == game.content.goal,"official completed observes settled Surface Goal")

func key(code: int,pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode=code
	event.physical_keycode=code
	event.pressed=pressed
	event.echo=false
	Input.parse_input_event(event)
	await process_frame

func tap(code: int) -> void:
	await key(code,true)
	await delay(0.05)
	await key(code,false)
	await delay(0.7)

func delay(seconds: float) -> void:
	await create_timer(seconds).timeout

func playthroughs() -> void:
	# Added after the primary diagnostic loop has reproduced the reported defect.
	check(false,"playthrough fixture not implemented before diagnosis")

func finish() -> void:
	var report := {"checks":checks,"failures":failures,"pid":OS.get_process_id(),"engine":Engine.get_version_info(),"display":DisplayServer.get_name(),"graphical":graphical,"case":case_name,"entry":entry,"state_key_kind":"serialization of actual P01 observable fields; NOT Foundation StateKey","runtime_contract":"shipped catalog p01 -> GridInput -> GridMovement.try_held -> ContentState.neighbor","rows":rows,"routes":routes,"native_commits":commits,"formal_completions":completions,"screenshots":shots,"profiles":profiles}
	FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("L04 P1 ",case_name,": ",checks," checks; actions=",rows.size(),"; routes=",routes.size(),"; failures=",failures)
	quit(0 if failures.is_empty() else 1)
