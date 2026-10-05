extends "res://tests/foundation/authoring_integration/test_suite.gd"
## I2 headless preflight only. GRAPHICAL awaits the actual D4 service entry.
## D2 seals AUTHORING/BAKE/MANUAL_RUNTIME capabilities. Binder and C quality
## below run from this checkout outside a D4 controlled job; its selected job
## execution closure and graphical replay dispatch are not delivered here.
const Capture = preload("res://tools/foundation/authoring_acceptance/snapshot_capture.gd")
const Execution = preload("res://tools/foundation/authoring_acceptance/execution_project.gd")
const Adapter = preload("res://foundation/authoring/authoring_adapter.gd")
const Binder = preload("res://foundation/authoring/intent_binder.gd")
const Workflow = preload("res://tools/foundation/authoring_quality/quality_workflow.gd")
const Runs = preload("res://tools/foundation/authoring_acceptance/run_records.gd")
const Wire = preload("res://tools/foundation/authoring_acceptance/tool_wire.gd")
const Boundary = preload("res://tools/foundation/authoring_acceptance/boundary_control.gd")
const Trace = preload("res://foundation/solver/solution_trace.gd")
const Key = preload("res://foundation/contracts/state_key.gd")
const Records = preload("res://foundation/contracts/contract_records.gd")
const BASE := "res://tests/foundation/authoring_integration/maps/d3_action_capable/"
const GRAPHICAL_PENDING := ["tools/foundation/authoring_acceptance/task_service.gd::replay_run", "tools/foundation/authoring_acceptance/graphical_entry.gd", "tools/foundation/authoring_acceptance/worker_entry.gd selected quality job closure", "tools/foundation/authoring_acceptance/execution_dependencies.json selected D4 job closure"]
var observations: Array = []

func stage(result: Dictionary, id: String) -> Dictionary:
	for item in result.get("stages", []):
		if item.stage_id == id: return item
	return {}

func run() -> void:
	if mode() == "Graphical":
		check(false, "DEPENDENCY_PENDING: actual D4 graphical replay and selected execution closure: " + str(GRAPHICAL_PENDING))
		finish()
		return
	check(mode() == "Real" and DisplayServer.get_name() == "headless", "explicit headless Real preflight scope")
	for limited in [false, true]:
		_chain(limited)
	var file := FileAccess.open(evidence_dir().path_join("quality-preflight.txt"), FileAccess.WRITE)
	check(file != null, "raw native records preserved")
	if file != null:
		file.store_string(var_to_str({"scope": "I2_HEADLESS_PREFLIGHT_OUTSIDE_D4_JOB", "sealed_capabilities": Execution.CAPABILITIES, "graphical": "DEPENDENCY_PENDING", "pending": GRAPHICAL_PENDING, "algorithm_doubles": [], "boundary_status_provider": "LOCAL_TEST_HOST_INPUT; no D4 IPC, lease renewal or cancellation proof", "cases": observations}))
		file.close()
	finish()

func _chain(limited: bool) -> void:
	var label := "budget" if limited else "complete"
	var base := ProjectSettings.localize_path(evidence_dir()).trim_suffix("/") + "/saved_" + label + "/"
	check(DirAccess.make_dir_recursive_absolute(base) == OK, label + ": disposable saved author source")
	var originals := {}
	for name in ["level.tscn", "surface.tscn", "inner.tscn", "intent.tres"]:
		originals[name] = FileAccess.get_file_as_bytes(BASE + name)
		var text: String = originals[name].get_string_from_utf8().replace(BASE, base)
		if name == "intent.tres": text = _intent_text(text)
		var source := FileAccess.open(base + name, FileAccess.WRITE)
		check(source != null, label + ": save " + name)
		if source == null: return
		source.store_string(text)
		source.close()
	var policy := Runs.default_execution_policy("ACCEPT_SAVED")
	if limited: policy.search_budget.max_states = 1
	var request := {"entry_kind": "ACCEPT_SAVED", "level_ref": {"level_authoring_id": "00000000-0000-4000-8000-000000000001", "level_id": &"d3_action_capable", "root_source_uri": base + "level.tscn"}, "policy": policy}
	var captured := Capture.capture_saved(request, ProjectSettings.globalize_path("res://").replace("\\", "/").trim_suffix("/"))
	check(captured.ok, label + ": actual D2 saved capture")
	if not captured.ok:
		print("I2_CAPTURE_ISSUES ", captured.issues)
		return
	var verified := Execution.verify(captured.value)
	check(verified.ok, label + ": sealed payload and digests verified")
	if not verified.ok: return
	var payload: Dictionary = verified.value.authoring
	var baked := Adapter.bake_authoring(payload, verified.value.policy.bake_options, captured.value.identity)
	check(baked.ok, label + ": current captured author through formal Reader/Baker/Validator")
	if not baked.ok: return
	var table: Array[Dictionary] = []
	table.assign(payload.resource_table)
	var author := {}
	for entry in table:
		if entry.kind == "INTENT": author = entry.fields
	var bound := Binder.bind_intent(author, table, baked, captured.value.identity)
	check(bound.ok, label + ": same-capture Intent binds")
	if not bound.ok: return
	check(bound.source_intent_digest == captured.value.identity.source_intent_digest, label + ": original source Intent digest retained")
	var identity: Dictionary = verified.value.manifest.identity
	check(not identity.is_empty(), label + ": D2 snapshot identity accepted for local quality call (outside D4 job)")
	check(identity.policy_digest == Wire.digest("policy", policy).value and identity.execution_digest == captured.value.execution_digest, label + ": exact sealed D2 identity and policy retained")
	# A local test status provider supplies a healthy boundary observation. This
	# does not exercise D4 IPC, real lease renewal, process ownership or cancel.
	var status := {"identity": identity, "cancelled": false, "lease_deadline_msec": Time.get_ticks_msec()+30000, "stage_deadline_msec": Time.get_ticks_msec()+300000}
	var control := Boundary.new(identity, func(): return status)
	var before := var_to_bytes([payload, baked, bound, policy, identity])
	var result := Workflow.run_quality(baked.level, bound.bound_intent, policy, identity, control)
	check(result.issues.is_empty(), label + ": quality has no tool errors")
	check(not result.has("verdict") and not result.has("PASS"), label + ": no acceptance verdict")
	check(stage(result, "INTENT_VALIDATE").native_result.ok, label + ": actual formal Intent validation")
	var original := stage(result, "ORIGINAL_GRAPH")
	var soft := stage(result, "SOFTLOCK")
	check(original.actual_policy.mode == 1 and original.actual_policy.filter_descriptor.filter_id == &"UNFILTERED" and original.actual_policy.transition_filter.is_null(), label + ": FULL_GRAPH UNFILTERED real search")
	check(original.actual_budget == policy.search_budget, label + ": actual budget preserved")
	check(original.input_refs.level_hash == baked.level.content_hash and original.native_result.graph.initial_key == Key.build(baked.level, Records.initial_state(baked.level)).key, label + ": canonical and Spawn identity")
	if limited:
		check(original.execution == "INCOMPLETE", "budget: exhaustion remains incomplete")
		check(original.native_result.status == 2 and original.native_result.budget_reason != 0 and not original.native_result.graph.complete, "budget: native exhaustion flags retained")
		check(soft.execution == "INCOMPLETE" and soft.native_result.softlock_count == null, "budget: partial graph cannot prove zero locks")
		check(result.selected_trace_ref == null and stage(result, "TRACE_SEMANTICS").execution == "NOT_RUN" and stage(result, "MILESTONES").execution == "NOT_RUN", "budget: missing trace prevents semantic and milestone claims")
	else:
		check(original.execution == "COMPLETED" and original.native_result.status == 0 and original.native_result.graph.complete, "complete: live original graph solved and closed")
		check(soft.native_result.status == 0 and soft.native_result.softlock_count == 0 and soft.native_result.metrics.nodes_checked == original.native_result.graph.nodes.size(), "complete: softlock consumes original exploration scope")
		check(result.selected_trace_ref.origin == "ORIGINAL_GRAPH" and result.selected_trace_ref.trace == original.native_result.solution_trace, "complete: original selected trace retained")
		check(Trace.validate_semantics(baked.level, result.selected_trace_ref.trace).ok and stage(result, "TRACE_SEMANTICS").native_result.ok, "complete: same selected trace uses formal Kernel semantics")
		var milestone: Dictionary = stage(result, "MILESTONES").native_result
		check(milestone.status == 0 and milestone.scope == "SINGLE_TRACE" and milestone.sample_indices.finish == result.selected_trace_ref.trace.total_actions, "complete: required Goal milestone matches selected single trace")
		var ablation: Dictionary = stage(result, "ABLATION").native_result
		check(ablation.status == 0 and ablation.baseline.status == 0 and ablation.ablations[0].essential == true, "complete: real required MOVE ablation")
	check(var_to_bytes([payload, baked, bound, policy, identity]) == before, label + ": quality preserves all source inputs")
	for name in originals:
		check(FileAccess.get_file_as_bytes(BASE + name) == originals[name], label + ": source fixture unchanged " + name)
	observations.append({"case": label, "snapshot": captured.value, "bake": baked, "binding": bound, "quality": result})

func _intent_text(original: String) -> String:
	var prefix := '[gd_resource type="Resource" load_steps=4 format=3]\n[ext_resource type="Script" path="res://foundation/authoring/intent_authoring_resource.gd" id="Intent"]\n[ext_resource type="Script" path="res://foundation/authoring/milestone_authoring_resource.gd" id="Milestone"]\n[sub_resource type="Resource" id="Finish"]\nscript = ExtResource("Milestone")\nauthoring_id = "00000000-0000-4000-8000-000000000500"\nmilestone_id = &"finish"\nrequired = true\npredicate = {"kind": 4}\n'
	return prefix + original.substr(original.find("[resource]")).replace("required_mechanics = []", "required_mechanics = [0]").replace("expected_milestones = []", 'expected_milestones = [SubResource("Finish")]')
