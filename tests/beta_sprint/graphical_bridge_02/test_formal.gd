extends SceneTree
const Maps=preload("res://experiments/game_feel_01/maps/map_factory.gd")
const Records=preload("res://foundation/contracts/contract_records.gd")
const Solver=preload("res://foundation/solver/bfs_solver.gd")
const Search=preload("res://foundation/solver/search_records.gd")
const Replay=preload("res://foundation/parity/trace_replayer.gd")
const View=preload("res://foundation/game_feel/view_contract.gd")
var checks:=0
var failures:Array=[]
var rows:Array=[]
var evidence:=""
func _initialize()->void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): evidence=arg.trim_prefix("--evidence=")
	call_deferred("run")
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok: failures.append(label)
func run()->void:
	check(DisplayServer.get_name()!="headless","actual renderer")
	for letter in ["a","b"]:
		var baked:Dictionary=Maps.bake_game_feel(Maps.read_spec(letter))
		check(baked.ok,letter+" public Baker")
		var solved:Dictionary=Solver.solve(baked.level,Records.initial_state(baked.level),Search.default_policy(1),Search.default_budget())
		check(solved.status==0 and solved.solution_trace!=null,letter+" actual Solver witness")
		var driver:=Replay.new()
		root.add_child(driver)
		var previous:Array=[]
		for repeat in 2:
			var result:Dictionary=await driver.replay(baked.level,solved.solution_trace,{"mode":1})
			check(result.status==0,letter+" formal graphical MATCH")
			check(result.matched_steps==2,letter+" Fall then Roll both matched")
			var steps:Array=driver.get_step_evidence() if driver.has_method("get_step_evidence") else driver.get("_step_evidence").duplicate(true)
			check(steps.size()==2,letter+" two real step evidence records")
			for index in steps.size():
				var step:Dictionary=steps[index]
				var terminal:Dictionary=step.get("completion_evidence",{})
				var expected:Dictionary=solved.solution_trace.steps[index].expected_state
				check(step.status==0 and step.commit_delta==1 and step.commit_signals==1 and step.completion_received,letter+" step exact one commit and completion")
				check(not terminal.is_empty(),letter+" real registered Bridge completion evidence")
				if terminal.is_empty(): continue
				check(step.transition_identity==terminal.transition_identity and terminal.transition_identity.has_all(["session_id","level_run_id","generation","transaction_id","is_global"]),letter+" exact native scoped identity")
				check(terminal.started_order<terminal.committed_order and terminal.committed_order<terminal.completion_order and terminal.cancelled_order==0,letter+" real STARTED COMMITTED COMPLETED step ordering")
				check(terminal.final_state==expected and terminal.final_statekey==step.expected_statekey and step.actual_statekey==step.expected_statekey,letter+" exact full formal StateKey and state")
				check(terminal.orientation==expected.player.orientation and terminal.world_id==expected.player.location.layer and terminal.camera_quadrant==expected.camera_quadrant,letter+" orientation World and Camera authority")
				check(terminal.final_visual_pose==terminal.expected_visual_pose,letter+" actual final physical visual pose")
				var camera_basis:Array=terminal.final_camera_pose.basis
				var formal_basis:Basis=View.basis(expected.camera_quadrant)
				check(Vector3(camera_basis[0][0],camera_basis[0][1],camera_basis[0][2]).is_equal_approx(formal_basis.x) and Vector3(camera_basis[1][0],camera_basis[1][1],camera_basis[1][2]).is_equal_approx(formal_basis.y),letter+" actual Camera basis matches formal view")
				check(terminal.frames.size()>3,letter+" actual motion frames")
				if index==0:
					check(terminal.terminal.terminal_phase=="LANDING_SETTLED" and terminal.frames.any(func(f):return f.phase=="FALL") and terminal.frames.any(func(f):return f.phase=="LANDING"),letter+" real Fall then natural Landing")
				else: check(terminal.terminal.terminal_phase=="ROLL_RESTORED",letter+" real Roll restored after landing")
				if repeat==1 and index<previous.size(): check(previous[index].actual_statekey==step.actual_statekey and previous[index].transition_identity!=step.transition_identity,letter+" replay determinism with fresh native identity")
			rows.append({"map":letter,"repeat":repeat,"result":result,"steps":steps,"trace":solved.solution_trace})
			previous=steps
		driver.free()
	FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"doubles":[],"rows":rows,"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"user_data_dir":OS.get_user_data_dir(),"authority":"formal production Replayer mode1 + actual public Baker/Solver, no overrides or manual completion"},"\t"))
	quit(0 if failures.is_empty() else 1)
