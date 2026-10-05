extends RefCounted
## Unit-only clock, capture and owned-process port. No Solver/Bake/Runtime double.
const S = preload("res://tools/foundation/authoring_acceptance/wire_schemas.gd")
const W = preload("res://tools/foundation/authoring_acceptance/tool_wire.gd")
const R = preload("res://tools/foundation/authoring_acceptance/run_records.gd")
const E = preload("res://tools/foundation/authoring_acceptance/execution_project.gd")
var wall := 1791158400000
var ticks := 1000
var running := true
var handles := false
var callbacks := false
var resources := false
var capture_count := 0
var launch_count := 0
var messages: Array = []
var cancelled := false
var root := ""
var id: Dictionary = {}
var gen := 0
var capture_lock := false
var actual_exit_code := 0
var probe_calls := 0

func utc_msec() -> int: return wall
func monotonic_msec() -> int: return ticks
func advance(ms: int) -> void:
	wall += ms
	ticks += ms
func current_generation() -> int: return gen
func describe() -> Dictionary: return {"editor_instance_id":id.get("editor_instance_id","")}
func set_capture_lock(value: bool) -> void: capture_lock = value

static func request(stages: Array = ["BAKE"]) -> Dictionary:
	var policy := R.default_execution_policy("ANALYZE_CURRENT")
	policy.stages = stages.duplicate()
	return {"entry_kind":"ANALYZE_CURRENT","level_ref":{"level_authoring_id":"33333333-3333-4333-8333-333333333333","level_id":&"unit","root_source_uri":"res://maps/unit.tscn"},"policy":policy}

static func identity(policy: Dictionary) -> Dictionary:
	var versions := {"record_version":"foundationversions.v1","tool_version":"authoringrun.v1","schemas":S.SCHEMA_VERSIONS.duplicate(),"contracts":S.CONTRACT_VERSIONS.duplicate(),"engine":{"version":"4.7.2.stable.steam.ed1daf0bf","executable_sha256":"e".repeat(64)},"modules":[{"path":"res://foundation/a.gd","sha256":"a".repeat(64),"version":null}],"configuration":[{"path":"res://project.godot","sha256":"c".repeat(64),"version":null}]}
	var req := request()
	return R.make_identity("44444444-4444-4444-8444-444444444444",0,req.level_ref,{"identity":{"run_id":E.uuid(),"snapshot_id":E.uuid(),"source_fingerprint":"a".repeat(64),"source_intent_digest":null}},W.digest("policy",policy).value,W.digest("versions",versions).value,versions)

func capture(request_value: Dictionary) -> Dictionary:
	capture_count += 1
	id = identity(request_value.policy)
	return S.success({"identity":id,"project":{"root_path":root,"policy":request_value.policy.duplicate(true)}})
func launch(identity_value: Dictionary, _project: Dictionary, _entry: String) -> Dictionary:
	launch_count += 1
	id = identity_value.duplicate(true)
	return S.success({"identity":id,"pid":101,"hello_verified":false,"exited":false})
func send_cancel(_identity: Dictionary, _reason: String = "USER_CANCEL") -> Dictionary:
	cancelled = true
	return S.success(null)
func poll(_identity: Dictionary) -> Dictionary:
	var values := messages.duplicate(true)
	messages.clear()
	return S.success(values)
func release_state(_identity: Dictionary) -> Dictionary:
	return {"process_exited":not running,"file_handles_closed":handles,"callbacks_disconnected":callbacks,"preview_resources_released":resources}
func pass_eligible() -> bool: return not cancelled
func release_all() -> void:
	running = false
	handles = true
	callbacks = true
	resources = true

func create_process(_engine: String, _args: PackedStringArray) -> int: return 101
func is_process_running(_pid: int) -> bool: return running
func get_process_exit_code(_pid: int) -> int: return actual_exit_code
func probe() -> void: probe_calls += 1

## A real owned OS process for IPC Unit only. Its identity is an explicit
## fixture, and its idle loop executes no Bake/Solver/Runtime algorithm.
static func process_probe_script() -> String:
	return """extends SceneTree
const T = preload("res://tools/foundation/authoring_acceptance/process_transport.gd")
const W = preload("res://tools/foundation/authoring_acceptance/tool_wire.gd")
const E = preload("res://tools/foundation/authoring_acceptance/execution_project.gd")
var transport: RefCounted
var identity: Dictionary
func _initialize() -> void: call_deferred("start")
func start() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 3: quit(2); return
	var wire := E.read_bytes(args[2])
	if not wire.ok: quit(2); return
	var decoded := W.decode_wire("worker_message",wire.value)
	if not decoded.ok: quit(2); return
	identity = decoded.value.identity
	transport = T.new()
	if not transport.open_channels(identity,args[0],args[1],"HEADLESS",[],true).ok: quit(2); return
	if not transport.checkpoint().ok: quit(2); return
	if not transport.send("HELLO","",{"launch_id":args[1],"worker_role":"HEADLESS","engine":identity.versions.engine}).ok: quit(2); return
	var deadline := Time.get_ticks_msec() + 15000
	while Time.get_ticks_msec() < deadline:
		var boundary: Dictionary = transport.checkpoint()
		if not boundary.ok:
			var sent: Dictionary = transport.send("EXIT","",{"reason":"CANCELLED","exit_code":0,"file_handles_closed":true,"callbacks_disconnected":true,"preview_resources_released":true})
			quit(0 if sent.ok else 1)
			return
		await process_frame
	transport.send("EXIT","",{"reason":"FAILED","exit_code":1,"file_handles_closed":true,"callbacks_disconnected":true,"preview_resources_released":true})
	quit(1)
"""
