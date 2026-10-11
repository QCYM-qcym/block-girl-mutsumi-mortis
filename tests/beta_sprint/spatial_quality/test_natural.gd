extends "res://tests/beta_sprint/spatial_quality/suite.gd"
## Real Host input and natural Tween/Presenter completion only.
const Host = preload("res://experiments/spatial_puzzle_batch_01/host/spatial_lab.gd")
const Maps = preload("res://experiments/spatial_puzzle_batch_01/maps/map_factory.gd")
const Math = preload("res://foundation/orientation/discrete_orientation.gd")
const Geometry = preload("res://foundation/spatial/surface_geometry.gd")
const View = preload("res://foundation/game_feel/view_contract.gd")
const Key = preload("res://foundation/contracts/state_key.gd")
const Goal = preload("res://foundation/rules/goal_evaluator.gd")
const PREFIX := {&"world_shift_gate_lab":"gate",&"orientation_loop_lab":"loop",&"face_lock_lab":"lock",
	&"perspective_fork_lab":"fork",&"rubik_spatial_puzzle_01":"combined"}

func settle(host: Node) -> void:
	var until := Time.get_ticks_msec() + 5000
	while (not host.runtime.is_idle() or host.presenter.snapshot().phase != "IDLE") and Time.get_ticks_msec() < until:
		await process_frame
	await process_frame
	check(host.runtime.is_idle() and host.presenter.snapshot().phase == "IDLE", "natural completion returns to idle")

func pose(host: Node) -> void:
	var state: Dictionary = host.runtime.get_state()
	var columns := Math.columns(state.player.orientation)
	check(host.actor.basis.is_equal_approx(Basis(Vector3(columns[0]),Vector3(columns[1]),Vector3(columns[2]))), "six-face basis equals formal Orientation")
	var spatial := Geometry.snapshot(host.runtime.get_level(),state)
	check(spatial.ok,"formal support snapshot")
	if spatial.ok:
		var anchors: Array = spatial.value.anchors.filter(func(a):return a.layer == state.player.location.layer and a.face_id == Geometry.face_id(state.player.location.cube_id,state.player.location.face))
		check(anchors.size() == 1,"unique logical support")
		if anchors.size() == 1: check(host.actor.position.is_equal_approx(Vector3(anchors[0].position2 + anchors[0].frame.normal)*0.5),"rendered center matches formal support")
	check(host.actor.scale.is_equal_approx(Vector3.ONE),"no residual landing or Shift scale")
	check(host.camera.basis.is_equal_approx(View.basis(state.camera_quadrant)),"camera direction matches Runtime")

func shot(host: Node, name: String) -> void:
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(evidence.path_join(name + ".png")) == OK,"actual rendered screenshot recorded")
	rows.append({"case":current.id,"screenshot":name + ".png","state":host.runtime.get_state(),"statekey":Key.build(host.runtime.get_level(),host.runtime.get_state()).key,"visual_pose":host.actor.transform,"camera_pose":host.camera.transform})

func act(host: Node, action: Dictionary) -> void:
	var count: int = host.runtime.get_commit_count()
	var result: Dictionary = host.runtime.request_action(action)
	check(result.status == 0,"actual authored action accepted " + str(action))
	if result.status != 0: return
	await settle(host)
	check(host.runtime.get_state() == result.next_state,"natural commit matches exact accepted full state")
	check(host.runtime.get_commit_count() == count + (1 if result.changed else 0),"exactly one commit or explicit no-op")
	pose(host)

func key(code: int, pressed: bool, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	event.echo = echo
	Input.parse_input_event(event)

func tap(code: int) -> void:
	key(code,true)
	await process_frame
	key(code,false)
	await process_frame

func lifecycle(host: Node, id: StringName) -> void:
	begin(PREFIX[id] + ".lifecycle","NATURAL_GRAPHICAL")
	host.reset_lab()
	await process_frame
	var initial: Dictionary = host.runtime.get_state()
	# Test a real pending global Shift on gated maps, real local Fall/Roll otherwise.
	var pending := {"kind":0,"face_axis":2} if id == &"perspective_fork_lab" else {"kind":0,"face_axis":0}
	if id == &"world_shift_gate_lab":
		await act(host,{"kind":0,"face_axis":0})
		pending = {"kind":1}
	elif id in [&"face_lock_lab",&"rubik_spatial_puzzle_01"]:
		for action in [{"kind":0,"face_axis":3},{"kind":0,"face_axis":0},{"kind":0,"face_axis":1},{"kind":0,"face_axis":2}]: await act(host,action)
		pending = {"kind":1}
	var before: Dictionary = host.runtime.get_state()
	var commits: int = host.runtime.get_commit_count()
	var accepted: Dictionary = host.runtime.request_action(pending)
	check(accepted.status == 0 and accepted.changed and not host.runtime.is_idle(),"real pending animation exists")
	if accepted.status != 0 or not accepted.changed: return
	await process_frame
	await tap(KEY_ESCAPE)
	check(host.paused,"native Pause input handled")
	var frozen: Transform3D = host.actor.transform
	for frame in 12: await process_frame
	check(host.actor.transform.is_equal_approx(frozen) and host.runtime.get_state() == before and host.runtime.get_commit_count() == commits,"Pause freezes animation and authoritative commit")
	await tap(KEY_ESCAPE)
	check(not host.paused,"native Resume input handled")
	# Echoes and opposite movement while Busy cannot replace the actor transition.
	for code in [KEY_W,KEY_A,KEY_S,KEY_D,KEY_SPACE]:
		key(code,true,true)
		key(code,false)
	for code in [KEY_W,KEY_A,KEY_S,KEY_D,KEY_SPACE]:
		key(code,true)
		key(code,false)
	await process_frame
	check(host.runtime.get_state().player == before.player,"spam does not commit an extra physical candidate")
	await tap(KEY_R)
	check(host.runtime.get_state() == initial and host.runtime.get_commit_count() == 0 and host.runtime.is_idle(),"native Reset cancels pending action and restores full state")
	for frame in 45: await process_frame
	check(host.runtime.get_state() == initial and host.runtime.get_commit_count() == 0,"cancelled animation has no delayed commit or queued input")
	pose(host)
	# Q/E are real input; one complete roundtrip preserves physical state.
	await tap(KEY_E)
	await settle(host)
	await tap(KEY_Q)
	await settle(host)
	check(host.runtime.get_state() == initial,"native camera roundtrip preserves player World and Orientation")
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(30,-20)
	Input.parse_input_event(motion)
	await process_frame
	check(host.runtime.get_state() == initial,"mouse motion cannot mutate logical state")
	host.set_reduced_motion(true)
	await act(host,{"kind":0,"face_axis":2} if id == &"perspective_fork_lab" else {"kind":0,"face_axis":0})
	host.set_reduced_motion(false)
	await tap(KEY_R)
	pose(host)
	await shot(host,PREFIX[id] + "_reset")
	# Keep a real physical key pressed through completion, with actual Busy
	# repeats/opposite input. No Reset may conceal a drained queue in this case.
	var proposals: Array = []
	var listener: Callable = func(result,token,generation,global): proposals.append({"result":result.duplicate(true),"token":token,"generation":generation,"global":global})
	host.runtime.transition_started.connect(listener)
	var held_code: int = KEY_F if id == &"perspective_fork_lab" else (KEY_D if id == &"orientation_loop_lab" else KEY_W)
	var held_commits: int = host.runtime.get_commit_count()
	key(held_code,true)
	await process_frame
	check(proposals.size() == 1,"native held key starts one real transition")
	for frame in 3:
		key(held_code,true,true)
		key(KEY_S,true)
		key(KEY_S,false)
		await process_frame
	check(Input.is_physical_key_pressed(held_code),"physical key remains held across actual frames")
	await settle(host)
	for frame in 12:
		key(held_code,true,true)
		await process_frame
	key(held_code,false)
	for frame in 12: await process_frame
	check(proposals.size() == 1 and host.runtime.get_commit_count() == held_commits+1,"held echoes and Busy spam do not drain extra actions after natural completion")
	if proposals.size() == 1:
		check(host.runtime.get_state() == proposals[0].result.next_state,"held-input final full state equals the original accepted candidate")
	pose(host)
	rows.append({"coverage":"held_input_natural_completion","map":PREFIX[id],"proposals":proposals.duplicate(true),"commits":host.runtime.get_commit_count(),"completion":"natural; no intervening Reset"})
	host.runtime.transition_started.disconnect(listener)
	await tap(KEY_R)
	# A second pending transition dies with the actual Host scene.
	var runtime: RefCounted = host.runtime
	var exit_starts: Array = []
	var observed: WeakRef = weakref(runtime)
	runtime.transition_started.connect(func(result,token,generation,global):
		var live: RefCounted = observed.get_ref()
		if live != null: exit_starts.append(live.get_pending_identity(token,generation,global)))
	var result: Dictionary = runtime.request_action({"kind":0,"face_axis":2} if id == &"perspective_fork_lab" else {"kind":0,"face_axis":0})
	check(result.status == 0 and result.changed and exit_starts.size() == 1 and not runtime.is_idle(),"fresh pending identity exists immediately before Host exit")
	var exit_commits: int = runtime.get_commit_count()
	host.free()
	for frame in 45: await process_frame
	check(runtime.get_commit_count() == exit_commits,"scene exit retires pending animation without delayed commit")
	check(not runtime.is_loaded(),"Host exit unloads the actual Runtime session")
	if exit_starts.size() == 1:
		var identity: Dictionary = exit_starts[0]
		check(runtime.get_pending_identity(identity.transaction_id,identity.generation,identity.is_global).is_empty(),"Host exit retires the formerly live native identity without completion injection")
	runtime = null

func run() -> void:
	root.size = Vector2i(1280,720)
	var selected := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--map="): selected = arg.trim_prefix("--map=")
	for id in Maps.ids():
		if not selected.is_empty() and String(id) != selected: continue
		begin(PREFIX[id] + ".natural_pose","NATURAL_GRAPHICAL")
		check(DisplayServer.get_name() == "Windows","actual Windows renderer")
		var host := Host.new()
		host.lab_id = id
		root.add_child(host)
		await process_frame
		check(host.runtime.is_loaded() and host.host_issues.is_empty(),"real Host loads real Map and Runtime")
		if not host.runtime.is_loaded(): host.free(); continue
		check(host.actor.get_node("LocalFaceMarks").get_child_count() == 6,"six physical local faces remain visible")
		pose(host)
		await shot(host,PREFIX[id] + "_spawn")
		var initial: Dictionary = host.runtime.get_state()
		var witnesses: Dictionary = Maps.witnesses(id)
		for name in witnesses:
			if not String(name).begins_with("solution"): continue
			host.reset_lab()
			check(host.runtime.get_state() == initial,"route Reset restores exact origin")
			for action in witnesses[name]: await act(host,action)
			check(Goal.is_goal(host.runtime.get_level(),host.runtime.get_state()).is_goal,"actual route reaches Goal " + String(name))
			await shot(host,PREFIX[id] + "_" + String(name))
		check(host.host_issues.is_empty(),"no Host issues on authored routes")
		await lifecycle(host,id)
	finish()
