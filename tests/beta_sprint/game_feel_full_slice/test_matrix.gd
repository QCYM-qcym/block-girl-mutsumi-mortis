extends "res://tests/beta_sprint/ui_host_integration/test_matrix.gd"
const Key=preload("res://foundation/contracts/state_key.gd")
const Goal=preload("res://foundation/rules/goal_evaluator.gd")
var _extra := false
var routes: Array=[]

func finish() -> void:
	if not _extra:
		_extra=true
		extra_routes.call_deferred()
	else:
		observations["renderer"]=RenderingServer.get_current_rendering_method()
		super.finish()

func press(code: int, down: bool=true, echo: bool=false) -> void:
	var event:=InputEventKey.new()
	event.keycode=code;event.physical_keycode=code;event.pressed=down;event.echo=echo
	Input.parse_input_event(event)
	native_inputs.append({"key":code,"pressed":down,"echo":echo})

func state_key(lab: Node) -> String:
	return Key.build(lab.runtime.get_level(),lab.runtime.get_state()).key

func extra_routes() -> void:
	var shell: Node=load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	root.add_child(shell);await settle(0.3)
	root.mode=Window.MODE_WINDOWED;root.size=requested;await settle(0.3)
	var bridge: Node=shell.game_feel
	for reduced in [false,true]:
		shell.open_settings();await process_frame
		bridge.ui.buttons.reduced_motion.button_pressed=reduced
		shell.save_settings();await process_frame
		for letter in ["a","b"]:
			bridge.launch_lab(letter);await settle(0.2)
			var lab: Node=shell.adapter.level
			var source_key:=state_key(lab)
			var source_pose: Transform3D=lab.actor.transform
			var source_orientation: int=lab.runtime.get_state().player.orientation
			check(lab.presenter.reduced_motion_enabled()==reduced,"actual saved option reaches10A/10B")
			press(KEY_D);await settle(0.09)
			check(lab.events[-1].semantic=="MOVE_REJECTED_EDGE","native key -> native EDGE only")
			check(not bridge.ui.feedback_panel.visible,"edge has animation/audio feedback without duplicate text")
			check(bridge.audio.snapshot().cue_counts.get("edge_recoil",0)>0,"real Edge Blocked audio loaded and played")
			check(lab.presenter.snapshot().phase=="EDGE","real10B in shared single writer")
			check(lab.actor.transform.is_equal_approx(source_pose)==reduced,"normal lean visible; Reduced Motion neutral")
			check(state_key(lab)==source_key and lab.runtime.get_state().player.orientation==source_orientation,"EDGE preserves StateKey and orientation")
			await capture("edge_%s_%s"%[letter,str(reduced)])
			var elapsed: float=lab.presenter.snapshot().elapsed
			for index in 80: press(KEY_D,true,true)
			lab.runtime.request_action({"kind":0,"face_axis":0})
			check(lab.presenter.snapshot().elapsed>=elapsed,"held repeat retains current progress")
			await settle(0.6)
			lab.runtime.request_action({"kind":0,"face_axis":0})
			check(lab.presenter.snapshot().phase=="IDLE" and lab.actor.transform.is_equal_approx(source_pose),"held repeat after recoil stays neutral")
			press(KEY_D,false);await process_frame
			press(KEY_D);await settle(0.07)
			check(lab.presenter.snapshot().phase=="EDGE","native release rearms10B")
			var retired: Dictionary=lab.events[-1].duplicate(true)
			await key(KEY_R)
			check(lab.presenter.snapshot().phase=="IDLE" and lab.actor.transform.is_equal_approx(source_pose),"Reset cancels lean and restores transform")
			lab.presenter.consume_event(retired)
			check(lab.presenter.snapshot().phase=="IDLE" and state_key(lab)==source_key,"old generation callback ignored")
			press(KEY_D,false);await process_frame
			press(KEY_D);await settle(0.07)
			var impacts: int=bridge.audio.snapshot().cue_counts.get("landing_impact",0)
			await key(KEY_F)
			check(lab.presenter.snapshot().phase=="FALL","formal Fall preempts real lean")
			check(bridge.audio.snapshot().cue_counts.get("landing_impact",0)==impacts,"STARTED never plays Landing Impact")
			check(bridge.ui.feedback_panel.visible,"real Fall HUD without edge popup")
			await key(KEY_ESCAPE)
			var frozen: Transform3D=lab.actor.transform
			await settle(0.16)
			check(lab.actor.transform.is_equal_approx(frozen) and bridge.audio.snapshot().paused,"Pause holds actual actor and audio")
			await key(KEY_ESCAPE)
			await settle(1.8)
			press(KEY_D,false);await process_frame
			var target_key:=state_key(lab)
			check(lab.runtime.get_state().player.location.cube_id==&"target" and lab.presenter.snapshot().phase=="IDLE","natural Fall/Landing -> native target")
			check(lab.actor.transform.is_equal_approx(lab.project_pose(lab.runtime.get_state().player).transform),"Landing neutral pose equals formal projection")
			check(lab.runtime.get_state().player.orientation==source_orientation,"Fall authoritative orientation retained")
			check(bridge.audio.snapshot().cue_counts.get("landing_impact",0)==impacts+1,"only real COMMITTED delivers one Landing Impact")
			check(not bridge.ui.feedback_panel.visible,"matching commit clears Fall HUD")
			await capture("landing_%s_%s"%[letter,str(reduced)])
			lab.runtime.request_action({"kind":0,"face_axis":1});await settle(0.07)
			check(lab.presenter.snapshot().phase=="EDGE","target edge has native refusal")
			var rolls: int=bridge.audio.snapshot().cue_counts.get("cube_roll",0)
			var goals: int=bridge.audio.snapshot().cue_counts.get("goal",0)
			await key(KEY_D)
			check(lab.presenter.snapshot().phase=="ROLL","formal Roll preempts lean")
			await settle(0.5)
			check(Goal.is_goal(lab.runtime.get_level(),lab.runtime.get_state()).is_goal,"native Fall -> Roll -> Goal")
			check(lab.runtime.get_state().player.orientation==12,"ordinary Roll changes orientation by native rule")
			check(lab.presenter.snapshot().phase=="IDLE" and lab.host_issues.is_empty(),"one writer has no lifecycle issue")
			check(bridge.audio.snapshot().cue_counts.get("cube_roll",0)==rolls+1 and bridge.audio.snapshot().cue_counts.get("goal",0)==goals+1,"one native Roll and one formal Goal audio")
			await capture("goal_%s_%s"%[letter,str(reduced)])
			var final_key:=state_key(lab)
			routes.append({"map":letter,"reduced_motion":reduced,"source":source_key,"target":target_key,"goal":final_key,"orientation":lab.runtime.get_state().player.orientation,"audio":bridge.audio.snapshot()})
			await key(KEY_R)
			check(state_key(lab)==source_key,"Reset restores formal start")
			await key(KEY_F);await settle(1.8);await key(KEY_D);await settle(0.5)
			check(state_key(lab)==final_key,"Reset route repeats exact final StateKey")
			await key(KEY_R)
			await key(KEY_Q);await settle(0.35)
			await key(KEY_F)
			check(lab.runtime.is_idle() and state_key(lab)!=target_key and lab.presenter.snapshot().phase=="IDLE","illegal Camera cannot trigger Fall or lean")
			await key(KEY_R)
			await key(KEY_F);await settle(0.08);await key(KEY_R)
			check(lab.presenter.snapshot().phase=="IDLE" and state_key(lab)==source_key,"Reset cancels actual active Fall")
			await capture("reset_%s_%s"%[letter,str(reduced)])
	for index in 2:
		check(routes[index].source==routes[index+2].source and routes[index].target==routes[index+2].target and routes[index].goal==routes[index+2].goal,"Normal/Reduced complete StateKey parity "+str(index))
	shell.show_main_menu();await settle(0.2)
	check(bridge.audio.snapshot().context=="menu" and shell.adapter.level==null,"full slice returns through real Shell")
	observations={"requested":[requested.x,requested.y],"captures":captures,"native_inputs":native_inputs,"routes":routes,"runtime_readiness":"PENDING_RUNTIME_INTERFACE","graphical_trace_replayer":"PENDING separate formal case"}
	shell.queue_free();await settle(0.2);finish()
