extends "res://tests/foundation/authoring_integration/test_suite.gd"
const Support = preload("res://tests/foundation/authoring_quality/test_quality_workflow.gd")
const Workflow = preload("res://tools/foundation/authoring_quality/quality_workflow.gd")
const StageRecords = preload("res://tools/foundation/authoring_quality/quality_stage_records.gd")
const BoundaryDouble = preload("res://tests/foundation/authoring_quality/boundary_control_double.gd")
const Explorer = preload("res://foundation/solver/state_explorer.gd")
const Search = preload("res://foundation/solver/search_records.gd")
const Ablation = preload("res://foundation/quality/intent/ablation_analyzer.gd")
var evidence: Array = []

func run() -> void:
	doubles = ["res://tests/foundation/authoring_quality/boundary_control_double.gd","UNIT_DOUBLE: native-result safety count / malformed-record injection only"]
	var fixture := Support.Intents.scenario("required_shift")
	var level: Dictionary = fixture.level
	var policy := Support.RunRecords.default_execution_policy("ACCEPT_SAVED")
	var identity := Support.identity_for(level,policy)
	for stop in [["INTENT_VALIDATE",1],["ORIGINAL_GRAPH",2],["TRACE_SEMANTICS",2]]:
		var control := BoundaryDouble.new(stop[0],stop[1])
		var result := Workflow.run_quality(level,fixture.intent,policy,identity,control)
		var origin := Support.stage(result,"ORIGINAL_GRAPH")
		var semantics := Support.stage(result,"TRACE_SEMANTICS")
		check(control.stop_requested() and not result.issues.is_empty(),"cancellation recorded at " + stop[0])
		check(not result.has("verdict"),"cancelled result has no verdict")
		if stop[0] == "INTENT_VALIDATE":
			for stage in result.stages: check(stage.native_result == null and stage.execution == "CANCELLED","before first call: no invented native result " + stage.stage_id)
		elif stop[0] == "ORIGINAL_GRAPH":
			check(origin.native_result.status == 0 and origin.execution == "CANCELLED","post-call cancellation retains actual Solver result")
			check(Support.stage(result,"SOFTLOCK").native_result == null and Support.stage(result,"ABLATION").native_result == null,"post-call cancellation prevents later algorithms")
			check(control.calls.count("ORIGINAL_GRAPH") == 2,"Explorer has only entry/return checkpoints")
		else:
			check(semantics.native_result == null and Support.stage(result,"MILESTONES").native_result == null,"stop after structural check before semantics/milestones")
		check(result.run_identity == identity,"cancellation retains same identity")
		evidence.append({"case":"boundary " + stop[0],"checkpoints":control.calls,"result":result})
	for reason in ["TIMEOUT","LEASE_EXPIRED"]:
		var status := {"identity":identity,"cancelled":false,"lease_deadline_msec":0 if reason == "LEASE_EXPIRED" else Time.get_ticks_msec()+30000,"stage_deadline_msec":0 if reason == "TIMEOUT" else Time.get_ticks_msec()+300000}
		var control := Support.Boundary.new(identity,func(): return status)
		var result := Workflow.run_quality(level,fixture.intent,policy,identity,control)
		for stage in result.stages: check(stage.native_result == null and stage.execution == "ERROR" and stage.reason == reason,reason + " distinct from native search budget " + stage.stage_id)
		evidence.append({"case":reason,"result":result})
	var search := Search.default_policy(1)
	var initial := Support.Records.initial_state(level)
	var raw := Explorer.explore(level,initial,search,policy.search_budget)
	check(raw.status == 0,"real Explorer supplies unit wrapper record")
	var injected := raw.duplicate(true)
	injected.metrics.safety_unproven_rejections = 1
	var before := injected.duplicate(true)
	var wrapped := StageRecords.from_native("ORIGINAL_GRAPH",injected,{},search,policy.search_budget)
	check(wrapped.native_result == before and injected == before,"unknown count and native status not rewritten")
	check(wrapped.native_result.metrics.safety_unproven_rejections == 1 and wrapped.native_result.status == 0,"positive unknown retained without altering SOLVED")
	check(is_same(wrapped.native_result,injected) and is_same(wrapped.native_result.graph,injected.graph),"adapter retains actual result and live graph objects")
	check(not wrapped.has("verdict"),"unknown safety handed to D without C verdict")
	evidence.append({"case":"UNIT_DOUBLE safety count injection","stage":wrapped})
	var incomplete: Dictionary = policy.search_budget.duplicate(true)
	incomplete.max_states = 1
	var budget := Explorer.explore(level,initial,search,incomplete)
	var budget_stage := StageRecords.from_native("ORIGINAL_GRAPH",budget,{},search,incomplete)
	check(budget.status == 2 and budget_stage.execution == "INCOMPLETE" and budget_stage.native_result.budget_reason == budget.budget_reason,"real module budget propagated independently")
	var corrupted := level.duplicate(true)
	corrupted.content_hash = "0".repeat(64)
	var failed := Workflow.run_quality(corrupted,fixture.intent,policy,identity,Support.control_for(identity))
	var error_stage := Support.stage(failed,"ORIGINAL_GRAPH")
	check(error_stage.native_result.status == 3 and error_stage.native_result.graph == null and error_stage.execution == "ERROR","real Solver error retained")
	check(Support.stage(failed,"SOFTLOCK").native_result == null and Support.stage(failed,"SOFTLOCK").reason == "ORIGINAL_GRAPH_UNAVAILABLE","no fake zero-lock graph after Solver error")
	evidence.append({"case":"actual invalid canonical hash","result":failed})
	for malformed in [{"status":0,"issues":[]},{"status":false,"issues":[]},{}]:
		var rejected := StageRecords.from_native("ORIGINAL_GRAPH",malformed,{},search,policy.search_budget)
		check(rejected.execution == "ERROR" and rejected.reason == "NATIVE_RESULT_INVALID","malformed native record must not complete")
	var extra := raw.duplicate(true)
	extra.unapproved = true
	check(StageRecords.from_native("ORIGINAL_GRAPH",extra,{},search,policy.search_budget).reason == "NATIVE_RESULT_INVALID","unknown native field rejected")
	var absent := StageRecords.not_run("SOFTLOCK","ORIGINAL_GRAPH_UNAVAILABLE",{})
	check(absent.native_result == null and absent.execution == "NOT_RUN" and absent.started_at == null and absent.finished_at == null,"unrun record has no invented result or timestamps")
	var actual_ablation := Ablation.analyze(level,initial,fixture.intent,Search.default_policy(0),policy.search_budget)
	check(actual_ablation.status == 0,"actual ablation supplies complete unit input")
	var unknown := actual_ablation.duplicate(true)
	unknown.baseline.metrics.safety_unproven_rejections = 2
	unknown.ablations[0].metrics.ablated.safety_unproven_rejections = 3
	var unknown_stage := StageRecords.from_native("ABLATION",unknown,{},Search.default_policy(0),policy.search_budget)
	check(unknown_stage.native_result.baseline.metrics.safety_unproven_rejections == 2 and unknown_stage.native_result.ablations[0].metrics.ablated.safety_unproven_rejections == 3,"ablation baseline and child safety unknown remain independent")
	check(unknown_stage.native_result.status == actual_ablation.status,"safety unknown does not rewrite Ablation enum")
	evidence.append({"case":"UNIT_DOUBLE ablation safety injection","stage":unknown_stage})
	var file := FileAccess.open(evidence_dir().path_join("failure_calls.txt"),FileAccess.WRITE)
	file.store_string(var_to_str(evidence)); file.close()
	finish()
