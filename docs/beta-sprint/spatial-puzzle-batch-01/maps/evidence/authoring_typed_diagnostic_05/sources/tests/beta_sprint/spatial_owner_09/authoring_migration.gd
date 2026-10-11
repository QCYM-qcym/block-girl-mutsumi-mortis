extends SceneTree
const Factory=preload("res://experiments/spatial_puzzle_batch_01/maps/map_factory.gd")
const Sources=preload("res://foundation/authoring/source_map.gd")
const Session=preload("res://foundation/runtime/runtime_session.gd")
const Key=preload("res://foundation/contracts/state_key.gd")
const SourceChecks=preload("res://tests/beta_sprint/spatial_owner_09/source_expectations.gd")
var checks:=0
var failures:Array=[]
var rows:Array=[]
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label)
func run()->void:
	var out:String=OS.get_cmdline_user_args()[0]
	for id in Factory.ids():
		var uri:String="res://experiments/spatial_puzzle_batch_01/maps/authoring/"+String(id)+"/level.tscn"
		check(FileAccess.file_exists(uri),String(id)+" saved formal entry exists")
		var baked:Dictionary=Factory.bake(id)
		check(baked.ok,String(id)+" real saved authoring bake")
		var row:Dictionary={"id":id,"ok":baked.ok,"issues":baked.get("issues",[])}
		rows.append(row)
		check(baked.get("source_map") is Dictionary,String(id)+" actual adapter source map")
		if not baked.ok:continue
		var source_errors:Array[String]=SourceChecks.verify(baked,id)
		check(source_errors.is_empty(),String(id)+" exact SourceMap identity "+str(source_errors))
		var golden:Dictionary=str_to_var(FileAccess.get_file_as_string("res://tests/beta_sprint/spatial_owner_09/migration_baseline/"+String(id)+".gdvar"))
		check(baked.level==golden.level,String(id)+" exact canonical level and hash parity")
		if baked.get("source_map") is Dictionary:
			var found:Dictionary=Sources.locate(baked.source_map,{"path":"spawn","entity_ids":[]},"CANONICAL")
			check(found.ok and not found.value.is_empty(),String(id)+" root source location")
			if found.ok and not found.value.is_empty():check(found.value[0].document_uri==uri,String(id)+" source resolves saved level")
			for field in ["camera_initial_quadrant","perspective_falls"]:
				var located:Dictionary=Sources.locate(baked.source_map,{"path":field,"entity_ids":[]},"CANONICAL")
				check(located.ok and not located.value.is_empty() and located.value[0].document_uri==uri,String(id)+" formal field SourceMap "+field)
			if baked.level.schema_version==4:
				var located:Dictionary=Sources.locate(baked.source_map,{"path":"shift_gates","entity_ids":[]},"CANONICAL")
				check(located.ok and not located.value.is_empty() and located.value[0].document_uri==uri,String(id)+" gate SourceMap")
			if not baked.level.get("face_locks",[]).is_empty():
				var located:Dictionary=Sources.locate(baked.source_map,{"path":"face_locks[0].required_local_face","entity_ids":[]},"CANONICAL")
				check(located.ok and not located.value.is_empty() and located.value[0].document_uri==uri.get_base_dir()+"/contact_lock.tres",String(id)+" config SourceMap")
		for label in golden.traces:
			var session=Session.new()
			var tokens:Array=[]
			session.transition_started.connect(func(_r,i,g,b):tokens.append([i,g,b]))
			check(session.load_level(baked.level).ok,String(id)+" load")
			for index in golden.traces[label].size():
				var expected:Dictionary=golden.traces[label][index]
				if index>0:
					var response:Dictionary=session.request_action(expected.action)
					check(response.status==expected.status,String(id)+" "+label+" action status")
					if response.status==0 and response.changed:
						var token:Array=tokens[-1]
						if token[2]:session.finish_global(token[0],token[1])
						else:session.finish_local(token[0],token[1])
				check(session.state==expected.state and Key.build(baked.level,session.state).key==expected.key,String(id)+" "+label+" state/key/orientation parity "+str(index))
			session.reset()
			check(Key.build(baked.level,session.state).key==golden.traces[label][0].key,String(id)+" Reset parity")
	FileAccess.open(out.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows,"doubles":[]},"\t"))
	print("AUTHORING MIGRATION checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
