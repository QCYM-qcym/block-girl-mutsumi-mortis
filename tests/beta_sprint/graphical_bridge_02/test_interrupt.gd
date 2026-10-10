extends "res://tests/beta_sprint/graphical_bridge_02/test_bridge.gd"
func key(code:int)->void:
	for pressed in [true,false]:
		var event:=InputEventKey.new()
		event.physical_keycode=code
		event.pressed=pressed
		Input.parse_input_event(event)
func wait_phase(bridge:Node,phase:String)->void:
	var start:=Time.get_ticks_msec()
	while bridge.lab.presenter.snapshot().phase!=phase and Time.get_ticks_msec()-start<4000: await process_frame
	check(bridge.lab.presenter.snapshot().phase==phase,"real phase "+phase)
func run()->void:
	check(DisplayServer.get_name()!="headless","actual renderer")
	for letter in ["a","b"]:
		for phase in ["FALL","LANDING"]:
			var baked:Dictionary=Maps.bake_game_feel(Maps.read_spec(letter))
			var runtime:=Facade.new()
			runtime.load_level(baked.level)
			var bridge:=Bridge.new()
			root.add_child(bridge)
			bridge.bind_runtime(runtime,baked.level)
			var completed:Array=[]
			var cancelled:Array=[]
			bridge.motion_completed.connect(func(i,e):completed.append({"identity":i,"evidence":e}))
			bridge.motion_cancelled.connect(func(i,r):cancelled.append({"identity":i,"reason":r}))
			var initial:Dictionary=runtime.get_state()
			var initial_key:String=Key.build(baked.level,initial).key
			key(KEY_F)
			await wait_phase(bridge,phase)
			var old:Dictionary=bridge.lab.presenter.snapshot().transition_identity
			if phase=="FALL":
				for iteration in 6:
					for code in [KEY_W,KEY_A,KEY_S,KEY_D,KEY_Q,KEY_E,KEY_SPACE,KEY_F]: key(code)
				await process_frame
				check(runtime.get_state()==initial and runtime.get_commit_count()==0,letter+" native WASD Camera WorldShift repeatedFall BUSY")
				check(bridge.lab.presenter.snapshot().transition_identity==old,letter+" input cannot retarget captured identity")
				check(bridge.lab.events.any(func(e):return e.result.action.get("kind")==1 and e.result.status==1),letter+" Space really requests formal WorldShift rejection")
			key(KEY_R)
			await process_frame
			check(cancelled.size()==1 and completed.is_empty(),letter+" "+phase+" Reset has cancellation only")
			check(bridge.lab.presenter.snapshot().phase=="IDLE" and runtime.get_state()==initial and runtime.get_commit_count()==0,letter+" Reset restores formal source")
			check(Key.build(baked.level,runtime.get_state()).key==initial_key and bridge.lab.actor.transform.is_equal_approx(bridge.lab.project_pose(initial.player).transform),letter+" Reset exact StateKey and VisualRoot")
			check(runtime.finish_transition(old).ignored,letter+" captured old native finish rejected (negative only)")
			key(KEY_F)
			await wait_phase(bridge,"FALL")
			await wait_until_idle(bridge,runtime)
			check(completed.size()==1 and cancelled.size()==1 and runtime.get_commit_count()==1,letter+" fresh scope completes exactly once")
			check(not completed.is_empty() and completed[0].identity.generation!=old.generation and completed[0].identity.session_id==old.session_id,letter+" canonical identity new generation same session")
			key(KEY_D)
			await wait_phase(bridge,"ROLL")
			await wait_until_idle(bridge,runtime)
			check(completed.size()==2 and runtime.get_commit_count()==2,letter+" input remains usable after Reset")
			rows.append({"map":letter,"phase":phase,"completed":completed,"cancelled":cancelled,"snapshot":bridge.snapshot()})
			bridge.free()
		# Actual scene exit mid-motion: no completion may appear after teardown.
		for phase in ["FALL","LANDING"]:
			var baked:Dictionary=Maps.bake_game_feel(Maps.read_spec(letter))
			var runtime:=Facade.new()
			runtime.load_level(baked.level)
			var bridge:=Bridge.new()
			root.add_child(bridge)
			bridge.bind_runtime(runtime,baked.level)
			var completed:Array=[]
			var cancelled:Array=[]
			bridge.motion_completed.connect(func(i,e):completed.append(i))
			bridge.motion_cancelled.connect(func(i,r):cancelled.append(i))
			key(KEY_F)
			await wait_phase(bridge,phase)
			var before:int=runtime.get_commit_count()
			root.remove_child(bridge)
			await process_frame
			check(cancelled.size()==1 and completed.is_empty() and not runtime.is_loaded(),letter+" "+phase+" exit cancels distinct from completion")
			check(runtime.get_commit_count()==before and bridge.lab.presenter.snapshot().phase=="IDLE",letter+" exit cannot duplicate commit or leave active animation")
			bridge.free()
	FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"doubles":[],"rows":rows,"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"input":"real Input.parse_input_event to Host; old native finish used only as negative stale-callback probe","authority":"real formal Runtime and natural10A, real Reset and scene removal, no fake positive completion"},"\t"))
	quit(0 if failures.is_empty() else 1)
