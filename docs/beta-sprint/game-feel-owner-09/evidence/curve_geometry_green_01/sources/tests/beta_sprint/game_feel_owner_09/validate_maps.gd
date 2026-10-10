extends SceneTree
const Factory = preload("res://experiments/game_feel_01/maps/map_factory.gd")
const Session = preload("res://foundation/runtime/runtime_session.gd")
const Safety = preload("res://foundation/validation/safety_queries.gd")
const Key = preload("res://foundation/contracts/state_key.gd")
const Codec = preload("res://foundation/level/level_codec.gd")
const Records = preload("res://foundation/contracts/contract_records.gd")
const Solver = preload("res://foundation/solver/bfs_solver.gd")
const Search = preload("res://foundation/solver/search_records.gd")
const Replay = preload("res://foundation/parity/trace_replayer.gd")
var checks := 0
var failures: Array = []
var rows: Array = []
var output := ""
var profile := ""

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		print("BEHAVIORAL_FAIL: ",label)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): output = arg.trim_prefix("--evidence=")
		if arg.begins_with("--profile="): profile = arg.trim_prefix("--profile=")
	if output.is_empty() or profile.is_empty():
		quit(2)
		return
	check(OS.get_user_data_dir().replace("\\","/").begins_with(profile.replace("\\","/")+"/"),"isolated user data directory")
	for letter in ["a","b"]:
		var spec: Dictionary = Factory.read_spec(letter)
		# Author-data type/shape checks only, not formal v2 acceptance or Safety.
		var candidate: Dictionary = Factory.opt_in_authoring_candidate(spec)
		var fall: Dictionary = candidate.perspective_falls[0]
		check(candidate.schema_version==3 and candidate.contract_version=="foundation.game_feel.v2" and candidate.rule_version=="foundation.rules.game_feel.v2" and candidate.goal.face_id==&"exit/TOP" and candidate.cubes.size()==4,"schema3 and four-platform route")
		var trajectory: Dictionary = fall.get("trajectory",{})
		var departure: Array = trajectory.get("departure_points2",[])
		var controls: Array = trajectory.get("descent_control_points2",[])
		check(departure.size()==2 and controls.size()==4 and departure[0]==Factory.vector(spec.source_center2)+Vector3i(0,2,0) and controls[3]==Factory.vector(spec.target_center2)+Vector3i(0,2,0),"curve canonical endpoints and cardinalities")
		check(trajectory.get("trajectory_version")=="pfall.departure_cubic.v1" and not fall.has("path_points2") and typeof(fall.source_edge)==TYPE_INT and fall.source_face_id==&"source/TOP" and fall.target_face_id==&"target/TOP","explicit curve version with no polyline fallback")
		check(departure.size()==2 and controls.size()==4 and typeof(controls[0])==TYPE_VECTOR3I and controls[0]==departure[1] and controls[1]-controls[0]==departure[1]-departure[0],"authored exact join and C1 control relation; not motion Safety")
		check(Factory.authoring(spec).schema_version==1 and not Factory.authoring(spec).has("perspective_falls"),"baseline never auto-activates candidate")
		var opt_in_bake: Dictionary = Factory.bake_game_feel(spec)
		check(not opt_in_bake.ok and not opt_in_bake.issues.is_empty(),"baseline Baker honestly rejects undelivered v2; reclassify this case after 01 merge")
		var delta: int = spec.target_center2[1]-spec.source_center2[1]
		check(delta==(-4 if letter=="a" else 4),letter+" real height sign and magnitude")
		var connection: Dictionary = spec.connection
		check(int(connection.source.layer)==0 and connection.source.cube_id=="source" and connection.source.face=="TOP" and int(connection.target.layer)==0 and connection.target.cube_id=="target" and connection.target.face=="TOP","explicit same-world anchors")
		check(connection.allowed_camera_quadrants.size()==1 and int(connection.allowed_camera_quadrants[0])==1 and connection.activation=="EXPLICIT_PLAYER_ACTION" and connection.orientation_policy=="PRESERVE","candidate camera/input/orientation intent")
		check(connection.authorizes_traversal==false and connection.safety_status=="UNPROVEN" and not connection.has("authorized_path_points2"),"map cannot authorize motion")
		var baked: Dictionary = Factory.bake(spec)
		check(baked.ok,letter+" real Baker valid")
		if not baked.ok:
			rows.append({"map":letter,"bake":baked})
			continue
		var level: Dictionary = baked.level
		var encoded: Dictionary = Codec.encode(level)
		check(encoded.ok,"formal Codec encode")
		FileAccess.open(output.path_join("map_"+letter+"_baked.json"),FileAccess.WRITE).store_string(encoded.text)
		var session = Session.new()
		check(session.load_level(level).ok,"real Runtime load")
		var before: String = Key.build(level,session.state).key
		var move: Dictionary = session.request_action({"kind":0,"face_axis":2})
		check(move.status==1 and move.rejection_code==2000 and Key.build(level,session.state).key==before,"existing MOVE cannot authorize fall")
		var shift: Dictionary = session.request_action({"kind":1})
		check(shift.status==1 and shift.rejection_code==1400,"no accidental world mapping")
		var landing: Dictionary = session.state.duplicate(true)
		landing.player.location = Records.make_player_location(0,&"target",4)
		var safe: Dictionary = Safety.validate_state(level,landing)
		check(safe.status==0,"real static landing support SAFE")
		landing.player.location.face=0
		var unsafe_result: Dictionary = Safety.validate_state(level,landing)
		check(unsafe_result.status!=0,"real nonwalkable landing unsafe")
		var solve: Dictionary = Solver.solve(level,session.state,Search.default_policy(0),Search.default_budget())
		check(solve.status==1 and solve.solution_trace==null,"baseline Solver genuinely unreachable")
		session.reset()
		check(Key.build(level,session.state).key==before and session.state.player.orientation==0,"Reset canonical spawn")
		rows.append({"map":letter,"level_hash":level.content_hash,"move":move,"shift":shift,"static_landing":safe,"invalid_landing":unsafe_result,"solver_status":solve.status,"solver_metrics":solve.metrics,"before_StateKey":before,"after_StateKey":Key.build(level,session.state).key})
	var control: Dictionary = Factory.read_spec("a")
	control.id="owner09_adjacent_control"
	control.erase("exit_center2") # Preserve the original two-cube ordinary-move control.
	control.erase("blue_reference_center2")
	control.target_center2=[2,4,0]
	var baked: Dictionary = Factory.bake(control)
	check(baked.ok,"ordinary adjacent control bake")
	var solved: Dictionary = Solver.solve(baked.level,Records.initial_state(baked.level),Search.default_policy(0),Search.default_budget())
	check(solved.status==0,"ordinary control Solver")
	var replayer=Replay.new()
	root.add_child(replayer)
	var replay: Dictionary = await replayer.replay(baked.level,solved.solution_trace,{"mode":0})
	check(replay.status==0 and replay.matched_steps==1,"ordinary actual Replay MATCH")
	replayer.free()
	var pending: Array = []
	for id in ["fall_a","fall_b","fall_camera_gate","fall_wrong_world","fall_path_safety","fall_orientation_24","fall_reset_inflight","fall_solver","fall_replay","fall_graphical","fall_no_softlock"]:
		pending.append({"case_id":id,"status":"case_pending","checks":0,"dependency":"01 versioned Fall delivery + 00 host where applicable","delivery_sha":null})
	var report: Dictionary = {"checks":checks,"failures":failures,"rows":rows,"ordinary_replay":replay,"pending":pending,"doubles":[],"authority":"real baseline Baker/Runtime/Safety/Solver/Replay; map metadata grants no permission","input":"direct formal API; no graphical/native input claim","pid":OS.get_process_id(),"user_data_dir":OS.get_user_data_dir(),"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method()}
	FileAccess.open(output.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("OWNER09 checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
