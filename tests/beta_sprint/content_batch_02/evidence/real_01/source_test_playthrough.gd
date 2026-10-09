extends SceneTree
## Full native input routes. No graph/mover/world/view/pose writes or test doubles.
const ROOT = "res://game/levels/mutsumi/batch_02/"
const NAMES = ["l04_borrowed_path", "l05_gate_home"]
const IDS = ["mutsumi_l04", "mutsumi_l05"]
const Shell = preload("res://game/shell/game_shell.gd")
const Save = preload("res://game/shell/save_store.gd")
var shell
var game
var evidence := ""
var graphical := false
var checks := 0
var failures: Array[String] = []
var completion_events := 0
var completion_observations: Array = []
var trace: Array = []
var routes: Array = []
var shots: Array = []
var profiles: Array = []
var route_name := "setup"
var protected_save: Dictionary = {}
var source_hashes: Dictionary = {}

func _initialize() -> void:
	call_deferred("run")

func check(value: bool,label: String) -> void:
	checks += 1
	if not value:
		failures.append(label)
		printerr("FAIL: ",label)

func file_hash(path: String) -> String:
	return FileAccess.get_file_as_bytes(path).hex_encode().sha256_text() if FileAccess.file_exists(path) else "ABSENT"

func source_snapshot() -> Dictionary:
	var result: Dictionary = {}
	for path in [
		"game/levels/mutsumi/batch_01/content_level.gd", "game/levels/mutsumi/batch_01/content_state.gd",
		"game/levels/mutsumi/batch_01/content_level_data.gd", "game/levels/mutsumi/batch_01/content_hints.gd",
		"game/levels/mutsumi/batch_01/l01_3d/l01_presented.gd", "game/levels/mutsumi/batch_01/l01_3d/presenter.gd",
		"game/levels/mutsumi/batch_01/levels_3d/presenter.gd", "game/levels/mutsumi/batch_01/level_order.json",
		"prototype/perspective/grid_movement.gd", "prototype/perspective/perspective_controller.gd",
		"prototype/perspective/perspective_link.gd", "game/player/grid_input.gd",
		"game/shell/game_shell.gd", "game/shell/level_adapter.gd", "game/shell/save_store.gd",
		"game/levels/mutsumi/batch_02/batch_02_level.gd", "game/levels/mutsumi/batch_02/batch_02_hints.gd",
		"game/levels/mutsumi/batch_02/l04_borrowed_path.tres", "game/levels/mutsumi/batch_02/l05_gate_home.tres",
		"game/levels/mutsumi/batch_02/l04_borrowed_path.tscn", "game/levels/mutsumi/batch_02/l05_gate_home.tscn"]:
		# Actual byte SHA256, independent of text encoding.
		var bytes := FileAccess.get_file_as_bytes("res://"+path)
		var context := HashingContext.new()
		context.start(HashingContext.HASH_SHA256)
		context.update(bytes)
		result[path] = context.finish().hex_encode()
	return result

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="): evidence = arg.trim_prefix("--evidence-dir=")
		elif arg == "--graphical": graphical = true
	if evidence.is_empty():
		quit(2)
		return
	check((DisplayServer.get_name() != "headless") == graphical,"explicit headless/graphical execution mode")
	for path in [Save.DEFAULT_PATH,Save.DEFAULT_PATH+".bak"]: protected_save[path] = file_hash(path)
	source_hashes = source_snapshot()
	for index in 2:
		shell = Shell.new()
		shell.catalog_entries = [{"id":IDS[index],"title":NAMES[index],"scene":ROOT+NAMES[index]+".tscn","adapter":"p01"}]
		shell.save_path = "user://beta_sprint/content_batch_02/%s_%s/progress.json" % [OS.get_process_id(),IDS[index]]
		check(not FileAccess.file_exists(shell.save_path),"fresh isolated profile; no existing save overwritten")
		root.add_child(shell)
		await delay(0.12)
		shell.adapter.completed.connect(on_completed)
		shell.new_game()
		await delay(0.3)
		game = shell.adapter.level
		if game == null:
			check(false,"native scene startup")
			finish()
			return
		game.mover.committed.connect(on_committed)
		check(game.content.level_id == IDS[index] and game.mover.cell == game.content.spawn,"native configured stable ID and Spawn")
		check(game.presenter is Node3D and game.using_3d and not game.board.visible,"existing real 3D attachment constructed")
		check(game.approved_hud.title_label.text == game.content.display_title,"new level title uses approved HUD")
		check(game.hints.objective(game.mover,game.view) == game.content.intent,"own start intent, no old level instructions")
		await reset_probes(index)
		await view_orbit()
		await shot("spawn")
		for mode in ["normal","reset_replay","alternate_views"]:
			route_name = IDS[index]+"_"+mode
			await tap(KEY_R)
			check_reset()
			var events_before := completion_events
			if mode == "alternate_views": await tap(KEY_Q,4)
			if index == 0: await route_l04(mode)
			else: await route_l05(mode)
			await delay(0.12)
			check(game.graph.complete and game.mover.cell == game.content.goal and game.mover.phase == "complete" and game.mover.world == 0,"natural input committed Goal "+route_name)
			check(shell.state == shell.State.LEVEL_COMPLETE and completion_events == events_before+1,"official adapter.completed exactly once for committed Goal")
			check(game.mover.order.is_empty(),"Goal clears held input")
			await shot("goal")
			routes.append({"id":IDS[index],"mode":mode,"complete":game.graph.complete,"moves":game.mover.moves,"world":game.mover.world,"view":game.view.current,"cell":str(game.mover.cell),"adapter_completion_events":completion_events-events_before,"kind":"natural_InputEvent_route"})
			await tap(KEY_R)
			check_reset()
			check(shell.state == shell.State.PLAYING and not shell.adapter.reported,"R after Goal uses native Shell Reset and rearms real completion observer")
		var restored: Dictionary = shell.store.load_save()
		check(restored.has_progress and restored.recent == IDS[index] and IDS[index] in restored.completed and shell.store.last_error.is_empty(),"isolated progress saved and reloaded without data corruption")
		profiles.append({"id":IDS[index],"path":shell.save_path,"absolute":ProjectSettings.globalize_path(shell.save_path),"progress":restored,"checksum_valid":shell.store.last_error.is_empty()})
		DirAccess.copy_absolute(shell.save_path,evidence.path_join(IDS[index]+"_test_progress.json"))
		shell.show_main_menu()
		root.remove_child(shell)
		shell.free()
		await delay(0.15)
	check(completion_events == 6,"six routes produce six formal Goal completion events")
	for path in protected_save: check(file_hash(path) == protected_save[path],"default user save/backup unchanged: "+path)
	check(source_snapshot() == source_hashes,"content and all consumed frozen source bytes unchanged during Real")
	finish()

func native_snapshot() -> Dictionary:
	return {"id":game.content.level_id,"cell":[game.mover.cell.x,game.mover.cell.y],"world":game.mover.world,"view":game.view.current,"orientation":game.mover.orientation.key(),"moves":game.mover.moves,"phase":game.mover.phase,"link":game.graph.link.active,"plate":game.graph.plate_pressed,"gate":game.graph.door_open,"goal":game.graph.complete}

func on_committed() -> void:
	trace.append({"event":"native_mover.committed","route":route_name,"state":native_snapshot()})

func on_completed() -> void:
	completion_events += 1
	var level = shell.adapter.level
	completion_observations.append({"id":level.content.level_id,"goal":level.graph.complete,"phase":level.mover.phase,"world":level.mover.world,"cell":str(level.mover.cell)})
	check(level.graph.complete and level.mover.phase == "complete" and level.mover.cell == level.content.goal,"formal completion callback sees actual settled Goal")

func route_l04(mode: String) -> void:
	await move(Vector2i.UP)
	var pose = game.mover.orientation.key()
	await tap(KEY_SPACE)
	check(game.mover.world == 0 and game.feedback.visible and game.mover.orientation.key() == pose,"L04 unsafe Shift visibly blocked")
	await move(Vector2i.LEFT)
	await move(Vector2i.UP)
	check(game.mover.cell == Vector2i(0,4),"L04 bridge unavailable in Surface")
	await tap(KEY_SPACE)
	check(game.mover.world == 1,"L04 first real Shift")
	await move(Vector2i.UP,2)
	await move(Vector2i.RIGHT,3)
	await move(Vector2i.RIGHT)
	check(game.mover.cell == Vector2i(3,2) and not game.graph.link.active,"L04 logical gap blocks before alignment")
	if mode == "alternate_views": await tap(KEY_Q,3)
	else: await tap(KEY_E)
	check(game.graph.link.active and game.view.current == 1,"L04 Inner EAST combination activates link")
	check("连接已成立" in game.hints.objective(game.mover,game.view),"L04 local prompt matches actual Inner link")
	await tap(KEY_SPACE)
	await move(Vector2i.RIGHT)
	check(game.mover.cell == Vector2i(3,2) and not game.graph.link.active,"L04 Surface EAST cannot bypass world condition")
	check("里世界" in game.approved_hud.objective_label.text,"wrong-world hint correctly names Inner, not stale Surface")
	await tap(KEY_SPACE)
	await crossing(Vector2i(3,2),Vector2i(9,2))
	if mode == "alternate_views":
		await tap(KEY_E)
		check(not game.graph.link.active and game.graph.can_stand(game.mover.cell,1),"L04 disconnect preserves real destination support")
	await move(Vector2i.RIGHT)
	await move(Vector2i.RIGHT)
	check(game.mover.cell == Vector2i(10,2),"L04 Inner cannot use Surface exit branch")
	await tap(KEY_SPACE)
	await move(Vector2i.RIGHT)
	await move(Vector2i.UP)

func route_l05(mode: String) -> void:
	await move(Vector2i.UP)
	await move(Vector2i.LEFT,2)
	await move(Vector2i.UP)
	check(game.mover.cell == Vector2i(0,3),"L05 Surface cannot cross first bridge")
	await tap(KEY_SPACE)
	await move(Vector2i.UP,2)
	await move(Vector2i.RIGHT)
	await move(Vector2i.RIGHT)
	check(game.mover.cell == Vector2i(1,1),"L05 Inner cannot bypass Surface corridor")
	await tap(KEY_SPACE)
	await move(Vector2i.RIGHT,2)
	await move(Vector2i.UP)
	if mode == "alternate_views": await tap(KEY_Q,3)
	else: await tap(KEY_E)
	await move(Vector2i.RIGHT)
	check(game.mover.cell == Vector2i(3,0) and not game.graph.link.active,"L05 Surface EAST cannot use Inner connection")
	await tap(KEY_SPACE)
	check(game.graph.link.active,"L05 Inner EAST activates actual link")
	await crossing(Vector2i(3,0),Vector2i(9,0))
	if mode == "alternate_views": await tap(KEY_E)
	await move(Vector2i.RIGHT,2)
	await move(Vector2i.RIGHT)
	check(game.mover.cell == game.graph.PLATE and not game.graph.plate_pressed and not game.graph.door_open,"L05 Inner plate cannot bypass Gate")
	await tap(KEY_SPACE)
	check(game.graph.plate_pressed and game.graph.door_open,"L05 Surface occupancy opens real Gate")
	check(game.presenter.debug_snapshot().gate_state == "open","existing 3D Gate observes real open state")
	await shot("plate_open")
	var code := direction_key(Vector2i.RIGHT)
	await key(code,true)
	await key(code,false)
	await delay(0.1)
	check(game.mover.cell == game.graph.PLATE and game.graph.door_open and game.mover.moving,"Gate stays open during authorized native roll")
	await delay(0.35)
	check(game.mover.cell == game.graph.BEYOND_GATE and not game.graph.door_open,"Gate closes only after formal landing")
	await move(Vector2i.RIGHT)

func crossing(start: Vector2i,target: Vector2i) -> void:
	await shot("link_active")
	var code := direction_key(Vector2i.RIGHT)
	await key(code,true)
	await key(code,false)
	await delay(0.1)
	check(game.mover.crossing and game.mover.cell == start,"native connection is a timed cube roll, no teleport")
	await key(KEY_Q,true)
	await key(KEY_Q,false)
	check(not game.view.busy,"native crossing rejects camera mutation")
	await delay(0.35)
	check(game.mover.cell == target,"native committed connection arrival")
	await shot("link_arrival")

func reset_probes(index: int) -> void:
	for code in [KEY_W,KEY_SPACE,KEY_E]:
		await key(code,true)
		await key(code,false)
		await delay(0.08)
		check(game.mover.phase != "idle" or game.view.busy,"real transition started before R")
		await tap(KEY_R)
		check_reset()
	await key(KEY_W,true)
	await delay(0.1)
	await tap(KEY_R)
	await key(KEY_W,false)
	check_reset()
	check(game.mover.order.is_empty(),"R clears actual held input")
	# Demonstrate actual D/A and W/S reverse rolls without selecting state directly.
	await move(Vector2i.UP)
	await move(Vector2i.DOWN)
	check(game.mover.cell == game.content.spawn and game.mover.moves == 2,"natural forward/reverse rolls")
	await tap(KEY_R)
	check_reset()

func check_reset() -> void:
	check(game.mover.cell == game.content.spawn and game.mover.destination == game.content.spawn and game.mover.world == 0 and game.view.current == 0 and game.mover.phase == "idle" and game.mover.moves == 0 and not game.graph.complete and not game.graph.door_open and not game.view.busy and game.mover.order.is_empty(),"R restores original Spawn/world/view/input/Goal")
	check(game.hints.text == "W A S D" and game.hints.objective(game.mover,game.view) == game.content.intent,"R restores own tutorial and intent")

func view_orbit() -> void:
	var pose = game.mover.orientation.key()
	for code in [KEY_E,KEY_Q]:
		for i in 4:
			var before: int = game.view.current
			await tap(code)
			check(game.view.current == posmod(before+(1 if code == KEY_E else -1),4) and is_equal_approx(game.view.displayed_angle(),game.view.current*PI/2),"exact adjacent 90deg view snap")
			check(game.mover.orientation.key() == pose,"view orbit preserves physical pose")
			trace.append({"event":"settled_view","route":route_name,"state":native_snapshot()})

func direction_key(direction: Vector2i) -> int:
	var dirs = [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]
	return [KEY_W,KEY_D,KEY_S,KEY_A][posmod(dirs.find(direction)-game.view.current,4)]

func move(direction: Vector2i,count: int=1) -> void:
	await tap(direction_key(direction),count)

func key(code: int,pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	await process_frame

func tap(code: int,count: int=1) -> void:
	for i in count:
		await key(code,true)
		await key(code,false)
		await delay(0.45)

func delay(seconds: float) -> void:
	await create_timer(seconds).timeout

func shot(label: String) -> void:
	if not graphical: return
	await RenderingServer.frame_post_draw
	var name := "%03d_%s_%s.png" % [shots.size(),route_name,label]
	root.get_texture().get_image().save_png(evidence.path_join(name))
	shots.append({"file":name,"state":native_snapshot()})

func finish() -> void:
	var report = {"checks":checks,"failures":failures,"pid":OS.get_process_id(),"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"engine":Engine.get_version_info(),"graphical":graphical,"routes":routes,"completion_events":completion_events,"completion_observations":completion_observations,"trace":trace,"source_hashes":source_hashes,"profiles":profiles,"protected_default_save_hashes":protected_save,"screenshots":shots,"scope":{"runtime":"existing ContentLevel/ContentState/GridMovement/PerspectiveController","input":"real Input.parse_input_event -> native GridInput; no forced gameplay state","profile":"unique PID-isolated native SaveStore only, no save migration","graphical":"PASS only when explicitly --graphical and non-headless","Foundation":"NOT_RUN / unchanged"}}
	FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("BATCH02 REAL: ",checks," checks; routes=",routes.size(),"; completion_events=",completion_events,"; graphical=",graphical,"; failures=",failures)
	quit(0 if failures.is_empty() else 1)
