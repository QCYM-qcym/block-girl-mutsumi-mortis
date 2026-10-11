extends SceneTree
const F = preload("res://tests/beta_sprint/spatial_owner_01/fixtures.gd")
const Data = preload("res://foundation/contracts/contract_validation.gd")
const Codec = preload("res://foundation/level/level_codec.gd")
const Records = preload("res://foundation/contracts/contract_records.gd")
const Key = preload("res://foundation/contracts/state_key.gd")
var checks := 0
var failures: Array[String] = []
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func _initialize() -> void:
	for locked in [false,true]:
		var value := F.level(locked)
		var issues := Data.validate_level_shape(value)
		check(issues.is_empty(), "valid closed opt-in level " + str(issues))
		if not issues.is_empty(): continue
		var hashed := Codec.compute_content_hash(value)
		check(hashed.ok,"canonical hash accepts profile")
		if not hashed.ok: continue
		value.content_hash = hashed.content_hash
		var wire := Codec.encode(value)
		check(wire.ok,"single formal codec encodes")
		if not wire.ok: continue
		var decoded := Codec.decode(wire.text)
		check(decoded.ok and Data.validate_level_shape(decoded.level).is_empty() and Codec.encode(decoded.level).text == wire.text,"typed canonical codec round trip")
		if decoded.ok:
			check(typeof(decoded.level.shift_gates[0].gate_id) == TYPE_STRING_NAME and typeof(decoded.level.cubes[0].center2) == TYPE_VECTOR3I,"typed identities and coordinates restored")
		var swapped := value.duplicate(true)
		swapped.shift_gates.reverse()
		check(Codec.encode(swapped).text == wire.text,"gate insertion order canonical")
		var state := Records.initial_state(value)
		check(state.get("camera_quadrant") == 1,"new profile camera included")
		check(Key.build(value,state).ok,"full canonical key accepts latch state")
		check(Key.build(value,state).key.begins_with("statekey.game_feel.v1"),"existing versioned full key spine")
		if locked:
			var changed := state.duplicate(true)
			changed.mechanism_states.face_lock = &"latched"
			check(Key.build(value,changed).key != Key.build(value,state).key,"latch differentiates key")
			_bad(value,"invalid local face",func(x):x.face_locks[0].required_local_face=6)
			_bad(value,"wrong activation policy",func(x):x.face_locks[0].activation_mode=&"HOLD")
			_bad(value,"missing mechanism",func(x):x.face_locks[0].mechanism_id=&"absent")
			_bad(value,"invalid state",func(x):x.shift_gates[0].required_mechanism_states[0].state=&"absent")
			_bad(value,"duplicate lock",func(x):x.face_locks.append(x.face_locks[0].duplicate(true)))
			_bad(value,"sensor requires walkable host",func(x):F.face(x,&"step/TOP").walkable=false)
			_bad(value,"sensor cannot mix ENTER effects",func(x):
				var extra: Dictionary=x.mechanisms[0].duplicate(true)
				extra.mechanism_id=&"other_lock";extra.action.mechanism_id=&"other_lock"
				x.mechanisms.append(extra);F.face(x,&"step/TOP").mechanism_ids.append(&"other_lock"))
		_bad(value,"unknown field",func(x):x.shift_gates[0]["visual"]=true)
		_bad(value,"missing required field",func(x):x.shift_gates[0].erase("required_flags"))
		_bad(value,"String ID rejected",func(x):x.shift_gates[0].gate_id="forward")
		_bad(value,"duplicate source",func(x):x.shift_gates[1].source_face_id=&"floor/TOP")
		_bad(value,"same world",func(x):x.shift_gates[0].target_face_id=&"step/TOP")
		_bad(value,"missing target",func(x):x.shift_gates[0].target_face_id=&"absent/TOP")
		_bad(value,"legacy version rejects new fields",func(x):x.schema_version=3;x.contract_version="foundation.game_feel.v2";x.rule_version="foundation.rules.game_feel.v2")
		_bad(value,"unknown rule",func(x):x.rule_version="foundation.rules.spatial_puzzle.v2")
		_bad(value,"missing opt-in field",func(x):x.erase("shift_gates"))
	print("SPATIAL_CONTRACTS checks=",checks," failures=",failures," doubles=[]")
	quit(0 if failures.is_empty() else 1)
func _bad(value: Dictionary, label: String, mutate: Callable) -> void:
	var bad := value.duplicate(true)
	mutate.call(bad)
	check(not Data.validate_level_shape(bad).is_empty(),label)
