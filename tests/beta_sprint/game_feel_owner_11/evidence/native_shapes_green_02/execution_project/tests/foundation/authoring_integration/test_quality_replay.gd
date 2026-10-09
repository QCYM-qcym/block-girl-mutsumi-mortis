extends "res://tests/foundation/authoring_integration/test_suite.gd"
## I2 consumes one sealed D4 job through all actual Owner implementations.
## The optional Real branch remains a separately labelled headless preflight.
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
const Schemas = preload("res://tools/foundation/authoring_acceptance/wire_schemas.gd")
const TaskService = preload("res://tools/foundation/authoring_acceptance/task_service.gd")
const Codec = preload("res://foundation/level/level_codec.gd")
const Types = preload("res://foundation/contracts/foundation_types.gd")
const Session = preload("res://foundation/runtime/runtime_session.gd")
const Presenter = preload("res://foundation/runtime/prototype_presenter.gd")
const Goal = preload("res://foundation/rules/goal_evaluator.gd")
const MECHANICS := "res://tests/foundation/authoring_integration/maps/b_mechanics/"
const BASE := "res://tests/foundation/authoring_integration/maps/d3_action_capable/"
var observations: Array = []

func stage(result: Dictionary, id: String) -> Dictionary:
	for item in result.get("stages", []):
		if item.stage_id == id: return item
	return {}

func run() -> void:
	if mode() == "Graphical":
		check(DisplayServer.get_name() != "headless", "I2 requires an actual graphical parent")
		await _controlled_job(false)
		await _controlled_job(true)
		check(Execution.write_new(evidence_dir().path_join("i2-job-evidence.json"), JSON.stringify({"scope":"I2_FORMAL_D4_JOBS", "doubles":doubles, "cases":observations}, "\t").to_utf8_buffer()).ok, "raw same-run I2 observations preserved")
		finish()
		return
	check(mode() == "Real" and DisplayServer.get_name() == "headless", "explicit headless Real preflight scope")
	for limited in [false, true]:
		_chain(limited)
	var file := FileAccess.open(evidence_dir().path_join("quality-preflight.txt"), FileAccess.WRITE)
	check(file != null, "raw native records preserved")
	if file != null:
		file.store_string(var_to_str({"scope": "I2_HEADLESS_PREFLIGHT_OUTSIDE_D4_JOB", "sealed_capabilities": Execution.CAPABILITIES, "graphical": "NOT_EXERCISED_IN_THIS_PREFLIGHT", "algorithm_doubles": [], "boundary_status_provider": "LOCAL_TEST_HOST_INPUT; no D4 IPC, lease renewal or cancellation proof", "cases": observations}))
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

func _controlled_job(limited: bool) -> void:
	var label := "budget" if limited else "complete"
	var saved := ProjectSettings.globalize_path("res://.godot/i2_saved_" + label + "/" + Execution.uuid())
	check(DirAccess.make_dir_recursive_absolute(saved) == OK, label + ": disposable author source directory")
	var source_root := ProjectSettings.localize_path(saved).trim_suffix("/") + "/"
	var originals := {}
	for name in ["level.tscn", "surface.tscn", "inner.tscn", "intent.tres"]:
		originals[name] = FileAccess.get_file_as_bytes(MECHANICS + name)
		var text: String = originals[name].get_string_from_utf8().replace(MECHANICS, source_root)
		check(Execution.write_new(saved.path_join(name), text.to_utf8_buffer()).ok, label + ": actual saved author source " + name)
	var policy := Runs.default_execution_policy("ANALYZE_CURRENT")
	policy.stages = Schemas.ACCEPT_STAGES.slice(0, 10)
	if limited: policy.search_budget.max_states = 1
	var request := {"entry_kind":"ANALYZE_CURRENT", "level_ref":{"level_authoring_id":"00000000-0000-4000-8000-000000000001", "level_id":&"b_mechanics", "root_source_uri":source_root + "level.tscn"}, "policy":policy}
	var service := TaskService.new()
	get_root().add_child(service)
	var started: Dictionary = service.start(request)
	check(started.ok, label + ": same-run TaskService captures and launches selected full pipeline")
	if not started.ok:
		print("I2_JOB_START_REJECTED ", started.issues)
		service.queue_free()
		await process_frame
		return
	var identity: Dictionary = started.value.identity
	var transport: RefCounted = service._transport
	var pid: int = transport._pid
	check(pid > 0 and pid != OS.get_process_id(), label + ": actual independent worker process")
	check(not service.start(request).ok, label + ": real job retains single heavy slot")
	var snapshot := Execution.snapshot_from_run(transport._root)
	check(snapshot.ok, label + ": worker input.ready snapshot is durable")
	var verified := Execution.verify(snapshot.value) if snapshot.ok else snapshot
	check(verified.ok and verified.value.manifest.identity == identity, label + ": exact sealed run identity verified")
	if verified.ok:
		check(verified.value.policy == policy and identity.policy_digest == Wire.digest("policy", policy).value, label + ": actual policy and budget sealed before worker")
		for id in policy.stages:
			var uri: String = Execution.stage_module(id)
			check(verified.value.files.has(uri) and verified.value.files[uri] == FileAccess.get_file_as_bytes(uri), label + ": formal Owner module sealed " + id)
		for uri in ["res://tools/foundation/authoring_acceptance/graphical_entry.gd", "res://foundation/runtime/prototype_presenter.gd", "res://foundation/runtime/runtime_session.gd"]:
			check(verified.value.files.has(uri), label + ": actual graphical execution dependency " + uri)
	var deadline := Time.get_ticks_msec() + 180000
	var graphical_started := -1
	var graphical_elapsed := -1
	var final: Dictionary = service.status(identity)
	while final.ok and not final.value.release_confirmed and Time.get_ticks_msec() < deadline:
		if final.value.stage_id == "GRAPHICAL_REPLAY" and graphical_started < 0: graphical_started = Time.get_ticks_msec()
		if graphical_started >= 0 and graphical_elapsed < 0 and not _stored_stage(transport.stored_results(), "GRAPHICAL_REPLAY").is_empty(): graphical_elapsed = Time.get_ticks_msec() - graphical_started
		await process_frame
		final = service.status(identity)
	if graphical_started >= 0 and graphical_elapsed < 0: graphical_elapsed = Time.get_ticks_msec() - graphical_started
	check(final.ok and final.value.release_confirmed and final.value.lifecycle == "COMPLETED", label + ": real worker completes and confirms resource release")
	if not final.ok or not final.value.release_confirmed:
		service.cancel(identity)
		while final.ok and not final.value.release_confirmed:
			await process_frame
			final = service.status(identity)
	var release: Dictionary = transport.release_state(identity)
	for field in ["process_exited", "file_handles_closed", "callbacks_disconnected", "preview_resources_released"]:
		check(release.get(field, false), label + ": release gate confirms " + field)
	var stored: Array = transport.stored_results()
	var omitted: Array = transport.omitted_stages()
	var expected: Array = policy.stages.slice(0, 7) if limited else policy.stages
	check(stored.size() == expected.size(), label + ": exact number of genuinely executed native stages")
	var refs := {}
	for index in stored.size():
		var wrapped: Dictionary = stored[index]
		var item: Dictionary = wrapped.stage_record
		check(wrapped.run_identity == identity, label + ": immutable stage shares exact run identity " + item.stage_id)
		check(index < expected.size() and item.stage_id == expected[index], label + ": storage preserves approved formal stage order")
		check(item.module_ref == Execution.stage_module(item.stage_id) and item.owner == Execution.stage_owner(item.stage_id), label + ": producer is formal Owner " + item.stage_id)
		check(item.native_result != null and item.execution in (["COMPLETED", "INCOMPLETE"] if limited else ["COMPLETED"]), label + ": native outcome is retained " + item.stage_id)
		var path: String = "artifacts/stages/" + item.stage_id + "/stage_result.wire"
		var raw := Execution.read_bytes(transport._root.path_join(path))
		var decoded := Wire.decode_wire("stage_result", raw.value) if raw.ok else raw
		check(decoded.ok and decoded.value == wrapped, label + ": formal StageResult wire equals accepted storage " + item.stage_id)
		if raw.ok: refs[item.stage_id] = Execution.artifact(path, raw.value, "foundationtoolwire.v1")
	var bake := _stored_stage(stored, "BAKE")
	var bound := _stored_stage(stored, "INTENT_BIND")
	var original := _stored_stage(stored, "ORIGINAL_GRAPH")
	var soft := _stored_stage(stored, "SOFTLOCK")
	if bake.is_empty() or bound.is_empty() or original.is_empty() or soft.is_empty():
		check(false, label + ": required native producer missing")
	else:
		check(bound.native_result.ok and bound.input_refs.bake_result == refs.BAKE and bound.input_refs.canonical == bake.evidence_refs.canonical, label + ": real A_EDIT Binder consumes same-run Bake")
		check(verified.ok and bound.native_result.source_intent_digest == snapshot.value.identity.source_intent_digest and bound.input_refs.source_intent_digest == bound.native_result.source_intent_digest, label + ": captured source Intent digest retained")
		var canonical := Execution.read_artifact(transport._root, bake.evidence_refs.canonical)
		var level: Dictionary = Codec.decode(canonical.value.get_string_from_utf8()) if canonical.ok else canonical
		check(level.ok, label + ": actual canonical attachment decoded by formal Codec")
		if level.ok:
			for item in stored.slice(3):
				check(item.stage_record.input_refs.canonical == bake.evidence_refs.canonical and item.stage_record.input_refs.level_hash == level.level.content_hash and item.stage_record.input_refs.initial_statekey == Key.build(level.level, Records.initial_state(level.level)).key, label + ": quality/replay share same canonical and spawn " + item.stage_record.stage_id)
		check(original.actual_policy.mode == 1 and original.actual_policy.filter_descriptor.filter_id == &"UNFILTERED" and original.actual_budget == policy.search_budget, label + ": actual FULL_GRAPH and unfiltered budget")
		check(soft.input_refs.original_graph_result == refs.ORIGINAL_GRAPH, label + ": Softlock consumes same-run original exploration")
		var graph_bytes := Execution.read_artifact(transport._root, original.evidence_refs.graph_archive)
		var graph := Wire.decode_wire("graph_archive", graph_bytes.value) if graph_bytes.ok else graph_bytes
		check(graph.ok and graph.value.complete == (not limited), label + ": graph archive preserves true completeness")
		if limited:
			check(original.execution == "INCOMPLETE" and original.native_result.status == 2 and original.native_result.budget_reason != 0, "budget: exhaustion remains native INCOMPLETE")
			check(soft.execution == "INCOMPLETE" and soft.native_result.softlock_count == null, "budget: partial graph cannot prove zero softlocks")
			check(original.evidence_refs.selected_trace_ref == null and original.native_result.solution_trace == null, "budget: no unsupported selected trace")
			check(omitted.size() == 3, "budget: exactly three unavailable trace consumers omitted")
			var limited_ablation := _stored_stage(stored, "ABLATION")
			check(limited_ablation.actual_budget == policy.search_budget and limited_ablation.execution == "INCOMPLETE" and limited_ablation.native_result.status == 1 and limited_ablation.native_result.baseline.status == 2, "budget: Ablation preserves its actual exhausted baseline and sealed budget")
			check(limited_ablation.native_result.ablations.is_empty() and limited_ablation.native_result.baseline.solution_trace == null, "budget: exhausted baseline cannot invent essential-mechanic or trace evidence")
			for id in ["TRACE_SEMANTICS", "MILESTONES", "GRAPHICAL_REPLAY"]:
				var rows: Array = omitted.filter(func(item): return item.stage_id == id)
				check(rows.size() == 1 and rows[0].execution == "NOT_RUN" and rows[0].native_result == null and _stored_stage(stored, id).is_empty(), "budget: no fabricated evidence " + id)
		else:
			check(omitted.is_empty() and original.native_result.status == 0 and soft.native_result.status == 0 and soft.native_result.softlock_count == 0, "complete: full graph and real Softlock conclusion")
			_verify_selected_chain(stored, bound, original, transport._root, graphical_elapsed)
	var messages: Array = []
	for name in DirAccess.get_files_at(transport._channel("worker_to_parent")):
		var bytes := Execution.read_bytes(transport._channel("worker_to_parent").path_join(name))
		var decoded := Wire.decode_wire("worker_message", bytes.value) if bytes.ok else bytes
		check(decoded.ok, label + ": actual IPC uses formal WorkerMessage")
		if decoded.ok: messages.append(decoded.value)
	messages.sort_custom(func(a, b): return a.sequence < b.sequence)
	var starts: Array = []
	var results: Array = []
	for index in messages.size():
		var message: Dictionary = messages[index]
		check(message.sequence == index and message.identity == identity, label + ": same-run contiguous worker sequence")
		if message.kind == "STAGE_STARTED": starts.append(message.stage_id)
		if message.kind == "STAGE_RESULT": results.append(message.stage_id)
	check(starts == expected and results == expected, label + ": each actual native call has matching start/result IPC")
	check(not messages.is_empty() and messages[0].kind == "HELLO" and messages[0].payload_ref_or_inline.worker_role == "GRAPHICAL", label + ": actual controlled Graphical worker HELLO")
	check(not messages.is_empty() and messages.back().kind == "EXIT" and messages.back().payload_ref_or_inline.reason == "FINISHED" and not transport.release_error(), label + ": durable EXIT agrees with owned OS completion")
	for name in originals:
		check(FileAccess.get_file_as_bytes(MECHANICS + name) == originals[name], label + ": original fixture unchanged " + name)
	if not limited and not bake.is_empty(): await _manual_mechanics(transport._root, identity, bake.evidence_refs.canonical)
	observations.append({"case":label, "pid":pid, "launch_id":transport._launch, "run_dir":transport._root, "identity":identity, "policy":policy, "status":final, "release":release, "records":stored, "omitted":omitted, "messages":messages, "graphical_elapsed_msec":graphical_elapsed})
	service.queue_free()
	await process_frame

func _stored_stage(stored: Array, id: String) -> Dictionary:
	for wrapped in stored:
		if wrapped.stage_record.stage_id == id: return wrapped.stage_record
	return {}

func _verify_selected_chain(stored: Array, bound: Dictionary, original: Dictionary, run_root: String, elapsed: int) -> void:
	if original.evidence_refs.selected_trace_ref == null:
		check(false, "complete: successful original exploration must supply selected trace")
		return
	var selected: Dictionary = original.evidence_refs.selected_trace_ref
	check(selected.origin == "ORIGINAL_GRAPH", "complete: selected trace originates in same-run original graph")
	var bytes := Execution.read_artifact(run_root, selected.trace)
	var decoded := Wire.decode_wire("trace", bytes.value) if bytes.ok else bytes
	check(decoded.ok and decoded.value == original.native_result.solution_trace, "complete: archival selected trace matches actual native solution")
	for id in ["INTENT_VALIDATE", "ABLATION", "MILESTONES"]:
		var item := _stored_stage(stored, id)
		check(item.input_refs.bound_intent == bound.evidence_refs.bound_intent, "complete: same-run captured BoundIntent consumed " + id)
	check(_stored_stage(stored, "INTENT_VALIDATE").native_result.ok, "complete: real formal Intent validation")
	var ablation := _stored_stage(stored, "ABLATION")
	check(ablation.native_result.status == 0 and ablation.native_result.baseline.status == 0 and ablation.native_result.ablations[0].essential, "complete: real required MOVE ablation")
	for id in ["TRACE_SEMANTICS", "MILESTONES", "GRAPHICAL_REPLAY"]:
		var item := _stored_stage(stored, id)
		check(item.input_refs.selected_trace == selected.trace and item.input_refs.selected_trace_digest == selected.trace.sha256, "complete: exact selected trace consumed " + id)
	check(_stored_stage(stored, "TRACE_SEMANTICS").native_result.ok, "complete: formal Trace semantics")
	var milestones := _stored_stage(stored, "MILESTONES")
	check(decoded.ok and milestones.native_result.status == 0 and milestones.native_result.scope == "SINGLE_TRACE" and milestones.native_result.sample_indices.finish == decoded.value.total_actions, "complete: required Goal milestone reaches selected trace endpoint")
	var replay := _stored_stage(stored, "GRAPHICAL_REPLAY")
	check(replay.module_ref == "res://foundation/parity/trace_replayer.gd" and replay.actual_policy.mode == 1 and replay.native_result.status == 0 and replay.native_result.matched_steps > 0, "complete: formal actual Graphical Replayer matches")
	check(replay.native_result.matched_steps == replay.native_result.trace_length and replay.native_result.expected_statekey == replay.native_result.actual_statekey and replay.native_result.actual_statekey == decoded.value.goal_statekey, "complete: Runtime StateKey MATCH with same-run selected trace")
	check(elapsed > 0, "complete: graphical scheduling duration observed separately from natural Tween proof")

func _manual_mechanics(run_root: String, identity: Dictionary, canonical_ref: Dictionary) -> void:
	var raw := Execution.read_artifact(run_root, canonical_ref)
	var decoded: Dictionary = Codec.decode(raw.value.get_string_from_utf8()) if raw.ok else raw
	check(decoded.ok, "manual: exact same-run canonical attachment verified by formal Codec")
	if not decoded.ok: return
	var session := Session.new()
	var presenter := Presenter.new()
	get_root().add_child(presenter)
	var loaded: Dictionary = session.load_level(decoded.level)
	check(loaded.ok, "manual: independent actual RuntimeSession initializes from formal Spawn")
	if not loaded.ok:
		presenter.queue_free()
		await process_frame
		return
	check(presenter.sync_state(session.level, session.state).ok, "manual: actual Presenter displays formal Spawn")
	var initial: String = Key.build(session.level, session.state).key
	var actions: Array = []
	actions.append(await _natural_action(session, presenter, {"kind":Types.PuzzleActionKind.MOVE, "face_axis":Types.FaceAxis.U_POS}, false, "MOVE"))
	var goal := Goal.is_goal(session.level, session.state)
	check(goal.ok and goal.is_goal, "manual: formal Goal reached after MOVE")
	session.reset()
	check(Key.build(session.level, session.state).key == initial and session.commit_count == 0, "manual: real Runtime Reset restores Spawn StateKey")
	check(presenter.sync_state(session.level, session.state).ok, "manual: Presenter follows actual Reset")
	actions.append(await _natural_action(session, presenter, {"kind":Types.PuzzleActionKind.ROTATE_INNER, "rotation_delta":22}, true, "WORLD_ROTATION"))
	actions.append(await _natural_action(session, presenter, {"kind":Types.PuzzleActionKind.SHIFT_WORLD}, true, "WORLD_SHIFT"))
	check(Key.build(session.level, session.state).key != initial, "manual: successful shift changes formal StateKey")
	session.reset()
	check(Key.build(session.level, session.state).key == initial and session.commit_count == 0, "manual: Reset restores rotated/shifted Runtime independently of Replayer")
	check(presenter.sync_state(session.level, session.state).ok, "manual: actual Presenter displays final Reset")
	observations.append({"case":"manual_same_run_mechanics", "run_identity":identity, "canonical_ref":canonical_ref, "loaded":loaded, "actions":actions, "goal":goal, "reset_statekey":Key.build(session.level, session.state).key, "initial_statekey":initial})
	presenter.queue_free()
	await process_frame

func _natural_action(session: RefCounted, presenter: Node, action: Dictionary, global: bool, label: String) -> Dictionary:
	var commits: int = session.commit_count
	var before: String = Key.build(session.level, session.state).key
	var ticket := {}
	var observed := func(_result: Dictionary, id: int, generation: int, is_global: bool) -> void:
		ticket.assign({"id":id, "generation":generation, "is_global":is_global})
	session.transition_started.connect(observed, CONNECT_ONE_SHOT)
	var outcome: Dictionary = session.request_action(action)
	check(outcome.get("status", -1) == 0, "manual: legal formal action APPLIED " + label)
	if outcome.get("status", -1) != 0:
		if session.transition_started.is_connected(observed): session.transition_started.disconnect(observed)
		print("I2_MANUAL_ACTION_FAILURE ", label, " ", outcome)
		return {"label":label, "native":outcome}
	check(ticket.get("is_global", not global) == global, "manual: proper local/global transition " + label)
	var animated: Dictionary = presenter.animate_transition(session.level, outcome, 0.30)
	check(animated.ok, "manual: formal Presenter accepts actual transition " + label)
	if not animated.ok: return {"label":label, "native":outcome, "animation":animated}
	var finished := [false]
	var tween: Tween = animated.tween
	check(tween.is_valid() and tween.is_running(), "manual: actual owned Presenter Tween running " + label)
	tween.finished.connect(func(): finished[0] = true, CONNECT_ONE_SHOT)
	var frames := 0
	var deadline := Time.get_ticks_msec() + 10000
	while not finished[0] and Time.get_ticks_msec() < deadline:
		frames += 1
		await process_frame
	check(finished[0] and frames > 0, "manual: natural Tween.finished and observed frames " + label)
	check(session.commit_count == commits, "manual: no early logical commit before natural Tween " + label)
	var completion: Dictionary = session.finish_global(ticket.id, ticket.generation) if global else session.finish_local(ticket.id, ticket.generation)
	check(not completion.ignored and session.commit_count == commits + 1, "manual: natural completion commits exactly once " + label)
	check(presenter.sync_state(session.level, session.state).ok, "manual: Presenter follows committed endpoint " + label)
	presenter.clear_previews()
	await process_frame
	return {"label":label, "action":action, "native":outcome, "ticket":ticket, "natural_tween_finished":finished[0], "frames":frames, "completion":completion, "before_statekey":before, "after_statekey":Key.build(session.level, session.state).key, "commit_delta":session.commit_count - commits}
