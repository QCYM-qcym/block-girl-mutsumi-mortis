extends SceneTree
const Maps=preload("res://experiments/game_feel_01/maps/map_factory.gd")
const Records=preload("res://foundation/contracts/contract_records.gd")
const Solver=preload("res://foundation/solver/bfs_solver.gd")
const Search=preload("res://foundation/solver/search_records.gd")
const Replay=preload("res://foundation/parity/trace_replayer.gd")
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
		var result:Dictionary=await driver.replay(baked.level,solved.solution_trace,{"mode":1})
		check(result.status==0,letter+" formal graphical MATCH")
		check(result.matched_steps==2,letter+" Fall then Roll both matched")
		rows.append({"map":letter,"result":result,"steps":driver.get("_step_evidence"),"trace":solved.solution_trace})
		driver.free()
	FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"doubles":[],"rows":rows,"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"user_data_dir":OS.get_user_data_dir(),"authority":"formal production Replayer mode1 + actual public Baker/Solver, no overrides or manual completion"},"\t"))
	quit(0 if failures.is_empty() else 1)
