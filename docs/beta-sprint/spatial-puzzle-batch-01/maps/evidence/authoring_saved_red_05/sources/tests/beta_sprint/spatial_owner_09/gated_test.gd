extends SceneTree
const Factory=preload("res://experiments/spatial_puzzle_batch_01/maps/map_factory.gd")
const Session=preload("res://foundation/runtime/runtime_session.gd")
const Key=preload("res://foundation/contracts/state_key.gd")
const R=preload("res://foundation/contracts/contract_records.gd")
const Goal=preload("res://foundation/rules/goal_evaluator.gd")
const Solver=preload("res://foundation/solver/bfs_solver.gd")
const Search=preload("res://foundation/solver/search_records.gd")
const Softlock=preload("res://foundation/quality/softlock/softlock_analyzer.gd")
const Replay=preload("res://foundation/parity/trace_replayer.gd")
var checks:=0
var failures:Array=[]
var results:Array=[]
var session:RefCounted
var tokens:Array=[]
var commits:Array=[]
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label)
func act(level:Dictionary,action:Dictionary,expected:int=0)->Dictionary:
	var before:Dictionary=session.state.duplicate(true)
	var count:int=tokens.size()
	var commit_count:int=commits.size()
	var result:Dictionary=session.request_action(action)
	check(result.status==expected,"status "+str(action))
	if result.status==0 and result.changed:
		check(tokens.size()==count+1,"one native transition")
		var token:Array=tokens[-1]
		if token[2]:session.finish_global(token[0],token[1])
		else:session.finish_local(token[0],token[1])
		check(commits.size()==commit_count+1,"one authoritative commit")
		if action.kind==1:
			check(session.state.player.orientation==before.player.orientation and session.state.camera_quadrant==before.camera_quadrant,"Shift preserves orientation and camera")
	elif result.status==1:
		check(Key.build(level,before).key==Key.build(level,session.state).key and tokens.size()==count and commits.size()==commit_count,"rejection preserves key and emits no transition/commit")
	return {"action":action,"result":result,"after":session.state.duplicate(true),"before_key":Key.build(level,before).key,"after_key":Key.build(level,session.state).key}
func run()->void:
	var args:PackedStringArray=OS.get_cmdline_user_args()
	var id:StringName=StringName(args[2])
	check(OS.get_user_data_dir().replace("\\","/").begins_with(args[1]+"/"),"isolated profile")
	var baked:Dictionary=Factory.bake(id)
	check(baked.ok,"schema4 real Baker "+String(id))
	if baked.ok:
		var level:Dictionary=baked.level
		session=Session.new()
		session.transition_started.connect(func(_r,i,g,b):tokens.append([i,g,b]))
		session.committed.connect(func(state):commits.append(state.duplicate(true)))
		check(session.load_level(level).ok,"real load")
		var initial:String=Key.build(level,session.state).key
		var denied:Dictionary=act(level,{"kind":1},1)
		check(denied.result.rejection_code==(2010 if id==&"world_shift_gate_lab" else 2011),"off-point or locked gate code")
		results.append({"negative_shift":denied})
		for name in Factory.witnesses(id):
			session.reset()
			check(Key.build(level,session.state).key==initial,"Reset restores initial key")
			var steps:Array=[]
			for action in Factory.witnesses(id)[name]:
				var step:Dictionary=act(level,action)
				steps.append(step)
				if step.result.status!=0:break
			if name=="wrong_face":check(session.state.mechanism_states.contact_lock==&"idle","wrong contact rolls without latch")
			if name=="correct_face":
				check(session.state.mechanism_states.contact_lock==&"latched","correct post-roll contact latches")
				steps.append(act(level,{"kind":5,"mechanism_id":&"contact_lock"},1))
				steps.append(act(level,{"kind":0,"face_axis":2}))
				steps.append(act(level,{"kind":0,"face_axis":0}))
				check(session.state.mechanism_states.contact_lock==&"latched","repeat arrival retains latch")
			if String(name).begins_with("solution"):
				var goal:Dictionary=Goal.is_goal(level,session.state)
				check(goal.ok and goal.is_goal,"solution reaches formal Goal")
			results.append({"witness":name,"steps":steps})
		session.reset()
		check(Key.build(level,session.state).key==initial,"final Reset restores full key")
		FileAccess.open(args[0].path_join("runtime_witnesses.json"),FileAccess.WRITE).store_string(JSON.stringify({"id":id,"checks":checks,"failures":failures,"results":results,"stage":"Runtime witnesses only; Solver/Softlock/Replay still pending"},"\t"))
		print("RUNTIME_WITNESSES_COMPLETE ",id," checks=",checks," failures=",failures)
		var solved:Dictionary=Solver.solve(level,R.initial_state(level),Search.default_policy(1),Search.default_budget())
		print("SOLVER_COMPLETE ",id," status=",solved.status," complete=",solved.graph.complete," metrics=",solved.metrics)
		check(solved.status==0 and solved.graph.complete,"complete real Solver graph solved")
		var softlock:Dictionary=Softlock.analyze(level,solved.graph,{"max_nodes":10000,"max_edges":100000,"max_runtime_ms":0})
		check(softlock.status==0 and softlock.softlock_count==0,"all reachable states recover without Reset")
		var bypasses:int=0
		if id!=&"world_shift_gate_lab":
			for node in solved.graph.nodes.values():
				if node.state.player.location.layer==1 and node.state.mechanism_states.contact_lock!=&"latched":bypasses+=1
			check(bypasses==0,"no reachable Inner bypasses contact latch")
		var replay:Dictionary={"status":-1,"reason":"No solution trace"}
		if solved.solution_trace is Dictionary:
			var replayer=Replay.new()
			root.add_child(replayer)
			replay=await replayer.replay(level,solved.solution_trace,{"mode":0})
			replayer.free()
		check(replay.status==0,"logical Replay matches solver StateKeys")
		results.append({"metrics":solved.metrics,"complete":solved.graph.complete,"softlock":softlock,"trace":solved.solution_trace,"replay":replay,"bypasses":bypasses})
	FileAccess.open(args[0].path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"id":id,"checks":checks,"failures":failures,"bake":baked,"results":results,"doubles":[],"user_data_dir":OS.get_user_data_dir(),"pid":OS.get_process_id(),"scope":"logical formal contracts only; graphical and Human NOT_RUN"},"\t"))
	print("GATED MAP ",id," checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
