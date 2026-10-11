extends SceneTree
const Factory=preload("res://experiments/spatial_puzzle_batch_01/maps/map_factory.gd")
const R=preload("res://foundation/contracts/contract_records.gd")
const Session=preload("res://foundation/runtime/runtime_session.gd")
const Key=preload("res://foundation/contracts/state_key.gd")
const Solver=preload("res://foundation/solver/bfs_solver.gd")
const Search=preload("res://foundation/solver/search_records.gd")
const Goal=preload("res://foundation/rules/goal_evaluator.gd")
const Softlock=preload("res://foundation/quality/softlock/softlock_analyzer.gd")
const Replay=preload("res://foundation/parity/trace_replayer.gd")
var checks:=0
var failures:Array=[]
var rows:Array=[]
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label)
func walk(level:Dictionary,actions:Array)->Dictionary:
	var session=Session.new()
	var tokens:Array=[]
	session.transition_started.connect(func(_r,id,gen,glob):tokens.append([id,gen,glob]))
	check(session.load_level(level).ok,"real load")
	var initial:String=Key.build(level,session.state).key
	var steps:Array=[]
	for action in actions:
		var result:Dictionary=session.request_action(action)
		check(result.status==0,"witness action APPLIED")
		if result.status!=0:
			steps.append(result)
			break
		if result.changed:
			var t:Array=tokens[-1]
			if t[2]:session.finish_global(t[0],t[1])
			else:session.finish_local(t[0],t[1])
		steps.append({"action":action,"state":session.state.duplicate(true),"key":Key.build(level,session.state).key})
	var final:Dictionary=session.state.duplicate(true)
	session.reset()
	check(Key.build(level,session.state).key==initial,"real Reset restores canonical state")
	var goal:Dictionary=Goal.is_goal(level,final)
	check(goal.ok,"formal Goal query")
	return {"state":final,"steps":steps,"is_goal":goal.is_goal}
func run()->void:
	var out:String=OS.get_cmdline_user_args()[0]
	var profile:String=OS.get_cmdline_user_args()[1]
	check(OS.get_user_data_dir().replace("\\","/").begins_with(profile+"/"),"isolated profile")
	check(Factory.ids().size()==5,"five stable IDs")
	for id in [&"orientation_loop_lab",&"perspective_fork_lab"]:
		var baked:Dictionary=Factory.bake(id)
		check(baked.ok,"real Baker "+String(id))
		if not baked.ok:
			rows.append({"id":id,"bake":baked})
			continue
		var level:Dictionary=baked.level
		var witnesses:Dictionary=Factory.witnesses(id)
		var evidence:Dictionary={}
		for name in witnesses:
			evidence[name]=walk(level,witnesses[name])
			if String(name).begins_with("solution"):check(evidence[name].is_goal,"witness reaches Goal")
		if id==&"orientation_loop_lab":
			check(evidence.route_a.state.player.location==evidence.route_b.state.player.location and evidence.route_a.state.player.orientation!=evidence.route_b.state.player.orientation,"same location distinct orientations")
			check(evidence.closed_loop.state.player.location==level.spawn.location and evidence.closed_loop.state.player.orientation!=level.spawn.orientation,"closed loop changes orientation")
		else:
			check(evidence.solution_east.steps[1].state.player.location.cube_id==&"target_a" and evidence.solution_south.steps[1].state.player.location.cube_id==&"target_b","same MOVE unique camera targets")
		var solved:Dictionary=Solver.solve(level,R.initial_state(level),Search.default_policy(1),Search.default_budget())
		check(solved.status==0 and solved.graph.complete,"complete real Solver graph solved")
		var softlock:Dictionary=Softlock.analyze(level,solved.graph,{"max_nodes":10000,"max_edges":100000,"max_runtime_ms":0})
		check(softlock.status==0 and softlock.softlock_count==0,"formal full-graph softlock analysis finds no stranded state")
		var replayer=Replay.new()
		root.add_child(replayer)
		var replay:Dictionary={"status":-1,"reason":"No solution trace"}
		if solved.solution_trace is Dictionary:
			replay=await replayer.replay(level,solved.solution_trace,{"mode":0})
		check(replay.status==0,"actual logical Runtime Replay matches solver trace")
		replayer.free()
		rows.append({"id":id,"level_hash":level.content_hash,"witnesses":evidence,"solver_metrics":solved.metrics,"graph_complete":solved.graph.complete,"softlock":softlock,"trace":solved.solution_trace,"replay":replay})
	FileAccess.open(out.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"maps":rows,"doubles":[],"user_data_dir":OS.get_user_data_dir(),"pid":OS.get_process_id(),"scope":"Baker + logical Runtime + complete Solver + logical Replay; no graphical/human claims"},"\t"))
	print("SPATIAL MAPS checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
