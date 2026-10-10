extends SceneTree
const Factory = preload("res://experiments/game_feel_01/maps/map_factory.gd")
const Baker = preload("res://foundation/level/level_baker.gd")
const Geometry = preload("res://foundation/spatial/surface_geometry.gd")
const Records = preload("res://foundation/contracts/contract_records.gd")
const Solver = preload("res://foundation/solver/bfs_solver.gd")
const Search = preload("res://foundation/solver/search_records.gd")
const Replay = preload("res://foundation/parity/trace_replayer.gd")
var checks := 0
var failures: Array = []
var rows: Array = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures.append(label)

func run() -> void:
	var output := ""
	var profile := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): output=arg.trim_prefix("--evidence=")
		if arg.begins_with("--profile="): profile=arg.trim_prefix("--profile=")
	if output.is_empty() or profile.is_empty():
		quit(2)
		return
	check(OS.get_user_data_dir().replace("\\","/").begins_with(profile.replace("\\","/")+"/"),"isolated profile")
	for letter in ["a","b"]:
		var spec: Dictionary = Factory.read_spec(letter)
		var authored: Dictionary = Factory.authoring(spec)
		check(authored.goal.face_id==&"exit/TOP",letter+" Goal must require roll after landing")
		if authored.goal.face_id!=&"exit/TOP": continue
		var full: Dictionary = Factory.bake(spec)
		check(full.ok,"complete map Baker")
		var original: Dictionary = Solver.solve(full.level,Records.initial_state(full.level),Search.default_policy(0),Search.default_budget())
		check(original.status==1,"source has no non-Fall shortcut")
		# Separate authored spawn fixture: never mutate Runtime state or fake a Fall.
		authored.level_id=StringName(String(authored.level_id)+"_landing_roll_control")
		authored.spawn=Records.make_player_state(Records.make_player_location(0,&"target",4),0)
		var baked: Dictionary = Baker.bake(authored,{"max_configurations":4096,"max_checks":100000})
		check(baked.ok,"landing-spawn control real Baker")
		var snapshot: Dictionary = Geometry.snapshot(baked.level,Records.initial_state(baked.level))
		var target: Dictionary = {}
		var exit_anchor: Dictionary = {}
		for anchor in snapshot.value.anchors:
			if anchor.face_id==&"target/TOP": target=anchor
			if anchor.face_id==&"exit/TOP": exit_anchor=anchor
		check(exit_anchor.position2==target.position2+2*target.frame.u and exit_anchor.frame.normal==target.frame.normal,"formal TOP U_POS adjacency")
		var solved: Dictionary = Solver.solve(baked.level,Records.initial_state(baked.level),Search.default_policy(0),Search.default_budget())
		check(solved.status==0 and solved.solution_trace.total_actions==1,"one ordinary roll reaches Goal")
		if solved.status!=0: continue
		var action: Dictionary = solved.solution_trace.steps[0].action
		check(action.kind==0 and action.face_axis==0,"formal MOVE U_POS")
		var replayer=Replay.new()
		root.add_child(replayer)
		var replay: Dictionary = await replayer.replay(baked.level,solved.solution_trace,{"mode":0})
		check(replay.status==0 and replay.matched_steps==1,"real Runtime Replay landing Roll MATCH")
		replayer.free()
		rows.append({"map":letter,"full_map_hash":full.level.content_hash,"full_solver_status":original.status,"fixture_kind":"AUTHORED_LANDING_SPAWN_CONTROL_NOT_FALL","target_anchor":target,"exit_anchor":exit_anchor,"trace":solved.solution_trace,"replay":replay})
	var report: Dictionary = {"checks":checks,"failures":failures,"rows":rows,"doubles":[],"input":"direct Solver and actual Runtime Replay; landing is an authored spawn, not Fall acceptance","user_data_dir":OS.get_user_data_dir(),"pid":OS.get_process_id(),"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"fall_status":"case_pending","fall_checks":0}
	FileAccess.open(output.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("EXIT checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
