extends "res://tests/foundation/authoring_integration/test_suite.gd"
const Support = preload("res://tests/foundation/authoring_quality/test_quality_workflow.gd")
const Workflow = preload("res://tools/foundation/authoring_quality/quality_workflow.gd")
const Selected = preload("res://tools/foundation/authoring_quality/selected_trace_checks.gd")
const Intents = preload("res://tests/foundation/quality/intent/intent_fixtures.gd")
const Records = preload("res://foundation/contracts/contract_records.gd")
const Explorer = preload("res://foundation/solver/state_explorer.gd")
const Search = preload("res://foundation/solver/search_records.gd")
const Trace = preload("res://foundation/solver/solution_trace.gd")
const IntentTypes = preload("res://foundation/quality/intent/intent_types.gd")
var evidence: Array = []

func analyze(level: Dictionary, intent: Dictionary, label: String, policy: Dictionary = {}) -> Dictionary:
	if policy.is_empty(): policy = Support.RunRecords.default_execution_policy("ACCEPT_SAVED")
	var identity := Support.identity_for(level,policy)
	var before := intent.duplicate(true)
	var result := Workflow.run_quality(level,intent,policy,identity,Support.control_for(identity))
	check(intent == before,label + ": intent unchanged")
	evidence.append({"case":label,"result":result})
	return result

func run() -> void:
	for name in ["required_shift","shift_bypass","optional_mechanism"]:
		var fixture := Intents.scenario(name)
		var result := analyze(fixture.level,fixture.intent,name)
		var valid := Support.stage(result,"INTENT_VALIDATE")
		check(not valid.is_empty(),name + ": explicit formal Intent validation")
		if not valid.is_empty(): check(valid.native_result.ok,name + ": valid intent")
		var ablation := Support.stage(result,"ABLATION")
		check(not ablation.is_empty(),name + ": formal ablation performed")
		if not ablation.is_empty():
			check(ablation.native_result.status == 0,name + ": ablation complete")
			var sub: Dictionary = ablation.native_result.ablations[0]
			check(sub.essential == (name == "required_shift"),name + ": actual necessity")
			check(sub.bypass_detected == (name == "shift_bypass"),name + ": required vs optional bypass")
			if name == "optional_mechanism": check(not ablation.native_result.advisories.is_empty(),"unused mechanism remains advisory")
		var semantic := Support.stage(result,"TRACE_SEMANTICS")
		check(not semantic.is_empty(),name + ": selected semantic validation exists")
		if not semantic.is_empty(): check(semantic.native_result.ok,name + ": selected semantics pass")
		var milestone := Support.stage(result,"MILESTONES")
		check(not milestone.is_empty(),name + ": selected milestones exist")
		if not milestone.is_empty(): check(milestone.native_result.status == 0 and milestone.native_result.scope == "SINGLE_TRACE",name + ": selected SINGLE_TRACE match")
		check(is_same(result.selected_trace_ref.trace,Support.stage(result,"ORIGINAL_GRAPH").native_result.solution_trace),name + ": selected retains original object")
	var level := Support.Fixtures.corridor(3)
	var empty := Intents.empty_intent(level)
	for kind in ["empty","optional_only","milestone_only","invalid","missing"]:
		var intent := empty.duplicate(true)
		if kind == "optional_only": intent.optional_mechanics = [IntentTypes.MechanicTag.MOVE]
		if kind == "milestone_only": intent.expected_milestones = [Intents.milestone(&"goal",{"kind":4})]
		if kind == "invalid": intent.level_hash = "0".repeat(64)
		if kind == "missing": intent = {}
		var result := analyze(level,intent,kind)
		var valid := Support.stage(result,"INTENT_VALIDATE")
		check(not valid.is_empty(),kind + ": validation stage retained")
		if not valid.is_empty():
			if kind == "missing": check(valid.native_result == null and valid.reason == "MISSING_INPUT","missing is not empty")
			else: check(valid.native_result.ok == (kind != "invalid"),kind + ": actually validated")
		var abl := Support.stage(result,"ABLATION")
		check(not abl.is_empty(),kind + ": ablation applicability recorded")
		if not abl.is_empty():
			if kind in ["empty","milestone_only"]: check(abl.applicability == "NOT_APPLICABLE" and abl.native_result == null,kind + ": no mechanic declarations")
			elif kind == "optional_only": check(abl.native_result.ablations.size() == 1,"optional is actual request")
			else: check(abl.native_result == null and abl.applicability == "APPLICABLE","bad intent does not become empty")
	var many: Dictionary = Support.Fixtures.bake(Support.Locks.make_authoring("multiple_goals")).level
	var many_intent := Intents.empty_intent(many)
	many_intent.optional_mechanics = [6]
	many_intent.expected_milestones = [Intents.milestone(&"sky",{"kind":3,"mechanic":6})]
	var multi := analyze(many,many_intent,"distinct witnesses")
	var original: Dictionary = Support.stage(multi,"ORIGINAL_GRAPH").native_result
	var ablated := Support.stage(multi,"ABLATION")
	if not ablated.is_empty() and ablated.get("native_result") is Dictionary:
		check(ablated.native_result.baseline.solution_trace.policy_descriptor.mode == 0 and original.solution_trace.policy_descriptor.mode == 1,"baseline FIRST_SHORTEST identity distinct from original FULL_GRAPH")
		check(multi.selected_trace_ref.trace == original.solution_trace,"ablation baseline does not replace selected witness")
	var alternative := {}
	for node in original.graph.nodes.values():
		if node.is_goal and node.state.celestial.slot_id == &"b":
			alternative = Trace.from_graph(many,original.graph,node.state_key).trace
			break
	check(not alternative.is_empty(),"actual alternative solution obtained from live graph")
	if not alternative.is_empty():
		var selected := Selected.check_selected(many,many_intent,alternative,Records.initial_state(many))
		check(selected.get("semantics",{}).get("ok",false),"alternate is real semantic witness")
		check(selected.get("milestones",{}).get("status") == 0,"alternate selected witness matches sky milestone")
		var primary := Support.stage(multi,"MILESTONES")
		check(not primary.is_empty() and primary.get("native_result",{}).get("status") == 1,"original witness bypass retained despite alternate solution")
	var search := Search.default_policy(0)
	var other := Records.initial_state(level)
	other.player.location = {"layer":0,"cube_id":&"cell1","face":4}
	var foreign := Explorer.explore(level,other,search,Support.RunRecords.default_execution_policy("ACCEPT_SAVED").search_budget)
	check(foreign.status == 0 and Trace.validate_semantics(level,foreign.solution_trace).ok,"real non-Spawn trace is semantically valid")
	var rejected := Selected.check_selected(level,empty,foreign.solution_trace,Records.initial_state(level))
	check(rejected.get("spawn_matches") == false and rejected.get("semantics") == null,"non-Spawn selection rejected before semantics")
	var forged: Dictionary = original.solution_trace.duplicate(true)
	forged.steps[0].action.face_axis = 2
	check(Trace.validate(many,forged).ok,"forgery is structurally valid")
	var denied := Selected.check_selected(many,many_intent,forged,Records.initial_state(many))
	check(denied.get("semantics",{}).get("ok") == false and denied.get("milestones") == null,"semantic forgery cannot reach milestones")
	var zero: Dictionary = Support.Fixtures.bake(Support.Locks.make_authoring("initial_goal")).level
	var zero_intent := Intents.empty_intent(zero)
	zero_intent.expected_milestones = [Intents.milestone(&"goal",{"kind":4})]
	var zero_result := analyze(zero,zero_intent,"zero step goal")
	var zero_checks := Support.stage(zero_result,"MILESTONES")
	check(zero_result.selected_trace_ref.trace.total_actions == 0,"zero-step trace retained")
	check(not zero_checks.is_empty() and zero_checks.get("native_result",{}).get("sample_indices",{}).get(&"goal") == 0,"zero-step goal milestone at initial sample")
	var required := Intents.scenario("required_shift")
	var tight := Support.RunRecords.default_execution_policy("ACCEPT_SAVED")
	tight.search_budget.max_action_evaluations = 6
	var budget_result := analyze(required.level,required.intent,"ablation budget",tight)
	var budget_abl := Support.stage(budget_result,"ABLATION")
	check(not budget_abl.is_empty(),"budget ablation stage exists")
	if not budget_abl.is_empty():
		check(budget_abl.execution == "INCOMPLETE" and budget_abl.native_result.ablations[0].essential == null and budget_abl.native_result.ablations[0].bypass_detected == null,"ablated budget never guesses conclusion")
	var file := FileAccess.open(evidence_dir().path_join("selected_calls.txt"),FileAccess.WRITE)
	file.store_string(var_to_str(evidence)); file.close()
	finish()
