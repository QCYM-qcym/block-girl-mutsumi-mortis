extends SceneTree
const F = preload("res://tests/beta_sprint/game_feel_owner_01/fixtures.gd")
const Facade = preload("res://foundation/game_feel/runtime_facade.gd")
const Key = preload("res://foundation/contracts/state_key.gd")
const LegacyFixture = preload("res://tests/foundation/rules/kernel_fixture.gd")
const Codec = preload("res://foundation/level/level_codec.gd")
var checks := 0
var failures: Array[String] = []
var events: Array = []
func check(ok: bool, name: String) -> void:
	checks += 1
	if not ok: failures.append(name)
func _initialize() -> void:
	create_timer(20).timeout.connect(func(): printerr("TEST_TIMEOUT"); quit(2))
	call_deferred("run")
func run() -> void:
	var level := F.level()
	level.content_hash = Codec.compute_content_hash(level).content_hash
	var runtime := Facade.new()
	runtime.game_feel_event.connect(func(e):events.append(e))
	check(runtime.load_level(level).ok,"load real opt-in formal Runtime")
	var loaded_scope := runtime.get_presentation_scope()
	check(loaded_scope.is_read_only() and loaded_scope.generation == runtime.get_generation(),"host binds a read-only actual current presentation scope")
	var before: String = Key.build(level,runtime.get_state()).key
	var edge := runtime.request_action({"kind":0,"face_axis":0})
	check(edge.status == 1 and Key.build(level,runtime.get_state()).key == before and runtime.get_commit_count() == 0,"edge changes no authoritative field")
	check(events.size() == 1 and events[-1].semantic == "MOVE_REJECTED_EDGE","missing road produces explicit Edge event")
	var result := runtime.request_action({"kind":8,"connection_id":&"edge_a"})
	check(result.status == 0 and result.changed and Key.build(level,runtime.get_state()).key == before,"Fall acceptance is not a commit")
	check(events.size() == 3 and events[1].semantic == "ANIMATION_INTERRUPTED" and events[1].interruption_reason == "CANCEL" and events[-1].semantic == "PERSPECTIVE_FALL_APPLIED" and events[-1].phase == "STARTED","real permission publishes authorized path at STARTED")
	var started: Dictionary = events[-1] if events.size() >= 2 else {}
	var token: Dictionary = started.get("transition_identity",{})
	var completion := runtime.finish_transition(token)
	check(not completion.ignored and runtime.get_commit_count() == 1,"captured identity completes native commit exactly once")
	check(events.size() >= 3 and events[-1].phase == "COMMITTED","COMMITTED comes from actual native commit")
	var invalid_token := token.duplicate(true)
	invalid_token.session_id = false
	check(runtime.finish_transition(invalid_token).ignored,"malformed identity is rejected without callback type errors")
	check(started.is_read_only() and started.result.is_read_only() and started.authorized_path_points2.is_read_only(),"event is an immutable deep snapshot")
	check(started.transition_identity.is_global == false and started.orientation_policy == "PRESERVE" and started.safety_verdict.status == "SAFE" and started.safety_verdict.issues.is_empty(),"Fall event carries actual local token and complete Safety proof")
	var after: String = Key.build(level,runtime.get_state()).key
	check(runtime.finish_transition(token).ignored and runtime.get_commit_count() == 1 and Key.build(level,runtime.get_state()).key == after,"duplicate completion never commits twice")
	runtime.reset()
	check(Key.build(level,runtime.get_state()).key == before,"Reset restores formal initial state")
	check(runtime.get_presentation_scope().generation > loaded_scope.generation and loaded_scope.generation != runtime.get_presentation_scope().generation,"Reset invalidates previously captured scope without mutating its snapshot")
	runtime.request_action({"kind":8,"connection_id":&"edge_a"})
	var old: Dictionary = events[-1].get("transition_identity",{}) if events.size() >= 2 else {}
	for conflict in [{"kind":0,"face_axis":0},{"kind":1},{"kind":9,"camera_quadrant":0},{"kind":8,"connection_id":&"edge_a"}]:
		var busy := runtime.request_action(conflict)
		check(busy.status == 1 and events[-1].reason_category == "BUSY" and runtime.get_commit_count() == 0,"in-flight conflicting input is Busy with no commit")
	runtime.reset()
	check(runtime.finish_transition(old).ignored and runtime.get_commit_count() == 0 and Key.build(level,runtime.get_state()).key == before,"Reset invalidates old completion")
	check(events.any(func(e):return e.semantic == "ANIMATION_INTERRUPTED" and e.interruption_reason == "RESET"),"Reset interrupts captured presentation identity")
	runtime.set_paused(true)
	var paused := runtime.request_action({"kind":0,"face_axis":0})
	check(paused.status == 1 and not events.is_empty() and events[-1].reason_category == "BUSY","Pause must never masquerade as physical Edge")
	runtime.set_paused(false)
	for reason in ["CANCEL","UNLOAD","QUIT"]:
		runtime.load_level(level)
		runtime.request_action({"kind":8,"connection_id":&"edge_a"})
		var captured: Dictionary = events[-1].transition_identity.duplicate(true)
		runtime.interrupt(reason)
		check(runtime.finish_transition(captured).ignored and runtime.get_commit_count() == 0,"lifecycle invalidation rejects stale completion: " + reason)
		check(events[-1].semantic == "ANIMATION_INTERRUPTED" and events[-1].interruption_reason == reason and events[-1].presentation_identity.generation == captured.generation,"interruption names old captured identity: " + reason)
	runtime.load_level(level)
	var external := runtime.get_state()
	external.player.orientation = 7
	check(runtime.get_state().player.orientation == 0,"public state snapshot cannot write Gameplay State")
	var mechanism_level := LegacyFixture.make_level(true)
	mechanism_level.schema_version = 2
	mechanism_level.contract_version = "foundation.game_feel.v1"
	mechanism_level.rule_version = "foundation.rules.game_feel.v1"
	mechanism_level["camera_initial_quadrant"] = 1
	mechanism_level["perspective_falls"] = []
	mechanism_level.content_hash = Codec.compute_content_hash(mechanism_level).content_hash
	# Console is on floor/TOP; the formal spawn is moved in the authored fixture
	# to step/TOP, never by assigning a live Session state.
	mechanism_level.spawn.location.cube_id = &"step"
	mechanism_level.content_hash = Codec.compute_content_hash(mechanism_level).content_hash
	check(runtime.load_level(mechanism_level).ok,"load real native mechanism fixture")
	var locked := runtime.request_action({"kind":5,"mechanism_id":&"console"})
	check(locked.status == 1 and events[-1].reason_category == "MECHANISM_LOCKED" and events[-1].semantic == "ACTION_FEEDBACK","native mechanism permission rejection keeps its explicit category")
	mechanism_level.spawn.location.cube_id = &"floor"
	var console: Dictionary = mechanism_level.mechanisms[0]
	console.action.celestial_op = 1
	console.action.target_slot_id = &""
	console.action.alternate_slot_id = &""
	mechanism_level.celestial.initial_slot_id = &"b"
	mechanism_level.content_hash = Codec.compute_content_hash(mechanism_level).content_hash
	check(runtime.load_level(mechanism_level).ok,"load non-wrapping celestial permission boundary")
	var unavailable := runtime.request_action({"kind":5,"mechanism_id":&"console"})
	check(unavailable.status == 1 and events[-1].reason_category == "UNCLASSIFIED_REJECTION","celestial step refusal must not invent a Safety verdict")
	runtime.load_level(level)
	var invalid := runtime.request_move(Vector2(NAN,0))
	check(invalid.status == 2 and events[-1].reason_category == "INVALID_ACTION" and events[-1].semantic == "ACTION_FEEDBACK","invalid input mapping never produces physical Edge")
	# Exercise synchronous listeners: reset during STARTED must not resurrect
	# old authority; completion during STARTED must emit one committed result.
	var reentrant := Facade.new()
	var reentrant_events: Array = []
	reentrant.load_level(level)
	reentrant.game_feel_event.connect(func(e):
		reentrant_events.append(e)
		if e.phase == "STARTED": reentrant.reset())
	reentrant.request_action({"kind":8,"connection_id":&"edge_a"})
	check(reentrant.get_commit_count() == 0 and reentrant.is_idle() and reentrant_events.size() == 2 and reentrant_events[-1].phase == "INTERRUPTED","Reset inside STARTED callback cannot revive old proposal")
	var instant := Facade.new()
	var instant_events: Array = []
	instant.load_level(level)
	instant.game_feel_event.connect(func(e):
		instant_events.append(e)
		if e.phase == "STARTED": instant.finish_transition(e.transition_identity))
	instant.request_action({"kind":8,"connection_id":&"edge_a"})
	check(instant.get_commit_count() == 1 and instant.is_idle() and instant_events.size() == 2 and instant_events[-1].phase == "COMMITTED","logical synchronous completion cannot publish duplicate acceptance")
	var pausable := Facade.new()
	var pause_events: Array = []
	pausable.game_feel_event.connect(func(e):pause_events.append(e))
	pausable.load_level(level)
	pausable.request_action({"kind":8,"connection_id":&"edge_a"})
	var pause_token: Dictionary = pause_events[-1].transition_identity
	pausable.set_paused(true)
	check(pausable.finish_transition(pause_token).ignored and pausable.get_commit_count() == 0,"Pause cannot manufacture landing/commit")
	pausable.set_paused(false)
	check(not pausable.finish_transition(pause_token).ignored and pausable.get_commit_count() == 1,"Resume retains the original completion identity")
	var stale := Facade.new()
	stale.load_level(level)
	var native_states: Array = []
	var stale_events: Array = []
	stale.committed.connect(func(s):native_states.append(s))
	stale.game_feel_event.connect(func(e):
		stale_events.append(e)
		if e.phase == "COMMITTED": stale.reset())
	stale.request_action({"kind":8,"connection_id":&"edge_a"})
	stale.finish_transition(stale_events[-1].transition_identity)
	check(native_states.size() == 1 and native_states[-1].player.location.cube_id == &"floor" and stale.get_state().player.location.cube_id == &"floor","native forwarded committed cannot overwrite a reentrant Reset")
	runtime.load_level(level)
	var camera_starts: Array = []
	runtime.transition_started.connect(func(r,id,g,global):camera_starts.append({"result":r,"id":id,"generation":g,"is_global":global}))
	var camera := runtime.request_action({"kind":9,"camera_quadrant":0})
	check(camera.status == 0 and camera.changed and events[-1].phase == "FEEDBACK" and events[-1].transition_identity == null,"neutral Camera feedback never supplies a Runtime completion identity")
	check(camera_starts.size() == 1 and camera_starts[0].result.action.kind == 9 and not camera_starts[0].is_global,"native camera acceptance carries actual local token")
	if runtime.has_method("get_pending_identity"):
		var captured: Dictionary = runtime.get_pending_identity(camera_starts[0].id,camera_starts[0].generation,camera_starts[0].is_global)
		check(not runtime.finish_transition(captured).ignored and runtime.get_state().camera_quadrant == 0 and runtime.is_idle(),"native captured Camera identity commits once without a motion feedback cue")
	runtime.reset()
	var corrupt := level.duplicate(true)
	corrupt.perspective_falls[0].presentation_duration_ms = 500
	check(not runtime.load_level(corrupt).ok and not runtime.is_loaded(),"reload rejects tampered content identity rather than keeping prior Runtime")
	var last_id := 0
	for event in events:
		check(event.event_id > last_id,"event IDs are monotonic across reset/reload")
		last_id = event.event_id
	for instance in [runtime,reentrant,instant,pausable,stale]:
		for connection in instance.game_feel_event.get_connections(): instance.game_feel_event.disconnect(connection.callable)
		for connection in instance.committed.get_connections(): instance.committed.disconnect(connection.callable)
	var summary := {"checks":checks,"failures":failures,"doubles":[],"authority":"real RuntimeSession/Kernel/Safety; completion=LOGICAL_SESSION","events":events}
	FileAccess.open(OS.get_environment("FOUNDATION_TEST_EVIDENCE").path_join("results.json"),FileAccess.WRITE).store_string(JSON.stringify(summary))
	print("RUNTIME checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
