extends SceneTree
## Current real actor/platform/anchor and contact audit; no completion injection.
const Maps=preload("res://experiments/game_feel_01/maps/map_factory.gd")
const Runtime=preload("res://foundation/game_feel/runtime_facade.gd")
const Bridge=preload("res://game/feel/graphical_completion_bridge.gd")
const Geometry=preload("res://foundation/spatial/surface_geometry.gd")
const Key=preload("res://foundation/contracts/state_key.gd")
const Goal=preload("res://foundation/rules/goal_evaluator.gd")
var evidence:=""
var checks:=0
var failures:Array=[]
var rows:Array=[]
var contact_only:=false

func _initialize()->void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): evidence=arg.trim_prefix("--evidence=")
	call_deferred("run")

func check(ok:bool,label:String)->void:
	checks+=1
	if not ok: failures.append(label)

func v(value:Vector3)->Array:
	return [value.x,value.y,value.z]

func visual_pose(value:Transform3D)->Dictionary:
	return {"origin":v(value.origin),"basis":[v(value.basis.x),v(value.basis.y),v(value.basis.z)]}

func support_gap(body:MeshInstance3D,anchor:Dictionary)->float:
	var box:AABB=body.get_aabb()
	var normal:=Vector3(anchor.frame.normal)
	var top:=Vector3(anchor.position2)*0.5
	var lowest:=INF
	for x in [0.0,1.0]:
		for y in [0.0,1.0]:
			for z in [0.0,1.0]:
				var corner:Vector3=body.global_transform*(box.position+box.size*Vector3(x,y,z))
				lowest=minf(lowest,normal.dot(corner-top))
	return lowest

func run()->void:
	check(DisplayServer.get_name()!="headless","real Godot renderer")
	root.size=Vector2i(1152,648)
	for letter in ["a","b"]:
		var spec:Dictionary=Maps.read_spec(letter)
		var baked:Dictionary=Maps.bake_game_feel(spec)
		check(baked.ok,letter+" actual public Baker")
		if not baked.ok: continue
		var runtime:=Runtime.new()
		check(runtime.load_level(baked.level).ok,letter+" actual public Runtime")
		var bridge:=Bridge.new()
		root.add_child(bridge)
		check(bridge.bind_runtime(runtime,baked.level).ok,letter+" same Facade natural Presenter")
		var lab:Node3D=bridge.lab
		var before:Dictionary=runtime.get_state()
		var resolved:Dictionary=Geometry.snapshot(baked.level,before)
		var anchors:Dictionary={}
		for anchor in resolved.value.anchors:
			if String(anchor.face_id).ends_with("/TOP"):
				anchors[String(anchor.face_id)]=anchor
		var source:Dictionary=anchors["source/TOP"]
		var target:Dictionary=anchors["target/TOP"]
		var yellow:Dictionary=anchors["exit/TOP"]
		var actual_target:MeshInstance3D=lab.geometry_root.get_node("target")
		var actual_yellow:MeshInstance3D=lab.geometry_root.get_node("exit")
		var body:MeshInstance3D=lab.actor.get_child(0)
		var samples:Array=[]
		var source_screen:Vector2=lab.camera.unproject_position(lab.actor.global_position)
		var departure_horizontal:=0.0
		var gaps:Array=[]
		var result:Dictionary=runtime.request_action({"kind":0,"face_axis":2})
		check(result.status==0,letter+" original formal MOVE triggers authored Fall")
		var started:Dictionary=lab.events[-1]
		check(started.semantic=="PERSPECTIVE_FALL_APPLIED",letter+" no synthetic Fall")
		var token:Dictionary=started.transition_identity
		var deadline:=Time.get_ticks_msec()+4000
		while lab.presenter.snapshot().phase!="IDLE" and Time.get_ticks_msec()<deadline:
			await process_frame
			var phase:String=lab.presenter.snapshot().phase
			var screen:Vector2=lab.camera.unproject_position(lab.actor.global_position)
			var sample:Dictionary={"phase":phase,"time_ms":Time.get_ticks_msec(),"pose":visual_pose(lab.actor.global_transform),"screen":[screen.x,screen.y],"statekey":Key.build(baked.level,runtime.get_state()).key}
			if phase=="FALL":
				var motion:Dictionary=lab.presenter._fall.sample(lab.presenter.snapshot().elapsed)
				sample["motion_phase"]=motion.phase
				if motion.phase=="DEPARTURE": departure_horizontal=maxf(departure_horizontal,absf(screen.x-source_screen.x))
			if phase=="LANDING":
				var gap:=support_gap(body,target)
				gaps.append(gap)
				sample["target_support_gap"]=gap
			samples.append(sample)
		check(lab.presenter.snapshot().phase=="IDLE" and runtime.get_commit_count()==1,letter+" real Fall/Landing completes once")
		check(runtime.get_state().player.location.cube_id==&"target" and runtime.get_state().player.orientation==0,letter+" old native target and PRESERVE")
		check(lab.actor.transform.is_equal_approx(lab.project_pose(runtime.get_state().player).transform),letter+" exact formal terminal Visual Pose")
		if not contact_only:
			check(target.position2==yellow.position2,letter+" requested target is actual pre-existing yellow platform position")
			check(departure_horizontal>0.5,letter+" visible horizontal forward departure before descent")
		check(not gaps.is_empty() and gaps.all(func(g):return absf(g)<=0.0001),letter+" real Landing body remains on exact TOP through deformation")
		await RenderingServer.frame_post_draw
		get_root().get_texture().get_image().save_png(evidence.path_join(letter+"_old_target_settled.png"))
		var after:Dictionary=runtime.get_state()
		rows.append({"map":letter,"source_face":"source/TOP","source_anchor2":str(source.position2),"target_face":"target/TOP","target_anchor2":str(target.position2),"yellow_face_before_fix":"exit/TOP","yellow_anchor2":str(yellow.position2),"target_platform_mesh":String(actual_target.get_path()),"yellow_platform_mesh":String(actual_yellow.get_path()),"actor_visual_root":String(lab.actor.get_path()),"actor_body_mesh":String(body.get_path()),"target_albedo":str(actual_target.material_override.albedo_color),"yellow_albedo":str(actual_yellow.material_override.albedo_color),"camera":before.camera_quadrant,"action":result.action,"native_identity":token,"before":before,"after":after,"final_statekey":Key.build(baked.level,after).key,"final_visual_pose":visual_pose(lab.actor.transform),"departure_horizontal_pixels":departure_horizontal,"landing_support_gaps":gaps,"samples":samples})
		check(runtime.request_action({"kind":0,"face_axis":0}).status==0,letter+" original U_POS Roll still admitted")
		deadline=Time.get_ticks_msec()+2000
		while lab.presenter.snapshot().phase!="IDLE" and Time.get_ticks_msec()<deadline: await process_frame
		check(Goal.is_goal(baked.level,runtime.get_state()).is_goal,letter+" original route still reaches actual Goal")
		bridge.close()
		root.remove_child(bridge)
		bridge.queue_free()
		await process_frame
	FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"scope":"ACTUAL_LANDING_CONTACT" if contact_only else "TARGET_TRAJECTORY_CONTACT_AUDIT","checks":checks,"failures":failures,"doubles":[],"rows":rows,"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"user_data_dir":OS.get_user_data_dir(),"authority":"same formal Facade/public Baker with real Bridge/10A; actual Mesh corners for support contact; no synthetic completion or state/pose write"},"\t"))
	quit(0 if failures.is_empty() else 1)
