extends SceneTree
## Prepared public production consumers. No new-profile route runs while dependencies are absent.
const Gate = preload("res://tests/beta_sprint/game_feel_owner_03/yellow_target_gate.gd")
const Maps = preload("res://experiments/game_feel_01/maps/map_factory.gd")
const Records = preload("res://foundation/contracts/contract_records.gd")
const Codec = preload("res://foundation/level/level_codec.gd")
const Baker = preload("res://foundation/level/level_baker.gd")
const Kernel = preload("res://foundation/rules/puzzle_rule_kernel.gd")
const Rules = preload("res://foundation/rules/rule_records.gd")
const Facade = preload("res://foundation/game_feel/runtime_facade.gd")
const Key = preload("res://foundation/contracts/state_key.gd")
const Geometry = preload("res://foundation/spatial/surface_geometry.gd")
const F = preload("res://tests/foundation/level/baker_fixture.gd") # DATA factories only.
const Safety = preload("res://foundation/validation/safety_queries.gd")
const Search = preload("res://foundation/solver/search_records.gd")
const Explorer = preload("res://foundation/solver/state_explorer.gd")
const Softlock = preload("res://foundation/quality/softlock/softlock_analyzer.gd")
const Trace = preload("res://foundation/solver/solution_trace.gd")
const Replayer = preload("res://foundation/parity/trace_replayer.gd")
const Capture = preload("res://tests/beta_sprint/game_feel_owner_03/capture_identity.gd")
var evidence := ""
var checks := 0
var failures: Array[String] = []
var rows: Array = []

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): evidence = arg.trim_prefix("--evidence=")
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func eval_action(level: Dictionary, state: Dictionary, action: Dictionary) -> Dictionary:
	return Kernel.evaluate_action(level, state, action, Rules.idle_context())

func verify_sampler(trajectory: Dictionary, letter: String) -> void:
	var sampler: Variant = load(Gate.SAMPLER)
	var immutable_before := trajectory.duplicate(true)
	check(trajectory.departure_points2 == [Vector3i(0,6,0),Vector3i(-2,6,0)], letter + " exact approved departure")
	var expected_controls: Array = [Vector3i(-2,6,0),Vector3i(-4,6,0),
		Vector3i(-6,4 if letter == "a" else 14,8),Vector3i(-6,2 if letter == "a" else 10,8)]
	check(trajectory.descent_control_points2 == expected_controls, letter + " exact approved C1 controls and vertical final approach")
	# Hand-derived literals from the approved profile. No test-side sampler or Bezier solver.
	var samples: Array = [[0.0, Vector3(0,3,0)], [0.125, Vector3(-0.5,3,0)],
		[0.25, Vector3(-1,3,0)],
		[0.5, Vector3(-53.0/27, 73.0/27 if letter == "a" else 107.0/27, 28.0/27)],
		[0.75, Vector3(-73.0/27, 53.0/27 if letter == "a" else 145.0/27, 80.0/27)],
		[1.0, Vector3(-3,1 if letter == "a" else 5,4)]]
	for sample in samples:
		var actual: Dictionary = sampler.sample_actor_center(trajectory, sample[0])
		check(actual.size() == 3 and actual.has_all(["ok","position","issues"]), letter + " closed sampler result")
		check(actual.ok and actual.issues.is_empty() and actual.position is Vector3, letter + " valid public sampling")
		if actual.position is Vector3: check(actual.position.is_equal_approx(sample[1]), letter + " independently derived sample " + str(sample[0]))
		check(actual == sampler.sample_actor_center(trajectory, sample[0]), letter + " repeat deterministic pure sampling")
	for parameter in [-0.01, 1.01, NAN, INF, -INF]:
		var invalid: Dictionary = sampler.sample_actor_center(trajectory, parameter)
		check(not invalid.ok and invalid.position == null and not invalid.issues.is_empty(), letter + " invalid parameter rejected without clamp")
	var malformed: Array = []
	var unknown := trajectory.duplicate(true)
	unknown.trajectory_version = "unknown"
	malformed.append(unknown)
	var extra := trajectory.duplicate(true)
	extra["fallback"] = true
	malformed.append(extra)
	var missing := trajectory.duplicate(true)
	missing.erase("departure_points2")
	malformed.append(missing)
	var huge := trajectory.duplicate(true)
	huge.departure_points2[0] = Vector3i(1000001,6,0)
	malformed.append(huge)
	var wrong_type := trajectory.duplicate(true)
	wrong_type.descent_control_points2 = [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]
	malformed.append(wrong_type)
	for bad in malformed:
		var invalid: Dictionary = sampler.sample_actor_center(bad, 0.5)
		check(not invalid.ok and invalid.position == null and not invalid.issues.is_empty(), letter + " malformed trajectory rejects")
	var left: Dictionary = sampler.sample_actor_center(trajectory, 0.2499)
	var right: Dictionary = sampler.sample_actor_center(trajectory, 0.2501)
	check(left.ok and right.ok, letter + " public samples immediately around join")
	if left.position is Vector3 and right.position is Vector3:
		check(((Vector3(-1,3,0) - left.position) / 0.0001).distance_to(Vector3(-4,0,0)) < 0.01, letter + " line derivative near join, finite-difference float tolerance")
		check(((right.position - Vector3(-1,3,0)) / 0.0001).distance_to(Vector3(-4,0,0)) < 0.03, letter + " cubic derivative tends to same C1 tangent")
	check(trajectory == immutable_before, letter + " public sampler does not mutate authorized input")

func verify_permissions(level: Dictionary, initial: Dictionary, letter: String) -> void:
	var action := {"kind":8, "connection_id": level.perspective_falls[0].connection_id}
	for quadrant in [0,2,3]:
		var wrong := initial.duplicate(true)
		wrong.camera_quadrant = quadrant
		var denied := eval_action(level, wrong, action)
		check(denied.status == 1 and not denied.changed and denied.next_state == null, letter + " illegal Camera rejected " + str(quadrant))
		var author_variant := level.duplicate(true)
		author_variant.erase("content_hash")
		author_variant.camera_initial_quadrant = quadrant
		var baked_variant := Baker.bake(author_variant,{"max_configurations":4096,"max_checks":100000})
		check(baked_variant.ok, letter + " actual Baker accepts authored illegal-view initial observation")
		if not baked_variant.ok: continue
		var camera_runtime := Facade.new()
		var camera_events: Array = []
		camera_runtime.game_feel_event.connect(func(event): camera_events.append(event.duplicate(true)))
		var loaded := camera_runtime.load_level(baked_variant.level)
		check(loaded.ok, letter + " actual illegal-view Runtime loaded")
		if not loaded.ok: continue
		var actual_before := camera_runtime.get_state()
		var actual_key: String = Key.build(baked_variant.level,actual_before).key
		var rejected := camera_runtime.request_action(action)
		check(rejected.status == 1 and not rejected.changed and rejected.next_state == null and camera_runtime.get_state() == actual_before and camera_runtime.get_commit_count() == 0 and Key.build(baked_variant.level,camera_runtime.get_state()).key == actual_key, letter + " real Camera rejection leaves full authoritative state/key unchanged")
		check(camera_events.size() == 1 and camera_events[0].phase == "FEEDBACK" and camera_events[0].reason_category == "CAMERA_NOT_ALLOWED", letter + " original formal Camera diagnostic retained")
		rows.append({"scope":"NEGATIVE_AUTHORED_CAMERA_VARIANT","map":letter,"camera":quadrant,
			"level_hash":baked_variant.level.content_hash,"before":actual_before,"after":camera_runtime.get_state(),
			"before_key":actual_key,"after_key":Key.build(baked_variant.level,camera_runtime.get_state()).key,
			"result":rejected,"events":camera_events})
		camera_runtime.interrupt("UNLOAD")
	var absent := level.duplicate(true)
	absent.perspective_falls = []
	absent.content_hash = Codec.compute_content_hash(absent).content_hash
	var denied := eval_action(absent, initial, {"kind":0,"face_axis":2})
	check(denied.status == 1 and not denied.changed and denied.next_state == null, letter + " unauthored edge cannot Fall")
	var cross := level.duplicate(true)
	for cube in cross.cubes:
		if cube.cube_id == &"target": cube.layer = 1
	cross.content_hash = Codec.compute_content_hash(cross).content_hash
	denied = eval_action(cross, initial, action)
	check(denied.status != 0 and not denied.changed and denied.next_state == null, letter + " cross World fails closed")
	var invalid_face := level.duplicate(true)
	for face in invalid_face.faces:
		if face.face_id == &"target/TOP": face.walkable = false
	invalid_face.content_hash = Codec.compute_content_hash(invalid_face).content_hash
	denied = eval_action(invalid_face, initial, action)
	check(denied.status != 0 and not denied.changed and denied.next_state == null, letter + " invalid landing Face fails closed")

func run() -> void:
	if Gate.blocked(self, evidence): return
	for letter in ["a","b"]:
		var data := Maps.read_spec(letter)
		var baked := Maps.bake_game_feel(data)
		check(baked.ok, letter + " real public schema3 Baker")
		if not baked.ok: continue
		var level: Dictionary = baked.level
		check(level.schema_version == 3 and level.contract_version == "foundation.game_feel.v2" and level.rule_version == "foundation.rules.game_feel.v2" and level.orientation_version == "cube24.v1", letter + " closed explicit profile identity")
		check(Maps.bake_game_feel(data).level == level, letter + " repeated canonical Bake")
		var y := 0 if letter == "a" else 8
		var centers := {&"source":Vector3i(0,4,0), &"target":Vector3i(-6,y,8), &"blue_reference":Vector3i(-8,y,8), &"exit":Vector3i(-4,y,8)}
		check(level.cubes.size() == 4, letter + " exactly four actual platforms")
		for id in centers:
			var bodies: Array = level.cubes.filter(func(c): return c.cube_id == id)
			check(bodies.size() == 1 and bodies[0].center2 == centers[id], letter + " canonical actual body " + str(id))
		var blue_faces: Array = level.faces.filter(func(f): return f.cube_id == &"blue_reference")
		check(blue_faces.size() == 6 and blue_faces.all(func(f): return not f.walkable), letter + " blue reference has no walkable support")
		var connection: Dictionary = level.perspective_falls[0]
		check(connection.has("trajectory") and not connection.has("path_points2"), letter + " no old path fallback")
		if not connection.has("trajectory"): continue
		verify_sampler(connection.trajectory, letter)
		var initial := Records.initial_state(level)
		var applied := eval_action(level, initial, {"kind":0,"face_axis":2})
		check(applied.status == 0 and applied.changed and applied.next_state.player.location.cube_id == &"target" and applied.next_state.player.orientation == initial.player.orientation, letter + " real lower/higher Fall to yellow target PRESERVE")
		if applied.status != 0: continue
		var safe := Safety.validate_perspective_motion(level, initial, applied.next_state, connection.connection_id)
		check(safe.status == 0 and safe.issues.is_empty(), letter + " real continuous cubic cube sweep SAFE")
		var blocked := level.duplicate(true)
		blocked.cubes.append(F.cube(&"quality_interior_obstacle",0,Vector3i(-4,6 if letter == "a" else 8,2)))
		for face in Geometry.make_face_nodes(&"quality_interior_obstacle"): blocked.faces.append(face)
		blocked.content_hash = Codec.compute_content_hash(blocked).content_hash
		var collision := Safety.validate_perspective_motion(blocked, initial, applied.next_state, connection.connection_id)
		check(collision.status == 1 and not collision.issues.is_empty(), letter + " actual interior obstacle proves UNSAFE")
		verify_permissions(level, initial, letter)
		# Observe the real STARTED proposal, then interrupt it. Never manually finish a new Fall.
		var runtime := Facade.new()
		var events: Array = []
		runtime.game_feel_event.connect(func(event): events.append(event.duplicate(true)))
		var loaded := runtime.load_level(level)
		check(loaded.ok, letter + " real Facade load")
		if not loaded.ok: continue
		var proposal := runtime.request_action({"kind":0,"face_axis":2})
		check(proposal.status == 0 and proposal.changed and runtime.get_state() == initial and runtime.get_commit_count() == 0, letter + " accepted Fall does not commit early")
		check(events.size() == 1 and events[0].phase == "STARTED" and events[0].schema_version == 2 and events[0].contract_version == "game_feel.event.v2", letter + " actual Fall STARTED v2")
		if events.size() == 1:
			check(events[0].get("authorized_trajectory") == connection.trajectory and not events[0].has("authorized_path_points2"), letter + " immutable exact authorized trajectory")
			var proof: Dictionary = events[0].get("safety_verdict", {}).get("evidence_ref", {})
			check(proof.get("kind") == "dyadic_cubic_cube_sweep.v1" and proof.get("level_hash") == level.content_hash and proof.get("before_statekey") == Key.build(level,initial).key and proof.get("after_statekey") == Key.build(level,applied.next_state).key, letter + " actual continuous proof binds query endpoints and level")
		runtime.interrupt("CANCEL")
		runtime.interrupt("UNLOAD")
		var explored := Explorer.explore(level, initial, Search.default_policy(1), Search.default_budget())
		check(explored.status == 0 and explored.graph != null and explored.graph.complete and explored.solution_trace != null, letter + " production UNFILTERED FULL_GRAPH solved")
		if explored.graph == null or explored.solution_trace == null: continue
		var trace: Dictionary = explored.solution_trace
		check(Trace.validate(level,trace).ok and Trace.validate_semantics(level,trace).ok, letter + " original hard witness revalidated")
		check(trace.total_actions == 2 and trace.steps.size() == 2 and trace.steps[0].expected_state.player.location.cube_id == &"target" and trace.steps[1].expected_state.player.location.cube_id == &"exit", letter + " true two-action Fall then Roll Goal")
		var graph_before: Dictionary = explored.graph.duplicate(true)
		var softlock := Softlock.analyze(level, explored.graph, {"max_nodes":10000,"max_edges":100000,"max_runtime_ms":0})
		check(softlock.status == 0 and softlock.softlock_count == 0 and explored.graph == graph_before, letter + " same actual live graph complete Softlock analysis")
		var driver := Replayer.new()
		root.add_child(driver)
		var logical: Dictionary = await driver.replay(level, trace, {"mode":0})
		check(logical.status == 0 and logical.matched_steps == 2 and logical.actual_statekey == trace.goal_statekey, letter + " actual distinct LOGICAL_SESSION Replay")
		driver.free()
		rows.append({"map":letter,"level":level,"level_hash":level.content_hash,"safety":safe,"interior_collision":collision,
			"events":events,"policy":Search.default_policy(1),"original_trace":trace,"explorer":explored,"softlock":softlock,"logical":logical})
	FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({
		"checks":checks,"failures":failures,"doubles":[],"rows":rows,"scope":"NEW_PROFILE_REAL",
		"profile":"foundation.game_feel.v2","capture":Gate.real_capture("NEW_PROFILE_CORE_REAL"),
		"uncovered_predicates":["UNPROVEN frozen-proof-budget boundary fixture awaits actual Owner01 delivery", "Surface/Inner authored permission variants and full rejection diagnostics"],
		"authority":"Actual production APIs; this job's success does not establish all twelve case predicates"},"\t"))
	quit(0 if failures.is_empty() else 1)
