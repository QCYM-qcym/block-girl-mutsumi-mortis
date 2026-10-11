extends SceneTree
const F = preload("res://tests/beta_sprint/spatial_owner_01/fixtures.gd")
const Baker = preload("res://foundation/level/level_baker.gd")
const Kernel = preload("res://foundation/rules/puzzle_rule_kernel.gd")
const Rules = preload("res://foundation/rules/rule_records.gd")
const Records = preload("res://foundation/contracts/contract_records.gd")
const Key = preload("res://foundation/contracts/state_key.gd")
const Derived = preload("res://foundation/rules/derived_state_resolver.gd")
const Classifier = preload("res://foundation/quality/intent/mechanic_classifier.gd")
const Safety = preload("res://foundation/validation/safety_queries.gd")
var checks := 0
var failures: Array[String] = []
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func _initialize() -> void:
	_fixed()
	_latch()
	print("SPATIAL_RULES checks=",checks," failures=",failures," doubles=[]")
	quit(0 if failures.is_empty() else 1)
func bake(value: Dictionary) -> Dictionary:
	value.erase("content_hash")
	return Baker.bake(value,{"max_configurations":4096,"max_checks":100000})
func run_action(level: Dictionary, state: Dictionary, action: Dictionary) -> Dictionary:
	var bytes := var_to_bytes([level,state,action])
	var result := Kernel.evaluate_action(level,state,action,Rules.idle_context())
	check(var_to_bytes([level,state,action]) == bytes,"kernel inputs immutable")
	return result
func denied(level: Dictionary, state: Dictionary, action: Dictionary, code: int, label: String) -> void:
	var key := Key.build(level,state)
	var result := run_action(level,state,action)
	check(result.status == 1 and result.rejection_code == code,label + " exact formal rejection " + str(result))
	check(result.next_state == null and not result.changed,label + " no partial state")
	check(Key.build(level,state) == key,label + " key unchanged")
func _fixed() -> void:
	var value := F.level()
	var baked := bake(value)
	check(baked.ok,"fixed gate real Baker " + str(baked.issues))
	if not baked.ok: return
	var level: Dictionary = baked.level
	var state := Records.initial_state(level)
	var applied := run_action(level,state,{"kind":1})
	check(applied.status == 0,"fixed gate applied")
	if applied.status == 0:
		check(applied.next_state.player.location == {"layer":1,"cube_id":&"mirror","face":4},"exact mapped target")
		check(applied.next_state.player.orientation == 0 and applied.next_state.camera_quadrant == 1,"Shift preserves orientation and camera")
		check(Safety.validate_motion(level,state,applied.next_state,{"kind":1}).status == 0,"real shift Safety")
	var missing := level.duplicate(true)
	missing.shift_gates = []
	check(Derived.shift_mapping(missing,state).status == 1,"off-point has real UNIQUE mapping")
	denied(missing,state,{"kind":1},2010,"off-point")
	var target := level.duplicate(true)
	target.shift_gates[0].target_face_id = &"goal/TOP"
	denied(target,state,{"kind":1},2012,"gate bound target must match geometry")
	var lit := level.duplicate(true)
	lit.celestial.slots[0].position2 = Vector3i(0,10,0)
	denied(lit,state,{"kind":1},1403,"gate cannot bypass Shadow")
	var blocked := level.duplicate(true)
	F.face(blocked,&"floor/TOP").shift_exit_blocked = true
	denied(blocked,state,{"kind":1},1404,"gate cannot bypass exit block")
	blocked = level.duplicate(true)
	F.face(blocked,&"mirror/TOP").shift_entry_blocked = true
	denied(blocked,state,{"kind":1},1405,"gate cannot bypass entry block")
func _latch() -> void:
	var baked := bake(F.level(true))
	check(baked.ok,"latch real Baker " + str(baked.issues))
	if not baked.ok: return
	var level: Dictionary = baked.level
	var initial := Records.initial_state(level)
	denied(level,initial,{"kind":1},2011,"locked gate")
	var wrong := initial.duplicate(true)
	wrong.player.orientation = 22
	var arrived := run_action(level,wrong,{"kind":0,"face_axis":0})
	check(arrived.status == 0,"wrong pose still MOVE applied")
	if arrived.status == 0:
		check(arrived.next_state.player.location.cube_id == &"step" and arrived.next_state.mechanism_states.face_lock == &"inactive","wrong face no activation at same sensor")
		var classified := Classifier.classify_transition(level,arrived)
		check(classified.ok and classified.tags == [0] and classified.mechanism_ids.is_empty(),"wrong contact is only MOVE")
	var correct := run_action(level,initial,{"kind":0,"face_axis":0})
	check(correct.status == 0,"correct contact MOVE applied")
	if correct.status != 0: return
	check(correct.next_state.player.orientation == 12,"post-roll golden orientation")
	check(correct.next_state.mechanism_states.face_lock == &"latched","correct local RIGHT face contact latches")
	check(correct.global_kind == 0 and correct.next_state.level_flags == initial.level_flags,"single local candidate and flags unchanged")
	check(Safety.validate_motion(level,initial,correct.next_state,correct.action).status == 0,"Roll+latch real Safety")
	var classification := Classifier.classify_transition(level,correct)
	check(classification.ok and classification.tags == [0,7] and classification.mechanism_ids == [&"face_lock"],"real latch mechanism classification")
	var returned := run_action(level,correct.next_state,{"kind":0,"face_axis":2})
	check(returned.status == 0,"leave sensor")
	if returned.status != 0: return
	check(returned.next_state.mechanism_states.face_lock == &"latched","latch persists after leave")
	var repeated := run_action(level,returned.next_state,{"kind":0,"face_axis":0})
	check(repeated.status == 0,"repeat contact MOVE applied")
	if repeated.status == 0:
		check(repeated.next_state == correct.next_state,"repeat contact is idempotent")
		classification = Classifier.classify_transition(level,repeated)
		check(classification.ok and classification.tags == [0] and classification.mechanism_ids.is_empty(),"repeat contact does not trigger again")
	var shift := run_action(level,returned.next_state,{"kind":1})
	check(shift.status == 0,"unlocked gate applied")
	if shift.status == 0:
		check(shift.next_state.player.orientation == returned.next_state.player.orientation and shift.next_state.mechanism_states == returned.next_state.mechanism_states,"unlock Shift preserves pose+latch")
	denied(level,correct.next_state,{"kind":5,"mechanism_id":&"face_lock"},1503,"ENTER sensor cannot be used manually")
