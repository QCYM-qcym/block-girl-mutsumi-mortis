extends "res://tests/beta_sprint/graphical_bridge_02/test_formal.gd"
const SpatialMaps=preload("res://experiments/spatial_puzzle_batch_01/maps/map_factory.gd")
func run()->void:
	for id in [&"world_shift_gate_lab",&"face_lock_lab",&"rubik_spatial_puzzle_01"]:
		var baked:Dictionary=SpatialMaps.bake(id)
		check(baked.ok,String(id)+" real schema4 Baker")
		if not baked.ok:
			rows.append({"id":id,"issues":baked.issues});continue
		var solved:Dictionary=Solver.solve(baked.level,Records.initial_state(baked.level),Search.default_policy(0),Search.default_budget())
		check(solved.status==0 and solved.solution_trace is Dictionary,String(id)+" actual shortest witness")
		if not solved.solution_trace is Dictionary: continue
		var driver:=Replay.new();root.add_child(driver)
		var result:Dictionary=await driver.replay(baked.level,solved.solution_trace,{"mode":1,"step_timeout_ms":2000})
		check(result.status==0 and result.matched_steps==solved.solution_trace.total_actions,String(id)+" registered Bridge observes all natural completions")
		var steps:Array=driver.get_step_evidence()
		var shift_count:=0
		for step in steps:
			check(step.completion_received and step.commit_delta==1 and step.commit_signals==1,String(id)+" one completion and one commit")
			check(step.actual_statekey==step.expected_statekey,String(id)+" full StateKey matches")
			if step.action.kind==1:
				shift_count+=1
				var terminal:Dictionary=step.completion_evidence
				check(terminal.get("terminal",{}).get("completion")=="Tween.finished",String(id)+" actual Shift Tween completion")
		check(shift_count==1,String(id)+" real world gate step present")
		rows.append({"id":id,"result":result,"steps":steps,"trace":solved.solution_trace})
		driver.free();await process_frame
	FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"doubles":[],"rows":rows,"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"authority":"registered production mode1 Replayer + actual first-shortest Solver + native spatial Host; headless runs prove nodes only, not rendered Graphical acceptance"},"\t"))
	quit(0 if failures.is_empty() else 1)
