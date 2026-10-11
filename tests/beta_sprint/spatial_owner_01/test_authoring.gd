extends SceneTree
const F = preload("res://tests/foundation/authoring/authoring_fixtures.gd")
const SF = preload("res://tests/beta_sprint/spatial_owner_01/fixtures.gd")
const Schema = preload("res://foundation/authoring/authoring_schema.gd")
const Adapter = preload("res://foundation/authoring/authoring_adapter.gd")
const Projector = preload("res://foundation/authoring/document_projector.gd")
const Sources = preload("res://foundation/authoring/source_map.gd")
const RootScript = preload("res://foundation/authoring/level_authoring_root.gd")
const WorldScript = preload("res://foundation/authoring/world_authoring_root.gd")
const CubeScript = preload("res://foundation/authoring/cube_authoring_node.gd")
const SlotScript = preload("res://foundation/authoring/slot_authoring_node.gd")
const MechanismScript = preload("res://foundation/authoring/mechanism_authoring_node.gd")
const ConfigScript = preload("res://foundation/authoring/mechanism_config.gd")
const FaceScript = preload("res://foundation/authoring/face_authoring_resource.gd")
var checks := 0
var failures: Array[String] = []
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func _initialize() -> void:
	var payload := _payload()
	check(Schema.validate_authoring(payload).ok,"closed opt-in typed author document")
	var fields: Dictionary = payload.documents[0].records[0].fields
	var node := RootScript.new()
	for key in fields: node.set(key,fields[key])
	check(node.declared_fields() == fields,"Level root retains exact opt-in fields")
	node.free()
	var projected := _project_world(payload.documents[1])
	check(projected.ok,"real MechanismAuthoringNode/Config Resource Binding projection " + str(projected.issues))
	if projected.ok:
		payload.documents[1] = projected.value
		payload.resource_table = []
		for doc in payload.documents: payload.resource_table.append_array(doc.resources)
	var before := payload.duplicate(true)
	var baked := Adapter.bake_authoring(payload,F.options(),F.identity())
	check(baked.ok,"real Adapter->Reader->Baker " + str(baked.issues))
	check(payload == before,"typed source remains immutable")
	if baked.ok:
		check(baked.level.face_locks == [{"mechanism_id":&"lock_name","required_local_face":3,"activation_mode":&"LATCH_ON_SUCCESS","latched_state":&"latched"}],"Config projects exact formal lock")
		check(baked.level.shift_gates[0].required_mechanism_states == [{"mechanism_id":&"lock_name","state":&"latched"}],"author gate permission preserved")
		check(baked.validation.checks_performed > 0,"real static validation ran")
		var found := Sources.locate(baked.source_map,{"path":"face_locks[0].required_local_face","entity_ids":[]},"CANONICAL")
		check(found.ok and not found.value.is_empty() and found.value[0].authoring_id == F.uuid(220),"lock field resolves to actual bound config resource")
		var legacy := payload.duplicate(true)
		var root_fields: Dictionary = legacy.documents[0].records[0].fields
		root_fields.schema_version=1;root_fields.contract_version="foundation.contract.v1";root_fields.rule_version="foundation.rules.v1"
		for field in ["camera_initial_quadrant","perspective_falls","shift_gates"]: root_fields.erase(field)
		check(not Adapter.bake_authoring(legacy,F.options(),F.identity()).ok,"latch config cannot opt in legacy root")
	print("SPATIAL_AUTHORING checks=",checks," failures=",failures," doubles=[]")
	quit(0 if failures.is_empty() else 1)
func _payload() -> Dictionary:
	var payload := F.payload("")
	var level: Dictionary = payload.documents[0].records[0].fields
	level.schema_version=4;level.contract_version="foundation.spatial_puzzle.v1";level.rule_version="foundation.rules.spatial_puzzle.v1"
	level["camera_initial_quadrant"]=1;level["perspective_falls"]=[]
	level.goal.face_ref.cube_id=&"inner_floor"
	var gate := SF.gate(&"forward",&"floor/TOP",&"inner_floor/TOP")
	gate.required_mechanism_states=[{"mechanism_id":&"lock_name","state":&"latched"}]
	level["shift_gates"]=[gate]
	var world: Dictionary = payload.documents[1]
	world.records[2].fields.transform.origin.y=-5
	var faces: Array = []
	for face in 6:
		faces.append({"resource_ref":F.uuid(201+face)})
		world.resources.append(F.resource("FACE","surface.tscn",201+face,{"face":face,"walkable":face==4,"shift_exit_blocked":false,"shift_entry_blocked":false}))
	world.records.append(F.record("CUBE",200,{"cube_id":&"step","occludes_light":true,"tags":[],"transform":Transform3D(Basis.IDENTITY,Vector3(1,0,0)),"faces":faces},"Step"))
	world.resources.append(F.resource("MECHANISM_CONFIG","surface.tscn",220,{"kind":5,"initial_state":&"inactive","allowed_states":[&"inactive",&"latched"],"required_local_face":3,"activation_mode":&"LATCH_ON_SUCCESS","latched_state":&"latched"}))
	world.records.append(F.record("MECHANISM",230,{"mechanism_id":&"lock_name","host_face":{"cube_id":&"step","face":4},"trigger":&"ENTER","priority":0,"config":{"resource_ref":F.uuid(220)},"target_bindings":{}},"Plate"))
	payload.resource_table=[]
	for doc in payload.documents: payload.resource_table.append_array(doc.resources)
	return payload
func _project_world(doc: Dictionary) -> Dictionary:
	var resources := {}
	for resource in doc.resources:
		var object: Resource = ConfigScript.new() if resource.kind == "MECHANISM_CONFIG" else FaceScript.new()
		object.set("authoring_id",resource.authoring_id)
		for key in resource.fields: object.set(key,resource.fields[key])
		resources[resource.authoring_id]=object
	var world := WorldScript.new()
	for record in doc.records:
		var node: Node3D = world
		if record.kind == "CUBE": node=CubeScript.new()
		elif record.kind == "SLOT": node=SlotScript.new()
		elif record.kind == "MECHANISM": node=MechanismScript.new()
		node.set("authoring_id",record.authoring_id)
		for key in record.fields:
			var value: Variant = record.fields[key]
			if key == "faces":
				value=[]
				for ref in record.fields.faces: value.append(resources[ref.resource_ref])
			elif key == "config": value=resources[value.resource_ref]
			node.set(key,value)
		if node != world:
			node.name=record.node_path
			world.add_child(node)
	var digests := {}
	for kind in Schema.SCRIPTS: digests[Schema.script_path(kind)]=FileAccess.get_sha256(Schema.script_path(kind))
	var result := Projector.project_document(world,{"document_uri":doc.document_uri,"document_authoring_id":doc.document_authoring_id,"origin":"EDITOR_BUFFER","allowed_script_digests":digests,"instance_role":null})
	world.free()
	return result
