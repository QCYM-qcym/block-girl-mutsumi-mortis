extends SceneTree
const F = preload("res://tests/beta_sprint/game_feel_owner_01/curve_fixtures.gd")
const Old = preload("res://tests/beta_sprint/game_feel_owner_01/fixtures.gd")
const Base = preload("res://tests/foundation/level/baker_fixture.gd")
const Baker = preload("res://foundation/level/level_baker.gd")
const Codec = preload("res://foundation/level/level_codec.gd")
const Records = preload("res://foundation/contracts/contract_records.gd")
const Key = preload("res://foundation/contracts/state_key.gd")
var checks := 0
var failures: Array[String] = []
var legacy_identity: Array = []
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func _initialize() -> void:
	create_timer(20).timeout.connect(func():printerr("TEST_TIMEOUT");quit(2))
	call_deferred("run")
func run() -> void:
	for old in [Base.make_golden_level(),Old.level()]:
		var identity: Dictionary = Codec.compute_content_hash(old)
		check(identity.ok,"legacy canonical content remains valid")
		if identity.ok:
			old.content_hash = identity.content_hash
			legacy_identity.append({"hash":identity.content_hash,"text":Codec.encode(old).text,"key":Key.build(old,Records.initial_state(old)).key})
	for higher in [false,true]:
		var baked: Dictionary = Baker.bake(F.authoring(higher),{"max_configurations":4096,"max_checks":100000})
		check(baked.ok,"schema3 real Baker accepts the closed curve profile")
		if baked.ok:
			var level: Dictionary = baked.level
			var text: Dictionary = Codec.encode(level)
			var decoded: Dictionary = Codec.decode(text.text)
			check(text.ok and decoded.ok and decoded.level == level,"single formal Codec roundtrips ordered Vector3i controls")
			check(level.perspective_falls[0].trajectory == F.trajectory(higher),"control ordering and exact integer endpoints survive canonical wire")
			var state: Dictionary = Records.initial_state(level)
			var key: Dictionary = Key.build(level,state)
			check(state.get("camera_quadrant") == 1 and key.ok and key.key.begins_with("statekey.game_feel.v1:"),"schema3 core/key keeps the camera and existing canonical format")
			check(key.key.contains('"rule_version":"foundation.rules.game_feel.v2"'),"new rule identity is bound in the formal key")
			var polluted: Dictionary = state.duplicate(true)
			polluted["trajectory"] = F.trajectory(higher)
			check(not Key.build(level,polluted).ok,"trajectory is author geometry, never PuzzleState")
			for field in ["trajectory","path_points2"]:
				var bad: Dictionary = level.duplicate(true)
				bad.perspective_falls[0][field] = {} if field == "trajectory" else []
				check(not Codec.compute_content_hash(bad).ok,"no implicit trajectory or polyline fallback")
	var wrong: Dictionary = F.authoring()
	wrong.schema_version = 2
	wrong.contract_version = "foundation.game_feel.v1"
	wrong.rule_version = "foundation.rules.game_feel.v1"
	check(not Baker.bake(wrong,{"max_configurations":4096,"max_checks":100000}).ok,"old schema2 cannot reinterpret a new trajectory")
	var module_path := "res://foundation/game_feel/trajectory_profile.gd"
	check(ResourceLoader.exists(module_path),"approved pure sampler dependency exists")
	if ResourceLoader.exists(module_path):
		var api: Variant = load(module_path)
		for higher in [false,true]:
			var profile: Dictionary = F.trajectory(higher)
			var original: Dictionary = profile.duplicate(true)
			var wants := [Vector3(0,3,0),Vector3(-0.5,3,0),Vector3(-1,3,0),Vector3(-2.375,4.75 if higher else 2.375,2),Vector3(-3,5 if higher else 1,4)]
			var parameters := [0.0,0.125,0.25,0.625,1.0]
			for i in parameters.size():
				var sample: Dictionary = api.sample_actor_center(profile,parameters[i])
				check(sample.ok and sample.position == wants[i],"literal world-unit line/cubic sample at "+str(parameters[i]))
				check(sample == api.sample_actor_center(profile,parameters[i]),"repeated pure sampling is deterministic")
			check(profile == original,"pure sampling never mutates the authorized payload")
			for u in [-0.01,1.01,NAN,INF]:
				var bad: Dictionary = api.sample_actor_center(profile,u)
				check(not bad.ok and bad.position == null and not bad.issues.is_empty(),"invalid parameter rejects rather than clamping")
			for fault in ["unknown","version","missing","count","float","overflow"]:
				var invalid: Dictionary = profile.duplicate(true)
				match fault:
					"unknown": invalid["curve"] = 0
					"version": invalid.trajectory_version = "pfall.departure_cubic.v2"
					"missing": invalid.erase("departure_points2")
					"count": invalid.descent_control_points2.pop_back()
					"float": invalid.descent_control_points2[1] = Vector3(-4,6,0)
					"overflow": invalid.descent_control_points2[1] = Vector3i(-1000001,6,0)
				var bad: Dictionary = api.sample_actor_center(invalid,0.5)
				check(not bad.ok and bad.position == null,"closed trajectory rejects "+fault)
	var summary := {"checks":checks,"failures":failures,"doubles":[],"authority":"synthetic approved author DATA; real Baker/Codec/Key and pure sampler","legacy_identity":legacy_identity}
	FileAccess.open(OS.get_environment("FOUNDATION_TEST_EVIDENCE").path_join("results.json"),FileAccess.WRITE).store_string(JSON.stringify(summary))
	print("CURVE_PROFILE checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
