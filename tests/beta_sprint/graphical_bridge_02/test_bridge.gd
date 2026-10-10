extends "res://tests/beta_sprint/graphical_bridge_02/test_formal.gd"
const Facade=preload("res://foundation/game_feel/runtime_facade.gd")
const Bridge=preload("res://game/feel/graphical_completion_bridge.gd")
const Key=preload("res://foundation/contracts/state_key.gd")
func wait_until_idle(bridge:Node,runtime:RefCounted)->void:
	await process_frame
	var started:=Time.get_ticks_msec()
	while (not runtime.is_idle() or bridge.lab.presenter.snapshot().phase!="IDLE") and Time.get_ticks_msec()-started<4000:
		await process_frame
func run()->void:
	check(DisplayServer.get_name()!="headless","actual renderer")
	for letter in ["a","b"]:
		var baked:Dictionary=Maps.bake_game_feel(Maps.read_spec(letter))
		var runtime:=Facade.new()
		check(runtime.load_level(baked.level).ok,letter+" real Facade")
		var bridge:=Bridge.new()
		root.add_child(bridge)
		check(bridge.bind_runtime(runtime,baked.level).ok,letter+" real registered Bridge")
		var completed:Array=[]
		bridge.motion_completed.connect(func(identity,detail):completed.append({"identity":identity,"detail":detail}))
		var start:Dictionary=runtime.get_state()
		var accepted:Dictionary=runtime.request_action({"kind":8,"connection_id":StringName("pfall_"+letter)})
		check(accepted.status==0 and accepted.changed,letter+" formal Fall accepted")
		await wait_until_idle(bridge,runtime)
		check(completed.size()==1,letter+" exactly one naturally settled completion")
		if completed.size()==1:
			var row:Dictionary=completed[0].detail
			check(row.started_order<row.committed_order and row.committed_order<row.completion_order,letter+" actual STARTED then COMMITTED then Landing settled")
			check(row.terminal.terminal_phase=="LANDING_SETTLED" and row.orientation==start.player.orientation,letter+" Fall natural endpoint preserves orientation")
			check(row.final_state==accepted.next_state and row.final_visual_pose==row.expected_visual_pose,letter+" formal state and physical final pose")
			check(row.frames.size()>10 and row.frames.any(func(f):return f.phase=="FALL") and row.frames.any(func(f):return f.phase=="LANDING"),letter+" actual motion frames sampled")
		var roll:Dictionary=runtime.request_action({"kind":0,"face_axis":0})
		await wait_until_idle(bridge,runtime)
		check(roll.status==0 and runtime.get_state()==roll.next_state and completed.size()==2,letter+" actual Roll to Goal completion")
		rows.append(bridge.snapshot())
		bridge.free()
	FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"doubles":[],"rows":rows,"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"authority":"Real default Facade, real registered production Bridge/CoreLab/10A sampler; no manual finish or synthetic events"},"\t"))
	quit(0 if failures.is_empty() else 1)
