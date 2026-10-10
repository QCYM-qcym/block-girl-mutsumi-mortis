extends SceneTree
## Actual native engine input routing; no Runtime action/completion or pose writes.
const Gate = preload("res://tests/beta_sprint/game_feel_owner_03/yellow_target_gate.gd")
const Lab = preload("res://experiments/game_feel_01/host/core_lab.tscn")
const Mapper = preload("res://foundation/runtime/input_mapper.gd")
const Geometry = preload("res://foundation/spatial/surface_geometry.gd")
const View = preload("res://foundation/game_feel/view_contract.gd")
const Key = preload("res://foundation/contracts/state_key.gd")
var checks := 0
var failures: Array[String] = []
var rows: Array = []
var evidence := ""

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): evidence = arg.trim_prefix("--evidence=")
	call_deferred("run")

func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func key(code: int, down: bool, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = down
	event.echo = echo
	Input.parse_input_event(event)

func wait_idle(host: Node) -> void:
	var deadline := Time.get_ticks_msec() + 4500
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if host.presenter.snapshot().phase == "IDLE" and host.runtime.is_idle(): return
	check(false,"bounded actual natural input completion")

func run() -> void:
	if Gate.blocked(self,evidence): return
	check(DisplayServer.get_name() == "Windows","actual native input renderer")
	var host: Node = Lab.instantiate()
	root.add_child(host)
	await process_frame
	for letter in ["a","b"]:
		host.load_map(letter)
		await process_frame
		var level: Dictionary = host.runtime.get_level()
		check(level.get("schema_version") == 3 and level.get("contract_version") == "foundation.game_feel.v2",letter + " no old profile held-input proof")
		var initial: Dictionary = host.runtime.get_state()
		var source_key: String = Key.build(level,initial).key
		var spatial: Dictionary = Geometry.snapshot(level,initial)
		check(spatial.ok,letter + " formal source Spatial")
		if not spatial.ok: continue
		var source: Array = spatial.value.anchors.filter(func(a): return a.face_id == &"source/TOP" and a.layer == initial.player.location.layer)
		check(source.size() == 1,letter + " actual unique source anchor")
		if source.size() != 1: continue
		var chosen := 0
		var directions := {KEY_W:Vector2.UP,KEY_A:Vector2.LEFT,KEY_S:Vector2.DOWN,KEY_D:Vector2.RIGHT}
		for code in directions:
			var mapped: Dictionary = Mapper.map_move(source[0].frame,View.basis(initial.camera_quadrant),directions[code])
			if mapped.ok and mapped.action == {"kind":0,"face_axis":2}:
				chosen = code
				break
		check(chosen != 0,letter + " sole formal Mapper supplies authorized native entry key")
		if chosen == 0: continue
		var events: Array = []
		var observer: Callable = func(event): events.append(event.duplicate(true))
		host.runtime.game_feel_event.connect(observer)
		key(chosen,true)
		await process_frame
		check(host.presenter.snapshot().phase == "FALL" and host.runtime.get_commit_count() == 0,letter + " held WASD really starts pending Fall")
		var identity: Dictionary = host.presenter.snapshot().transition_identity.duplicate(true)
		# Repeat routing attempts during the active Fall, then maintain a true key
		# down state through actual Fall/Landing/idle frames. Echo is native input,
		# never a synthetic gameplay event or completion.
		if host.presenter.snapshot().phase == "FALL":
			for repeat in 20:
				for code in directions: key(code,true)
			await process_frame
		for code in directions:
			if code != chosen: key(code,false)
		var held: Array = []
		var deadline := Time.get_ticks_msec() + 4000
		var idle_seen := -1
		while Time.get_ticks_msec() < deadline:
			key(chosen,true,true)
			await process_frame
			held.append({"time_ms":Time.get_ticks_msec(),"pressed":Input.is_physical_key_pressed(chosen),
				"phase":host.presenter.snapshot().phase,"commit_count":host.runtime.get_commit_count(),
				"statekey":Key.build(level,host.runtime.get_state()).key})
			if host.presenter.snapshot().phase == "IDLE" and host.runtime.is_idle():
				if idle_seen < 0: idle_seen = Time.get_ticks_msec()
				if Time.get_ticks_msec() - idle_seen >= 300: break
		key(chosen,false)
		await process_frame
		check(idle_seen >= 0 and held.size() > 12 and held.all(func(frame): return frame.pressed),letter + " real held input spans motion and settled idle")
		var starts: Array = events.filter(func(e): return e.semantic == "PERSPECTIVE_FALL_APPLIED" and e.phase == "STARTED")
		var commits: Array = events.filter(func(e): return e.semantic == "PERSPECTIVE_FALL_APPLIED" and e.phase == "COMMITTED")
		check(starts.size() == 1 and commits.size() == 1 and starts[0].transition_identity == identity and commits[0].transition_identity == identity,letter + " exactly one native Fall identity and commit after hold/spam")
		check(host.runtime.get_commit_count() == 1 and host.runtime.get_state().player.location.cube_id == &"target" and host.runtime.get_state().player.orientation == initial.player.orientation,letter + " hold cannot retarget or drift orientation")
		var settled_pose: Dictionary = host.project_pose(host.runtime.get_state().player)
		check(settled_pose.ok and host.actor.transform.is_equal_approx(settled_pose.transform),letter + " exact natural settled pose after release")
		var held_events := events.duplicate(true)
		var recovery_offset := events.size()
		key(KEY_R,true)
		await process_frame
		key(KEY_R,false)
		await process_frame
		check(Key.build(level,host.runtime.get_state()).key == source_key and host.runtime.get_commit_count() == 0,letter + " native Reset recovers full state and input")
		key(chosen,true)
		await process_frame
		key(chosen,false)
		await wait_idle(host)
		check(host.runtime.get_commit_count() == 1 and host.runtime.get_state().player.location.cube_id == &"target",letter + " fresh native input after hold Reset works")
		host.runtime.game_feel_event.disconnect(observer)
		rows.append({"map":letter,"level_hash":level.content_hash,"entry_key":chosen,"old_identity":identity,
			"held_frames":held,"held_events":held_events,"recovery_events":events.slice(recovery_offset),
			"final_state":host.runtime.get_state(),"host_issues":host.host_issues.duplicate(true)})
		check(host.host_issues.is_empty(),letter + " no actual input/Presenter script issues")
	host.free()
	FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({
		"checks":checks,"failures":failures,"doubles":[],"rows":rows,"scope":"NEW_PROFILE_REAL",
		"profile":"foundation.game_feel.v2","capture":Gate.real_capture("NEW_PROFILE_NATIVE_HELD_INPUT"),
		"authority":"Input.parse_input_event to actual CoreLab Router/Runtime/Presenter; OS/human input NOT_RUN"},"\t"))
	quit(0 if failures.is_empty() else 1)
