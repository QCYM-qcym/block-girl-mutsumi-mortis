extends "res://tests/beta_sprint/graphical_bridge_02/test_interrupt.gd"
func run()->void:
	check(DisplayServer.get_name()!="headless","actual renderer")
	for letter in ["a","b"]:
		for phase in ["FALL","LANDING"]:
			for reason in ["CANCEL","UNLOAD"]:
				var baked:Dictionary=Maps.bake_game_feel(Maps.read_spec(letter))
				var runtime:=Facade.new()
				runtime.load_level(baked.level)
				var bridge:=Bridge.new()
				root.add_child(bridge)
				bridge.bind_runtime(runtime,baked.level)
				var completed:Array=[]
				var cancelled:Array=[]
				bridge.motion_completed.connect(func(i,e):completed.append(i))
				bridge.motion_cancelled.connect(func(i,r):cancelled.append({"identity":i,"reason":r}))
				key(KEY_F)
				await wait_phase(bridge,phase)
				var old:Dictionary=bridge.lab.presenter.snapshot().transition_identity
				var committed:int=runtime.get_commit_count()
				runtime.interrupt(reason)
				await process_frame
				await process_frame
				check(cancelled.size()==1 and completed.is_empty(),letter+" "+phase+" native "+reason+" cancels only")
				check(not cancelled.is_empty() and cancelled[0].reason==reason,letter+" exact lifecycle reason retained")
				check(bridge.lab.presenter.snapshot().phase=="IDLE" and runtime.get_commit_count()==committed,letter+" native cancellation no extra commit/active visual")
				check(runtime.finish_transition(old).ignored,letter+" late captured finish cannot commit")
				if reason=="CANCEL":
					check(runtime.get_generation()!=old.generation,letter+" authoritative CANCEL advances generation")
					bridge.lab.reset_lab()
					key(KEY_F)
					await wait_phase(bridge,"FALL")
					await wait_until_idle(bridge,runtime)
					check(completed.size()==1 and runtime.get_commit_count()==1,letter+" real input restored after CANCEL")
				rows.append({"map":letter,"phase":phase,"reason":reason,"cancelled":cancelled,"snapshot":bridge.snapshot()})
				bridge.free()
		# A cancellation observer unloads synchronously during real Landing->Roll
		# preemption. The outer STARTED must never install an obsolete motion.
		var baked:Dictionary=Maps.bake_game_feel(Maps.read_spec(letter))
		var runtime:=Facade.new()
		runtime.load_level(baked.level)
		var bridge:=Bridge.new()
		root.add_child(bridge)
		bridge.bind_runtime(runtime,baked.level)
		key(KEY_F)
		await wait_phase(bridge,"LANDING")
		bridge.motion_cancelled.connect(func(_i,_r):runtime.interrupt("UNLOAD"),CONNECT_ONE_SHOT)
		key(KEY_D)
		await process_frame
		await process_frame
		check(not runtime.is_loaded() and bridge.lab.presenter.snapshot().phase=="IDLE",letter+" reentrant cancellation cannot install obsolete Roll")
		check(bridge.lab.host_issues.is_empty(),letter+" reentrant unload no stale projection")
		rows.append({"map":letter,"scope":"synchronous native unload on actual preemption","snapshot":bridge.snapshot()})
		bridge.free()
	FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"doubles":[],"rows":rows,"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"authority":"real default Facade cancel/unload + natural Landing; synchronous native cancellation observer; no synthetic completion"},"\t"))
	quit(0 if failures.is_empty() else 1)
