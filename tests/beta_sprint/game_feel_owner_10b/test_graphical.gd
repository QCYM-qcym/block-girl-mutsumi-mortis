extends SceneTree
const Lab = preload("res://tests/beta_sprint/game_feel_owner_10b/lab_view.gd")
const Fixture = preload("res://tests/beta_sprint/game_feel_owner_10b/fixture.gd")
var lab: Node3D
var evidence := ""
var checks := 0
var failures: Array[String] = []
var shots: Array = []

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="): evidence = arg.trim_prefix("--evidence-dir=")
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code; event.pressed = pressed
	root.push_input(event)

func delay(seconds: float) -> void:
	await create_timer(seconds).timeout

func wait_phase(wanted: String) -> void:
	var deadline := Time.get_ticks_msec() + 700
	while lab.last_sample.phase != wanted and Time.get_ticks_msec() < deadline:
		await process_frame
	check(lab.last_sample.phase == wanted, "naturally observed " + wanted)

func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var path := evidence.path_join(name + ".png")
	var result := root.get_texture().get_image().save_png(path)
	check(result == OK, "rendered capture " + name)
	shots.append({"name": name, "path": path, "phase": lab.last_sample.phase, "angle": lab.last_sample.rotation_offset.get_angle(),
		"world": lab.world, "camera": lab.quadrant, "formal_orientation": lab.orientation})

func run() -> void:
	root.size = Vector2i(920,740)
	lab = Lab.new(); root.add_child(lab)
	check(DisplayServer.get_name() != "headless", "actual rendered display")
	await delay(0.2)
	for world in range(2):
		for view in range(4):
			lab.configure(world,view,0)
			await shot("w%d_q%d_initial" % [world,view])
			var before: int = lab.cues.size()
			key(KEY_W,true)
			await delay(0.07)
			check(lab.last_sample.active and lab.last_sample.rotation_offset.get_angle() > 0.03,"mapped natural lean w%d q%d" % [world,view])
			await shot("w%d_q%d_lean" % [world,view])
			await wait_phase("BLOCKED")
			await shot("w%d_q%d_blocked" % [world,view])
			await wait_phase("RECOIL")
			check(lab.last_sample.phase == "RECOIL","natural return w%d q%d" % [world,view])
			await shot("w%d_q%d_recoil" % [world,view])
			await delay(0.4)
			check(lab.actor.transform.is_equal_approx(lab.base) and lab.last_sample.rotation_offset == Quaternion.IDENTITY,"exact final Pose w%d q%d" % [world,view])
			check(lab.cues.size() == before + 3,"hold no replay w%d q%d" % [world,view])
			await shot("w%d_q%d_rest" % [world,view])
			key(KEY_W,false)
	lab.configure(0,0,0)
	var hold_cues: int = lab.cues.size()
	key(KEY_D,true); await delay(2.0)
	check(lab.cues.size() == hold_cues + 3 and not lab.last_sample.active, "two-second hold one cycle under frame retries")
	key(KEY_D,false)
	# Native opposite-key and pause/preemption lifecycle in the rendered Unit lab.
	lab.configure(0,0,7)
	key(KEY_D,true); await delay(0.07)
	key(KEY_A,true); await delay(0.1)
	check((Basis(lab.last_sample.rotation_offset)*Vector3.UP).x < 0,"sudden opposite key uses -X")
	await shot("opposite")
	key(KEY_A,false); key(KEY_D,false)
	await delay(0.5)
	lab.configure(1,1,19)
	key(KEY_W,true); await delay(0.06)
	lab.paused = true
	var frozen: Transform3D = lab.actor.transform
	await delay(0.3)
	check(lab.actor.transform == frozen,"pause preserves exact in-flight visual Pose")
	lab.paused = false; await delay(0.06)
	check(lab.actor.transform != frozen,"resume continues existing motion")
	lab.preempt()
	check(lab.actor.transform.is_equal_approx(lab.base),"successful-motion preemption port neutral (Unit only)")
	await shot("preempted")
	for time in [0.05,0.145,0.25]:
		lab.configure(0,2,12)
		key(KEY_W,true); await delay(time)
		lab.configure(0,2,12)
		check(lab.actor.transform.is_equal_approx(lab.base),"Reset/clear phase %.3f" % time)
		key(KEY_W,false)
	await shot("reset")
	var samples: Array = lab.samples.duplicate(true)
	var inputs: Array = lab.inputs.duplicate(true)
	var cues: Array = lab.cues.duplicate(true)
	root.remove_child(lab); lab.free()
	await process_frame
	var report := Fixture.META.duplicate(true)
	report.merge({"checks":checks,"failures":failures,"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),
		"engine":Engine.get_version_info(),"pid":OS.get_process_id(),"user_data_dir":OS.get_user_data_dir(),"shots":shots,
		"natural_samples":samples,"inputs":inputs,"cues":cues,"formal_runtime_cases":{"status":"case_pending","checks":0,"reason":"01 event facade and 00 sole-writer host not delivered on contract baseline"}})
	var file := FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print("EDGE_RENDERED_UNIT checks=%d failures=%d captures=%d natural_samples=%d" % [checks,failures.size(),shots.size(),samples.size()])
	for failure in failures: print("FAIL: ",failure)
	quit(0 if failures.is_empty() else 1)
