extends SceneTree
## Exact latest Owner09 public entry; all positive edges use formal production APIs.
const Maps = preload("res://experiments/game_feel_01/maps/map_factory.gd")
const Baker = preload("res://foundation/level/level_baker.gd")
const Codec = preload("res://foundation/level/level_codec.gd")
const Records = preload("res://foundation/contracts/contract_records.gd")
const Key = preload("res://foundation/contracts/state_key.gd")
const Facade = preload("res://foundation/game_feel/runtime_facade.gd")
const Kernel = preload("res://foundation/rules/puzzle_rule_kernel.gd")
const Rules = preload("res://foundation/rules/rule_records.gd")
const Goal = preload("res://foundation/rules/goal_evaluator.gd")
const Safety = preload("res://foundation/validation/safety_queries.gd")
const Search = preload("res://foundation/solver/search_records.gd")
const Explorer = preload("res://foundation/solver/state_explorer.gd")
const Graph = preload("res://foundation/solver/state_graph.gd")
const Trace = preload("res://foundation/solver/solution_trace.gd")
const Softlock = preload("res://foundation/quality/softlock/softlock_analyzer.gd")
const Replayer = preload("res://foundation/parity/trace_replayer.gd")
const V1_HASHES = {"a":"8c2c341aeca6aae2137b95da95752fd43ef95ffbb40623fc8f77e3cd992997f4", "b":"a02ae685981ce0d9735111886dc23738485184f6872804140cdf4cada3b168a1"}
var checks := 0
var failures: Array[String] = []
var routes: Array = []
var evidence := ""
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		print("BEHAVIORAL_FAIL: ",label)
func save(name: String, value: Variant) -> void:
	FileAccess.open(evidence.path_join(name),FileAccess.WRITE).store_string(JSON.stringify(value,"\t"))
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): evidence=arg.trim_prefix("--evidence=")
	call_deferred("run")
func evaluate(level: Dictionary, state: Dictionary, action: Dictionary) -> Dictionary:
	return Kernel.evaluate_action(level,state,action,Rules.idle_context())
func run() -> void:
	for letter in ["a","b"]:
		var data := Maps.read_spec(letter)
		var original := data.duplicate(true)
		var legacy := Maps.bake(data)
		check(legacy.ok,letter+" v1 public bake remains valid")
		if legacy.ok:
			check(legacy.level.content_hash==V1_HASHES[letter],letter+" v1 canonical hash matches 82a8 historical evidence")
			check(legacy.level.schema_version==1 and not legacy.level.has("perspective_falls") and not legacy.level.has("camera_initial_quadrant"),letter+" v1 has no opt-in state")
			var legacy_state := Records.initial_state(legacy.level)
			check(Key.build(legacy.level,legacy_state).key.begins_with("statekey.v1:"),letter+" v1 StateKey tag preserved")
			check(evaluate(legacy.level,legacy_state,{"kind":0,"face_axis":2}).status==1,letter+" v1 ordinary road absence cannot grant Fall")
		var baked := Maps.bake_game_feel(data)
		check(baked.ok,letter+" exact v2 public Baker admits current candidate")
		check(data==original,letter+" public Baker does not mutate map data")
		if not baked.ok:
			routes.append({"map":letter,"baker":baked})
			continue
		var level: Dictionary=baked.level
		check(level.schema_version==2 and level.camera_initial_quadrant==1 and level.perspective_falls[0].presentation_duration_ms==600,letter+" exact Owner09 opt-in ABI/profile consumed")
		var wire:=Codec.encode(level)
		check(wire.ok and Codec.decode(wire.text).level==level,letter+" canonical v2 Codec roundtrip exact")
		FileAccess.open(evidence.path_join("map_"+letter+".level.json"),FileAccess.WRITE).store_string(wire.text)
		var runtime:=Facade.new()
		var events: Array=[]
		runtime.game_feel_event.connect(func(event):events.append(event))
		check(runtime.load_level(level).ok,letter+" real default Facade loads canonical current candidate")
		var initial:=runtime.get_state()
		var initial_key: String=Key.build(level,initial).key
		check(not Goal.is_goal(level,initial).is_goal,letter+" spawn is not Goal")
		var fall:=runtime.request_action({"kind":0,"face_axis":2})
		check(fall.status==0 and fall.changed and events[-1].semantic=="PERSPECTIVE_FALL_APPLIED",letter+" normal mapped MOVE authoritatively resolves Fall")
		if fall.status!=0 or not fall.changed: continue
		check(runtime.get_state()==initial and runtime.get_commit_count()==0,letter+" proposal leaves committed source unchanged")
		var fall_safe:=Safety.validate_perspective_motion(level,initial,fall.next_state,StringName("pfall_"+letter))
		check(fall_safe.status==0 and fall_safe.issues.is_empty(),letter+" exact source-clearance and full Fall sweep SAFE")
		check(not runtime.finish_transition(events[-1].transition_identity).ignored,letter+" logical native completion accepted")
		var landing:=runtime.get_state()
		check(landing.player.location.cube_id==&"target" and landing.player.location.face==4 and not Goal.is_goal(level,landing).is_goal,letter+" exact target/TOP landing is not premature Goal")
		check(landing.player.orientation==initial.player.orientation and landing.player.location.layer==initial.player.location.layer,letter+" Fall preserves authoritative orientation and World")
		var roll:=runtime.request_action({"kind":0,"face_axis":0})
		check(roll.status==0 and roll.changed and events[-1].semantic=="MOVE_APPLIED_NORMAL",letter+" target/TOP U_POS is formal ordinary Roll")
		check(Safety.validate_motion(level,landing,roll.next_state,roll.action).status==0,letter+" post-landing ordinary Roll sweep SAFE")
		check(not runtime.finish_transition(events[-1].transition_identity).ignored,letter+" exit Roll logical native completion accepted")
		var final:=runtime.get_state()
		var final_key: String=Key.build(level,final).key
		check(final.player.location.cube_id==&"exit" and final.player.location.face==4 and Goal.is_goal(level,final).is_goal and runtime.get_commit_count()==2,letter+" Fall then Roll reaches exact exit/TOP Goal")
		runtime.reset()
		check(Key.build(level,runtime.get_state()).key==initial_key and runtime.get_commit_count()==0,letter+" Reset restores exact initial StateKey")
		var solved:=Explorer.explore(level,initial,Search.default_policy(1),Search.default_budget())
		check(solved.status==0 and solved.graph!=null and solved.graph.complete and solved.solution_trace!=null,letter+" real unfiltered Explorer returns complete graph and solution")
		if solved.graph==null or solved.solution_trace==null: continue
		var graph: Dictionary=solved.graph
		check(Graph.validate(level,graph).ok and graph.level_hash==level.content_hash,letter+" live graph validates against this exact v2 level")
		var fall_edges: Array=[]
		var exit_edges: Array=[]
		var quadrants: Dictionary={}
		for node in graph.nodes.values(): quadrants[node.state.camera_quadrant]=true
		for edge in graph.edges:
			if edge.action.kind==8:
				fall_edges.append(edge)
				var source_state: Dictionary=graph.nodes[edge.from_key].state
				var target_state: Dictionary=graph.nodes[edge.to_key].state
				check(source_state.player.location.cube_id==&"source" and target_state.player.location.cube_id==&"target" and source_state.camera_quadrant==1 and target_state.player.location.layer==source_state.player.location.layer,letter+" live formal Fall edge source/target/camera/World")
				check(Safety.validate_motion(level,source_state,target_state,edge.action).status==0,letter+" live explicit Fall edge full sweep SAFE")
			if edge.action=={"kind":0,"face_axis":0} and graph.nodes[edge.from_key].state.player.location.cube_id==&"target" and graph.nodes[edge.to_key].state.player.location.cube_id==&"exit": exit_edges.append(edge)
		check(not fall_edges.is_empty() and not exit_edges.is_empty(),letter+" actual same graph contains formal Fall and target-to-exit Roll edges")
		check(quadrants.size()==4,letter+" complete graph includes all four authoritative views")
		check(solved.solution_trace.total_actions==2 and solved.solution_trace.steps[0].expected_state.player.location.cube_id==&"target" and solved.solution_trace.steps[1].action=={"kind":0,"face_axis":0} and solved.solution_trace.goal_statekey==final_key,letter+" shortest actual trace is Fall then U_POS Roll to matching Goal StateKey")
		check(Trace.validate_semantics(level,solved.solution_trace).ok,letter+" formal Kernel re-executes every complete trace step")
		var graph_before:=graph.duplicate(true)
		var softlock:=Softlock.analyze(level,graph,{"max_nodes":10000,"max_edges":100000,"max_runtime_ms":0})
		check(softlock.status==0 and softlock.softlock_count==0 and initial_key in softlock.goal_reachable_states and softlock.metrics.edges_checked==graph.edges.size(),letter+" full path SAFE uses this complete Fall-bearing graph; zero softlocks")
		check(graph==graph_before,letter+" reverse Safety analysis does not mutate actual graph")
		var replayer:=Replayer.new()
		root.add_child(replayer)
		var replay: Dictionary=await replayer.replay(level,solved.solution_trace,{"mode":0})
		check(replay.status==0 and replay.matched_steps==2 and replay.actual_statekey==final_key,letter+" real LOGICAL_SESSION Replay reaches matching full-path endpoint")
		var graphical: Dictionary=await replayer.replay(level,solved.solution_trace,{"mode":1})
		check(graphical.status==2 and graphical.matched_steps==0 and not graphical.issues.is_empty() and graphical.issues[0].message.begins_with("CASE_DEPENDENCY_PENDING:"),letter+" Graphical TraceReplayer dependency fails closed and is not counted as graphical PASS")
		replayer.free()
		for camera in [0,2,3]:
			var wrong:=initial.duplicate(true)
			wrong.camera_quadrant=camera
			var denied:=evaluate(level,wrong,{"kind":8,"connection_id":StringName("pfall_"+letter)})
			check(denied.status==1 and not denied.changed and denied.next_state==null,letter+" unauthorized camera "+str(camera)+" cannot grant Fall")
		for orientation in 24:
			var pose:=initial.duplicate(true)
			pose.player.orientation=orientation
			var preserved:=evaluate(level,pose,{"kind":8,"connection_id":StringName("pfall_"+letter)})
			check(preserved.status==0 and preserved.next_state.player.orientation==orientation,letter+" exact candidate preserves cube24 orientation "+str(orientation))
		# Negative authoring controls are canonicalized by the same real Baker.
		var absent:=Maps.opt_in_authoring_candidate(data)
		absent.perspective_falls=[]
		var absent_bake:=Baker.bake(absent,{"max_configurations":4096,"max_checks":100000})
		check(absent_bake.ok,letter+" valid no-connection control uses real Baker")
		if absent_bake.ok:
			var denied:=evaluate(absent_bake.level,Records.initial_state(absent_bake.level),{"kind":0,"face_axis":2})
			check(denied.status==1 and not denied.changed,letter+" unconnected ordinary edge remains rejected")
		# Deliberately invalid negative inputs exercise the public Kernel's closed admission.
		var cross:=level.duplicate(true)
		for cube in cross.cubes:
			if cube.cube_id==&"target": cube.layer=1
		var cross_result:=evaluate(cross,initial,{"kind":8,"connection_id":StringName("pfall_"+letter)})
		check(cross_result.status==1 and cross_result.rejection_code==2102,letter+" cross-World target rejected by WORLD_NOT_ALLOWED")
		var permission:=level.duplicate(true)
		permission.perspective_falls[0].allowed_world_orientations=[22]
		var permission_result:=evaluate(permission,initial,{"kind":8,"connection_id":StringName("pfall_"+letter)})
		check(permission_result.status==1 and permission_result.rejection_code==2102,letter+" unpermitted committed World orientation rejected by WORLD_NOT_ALLOWED")
		var blocked:=level.duplicate(true)
		for face in blocked.faces:
			if face.face_id==&"target/TOP": face.walkable=false
		check(evaluate(blocked,initial,{"kind":8,"connection_id":StringName("pfall_"+letter)}).status!=0,letter+" invalid landing support fails closed")
		var clipped:=level.duplicate(true)
		clipped.perspective_falls[0].path_points2[1]=Vector3i(0,4,0)
		check(evaluate(clipped,initial,{"kind":8,"connection_id":StringName("pfall_"+letter)}).status!=0,letter+" path through source support fails closed")
		save("map_"+letter+".graph.json",graph)
		routes.append({"map":letter,"level_hash":level.content_hash,"initial_key":initial_key,"landing_key":Key.build(level,landing).key,"final_key":final_key,"trace":solved.solution_trace,"graph_nodes":graph.nodes.size(),"graph_edges":graph.edges.size(),"formal_fall_edges":fall_edges.size(),"exit_roll_edges":exit_edges.size(),"softlock":softlock,"replay":replay,"graphical_replay":{"status":"PENDING","result":graphical},"fall_sweep":fall_safe,"events":events,"v1_hash":legacy.level.content_hash})
	save("report.json",{"checks":checks,"failures":failures,"routes":routes,"doubles":[],"authority":"exact09 bake_game_feel -> real Baker/Codec/Facade/Kernel/complete Explorer/Fall-bearing Softlock/Safety/LOGICAL_SESSION Replayer; logical transition completions only; natural10A tested separately","graphical_replayer":"PENDING_GAME_FEEL_GRAPHICAL_COMPLETION_BRIDGE","pid":OS.get_process_id(),"user_data_dir":OS.get_user_data_dir(),"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"input":"direct formal public APIs; logical native completion only; OS/human input NOT_RUN","human_qa":"NOT_RUN"})
	print("PFALL_V2_PATH checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
