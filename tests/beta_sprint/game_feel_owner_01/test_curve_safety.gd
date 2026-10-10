extends SceneTree
const F = preload("res://tests/beta_sprint/game_feel_owner_01/curve_fixtures.gd")
const Base = preload("res://tests/foundation/level/baker_fixture.gd")
const Geometry = preload("res://foundation/spatial/surface_geometry.gd")
const Baker = preload("res://foundation/level/level_baker.gd")
const Records = preload("res://foundation/contracts/contract_records.gd")
const Kernel = preload("res://foundation/rules/puzzle_rule_kernel.gd")
const Rules = preload("res://foundation/rules/rule_records.gd")
const Safety = preload("res://foundation/validation/safety_queries.gd")
const Codec = preload("res://foundation/level/level_codec.gd")
var checks := 0
var failures: Array[String] = []
var observations: Array = []
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func bake(author: Dictionary) -> Dictionary:
	var result: Dictionary = Baker.bake(author,{"max_configurations":4096,"max_checks":100000})
	check(result.ok,"real Baker admits the diagnostic geometry")
	return result.level if result.ok else {}
func rehash(level: Dictionary) -> void:
	var identity: Dictionary = Codec.compute_content_hash(level)
	if identity.ok: level.content_hash = identity.content_hash
func _initialize() -> void:
	create_timer(30).timeout.connect(func():printerr("TEST_TIMEOUT");quit(2))
	call_deferred("run")
func run() -> void:
	for higher in [false,true]:
		var author: Dictionary = F.authoring(higher)
		author.spawn.location.cube_id = &"target"
		var landing: Dictionary = bake(author)
		if not landing.is_empty():
			var roll: Dictionary = Kernel.evaluate_action(landing,Records.initial_state(landing),{"kind":0,"face_axis":0},Rules.idle_context())
			check(roll.status == 0 and roll.next_state.player.location.cube_id == &"exit","new-rule exact directed Roll proof separates the real rear blue entity")
			observations.append({"higher":higher,"roll":roll})
		var legacy: Dictionary = author.duplicate(true)
		legacy.schema_version = 1
		legacy.contract_version = "foundation.contract.v1"
		legacy.rule_version = "foundation.rules.v1"
		legacy.erase("camera_initial_quadrant")
		legacy.erase("perspective_falls")
		var old: Dictionary = bake(legacy)
		if not old.is_empty():
			var roll: Dictionary = Kernel.evaluate_action(old,Records.initial_state(old),{"kind":0,"face_axis":0},Rules.idle_context())
			check(roll.status == 1 and roll.issues.any(func(i):return i.code == 1601 and &"blue_reference" in i.entity_ids),"legacy conservative Roll decision is unchanged")
	var module_path := "res://foundation/game_feel/trajectory_sweep.gd"
	check(ResourceLoader.exists(module_path),"continuous curve proof is present for the real Runtime consumer")
	if ResourceLoader.exists(module_path):
		var sweep: Variant = load(module_path)
		for higher in [false,true]:
			var level: Dictionary = bake(F.authoring(higher))
			if level.is_empty(): continue
			var before: Dictionary = Records.initial_state(level)
			var action := {"kind":0,"face_axis":2}
			var fall: Dictionary = Kernel.evaluate_action(level,before,action,Rules.idle_context())
			check(fall.status == 0 and fall.next_state.player.location.cube_id == &"target","actual higher/lower yellow curve Fall is APPLIED")
			if fall.status == 0:
				check(fall.next_state.player.orientation == 0 and fall.next_state.world_orientations == before.world_orientations,"curve translates only, preserving World and orientation")
				check(Safety.validate_perspective_motion(level,before,fall.next_state,&"yellow_fall").status == 0,"full formal curve query proves every physical entity")
			for q in [0,2,3]:
				var wrong: Dictionary = before.duplicate(true)
				wrong.camera_quadrant = q
				check(Kernel.evaluate_action(level,wrong,action,Rules.idle_context()).rejection_code == 2101,"unauthorized camera cannot select a curve")
			for fault in ["no_connection","wrong_world","unwalkable","endpoint","join","contact","reverse_view"]:
				var wrong: Dictionary = level.duplicate(true)
				var c: Dictionary = wrong.perspective_falls[0]
				match fault:
					"no_connection": wrong.perspective_falls = []
					"wrong_world": wrong.cubes.filter(func(cube):return cube.cube_id == &"target")[0].layer = 1
					"unwalkable": wrong.faces.filter(func(face):return face.face_id == &"target/TOP")[0].walkable = false
					"endpoint": c.trajectory.descent_control_points2[3].x -= 1
					"join": c.trajectory.descent_control_points2[1].z += 1
					"contact": c.trajectory.descent_control_points2[2].x -= 1
					"reverse_view": c.trajectory.descent_control_points2[2] = Vector3i(-6,30,8)
				rehash(wrong)
				var rejected: Dictionary = Kernel.evaluate_action(wrong,before,action,Rules.idle_context())
				check(rejected.status != 0 and rejected.next_state == null,"invalid geometry/permission never proposes state: "+fault)
			observations.append({"higher":higher,"fall":fall})
		var obstruction: Dictionary = F.authoring()
		obstruction.cubes.append(Base.cube(&"middle_obstacle",0,Vector3i(-6,6,4)))
		for face in Geometry.make_face_nodes(&"middle_obstacle"): obstruction.faces.append(face)
		var obstructed: Dictionary = bake(obstruction)
		if not obstructed.is_empty():
			check(not Safety._linear_body_hits(Vector3i(0,6,0),Vector3i(-6,2,8),Vector3i(-6,6,4)),"endpoint chord is clear in the middle-curve collision negative")
			var result: Dictionary = Kernel.evaluate_action(obstructed,Records.initial_state(obstructed),{"kind":0,"face_axis":2},Rules.idle_context())
			check(result.status == 1 and result.rejection_code == 2103 and result.issues.any(func(i):return &"middle_obstacle" in i.entity_ids),"exact interior curve witness rejects despite clear endpoints/chord")
		var tangent := {"trajectory_version":"pfall.departure_cubic.v1","departure_points2":[Vector3i(-5,0,0),Vector3i(-3,0,0)],"descent_control_points2":[Vector3i(-3,0,0),Vector3i(-3,0,0),Vector3i(6,0,0),Vector3i(-3,0,0)]}
		var unresolved: Dictionary = sweep.prove(tangent,[Base.cube(&"tangent",0,Vector3i(3,0,0))],0)
		check(unresolved.status == 2 and unresolved.issues.any(func(i):return i.code == 1601),"non-dyadic tangency stops at bounded UNPROVEN, never sampled SAFE")
		var extreme: Dictionary = sweep.prove(F.trajectory(),[Base.cube(&"far",0,Vector3i(2147483646,2147483646,2147483646))],0)
		check(extreme.status == 0,"far int32 obstacles separate before scaling without arithmetic overflow")
		var too_large := F.trajectory()
		too_large.descent_control_points2[1] = Vector3i(1000001,6,0)
		var overflow: Dictionary = sweep.prove(too_large,[],0)
		check(overflow.status == 3 and overflow.issues.any(func(i):return i.code == 1105),"overflow is ERROR1105, not safety permission")
		# Pure proof limits: these are shape-valid trajectories, not gameplay
		# permission fixtures. Exercise both the root and subdivision budgets.
		var many_far: Array = []
		many_far.resize(100001)
		many_far.fill(Base.cube(&"far_budget",0,Vector3i(1000002,1000002,1000002)))
		var root_budget: Dictionary = sweep.prove(F.trajectory(),many_far,0)
		check(root_budget.status == 2 and root_budget.issues.any(func(i):return i.code == 1601),"root obstacle budget exhausts as UNPROVEN")
		var many_tangent: Array = []
		many_tangent.resize(50000)
		many_tangent.fill(Base.cube(&"hull_budget",0,Vector3i(3,0,0)))
		var hull_budget: Dictionary = sweep.prove(tangent,many_tangent,0)
		check(hull_budget.status == 2 and hull_budget.issues.any(func(i):return i.code == 1601 and i.message.contains("budget")),"retained hull budget exhausts as UNPROVEN")
		for bound in [-1000000,1000000]:
			var boundary := {"trajectory_version":"pfall.departure_cubic.v1","departure_points2":[Vector3i(bound,bound,bound),Vector3i(bound,bound,bound)],"descent_control_points2":[Vector3i(bound,bound,bound),Vector3i(bound,bound,bound),Vector3i(bound,bound,bound),Vector3i(bound,bound,bound)]}
			var retained: Dictionary = sweep.prove(boundary,[Base.cube(&"near_bound",0,Vector3i(bound+1,bound+1,bound+1))],0)
			check(retained.status == 1 and retained.issues.any(func(i):return i.code == 1204 and &"near_bound" in i.entity_ids),"near-bound scaled interior is collision checked without overflow")
	var summary := {"checks":checks,"failures":failures,"doubles":[],"authority":"synthetic approved geometry; actual Baker/Kernel/Safety; pure proof boundary cases","observations":observations}
	FileAccess.open(OS.get_environment("FOUNDATION_TEST_EVIDENCE").path_join("results.json"),FileAccess.WRITE).store_string(JSON.stringify(summary))
	print("CURVE_SAFETY checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
