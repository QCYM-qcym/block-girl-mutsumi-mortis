extends SceneTree
const F = preload("res://tests/beta_sprint/spatial_owner_01/fixtures.gd")
const Baker = preload("res://foundation/level/level_baker.gd")
const Codec = preload("res://foundation/level/level_codec.gd")
const Records = preload("res://foundation/contracts/contract_records.gd")
const Kernel = preload("res://foundation/rules/puzzle_rule_kernel.gd")
const Rules = preload("res://foundation/rules/rule_records.gd")
const Classifier = preload("res://foundation/quality/intent/mechanic_classifier.gd")
var checks := 0
var failures: Array[String] = []
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func _initialize() -> void:
	_state_order()
	_enter_channel()
	print("SPATIAL_REVIEW checks=",checks," failures=",failures," doubles=[]")
	quit(0 if failures.is_empty() else 1)
func _state_order() -> void:
	var wires: Array = []
	for reversed in [false,true]:
		var author := F.level(true)
		author.erase("content_hash")
		author.mechanisms[0].initial_state=&"ready"
		author.mechanisms[0].allowed_states=[&"ready",&"active"]
		if reversed: author.mechanisms[0].allowed_states.reverse()
		author.face_locks[0].latched_state=&"active"
		author.shift_gates[0].required_mechanism_states[0].state=&"active"
		var baked := Baker.bake(author,{"max_configurations":4096,"max_checks":100000})
		check(baked.ok,"Baker accepts exact two-state set regardless of lexical/authored order " + str(reversed) + str(baked.issues))
		if not baked.ok: continue
		var encoded := Codec.encode(baked.level)
		check(encoded.ok and Codec.decode(encoded.text).ok,"two-state codec round trip")
		wires.append(encoded.text)
		var moved := Kernel.evaluate_action(baked.level,Records.initial_state(baked.level),{"kind":0,"face_axis":0},Rules.idle_context())
		check(moved.status==0 and moved.next_state.mechanism_states.face_lock==&"active","nonlexical initial/latched names activate normally")
	check(wires.size()==2 and wires[0]!=wires[1],"existing LevelCodec retains authored allowed_states order in identity")
func _enter_channel() -> void:
	var author := F.level()
	F.face(author,&"step/FRONT").walkable=true
	author.face_transitions=[{"transition_id":&"entry_channel","source_face_id":&"step/TOP","target_face_id":&"step/FRONT","entry_axis":0,"exit_axis":0,"rotation_steps":[2],"required_flags":[]}]
	author.mechanisms=[{"mechanism_id":&"plate","face_id":&"step/TOP","trigger":&"ENTER","action":{"kind":4,"transition_id":&"entry_channel"},"priority":0,"initial_state":&"ready","allowed_states":[&"ready"]}]
	F.face(author,&"step/TOP").mechanism_ids=[&"plate"]
	author.erase("content_hash")
	var baked := Baker.bake(author,{"max_configurations":4096,"max_checks":100000})
	check(baked.ok,"schema4 ENTER channel uses real Baker " + str(baked.issues))
	if not baked.ok: return
	var result := Kernel.evaluate_action(baked.level,Records.initial_state(baked.level),{"kind":0,"face_axis":0},Rules.idle_context())
	check(result.status==0 and result.next_state.player.location=={"layer":0,"cube_id":&"step","face":0},"real MOVE+ENTER ends beyond physical Roll entry")
	if result.status!=0: return
	var classified := Classifier.classify_transition(baked.level,result)
	check(classified.ok and classified.tags==[0,4,7] and classified.mechanism_ids==[&"plate"],"MOVE+ENTER retains mechanism and FaceTransition classifications " + str(classified))
	var forged := result.duplicate(true)
	forged.next_state.player.orientation=(result.next_state.player.orientation+1)%24
	check(not Classifier.classify_transition(baked.level,forged).ok,"classification still rejects nonauthoritative candidate")
