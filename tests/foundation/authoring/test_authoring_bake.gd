extends "res://tests/foundation/authoring_integration/test_suite.gd"
const Adapter = preload("res://foundation/authoring/authoring_adapter.gd")
const Sources = preload("res://foundation/authoring/source_map.gd")
const Projector = preload("res://foundation/authoring/document_projector.gd")
const Assembler = preload("res://foundation/authoring/payload_assembler.gd")
const Schema = preload("res://foundation/authoring/authoring_schema.gd")
const Codec = preload("res://foundation/level/level_codec.gd")
const Geometry = preload("res://foundation/spatial/surface_geometry.gd")
const Reader = preload("res://foundation/level/authoring_reader.gd")
const IntentTypes = preload("res://foundation/quality/intent/intent_types.gd")
const F = preload("res://tests/foundation/authoring/authoring_fixtures.gd")
var added_nodes := 0

func run() -> void:
	var payload := real_payload()
	if payload.is_empty():
		finish()
		return
	var before := payload.duplicate(true)
	_provenance_cases(payload)
	node_added.connect(_on_node_added)
	var orphan_count := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var one := Adapter.bake_authoring(payload, F.options(), F.identity())
	var two := Adapter.bake_authoring(payload, F.options(), F.identity())
	var diagnostic := FileAccess.open(evidence_dir().path_join("bake.txt"), FileAccess.WRITE)
	diagnostic.store_string(var_to_str(one))
	diagnostic.close()
	check(one.ok and two.ok, "real projected author closure bakes twice")
	check(payload == before, "bake preserves source declarations")
	check(added_nodes == 0, "temporary profile never enters active SceneTree")
	check(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)) == orphan_count, "success frees detached temporary nodes")
	var renamed := real_payload(true)
	var reordered := Adapter.bake_authoring(renamed, F.options(), F.identity())
	check(reordered.ok, "renamed reordered real author scene bakes")
	if one.ok and two.ok and reordered.ok:
		check(Codec.encode(one.level).text == Codec.encode(two.level).text, "repeat canonical is byte identical")
		check(one.level.content_hash == reordered.level.content_hash, "tree order and display names do not change formal hash")
		check(one.level.content_hash == Codec.compute_content_hash(one.level).content_hash, "formal Codec owns content identity")
		check(one.validation != null and one.validation.checks_performed > 0, "public Baker runs real Validator")
		check(one.level.cubes[0].center2 == Vector3i.ZERO and one.level.cubes[0].orientation == 0, "Reader supplies center and orientation")
		check(one.level.faces.size() == 12, "Reader produces exactly six faces per cube")
		check(one.level.goal.face_id == Geometry.face_id(&"floor", 4), "formal face references use Geometry")
		_source_cases(one.source_map)
	var invalid := real_payload(false, 0.125)
	var failed := Adapter.bake_authoring(invalid, F.options(), F.identity())
	check(not failed.ok and failed.level == null, "failure after success never returns historical level")
	check(failed.validation == null, "Reader failure stops before Baker")
	check(not failed.issues.is_empty() and failed.issues[0].code == 1100, "off lattice preserves original Reader issue code")
	if not failed.issues.is_empty():
		var found := Sources.locate(failed.source_map, failed.issues[0], "READER")
		check(found.ok and not found.value.is_empty() and found.value[0].authoring_id == F.uuid(10), "Reader empty entity IDs locate original cube")
		check(failed.issues[0].get("entity_ids", ["unexpected"]).is_empty(), "Reader early error entity IDs remain empty")
	var early_entries: Array = failed.source_map.get("entries", [])
	check(not early_entries.is_empty(), "Reader failure retains source map")
	check(early_entries.all(func(entry: Dictionary) -> bool: return entry.canonical_path == null), "early Reader failure never fabricates canonical path")
	check(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)) == orphan_count, "Reader failure releases temporary tree")
	_more_boundaries(payload, orphan_count)
	_rich_scene()
	check(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)) == orphan_count, "rich success and validation failure release all temporary nodes")
	check(added_nodes == 0, "all temporary trees remain detached")
	node_added.disconnect(_on_node_added)
	finish()

func _provenance_cases(payload: Dictionary) -> void:
	var identity := F.identity()
	var baked := Adapter.bake_authoring(payload, F.options(), identity)
	check(baked.ok and Schema.exact(baked, ["ok", "level", "issues", "validation", "source_map", "bake_provenance"]), "approved Bake wrapper has exactly six fields")
	var proof: Variant = baked.get("bake_provenance")
	check(Schema.exact(proof, ["run_id", "snapshot_id", "source_fingerprint"]), "BakeProvenance has exactly three fields")
	var expected := {"run_id": identity.run_id, "snapshot_id": identity.snapshot_id, "source_fingerprint": identity.source_fingerprint}
	check(proof == expected, "provenance copies validated input identity exactly")
	check(Schema.exact(baked.source_map, ["map_version", "snapshot_id", "source_fingerprint", "level_hash", "entries"]), "SourceMap shape stays unchanged without run_id")
	identity.run_id = "another-run"
	var another := Adapter.bake_authoring(payload, F.options(), identity)
	check(another.ok and baked.level == another.level, "run_id cannot change formal Level")
	check(Codec.encode(baked.level).text == Codec.encode(another.level).text and baked.level.content_hash == another.level.content_hash, "run_id cannot change canonical bytes or hash")
	check(proof == expected, "later input mutation cannot rewrite previous provenance")
	check(proof != another.get("bake_provenance") and another.get("bake_provenance", {}).get("run_id") == identity.run_id, "same snapshot and source distinguish different runs")
	var failures_to_test: Array[Dictionary] = []
	var invalid := payload.duplicate(true)
	invalid.authoring_version = "unknown"
	failures_to_test.append(Adapter.bake_authoring(invalid, F.options(), F.identity()))
	invalid = payload.duplicate(true)
	_record(invalid, "CUBE").fields.transform.origin.x = 0.125
	failures_to_test.append(Adapter.bake_authoring(invalid, F.options(), F.identity()))
	failures_to_test.append(Adapter.bake_authoring(payload, {"max_configurations": 1, "max_checks": 1}, F.identity()))
	failures_to_test.append(Adapter.bake_authoring(payload, {}, F.identity()))
	var bad_identity := F.identity()
	bad_identity.run_id = &"wrong-type"
	failures_to_test.append(Adapter.bake_authoring(payload, F.options(), bad_identity))
	for result in failures_to_test:
		check(not result.ok and result.level == null and result.has("bake_provenance") and result.bake_provenance == null, "every failure has explicit null provenance and no cached level")
		check(Schema.exact(result, ["ok", "level", "issues", "validation", "source_map", "bake_provenance"]), "failure wrapper remains exactly six fields")

func _source_cases(map: Dictionary) -> void:
	check(map.get("map_version") == "authoringsourcemap.v1" and map.get("level_hash") != null, "successful map binds formal hash")
	var found := Sources.locate(map, {"path": "cubes[0].center2", "entity_ids": []}, "CANONICAL")
	check(found.ok and not found.value.is_empty() and found.value[0].authoring_id == F.uuid(10), "canonical sorted cube index maps by identity")
	var analysis := Sources.locate(map, {"path": "analysis", "upstream": [{"path": "cubes[0].center2", "entity_ids": []}]}, "CANONICAL")
	check(analysis.ok and not analysis.value.is_empty(), "AnalysisIssue locates through actual upstream without entity_ids")
	var absent := Sources.locate(map, {"path": "cubes[999].center2", "entity_ids": []}, "CANONICAL")
	check(not absent.ok and absent.value.is_empty() and not absent.issues.is_empty(), "unlocatable issue is explicit and never picks nearby object")
	var unknown_phase := Sources.locate(map, {"path": "cubes[0]"}, "UNRECOGNIZED")
	check(not unknown_phase.ok and unknown_phase.value.is_empty(), "unknown diagnostic phase never interprets array positions")
	var wrong_phase := Sources.locate(map, {"path": "cubes[0].center2"}, "READER")
	check(not wrong_phase.ok, "canonical ordering must not masquerade as Reader order")
	var malformed := Sources.locate({"map_version": "authoringsourcemap.v1", "entries": [null]}, {}, "CANONICAL")
	check(not malformed.ok and not malformed.issues.is_empty(), "malformed source map fails with a diagnostic")
	var entities := Sources.locate(map, {"entity_ids": [&"floor", &"inner_floor"], "details": {}}, "VALIDATION")
	check(entities.ok and entities.value.any(func(e: Dictionary) -> bool: return e.authoring_id == F.uuid(10)) and entities.value.any(func(e: Dictionary) -> bool: return e.authoring_id == F.uuid(11)), "ValidationIssue can locate multiple exact entities")
	for code in [IntentTypes.QualityCode.MILESTONE_BYPASS, IntentTypes.QualityCode.MECHANIC_BYPASS]:
		var intent_subject := Sources.locate(map, {"code": code, "subject_ids": [&"floor"], "scope": &"SINGLE_TRACE", "trace": null, "details": {}}, "QUALITY")
		check(not intent_subject.ok and intent_subject.value.is_empty(), "unmapped Intent subject never selects same-spelling Cube")
	var unknown_subject := Sources.locate(map, {"subject_ids": [&"absent"], "path": "cubes[0]"}, "QUALITY")
	check(not unknown_subject.ok, "unknown explicit subject cannot fall back to unrelated path")
	var forged := map.duplicate(true)
	var duplicate: Dictionary = forged.entries.filter(func(e: Dictionary) -> bool: return e.canonical_path == "cubes[0].center2")[0].duplicate(true)
	duplicate.authoring_id = F.uuid(999)
	forged.entries.append(duplicate)
	var ambiguous := Sources.locate(forged, {"path": "cubes[0].center2"}, "CANONICAL")
	check(not ambiguous.ok and ambiguous.value.is_empty(), "ambiguous captured path never guesses an author object")

func _more_boundaries(payload: Dictionary, orphan_count: int) -> void:
	var root_scaled := payload.duplicate(true)
	root_scaled.documents[0].root_transform.basis = Basis.from_scale(Vector3(2, 1, 1))
	var root_result := Adapter.bake_authoring(root_scaled, F.options(), F.identity())
	check(not root_result.ok and root_result.level == null and root_result.issues[0].code == 1101, "original Level root transform reaches formal Reader")
	if not root_result.ok:
		var location := Sources.locate(root_result.source_map, root_result.issues[0], "READER")
		check(location.ok and location.value[0].authoring_id == F.uuid(1), "Reader root transform error locates actual Level declaration")
	var moved_root := payload.duplicate(true)
	moved_root.documents[0].root_transform.origin = Vector3(4, 8, 12)
	var placed := Adapter.bake_authoring(moved_root, F.options(), F.identity())
	check(placed.ok and placed.level.content_hash == Adapter.bake_authoring(payload, F.options(), F.identity()).level.content_hash, "rigid root placement cancels in formal root relative coordinates")
	var scaled := payload.duplicate(true)
	_record(scaled, "CUBE").fields.transform.basis = Basis.from_scale(Vector3(1.01, 1, 1))
	var rejected := Adapter.bake_authoring(scaled, F.options(), F.identity())
	check(not rejected.ok and rejected.level == null and rejected.issues[0].code == 1101, "Reader rejects raw non-cube basis without adapter repair")
	var near_grid := payload.duplicate(true)
	_record(near_grid, "CUBE").fields.transform.origin.x = 0.0000001
	var tolerated := Adapter.bake_authoring(near_grid, F.options(), F.identity())
	check(tolerated.ok, "formal Reader owns acceptance inside its lattice tolerance")
	var outside := payload.duplicate(true)
	_record(outside, "CUBE").fields.transform.origin.x = 0.000002
	rejected = Adapter.bake_authoring(outside, F.options(), F.identity())
	check(not rejected.ok and rejected.issues[0].code == 1100, "raw transform outside Reader tolerance is not pre-rounded")
	var direct_root := Node3D.new()
	direct_root.set_meta("foundation_authoring", {"cubes": [], "faces": [], "celestial": {"slots": []}})
	var direct_cubes := Node3D.new()
	direct_cubes.name = "Cubes"
	direct_root.add_child(direct_cubes)
	var direct_slots := Node3D.new()
	direct_slots.name = "Slots"
	direct_root.add_child(direct_slots)
	var direct_cube := Node3D.new()
	direct_cube.name = "n_" + F.uuid(10).replace("-", "_")
	direct_cube.transform = _record(outside, "CUBE").fields.transform
	direct_cube.set_meta("foundation_cube", {"cube_id": &"floor", "layer": 0, "group_id": &"", "occludes_light": true, "tags": []})
	direct_cubes.add_child(direct_cube)
	var original := Reader.read_scene(direct_root)
	direct_root.free()
	check(rejected.issues == original.issues, "all six original Reader issue fields remain unchanged")
	var slot := payload.duplicate(true)
	_record(slot, "SLOT").fields.transform.origin.x = 0.125
	rejected = Adapter.bake_authoring(slot, F.options(), F.identity())
	check(not rejected.ok and rejected.level == null and rejected.issues[0].code == 1100, "slot raw off-lattice rejected by Reader")
	var invalid_schema := payload.duplicate(true)
	invalid_schema.authoring_version = "unknown"
	rejected = Adapter.bake_authoring(invalid_schema, F.options(), F.identity())
	check(not rejected.ok and rejected.level == null and rejected.validation == null, "schema failure does not allocate or retain a level")
	var invalid_identity := F.identity()
	invalid_identity.source_fingerprint = "bad"
	rejected = Adapter.bake_authoring(payload, F.options(), invalid_identity)
	check(not rejected.ok and rejected.level == null, "invalid snapshot provenance is rejected")
	rejected = Adapter.bake_authoring(payload, {"max_checks": 0, "max_configurations": 4096}, F.identity())
	check(not rejected.ok and rejected.level == null and rejected.issues[0].path == "options", "Baker option error preserved")
	var exhausted := Adapter.bake_authoring(payload, {"max_checks": 1, "max_configurations": 4096}, F.identity())
	check(not exhausted.ok and exhausted.level == null and exhausted.validation != null and exhausted.validation.status == 2, "real Validator incomplete is never successful Bake")
	check(exhausted.source_map.level_hash == null and exhausted.source_map.entries.all(func(e: Dictionary) -> bool: return e.canonical_path == null), "failed Baker publishes neither success hash nor canonical paths")
	check(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)) == orphan_count, "schema identity Reader Baker and budget failures all release nodes")

func _record(payload: Dictionary, kind: String) -> Dictionary:
	for doc in payload.documents:
		for record in doc.records:
			if record.kind == kind:
				return record
	return {}

func _rich_scene() -> void:
	var payload := real_payload(false, 0.0, true)
	var baked := Adapter.bake_authoring(payload, F.options(), F.identity())
	var file := FileAccess.open(evidence_dir().path_join("rich-bake.txt"), FileAccess.WRITE)
	file.store_string(var_to_str(baked))
	file.close()
	check(baked.ok, "real author group transition and all three mechanism config kinds bake")
	if not baked.ok:
		return
	var level: Dictionary = baked.level
	check(level.groups[0].cube_ids == [&"inner_floor"] and level.cubes[1].group_id == &"island" and level.cubes[0].group_id == &"", "group membership is sole cube group_id source")
	var top: Dictionary = level.faces.filter(func(f: Dictionary) -> bool: return f.face_id == Geometry.face_id(&"floor", 4))[0]
	check(top.mechanism_ids == [&"rotate", &"sun", &"tip"], "host_face alone generates reverse mechanism index")
	check(level.face_transitions[0].source_face_id == Geometry.face_id(&"floor", 4) and level.face_transitions[0].target_face_id == Geometry.face_id(&"floor", 0), "transition face refs resolve through Geometry")
	check(level.mechanisms[0].action == {"kind": 6, "group_id": &"island", "rotation_delta": 22, "mechanism_id": &"rotate"}, "group mechanism config and instance binding preserved")
	check(level.mechanisms[1].action == {"kind": 7, "celestial_op": 0, "target_slot_id": &"sun", "alternate_slot_id": &"", "mechanism_id": &"sun"}, "celestial mechanism config preserved")
	check(level.mechanisms[2].action == {"kind": 4, "transition_id": &"tip"}, "transition action has no extra mechanism_id")
	var collision := Sources.locate(baked.source_map, {"entity_ids": [&"sun"]}, "CANONICAL")
	check(not collision.ok and collision.value.is_empty(), "same spelling slot and mechanism ID is ambiguous without kind path")
	var located := Sources.locate(baked.source_map, {"entity_ids": [&"sun"], "path": "celestial.slots[0].position2"}, "CANONICAL")
	check(located.ok and located.value.all(func(e: Dictionary) -> bool: return e.entity_kind == "SLOT"), "typed source namespace disambiguates by exact canonical path")
	var unused := Sources.locate(baked.source_map, {"code": IntentTypes.QualityCode.UNUSED_MECHANISM, "severity": 1, "subject_ids": [&"sun"], "scope": &"RETURNED_SHORTEST_TRACE", "trace": null, "details": {"mechanism_id": &"sun"}}, "QUALITY")
	check(unused.ok and unused.value.all(func(e: Dictionary) -> bool: return e.entity_kind == "MECHANISM"), "formal unused mechanism finding uses typed identity despite same-spelling slot")
	var reordered := Adapter.bake_authoring(real_payload(true, 0.0, true), F.options(), F.identity())
	check(reordered.ok and Codec.encode(level).text == Codec.encode(reordered.level).text, "nontrivial author tree reorder leaves complete canonical unchanged")
	var reordered_path := Sources.locate(reordered.source_map, {"path": "mechanisms[0].action.rotation_delta"}, "CANONICAL")
	check(reordered_path.ok and reordered_path.value[0].authoring_id == F.uuid(61), "canonical mechanism sorting joins config by ID not source array index")
	var invalid := payload.duplicate(true)
	_record(invalid, "TRANSITION").fields.rotation_steps = [3]
	var rejected := Adapter.bake_authoring(invalid, F.options(), F.identity())
	check(not rejected.ok and rejected.level == null and rejected.validation != null, "real Baker rejects invalid transport semantics without second Validator")
	check(rejected.issues == rejected.validation.issues, "Baker issues retain original fields and codes")

func _node(kind: String, n: int, fields: Dictionary, parent: Node) -> Node3D:
	var node: Node3D = load(Schema.script_path(kind)).new()
	node.name = kind + str(n)
	node.set("authoring_id", F.uuid(n))
	for key in fields:
		node.set(key, fields[key])
	parent.add_child(node)
	node.owner = parent
	return node

func _rich_nodes(author: Node3D, layer: int) -> void:
	if layer == 1:
		_node("GROUP", 50, {"group_id": &"island", "cube_ids": [&"inner_floor"], "pivot2": Vector3i.ZERO, "initial_orientation": 0, "allowed_states": [0, 22], "allowed_rotation_deltas": [22, 18], "edges": [{"from_orientation": 0, "rotation_delta": 22, "to_orientation": 22}, {"from_orientation": 22, "rotation_delta": 18, "to_orientation": 0}]}, author)
		return
	var faces: Array = author.get_node("Cube").get("faces").duplicate()
	faces[0] = faces[0].duplicate(true)
	faces[0].set("walkable", true)
	author.get_node("Cube").set("faces", faces)
	_node("TRANSITION", 51, {"transition_id": &"tip", "source": {"cube_id": &"floor", "face": 4}, "target": {"cube_id": &"floor", "face": 0}, "entry_axis": 0, "exit_axis": 0, "rotation_steps": [2], "required_flags": []}, author)
	for i in range(3):
		var config: Resource = load(Schema.script_path("MECHANISM_CONFIG")).new()
		config.set("authoring_id", F.uuid(60 + i))
		config.set("kind", [7, 6, 4][i])
		config.set("initial_state", &"ready")
		config.set("allowed_states", [&"ready"])
		if i == 0:
			config.set("celestial_op", 0)
		elif i == 1:
			config.set("rotation_delta", 22)
		_node("MECHANISM", 70 + i, {"mechanism_id": [&"sun", &"rotate", &"tip"][i], "host_face": {"cube_id": &"floor", "face": 4}, "trigger": &"USE", "priority": i, "config": config, "target_bindings": [{"target_slot_id": &"sun", "alternate_slot_id": &""}, {"group_id": &"island"}, {"transition_id": &"tip"}][i]}, author)

func _on_node_added(_node: Node) -> void:
	added_nodes += 1

func context(file: String, n: int) -> Dictionary:
	var digests := {}
	for kind in Schema.SCRIPTS:
		var path: String = Schema.script_path(kind)
		digests[path] = FileAccess.get_sha256(path)
	return {"document_uri": F.BASE + file, "document_authoring_id": F.uuid(n), "origin": "SAVED", "allowed_script_digests": digests, "instance_role": null}

func real_payload(reorder: bool = false, position_x: float = 0.0, rich: bool = false) -> Dictionary:
	var docs: Array[Dictionary] = []
	for index in range(3):
		var file: String = ["level.tscn", "surface.tscn", "inner.tscn"][index]
		var scene := load(F.BASE + file) as PackedScene
		var author := scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE) as Node3D
		if rich and index > 0:
			_rich_nodes(author, index - 1)
		if index == 1:
			author.get_node("Cube").position.x = position_x
			if reorder:
				author.move_child(author.get_node("Sun"), 0)
				author.get_node("Cube").name = "RenamedCube"
				if rich:
					author.move_child(author.get_node("MECHANISM71"), 0)
		var projected := Projector.project_document(author, context(file, index + 1))
		check(projected.ok, file + " projects real author nodes")
		if projected.ok:
			docs.append(projected.value)
		author.free()
	var intent := Projector.project_document(load(F.BASE + "intent.tres"), context("intent.tres", 4))
	check(intent.ok, "real Intent resource projects")
	if intent.ok:
		docs.append(intent.value)
	var result := Assembler.assemble_payload(docs, F.payload("minimal").level_ref)
	check(result.ok, "real document closure assembles")
	return result.value if result.ok else {}
