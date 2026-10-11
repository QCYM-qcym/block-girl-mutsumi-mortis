extends SceneTree
const Maps=preload("res://experiments/spatial_puzzle_batch_01/maps/map_factory.gd")
const Host=preload("res://experiments/spatial_puzzle_batch_01/host/spatial_lab.gd")
const Goal=preload("res://foundation/rules/goal_evaluator.gd")
const Key=preload("res://foundation/contracts/state_key.gd")
var checks:=0
var failures:Array=[]
var rows:Array=[]
var evidence:=OS.get_environment("FOUNDATION_TEST_EVIDENCE")
var selected:Array[StringName]=[&"orientation_loop_lab",&"perspective_fork_lab"]
func _initialize()->void:
	for arg in OS.get_cmdline_user_args():
		if arg=="--all-maps": selected=Maps.ids()
	call_deferred("run")
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok: failures.append(label)
func capture(name:String)->void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(evidence.path_join(name+".png"))
func run()->void:
	root.size=Vector2i(1280,720)
	check(DisplayServer.get_name()!="headless","real graphical renderer")
	for id in selected:
		var host:=Host.new();host.lab_id=id
		root.add_child(host)
		await process_frame
		check(host.runtime.is_loaded() and host.host_issues.is_empty(),String(id)+" actual Host loads formal map")
		if not host.runtime.is_loaded(): host.free();continue
		await capture(String(id)+"_start")
		var witnesses:Dictionary=Maps.witnesses(id)
		var routes:Array=[]
		for name in witnesses:
			if String(name).begins_with("solution"): routes.append(name)
		check(not routes.is_empty(),String(id)+" explicit formal solution witnesses")
		for route_index in mini(2,routes.size()):
			host.reset_lab()
			var actions:Array=witnesses[routes[route_index]]
			var steps:Array=[]
			for action in actions:
				var result:Dictionary=host.runtime.request_action(action)
				check(result.status==0,String(id)+" actual action applies "+str(action))
				if result.status!=0: break
				var stamps:Dictionary={}
				var until:=Time.get_ticks_msec()+4000
				while (not host.runtime.is_idle() or host.presenter.snapshot().phase!="IDLE") and Time.get_ticks_msec()<until:
					await process_frame
					var view:Dictionary=host.presenter.snapshot()
					if route_index==0 and view.phase in ["FALL","LANDING"]:
						var label:String="fall_advance" if view.phase=="FALL" and view.elapsed<0.35 else ("fall_descend" if view.phase=="FALL" else "landing")
						if not stamps.has(label):
							stamps[label]=true
							await capture(String(id)+"_step"+str(steps.size())+"_"+label)
				check(host.runtime.is_idle() and host.presenter.snapshot().phase=="IDLE",String(id)+" natural completion settles")
				check(host.runtime.get_state()==result.next_state,String(id)+" actual state equals authoritative accepted state")
				check(host.actor.transform.is_equal_approx(host.project_pose(host.runtime.get_state().player).transform),String(id)+" final visual pose matches authority")
				steps.append({"action":action,"statekey":Key.build(host.runtime.get_level(),host.runtime.get_state()).key,"commits":host.runtime.get_commit_count()})
			check(Goal.is_goal(host.runtime.get_level(),host.runtime.get_state()).is_goal,String(id)+" witness reaches real Goal")
			await capture(String(id)+"_goal_"+str(route_index))
			rows.append({"id":id,"route":routes[route_index],"steps":steps,"host_issues":host.host_issues.duplicate(true)})
		check(host.host_issues.is_empty(),String(id)+" no Host errors")
		host.free();await process_frame
	FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"doubles":[],"rows":rows,"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"authority":"real MapFactory+Baker+Facade+spatial Host with natural animation completion; Runtime action API input, no manual finish"},"\t"))
	quit(0 if failures.is_empty() else 1)
