extends SceneTree
const F = preload("res://tests/beta_sprint/game_feel_owner_01/fixtures.gd")
const Data = preload("res://foundation/contracts/contract_validation.gd")
const Records = preload("res://foundation/contracts/contract_records.gd")
const Key = preload("res://foundation/contracts/state_key.gd")
const Codec = preload("res://foundation/level/level_codec.gd")
var checks := 0
var failures: Array[String] = []
func check(ok: bool, name: String) -> void:
	checks += 1
	if not ok: failures.append(name)
func _initialize() -> void:
	create_timer(20).timeout.connect(func(): printerr("TEST_TIMEOUT: did not reach result boundary"); quit(2))
	call_deferred("run")
func run() -> void:
	for higher in [false,true]:
		var level := F.level(higher)
		check(Data.validate_level_shape(level).is_empty(),"explicit v2 level has a closed accepted schema")
		var state := Records.initial_state(level)
		check(state.get("camera_quadrant",-1) == 1,"authoritative initial camera is core state")
		check(Data.validate_action_shape(level,{"kind":8,"connection_id":&"edge_a"}).is_empty(),"semantic Fall action is versioned")
		check(Data.validate_action_shape(level,{"kind":9,"camera_quadrant":0}).is_empty(),"semantic discrete view action is versioned")
		var key := Key.build(level,state)
		check(key.ok and key.key.begins_with("statekey.game_feel.v1:"),"camera has a separate canonical StateKey version")
		var identity := Codec.compute_content_hash(level)
		check(identity.ok,"sole formal Codec includes authored Fall rule data")
		if identity.ok:
			level.content_hash = identity.content_hash
			var encoded := Codec.encode(level)
			check(encoded.ok,"v2 Level canonical encoding succeeds")
			if encoded.ok:
				var decoded := Codec.decode(encoded.text)
				check(decoded.ok and decoded.level == level,"exact v2 typed wire roundtrip")
	var extended := F.level()
	extended.content_hash = Codec.compute_content_hash(extended).content_hash
	var core := Records.initial_state(extended)
	var original := Key.build(extended,core)
	for quadrant in 4:
		var variant := core.duplicate(true)
		variant.camera_quadrant = quadrant
		check(Key.build(extended,variant).ok,"each finite quadrant has a valid identity")
		check((Key.build(extended,variant).key == original.key) == (quadrant == 1),"camera qualification changes exact key")
	for field in ["Camera","RotateTarget","AnimationProgress","FaceLightState"]:
		var polluted := core.duplicate(true)
		polluted[field] = 0
		check(not Key.build(extended,polluted).ok,"presentation fields cannot enter canonical core: " + field)
	var reversed := {}
	var fields: Array = extended.keys()
	fields.reverse()
	for field in fields: reversed[field] = extended[field]
	check(Codec.encode(reversed).text == Codec.encode(extended).text,"root map insertion order never changes wire")
	var changed := extended.duplicate(true)
	changed.perspective_falls[0].path_points2[1] = Vector3i(-3,6,3)
	check(Codec.compute_content_hash(changed).content_hash != extended.content_hash,"authored path binds level identity")
	changed = extended.duplicate(true)
	changed.contract_version = "foundation.game_feel.v2"
	check(not Data.validate_level_shape(changed).is_empty(),"unapproved versions fail closed")
	changed = extended.duplicate(true)
	changed.perspective_falls[0]["extra"] = true
	check(not Data.validate_level_shape(changed).is_empty(),"connection is a closed record")
	var old := F.F.make_golden_level()
	check(Data.validate_level_shape(old).is_empty(),"legacy v1 remains valid")
	check(not Data.validate_action_shape(old,{"kind":8,"connection_id":&"edge_a"}).is_empty(),"new action is never a private legacy kind8 alias")
	old["camera_initial_quadrant"] = 1
	check(not Data.validate_level_shape(old).is_empty(),"v1 still rejects added fields")
	var result := {"checks":checks,"failures":failures,"doubles":[],"display":DisplayServer.get_name(),"user_dir":OS.get_user_data_dir()}
	FileAccess.open(OS.get_environment("FOUNDATION_TEST_EVIDENCE").path_join("results.json"),FileAccess.WRITE).store_string(JSON.stringify(result))
	print(JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)
