extends RefCounted
const Sources=preload("res://foundation/authoring/source_map.gd")
const Saved=preload("res://experiments/spatial_puzzle_batch_01/maps/saved_authoring.gd")
static func verify(baked:Dictionary,id:StringName)->Array[String]:
	var errors:Array[String]=[]
	var uri:String=Saved.uri(id)
	var scene:PackedScene=load(uri)
	var root_uuid:String=Saved.document_id(scene.get_state())
	var expected:Array=[]
	for field in ["spawn","camera_initial_quadrant","perspective_falls"]:
		expected.append({"path":field,"uuid":root_uuid,"uri":uri,"node":".","field":field,"kind":"LEVEL","id":id})
	if baked.level.schema_version==4:expected.append({"path":"shift_gates","uuid":root_uuid,"uri":uri,"node":".","field":"shift_gates","kind":"LEVEL","id":id})
	if not baked.level.get("face_locks",[]).is_empty():
		var config_uri:String=uri.get_base_dir()+"/contact_lock.tres"
		var resource:Resource=load(config_uri)
		expected.append({"path":"face_locks[0].required_local_face","uuid":resource.get("authoring_id"),"uri":config_uri,"node":null,"field":"required_local_face","kind":"MECHANISM","id":&"contact_lock"})
	var world_uri:String=uri.get_base_dir()+"/surface.tscn"
	var world:SceneState=(load(world_uri) as PackedScene).get_state()
	for index in world.get_node_count():
		var fields:Dictionary={}
		for property in world.get_node_property_count(index):fields[String(world.get_node_property_name(index,property))]=world.get_node_property_value(index,property)
		if fields.get("cube_id")!=&"source":continue
		for cube_index in baked.level.cubes.size():
			if baked.level.cubes[cube_index].cube_id==&"source":expected.append({"path":"cubes[%d].center2"%cube_index,"uuid":fields.authoring_id,"uri":world_uri,"node":String(world.get_node_path(index)).trim_prefix("./"),"field":"transform","kind":"CUBE","id":&"source"})
		for face in fields.faces:
			if face.get("face")!=4:continue
			for face_index in baked.level.faces.size():
				if baked.level.faces[face_index].face_id==&"source/TOP":expected.append({"path":"faces[%d].walkable"%face_index,"uuid":face.get("authoring_id"),"uri":world_uri,"node":null,"field":"walkable","kind":"FACE","id":&"source/TOP"})
	if baked.source_map.level_hash!=baked.level.content_hash:errors.append("SourceMap level hash mismatch")
	if baked.source_map.source_fingerprint!=Saved.snapshot(id).fingerprint:errors.append("SourceMap snapshot mismatch")
	for item in expected:
		var located:Dictionary=Sources.locate(baked.source_map,{"path":item.path,"entity_ids":[]},"CANONICAL")
		if not located.ok or located.value.size()!=1:
			errors.append(item.path+" unique mapping missing");continue
		var entry:Dictionary=located.value[0]
		if entry.authoring_id!=item.uuid or entry.document_uri!=item.uri or entry.node_path_at_capture!=item.node or entry.field!=item.field or entry.entity_kind!=item.kind or entry.entity_id!=item.id or entry.canonical_path!=item.path:errors.append(item.path+" incorrect author provenance")
	return errors
