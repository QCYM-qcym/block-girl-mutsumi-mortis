extends SceneTree
## Diagnostic live-node projection of the SAME saved resources, never a production fallback.
const Factory=preload("res://experiments/spatial_puzzle_batch_01/maps/map_factory.gd")
const Saved=preload("res://experiments/spatial_puzzle_batch_01/maps/saved_authoring.gd")
const Schema=preload("res://foundation/authoring/authoring_schema.gd")
const Projector=preload("res://foundation/authoring/document_projector.gd")
const Assembler=preload("res://foundation/authoring/payload_assembler.gd")
const Adapter=preload("res://foundation/authoring/authoring_adapter.gd")
const Sources=preload("res://foundation/authoring/source_map.gd")
var checks:=0
var failures:Array=[]
var rows:Array=[]
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label)
func run()->void:
	for id in Factory.ids():
		var snapshot:Dictionary=Saved.snapshot(id)
		var docs:Array[Dictionary]=[]
		var row:Dictionary={"id":id,"projections":[]}
		rows.append(row)
		var root_id:String=""
		var all_ok:bool=true
		for path in snapshot.paths:
			var resource:Resource=ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE)
			var source:Variant=resource.get_state() if resource is PackedScene else resource
			var author_id:String=Saved.document_id(source) if source is SceneState else resource.get("authoring_id")
			if path==Saved.uri(id):
				root_id=author_id
				# Supported public Node3D overload used only to isolate frozen projector from schema/adapter.
				source=resource.instantiate()
				var fields:Dictionary=source.declared_fields()
				fields.erase("authoring_id")
				fields.intent={"resource_ref":fields.intent.get("authoring_id")}
				row["typed_level_fields"]=fields
				row["typed_level_valid"]=Schema.fields_valid("LEVEL",fields)
			var projected:Dictionary=Projector.project_document(source,{"document_uri":path,"document_authoring_id":author_id,"origin":"SAVED","allowed_script_digests":snapshot.digests,"instance_role":null})
			if source is Node:source.free()
			row.projections.append({"path":path,"ok":projected.ok,"issues":projected.issues})
			if projected.ok:docs.append(projected.value)
			else:all_ok=false
			check(projected.ok,String(id)+" diagnostic projection "+path.get_file())
		if not all_ok:continue
		var assembled:Dictionary=Assembler.assemble_payload(docs,{"level_authoring_id":root_id,"level_id":id,"root_source_uri":Saved.uri(id)})
		row["assembly"]={"ok":assembled.ok,"issues":assembled.issues}
		check(assembled.ok,String(id)+" real assembly")
		if not assembled.ok:continue
		var baked:Dictionary=Adapter.bake_authoring(assembled.value,{"max_configurations":4096,"max_checks":100000},{"run_id":"diagnostic_"+String(id),"snapshot_id":snapshot.fingerprint,"source_fingerprint":snapshot.fingerprint,"source_intent_digest":null})
		row["bake"]={"ok":baked.ok,"issues":baked.issues}
		check(baked.ok,String(id)+" real diagnostic Adapter Reader Baker")
		if not baked.ok:continue
		var golden:Dictionary=str_to_var(FileAccess.get_file_as_string("res://tests/beta_sprint/spatial_owner_09/migration_baseline/"+String(id)+".gdvar"))
		row["canonical_equal"]=baked.level==golden.level
		row["hash"]=baked.level.content_hash
		row["baseline_hash"]=golden.level.content_hash
		check(baked.level==golden.level,String(id)+" diagnostic canonical/hash parity")
		var fields:Array=["spawn","camera_initial_quadrant","shift_gates"]
		if not baked.level.perspective_falls.is_empty():fields.append("perspective_falls")
		if not baked.level.face_locks.is_empty():fields.append("face_locks[0].required_local_face")
		row["locations"]={}
		for field in fields:
			var found:Dictionary=Sources.locate(baked.source_map,{"path":field,"entity_ids":[]},"CANONICAL")
			row.locations[field]=found
			check(found.ok and not found.value.is_empty(),String(id)+" source " +field)
	FileAccess.open(OS.get_cmdline_user_args()[0].path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows,"production_acceptance":false},"\t"))
	quit(0 if failures.is_empty() else 1)
