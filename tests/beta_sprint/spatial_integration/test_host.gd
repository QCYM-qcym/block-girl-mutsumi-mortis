extends SceneTree
const Maps=preload("res://experiments/game_feel_01/maps/map_factory.gd")
const Facade=preload("res://foundation/game_feel/runtime_facade.gd")
var checks:=0
var failures:Array=[]
var evidence:=OS.get_environment("FOUNDATION_TEST_EVIDENCE")
func _initialize()->void: call_deferred("run")
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok: failures.append(label)
func run()->void:
	var path:="res://experiments/spatial_puzzle_batch_01/host/spatial_lab.gd"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--host-script="): path=arg.trim_prefix("--host-script=")
	var baked:Dictionary=Maps.bake_game_feel(Maps.read_spec("a"))
	check(baked.ok,"real prior Forward Drop fixture bakes")
	var runtime:=Facade.new()
	check(runtime.load_level(baked.level).ok,"actual runtime loads")
	var host=load(path).new()
	host.runtime=runtime
	host.external_runtime=true
	root.add_child(host)
	await process_frame
	var event:=InputEventKey.new()
	event.physical_keycode=KEY_F;event.keycode=KEY_F;event.pressed=true
	host._unhandled_key_input(event)
	check(not host.events.is_empty(),"physical F reaches real runtime")
	if not host.events.is_empty():
		check(host.events.back().result.action=={"kind":0,"face_axis":2},"F delegates same formal MOVE direction, never chooses connection")
	check(host.actor.has_node("LocalFaceMarks"),"physical cube exposes six distinct local faces")
	if host.actor.has_node("LocalFaceMarks"):
		check(host.actor.get_node("LocalFaceMarks").get_child_count()==6,"all six local faces visible as marks")
	var deadline:=Time.get_ticks_msec()+3500
	while not runtime.is_idle() and Time.get_ticks_msec()<deadline: await process_frame
	check(runtime.is_idle() and runtime.get_commit_count()==1,"natural animation completes one real commit")
	check(runtime.get_state().player.location.cube_id==&"target","formal yellow support reached")
	host.reset_lab()
	check(runtime.get_state().player.location.cube_id==&"source" and runtime.get_commit_count()==0,"Reset exact source")
	if host.has_signal("native_motion_completed"):
		var native:Array=[]
		host.native_motion_completed.connect(func(identity,detail): native.append({"identity":identity,"detail":detail}))
		var camera_result:Dictionary=runtime.request_action({"kind":9,"camera_quadrant":2})
		deadline=Time.get_ticks_msec()+2000
		while not runtime.is_idle() and Time.get_ticks_msec()<deadline: await process_frame
		await process_frame
		check(camera_result.status==0 and native.size()==1,"natural Camera exposes one scoped completion for formal replay")
		check(runtime.get_state().camera_quadrant==2 and runtime.get_state().player.orientation==0,"Camera changes view without cube orientation")
	check(host.host_issues.is_empty(),"no Host issues")
	host.free()
	await process_frame
	FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"doubles":[],"display":DisplayServer.get_name(),"authority":"real Facade + real prior-map Baker + natural Presenter; no completion injection"},"\t"))
	quit(0 if failures.is_empty() else 1)
