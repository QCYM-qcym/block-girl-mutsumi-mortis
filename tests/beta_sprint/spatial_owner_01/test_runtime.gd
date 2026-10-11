extends SceneTree
const F = preload("res://tests/beta_sprint/spatial_owner_01/fixtures.gd")
const Baker = preload("res://foundation/level/level_baker.gd")
const Facade = preload("res://foundation/game_feel/runtime_facade.gd")
const Key = preload("res://foundation/contracts/state_key.gd")
const Goal = preload("res://foundation/rules/goal_evaluator.gd")
var checks := 0
var failures: Array[String] = []
var events: Array = []
var transitions: Array = []
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func _initialize() -> void:
	var author := F.level(true)
	author.erase("content_hash")
	var baked := Baker.bake(author,{"max_configurations":4096,"max_checks":100000})
	check(baked.ok,"runtime uses real baked locked gate")
	if baked.ok: _run(baked.level)
	print("SPATIAL_RUNTIME checks=",checks," failures=",failures," doubles=[]")
	quit(0 if failures.is_empty() else 1)
func _run(level: Dictionary) -> void:
	var runtime := Facade.new()
	runtime.game_feel_event.connect(func(event):events.append(event))
	runtime.transition_started.connect(func(result,id,generation,is_global):transitions.append({"result":result,"id":id,"generation":generation,"is_global":is_global}))
	check(runtime.load_level(level).ok,"real Runtime load")
	var initial: String = Key.build(level,runtime.get_state()).key
	check(runtime.request_action({"kind":1}).status == 1 and runtime.get_commit_count() == 0,"locked Shift cannot commit")
	check(events[-1].semantic == "ACTION_FEEDBACK" and events[-1].reason_category == "MECHANISM_LOCKED","gate locked feedback is explicit")
	var move := runtime.request_action({"kind":0,"face_axis":0})
	check(move.status == 0 and runtime.get_state().mechanism_states.face_lock == &"inactive" and runtime.get_commit_count() == 0,"MOVE+latch acceptance does not commit")
	var token := runtime.get_pending_identity(transitions[-1].id,transitions[-1].generation,transitions[-1].is_global)
	check(not token.is_global,"MOVE+latch is native local")
	check(runtime.request_action({"kind":0,"face_axis":0}).status == 1 and events[-1].reason_category == "BUSY","spam is Busy and never Edge")
	check(not runtime.finish_transition(token).ignored and runtime.get_state().mechanism_states.face_lock == &"latched" and runtime.get_commit_count() == 1,"one local authoritative latch commit")
	var latched_key: String = Key.build(level,runtime.get_state()).key
	check(runtime.finish_transition(token).ignored and runtime.get_commit_count() == 1 and Key.build(level,runtime.get_state()).key == latched_key,"duplicate callback ignored")
	_finish(runtime,{"kind":0,"face_axis":2},false)
	var old_global := _finish(runtime,{"kind":1},true)
	check(not old_global.is_empty() and old_global.is_global,"retained actual accepted global identity")
	check(runtime.get_state().player.location.cube_id == &"mirror" and runtime.get_state().player.orientation == 0 and runtime.get_commit_count() == 3,"unlocked Shift preserves pose and exact count")
	check(runtime.finish_transition(token).ignored and runtime.get_commit_count() == 3,"old local token cannot finish newer global")
	_finish(runtime,{"kind":0,"face_axis":2},false)
	check(runtime.finish_transition(old_global).ignored and runtime.get_commit_count()==4,"duplicate old global cannot alter later local commit")
	check(Goal.is_goal(level,runtime.get_state()).is_goal and runtime.get_commit_count() == 4,"real formal Goal")
	runtime.reset()
	check(Key.build(level,runtime.get_state()).key == initial and runtime.get_state().mechanism_states.face_lock == &"inactive" and runtime.get_commit_count() == 0,"Reset restores exact initial core/latch/key")
	runtime.request_action({"kind":0,"face_axis":0})
	var stale := runtime.get_pending_identity(transitions[-1].id,transitions[-1].generation,transitions[-1].is_global)
	runtime.reset()
	check(runtime.finish_transition(stale).ignored and runtime.is_idle() and Key.build(level,runtime.get_state()).key == initial,"Reset cancels pending latch/generation")
	runtime.request_action({"kind":0,"face_axis":0})
	var exiting := runtime.get_pending_identity(transitions[-1].id,transitions[-1].generation,transitions[-1].is_global)
	runtime.interrupt("UNLOAD")
	check(runtime.finish_transition(exiting).ignored and not runtime.is_loaded(),"unload cancels pending commit")
func _finish(runtime: RefCounted, action: Dictionary, global: bool) -> Dictionary:
	var count: int = runtime.get_commit_count()
	var result: Dictionary = runtime.request_action(action)
	check(result.status == 0,"real action accepted " + str(action))
	if result.status != 0: return {}
	var started: Dictionary = transitions[-1]
	check(started.is_global == global,"actual transition kind")
	var identity: Dictionary = runtime.get_pending_identity(started.id,started.generation,started.is_global)
	check(not runtime.finish_transition(identity).ignored and runtime.get_commit_count() == count + 1,"one native authoritative commit")
	return identity
