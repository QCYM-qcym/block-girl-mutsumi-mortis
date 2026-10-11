extends RefCounted
## One adaptation to the existing Reader profile. No spatial or validation rules.
const Schema = preload("res://foundation/authoring/authoring_schema.gd")
const Sources = preload("res://foundation/authoring/source_map.gd")
const Reader = preload("res://foundation/level/authoring_reader.gd")
const Baker = preload("res://foundation/level/level_baker.gd")
const Geometry = preload("res://foundation/spatial/surface_geometry.gd")
const Records = preload("res://foundation/contracts/contract_records.gd")
const Feel = preload("res://foundation/game_feel/schema.gd")
const Types = preload("res://foundation/contracts/foundation_types.gd")

static func bake_authoring(payload: Dictionary, bake_options: Dictionary, snapshot_identity: Dictionary) -> Dictionary:
	var map := {"map_version": "authoringsourcemap.v1", "snapshot_id": snapshot_identity.get("snapshot_id", ""), "source_fingerprint": snapshot_identity.get("source_fingerprint", ""), "level_hash": null, "entries": []}
	var checked := Schema.validate_authoring(payload)
	if not checked.ok:
		return _failure(checked.issues, map)
	if not Schema.exact(snapshot_identity, ["run_id", "snapshot_id", "source_fingerprint", "source_intent_digest"]) or not snapshot_identity.run_id is String or snapshot_identity.run_id.is_empty() or not snapshot_identity.snapshot_id is String or snapshot_identity.snapshot_id.is_empty() or not _digest(snapshot_identity.source_fingerprint) or (snapshot_identity.source_intent_digest != null and not _digest(snapshot_identity.source_intent_digest)):
		return _failure([Schema.issue("SNAPSHOT_IDENTITY_INVALID", "snapshot_identity", "Expected explicit snapshot provenance.")], map)
	# Approved tool-only provenance: independent values from this validated call.
	# Never enter SourceMap, formal Level, or the content identity calculation.
	var provenance := {"run_id": snapshot_identity.run_id, "snapshot_id": snapshot_identity.snapshot_id, "source_fingerprint": snapshot_identity.source_fingerprint}
	var resources := {}
	var cube_layers := {}
	var membership := {}
	var hosts := {}
	var level_fields := {}
	var root_transform := Transform3D.IDENTITY
	for resource in payload.resource_table:
		resources[resource.authoring_id] = resource
	for doc in payload.documents:
		var layer := -1
		for record in doc.records:
			if record.kind == "WORLD":
				layer = record.fields.layer
		for record in doc.records:
			var f: Dictionary = record.fields
			match record.kind:
				"LEVEL":
					level_fields = f
					root_transform = doc.root_transform
				"CUBE": cube_layers[f.cube_id] = layer
				"GROUP":
					for id in f.cube_ids:
						membership[id] = f.group_id
				"MECHANISM":
					var id: StringName = Geometry.face_id(f.host_face.cube_id, f.host_face.face)
					if not hosts.has(id):
						hosts[id] = []
					hosts[id].append(f.mechanism_id)
	var template := {}
	for key in ["schema_version", "contract_version", "orientation_version", "rule_version", "level_id", "cell_size", "shift_compatibilities", "flag_definitions", "build_info"]:
		template[key] = level_fields[key]
	if Feel.spatial(level_fields):
		for key in ["camera_initial_quadrant","perspective_falls","shift_gates"]:
			template[key] = level_fields[key].duplicate(true) if level_fields[key] is Array else level_fields[key]
		template["face_locks"] = []
	for key in ["worlds", "cubes", "faces", "groups", "mechanisms", "face_transitions"]:
		template[key] = []
	template["celestial"] = level_fields.celestial.duplicate(true)
	template.celestial["slots"] = []
	var spawn: Dictionary = level_fields.spawn
	template["spawn"] = Records.make_player_state(Records.make_player_location(cube_layers[spawn.face_ref.cube_id], spawn.face_ref.cube_id, spawn.face_ref.face), spawn.orientation)
	template["goal"] = {"face_id": Geometry.face_id(level_fields.goal.face_ref.cube_id, level_fields.goal.face_ref.face), "required_flags": level_fields.goal.required_flags.duplicate()}
	# All input checks precede allocation. From here there is exactly one free/exit.
	var root := Node3D.new()
	root.transform = root_transform
	var cubes := Node3D.new()
	cubes.name = "Cubes"
	root.add_child(cubes)
	var slots := Node3D.new()
	slots.name = "Slots"
	root.add_child(slots)
	for doc in payload.documents:
		var layer := -1
		for record in doc.records:
			if record.kind == "WORLD":
				layer = record.fields.layer
		for record in doc.records:
			var f: Dictionary = record.fields
			match record.kind:
				"LEVEL":
					Sources.capture(map, doc, record, "LEVEL", f.level_id, "")
				"WORLD":
					Sources.capture(map, doc, record, "WORLD", null, "worlds[%d]" % template.worlds.size())
					template.worlds.append(f.duplicate(true))
				"GROUP":
					Sources.capture(map, doc, record, "GROUP", f.group_id, "groups[%d]" % template.groups.size())
					var group := f.duplicate(true)
					group["layer"] = layer
					template.groups.append(group)
				"TRANSITION":
					Sources.capture(map, doc, record, "TRANSITION", f.transition_id, "face_transitions[%d]" % template.face_transitions.size())
					template.face_transitions.append({"transition_id": f.transition_id, "source_face_id": Geometry.face_id(f.source.cube_id, f.source.face), "target_face_id": Geometry.face_id(f.target.cube_id, f.target.face), "entry_axis": f.entry_axis, "exit_axis": f.exit_axis, "rotation_steps": f.rotation_steps.duplicate(), "required_flags": f.required_flags.duplicate()})
				"MECHANISM":
					var config: Dictionary = resources[f.config.resource_ref]
					var path := "mechanisms[%d]" % template.mechanisms.size()
					var lock_path := ""
					if config.fields.kind == Types.PuzzleActionKind.TRIGGER_MECHANISM:
						lock_path = "face_locks[%d]" % template.face_locks.size()
						template.face_locks.append({"mechanism_id":f.mechanism_id,"required_local_face":config.fields.required_local_face,"activation_mode":config.fields.activation_mode,"latched_state":config.fields.latched_state})
					Sources.capture(map, doc, record, "MECHANISM", f.mechanism_id, path, lock_path)
					Sources.capture_resource(map, config, record, "MECHANISM", f.mechanism_id, path, null, lock_path)
					var action: Dictionary = f.target_bindings.duplicate(true)
					action["kind"] = config.fields.kind
					if config.fields.kind == Types.PuzzleActionKind.LOCAL_GROUP_ROTATE:
						action["rotation_delta"] = config.fields.rotation_delta
					if config.fields.kind == Types.PuzzleActionKind.MOVE_CELESTIAL:
						action["celestial_op"] = config.fields.celestial_op
					if config.fields.kind != Types.PuzzleActionKind.USE_FACE_TRANSITION:
						action["mechanism_id"] = f.mechanism_id
					template.mechanisms.append({"mechanism_id": f.mechanism_id, "face_id": Geometry.face_id(f.host_face.cube_id, f.host_face.face), "trigger": f.trigger, "action": action, "priority": f.priority, "initial_state": config.fields.initial_state, "allowed_states": config.fields.allowed_states.duplicate()})
				"CUBE":
					var node := Node3D.new()
					node.name = "n_" + record.authoring_id.replace("-", "_")
					node.transform = f.transform
					var metadata := {"cube_id": f.cube_id, "layer": layer, "group_id": membership.get(f.cube_id, &""), "occludes_light": f.occludes_light, "tags": f.tags.duplicate()}
					node.set_meta("foundation_cube", metadata)
					var path := "Cubes/" + String(node.name)
					Sources.capture(map, doc, record, "CUBE", f.cube_id, path)
					var faces: Array = []
					for ref in f.faces:
						var resource: Dictionary = resources[ref.resource_ref]
						var attributes: Dictionary = resource.fields.duplicate(true)
						var face_id: StringName = Geometry.face_id(f.cube_id, attributes.face)
						attributes["mechanism_ids"] = hosts.get(face_id, []).duplicate()
						Sources.capture_resource(map, resource, record, "FACE", face_id, path + ".foundation_faces[%d]" % faces.size(), attributes.face)
						faces.append(attributes)
					node.set_meta("foundation_faces", faces)
					cubes.add_child(node)
				"SLOT":
					var node := Node3D.new()
					node.name = "n_" + record.authoring_id.replace("-", "_")
					node.transform = f.transform
					node.set_meta("slot_id", f.slot_id)
					Sources.capture(map, doc, record, "SLOT", f.slot_id, "Slots/" + String(node.name))
					slots.add_child(node)
	root.set_meta("foundation_authoring", template)
	var read := Reader.read_scene(root)
	root.free()
	if not read.ok:
		return _failure(read.issues, map)
	var baked := Baker.bake(read.authoring, bake_options)
	if baked.ok:
		Sources.complete(map, baked.level, payload)
	return {"ok": baked.ok, "level": baked.level, "issues": baked.issues, "validation": baked.validation, "source_map": map, "bake_provenance": provenance if baked.ok else null}

static func _digest(value: Variant) -> bool:
	if not value is String or value.length() != 64:
		return false
	for c in value:
		if c not in "0123456789abcdef":
			return false
	return true

static func _failure(issues: Array, map: Dictionary) -> Dictionary:
	return {"ok": false, "level": null, "issues": issues, "validation": null, "source_map": map, "bake_provenance": null}
