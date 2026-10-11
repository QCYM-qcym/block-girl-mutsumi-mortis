extends SceneTree
const Maps=preload("res://experiments/game_feel_01/maps/map_factory.gd")
const Facade=preload("res://foundation/game_feel/runtime_facade.gd")
const Bridge=preload("res://game/feel/graphical_completion_bridge.gd")
var checks:=0
var failures:Array=[]
var observations:Array=[]
func _initialize()->void: call_deferred("run")
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok: failures.append(label)
func run()->void:
	var baked:Dictionary=Maps.bake_game_feel(Maps.read_spec("a"))
	var runtime=Facade.new()
	check(baked.ok and runtime.load_level(baked.level).ok,"actual old MAP A loads")
	var bridge=Bridge.new()
	root.add_child(bridge)
	check(bridge.bind_runtime(runtime,baked.level).ok,"formal Bridge binds")
	var completions:Array=[]
	bridge.motion_completed.connect(func(identity,evidence): completions.append({"identity":identity,"semantic":evidence.semantic}))
	var fall:Dictionary=runtime.request_action({"kind":0,"face_axis":2})
	check(fall.status==0,"actual Fall accepted")
	var until:=Time.get_ticks_msec()+6000
	while bridge.lab.presenter.snapshot().phase!="LANDING" and Time.get_ticks_msec()<until: await process_frame
	check(bridge.lab.presenter.snapshot().phase=="LANDING" and runtime.is_idle(),"natural committed Fall is still Landing")
	var camera:Dictionary=runtime.request_action({"kind":9,"camera_quadrant":2})
	check(camera.status==0 and camera.changed,"Camera during Landing is formally accepted")
	until=Time.get_ticks_msec()+6000
	while (not runtime.is_idle() or bridge.lab.presenter.snapshot().phase!="IDLE") and Time.get_ticks_msec()<until: await process_frame
	await process_frame
	await process_frame
	check(runtime.is_idle() and bridge.lab.presenter.snapshot().phase=="IDLE","both motions naturally settle")
	check(runtime.get_commit_count()==2,"exactly two authoritative commits")
	check(runtime.get_state()==camera.next_state,"final state matches accepted Camera result")
	check(bridge.lab.actor.transform.is_equal_approx(bridge.lab.project_pose(runtime.get_state().player).transform),"final visual pose equals formal pose")
	check(completions.size()==2,"both accepted motions deliver completion")
	var identities:Array=[]
	for event in completions:
		check(event.identity not in identities,"completion identity delivered once")
		identities.append(event.identity)
	for record in bridge.snapshot().records:
		check(record.delivered and record.committed_order>0 and record.completion_order>record.committed_order,"terminal committed record eventually delivered")
	observations.append({"completions":completions,"records":bridge.snapshot().records})
	for frame in 10: await process_frame
	check(completions.size()==2,"later frames never repeat completions")
	bridge.free()
	FileAccess.open(OS.get_environment("FOUNDATION_TEST_EVIDENCE").path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"doubles":[],"observations":observations,"authority":"Actual MAP A Runtime+Presenter; no forced finish or timer completion"},"\t"))
	quit(0 if failures.is_empty() else 1)
