extends SceneTree
const F = preload("res://tests/beta_sprint/game_feel_owner_01/fixtures.gd")
const Data = preload("res://foundation/contracts/contract_validation.gd")
const R = preload("res://foundation/contracts/contract_records.gd")
const Key = preload("res://foundation/contracts/state_key.gd")
const Codec = preload("res://foundation/level/level_codec.gd")
const Kernel = preload("res://foundation/rules/puzzle_rule_kernel.gd")
const Rules = preload("res://foundation/rules/rule_records.gd")
const Safety = preload("res://foundation/validation/safety_queries.gd")
const Goal = preload("res://foundation/rules/goal_evaluator.gd")
var checks := 0
var failures: Array[String] = []
var observations: Array = []
func check(ok: bool, name: String) -> void:
	checks += 1
	if not ok: failures.append(name)
func _initialize() -> void:
	create_timer(20).timeout.connect(func(): printerr("TEST_TIMEOUT: did not reach result boundary"); quit(2))
	call_deferred("run")
func request(level: Dictionary, state: Dictionary, action: Dictionary) -> Dictionary:
	return Kernel.evaluate_action(level,state,action,Rules.idle_context())
func run() -> void:
	for higher in [false,true]:
		var level := F.level(higher)
		level.content_hash = Codec.compute_content_hash(level).content_hash
		var state := R.initial_state(level)
		var action := {"kind":8,"connection_id":&"edge_a"}
		var result := request(level,state,action)
		check(result.status == 0 and result.changed,"authored real-height " + str(higher) + " screen descent is APPLIED")
		if result.status == 0 and result.changed:
			check(result.next_state.player.orientation == state.player.orientation,"Fall preserves cube24 orientation")
			check(result.next_state.player.location.cube_id == &"target","formal target support identity")
			check(Goal.is_goal(level,result.next_state).is_goal,"formal Goal follows legal landing")
			check(Safety.validate_motion(level,state,result.next_state,action).status == 0,"complete path has real SAFE verdict")
			check(request(level,result.next_state,action).status == 1,"directed connection never implies reverse traversal")
		observations.append({"higher":higher,"result":result})
		var fallback := request(level,state,{"kind":0,"face_axis":2})
		check(fallback.status == 0 and fallback.changed,"active mapped MOVE resolves declared Fall only after ordinary road absence")
		for camera in [0,2,3]:
			var wrong := state.duplicate(true)
			wrong.camera_quadrant = camera
			var rejected := request(level,wrong,action)
			check(rejected.status == 1 and not rejected.changed,"unauthorized quadrant rejected: " + str(camera))
		var view := request(level,state,{"kind":9,"camera_quadrant":0})
		check(view.status == 0 and view.changed and view.next_state.player == state.player,"camera action changes only authority view")
	var level := F.level()
	var state := R.initial_state(level)
	var bad := level.duplicate(true)
	bad.perspective_falls = []
	check(request(bad,state,{"kind":8,"connection_id":&"edge_a"}).status == 1,"no authored connection never grants Fall")
	bad = level.duplicate(true)
	bad.cubes[1].layer = 1
	check(request(bad,state,{"kind":8,"connection_id":&"edge_a"}).status == 1,"Fall cannot bypass World Shift")
	bad = level.duplicate(true)
	for face in bad.faces:
		if face.face_id == &"target/TOP": face.walkable = false
	check(request(bad,state,{"kind":8,"connection_id":&"edge_a"}).status == 1,"invalid landing face is rejected")
	bad = level.duplicate(true)
	bad.cubes.append(F.F.cube(&"obstacle",0,Vector3i(-4,6,4)))
	for face in F.Geometry.make_face_nodes(&"obstacle"): bad.faces.append(face)
	check(request(bad,state,{"kind":8,"connection_id":&"edge_a"}).status == 1,"whole swept body detects obstacle between endpoints")
	bad = level.duplicate(true)
	bad.perspective_falls[0].path_points2[1] = Vector3i(0,4,0)
	check(request(bad,state,{"kind":8,"connection_id":&"edge_a"}).status == 1,"cannot descend through source support before edge exit")
	bad = level.duplicate(true)
	bad.worlds[0].allowed_states = [0,22]
	bad.perspective_falls[0].allowed_world_orientations = [22]
	var second: Dictionary = bad.perspective_falls[0].duplicate(true)
	second.connection_id = &"edge_b"
	second.allowed_world_orientations = [0]
	bad.perspective_falls.append(second)
	var selected := request(bad,state,{"kind":0,"face_axis":2})
	check(selected.status == 0 and selected.changed,"select current world permission before lexical connection order")
	if selected.status == 0:
		var described := Kernel.game_feel_description(bad,state,selected.action,selected)
		check(described.motion.connection_id == &"edge_b","event identifies the actually permitted connection")
	for orientation in 24:
		var pose := state.duplicate(true)
		pose.player.orientation = orientation
		var preserved := request(level,pose,{"kind":8,"connection_id":&"edge_a"})
		check(preserved.status == 0 and preserved.next_state.player.orientation == orientation,"complete Fall safety preserves orientation " + str(orientation))
	bad = level.duplicate(true)
	bad.celestial.slots.append({"slot_id":&"b","position2":Vector3i(0,12,0)})
	bad.celestial.slot_order.append(&"b")
	bad.celestial.edges.append({"from_slot_id":&"a","to_slot_id":&"b"})
	bad.mechanisms.append({"mechanism_id":&"arrival","face_id":&"target/TOP","trigger":&"ENTER","action":{"kind":7,"celestial_op":0,"target_slot_id":&"b","alternate_slot_id":&"","mechanism_id":&"arrival"},"priority":0,"initial_state":&"ready","allowed_states":[&"ready"]})
	for face in bad.faces:
		if face.face_id == &"target/TOP": face.mechanism_ids.append(&"arrival")
	var entry_state := R.initial_state(bad)
	var entry := request(bad,entry_state,{"kind":8,"connection_id":&"edge_a"})
	check(entry.status == 1 and not entry.changed,"translation-only profile must never silently bypass target ENTER effect")
	bad = level.duplicate(true)
	bad.cubes.append(F.F.cube(&"road",0,Vector3i(-2,4,0)))
	for face in F.Geometry.make_face_nodes(&"road"):
		face.walkable = face.face == 4
		bad.faces.append(face)
	var normal := request(bad,R.initial_state(bad),{"kind":0,"face_axis":2})
	check(normal.status == 0 and normal.next_state.player.location.cube_id == &"road","ordinary Roll wins over authored Fall on the same input")
	check(request(bad,R.initial_state(bad),{"kind":8,"connection_id":&"edge_a"}).status == 1,"explicit Fall cannot jump over an existing ordinary road")
	var ordinary := Kernel.game_feel_description(bad,R.initial_state(bad),normal.action,normal)
	check(ordinary.semantic == "MOVE_APPLIED_NORMAL" and ordinary.motion.is_empty(),"ordinary Roll has no Fall path/cue")
	var locked := level.duplicate(true)
	locked.flag_definitions = [{"flag_id":&"open","initial_value":false}]
	locked.perspective_falls[0].required_flags = [&"open"]
	var refusal := request(locked,R.initial_state(locked),{"kind":0,"face_axis":2})
	check(refusal.status == 1 and Kernel.game_feel_description(locked,R.initial_state(locked),refusal.action,refusal).reason_category == "MECHANISM_LOCKED","locked authored connection never degrades into Edge")
	var invalid_pose := state.duplicate(true)
	invalid_pose.player.location.face = 6
	var invalid_result := request(level,invalid_pose,{"kind":0,"face_axis":0})
	check(invalid_result.status == 2 and Kernel.game_feel_description(level,invalid_pose,invalid_result.action,invalid_result).reason_category == "INVALID_FACE","invalid support pose is Error/InvalidFace, never Edge")
	var summary := {"checks":checks,"failures":failures,"doubles":[],"user_dir":OS.get_user_data_dir(),"observations":observations}
	FileAccess.open(OS.get_environment("FOUNDATION_TEST_EVIDENCE").path_join("results.json"),FileAccess.WRITE).store_string(JSON.stringify(summary))
	print("RULES checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
