extends SceneTree
const Fixture = preload("res://tests/beta_sprint/game_feel_owner_10b/fixture.gd")
const Math = preload("res://foundation/orientation/discrete_orientation.gd")
const Geometry = preload("res://foundation/spatial/surface_geometry.gd")
const Mapper = preload("res://foundation/runtime/input_mapper.gd")
var checks := 0
var failures: Array[String] = []
var Edge: Script
var Recoil: Script
var evidence := ""

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="): evidence = arg.trim_prefix("--evidence-dir=")
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func neutral(s: Dictionary) -> bool:
	return not s.active and s.position == null and s.rotation_offset == Quaternion.IDENTITY and s.scale_multiplier == Vector3.ONE

func run() -> void:
	for path in ["res://game/feel/animation/edge_recoil/edge_lean.gd", "res://game/feel/animation/edge_recoil/recoil_motion.gd"]:
		if not ResourceLoader.exists(path):
			check(false, "edge sampler implementation exists: " + path)
			finish(); return
	Edge = load("res://game/feel/animation/edge_recoil/edge_lean.gd")
	Recoil = load("res://game/feel/animation/edge_recoil/recoil_motion.gd")
	if not Edge.can_instantiate() or not Recoil.can_instantiate():
		check(false, "sampler compiles (harness failure, not behavioral RED)")
		finish(); return
	var e = Edge.new()
	var event := Fixture.edge()
	var original := event.duplicate(true)
	var cues: Array = []
	e.cue.connect(func(name: String, id: Dictionary): cues.append([name, id]))
	check(e.begin(event).ok, "explicit EDGE begins")
	check(e.sample(0).rotation_offset == Quaternion.IDENTITY, "initial pose exact")
	var peak: Dictionary = e.sample(0.13)
	check(peak.active and peak.phase == "BLOCKED" and absf(peak.rotation_offset.get_angle() - deg_to_rad(12)) < 0.00001, "small peak, blocked hold")
	check((Basis(peak.rotation_offset) * Vector3.UP).x > 0.2, "FaceAxis U_POS leans world +X")
	check(e.support_pivot_offset().is_equal_approx(Vector3(0.5, -0.5, 0)), "pivot is front bottom edge, not center")
	check(peak.position == null and peak.scale_multiplier == Vector3.ONE, "no logical half-step or scale")
	var tail: Dictionary = e.sample(0.23)
	check(tail.phase == "RECOIL" and tail.rotation_offset.get_angle() < peak.rotation_offset.get_angle(), "rebound moves toward standing")
	check(neutral(e.sample(0.44)) and e.sample(0.9).motion_done, "final absolute pose exact and stable")
	check(cues.map(func(c): return c[0]) == ["EdgeLeanStart", "EdgeBlocked", "EdgeRecoilEnd"], "three one-shot hooks")
	check(event == original, "DTO native state/orientation not mutated")
	check(not e.begin(event).ok, "duplicate completed delivery cannot replay")
	for attempt in range(2, 250):
		check(not e.begin(Fixture.edge(attempt)).ok, "held attempt suppressed %d" % attempt)
	check(cues.size() == 3 and neutral(e.sample(0)), "long hold has no animation flood")
	e.set_intent(null)
	check(e.begin(Fixture.edge(250)).ok, "release rearms fresh attempt")
	e.set_intent(2)
	check(neutral(e.sample(0.05)), "opposite mapped input immediately yields")
	check(e.begin(Fixture.edge(251, 2)).ok, "opposite edge can begin")
	check((Basis(e.sample(0.13).rotation_offset) * Vector3.UP).x < -0.2, "opposite lean signed correctly")
	e.cancel(Fixture.edge(250).presentation_identity)
	check(e.sample(0.14).active, "old attempt cancellation cannot stop new")
	var id: Dictionary = Fixture.edge(251, 2).presentation_identity
	e.cancel(id)
	check(neutral(e.sample(0.2)), "identity cancellation immediately neutral")
	check(not cues.is_empty() and cues.back()[0] != "EdgeRecoilEnd", "cancel does not manufacture normal completion")
	e.clear()
	check(not e.begin(Fixture.edge(249)).ok, "clear retains stale delivery watermark")
	var fresh := Fixture.edge(252)
	fresh.presentation_identity.generation = 2
	check(e.begin(fresh).ok, "new generation admits")
	e.cancel(id)
	check(e.sample(0.1).active, "old generation cancel ignored")
	for reason in ["BUSY", "PAUSED", "MECHANISM_LOCKED", "INVALID_FACE", "SAFETY_REJECTED", "INVALID_ACTION", "WORLD_NOT_ALLOWED", "CAMERA_NOT_ALLOWED", "UNCLASSIFIED_REJECTION", "ERROR"]:
		var bad := Fixture.edge(300)
		bad.reason_category = reason
		check(not e.begin(bad).ok and e.sample(0.1).active, "non-edge does not start or replace: " + reason)
	for change in ["semantic", "version", "status", "changed", "direction", "frame", "token", "target", "identity", "pose"]:
		var bad := Fixture.edge(301)
		match change:
			"semantic": bad.semantic = "ACTION_FEEDBACK"
			"version": bad.contract_version = "game_feel.event.v0"
			"status": bad.result.status = 0
			"changed": bad.result.changed = true
			"direction": bad.intended_move_direction = 4
			"frame": bad.source_frame.v = Vector3i.RIGHT
			"token": bad.transition_identity = {"transaction_id": 7}
			"target": bad.target_pose = bad.source_pose
			"identity": bad.presentation_identity.attempt_id = 8
			"pose": bad.source_pose.orientation = 24
		check(not e.begin(bad).ok, "invalid consumed DTO refused atomically: " + change)
	var isolated = Edge.new()
	var mutable := Fixture.edge()
	isolated.begin(mutable)
	mutable.presentation_identity.attempt_id = 999
	mutable.source_frame.u = Vector3i.LEFT
	check(isolated.sample(0.13).identity is Dictionary and isolated.sample(0.13).identity.attempt_id == 1 and isolated.support_pivot_offset().x == 0.5, "deep snapshot survives caller mutation")
	var sample_copy: Dictionary = isolated.sample(0.13)
	if sample_copy.identity is Dictionary: sample_copy.identity.generation = 99
	check(isolated.sample(0.13).identity is Dictionary and isolated.sample(0.13).identity.generation == 1, "sample identity owned copy")
	check(isolated.sample(NAN).rotation_offset.is_finite() and isolated.sample(-5).rotation_offset.is_finite(), "bad elapsed cannot poison pose")
	var r = Recoil.new()
	check(r.begin(Fixture.edge()).ok, "standalone return validates EDGE DTO")
	check(r.sample(0).rotation_offset.get_angle() > 0.2 and neutral(r.sample(0.265)), "standalone peak to exact neutral")
	var reentrant = Edge.new()
	reentrant.cue.connect(func(name: String, _identity: Dictionary):
		if name == "EdgeBlocked":
			reentrant.clear()
			reentrant.begin(Fixture.edge(2, 2)))
	reentrant.begin(Fixture.edge())
	reentrant.sample(0.44)
	check(reentrant.sample(0.01).active and reentrant.sample(0.01).identity.attempt_id == 2, "old end cannot clean reentrant new effect")
	for connection in reentrant.cue.get_connections(): reentrant.cue.disconnect(connection.callable)
	var nested = Edge.new()
	var ends: Array = []
	nested.cue.connect(func(name: String, _id: Dictionary):
		if name == "EdgeBlocked": nested.sample(1.0)
		if name == "EdgeRecoilEnd": ends.append(name))
	nested.begin(Fixture.edge())
	check(neutral(nested.sample(0.44)) and ends.size() == 1, "nested completion emits end exactly once")
	for connection in nested.cue.get_connections(): nested.cue.disconnect(connection.callable)
	for field in ["status", "previous_state", "next_state", "action", "changed", "rejection_code", "issues", "global_kind"]:
		var incomplete := Fixture.edge()
		incomplete.result.erase(field)
		check(not Edge.new().begin(incomplete).ok, "missing native result field refused: " + field)
	for field in ["kind", "face_axis"]:
		var wrong_type := Fixture.edge()
		wrong_type.result.action[field] = 0.0
		check(not Edge.new().begin(wrong_type).ok, "native action integer type required: " + field)
	var wrong_schema := Fixture.edge()
	wrong_schema.schema_version = 1.0
	check(not Edge.new().begin(wrong_schema).ok, "schema_version exact integer required")
	for Module in [Edge, Recoil]:
		var guarded = Module.new()
		guarded.begin(Fixture.edge())
		guarded.sample(0.1)
		check(not guarded.begin(Fixture.edge()).ok, "public sampler duplicate cannot rewind")
		guarded.clear()
		check(not guarded.begin(Fixture.edge()).ok, "public sampler clear rejects stale replay")
		var new_run := Fixture.edge()
		new_run.level_run_id = "second-run"
		new_run.presentation_identity.level_run_id = "second-run"
		check(guarded.begin(new_run).ok, "new run begins with own monotonic sequence")
		check(not guarded.begin(Fixture.edge(2)).ok, "retired known run cannot preempt current run")
	var rapid = Edge.new()
	rapid.begin(Fixture.edge())
	var before_repeat: Dictionary = rapid.sample(0.1)
	rapid.set_intent(null)
	check(not rapid.begin(Fixture.edge(2)).ok, "rapid release/repress cannot restart an active identical edge cycle")
	check(rapid.sample(0).rotation_offset == before_repeat.rotation_offset, "same-cycle throttle preserves current progress")
	var released = Edge.new()
	released.begin(Fixture.edge())
	released.sample(0.1)
	released.set_intent(null)
	released.set_intent(2)
	check(neutral(released.sample(0.12)), "release then opposite non-edge intent cancels without another EDGE begin")
	geometry_matrix()
	finish()

func geometry_matrix() -> void:
	# Breaking axis resolution, world precomposition or pivot sign must fail these
	# independent plane/corner constraints; no sampler helper builds expectations.
	for face in range(6):
		var frame: Dictionary = Geometry.face_frame(face)
		var n := Vector3(frame.normal)
		var directions: Array[Vector3] = [Vector3(frame.u), Vector3(frame.v), -Vector3(frame.u), -Vector3(frame.v)]
		for orientation in range(24):
			var columns := Math.columns(orientation)
			var base := Basis(Vector3(columns[0]), Vector3(columns[1]), Vector3(columns[2]))
			for axis in range(4):
				var e = Edge.new()
				var event := Fixture.edge(1, axis, face % 2, 0, orientation)
				event.source_pose.location.face = face
				event.source_face.face = face
				event.result.previous_state.player.location.face = face
				event.source_frame = frame
				check(e.begin(event).ok, "six support faces / cube24 admits")
				var s: Dictionary = e.sample(0.13)
				var r := Basis(s.rotation_offset)
				var pivot: Vector3 = e.support_pivot_offset()
				var center := 0.5 * n + pivot - r * pivot
				check((r * n).dot(directions[axis]) > 0.2, "leans toward formal mapped tangent")
				check((center + r * pivot).is_equal_approx(0.5 * directions[axis]), "front support edge stays fixed")
				for x in [-0.5, 0.5]:
					for y in [-0.5, 0.5]:
						for z in [-0.5, 0.5]:
							var corner := center + r * base * Vector3(x,y,z)
							check(corner.dot(n) >= -0.00001, "oriented body never penetrates support plane")
				check(e.sample(1).rotation_offset == Quaternion.IDENTITY and event.source_pose.orientation == orientation, "cube24 formal orientation preserved / visual rest exact")
	var top := Geometry.face_frame(4)
	var keys: Array[Vector2] = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
	var expected := [[1,0,3,2],[2,1,0,3],[3,2,1,0],[0,3,2,1]]
	for quadrant in range(4):
		var camera := Basis(Vector3.UP, quadrant * PI / 2) * Basis(Vector3.RIGHT, Vector3.FORWARD, Vector3.UP)
		for key in range(4):
			var result := Mapper.map_move(top, camera, keys[key])
			check(result.ok and result.action.face_axis == expected[quadrant][key], "native InputMapper quadrant %d screen %d" % [quadrant,key])

func finish() -> void:
	var report := Fixture.META.duplicate(true)
	report.merge({"checks": checks, "failures": failures, "user_data_dir": OS.get_user_data_dir(),
		"display": DisplayServer.get_name(), "engine": Engine.get_version_info(), "pid": OS.get_process_id()})
	if not evidence.is_empty():
		var f := FileAccess.open(evidence.path_join("report.json"), FileAccess.WRITE)
		f.store_string(JSON.stringify(report, "\t"))
	print("EDGE_UNIT checks=%d failures=%d" % [checks, failures.size()])
	for failure in failures: print("FAIL: ", failure)
	quit(0 if failures.is_empty() else 1)
