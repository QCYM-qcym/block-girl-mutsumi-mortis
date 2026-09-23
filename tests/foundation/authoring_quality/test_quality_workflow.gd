extends "res://tests/foundation/authoring_integration/test_suite.gd"

const Workflow = preload("res://tools/foundation/authoring_quality/quality_workflow.gd")
const StageRecords = preload("res://tools/foundation/authoring_quality/quality_stage_records.gd")
const RunRecords = preload("res://tools/foundation/authoring_acceptance/run_records.gd")
const Schemas = preload("res://tools/foundation/authoring_acceptance/wire_schemas.gd")
const Wire = preload("res://tools/foundation/authoring_acceptance/tool_wire.gd")
const Boundary = preload("res://tools/foundation/authoring_acceptance/boundary_control.gd")
const Fixtures = preload("res://tests/foundation/solver/solver_fixtures.gd")
const Locks = preload("res://tests/foundation/quality/softlock/softlock_fixtures.gd")
const Intents = preload("res://tests/foundation/quality/intent/intent_fixtures.gd")
const Records = preload("res://foundation/contracts/contract_records.gd")
const Key = preload("res://foundation/contracts/state_key.gd")
var evidence: Array = []

static func identity_for(level: Dictionary, policy: Dictionary) -> Dictionary:
	# Actual controlled checkout/engine identity from I0; source fingerprint is
	# explicitly fixture metadata, not a claim of an A/D captured authoring run.
	var base := OS.get_environment("FOUNDATION_TEST_EVIDENCE").get_base_dir().get_base_dir()
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base.path_join("identity.json")))
	var modules: Array = []
	for item in source.sources:
		if item.path.ends_with(".gd") or item.path.ends_with(".uid"):
			modules.append({"path":"res://" + item.path,"sha256":item.sha256,"version":null})
	modules.sort_custom(func(a: Dictionary, b: Dictionary): return a.path < b.path)
	var versions := {"record_version":"foundationversions.v1","tool_version":"authoringrun.v1",
		"schemas":Schemas.SCHEMA_VERSIONS.duplicate(),"contracts":Schemas.CONTRACT_VERSIONS.duplicate(),
		"engine":{"version":source.engine.version,"executable_sha256":source.engine.sha256},
		"modules":modules,"configuration":[{"path":"res://project.godot","sha256":FileAccess.get_sha256("res://project.godot"),"version":null}]}
	var snapshot := {"identity":{"run_id":"11111111-1111-4111-8111-111111111111","snapshot_id":"22222222-2222-4222-8222-222222222222","source_fingerprint":"a".repeat(64),"source_intent_digest":null}}
	var level_ref := {"level_authoring_id":"33333333-3333-4333-8333-333333333333","level_id":level.level_id,"root_source_uri":"res://tests/foundation/solver/solver_fixtures.gd"}
	return RunRecords.make_identity("44444444-4444-4444-8444-444444444444",0,level_ref,snapshot,Wire.digest("policy",policy).value,Wire.digest("versions",versions).value,versions)

static func control_for(identity: Dictionary) -> RefCounted:
	var status := {"identity":identity,"cancelled":false,"lease_deadline_msec":Time.get_ticks_msec()+30000,"stage_deadline_msec":Time.get_ticks_msec()+300000}
	return Boundary.new(identity, func(): return status)

static func stage(result: Dictionary, id: String) -> Dictionary:
	for item in result.get("stages",[]):
		if item.stage_id == id: return item
	return {}

func execute(level: Dictionary, policy: Dictionary, label: String) -> Dictionary:
	var identity := identity_for(level,policy)
	check(not identity.is_empty(),label + ": formal identity constructed")
	var intent := Intents.empty_intent(level)
	var before := [level.duplicate(true),policy.duplicate(true),intent.duplicate(true),identity.duplicate(true)]
	var result := Workflow.run_quality(level,intent,policy,identity,control_for(identity))
	check(result.has("stages"),label + ": quality stages returned")
	check(not result.has("verdict") and not result.has("PASS"),label + ": no acceptance verdict")
	check([level,policy,intent,identity] == before,label + ": inputs unchanged")
	evidence.append({"case":label,"result":result})
	return result

func run() -> void:
	var policy := RunRecords.default_execution_policy("ACCEPT_SAVED")
	var level := Fixtures.corridor(3)
	var result := execute(level,policy,"corridor")
	var original := stage(result,"ORIGINAL_GRAPH")
	var softlock := stage(result,"SOFTLOCK")
	check(not original.is_empty(),"corridor: original graph exists")
	check(not softlock.is_empty(),"corridor: softlock exists")
	if not original.is_empty() and not softlock.is_empty():
		check(original.native_result.status == 0 and original.native_result.graph.complete,"corridor: solved FULL_GRAPH")
		check(original.actual_policy.mode == 1 and original.actual_policy.filter_descriptor.filter_id == &"UNFILTERED" and original.actual_policy.transition_filter.is_null(),"formal unfiltered policy without injected options")
		check(original.native_result.graph.initial_key == Key.build(level,Records.initial_state(level)).key,"formal Spawn key")
		check(softlock.native_result.status == 0 and softlock.native_result.softlock_count == 0,"corridor zero softlocks")
		check(softlock.native_result.initial_key == original.native_result.graph.initial_key and softlock.native_result.metrics.nodes_checked == original.native_result.graph.nodes.size(),"same exploration scope consumed")
		check(original.native_result.metrics.has("safety_unproven_rejections"),"original safety unknown metric preserved")
		check(result.selected_trace_ref.trace == original.native_result.solution_trace and result.selected_trace_ref.origin == "ORIGINAL_GRAPH","select original trace")
	for name in ["sink","cycle"]:
		var baked := Fixtures.bake(Locks.make_authoring(name))
		check(baked.ok,name + ": real Baker accepts authored fixture")
		if not baked.ok: continue
		var locks := stage(execute(baked.level,policy,name),"SOFTLOCK")
		check(not locks.is_empty(),name + ": softlock stage exists")
		if not locks.is_empty():
			check(locks.native_result.status == 0 and locks.native_result.softlock_count > 0,name + ": real softlocks proven")
			check(locks.native_result.reset_recoverable_count == locks.native_result.softlock_count,name + ": Reset recovery does not subtract locks")
	var limited := policy.duplicate(true)
	limited.search_budget.max_states = 1
	var partial := execute(level,limited,"max_states")
	var bounded := stage(partial,"ORIGINAL_GRAPH")
	check(not bounded.is_empty(),"budget stage exists")
	if not bounded.is_empty():
		check(bounded.native_result.status == 2 and bounded.execution == "INCOMPLETE" and bounded.native_result.budget_reason != 0,"actual BUDGET_EXCEEDED unchanged")
		check(stage(partial,"SOFTLOCK").native_result.softlock_count == null,"partial graph cannot prove zero softlocks")
	var local := RunRecords.default_execution_policy("ANALYZE_CURRENT")
	local.stages = ["ORIGINAL_GRAPH","SOFTLOCK"]
	local.search_mode = 0
	var local_result := execute(level,local,"local first shortest")
	var local_stage := stage(local_result,"ORIGINAL_GRAPH")
	check(not local_stage.is_empty(),"local graph exists")
	if not local_stage.is_empty():
		check(local_stage.native_result.status == 0 and not local_stage.native_result.graph.complete,"single trace is not complete graph")
		check(stage(local_result,"SOFTLOCK").execution == "INCOMPLETE","local softlock remains incomplete")
	var invalid := policy.duplicate(true)
	invalid.search_mode = 0
	var denied := Workflow.run_quality(level,Intents.empty_intent(level),invalid,identity_for(level,policy),control_for(identity_for(level,policy)))
	check(not denied.get("issues",[]).is_empty() and stage(denied,"ORIGINAL_GRAPH").get("native_result") == null,"ACCEPT_SAVED cannot substitute FIRST_SHORTEST")
	var source := Locks.make_authoring("sink")
	var branch_level: Dictionary = Fixtures.bake(source).level
	limited = policy.duplicate(true)
	limited.search_budget.max_states = 2
	var with_trace := execute(branch_level,limited,"budget with trace")
	var trace_stage := stage(with_trace,"ORIGINAL_GRAPH")
	check(not trace_stage.is_empty(),"budget-with-trace stage exists")
	if not trace_stage.is_empty():
		check(trace_stage.native_result.status == 2 and trace_stage.native_result.solution_trace is Dictionary,"trace cannot replace exhausted FULL_GRAPH")
		check(trace_stage.execution == "INCOMPLETE" and with_trace.selected_trace_ref.trace == trace_stage.native_result.solution_trace,"retain budget and its selected witness")
	var injected := policy.duplicate(true)
	injected.graph = {}
	var refused := Workflow.run_quality(level,Intents.empty_intent(level),injected,identity_for(level,policy),control_for(identity_for(level,policy)))
	check(not refused.get("issues",[]).is_empty() and stage(refused,"ORIGINAL_GRAPH").get("native_result") == null,"caller graph option refused by D schema")
	var file := FileAccess.open(evidence_dir().path_join("quality_calls.txt"),FileAccess.WRITE)
	file.store_string(var_to_str(evidence)); file.close()
	finish()
