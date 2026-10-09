extends "res://tests/foundation/authoring_integration/test_suite.gd"
const Edits = preload("res://foundation/authoring/edit_operations.gd")
const IDs = preload("res://foundation/authoring/id_registry.gd")
const Schema = preload("res://foundation/authoring/authoring_schema.gd")
const Projector = preload("res://foundation/authoring/document_projector.gd")
const F = preload("res://tests/foundation/authoring/authoring_fixtures.gd")

func run() -> void:
	var allocated := IDs.allocate("MECHANISM", [&"mechanism_1", &"mechanism_2"])
	check(allocated.ok, "registry allocates declared entity kind")
	if allocated.ok:
		check(Schema.valid_uuid(allocated.value.authoring_id), "new author UUID is valid")
		check(Schema.valid_id(allocated.value.entity_id) and allocated.value.entity_id not in [&"mechanism_1", &"mechanism_2"], "new formal ID avoids occupied IDs")
	check(not IDs.allocate("UNKNOWN", []).ok, "unknown entity kind rejected")
	check(not IDs.allocate("CUBE", [&"bad-id"]).ok, "invalid occupied ID rejected rather than normalized")
	var repeated := IDs.allocate("MECHANISM", [&"mechanism_1", &"mechanism_2"])
	check(repeated.ok and repeated.value.authoring_id != allocated.value.authoring_id, "separate allocations have fresh author identities")
	_copy_delete()
	_resources()
	finish()

func _copy_delete() -> void:
	var world := (load(F.BASE + "surface.tscn") as PackedScene).instantiate() as Node3D
	var config := resource("MECHANISM_CONFIG", 30, {"kind": 7, "initial_state": &"ready", "allowed_states": [&"ready"], "celestial_op": 0})
	var mechanism: Node3D = load(Schema.script_path("MECHANISM")).new()
	mechanism.name = "Switch"
	mechanism.set("authoring_id", F.uuid(31))
	for key in {"mechanism_id": &"switch", "host_face": {"cube_id": &"floor", "face": 4}, "trigger": &"USE", "priority": 0, "config": config, "target_bindings": {"target_slot_id": &"sun", "alternate_slot_id": &""}}:
		var fields := {"mechanism_id": &"switch", "host_face": {"cube_id": &"floor", "face": 4}, "trigger": &"USE", "priority": 0, "config": config, "target_bindings": {"target_slot_id": &"sun", "alternate_slot_id": &""}}
		mechanism.set(key, fields[key])
	world.add_child(mechanism)
	mechanism.owner = world
	var ctx := context(world)
	var original: Dictionary = mechanism.declared_fields().duplicate(true)
	var prepared := Edits.prepare_edit("COPY", ref(mechanism), ctx)
	check(prepared.ok, "mechanism COPY prepares real node")
	check(mechanism.declared_fields() == original and world.get_child_count() == 3, "COPY preflight leaves source unchanged")
	if prepared.ok:
		var proposal: Dictionary = prepared.value
		check(no_callable(proposal), "COPY proposal contains no executable Callable")
		var clone: Node = proposal.created_objects[0]
		check(clone.get("authoring_id") != mechanism.get("authoring_id") and clone.get("mechanism_id") != &"switch", "COPY assigns new author and formal self identity")
		check(clone.get("target_bindings") == mechanism.get("target_bindings") and clone.get("host_face") == mechanism.get("host_face"), "COPY retains all external slot and face bindings")
		var changed: Dictionary = clone.get("target_bindings")
		changed.target_slot_id = &"another"
		check(mechanism.get("target_bindings").target_slot_id == &"sun", "COPY mutable binding dictionaries never alias the source")
		changed.target_slot_id = &"sun"
		check(clone.get_parent() == null and proposal.hierarchy_changes.size() == 1, "COPY only describes hierarchy change")
		var uuid: String = clone.get("authoring_id")
		var id: StringName = clone.get("mechanism_id")
		# Test consumer applies/reverts the proposal; no Editor transaction double.
		world.add_child(clone)
		world.remove_child(clone)
		world.add_child(clone)
		check(clone.get("authoring_id") == uuid and clone.get("mechanism_id") == id, "redo reuses preallocated object and IDs")
		world.remove_child(clone)
		Edits.discard_proposal(proposal)
		check(not is_instance_valid(clone) and is_instance_valid(mechanism), "discard frees unadopted node without touching source")
		Edits.discard_proposal(proposal)
	var cube := world.get_node("Cube")
	prepared = Edits.prepare_edit("DELETE", ref(cube), ctx)
	check(prepared.ok, "DELETE prepares references without deleting source")
	if prepared.ok:
		var proposal: Dictionary = prepared.value
		check(proposal.requires_confirmation and proposal.created_objects.is_empty(), "DELETE defaults to confirmation and creates nothing")
		check(proposal.reference_impacts.size() >= 3, "DELETE enumerates spawn goal and mechanism host references")
		check(is_instance_valid(cube) and cube.get_parent() == world, "DELETE preflight retains original object")
		var change: Dictionary = proposal.hierarchy_changes[0]
		var id: String = cube.get("authoring_id")
		cube.owner = null
		world.remove_child(cube)
		check(mechanism.get("host_face").cube_id == &"floor", "confirmed delete leaves diagnostic dangling references")
		world.add_child(change.node)
		world.move_child(change.node, change.index)
		change.node.owner = change.owner
		check(cube.get("authoring_id") == id and cube.get("cube_id") == &"floor" and cube.get_parent() == world, "undo restores original object identity and hierarchy")
		Edits.discard_proposal(proposal)
		check(is_instance_valid(cube), "discard DELETE cannot free original object")
	var unresolved := ctx.duplicate()
	unresolved.documents = ctx.documents.duplicate(true)
	unresolved.documents[0].dependencies.append("res://missing_author_document.tscn")
	prepared = Edits.prepare_edit("DELETE", ref(cube), unresolved)
	check(prepared.ok and prepared.value.reference_impacts.any(func(impact: Dictionary) -> bool: return impact.status == "UNRESOLVED_DEPENDENCY"), "DELETE explicitly reports unresolved declaration dependency")
	if prepared.ok:
		Edits.discard_proposal(prepared.value)
	var group: Node3D = load(Schema.script_path("GROUP")).new()
	group.name = "Group"
	group.set("authoring_id", F.uuid(50))
	var group_fields := {"group_id": &"island", "cube_ids": [&"floor"], "pivot2": Vector3i.ZERO, "initial_orientation": 0, "allowed_states": [0], "allowed_rotation_deltas": [], "edges": []}
	for key in group_fields:
		group.set(key, group_fields[key])
	world.add_child(group)
	group.owner = world
	var group_context := context(world)
	var orphans := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	prepared = Edits.prepare_edit("COPY", ref(group), group_context)
	check(not prepared.ok and prepared.value == null and not prepared.issues.is_empty(), "retained group members make COPY candidate illegal and diagnostic")
	check(group.get("cube_ids") == [&"floor"] and group.get("group_id") == &"island", "illegal group COPY never remaps targets or original identity")
	check(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)) == orphans, "post-allocation COPY rejection releases the detached candidate")
	group.owner = null
	world.remove_child(group)
	group.free()
	var another := (load(F.BASE + "inner.tscn") as PackedScene).instantiate()
	prepared = Edits.prepare_edit("COPY", {"object": another.get_node("Cube"), "authoring_id": F.uuid(11), "document_uri": F.BASE + "surface.tscn"}, ctx)
	check(not prepared.ok and prepared.value == null, "cross-document source object rejected")
	another.free()
	ctx.existing_ids = {"MECHANISM": [&"mechanism_1", &"mechanism_2"]}
	prepared = Edits.prepare_edit("COPY", ref(mechanism), ctx)
	check(prepared.ok and prepared.value.created_objects[0].get("mechanism_id") not in [&"switch", &"mechanism_1", &"mechanism_2"], "COPY honors external reserved self IDs without overwriting")
	if prepared.ok:
		Edits.discard_proposal(prepared.value)
	prepared = Edits.prepare_edit("COPY", ref(cube), ctx)
	check(prepared.ok, "Cube COPY includes independent six face resources")
	if prepared.ok:
		var clone: Node = prepared.value.created_objects[0]
		var independent := true
		for i in range(6):
			independent = independent and clone.get("faces")[i] != cube.get("faces")[i] and clone.get("faces")[i].get("authoring_id") != cube.get("faces")[i].get("authoring_id")
		check(independent, "six mutable face resources are never shared with copied Cube")
		Edits.discard_proposal(prepared.value)
	mechanism.set("target_bindings", {"target_slot_id": &"missing", "alternate_slot_id": &""})
	prepared = Edits.prepare_edit("COPY", ref(mechanism), ctx)
	check(not prepared.ok and prepared.value == null and not prepared.issues.is_empty(), "invalid retained target is diagnostic without silent remap")
	check(mechanism.get("target_bindings").target_slot_id == &"missing", "invalid source is never repaired")
	world.free()

func _resources() -> void:
	var root := Node3D.new()
	root.set_script(load(Schema.script_path("LEVEL")))
	root.set("authoring_id", F.uuid(1))
	var milestone := resource("MILESTONE", 42, {"milestone_id": &"visit", "required": true, "predicate": {"kind": 0, "face_ref": {"cube_id": &"floor", "face": 4}}})
	var intent := resource("INTENT", 40, {"authoring_version": "puzzleintentauthoring.v1", "intent_id": &"intent", "required_mechanics": [], "optional_mechanics": [], "expected_milestones": [milestone, milestone], "forbidden_bypasses": []})
	root.set("intent", intent)
	var ctx := {"document_root": root, "documents": F.documents("minimal"), "existing_ids": {}}
	var prepared := Edits.prepare_edit("MAKE_UNIQUE", {"object": intent, "authoring_id": F.uuid(40), "document_uri": F.BASE + "level.tscn"}, ctx)
	check(prepared.ok, "MAKE_UNIQUE accepts real whitelisted semantic resource graph")
	if prepared.ok:
		var proposal: Dictionary = prepared.value
		var copy: Resource = proposal.created_objects[0]
		check(copy != intent and copy.get("authoring_id") != intent.get("authoring_id"), "outer Resource is independently identified")
		check(copy.get("expected_milestones")[0] == copy.get("expected_milestones")[1], "internal nested alias is preserved")
		check(copy.get("expected_milestones")[0] != milestone, "nested mutable graph disconnected from original")
		check(copy.get("expected_milestones")[0].get("predicate") == milestone.get("predicate"), "external AT_FACE target retained")
		check(proposal.retained_targets == [&"floor"], "MAKE_UNIQUE enumerates retained nested AT_FACE target")
		var accurate_ids := true
		for i in range(proposal.created_objects.size()):
			var made: Resource = proposal.created_objects[i]
			var kind: String = Schema.kind_of(made.get_script())
			accurate_ids = accurate_ids and proposal.assigned_ids[i].authoring_id == made.get("authoring_id")
			if IDs.NAMED.has(kind):
				accurate_ids = accurate_ids and proposal.assigned_ids[i].entity_id == made.get(IDs.NAMED[kind])
		check(accurate_ids, "MAKE_UNIQUE assigned IDs describe actual copied identities")
		check(no_callable(proposal), "MAKE_UNIQUE proposal contains no Callable")
		check(root.get("intent") == intent and proposal.before[0].value == intent and proposal.after[0].value == copy, "MAKE_UNIQUE describes replacement without applying it")
		var weak: WeakRef = weakref(copy)
		copy = null
		Edits.discard_proposal(proposal)
		check(weak.get_ref() == null and root.get("intent") == intent, "discard drops all references to new Resource graph only")
	var unknown := Resource.new()
	intent.set("expected_milestones", [unknown])
	var resource_count := int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))
	prepared = Edits.prepare_edit("MAKE_UNIQUE", {"object": intent, "authoring_id": F.uuid(40), "document_uri": F.BASE + "level.tscn"}, ctx)
	check(not prepared.ok and prepared.value == null, "unknown nested Resource rejected atomically")
	check(int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)) == resource_count, "unknown Resource failure leaves no staged resources")
	var wrong_kind := resource("FACE", 90, {"face": 0, "walkable": true, "shift_exit_blocked": false, "shift_entry_blocked": false})
	for bad in [123, wrong_kind]:
		intent.set("expected_milestones", [bad])
		prepared = Edits.prepare_edit("MAKE_UNIQUE", {"object": intent, "authoring_id": F.uuid(40), "document_uri": F.BASE + "level.tscn"}, ctx)
		check(not prepared.ok and prepared.value == null, "Intent milestone edges reject non-Milestone values atomically")
		if prepared.ok:
			Edits.discard_proposal(prepared.value)
	resource_count = int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))
	intent.set("expected_milestones", [intent])
	prepared = Edits.prepare_edit("MAKE_UNIQUE", {"object": intent, "authoring_id": F.uuid(40), "document_uri": F.BASE + "level.tscn"}, ctx)
	check(not prepared.ok and prepared.value == null, "semantic cycle rejected atomically")
	check(int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)) == resource_count, "cycle failure leaves no partial copy graph")
	intent.set("expected_milestones", [])
	intent.set("forbidden_bypasses", [milestone])
	prepared = Edits.prepare_edit("MAKE_UNIQUE", {"object": intent, "authoring_id": F.uuid(40), "document_uri": F.BASE + "level.tscn"}, ctx)
	check(not prepared.ok and prepared.value == null, "Bypass edges cannot hold Milestone resources")
	intent.set("forbidden_bypasses", [])
	intent.set("expected_milestones", [milestone])
	intent.take_over_path("res://foreign-intent.tres")
	prepared = Edits.prepare_edit("MAKE_UNIQUE", {"object": milestone, "authoring_id": F.uuid(42), "document_uri": F.BASE + "level.tscn"}, ctx)
	check(not prepared.ok and prepared.value == null and prepared.issues[0].code == "CROSS_DOCUMENT_EDIT", "nested specialization cannot edit another document resource")
	check(intent.get("expected_milestones")[0] == milestone, "cross-document rejection leaves original reference intact")
	root.free()

func no_callable(value: Variant) -> bool:
	if typeof(value) == TYPE_CALLABLE:
		return false
	if value is Array:
		return value.all(no_callable)
	if value is Dictionary:
		return value.values().all(no_callable)
	return true

func resource(kind: String, n: int, fields: Dictionary) -> Resource:
	var value: Resource = load(Schema.script_path(kind)).new()
	value.set("authoring_id", F.uuid(n))
	for key in fields:
		value.set(key, fields[key])
	return value

func ref(node: Node) -> Dictionary:
	return {"object": node, "authoring_id": node.get("authoring_id"), "document_uri": F.BASE + "surface.tscn"}

func context(world: Node) -> Dictionary:
	var docs := F.documents("minimal")
	var digests := {}
	for kind in Schema.SCRIPTS:
		var path: String = Schema.script_path(kind)
		digests[path] = FileAccess.get_sha256(path)
	var projection := Projector.project_document(world, {"document_uri": F.BASE + "surface.tscn", "document_authoring_id": F.uuid(2), "origin": "EDITOR_BUFFER", "allowed_script_digests": digests, "instance_role": null})
	check(projection.ok, "actual World declarations project for edit context")
	if projection.ok:
		docs[1] = projection.value
	return {"document_root": world, "documents": docs, "existing_ids": {}}
