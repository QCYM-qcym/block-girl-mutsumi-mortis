extends RefCounted
const BASE := "res://tests/foundation/authoring/fixtures/minimal/"

static func uuid(n: int) -> String:
	return "00000000-0000-4000-8000-%012d" % n

static func identity() -> Dictionary:
	return {"run_id": "test-run", "snapshot_id": "test-snapshot", "source_fingerprint": "1".repeat(64), "source_intent_digest": "2".repeat(64)}

static func options() -> Dictionary:
	return {"max_configurations": 4096, "max_checks": 100000}

static func record(kind: String, n: int, fields: Dictionary, path: String = ".") -> Dictionary:
	return {"kind": kind, "authoring_id": uuid(n), "node_path": path, "label": kind, "fields": fields}

static func document(kind: String, file: String, n: int) -> Dictionary:
	return {"authoring_version": "levelauthoring.v1", "document_uri": BASE + file, "document_authoring_id": uuid(n), "kind": kind, "root_transform": Transform3D.IDENTITY, "records": [], "resources": [], "dependencies": [], "override_paths": []}

static func resource(kind: String, file: String, n: int, fields: Dictionary) -> Dictionary:
	return {"authoring_id": uuid(n), "kind": kind, "document_uri": BASE + file, "resource_uid": null, "fields": fields}

static func documents(case_name: String) -> Array[Dictionary]:
	var level := document("LEVEL", "level.tscn", 1)
	level.dependencies = [BASE + "surface.tscn", BASE + "inner.tscn", BASE + "intent.tres"]
	level.records = [record("LEVEL", 1, {
		"authoring_version": "levelauthoring.v1", "level_id": &"authoring_minimal", "schema_version": 1,
		"contract_version": "foundation.contract.v1", "orientation_version": "cube24.v1", "rule_version": "foundation.rules.v1",
		"cell_size": 1, "shift_compatibilities": [0, 1], "flag_definitions": [], "build_info": {},
		"surface_source": BASE + "surface.tscn", "inner_source": BASE + "inner.tscn", "intent": {"resource_ref": uuid(4)},
		"spawn": {"face_ref": {"cube_id": &"floor", "face": 4}, "orientation": 0},
		"goal": {"face_ref": {"cube_id": &"floor", "face": 4}, "required_flags": []},
		"celestial": {"slot_order": [&"sun"], "wrap": false, "initial_slot_id": &"sun", "edges": []}
	})]
	var docs: Array[Dictionary] = [level]
	for layer in [0, 1]:
		var file := "surface.tscn" if layer == 0 else "inner.tscn"
		var world := document("WORLD", file, 2 + layer)
		world.records = [record("WORLD", 2 + layer, {"layer": layer, "pivot2": Vector3i.ZERO, "initial_orientation": 0, "allowed_states": [0], "allowed_rotation_deltas": [], "allowed_rotation_intents": []})]
		var faces: Array = []
		for face in range(6):
			var n: int = 100 + layer * 10 + face
			faces.append({"resource_ref": uuid(n)})
			world.resources.append(resource("FACE", file, n, {"face": face, "walkable": face == 4, "shift_exit_blocked": false, "shift_entry_blocked": false}))
		world.records.append(record("CUBE", 10 + layer, {"cube_id": &"floor" if layer == 0 else &"inner_floor", "occludes_light": true, "tags": [], "transform": Transform3D.IDENTITY, "faces": faces}, "Cube"))
		if layer == 0:
			world.records.append(record("SLOT", 20, {"slot_id": &"sun", "transform": Transform3D(Basis.IDENTITY, Vector3(0, 5, 0))}, "Sun"))
		docs.append(world)
	var intent := document("INTENT", "intent.tres", 4)
	intent.resources = [resource("INTENT", "intent.tres", 4, {"authoring_version": "puzzleintentauthoring.v1", "intent_id": &"empty_intent", "required_mechanics": [], "optional_mechanics": [], "expected_milestones": [], "forbidden_bypasses": []})]
	docs.append(intent)
	match case_name:
		"missing_face": docs[1].records[1].fields.faces.pop_back()
		"duplicate_face": docs[1].resources[5].fields.face = 0
		"duplicate_id": docs[2].records[1].fields.cube_id = &"floor"
		"shared_alias": docs[2].records[1].fields.faces = docs[1].records[1].fields.faces.duplicate(true)
		"resource_conflict":
			var conflicting: Dictionary = docs[1].resources[0].duplicate(true)
			conflicting.fields.walkable = true
			docs[2].resources.append(conflicting)
		"off_lattice": docs[1].records[1].fields.transform.origin.x = 0.125
		"unsupported_override": docs[0].override_paths = ["Surface/Cube.faces"]
	return docs

static func payload(case_name: String) -> Dictionary:
	var docs := documents(case_name)
	var resources: Array = []
	for doc in docs:
		resources.append_array(doc.resources)
	return {"authoring_version": "levelauthoring.v1", "level_ref": {"level_authoring_id": uuid(1), "level_id": &"authoring_minimal", "root_source_uri": BASE + "level.tscn"}, "documents": docs, "resource_table": resources}
