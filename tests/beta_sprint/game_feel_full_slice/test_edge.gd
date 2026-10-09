extends "res://tests/beta_sprint/ui_host_integration/test_host.gd"

func run() -> void:
	var shell: Node=load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	root.add_child(shell)
	await settle(0.2)
	shell.game_feel.launch_lab("a")
	await settle(0.2)
	var lab: Node=shell.adapter.level
	var before: Dictionary=lab.runtime.get_state()
	var pose: Transform3D=lab.actor.transform
	lab.runtime.request_action({"kind":0,"face_axis":0})
	check(lab.events[-1].semantic=="MOVE_REJECTED_EDGE","native Runtime explicitly rejects actual edge")
	check(lab.presenter.snapshot().phase=="EDGE","real edge event starts shared Presenter/10B")
	await settle(0.1)
	check(not lab.actor.transform.is_equal_approx(pose),"actual lean changes visual transform")
	check(lab.runtime.get_state()==before,"lean preserves full authoritative state and orientation")
	await settle(0.6)
	check(lab.presenter.snapshot().phase=="IDLE","natural recoil finishes")
	check(lab.actor.transform.is_equal_approx(pose),"neutral visual pose restored exactly")
	observations={"events":lab.events,"presenter":lab.presenter.snapshot(),"host_issues":lab.host_issues}
	shell.queue_free()
	await settle(0.2)
	finish()
