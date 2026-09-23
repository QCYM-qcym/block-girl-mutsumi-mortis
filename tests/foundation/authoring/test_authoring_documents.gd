extends "res://tests/foundation/authoring_integration/test_suite.gd"
const Schema = preload("res://foundation/authoring/authoring_schema.gd")
const F = preload("res://tests/foundation/authoring/authoring_fixtures.gd")
const Projector = preload("res://foundation/authoring/document_projector.gd")
const Assembler = preload("res://foundation/authoring/payload_assembler.gd")

func run() -> void:
	check(Schema.validate_authoring(F.payload("minimal")).ok, "explicit six faces and two worlds are accepted")
	for name in ["missing_face", "duplicate_face", "duplicate_id", "shared_alias", "resource_conflict", "unsupported_override"]:
		var invalid := F.payload(name)
		var before := invalid.duplicate(true)
		check(not Schema.validate_authoring(invalid).ok, name + " is rejected")
		check(invalid == before, name + " is never silently repaired")
	check(Schema.validate_authoring(F.payload("off_lattice")).ok, "authoring does not quantize or replace Reader legality")
	var unknown := F.payload("minimal")
	unknown.authoring_version = "unknown"
	check(not Schema.validate_authoring(unknown).ok, "unknown authoring version must be rejected")
	var missing := F.payload("minimal")
	missing.documents[1].resources[0].fields.erase("walkable")
	check(not Schema.validate_authoring(missing).ok, "missing false field must not be defaulted")
	var extra := F.payload("minimal")
	extra.documents[1].resources[0].fields["mechanism_ids"] = []
	check(not Schema.validate_authoring(extra).ok, "reverse mechanism index is not author writable")
	_nested_cases()
	_persistence()
	_projection_boundaries()
	_resource_ownership()
	_scene_hierarchy_edges()
	finish()

func _nested_cases() -> void:
	var cases: Array[Dictionary] = []
	var candidate := F.payload("minimal")
	candidate.documents[0].records[0].fields.spawn["unknown"] = true
	cases.append({"label": "nested spawn unknown field", "payload": candidate})
	candidate = F.payload("minimal")
	candidate.documents[0].records[0].fields.goal.face_ref.cube_id = &"absent"
	cases.append({"label": "unresolved goal face", "payload": candidate})
	candidate = F.payload("minimal")
	candidate.documents[1].records[0].fields.allowed_states = ["0"]
	cases.append({"label": "wrong world orientation element type", "payload": candidate})
	candidate = F.payload("minimal")
	candidate.documents[1].records[1].fields.tags = [Callable()]
	cases.append({"label": "callback in declaration", "payload": candidate})
	candidate = F.payload("minimal")
	candidate.documents[0].records[0].fields.celestial.slot_order = [&"absent"]
	cases.append({"label": "unresolved celestial slot", "payload": candidate})
	candidate = F.payload("minimal")
	candidate.documents[0].records[0].fields.goal.required_flags = [&"absent"]
	cases.append({"label": "unresolved goal flag", "payload": candidate})
	candidate = F.payload("minimal")
	candidate.documents[0].records[0].fields.flag_definitions = [{"flag_id": &"flag", "initial_value": false}, {"flag_id": &"flag", "initial_value": true}]
	cases.append({"label": "duplicate flag identity", "payload": candidate})
	candidate = F.payload("minimal")
	candidate.documents[1].records[0] = null
	cases.append({"label": "malformed root record returns a diagnostic", "payload": candidate})
	candidate = F.payload("minimal")
	candidate.documents[3].resources[0].fields.required_mechanics = [0, 0]
	cases.append({"label": "duplicate intent mechanic", "payload": candidate})
	candidate = F.payload("minimal")
	candidate.documents[1].records[2].node_path = "Cube/Sun"
	cases.append({"label": "pure payload gameplay hierarchy is not flattened", "payload": candidate})
	candidate = F.payload("minimal")
	var conflicting: Dictionary = candidate.documents[3].resources[0].duplicate(true)
	conflicting.authoring_id = F.uuid(400)
	conflicting.fields.intent_id = &"other_intent"
	candidate.documents[0].resources.append(conflicting)
	candidate.resource_table.append(conflicting)
	cases.append({"label": "one external Intent URI cannot hold two identities", "payload": candidate})
	candidate = F.payload("minimal")
	candidate.documents[1].records[1].fields.faces[0] = {"resource_ref": F.uuid(999)}
	cases.append({"label": "missing semantic resource is rejected", "payload": candidate})
	candidate = F.payload("minimal")
	candidate.documents[1].root_transform.origin.x = 1.0
	cases.append({"label": "World root transform remains identity", "payload": candidate})
	candidate = F.payload("minimal")
	candidate.documents[1].records[1].authoring_id = F.uuid(2)
	cases.append({"label": "duplicate authoring identity is rejected", "payload": candidate})
	candidate = F.payload("minimal")
	candidate.documents.pop_back()
	cases.append({"label": "missing dependency document cannot use stale data", "payload": candidate})
	for item in cases:
		check(not Schema.validate_authoring(item.payload).ok, item.label)
	var config := {"kind": 6, "initial_state": &"default", "allowed_states": [&"default"], "rotation_delta": 22}
	check(Schema.fields_valid("MECHANISM_CONFIG", config), "group config uses explicit approved rotation_delta")
	config.initial_state = &"ready"
	config.allowed_states = [&"ready"]
	check(Schema.fields_valid("MECHANISM_CONFIG", config), "single mechanism state is preserved without renaming to default")
	config.allowed_states = ["ready"]
	check(not Schema.fields_valid("MECHANISM_CONFIG", config), "mechanism state requires StringName rather than equal String")
	config.allowed_states = [&"ready"]
	config["target_bindings"] = {"group_id": &"group"}
	check(not Schema.fields_valid("MECHANISM_CONFIG", config), "config cannot own instance targets")

func context(file: String, n: int) -> Dictionary:
	var digests := {}
	for kind in Schema.SCRIPTS:
		var path: String = Schema.script_path(kind)
		digests[path] = FileAccess.get_sha256(path)
	return {"document_uri": F.BASE + file, "document_authoring_id": F.uuid(n), "origin": "SAVED", "allowed_script_digests": digests, "instance_role": null}

func _persistence() -> void:
	var projected: Array[Dictionary] = []
	for index in range(3):
		var file: String = ["level.tscn", "surface.tscn", "inner.tscn"][index]
		var packed := load(F.BASE + file) as PackedScene
		check(packed != null, file + " loads a real PackedScene")
		if packed == null:
			continue
		var root := packed.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE) as Node3D
		check(root != null, file + " creates supported author nodes")
		if root == null:
			continue
		var ctx := context(file, index + 1)
		var live: Dictionary = Projector.project_document(root, ctx)
		var saved: Dictionary = Projector.project_document(packed.get_state(), ctx)
		if not live.ok or not saved.ok or live.value != saved.value:
			var diagnostic := FileAccess.open(evidence_dir().path_join(file + ".projection.txt"), FileAccess.WRITE)
			diagnostic.store_string("LIVE\n" + var_to_str(live) + "\nSAVED\n" + var_to_str(saved))
			diagnostic.close()
		check(live.ok, file + " live projection succeeds")
		check(saved.ok, file + " frozen SceneState projection succeeds")
		if live.ok and saved.ok:
			check(live.value == saved.value, file + " both readers project the same declaration")
			check(Schema.pure(live.value), file + " projection has no active object references")
			projected.append(live.value)
		var reopened_scene := PackedScene.new()
		check(reopened_scene.pack(root) == OK, file + " real packing succeeds")
		var path := evidence_dir().path_join(file)
		check(ResourceSaver.save(reopened_scene, path) == OK, file + " real scene save succeeds")
		var reopened := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
		check(reopened != null, file + " saved scene reopens")
		if reopened != null and saved.ok:
			var replayed: Dictionary = Projector.project_document(reopened.get_state(), ctx)
			check(replayed.ok and replayed.value == saved.value, file + " save preserves IDs false fields and aliases")
		root.free()
	var intent := load(F.BASE + "intent.tres") as Resource
	var intent_projection: Dictionary = Projector.project_document(intent, context("intent.tres", 4))
	check(intent_projection.ok, "standalone Intent Resource projects")
	check(ResourceSaver.save(intent, evidence_dir().path_join("intent.tres")) == OK, "real resource saves")
	var intent_reopened := ResourceLoader.load(evidence_dir().path_join("intent.tres"), "", ResourceLoader.CACHE_MODE_IGNORE)
	var intent_again: Dictionary = Projector.project_document(intent_reopened, context("intent.tres", 4))
	check(intent_again.ok and intent_projection.ok and intent_again.value == intent_projection.value, "Intent reopens without identity loss")
	if intent_projection.ok:
		projected.append(intent_projection.value)
	var assembled: Dictionary = Assembler.assemble_payload(projected, F.payload("minimal").level_ref)
	check(assembled.ok, "real saved scene and resource closure assembles")
	if assembled.ok:
		check(Schema.validate_authoring(assembled.value).ok, "actual author scene closure validates")
	var good := F.documents("minimal")
	check(Assembler.assemble_payload(good, F.payload("minimal").level_ref).ok, "value declaration closure assembles")
	check(not Assembler.assemble_payload(F.documents("resource_conflict"), F.payload("minimal").level_ref).ok, "assembler rejects conflicting resource versions")

func _project_both(root: Node3D, ctx: Dictionary, label: String) -> void:
	var live: Dictionary = Projector.project_document(root, ctx)
	check(not live.ok and live.value == null, label + " live rejected")
	var packed := PackedScene.new()
	check(packed.pack(root) == OK, label + " packs for frozen negative")
	var saved: Dictionary = Projector.project_document(packed.get_state(), ctx)
	check(not saved.ok and saved.value == null, label + " frozen rejected")

func _projection_boundaries() -> void:
	var level := (load(F.BASE + "level.tscn") as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE) as Node3D
	level.get_node("Surface").name = "DisplayName"
	check(Projector.project_document(level, context("level.tscn", 1)).ok, "World instance display name is not a gameplay override")
	var duplicate := (load(F.BASE + "surface.tscn") as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE) as Node3D
	level.add_child(duplicate)
	duplicate.owner = level
	_project_both(level, context("level.tscn", 1), "duplicate World assembly")
	level.free()
	var world := (load(F.BASE + "surface.tscn") as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE) as Node3D
	var cube := world.get_node("Cube") as Node3D
	var sun := world.get_node("Sun") as Node3D
	sun.owner = null
	sun.reparent(cube, false)
	sun.owner = world
	cube.position = Vector3(3, 0, 0)
	_project_both(world, context("surface.tscn", 2), "gameplay nesting cannot lose inherited placement")
	world.free()
	world = (load(F.BASE + "surface.tscn") as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE) as Node3D
	cube = world.get_node("Cube") as Node3D
	cube.position.x = 0.125
	var raw: Dictionary = Projector.project_document(world, context("surface.tscn", 2))
	check(raw.ok and raw.value.records[1].fields.transform.origin.x == 0.125, "projection preserves off-lattice transform")
	var config_script := load(Schema.script_path("MECHANISM_CONFIG")) as GDScript
	var config: Resource = config_script.new()
	config.set("authoring_id", F.uuid(30))
	config.set("kind", 7)
	config.set("initial_state", &"default")
	config.set("allowed_states", [&"default"])
	config.set("celestial_op", 0)
	for i in range(2):
		var mechanism: Node3D = load(Schema.script_path("MECHANISM")).new()
		mechanism.name = "Mechanism" + str(i)
		mechanism.set("authoring_id", F.uuid(31 + i))
		mechanism.set("mechanism_id", &"switch_one" if i == 0 else &"switch_two")
		mechanism.set("host_face", {"cube_id": &"floor", "face": 4})
		mechanism.set("trigger", &"USE")
		mechanism.set("priority", i)
		mechanism.set("config", config)
		mechanism.set("target_bindings", {"target_slot_id": &"sun", "alternate_slot_id": &""})
		world.add_child(mechanism)
		mechanism.owner = world
	var alias: Dictionary = Projector.project_document(world, context("surface.tscn", 2))
	check(alias.ok, "shared real config projects")
	if alias.ok:
		check(alias.value.resources.size() == 7, "shared config has one resource-table identity")
	var packed := PackedScene.new()
	check(packed.pack(world) == OK, "shared config scene packs")
	var saved_path := evidence_dir().path_join("shared_alias.tscn")
	check(ResourceSaver.save(packed, saved_path) == OK, "shared config scene saves")
	var reopened := (ResourceLoader.load(saved_path, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	check(is_same(reopened.get_node("Mechanism0").get("config"), reopened.get_node("Mechanism1").get("config")), "shared config alias survives real reopen")
	var again: Dictionary = Projector.project_document(reopened, context("surface.tscn", 2))
	check(again.ok and alias.ok and again.value == alias.value, "shared scene reprojects without alias or transform loss")
	reopened.free()
	var original_source := config_script.source_code
	config_script.source_code = original_source + "\n# unsaved script revision\n"
	var changed: Dictionary = Projector.project_document(world, context("surface.tscn", 2))
	check(not changed.ok, "in-memory script drift cannot borrow disk digest")
	config_script.source_code = original_source
	world.get_node("Mechanism0").position = Vector3(7, 2, 1)
	var visual: Dictionary = Projector.project_document(world, context("surface.tscn", 2))
	check(visual.ok and alias.ok and visual.value == alias.value, "mechanism visual placement is not gameplay binding")
	world.free()
	var intent: Resource = load(Schema.script_path("INTENT")).new()
	for key in F.documents("minimal")[3].resources[0].fields:
		intent.set(key, F.documents("minimal")[3].resources[0].fields[key])
	intent.set("authoring_id", F.uuid(4))
	var cyclic: Array = [intent]
	intent.set("expected_milestones", cyclic)
	check(not Projector.project_document(intent, context("intent.tres", 4)).ok, "semantic Resource cycle rejects without partial result")
	cyclic.clear()
	intent.set("expected_milestones", [Resource.new()])
	check(not Projector.project_document(intent, context("intent.tres", 4)).ok, "unknown semantic Resource rejects")
	intent.set("expected_milestones", [])

func _resource_ownership() -> void:
	var intent: Resource = load(Schema.script_path("INTENT")).new()
	for key in F.documents("minimal")[3].resources[0].fields:
		intent.set(key, F.documents("minimal")[3].resources[0].fields[key])
	intent.set("authoring_id", F.uuid(4))
	intent.take_over_path(F.BASE + "intent.tres")
	var milestone: Resource = load(Schema.script_path("MILESTONE")).new()
	milestone.set("authoring_id", F.uuid(40))
	milestone.set("milestone_id", &"reach_floor")
	milestone.set("required", true)
	milestone.set("predicate", {"kind": 0, "face_ref": {"cube_id": &"floor", "face": 4}})
	var bypass: Resource = load(Schema.script_path("BYPASS")).new()
	bypass.set("authoring_id", F.uuid(41))
	bypass.set("bypass_id", &"without_shift")
	bypass.set("disabled_mechanics", [1])
	intent.set("expected_milestones", [milestone])
	intent.set("forbidden_bypasses", [bypass])
	var level := (load(F.BASE + "level.tscn") as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE) as Node3D
	level.set("intent", intent)
	var projected: Dictionary = Projector.project_document(level, context("level.tscn", 1))
	var separate: Dictionary = Projector.project_document(intent, context("intent.tres", 4))
	check(projected.ok and separate.ok, "nested external Intent projects through both roots")
	if projected.ok and separate.ok:
		check(projected.value.resources == separate.value.resources, "embedded semantic children belong to external Intent document")
		var docs := F.documents("minimal")
		docs[0] = projected.value
		docs[3] = separate.value
		check(Assembler.assemble_payload(docs, F.payload("minimal").level_ref).ok, "valid external nested resource closure assembles")
	check(ResourceSaver.save(intent, evidence_dir().path_join("nested_intent.tres")) == OK, "nested Intent really saves")
	var reopened := ResourceLoader.load(evidence_dir().path_join("nested_intent.tres"), "", ResourceLoader.CACHE_MODE_IGNORE)
	var again: Dictionary = Projector.project_document(reopened, context("intent.tres", 4))
	check(again.ok and separate.ok and again.value == separate.value, "Milestone and Bypass survive Resource reopen")
	level.free()
	var path := evidence_dir().path_join("inherited_world.tscn")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string('[gd_scene load_steps=2 format=3]\n[ext_resource type="PackedScene" path="' + F.BASE + 'surface.tscn" id="Base"]\n[node name="Surface" instance=ExtResource("Base")]\n')
	file.close()
	var packed := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	check(packed != null, "inherited negative fixture loads")
	if packed != null:
		var inherited := packed.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
		check(not Projector.project_document(inherited, context("surface.tscn", 2)).ok, "live inherited gameplay source is rejected")
		check(not Projector.project_document(packed.get_state(), context("surface.tscn", 2)).ok, "frozen inherited gameplay source is rejected")
		inherited.free()

func _scene_hierarchy_edges() -> void:
	var source := FileAccess.get_file_as_string(F.BASE + "surface.tscn")
	var path := evidence_dir().path_join("scaled_container.tscn")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(source + '\n[node name="Container" type="Node3D" parent="."]\nscale = Vector3(2, 2, 2)\n')
	file.close()
	var packed := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	check(packed != null, "scaled native container fixture loads")
	if packed != null:
		check(not Projector.project_document(packed.get_state(), context("surface.tscn", 2)).ok, "frozen separate scale property cannot disappear")
		var live := packed.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
		check(not Projector.project_document(live, context("surface.tscn", 2)).ok, "live scaled container rejects")
		live.free()
	var world := (load(F.BASE + "surface.tscn") as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	var cube := world.get_node("Cube")
	var child_scene := PackedScene.new()
	check(child_scene.pack(cube) == OK, "Cube subscene negative packs")
	var child_path := evidence_dir().path_join("cube_instance.tscn")
	check(ResourceSaver.save(child_scene, child_path) == OK, "Cube subscene negative saves")
	var loaded := ResourceLoader.load(child_path, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	var child := loaded.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	child.name = "CubeInstance"
	world.add_child(child)
	child.owner = world
	_project_both(world, context("surface.tscn", 2), "nested scene instance in World")
	world.free()
