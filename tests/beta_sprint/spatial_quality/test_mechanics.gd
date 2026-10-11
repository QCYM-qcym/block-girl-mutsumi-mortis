extends "res://tests/beta_sprint/spatial_quality/suite.gd"
## Independent production Facade cases; explicit logical completion, no graphical claims.
const Maps = preload("res://experiments/spatial_puzzle_batch_01/maps/map_factory.gd")
const Facade = preload("res://foundation/game_feel/runtime_facade.gd")
const Key = preload("res://foundation/contracts/state_key.gd")
const Geometry = preload("res://foundation/spatial/surface_geometry.gd")
const Math = preload("res://foundation/orientation/discrete_orientation.gd")
const Goal = preload("res://foundation/rules/goal_evaluator.gd")
const Classifier = preload("res://foundation/quality/intent/mechanic_classifier.gd")
const Baker = preload("res://foundation/level/level_baker.gd")
const Codec = preload("res://foundation/level/level_codec.gd")
const Data = preload("res://foundation/contracts/contract_validation.gd")
const PREFIX := {&"world_shift_gate_lab":"gate",&"orientation_loop_lab":"loop",&"face_lock_lab":"lock",
	&"perspective_fork_lab":"fork",&"rubik_spatial_puzzle_01":"combined"}
var runtime: RefCounted
var native: Array = []
var level: Dictionary = {}

func fresh(definition: Dictionary) -> bool:
	if runtime != null: runtime.interrupt("UNLOAD")
	runtime = Facade.new()
	native.clear()
	runtime.transition_started.connect(func(result,token,generation,global): native.append({"identity":runtime.get_pending_identity(token,generation,global),"result":result.duplicate(true)}))
	level = definition
	var loaded: Dictionary = runtime.load_level(level)
	check(loaded.ok,"real canonical Facade load")
	return loaded.ok

func act(action: Dictionary, expected_status: int = 0) -> Dictionary:
	var before: Dictionary = runtime.get_state()
	var before_key: String = Key.build(level,before).key
	var count: int = native.size()
	var commits: int = runtime.get_commit_count()
	var result: Dictionary = runtime.request_action(action)
	check(result.status == expected_status,"formal action status " + str(action))
	if result.status == 0 and result.changed:
		check(native.size() == count+1 and runtime.get_state() == before,"one actual native proposal before logical completion")
		if native.size() == count+1:
			var identity: Dictionary = native[-1].identity
			var completed: Dictionary = runtime.finish_transition(identity)
			check(not completed.get("ignored",true) and runtime.get_commit_count() == commits+1,"one real logical commit")
			check(runtime.get_state() == result.next_state and runtime.is_idle(),"actual state equals native accepted candidate and releases Busy")
	else:
		check(runtime.get_state() == before and Key.build(level,runtime.get_state()).key == before_key and runtime.get_commit_count() == commits and native.size() == count,"denied/no-op action changes no state, key, transition or commit")
	var row := {"case":current.id,"action":action,"result":result,"before":before,"after":runtime.get_state(),
		"before_key":before_key,"after_key":Key.build(level,runtime.get_state()).key,"completion_scope":"LOGICAL_PHASE_API_ONLY"}
	rows.append(row)
	return row

func route(actions: Array) -> Dictionary:
	for action in actions:
		var actual := act(action)
		if actual.result.status != 0: break
	return runtime.get_state()

func loop_cases(definition: Dictionary) -> void:
	begin("loop.routes","REAL_RUNTIME")
	var witnesses := Maps.witnesses(&"orientation_loop_lab")
	fresh(definition)
	var initial: Dictionary = runtime.get_state()
	var a := route(witnesses.route_a)
	fresh(definition)
	var b := route(witnesses.route_b)
	check(a.player.location == b.player.location and a.player.orientation != b.player.orientation,"two real routes: same position, different orientation")
	check(Key.build(level,a).key != Key.build(level,b).key,"formal StateKey distinguishes the two poses")
	fresh(definition)
	var closed := route(witnesses.closed_loop)
	check(closed.player.location == initial.player.location and closed.player.orientation != initial.player.orientation,"real closed route changes pose at original location")
	begin("loop.camera","REAL_RUNTIME")
	var pose: int = runtime.get_state().player.orientation
	for quadrant in [1,2,3,0]:
		act({"kind":9,"camera_quadrant":quadrant})
		check(runtime.get_state().player.orientation == pose,"Camera never rewrites physical cube orientation")
	runtime.reset()
	check(runtime.get_state() == initial,"Reset restores initial physical pose and Camera")

func gate_cases(definition: Dictionary) -> void:
	begin("gate.negative","REAL_RUNTIME")
	fresh(definition)
	var denied := act({"kind":1},1)
	check(denied.result.rejection_code == 2010,"off-point Shift uses exact formal gate rejection")
	begin("gate.mapping","REAL_RUNTIME")
	act({"kind":0,"face_axis":0})
	var before: Dictionary = runtime.get_state()
	act({"kind":1})
	check(runtime.get_state().player.location.cube_id == &"inner_gate" and runtime.get_state().player.location.layer == 1,"fixed gate reaches exact mapped Inner target")
	check(runtime.get_state().player.orientation == before.player.orientation and runtime.get_state().camera_quadrant == before.camera_quadrant,"exact Orientation and Camera preserved")
	act({"kind":1})
	check(runtime.get_state().player.location.cube_id == &"gate" and runtime.get_state().player.location.layer == 0,"explicit reverse gate reaches original Surface pair")
	# Derived negative input from the actual saved-authoring Bake; no second factory.
	var bright: Dictionary = definition.duplicate(true)
	bright.erase("content_hash") # Public Baker owns the new canonical hash.
	bright.cubes = bright.cubes.filter(func(c):return c.cube_id != &"roof")
	bright.faces = bright.faces.filter(func(f):return f.cube_id != &"roof")
	var baked := Baker.bake(bright,{"max_configurations":4096,"max_checks":100000})
	check(baked.ok,"actual roof-free author variant is valid")
	if baked.ok:
		fresh(baked.level)
		act({"kind":0,"face_axis":0})
		var blocked := act({"kind":1},1)
		check(blocked.result.rejection_code != 2010 and blocked.result.rejection_code != 2011,"fixed point does not bypass upstream Shadow rejection")

func lock_cases(definition: Dictionary) -> void:
	var id: StringName = definition.level_id
	var prefix: String = PREFIX[id]
	var witnesses := Maps.witnesses(id)
	begin("lock.contact" if prefix == "lock" else "combined.order","REAL_RUNTIME")
	fresh(definition)
	var initial: Dictionary = runtime.get_state()
	var denied := act({"kind":1},1)
	check(denied.result.rejection_code == 2011,"initial authored gate is locked")
	var wrong := route(witnesses.wrong_face)
	check(wrong.player.location.cube_id == &"corner" and wrong.mechanism_states.contact_lock == &"idle","wrong-face MOVE reaches sensor without activation or rollback")
	var wrong_result: Dictionary = rows[-1].result
	var wrong_tags := Classifier.classify_transition(level,wrong_result)
	check(wrong_tags.ok and not 7 in wrong_tags.tags,"wrong contact invents no trigger semantic")
	fresh(definition)
	var correct := route(witnesses.correct_face)
	check(correct.player.location == wrong.player.location and correct.mechanism_states.contact_lock == &"latched","same sensor position with correct post-roll pose latches")
	var correct_tags := Classifier.classify_transition(level,rows[-1].result)
	check(correct_tags.ok and 7 in correct_tags.tags and correct_tags.mechanism_ids == [&"contact_lock"],"actual latch emits exact formal mechanism classification")
	if prefix == "lock": begin("lock.reentry","REAL_RUNTIME")
	act({"kind":5,"mechanism_id":&"contact_lock"},1)
	act({"kind":0,"face_axis":2})
	check(runtime.get_state().mechanism_states.contact_lock == &"latched","leaving preserves latch")
	act({"kind":0,"face_axis":0})
	var repeated := Classifier.classify_transition(level,rows[-1].result)
	check(repeated.ok and not 7 in repeated.tags and runtime.get_state().mechanism_states.contact_lock == &"latched","re-entry creates no duplicate latch trigger")
	runtime.reset()
	check(runtime.get_state() == initial,"Reset restores full initial key and unlatched mechanism")
	for name in witnesses:
		if String(name).begins_with("solution"):
			fresh(definition)
			var solved := route(witnesses[name])
			var terminal := Goal.is_goal(level,solved)
			check(terminal.ok and terminal.is_goal,"actual complete authored route " + String(name))
			check(solved.player.location.layer == 1 and solved.mechanism_states.contact_lock == &"latched","Goal route really uses latched Inner world")

func fork_cases(definition: Dictionary) -> void:
	begin("fork.selection","REAL_RUNTIME")
	fresh(definition)
	var a_before: Dictionary = runtime.get_state()
	var a := act({"kind":0,"face_axis":2})
	fresh(definition)
	act({"kind":9,"camera_quadrant":2})
	var b_before: Dictionary = runtime.get_state()
	var b := act({"kind":0,"face_axis":2})
	check(a_before.player == b_before.player and a_before.world_orientations == b_before.world_orientations and a_before.camera_quadrant != b_before.camera_quadrant,"same source, edge, world, pose and input; only Camera differs")
	check(a.after.player.location.cube_id == &"target_a" and b.after.player.location.cube_id == &"target_b","Camera-qualified distinct authored targets")
	check(a.after.player.orientation == a_before.player.orientation and b.after.player.orientation == b_before.player.orientation,"both actual Falls preserve orientation")
	for name in Maps.witnesses(&"perspective_fork_lab"):
		fresh(definition)
		var final := route(Maps.witnesses(&"perspective_fork_lab")[name])
		check(Goal.is_goal(level,final).is_goal,"branch has an actual Goal/recovery route " + String(name))
	begin("fork.negative","REAL_RUNTIME")
	for quadrant in [0,3]:
		fresh(definition)
		act({"kind":9,"camera_quadrant":quadrant})
		act({"kind":0,"face_axis":2},1)
	var missing: Dictionary = definition.duplicate(true)
	missing.erase("content_hash")
	missing.perspective_falls = []
	var baked := Baker.bake(missing,{"max_configurations":4096,"max_checks":100000})
	check(baked.ok,"missing-connection author variant is structurally valid")
	if baked.ok:
		fresh(baked.level)
		act({"kind":0,"face_axis":2},1)
	var ambiguous: Dictionary = definition.duplicate(true)
	ambiguous.erase("content_hash")
	ambiguous.perspective_falls[1].allowed_camera_quadrants = [1]
	check(not Baker.bake(ambiguous,{"max_configurations":4096,"max_checks":100000}).ok,"same-camera overlapping targets are rejected by actual Baker")
	var illegal: Dictionary = definition.duplicate(true)
	illegal.erase("content_hash")
	for face in illegal.faces:
		if face.face_id == &"target_a/TOP": face.walkable = false
	baked = Baker.bake(illegal,{"max_configurations":4096,"max_checks":100000})
	if baked.ok:
		fresh(baked.level)
		act({"kind":0,"face_axis":2},1)
	else: check(not baked.issues.is_empty(),"illegal landing rejected with actual diagnostics")
	var cross: Dictionary = definition.duplicate(true)
	cross.erase("content_hash")
	for cube in cross.cubes:
		if cube.cube_id == &"target_a": cube.layer = 1
	baked = Baker.bake(cross,{"max_configurations":4096,"max_checks":100000})
	if baked.ok:
		fresh(baked.level)
		act({"kind":0,"face_axis":2},1)
	else: check(not baked.issues.is_empty(),"cross-world landing rejected with actual diagnostics")
	# Explicit adversarial Core input, never added to the shipped map: a real
	# interior blocker must be rejected by continuous Safety, not a mock verdict.
	var obstacle: Dictionary = definition.duplicate(true)
	obstacle.cubes.append({"cube_id":&"quality_cubic_blocker","layer":0,"center2":Vector3i(-4,6,2),"orientation":0,"group_id":&"","occludes_light":true,"tags":[]})
	obstacle.faces.append_array(Geometry.make_face_nodes(&"quality_cubic_blocker"))
	obstacle["content_hash"] = "0".repeat(64)
	var obstacle_hash := Codec.compute_content_hash(obstacle)
	check(obstacle_hash.ok,"adversarial blocker canonical hash computes: " + str(obstacle_hash.issues))
	rows.append({"adversarial_blocker_hash":obstacle_hash})
	if not obstacle_hash.ok: return
	obstacle.content_hash = obstacle_hash.content_hash
	check(Data.validate_level_shape(obstacle).is_empty(),"adversarial blocker retains exact formal DATA shape")
	if not fresh(obstacle): return
	act({"kind":0,"face_axis":2},1)
	# An actual adjacent support wins as ordinary Roll, even with a listed Fall.
	var road: Dictionary = definition.duplicate(true)
	road.cubes.append({"cube_id":&"quality_roll_neighbor","layer":0,"center2":Vector3i(-2,4,0),"orientation":0,"group_id":&"","occludes_light":true,"tags":[]})
	var road_faces := Geometry.make_face_nodes(&"quality_roll_neighbor")
	for face in road_faces: face.walkable = face.face == 4
	road.faces.append_array(road_faces)
	road["content_hash"] = "0".repeat(64)
	var road_hash := Codec.compute_content_hash(road)
	check(road_hash.ok,"adversarial ordinary-road canonical hash computes")
	road.content_hash = road_hash.content_hash
	if not fresh(road): return
	var rolled := act({"kind":0,"face_axis":2})
	check(rolled.after.player.location.cube_id == &"quality_roll_neighbor" and rolled.after.player.orientation != rolled.before.player.orientation,"formal ordinary Roll takes priority over listed Fall")

func lifecycle(definition: Dictionary, prefix: String) -> void:
	begin(prefix + ".runtime_lifecycle","REAL_RUNTIME")
	fresh(definition)
	var initial: Dictionary = runtime.get_state()
	var action: Dictionary = Maps.witnesses(definition.level_id).values()[0][0]
	if action.kind == 9: action = {"kind":0,"face_axis":2}
	if prefix == "gate":
		act({"kind":0,"face_axis":0})
		action = {"kind":1}
	elif prefix in ["lock","combined"]:
		route([{ "kind":0,"face_axis":3},{"kind":0,"face_axis":0},{"kind":0,"face_axis":1},{"kind":0,"face_axis":2}])
		action = {"kind":1}
	var pending_before: Dictionary = runtime.get_state()
	var pending_commits: int = runtime.get_commit_count()
	var count: int = native.size()
	var proposed: Dictionary = runtime.request_action(action)
	check(proposed.status == 0 and proposed.changed and native.size() == count+1,"actual pending transition begins")
	if native.size() != count+1: return
	var old: Dictionary = native[-1].identity
	for repeated_action in [action,{"kind":1},{"kind":9,"camera_quadrant":0}]:
		var denied: Dictionary = runtime.request_action(repeated_action)
		check(denied.status == 1 and runtime.get_state() == pending_before and runtime.get_commit_count() == pending_commits,"busy spam commits no second action")
	runtime.reset()
	check(runtime.finish_transition(old).get("ignored",false) and runtime.get_state() == initial and runtime.get_commit_count() == 0,"Reset retires original identity; late completion ignored")
	runtime.set_paused(true)
	var paused: Dictionary = runtime.request_action(action)
	check(paused.status == 1 and runtime.get_state() == initial,"paused Runtime rejects new action")
	runtime.set_paused(false)
	act({"kind":0,"face_axis":0} if prefix in ["gate","lock","combined"] else action)
	check(runtime.get_commit_count() == 1 and runtime.is_idle(),"fresh post-reset input is accepted exactly once")
	await process_frame
	await process_frame
	check(runtime.get_commit_count() == 1,"busy input was never queued/deferred")
	# Capture a NEW live identity: neither Reset nor logical completion retires it
	# before the UNLOAD boundary under test.
	runtime.reset()
	var starts_before: int = native.size()
	var unloading: Dictionary = runtime.request_action({"kind":0,"face_axis":2} if prefix == "fork" else {"kind":0,"face_axis":0})
	check(unloading.status == 0 and unloading.changed and native.size() == starts_before+1 and not runtime.is_idle(),"unload test begins with a fresh accepted pending transition")
	if native.size() != starts_before+1: return
	var unload_identity: Dictionary = native[-1].identity
	check(not runtime.get_pending_identity(unload_identity.transaction_id,unload_identity.generation,unload_identity.is_global).is_empty(),"fresh token is live immediately before UNLOAD")
	var unload_commits: int = runtime.get_commit_count()
	runtime.interrupt("UNLOAD")
	check(not runtime.is_loaded() and runtime.get_pending_identity(unload_identity.transaction_id,unload_identity.generation,unload_identity.is_global).is_empty(),"UNLOAD retires the actual pending identity and session")
	check(runtime.finish_transition(unload_identity).get("ignored",false) and runtime.get_commit_count() == unload_commits,"formerly live unload callback cannot commit")
	rows.append({"coverage":"pending_unload_identity","map":prefix,"identity":unload_identity,"is_loaded":runtime.is_loaded(),"commits":runtime.get_commit_count()})

func run() -> void:
	for id in Maps.ids():
		begin(String(PREFIX[id]) + ".mechanic_bake","UNIT")
		var baked := Maps.bake(id)
		check(baked.ok,"actual delivered map bakes")
		if not baked.ok: continue
		var definition: Dictionary = baked.level
		rows.append({"source":"SAVED_AUTHORING_BAKE","map":id,"level_hash":definition.content_hash,"source_map":baked.get("source_map"),"bake_provenance":baked.get("bake_provenance"),"negative_variants":"DEEP_COPY_OF_THIS_CANONICAL_LEVEL_ONLY"})
		match id:
			&"orientation_loop_lab": loop_cases(definition)
			&"world_shift_gate_lab": gate_cases(definition)
			&"face_lock_lab",&"rubik_spatial_puzzle_01": lock_cases(definition)
			&"perspective_fork_lab": fork_cases(definition)
		await lifecycle(definition,String(PREFIX[id]))
	finish()
