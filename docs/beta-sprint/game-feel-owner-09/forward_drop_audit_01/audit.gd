extends SceneTree
const F=preload("res://experiments/game_feel_01/maps/map_factory.gd")
const G=preload("res://foundation/spatial/surface_geometry.gd")
const R=preload("res://foundation/contracts/contract_records.gd")
const I=preload("res://foundation/runtime/input_mapper.gd")
const V=preload("res://foundation/game_feel/view_contract.gd")
const S=preload("res://foundation/solver/bfs_solver.gd")
const Search=preload("res://foundation/solver/search_records.gd")
const Replay=preload("res://foundation/parity/trace_replayer.gd")
const Safety=preload("res://foundation/validation/safety_queries.gd")
var checks:=0
var failures:Array=[]
func _initialize()->void: call_deferred("run")
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok: failures.append(label)
func run()->void:
	var out:=OS.get_cmdline_user_args()[0]
	var profile:=OS.get_cmdline_user_args()[1]
	check(OS.get_user_data_dir().replace("\\","/").begins_with(profile+"/"),"isolated profile")
	var rows:Array=[]
	for letter in ["a","b"]:
		var baked:Dictionary=F.bake_game_feel(F.read_spec(letter))
		check(baked.ok,"actual schema3 Baker accepted")
		if not baked.ok:
			rows.append({"map":letter,"bake":baked})
			continue
		var level:Dictionary=baked.level
		var state:Dictionary=R.initial_state(level)
		var anchors:Array=G.snapshot(level,state).value.anchors
		var source:Dictionary={}
		var target:Dictionary={}
		var exit_anchor:Dictionary={}
		for a in anchors:
			if a.face_id==&"source/TOP": source=a
			if a.face_id==&"target/TOP": target=a
			if a.face_id==&"exit/TOP": exit_anchor=a
		var y:int=0 if letter=="a" else 8
		check(state.player.location.face==4 and source.position2==Vector3i(0,5,0),"source TOP anchor")
		check(target.position2==Vector3i(-6,y+1,8) and target.frame.normal==Vector3i.UP,"original yellow TOP anchor")
		check(exit_anchor.position2==target.position2+2*target.frame.u and level.goal.face_id==&"exit/TOP","exit U_POS Goal")
		check(level.cubes.size()==4 and level.faces.filter(func(f):return f.cube_id==&"blue_reference" and f.walkable).is_empty(),"four actual cubes and no blue walkable support")
		var c:Dictionary=level.perspective_falls[0]
		check(c.source_face_id==&"source/TOP" and c.source_edge==2 and c.target_face_id==&"target/TOP" and c.orientation_policy==&"PRESERVE","formal connection identities")
		check(c.trajectory.departure_points2[1]-c.trajectory.departure_points2[0]==-2*source.frame.u,"departure parallel to declared U_NEG")
		var inputs:Dictionary={}
		for item in [{"key":"A/LEFT","dir":Vector2.LEFT},{"key":"D/RIGHT","dir":Vector2.RIGHT},{"key":"W/UP","dir":Vector2.UP},{"key":"S/DOWN","dir":Vector2.DOWN}]:
			inputs[item.key]=I.map_move(source.frame,V.basis(1),item.dir)
		check(inputs["A/LEFT"].ok and inputs["A/LEFT"].action.face_axis==2,"EAST A/LEFT maps to U_NEG")
		var landing:Dictionary=state.duplicate(true)
		landing.player.location=R.make_player_location(0,&"target",4)
		var safe:Dictionary=Safety.validate_perspective_motion(level,state,landing,c.connection_id)
		check(safe.status==0 and safe.issues.is_empty(),"actual full curve sweep SAFE")
		var blue:Dictionary=state.duplicate(true)
		blue.player.location=R.make_player_location(0,&"blue_reference",4)
		var blue_safety:Dictionary=Safety.validate_state(level,blue)
		check(blue_safety.status!=0,"actual blue standing support rejected")
		var solved:Dictionary=S.solve(level,state,Search.default_policy(0),Search.default_budget())
		check(solved.status==0 and solved.solution_trace.total_actions==2,"actual Solver Fall then Roll Goal")
		var replay_result:Dictionary={}
		if solved.status==0:
			var trace:Dictionary=solved.solution_trace
			check(trace.steps[0].expected_state.player.location.cube_id==&"target" and trace.steps[0].expected_state.player.orientation==state.player.orientation,"first step lands target with PRESERVE")
			check(trace.steps[1].action.kind==0 and trace.steps[1].action.face_axis==0 and trace.steps[1].expected_state.player.location.cube_id==&"exit","second step ordinary U_POS to exit")
			var replayer=Replay.new()
			root.add_child(replayer)
			replay_result=await replayer.replay(level,trace,{"mode":0})
			check(replay_result.status==0 and replay_result.matched_steps==2,"actual logical Runtime Replay MATCH")
			replayer.free()
		rows.append({"map":letter,"level_hash":level.content_hash,"source_anchor":source,"target_anchor":target,"exit_anchor":exit_anchor,"connection":c,"inputs_EAST":inputs,"curve_safety":safe,"blue_safety":blue_safety,"solver_status":solved.status,"trace":solved.solution_trace,"logical_replay":replay_result})
	FileAccess.open(out.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows,"doubles":[],"pid":OS.get_process_id(),"user_data_dir":OS.get_user_data_dir(),"scope":"read-only headless Map/Geometry/Safety/Solver/logical Runtime replay; graphical NOT_RUN"},"\t"))
	print("READONLY MAP AUDIT ",checks," ",failures)
	quit(0 if failures.is_empty() else 1)
