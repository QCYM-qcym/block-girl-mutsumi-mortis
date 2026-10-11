extends RefCounted
## Owner09 loading orchestration only. No projection, schema, baking or gameplay rules.
const Schema=preload("res://foundation/authoring/authoring_schema.gd")
const Projector=preload("res://foundation/authoring/document_projector.gd")
const Assembler=preload("res://foundation/authoring/payload_assembler.gd")
const Adapter=preload("res://foundation/authoring/authoring_adapter.gd")
const IDS: Array[StringName]=[&"world_shift_gate_lab",&"orientation_loop_lab",&"face_lock_lab",&"perspective_fork_lab",&"rubik_spatial_puzzle_01"]

static func uri(id:StringName)->String:
	return "res://experiments/spatial_puzzle_batch_01/maps/authoring/"+String(id)+"/level.tscn"

static func document_id(state:SceneState)->String:
	for p in state.get_node_property_count(0):
		if state.get_node_property_name(0,p)==&"authoring_id":return state.get_node_property_value(0,p)
	return ""

static func snapshot(id:StringName)->Dictionary:
	if id not in IDS:return Schema.failure("UNKNOWN_MAP","level_id","Unknown Owner09 map.")
	var folder:String=uri(id).get_base_dir()
	var paths:Array[String]=[]
	for file in DirAccess.get_files_at(folder):
		if file.get_extension() in ["tscn","tres"]:paths.append(folder.path_join(file))
	paths.sort()
	var digests:Dictionary={}
	var hashes:PackedStringArray=[]
	for kind in Schema.SCRIPTS:
		var script:String=Schema.script_path(kind)
		digests[script]=FileAccess.get_sha256(script)
		hashes.append(script+":"+digests[script])
	for path in paths:hashes.append(path+":"+FileAccess.get_sha256(path))
	hashes.sort()
	return {"ok":true,"paths":paths,"digests":digests,"fingerprint":"\n".join(hashes).sha256_text()}

static func bake(id:StringName)->Dictionary:
	var snap:Dictionary=snapshot(id)
	if not snap.ok:return failure(snap.issues)
	var documents:Array[Dictionary]=[]
	var issues:Array=[]
	var level_id:String=""
	for path in snap.paths:
		var resource:Resource=ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE)
		if resource==null:
			issues.append(Schema.issue("MISSING_DOCUMENT",path,"Saved author resource cannot be loaded."));continue
		var source:Variant=resource.get_state() if resource is PackedScene else resource
		var author_id:String=document_id(source) if source is SceneState else resource.get("authoring_id")
		if path==uri(id):level_id=author_id
		var result:Dictionary=Projector.project_document(source,{"document_uri":path,"document_authoring_id":author_id,"origin":"SAVED","allowed_script_digests":snap.digests,"instance_role":null})
		if result.ok:documents.append(result.value)
		else:issues.append_array(result.issues)
	if not issues.is_empty():return failure(issues)
	var assembled:Dictionary=Assembler.assemble_payload(documents,{"level_authoring_id":level_id,"level_id":id,"root_source_uri":uri(id)})
	if not assembled.ok:return failure(assembled.issues)
	return Adapter.bake_authoring(assembled.value,{"max_configurations":4096,"max_checks":100000},{"run_id":"owner09_saved_"+String(id),"snapshot_id":snap.fingerprint,"source_fingerprint":snap.fingerprint,"source_intent_digest":FileAccess.get_sha256(uri(id).get_base_dir().path_join("intent.tres"))})

static func failure(issues:Array)->Dictionary:
	return {"ok":false,"level":null,"issues":issues,"validation":null,"source_map":null,"bake_provenance":null}
