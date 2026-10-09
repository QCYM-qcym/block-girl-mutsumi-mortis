extends SceneTree
## Consumer of 00's actual host and 01's explicit event port. No host/Runtime/finish implementation.
const O = preload("res://foundation/orientation/discrete_orientation.gd")
const StateKey = preload("res://foundation/contracts/state_key.gd")
const Capture = preload("res://tests/beta_sprint/game_feel_owner_03/capture_identity.gd")
const CONTRACT_HASH = "6224f8cd364f98da41822eabe7ba2973fa2db01d030373e7b3e94d69f35f23de"
const KEY_CODES = {"W": KEY_W, "A": KEY_A, "S": KEY_S, "D": KEY_D, "Q": KEY_Q, "E": KEY_E,
	"F": KEY_F, "Space": KEY_SPACE, "R": KEY_R, "Escape": KEY_ESCAPE}
var evidence := ""
var case_id := "CORE_A_NATURAL_FALL"
var binding_path := "res://docs/beta-sprint/game-feel/CORE_PLAYABLE_QUALITY_BINDINGS.json"
var checks := 0
var failures: Array[String] = []
var events: Array = []
var event_references: Array = []
var samples: Array = []
var inputs: Array = []
var host: Node
var body: Node3D
var canonical_root: Node3D
var camera: Camera3D
var runtime: Object
var pending_input_state: Dictionary = {}
var pending_input_statekey: Dictionary = {}
var last_tick := 0

static func flight_failures(observations: Array, begin_ms: float, end_ms: float) -> Array[String]:
	var problems: Array[String] = []
	var flight := observations.filter(func(row: Dictionary) -> bool: return row.time_ms >= begin_ms and row.time_ms <= end_ms)
	if flight.size() <= 2:
		return ["missing continuous flight samples"]
	if not flight.any(func(row: Dictionary) -> bool: return row.canonical_position != flight[0].canonical_position and row.canonical_position != flight[-1].canonical_position):
		problems.append("actor is static or teleports without intermediate position")
	if flight[-1].screen_position[1] <= flight[0].screen_position[1] + 0.25:
		problems.append("Fall interval has no positive screen descent beyond measurement noise")
	for index in range(1, flight.size()):
		if flight[index].screen_position[1] < flight[index - 1].screen_position[1] - 0.25:
			problems.append("Fall interval contains upward screen jump")
	return problems

static func refusal_failures(event: Dictionary, runtime_before: Variant = null, runtime_after: Variant = null) -> Array[String]:
	var problems: Array[String] = []
	var result: Dictionary = event.get("result", {})
	if result.get("status") not in [1, 2] or result.get("changed") != false or not result.get("previous_state") is Dictionary or result.get("next_state") != null:
		problems.append("refusal does not preserve native null-next-state shape")
	if not runtime_before is Dictionary or not runtime_after is Dictionary or runtime_before != runtime_after or runtime_before != result.get("previous_state"):
		problems.append("actual Runtime before/after state missing or changed")
	for field in ["transition_identity", "target_pose", "target_face", "authoritative_final_orientation", "authorized_path_points2"]:
		if event.get(field) != null:
			problems.append("refusal has accepted authority: " + field)
	return problems

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="): evidence = arg.trim_prefix("--evidence-dir=")
		elif arg.begins_with("--case="): case_id = arg.trim_prefix("--case=")
		elif arg.begins_with("--bindings="): binding_path = arg.trim_prefix("--bindings=")
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		printerr("FAIL: ", label)

func write_report(status: String, missing: Array = []) -> void:
	var capture := Capture.snapshot("NATIVE_INPUT_PARSE_INPUT_EVENT")
	capture.fixture_kind = "REAL_CORE_HOST" if checks > 0 else "DEPENDENCY_DISCOVERY_ONLY"
	# This capture is a candidate measurement, not a formal receipt verdict.
	# Formal registration follows measured GREEN, not a prerequisite for running.
	capture.authoritative_runtime = null
	var report := {"case": case_id, "status": status, "checks": checks, "failures": failures,
		"source_sha": capture.execution_head if checks > 0 else null, "delivery_sha": null, "doubles": [],
		"capture": capture, "missing": missing, "events": events, "samples": samples, "inputs": inputs,
		"binding_path": binding_path, "binding_sha256": FileAccess.get_sha256(binding_path) if FileAccess.file_exists(binding_path) else null,
		"evidence_role": "PHASE_EVIDENCE_ONLY", "natural_success": null}
	FileAccess.open(evidence.path_join(case_id + ".json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("GAME_FEEL_CORE_CASE status=", status, " checks=", checks, " failures=", failures)

func on_event(event: Dictionary) -> void:
	# Capture before other consumers can mutate/reuse their Dictionary; the
	# producer's immutable-snapshot guarantee is separately tested after binding.
	events.append({"time_ms": Time.get_ticks_usec() / 1000.0, "event": event.duplicate(true),
		"runtime_before": pending_input_state.duplicate(true), "runtime_statekey_before": pending_input_statekey.duplicate(true),
		"runtime_after_callback": runtime.get_state()})
	event_references.append(event)

func vector_record(value: Vector3) -> Array:
	return [value.x, value.y, value.z]

func record_frame() -> void:
	var now := Time.get_ticks_usec()
	var position := canonical_root.to_local(body.global_position)
	var screen := camera.unproject_position(body.global_position)
	samples.append({"time_ms": now / 1000.0, "frame_interval_ms": (now - last_tick) / 1000.0 if last_tick else null,
		"process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		"canonical_position": vector_record(position), "screen_position": [screen.x, screen.y],
		"model_basis": [vector_record(body.global_basis.x), vector_record(body.global_basis.y), vector_record(body.global_basis.z)]})
	last_tick = now

func pause_sampling(seconds: float) -> void:
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < seconds * 1000.0:
		await process_frame
		record_frame()

func send_native(row: Dictionary) -> void:
	pending_input_state = runtime.get_state()
	pending_input_statekey = StateKey.build(runtime.get_level(), pending_input_state)
	inputs.append({"time_ms": Time.get_ticks_usec() / 1000.0, "input": row.duplicate(true),
		"runtime_before": pending_input_state.duplicate(true), "event_index": events.size()})
	if row.kind == "key":
		check(KEY_CODES.has(row.key), "registered native key")
		if not KEY_CODES.has(row.key): return
		var event := InputEventKey.new()
		event.keycode = KEY_CODES[row.key]
		event.physical_keycode = event.keycode
		event.pressed = row.pressed
		Input.parse_input_event(event)
	elif row.kind == "mouse_button":
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = Vector2(row.x, row.y)
		event.pressed = row.pressed
		Input.parse_input_event(event)
	elif row.kind == "mouse_motion":
		var event := InputEventMouseMotion.new()
		event.position = Vector2(row.x, row.y)
		event.relative = Vector2(row.dx, row.dy)
		event.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(event)
	else:
		check(false, "unknown native input kind")

func run() -> void:
	if evidence.is_empty():
		quit(2)
		return
	if not binding_path.begins_with("res://docs/beta-sprint/game-feel/") or not FileAccess.file_exists(binding_path):
		write_report("case_pending", ["00_CORE_PLAYABLE_BINDING", "01_RUNTIME_PORT"])
		quit(0)
		return
	var profile: Variant = JSON.parse_string(FileAccess.get_file_as_string(binding_path))
	if not profile is Dictionary or profile.get("contract_sha256") != CONTRACT_HASH or not profile.get("cases") is Dictionary or profile.get("registration_status") not in ["PHASE_EVIDENCE_ONLY", "TEST_DEPENDENCY_ONLY", "REGISTERED_00_CORE_PLAYABLE"]:
		write_report("case_pending", ["VALID_00_CANDIDATE_BINDING"])
		quit(0)
		return
	var binding: Dictionary = profile.cases.get(case_id, {})
	for field in ["host_scene", "runtime_node", "body_node", "camera_node", "canonical_root", "native_inputs", "expected", "delivery_commits"]:
		if not binding.has(field) or binding[field] == null:
			write_report("case_pending", ["CASE_BINDING:" + field])
			quit(0)
			return
	# Candidate execution records actual source/dirty identity and never signs
	# formal Real. 00 registers a Core slot only after the genuine closed loop.
	check(DisplayServer.get_name() != "headless", "actual graphical renderer for natural Runtime/Presenter loop")
	check(str(binding.host_scene).begins_with("res://experiments/game_feel_01/host/"), "actual 00 host namespace")
	var scene: Variant = load(binding.host_scene) if ResourceLoader.exists(binding.host_scene) else null
	check(scene is PackedScene, "real delivered host scene")
	if not failures.is_empty():
		write_report("FAIL")
		quit(1)
		return
	host = scene.instantiate()
	root.add_child(host)
	await process_frame
	var runtime_container := host.get_node_or_null(binding.runtime_node)
	runtime = (runtime_container.get(binding.runtime_property) if runtime_container != null and binding.has("runtime_property") else runtime_container) as Object
	body = host.get_node_or_null(binding.body_node) as Node3D
	var camera_container := host.get_node_or_null(binding.camera_node)
	camera = (camera_container.get(binding.camera_property) if camera_container != null and binding.has("camera_property") else camera_container) as Camera3D
	canonical_root = host.get_node_or_null(binding.canonical_root) as Node3D
	check(runtime is Object and runtime.has_signal("game_feel_event") and runtime.has_method("get_state"), "01 explicit production event port and read-only state getter")
	check(body != null and camera != null and canonical_root != null, "actual body/camera/canonical frame nodes")
	if not failures.is_empty():
		write_report("FAIL")
		quit(1)
		return
	runtime.connect("game_feel_event", on_event)
	var before_basis := body.global_basis
	record_frame()
	for row in binding.native_inputs:
		if row.get("kind") == "wait": await pause_sampling(float(row.seconds))
		elif row.get("kind") == "checkpoint":
			inputs.append({"time_ms": Time.get_ticks_usec() / 1000.0, "input": row.duplicate(true)})
			record_frame()
			var center := Vector3(row.center2[0], row.center2[1], row.center2[2]) * 0.5
			check(canonical_root.to_local(body.global_position).is_equal_approx(center), "actual checkpoint center: " + str(row.label))
			if row.get("preserve_initial_basis", false):
				check(body.global_basis.is_equal_approx(before_basis), "actual neutral Landing checkpoint basis")
		else:
			send_native(row)
			await process_frame
			inputs[-1].runtime_after_frame = runtime.get_state()
			inputs[-1].runtime_statekey_after = StateKey.build(runtime.get_level(), inputs[-1].runtime_after_frame)
			for event_index in range(inputs[-1].event_index, events.size()):
				events[event_index].runtime_after_frame = inputs[-1].runtime_after_frame.duplicate(true)
				events[event_index].runtime_statekey_after = inputs[-1].runtime_statekey_after.duplicate(true)
			record_frame()
	await pause_sampling(float(binding.get("settle_seconds", 0.5)))
	var started := events.filter(func(row: Dictionary) -> bool: return row.event.semantic == "PERSPECTIVE_FALL_APPLIED" and row.event.phase == "STARTED")
	var committed := events.filter(func(row: Dictionary) -> bool: return row.event.semantic == "PERSPECTIVE_FALL_APPLIED" and row.event.phase == "COMMITTED")
	var expected: Dictionary = binding.expected
	check(started.size() == int(expected.fall_count) and committed.size() == int(expected.fall_count), "exact natural Fall starts/commits")
	for index in mini(started.size(), committed.size()):
		var begin: Dictionary = started[index].event
		var end: Dictionary = committed[index].event
		check(begin.transition_identity == end.transition_identity and begin.presentation_identity == end.presentation_identity, "captured full identity commits once")
		check(end.result.status == 0 and end.result.changed and end.target_pose == begin.target_pose, "actual native commit agrees with proposed target")
		check(end.result.next_state == begin.result.next_state, "complete canonical state agrees with accepted proposal")
		check(O.is_valid(begin.source_pose.orientation) and end.authoritative_final_orientation == begin.source_pose.orientation and end.target_pose.orientation == begin.source_pose.orientation, "official cube24 PRESERVE endpoint")
		check(begin.connection_id == expected.connection_id and begin.camera_quadrant == int(expected.camera_quadrant), "actual author connection and captured camera")
		var safe: Variant = begin.get("safety_verdict")
		check(safe is Dictionary and safe.get("status") == "SAFE" and safe.get("issues") == [] and safe.get("evidence_ref") is Dictionary, "actual structured SAFE verdict and evidence reference preserved")
		if safe is Dictionary and safe.get("evidence_ref") is Dictionary:
			var ref: Dictionary = safe.evidence_ref
			var before_key := StateKey.build(runtime.get_level(), begin.result.previous_state)
			var after_key := StateKey.build(runtime.get_level(), end.result.next_state)
			check(before_key.ok and after_key.ok and ref.get("before_statekey") == before_key.key and ref.get("after_statekey") == after_key.key and ref.get("connection_id") == begin.connection_id and ref.get("profile_hash") == begin.motion_profile_hash, "Safety proof bound to actual versioned statekeys and authorized profile")
		check(begin.authorized_path_points2[0] == Vector3i(expected.source_center2[0], expected.source_center2[1], expected.source_center2[2]) and begin.authorized_path_points2[-1] == Vector3i(expected.target_center2[0], expected.target_center2[1], expected.target_center2[2]), "authorized actor centers agree with delivered map")
		var flight_problems := flight_failures(samples, started[index].time_ms, committed[index].time_ms)
		check(flight_problems.is_empty(), "actual Fall interval independently moves and descends: " + str(flight_problems))
	if int(expected.fall_count) > 0:
		var final_center: Array = expected.get("final_center2", expected.target_center2)
		var target := Vector3(final_center[0], final_center[1], final_center[2]) * 0.5
		check(canonical_root.to_local(body.global_position).is_equal_approx(target), "settled actual model reaches exact authorized target center")
		if expected.get("preserve_final_basis", true):
			check(body.global_basis.is_equal_approx(before_basis), "Landing ends at preserved physical basis without drift")
	else:
		check(body.global_basis.is_equal_approx(before_basis) and samples[0].canonical_position == samples[-1].canonical_position, "rejected case preserves physical pose")
		check(expected.has("required_reason"), "negative case specifies authoritative rejection class")
		if expected.has("required_reason"):
			var refusals := events.filter(func(row: Dictionary) -> bool: return row.event.semantic == "ACTION_FEEDBACK" and row.event.reason_category == expected.required_reason)
			check(not refusals.is_empty(), "actual specific refusal; never inferred EDGE")
			for row in refusals:
				check(refusal_failures(row.event, row.runtime_before, row.get("runtime_after_frame")).is_empty(), "actual Runtime before/after state unchanged; native null rejection has no accepted authority")
				var before_key: Dictionary = row.runtime_statekey_before
				var after_key: Dictionary = row.get("runtime_statekey_after", {})
				check(before_key.get("ok", false) and after_key.get("ok", false) and before_key.get("key") == after_key.get("key"), "actual official versioned StateKey unchanged on refusal")
	for index in events.size():
		check(event_references[index] == events[index].event, "producer event snapshot remains immutable after callbacks")
	host.queue_free()
	await create_timer(0.2).timeout
	write_report("OBSERVATIONS_RECORDED" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)
