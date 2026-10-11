extends "res://tests/beta_sprint/graphical_bridge_02/test_formal.gd"
const Kernel=preload("res://foundation/rules/puzzle_rule_kernel.gd")
const Rules=preload("res://foundation/rules/rule_records.gd")
const Key=preload("res://foundation/contracts/state_key.gd")
const Trace=preload("res://foundation/solver/solution_trace.gd")
func run()->void:
	var baked:Dictionary=Maps.bake_game_feel(Maps.read_spec("a"))
	var solved:Dictionary=Solver.solve(baked.level,Records.initial_state(baked.level),Search.default_policy(1),Search.default_budget())
	check(solved.status==0,"real Solver establishes base route")
	var trace:Dictionary=solved.solution_trace.duplicate(true)
	var state:Dictionary=trace.initial_state.duplicate(true)
	var actions:Array=[{"kind":9,"camera_quadrant":2},{"kind":9,"camera_quadrant":1}]
	for step in trace.steps: actions.append(step.action)
	trace.steps=[]
	for action in actions:
		var result:Dictionary=Kernel.evaluate_action(baked.level,state,action,Rules.idle_context())
		check(result.status==0 and result.changed,"actual formal Camera/Fall/Roll action")
		state=result.next_state
		trace.steps.append({"index":trace.steps.size()+1,"action":action,"expected_state":state,"resulting_statekey":Key.build(baked.level,state).key,"global_kind":result.global_kind})
	trace.total_actions=trace.steps.size();trace.shortest=false
	check(Trace.validate_semantics(baked.level,trace).ok,"real Kernel validates extended witness")
	var driver:=Replay.new();root.add_child(driver)
	var replay:Dictionary=await driver.replay(baked.level,trace,{"mode":1,"step_timeout_ms":1500})
	check(replay.status==0 and replay.matched_steps==4,"formal graphical Camera Camera Fall Roll all match")
	var steps:Array=driver.get_step_evidence()
	for step in steps:
		check(step.completion_received and step.commit_delta==1,"actual natural completion and single commit")
	driver.free()
	FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"doubles":[],"result":replay,"steps":steps,"display":DisplayServer.get_name(),"authority":"formal production graphical Replayer; actual Kernel-validated Camera extension of real Solver witness"},"\t"))
	quit(0 if failures.is_empty() else 1)
