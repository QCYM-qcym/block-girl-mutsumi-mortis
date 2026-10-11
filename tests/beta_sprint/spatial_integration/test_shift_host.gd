extends "res://tests/beta_sprint/spatial_integration/test_host.gd"
const Fixture=preload("res://tests/foundation/level/baker_fixture.gd")
const Geometry=preload("res://foundation/spatial/surface_geometry.gd")
const Baker=preload("res://foundation/level/level_baker.gd")
const Host=preload("res://experiments/spatial_puzzle_batch_01/host/spatial_lab.gd")
const Goal=preload("res://foundation/rules/goal_evaluator.gd")
var observations:Array=[]
func fixture()->Dictionary:
	var level:Dictionary=Fixture.make_golden_level()
	level.erase("content_hash")
	level.schema_version=3;level.contract_version="foundation.game_feel.v2";level.rule_version="foundation.rules.game_feel.v2"
	level["camera_initial_quadrant"]=1;level["perspective_falls"]=[]
	level.cubes=[Fixture.cube(&"floor",0,Vector3i.ZERO),Fixture.cube(&"step",0,Vector3i(2,0,0)),Fixture.cube(&"mirror",1,Vector3i.ZERO),Fixture.cube(&"goal",1,Vector3i(-2,0,0))]
	level.faces=[]
	for cube in level.cubes:
		for face in Geometry.make_face_nodes(cube.cube_id):
			face.walkable=face.face==4;level.faces.append(face)
	level.goal.face_id=&"goal/TOP"
	level.celestial.slots[0].position2=Vector3i(0,-10,0)
	level.shift_compatibilities=[0]
	return Baker.bake(level,{"max_configurations":4096,"max_checks":100000})
func settle(host:Node)->void:
	var until:=Time.get_ticks_msec()+2500
	while (not host.runtime.is_idle() or host.presenter.snapshot().phase!="IDLE") and Time.get_ticks_msec()<until: await process_frame
	check(host.runtime.is_idle() and host.presenter.snapshot().phase=="IDLE","natural presentation settles")
func run()->void:
	root.size=Vector2i(1280,720)
	var baked:=fixture()
	check(baked.ok,"real compatible SAME_NORMAL Shift fixture")
	if not baked.ok: failures.append(str(baked.issues));finish();return
	var runtime:=Facade.new()
	check(runtime.load_level(baked.level).ok,"real Facade loads actual Baker output")
	var host:=Host.new();host.runtime=runtime;host.external_runtime=true
	root.add_child(host)
	var completed:Array=[];var cancelled:Array=[]
	host.native_motion_completed.connect(func(identity,detail):completed.append({"identity":identity,"detail":detail}))
	host.native_motion_cancelled.connect(func(identity,reason):cancelled.append({"identity":identity,"reason":reason}))
	await process_frame
	var initial:Dictionary=runtime.get_state()
	var shift:Dictionary=runtime.request_action({"kind":1})
	check(shift.status==0 and shift.changed,"legal native Shift accepted")
	check(not host._shift_identity.is_empty(),"real native identity reaches Host")
	var rejected:Dictionary=runtime.request_action({"kind":0,"face_axis":0})
	check(rejected.status==1 and not rejected.changed,"actual Safety rejects Shift concurrent Roll")
	check(host.presenter.snapshot().phase=="IDLE","rejected Roll starts no second actor animation")
	await settle(host)
	check(completed.size()==1 and runtime.get_commit_count()==1,"Tween finished commits and completes Shift once")
	check(runtime.get_state().player.location.layer==1 and runtime.get_state().player.orientation==initial.player.orientation,"World changed with preserved orientation")
	check(host.actor.transform.is_equal_approx(host.project_pose(runtime.get_state().player).transform),"final visual agrees with formal target")
	check(not host.geometry_root.get_node("floor").visible and host.geometry_root.get_node("mirror").visible,"only current World platforms visible")
	check(runtime.request_action({"kind":0,"face_axis":2}).status==0,"Roll remains usable after Shift")
	await settle(host)
	check(Goal.is_goal(baked.level,runtime.get_state()).is_goal,"real Shift then Roll reaches Goal")
	host.reset_lab()
	check(runtime.get_state()==initial,"Reset initial full state")
	runtime.request_action({"kind":1})
	await process_frame
	host.set_lab_paused(true)
	var paused_pose:Transform3D=host.actor.transform
	for frame in 30: await process_frame
	check(runtime.get_commit_count()==0 and host.actor.transform.is_equal_approx(paused_pose),"Pause freezes real Shift Tween and commit")
	host.set_lab_paused(false)
	await settle(host)
	check(completed.size()==2 and runtime.get_commit_count()==1,"Resume reaches actual completion once")
	host.reset_lab();runtime.request_action({"kind":1})
	var old:Dictionary=host._shift_identity.duplicate(true)
	await process_frame
	host.reset_lab()
	for frame in 30: await process_frame
	host._finish_shift(old)
	check(completed.size()==2 and cancelled.size()==1,"Reset cancellation is separate from completion; stale callback ignored")
	check(runtime.get_state()==initial and runtime.get_commit_count()==0,"Reset protects state and commit count")
	check(host.actor.transform.is_equal_approx(host.project_pose(initial.player).transform),"Reset restores exact pose and scale")
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(evidence.path_join("shift_source.png"))
	observations=[{"completed":completed,"cancelled":cancelled,"host_issues":host.host_issues}]
	check(host.host_issues.is_empty(),"no Host errors")
	host.free();await process_frame
	finish()
func finish()->void:
	FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"doubles":[],"observations":observations,"display":DisplayServer.get_name(),"authority":"real schema3 SAME_NORMAL Shift + native Tween.finished; new schema4 permission is separate Owner gate"},"\t"))
	quit(0 if failures.is_empty() else 1)
