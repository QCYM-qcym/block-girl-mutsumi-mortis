extends "res://tests/beta_sprint/game_feel_full_slice/test_audio.gd"
const Goal=preload("res://foundation/rules/goal_evaluator.gd")
func run() -> void:
	var shell: Node=load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	root.add_child(shell);await settle(0.2)
	var bridge: Node=shell.game_feel
	bridge.launch_lab("a");await settle(0.2)
	var lab: Node=shell.adapter.level
	for attempt in 2:
		native_key(KEY_F,true);await process_frame;native_key(KEY_F,false);await settle(1.8)
		native_key(KEY_D,true);await process_frame;native_key(KEY_D,false);await settle(0.5)
		check(Goal.is_goal(lab.runtime.get_level(),lab.runtime.get_state()).is_goal,"real native Goal "+str(attempt))
		check(bridge.audio.snapshot().cue_counts.get("goal",0)==attempt+1,"one real Goal cue per generation")
		check(bridge.audio.snapshot().cue_counts.get("fall_start",0)==attempt+1 and bridge.audio.snapshot().cue_counts.get("landing_impact",0)==attempt+1,"native Fall audio survives Reset generation")
		check("实验完成" in bridge.ui.input_label.text,"actual Goal has visible approved HUD hint")
		shell.pause_game();await process_frame
		check(bridge.audio.snapshot().paused and bridge.audio.snapshot().context=="none","Pause preserves completion music context")
		shell.resume_game();await process_frame
		check(not bridge.audio.snapshot().paused and bridge.audio.snapshot().context=="none","Resume preserves same completion context")
		lab.reset_level();await process_frame
		check(not "实验完成" in bridge.ui.input_label.text,"Reset retires completion hint")
		check(bridge.audio.snapshot().context=="exploration" and not "music:complete" in bridge.audio.snapshot().playing,"Reset retires completion voice and resumes exploration")
	observations={"audio":bridge.audio.snapshot(),"progress":shell.progress,"scope":"Native Fall/Roll/Goal, no progress/unlock mutation"}
	shell.queue_free();await settle(0.2);finish()
