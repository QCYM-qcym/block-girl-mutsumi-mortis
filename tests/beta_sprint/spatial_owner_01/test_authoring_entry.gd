extends SceneTree
const Maps = preload("res://experiments/spatial_puzzle_batch_01/maps/map_factory.gd")
const Saved = preload("res://experiments/spatial_puzzle_batch_01/maps/saved_authoring.gd")
const Schema = preload("res://foundation/authoring/authoring_schema.gd")
const Projector = preload("res://foundation/authoring/document_projector.gd")
var checks := 0
var failures: Array[String] = []
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	for id in Maps.ids(): _level(id)
	_stored_negatives()
	var result := {"checks":checks,"failures":failures,"doubles":[]}
	FileAccess.open(OS.get_cmdline_user_args()[0].path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify(result))
	print("AUTHORING_ENTRY checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
func context(id: StringName, uri: String = "") -> Dictionary:
	var packed := ResourceLoader.load(Saved.uri(id),"",ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	var snapshot: Dictionary = Saved.snapshot(id)
	return {"document_uri":Saved.uri(id) if uri.is_empty() else uri,"document_authoring_id":Saved.document_id(packed.get_state()),"origin":"SAVED","allowed_script_digests":snapshot.digests,"instance_role":null}
func _level(id: StringName) -> void:
	var packed := ResourceLoader.load(Saved.uri(id),"",ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	var node := packed.instantiate() as Node3D
	var fields: Dictionary = node.declared_fields()
	fields.erase("authoring_id")
	fields.intent={"resource_ref":fields.intent.get("authoring_id")}
	check(Schema.fields_valid("LEVEL",fields),String(id)+" exact existing version declaration supported")
	var ctx := context(id)
	var frozen := Projector.project_document(packed.get_state(),ctx)
	var live := Projector.project_document(node,ctx)
	check(frozen.ok,String(id)+" actual saved SceneState projection")
	check(live.ok,String(id)+" actual live Node projection")
	check(frozen.ok and live.ok and frozen.value==live.value,String(id)+" saved/live closed declarations exactly equal")
	node.free()
	for mutation in ["missing_camera","missing_falls","camera_type","camera_range","falls_type","unknown_field","wrong_rule","wrong_contract","unknown_schema","wrong_orientation"]:
		var invalid := fields.duplicate(true)
		match mutation:
			"missing_camera": invalid.erase("camera_initial_quadrant")
			"missing_falls": invalid.erase("perspective_falls")
			"camera_type": invalid.camera_initial_quadrant=true
			"camera_range": invalid.camera_initial_quadrant=4
			"falls_type": invalid.perspective_falls={}
			"unknown_field": invalid["debug_state"]=true
			"wrong_rule": invalid.rule_version="foundation.rules.unapproved"
			"wrong_contract": invalid.contract_version="foundation.unapproved"
			"unknown_schema": invalid.schema_version=5
			"wrong_orientation": invalid.orientation_version="cube24.v2"
		check(not Schema.fields_valid("LEVEL",invalid),String(id)+" rejects " + mutation)
	if fields.schema_version==3:
		for field in ["shift_gates","face_locks"]:
			var invalid := fields.duplicate(true)
			invalid[field]=[]
			check(not Schema.fields_valid("LEVEL",invalid),"schema3 cannot acquire schema4 field " + field)
		var version2 := fields.duplicate(true)
		version2.schema_version=2;version2.contract_version="foundation.game_feel.v1";version2.rule_version="foundation.rules.game_feel.v1"
		check(not Schema.fields_valid("LEVEL",version2),"does not broaden previously unsupported typed schema2")
	var untrusted := ctx.duplicate(true)
	untrusted.allowed_script_digests[Schema.script_path("LEVEL")]="0".repeat(64)
	var denied := Projector.project_document(packed.get_state(),untrusted)
	check(not denied.ok and has_code(denied,"UNSUPPORTED_SCRIPT"),String(id)+" wrong digest remains fail closed")
func has_code(result: Dictionary, code: String) -> bool:
	for issue in result.issues:
		if issue.code==code: return true
	return false
func _stored_negatives() -> void:
	var id := &"perspective_fork_lab"
	var original := FileAccess.get_file_as_string(Saved.uri(id))
	var fixture_dir := OS.get_environment("TEMP").path_join("fixtures")
	DirAccess.make_dir_recursive_absolute(fixture_dir)
	for mutation in ["unknown_field","schema4_field","missing_camera","wrong_type","wrong_version","instance_override"]:
		var text := original
		match mutation:
			"unknown_field": text=text.replace("\n[node name=\"Surface\"","\ndebug_state = true\n[node name=\"Surface\"")
			"schema4_field": text=text.replace("\n[node name=\"Surface\"","\nshift_gates = []\n[node name=\"Surface\"")
			"missing_camera": text=text.replace("camera_initial_quadrant = 1\n","")
			"wrong_type": text=text.replace("camera_initial_quadrant = 1","camera_initial_quadrant = \"1\"")
			"wrong_version": text=text.replace("foundation.rules.game_feel.v2","foundation.rules.spatial_puzzle.v1")
			"instance_override":
				var start := text.find("[node name=\"Surface\"")
				var end := text.find("\n",start)
				text=text.insert(end+1,"pivot2 = Vector3i(1, 0, 0)\n")
		check(text!=original,"stored negative really changes one field " + mutation)
		var uri := fixture_dir.path_join(mutation+".tscn")
		FileAccess.open(uri,FileAccess.WRITE).store_string(text)
		var packed := ResourceLoader.load(uri,"",ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
		check(packed!=null,"valid parsed negative fixture " + mutation)
		if packed==null: continue
		var denied := Projector.project_document(packed.get_state(),context(id,uri))
		var code := "UNSUPPORTED_AUTHORING_OVERRIDE" if mutation=="instance_override" else ("INVALID_FIELD" if mutation in ["unknown_field","schema4_field"] else "INVALID_RECORD")
		check(not denied.ok and denied.value==null and has_code(denied,code),"stored closed boundary " + mutation + str(denied.issues))
