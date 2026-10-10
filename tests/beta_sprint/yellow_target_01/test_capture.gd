extends "res://tests/beta_sprint/yellow_target_01/test_audit.gd"
## New-design natural graphical evidence. No Runtime writes or completion injection.

func shot(lab:Node3D,name:String)->void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(evidence.path_join(name+".png"))

func run()->void:
	check(DisplayServer.get_name()!="headless","real Godot renderer")
	root.size=Vector2i(1280,720)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--size="):
			var dimensions:=arg.trim_prefix("--size=").split("x")
			root.size=Vector2i(int(dimensions[0]),int(dimensions[1]))
	for letter in ["a","b"]:
		var spec:Dictionary=Maps.read_spec(letter)
		var baked:Dictionary=Maps.bake_game_feel(spec)
		check(baked.ok,letter+" public Baker")
		if not baked.ok: continue
		check(baked.level.schema_version==3,letter+" explicit new trajectory level profile")
		# Old core PASS must not be mistaken for this new design.
		if baked.level.schema_version!=3: continue
		var runtime:=Runtime.new()
		check(runtime.load_level(baked.level).ok,letter+" actual formal Runtime")
		var bridge:=Bridge.new()
		root.add_child(bridge)
		check(bridge.bind_runtime(runtime,baked.level).ok,letter+" actual registered graphical view")
		var lab:Node3D=bridge.lab
		var before:Dictionary=runtime.get_state()
		var resolved:Dictionary=Geometry.snapshot(baked.level,before)
		var anchors:Dictionary={}
		for anchor in resolved.value.anchors:
			if String(anchor.face_id).ends_with("/TOP"): anchors[String(anchor.face_id)]=anchor
		var source:Dictionary=anchors["source/TOP"]
		var target:Dictionary=anchors["target/TOP"]
		var actual_target:MeshInstance3D=lab.geometry_root.get_node("target")
		var blue_reference:MeshInstance3D=lab.geometry_root.get_node("blue_reference")
		var body:MeshInstance3D=lab.actor.get_child(0)
		check(target.position2==Vector3i(-6,1 if letter=="a" else 9,8),letter+" target binds pre-existing yellow position TOP")
		check(actual_target!=body and blue_reference!=body and lab.actor!=lab.geometry_root,letter+" explicit Actor versus Platform identities")
		check(actual_target.material_override.albedo_color==Color(0.8,0.7,0.25),letter+" Host renders canonical target as requested yellow")
		var body_before:Transform3D=lab.actor.transform
		var source_screen:Vector2=lab.camera.unproject_position(lab.actor.global_position)
		await shot(lab,letter+"_01_source")
		var result:Dictionary=runtime.request_action({"kind":0,"face_axis":2})
		check(result.status==0,letter+" original U_NEG MOVE triggers one formal Fall")
		if result.status!=0:
			rows.append({"map":letter,"result":result,"host_issues":lab.host_issues})
			bridge.free()
			continue
		var started:Dictionary=lab.events[-1]
		check(started.semantic=="PERSPECTIVE_FALL_APPLIED" and started.schema_version==2 and started.contract_version=="game_feel.event.v2",letter+" explicit real event.v2 Fall")
		check(started.source_pose==before.player and started.target_pose.location.cube_id==&"target" and started.target_pose.location.face==4,letter+" formal Source/Target TOP identity")
		check(started.authoritative_final_orientation==before.player.orientation,letter+" PRESERVE authority")
		var samples:Array=[]
		var stages:Dictionary={"source":true}
		var gaps:Array=[]
		var horizontal:=0.0
		var descent:=0.0
		var previous_position:Vector3=body_before.origin
		var previous_screen:Vector2=source_screen
		var max_step:=0.0
		var monotone:=true
		var frame_count:=0
		var deadline:=Time.get_ticks_msec()+5000
		while lab.presenter.snapshot().phase!="IDLE" and Time.get_ticks_msec()<deadline:
			await process_frame
			await RenderingServer.frame_post_draw
			var view:Dictionary=lab.presenter.snapshot()
			var phase:String=view.phase
			var screen:Vector2=lab.camera.unproject_position(lab.actor.global_position)
			var item:Dictionary={"phase":phase,"elapsed":view.elapsed,"pose":visual_pose(lab.actor.transform),"screen":[screen.x,screen.y],"statekey":Key.build(baked.level,runtime.get_state()).key,"native_identity":view.transition_identity,"commits":runtime.get_commit_count()}
			if phase=="FALL":
				var motion:Dictionary=lab.presenter._fall.sample(view.elapsed)
				item.motion_phase=motion.phase
				item.progress=motion.progress
				max_step=maxf(max_step,lab.actor.position.distance_to(previous_position))
				if motion.phase=="DEPARTURE":
					horizontal=maxf(horizontal,absf(screen.x-source_screen.x))
					if not stages.has("departure") and horizontal>1.0:
						root.get_texture().get_image().save_png(evidence.path_join(letter+"_02_departure.png"))
						stages.departure=true
				if motion.phase=="FALL_MOVING":
					monotone=monotone and screen.y>=previous_screen.y-0.01
					descent=maxf(descent,screen.y-source_screen.y)
					if motion.progress>=0.55 and not stages.has("mid"):
						root.get_texture().get_image().save_png(evidence.path_join(letter+"_03_mid_descent.png"))
						stages.mid=true
					if motion.progress>=0.93 and not stages.has("pre_contact"):
						item.pre_contact_gap=support_gap(body,target)
						check(item.pre_contact_gap>0.0,letter+" approaches formal support from above before contact")
						root.get_texture().get_image().save_png(evidence.path_join(letter+"_04_pre_contact.png"))
						stages.pre_contact=true
			if phase=="LANDING":
				var gap:=support_gap(body,target)
				gaps.append(gap)
				item.support_gap=gap
				if not stages.has("contact"):
					check(runtime.get_commit_count()==1,letter+" contact follows real COMMITTED exactly once")
					root.get_texture().get_image().save_png(evidence.path_join(letter+"_05_yellow_contact.png"))
					stages.contact=true
			samples.append(item)
			previous_position=lab.actor.position
			previous_screen=screen
			frame_count+=1
		check(lab.presenter.snapshot().phase=="IDLE" and runtime.get_commit_count()==1,letter+" natural Fall plus Landing completion once")
		check(horizontal>1.0,letter+" visible forward departure")
		check(monotone and descent>10.0,letter+" entire rendered descent remains visually downward")
		check(frame_count>20 and max_step<0.6,letter+" continuous frames without position jumps")
		check(not gaps.is_empty() and gaps.all(func(g):return absf(g)<=0.0001),letter+" body contact preserved throughout compression/rebound")
		var landed:Dictionary=runtime.get_state()
		check(landed.player==started.target_pose and landed.player.orientation==before.player.orientation,letter+" exact target and preserved formal orientation")
		check(lab.actor.transform.is_equal_approx(lab.project_pose(landed.player).transform),letter+" neutral final Visual Pose matches target anchor")
		check(target.position2.y<source.position2.y if letter=="a" else target.position2.y>source.position2.y,letter+" required physical height direction")
		await shot(lab,letter+"_06_settled")
		stages.settled=true
		check(stages.size()==6,letter+" six real rendered trajectory stages")
		check(lab.host_issues.is_empty(),letter+" no Host integration errors")
		check(runtime.request_action({"kind":0,"face_axis":0}).status==0,letter+" real target U_POS Roll admitted with visible blue reference")
		deadline=Time.get_ticks_msec()+2000
		while lab.presenter.snapshot().phase!="IDLE" and Time.get_ticks_msec()<deadline: await process_frame
		check(Goal.is_goal(baked.level,runtime.get_state()).is_goal and runtime.get_commit_count()==2,letter+" real Fall Roll Goal")
		rows.append({"map":letter,"source_face":"source/TOP","source_anchor2":str(source.position2),"target_face":"target/TOP","target_anchor2":str(target.position2),"target_mesh":String(actual_target.get_path()),"blue_reference_mesh":String(blue_reference.get_path()),"actor_visual_root":String(lab.actor.get_path()),"actor_body_mesh":String(body.get_path()),"source_pose":before.player,"target_pose":landed.player,"camera":before.camera_quadrant,"action":result.action,"native_identity":started.transition_identity,"motion_profile_hash":started.motion_profile_hash,"safety":started.safety_verdict,"authorized_trajectory":started.authorized_trajectory,"final_statekey":Key.build(baked.level,landed).key,"goal_statekey":Key.build(baked.level,runtime.get_state()).key,"horizontal_pixels":horizontal,"descent_pixels":descent,"max_frame_displacement":max_step,"landing_support_gaps":gaps,"stages":stages,"samples":samples})
		bridge.free()
		await process_frame
	FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"task":"PFALL_TARGET_PLATFORM_AND_TRAJECTORY_FIX_01","checks":checks,"failures":failures,"doubles":[],"rows":rows,"viewport":[root.size.x,root.size.y],"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"user_data_dir":OS.get_user_data_dir(),"authority":"actual public Baker/Runtime/registered natural Presenter; native MOVE, per-frame real Mesh and support plane; no state mutation or synthetic completion"},"\t"))
	quit(0 if failures.is_empty() else 1)
