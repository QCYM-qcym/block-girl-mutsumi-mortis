extends "res://tests/beta_sprint/graphical_bridge_02/test_bridge.gd"
## Native keyboard, held/echo input, cancellation and four-camera permissions.
const Goal=preload("res://foundation/rules/goal_evaluator.gd")
var native_inputs:Array=[]

func input_key(code:int,pressed:bool=true,echo:bool=false)->void:
	var event:=InputEventKey.new()
	event.keycode=code
	event.physical_keycode=code
	event.pressed=pressed
	event.echo=echo
	Input.parse_input_event(event)
	native_inputs.append({"key":code,"pressed":pressed,"echo":echo})

func press_key(code:int)->void:
	input_key(code)
	input_key(code,false)

func wait_idle(bridge:Node,runtime:RefCounted)->void:
	var deadline:=Time.get_ticks_msec()+4000
	while (not runtime.is_idle() or bridge.lab.presenter.snapshot().phase!="IDLE") and Time.get_ticks_msec()<deadline: await process_frame
	check(runtime.is_idle() and bridge.lab.presenter.snapshot().phase=="IDLE","natural native completion before next action")

func run()->void:
	check(DisplayServer.get_name()!="headless","actual renderer")
	for letter in ["a","b"]:
		var baked:Dictionary=Maps.bake_game_feel(Maps.read_spec(letter))
		check(baked.ok and baked.level.schema_version==3,letter+" real new-profile Baker")
		if not baked.ok or baked.level.schema_version!=3: continue
		var runtime:=Facade.new()
		check(runtime.load_level(baked.level).ok,letter+" same authoritative Runtime")
		var bridge:=Bridge.new()
		root.add_child(bridge)
		check(bridge.bind_runtime(runtime,baked.level).ok,letter+" real Presenter binding")
		var lab:Node3D=bridge.lab
		var source:Dictionary=runtime.get_state()
		var source_key:String=Key.build(baked.level,source).key
		var completed:Array=[]
		var cancelled:Array=[]
		bridge.motion_completed.connect(func(id,ev):completed.append({"identity":id,"evidence":ev}))
		bridge.motion_cancelled.connect(func(id,reason):cancelled.append({"identity":id,"reason":reason}))
		input_key(KEY_A)
		await process_frame
		check(lab.presenter.snapshot().phase=="FALL",letter+" actual held movement key starts formal Fall")
		var old:Dictionary=lab.presenter.snapshot().transition_identity
		for index in 80: input_key(KEY_A,true,true)
		check(runtime.request_action({"kind":0,"face_axis":2}).status!=0,letter+" active native Fall rejects repeated action Busy")
		await wait_idle(bridge,runtime)
		for index in 80: input_key(KEY_A,true,true)
		await process_frame
		check(runtime.get_commit_count()==1 and completed.size()==1 and cancelled.is_empty(),letter+" held key cannot repeat Fall before or after completion")
		check(runtime.get_state().player.location.cube_id==&"target" and lab.presenter.snapshot().phase=="IDLE",letter+" held target remains exact with no queued action")
		input_key(KEY_A,false)
		press_key(KEY_R)
		await process_frame
		check(runtime.get_state()==source and Key.build(baked.level,runtime.get_state()).key==source_key,letter+" native Reset exact source StateKey")
		press_key(KEY_A)
		await process_frame
		old=lab.presenter.snapshot().transition_identity
		check(not old.is_empty(),letter+" new actual Fall identity before Reset")
		press_key(KEY_R)
		await process_frame
		check(cancelled.size()==1 and completed.size()==1 and runtime.get_commit_count()==0,letter+" Reset cancels distinct from natural completion")
		check(lab.actor.transform.is_equal_approx(lab.project_pose(source.player).transform) and runtime.get_state()==source,letter+" Reset neutral Visual Root and unchanged orientation")
		check(runtime.finish_transition(old).ignored,letter+" stale native callback is rejected (negative probe only)")
		check(lab.events.any(func(e):return e.semantic=="ANIMATION_INTERRUPTED" and e.schema_version==2 and e.contract_version=="game_feel.event.v2"),letter+" curve cancellation preserves event.v2")
		var cameras:Array=[]
		for quadrant in 4:
			var actual:int=runtime.get_state().camera_quadrant
			var before_camera:Dictionary=runtime.get_state()
			var count:int=runtime.get_commit_count()
			if actual!=1:
				var rejected:Dictionary=runtime.request_action({"kind":8,"connection_id":StringName("pfall_"+letter)})
				check(rejected.status!=0 and not rejected.changed and runtime.get_state()==before_camera and runtime.get_commit_count()==count,letter+" illegal Camera "+str(actual)+" rejects actual Fall without state change")
				check(lab.presenter.snapshot().phase=="IDLE",letter+" illegal Camera never animates")
				cameras.append({"camera":actual,"result":rejected})
			press_key(KEY_E)
			await wait_idle(bridge,runtime)
		check(cameras.size()==3 and runtime.get_state().camera_quadrant==1,letter+" all three illegal quadrants and legal EAST return")
		press_key(KEY_A)
		await wait_idle(bridge,runtime)
		press_key(KEY_D)
		await wait_idle(bridge,runtime)
		check(Goal.is_goal(baked.level,runtime.get_state()).is_goal,letter+" real input usable after Reset and Camera route to Goal")
		check(lab.host_issues.is_empty(),letter+" no lifecycle Host error")
		rows.append({"map":letter,"source_statekey":source_key,"camera_rejections":cameras,"completed":completed,"cancelled":cancelled,"events":lab.events,"final_statekey":Key.build(baked.level,runtime.get_state()).key,"snapshot":bridge.snapshot()})
		bridge.free()
		await process_frame
	FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"task":"PFALL_TARGET_PLATFORM_AND_TRAJECTORY_FIX_01","checks":checks,"failures":failures,"doubles":[],"rows":rows,"native_inputs":native_inputs,"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"user_data_dir":OS.get_user_data_dir(),"authority":"native Input.parse_input_event, true formal Facade and actual registered natural Presenter; old finish only used as rejected negative callback probe"},"\t"))
	quit(0 if failures.is_empty() else 1)
