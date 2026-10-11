extends SceneTree
const Factory=preload("res://experiments/spatial_puzzle_batch_01/maps/map_factory.gd")
const Baker=preload("res://foundation/level/level_baker.gd")
const Session=preload("res://foundation/runtime/runtime_session.gd")
const Key=preload("res://foundation/contracts/state_key.gd")
var checks:=0
var failures:Array=[]
var rows:Array=[]
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label)
func run()->void:
	var args:PackedStringArray=OS.get_cmdline_user_args()
	check(OS.get_user_data_dir().replace("\\","/").begins_with(args[1]+"/"),"isolated profile")
	var baked:Dictionary=Factory.bake(&"perspective_fork_lab")
	check(baked.ok,"real Baker")
	if baked.ok:
		for q in range(4):
			var session=Session.new()
			var tokens:Array=[]
			session.transition_started.connect(func(_r,i,g,b):tokens.append([i,g,b]))
			check(session.load_level(baked.level).ok,"load")
			var original:String=Key.build(baked.level,session.state).key
			var camera:Dictionary=session.request_action({"kind":9,"camera_quadrant":q})
			check(camera.status==0,"Camera APPLIED")
			if camera.changed:
				var t:Array=tokens[-1]
				if t[2]:session.finish_global(t[0],t[1])
				else:session.finish_local(t[0],t[1])
			var before:Dictionary=session.state.duplicate(true)
			check(before.player.orientation==0,"Camera preserves orientation")
			var count:int=tokens.size()
			var result:Dictionary=session.request_action({"kind":0,"face_axis":2})
			if q in [1,2]:
				check(result.status==0 and result.changed,"legal camera fall APPLIED")
				if result.status==0 and result.changed:
					var t:Array=tokens[-1]
					if t[2]:session.finish_global(t[0],t[1])
					else:session.finish_local(t[0],t[1])
					check(session.state.player.location.cube_id==(&"target_a" if q==1 else &"target_b"),"unique expected landing")
					check(session.state.player.orientation==before.player.orientation and session.state.player.location.layer==before.player.location.layer,"Fall preserves orientation and layer")
			else:
				check(result.status==1 and result.rejection_code==2101,"invalid camera remains CAMERA_NOT_ALLOWED")
				check(tokens.size()==count and Key.build(baked.level,before).key==Key.build(baked.level,session.state).key,"denied fall emits no transition and preserves key")
			rows.append({"camera":q,"result":result,"after":session.state.duplicate(true)})
			session.reset()
			check(Key.build(baked.level,session.state).key==original,"Reset restores exact initial key")
	for mutation in ["cross_world","unwalkable","overlap"]:
		var source:Dictionary=Factory.authoring(&"perspective_fork_lab")
		if mutation=="cross_world":
			for cube in source.cubes:
				if cube.cube_id==&"target_b":cube.layer=1
		elif mutation=="unwalkable":
			for face in source.faces:
				if face.face_id==&"target_a/TOP":face.walkable=false
		else:source.perspective_falls[1].allowed_camera_quadrants=[1]
		source.camera_initial_quadrant=2 if mutation=="cross_world" else 1
		var rejected:Dictionary=Baker.bake(source,{"max_configurations":4096,"max_checks":100000})
		if mutation=="overlap":
			check(not rejected.ok,"Baker rejects overlap")
			rows.append({"mutation":mutation,"bake":rejected})
		else:
			check(rejected.ok,"Baker admits conditional rejection case")
			if rejected.ok:
				var session=Session.new()
				var events:Array=[]
				session.transition_started.connect(func(_r,i,g,b):events.append([i,g,b]))
				check(session.load_level(rejected.level).ok,"negative load")
				var before:String=Key.build(rejected.level,session.state).key
				var denied:Dictionary=session.request_action({"kind":0,"face_axis":2})
				check(denied.status==1 and denied.rejection_code==(2102 if mutation=="cross_world" else 2100),"Runtime rejects "+mutation)
				check(events.is_empty() and Key.build(rejected.level,session.state).key==before,"invalid landing preserves key with no transition")
				rows.append({"mutation":mutation,"bake_ok":true,"result":denied})
	FileAccess.open(args[0].path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows,"doubles":[],"user_data_dir":OS.get_user_data_dir(),"pid":OS.get_process_id()},"\t"))
	print("FORK MATRIX checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
