extends SceneTree
## One-time migration tool. Frozen baseline is test input, never a production fallback.
const Schema=preload("res://foundation/authoring/authoring_schema.gd")
const Factory=preload("res://experiments/spatial_puzzle_batch_01/maps/map_factory.gd")
var failures:Array=[]
func _initialize()->void:call_deferred("run")
func uuid(seed:String)->String:
	var h:String=seed.sha256_text()
	return h.substr(0,8)+"-"+h.substr(8,4)+"-"+h.substr(12,4)+"-"+h.substr(16,4)+"-"+h.substr(20,12)
func object(kind:String,seed:String,fields:Dictionary)->Object:
	var result:Object=load(Schema.script_path(kind)).new()
	result.set("authoring_id",uuid(seed))
	for key in fields:result.set(key,fields[key])
	return result
func child(parent:Node,node:Node,label:String)->void:
	node.name=label
	parent.add_child(node)
	node.owner=parent
func save_scene(node:Node,path:String)->void:
	var packed:=PackedScene.new()
	if packed.pack(node)!=OK or ResourceSaver.save(packed,path)!=OK:failures.append(path)
	node.free()
func run()->void:
	var out:String=OS.get_cmdline_user_args()[0]
	for id in Factory.ids():
		var dir:String="res://experiments/spatial_puzzle_batch_01/maps/authoring/"+String(id)
		if FileAccess.file_exists(dir+"/level.tscn"):
			failures.append("Refusing to overwrite authored resources: "+String(id));continue
		DirAccess.make_dir_recursive_absolute(dir)
		var baseline:Dictionary=str_to_var(FileAccess.get_file_as_string("res://tests/beta_sprint/spatial_owner_09/migration_baseline/"+String(id)+".gdvar"))
		var level:Dictionary=baseline.level
		var intent:Resource=object("INTENT",String(id)+"/intent",{"authoring_version":"puzzleintentauthoring.v1","intent_id":StringName(String(id)+"_intent"),"required_mechanics":[],"optional_mechanics":[],"expected_milestones":[],"forbidden_bypasses":[]})
		if ResourceSaver.save(intent,dir+"/intent.tres")!=OK:failures.append("intent save")
		for world in level.worlds:
			var name:String="surface" if world.layer==0 else "inner"
			var root:Node3D=object("WORLD",String(id)+"/"+name,world)
			root.name=name.capitalize()
			for cube in level.cubes:
				if cube.layer!=world.layer:continue
				assert(cube.orientation==0,"Migration requires explicit nonidentity orientation handling")
				var faces:Array=[]
				for face in level.faces:
					if face.cube_id!=cube.cube_id:continue
					var fields:Dictionary={}
					for key in Schema.FIELDS.FACE:fields[key]=face[key]
					faces.append(object("FACE",String(id)+"/face/"+String(face.face_id),fields))
				var node:Node3D=object("CUBE",String(id)+"/cube/"+String(cube.cube_id),{"cube_id":cube.cube_id,"occludes_light":cube.occludes_light,"tags":cube.tags,"faces":faces})
				node.transform=Transform3D(Basis.IDENTITY,Vector3(cube.center2)/2.0)
				child(root,node,String(cube.cube_id))
			for mechanism in level.mechanisms:
				var host:StringName=StringName(String(mechanism.face_id).get_slice("/",0))
				var belongs:bool=false
				for cube in level.cubes:
					if cube.cube_id==host and cube.layer==world.layer:belongs=true
				if not belongs:continue
				var lock:Dictionary={}
				for item in level.get("face_locks",[]):
					if item.mechanism_id==mechanism.mechanism_id:lock=item
				assert(not lock.is_empty())
				var fields:Dictionary={"kind":5,"initial_state":mechanism.initial_state,"allowed_states":mechanism.allowed_states,"required_local_face":lock.required_local_face,"activation_mode":lock.activation_mode,"latched_state":lock.latched_state}
				var config:Resource=object("MECHANISM_CONFIG",String(id)+"/config/"+String(mechanism.mechanism_id),fields)
				if ResourceSaver.save(config,dir+"/contact_lock.tres")!=OK:failures.append("config save")
				var node:Node3D=object("MECHANISM",String(id)+"/mechanism/"+String(mechanism.mechanism_id),{"mechanism_id":mechanism.mechanism_id,"host_face":{"cube_id":host,"face":4},"trigger":mechanism.trigger,"priority":mechanism.priority,"config":config,"target_bindings":{}})
				child(root,node,"ContactLock")
			if world.layer==0:
				for slot in level.celestial.slots:
					var node:Node3D=object("SLOT",String(id)+"/slot/"+String(slot.slot_id),{"slot_id":slot.slot_id})
					node.transform=Transform3D(Basis.IDENTITY,Vector3(slot.position2)/2.0)
					child(root,node,"Sky")
			save_scene(root,dir+"/"+name+".tscn")
		var fields:Dictionary={"authoring_version":"levelauthoring.v1","surface_source":dir+"/surface.tscn","inner_source":dir+"/inner.tscn","intent":intent,"spawn":{"face_ref":{"cube_id":level.spawn.location.cube_id,"face":level.spawn.location.face},"orientation":level.spawn.orientation},"goal":{"face_ref":{"cube_id":StringName(String(level.goal.face_id).get_slice("/",0)),"face":4},"required_flags":level.goal.required_flags}}
		for key in ["level_id","schema_version","contract_version","orientation_version","rule_version","cell_size","shift_compatibilities","flag_definitions","build_info","camera_initial_quadrant","perspective_falls"]:fields[key]=level[key]
		if level.schema_version==4:fields["shift_gates"]=level.shift_gates
		fields["celestial"]=level.celestial.duplicate(true)
		fields.celestial.erase("slots")
		var root:Node3D=object("LEVEL",String(id)+"/level",fields)
		root.name="Level"
		for name in ["surface","inner"]:
			var scene:PackedScene=load(dir+"/"+name+".tscn")
			child(root,scene.instantiate(),name.capitalize())
		save_scene(root,dir+"/level.tscn")
	FileAccess.open(out.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":5,"failures":failures},"\t"))
	quit(0 if failures.is_empty() else 1)
