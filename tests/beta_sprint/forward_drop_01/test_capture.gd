extends "res://tests/beta_sprint/yellow_target_01/test_audit.gd"
## Real runtime, real natural Presenter, support geometry and fresh motion cadence.
const Profile=preload("res://foundation/game_feel/trajectory_profile.gd")
const View=preload("res://foundation/game_feel/view_contract.gd")

func image_frame(name:String)->void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(evidence.path_join(name+".png"))

func parameter_at(motion:RefCounted, trajectory:Dictionary, time:float, direction:Vector3)->float:
	var point:Vector3=motion.sample(time).position
	# Observation uses formal DOWN, strictly monotone on these accepted maps;
	# it is never a screen-coordinate animation or a permission computation.
	if point.is_equal_approx(Vector3(trajectory.descent_control_points2[-1])*0.5): return 1.0
	var low:=0.0
	var high:=1.0
	for i in 30:
		var middle:float=(low+high)*0.5
		var candidate:Vector3=Profile.sample_actor_center(trajectory,middle).position
		if candidate.dot(direction)<point.dot(direction): low=middle
		else: high=middle
	return (low+high)*0.5

func run()->void:
	check(DisplayServer.get_name()!="headless","real graphical renderer")
	root.size=Vector2i(1280,720)
	for letter in ["a","b"]:
		var baked:Dictionary=Maps.bake_game_feel(Maps.read_spec(letter))
		check(baked.ok,letter+" real v2 opt-in Baker")
		if not baked.ok: continue
		var runtime:=Runtime.new()
		check(runtime.load_level(baked.level).ok,letter+" real Runtime loaded")
		var bridge:=Bridge.new()
		root.add_child(bridge)
		check(bridge.bind_runtime(runtime,baked.level).ok,letter+" real registered graphical Presenter")
		var lab:Node3D=bridge.lab
		var before:Dictionary=runtime.get_state()
		var source_basis:Basis=lab.actor.basis
		var observation:=Vector3(View.DOWN[before.camera_quadrant])
		var resolved:Dictionary=Geometry.snapshot(baked.level,before)
		var anchors:Dictionary={}
		for anchor in resolved.value.anchors: anchors[String(anchor.face_id)]=anchor
		var source:Dictionary=anchors["source/TOP"]
		var target:Dictionary=anchors["target/TOP"]
		var body:MeshInstance3D=lab.actor.get_child(0)
		var target_mesh:MeshInstance3D=lab.geometry_root.get_node("target")
		check(target.position2==Vector3i(-6,1 if letter=="a" else 9,8),letter+" unchanged actual yellow TOP anchor")
		check(target_mesh.material_override.albedo_color==Color(0.8,0.7,0.25),letter+" real target is yellow")
		await image_frame(letter+"_01_source")
		check(runtime.request_action({"kind":0,"face_axis":2}).status==0,letter+" native forward MOVE accepted")
		var started:Dictionary=lab.events[-1]
		check(started.semantic=="PERSPECTIVE_FALL_APPLIED" and started.target_pose.location.cube_id==&"target" and started.target_pose.location.face==4,letter+" official Fall commits only yellow target/TOP")
		var path:Dictionary=started.authorized_trajectory
		var source_center:=Vector3(path.departure_points2[0])*0.5
		var leave_point:=Vector3(path.departure_points2[1])*0.5
		var forward:Vector3=(leave_point-source_center).normalized()
		var normal:=Vector3(source.frame.normal)
		var duration:float=started.presentation_duration_seconds
		var motion:RefCounted=lab.presenter._fall
		var initial:Dictionary=motion.sample(duration*0.05)
		var initial_advance:float=(initial.position-source_center).dot(forward)
		check(initial_advance>0.01,letter+" forward movement starts with initial lean; no stationary anticipation hold")
		check((initial.rotation_offset*normal).dot(forward)>0.005,letter+" initial signed lean is forward, not sideways/backward")
		var low:=0.0
		var high:=duration
		for i in 30:
			var middle:float=(low+high)*0.5
			if parameter_at(motion,path,middle,observation)<0.25: low=middle
			else: high=middle
		var descend_start:float=(low+high)*0.5
		var descent_time:=duration-descend_start
		var early_increment:float=parameter_at(motion,path,descend_start+descent_time*0.35,observation)-parameter_at(motion,path,descend_start+descent_time*0.15,observation)
		var late_increment:float=parameter_at(motion,path,descend_start+descent_time*0.85,observation)-parameter_at(motion,path,descend_start+descent_time*0.65,observation)
		check(late_increment>early_increment*1.2,letter+" descent accelerates along authorized path instead of uniform floating travel")
		var h:float=duration*0.0001
		var at_join:Vector3=motion.sample(descend_start).position
		var join_before:Vector3=(at_join-motion.sample(descend_start-h).position)/h
		var join_after:Vector3=(motion.sample(descend_start+h).position-at_join)/h
		check(join_before.length()>0.1 and join_before.normalized().dot(join_after.normalized())>0.999 and absf(join_before.length()-join_after.length())<join_before.length()*0.02,letter+" actual sampler velocity joins continuously with positive forward inertia")
		var sampled_geometry:=true
		var pre_edge_plane:=true
		var continuing:=true
		var previous_parameter:=0.0
		var cadence:Array=[]
		for i in range(1,121):
			var time:float=duration*float(i)/120.0
			var parameter:=parameter_at(motion,path,time,observation)
			var sampled:Dictionary=motion.sample(time)
			var advance:float=(sampled.position-source_center).dot(forward)
			var out_of_plane:float=absf((sampled.position-source_center).dot(normal))
			if advance<=0.5: pre_edge_plane=pre_edge_plane and out_of_plane<0.0001
			continuing=continuing and parameter>previous_parameter+0.000001
			sampled_geometry=sampled_geometry and sampled.position.distance_to(Profile.sample_actor_center(path,parameter).position)<0.0001
			cadence.append({"time":time,"parameter":parameter,"advance":advance,"out_of_plane":out_of_plane,"motion_phase":sampled.phase,"lean":sampled.rotation_offset.get_angle()})
			previous_parameter=parameter
		check(pre_edge_plane,letter+" no normal descent while COM remains inside actual source support edge")
		check(continuing,letter+" positive progress throughout; no air relay hold")
		check(sampled_geometry,letter+" exact formal source/leave/target trajectory only; no screen motion")
		var frames:Array=[]
		var stages:Dictionary={"source":true}
		var gaps:Array=[]
		var monotone:=true
		var previous_screen:Vector2=lab.camera.unproject_position(lab.actor.global_position)
		var previous_position:Vector3=source_center
		var max_step:=0.0
		var forward_lean:=false
		var compression:=false
		var rebound:=false
		var last_fall_image:Image
		var last_fall_frame:Dictionary={}
		var deadline:=Time.get_ticks_msec()+5000
		while lab.presenter.snapshot().phase!="IDLE" and Time.get_ticks_msec()<deadline:
			await process_frame
			await RenderingServer.frame_post_draw
			var view:Dictionary=lab.presenter.snapshot()
			var screen:Vector2=lab.camera.unproject_position(lab.actor.global_position)
			var frame:Dictionary={"phase":view.phase,"elapsed":view.elapsed,"pose":visual_pose(lab.actor.transform),"screen":[screen.x,screen.y],"commits":runtime.get_commit_count(),"statekey":Key.build(baked.level,runtime.get_state()).key,"identity":view.transition_identity}
			if view.phase=="FALL":
				var sampled:Dictionary=motion.sample(view.elapsed)
				var parameter:=parameter_at(motion,path,view.elapsed,observation)
				var advance:float=(lab.actor.position-source_center).dot(forward)
				frame.motion_phase=sampled.phase
				frame.parameter=parameter
				frame.advance=advance
				frame.lean=sampled.rotation_offset.get_angle()
				frame.actual_signed_forward_lean=((lab.actor.basis*source_basis.inverse())*normal).normalized().dot(forward)
				frame.support_gap=support_gap(body,target)
				max_step=maxf(max_step,lab.actor.position.distance_to(previous_position))
				if advance>0.05 and advance<1.0: forward_lean=forward_lean or frame.actual_signed_forward_lean>0.005
				if advance>0.5 and parameter<0.25 and not stages.has("edge"):
					root.get_texture().get_image().save_png(evidence.path_join(letter+"_02_forward_edge_leave.png"))
					stages.edge=true
				if parameter>=0.25:
					monotone=monotone and screen.y>=previous_screen.y-0.05
					if parameter>=0.55 and not stages.has("middle"):
						root.get_texture().get_image().save_png(evidence.path_join(letter+"_03_descend_middle.png"))
						stages.middle=true
				if advance<=0.5: check(absf((lab.actor.position-source_center).dot(normal))<0.0001,letter+" rendered frame stays on source plane before edge leave")
				last_fall_image=root.get_texture().get_image()
				last_fall_frame=frame.duplicate(true)
			if view.phase=="LANDING":
				var gap:=support_gap(body,target)
				gaps.append(gap)
				frame.support_gap=gap
				var scale:Vector3=lab.actor.basis.get_scale()
				compression=compression or scale.y<0.99
				rebound=rebound or scale.y>1.00001
				if not stages.has("contact"):
					check(last_fall_image!=null and last_fall_frame.get("support_gap",-1.0)>0.0 and last_fall_frame.get("commits",-1)==0,letter+" last actually rendered frame before yellow contact is above support and uncommitted")
					if last_fall_image!=null:
						last_fall_image.save_png(evidence.path_join(letter+"_04_pre_yellow_contact.png"))
						stages.precontact=true
					check(runtime.get_commit_count()==1,letter+" actual COMMITTED exactly once before landing")
					root.get_texture().get_image().save_png(evidence.path_join(letter+"_05_yellow_landing.png"))
					stages.contact=true
			frames.append(frame)
			previous_screen=screen
			previous_position=lab.actor.position
		check(forward_lean,letter+" natural forward movement retains forward weight")
		check(monotone and max_step<0.8,letter+" natural rendered descent continuous and visually downward")
		check(compression and rebound,letter+" actual contact compression and small rebound")
		check(not gaps.is_empty() and gaps.all(func(g):return absf(g)<0.0001),letter+" yellow TOP bottom contact throughout landing")
		check(lab.presenter.snapshot().phase=="IDLE" and runtime.get_commit_count()==1,letter+" single Fall completes and releases input")
		var landed:Dictionary=runtime.get_state()
		check(landed.player==started.target_pose and landed.player.orientation==before.player.orientation,letter+" authoritative final yellow Pose and Orientation")
		check(lab.actor.transform.is_equal_approx(lab.project_pose(landed.player).transform),letter+" exact neutral target Visual Pose")
		await image_frame(letter+"_06_stable")
		stages.stable=true
		check(stages.size()==6,letter+" all six actual phase images")
		check(runtime.request_action({"kind":0,"face_axis":0}).status==0,letter+" native next U_POS Roll accepted")
		deadline=Time.get_ticks_msec()+2000
		while lab.presenter.snapshot().phase!="IDLE" and Time.get_ticks_msec()<deadline: await process_frame
		check(Goal.is_goal(baked.level,runtime.get_state()).is_goal and runtime.get_commit_count()==2,letter+" actual Fall Roll Goal route")
		check(lab.host_issues.is_empty(),letter+" shared Host no errors")
		rows.append({"map":letter,"native_identity":started.transition_identity,"source_pose":before.player,"target_pose":landed.player,"source_anchor2":str(source.position2),"target_anchor2":str(target.position2),"forward":v(forward),"support_edge_distance":0.5,"leave_point":v(leave_point),"authorized_trajectory":path,"initial_advance":initial_advance,"descent_start_seconds":descend_start,"early_parameter_increment":early_increment,"late_parameter_increment":late_increment,"join_velocity_before":v(join_before),"join_velocity_after":v(join_after),"cadence":cadence,"samples":frames,"precontact_frame":last_fall_frame,"landing_gaps":gaps,"stages":stages,"final_statekey":Key.build(baked.level,landed).key,"goal_statekey":Key.build(baked.level,runtime.get_state()).key})
		bridge.free()
		await process_frame
	FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"task":"PFALL_FORWARD_THEN_DROP_TO_YELLOW_FIX_01","checks":checks,"failures":failures,"doubles":[],"rows":rows,"viewport":[root.size.x,root.size.y],"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"user_data_dir":OS.get_user_data_dir(),"authority":"Real public Baker/Runtime/registered natural Presenter; native MOVE and once-only COMMITTED. Dense pure sampler probes observe the accepted motion without changing clock or authority. Per-frame real mesh/contact and six renderer screenshots per map."},"\t"))
	quit(0 if failures.is_empty() else 1)
