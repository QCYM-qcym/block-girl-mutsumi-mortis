extends "res://tests/foundation/authoring_integration/test_suite.gd"
const Binder = preload("res://foundation/authoring/intent_binder.gd")
const Adapter = preload("res://foundation/authoring/authoring_adapter.gd")
const Projector = preload("res://foundation/authoring/document_projector.gd")
const Assembler = preload("res://foundation/authoring/payload_assembler.gd")
const Schema = preload("res://foundation/authoring/authoring_schema.gd")
const IntentValidation = preload("res://foundation/quality/intent/intent_validation.gd")
const F = preload("res://tests/foundation/authoring/authoring_fixtures.gd")
const IntentTypes = preload("res://foundation/quality/intent/intent_types.gd")
const ValidationTypes = preload("res://foundation/validation/validation_types.gd")

## Unit input identity is an explicit boundary fixture, not a 4D capture or hash.
## Track A reserves sealed digest/content mismatch verification for 4D Real.

func run() -> void:
	if mode() == "Real":
		_real_saved()
		finish()
		return
	check(mode() == "Unit", "deterministic binding cases require registered Unit mode")
	doubles.append("test-only SnapshotIdentity fixture; 4D sealed-source precondition is not authenticated here")
	var documents: Array[Dictionary] = []
	var digests := {}
	for kind in Schema.SCRIPTS:
		var path: String = Schema.script_path(kind)
		digests[path] = FileAccess.get_sha256(path)
	for i in range(4):
		var file: String = ["level.tscn", "surface.tscn", "inner.tscn", "intent.tres"][i]
		var source: Resource = load(F.BASE + file)
		var projected := Projector.project_document(source.get_state() if source is PackedScene else source, {"document_uri": F.BASE + file, "document_authoring_id": F.uuid(i + 1), "origin": "SAVED", "allowed_script_digests": digests, "instance_role": null})
		check(projected.ok, "real source document projects: " + file)
		if not projected.ok:
			finish()
			return
		documents.append(projected.value)
	var assembled := Assembler.assemble_payload(documents, F.payload("minimal").level_ref)
	check(assembled.ok, "real author closure assembles")
	if not assembled.ok:
		finish()
		return
	var identity := F.identity()
	var baked := Adapter.bake_authoring(assembled.value, F.options(), identity)
	check(baked.ok and baked.get("bake_provenance") != null, "actual new A_BAKE supplies successful provenance")
	if not baked.ok:
		finish()
		return
	var author_intent: Dictionary = documents[3].resources[0].fields.duplicate(true)
	var resource_table: Array[Dictionary] = []
	resource_table.assign(assembled.value.resource_table)
	var before := author_intent.duplicate(true)
	var bake_before := baked.duplicate(true)
	var resources_before := resource_table.duplicate(true)
	var bound := Binder.bind_intent(author_intent, resource_table, baked, identity)
	check(bound.ok and bound.bound_intent is Dictionary and bound.bound_intent.size() == 8, "explicit empty Intent binds to exactly eight formal fields")
	if bound.ok:
		check(bound.bound_intent.level_hash == baked.level.content_hash and bound.bound_intent.rule_version == baked.level.rule_version, "bindings come only from current Level")
		check(IntentValidation.validate(baked.level, bound.bound_intent).ok, "real formal IntentValidation validates explicit empty")
		check(bound.source_intent_digest == identity.source_intent_digest, "given source Intent digest is returned without recomputation")
		check(bound.bound_intent == {"intent_version": "puzzleintent.v1", "intent_id": &"empty_intent", "level_hash": baked.level.content_hash, "rule_version": "foundation.rules.v1", "required_mechanics": [], "optional_mechanics": [], "expected_milestones": [], "forbidden_bypasses": []}, "explicit empty preserves the exact closed formal declaration")
	check(author_intent == before, "author declarations are never rewritten")
	for field in ["run_id", "snapshot_id", "source_fingerprint"]:
		var changed := identity.duplicate()
		changed[field] = "2".repeat(64) if field == "source_fingerprint" else "different-" + field
		_rejected(Binder.bind_intent(author_intent, resource_table, baked, changed), "only identity." + field + " mismatch rejects unchanged successful Bake")
	for field in ["snapshot_id", "source_fingerprint"]:
		var changed := baked.duplicate(true)
		changed.source_map[field] = "mismatch"
		_rejected(Binder.bind_intent(author_intent, resource_table, changed, identity), "SourceMap cross-check rejects " + field)
	_rejected(Binder.bind_intent({}, resource_table, baked, identity), "missing Intent cannot be treated as explicit empty")
	_bake_boundaries(author_intent, resource_table, baked, identity)
	_author_boundaries(author_intent, resource_table, baked, identity)
	_resource_cases(documents, assembled.value.level_ref)
	check(baked == bake_before and resource_table == resources_before and author_intent == before, "all binding calls leave Bake, resource table and author source unchanged")
	finish()

func _rejected(result: Dictionary, label: String) -> void:
	check(result.get("ok") == false and result.get("bound_intent") == null and result.get("source_intent_digest") == null and result.get("issues") is Array and not result.issues.is_empty(), label)

func _bake_boundaries(author: Dictionary, resources: Array[Dictionary], bake: Dictionary, identity: Dictionary) -> void:
	for digest in [null, "", "a".repeat(63), "a".repeat(65), "A".repeat(64), "g".repeat(64), &"typed_wrong", 42]:
		var changed := identity.duplicate(true)
		changed.source_intent_digest = digest
		_rejected(Binder.bind_intent(author, resources, bake, changed), "present Intent rejects invalid or missing source_intent_digest: " + str(digest))
	for field in identity:
		var changed := identity.duplicate(true)
		changed.erase(field)
		_rejected(Binder.bind_intent(author, resources, bake, changed), "SnapshotIdentity rejects missing " + field)
	for field in ["run_id", "snapshot_id"]:
		var changed := identity.duplicate(true)
		changed[field] = ""
		_rejected(Binder.bind_intent(author, resources, bake, changed), "SnapshotIdentity rejects empty " + field)
	for field in ["ok", "level", "validation", "bake_provenance"]:
		var changed := bake.duplicate(true)
		changed[field] = false if field == "ok" else null
		_rejected(Binder.bind_intent(author, resources, changed, identity), "failure after success never reuses historical intent: " + field)
	for status in [ValidationTypes.ValidationStatus.INVALID, ValidationTypes.ValidationStatus.INCOMPLETE, 999]:
		var changed := bake.duplicate(true)
		changed.validation.status = status
		_rejected(Binder.bind_intent(author, resources, changed, identity), "non-VALID validation blocks binding: " + str(status))
	var changed := bake.duplicate(true)
	changed.validation.issues = [{"unexpected": true}]
	_rejected(Binder.bind_intent(author, resources, changed, identity), "VALID carrying issues is not formal successful validation")
	for field in ["status", "issues", "configurations_checked", "checks_performed"]:
		changed = bake.duplicate(true)
		changed.validation.erase(field)
		_rejected(Binder.bind_intent(author, resources, changed, identity), "validation record rejects missing " + field)
	for field in ["run_id", "snapshot_id", "source_fingerprint"]:
		changed = bake.duplicate(true)
		changed.bake_provenance.erase(field)
		_rejected(Binder.bind_intent(author, resources, changed, identity), "no provenance field is filled from caller identity: " + field)
	changed = bake.duplicate(true)
	changed.bake_provenance["extra"] = true
	_rejected(Binder.bind_intent(author, resources, changed, identity), "BakeProvenance remains exactly three fields")
	changed = bake.duplicate(true)
	changed.source_map.level_hash = "3".repeat(64)
	_rejected(Binder.bind_intent(author, resources, changed, identity), "source map hash must match this Bake level")
	changed = bake.duplicate(true)
	changed.level.content_hash = "invalid"
	_rejected(Binder.bind_intent(author, resources, changed, identity), "invalid formal level hash never reaches binding")
	changed = bake.duplicate(true)
	changed.level.rule_version = "unknown.rules"
	_rejected(Binder.bind_intent(author, resources, changed, identity), "unknown formal rule version rejects")

func _author_boundaries(author: Dictionary, resources: Array[Dictionary], bake: Dictionary, identity: Dictionary) -> void:
	for field in author:
		var changed := author.duplicate(true)
		changed.erase(field)
		_rejected(Binder.bind_intent(changed, resources, bake, identity), "author Intent rejects missing " + field)
	for pair in [["authoring_version", "unknown"], ["intent_id", &"Unknown"], ["required_mechanics", [99]], ["required_mechanics", [0, 0]], ["optional_mechanics", [1, 1]], ["expected_milestones", [{"resource_ref": F.uuid(999)}]], ["forbidden_bypasses", [{"resource_ref": F.uuid(999)}]]]:
		var changed := author.duplicate(true)
		changed[pair[0]] = pair[1]
		var table := resources.duplicate(true)
		_entry(table, F.uuid(4)).fields = changed.duplicate(true)
		_rejected(Binder.bind_intent(changed, table, bake, identity), "illegal author declaration rejects " + str(pair))
	var changed := author.duplicate(true)
	changed.required_mechanics = [0]
	changed.optional_mechanics = [0]
	var table := resources.duplicate(true)
	_entry(table, F.uuid(4)).fields = changed.duplicate(true)
	_rejected(Binder.bind_intent(changed, table, bake, identity), "required and optional mechanic sets cannot overlap")
	changed = author.duplicate(true)
	changed["level_hash"] = bake.level.content_hash
	_rejected(Binder.bind_intent(changed, resources, bake, identity), "author fields cannot supply a binding hash")
	changed = author.duplicate(true)
	changed.optional_mechanics = [1]
	_rejected(Binder.bind_intent(changed, resources, bake, identity), "stale author Intent does not match unchanged resource-table root")
	var duplicate := resources.duplicate(true)
	duplicate.append(duplicate[0].duplicate(true))
	_rejected(Binder.bind_intent(author, duplicate, bake, identity), "duplicate authoring_id cannot be deduplicated even for identical entries")
	for pair in [["kind", "UNKNOWN"], ["resource_uid", 42], ["document_uri", 42], ["authoring_id", "invalid-uuid"]]:
		var bad := resources.duplicate(true)
		bad[0][pair[0]] = pair[1]
		_rejected(Binder.bind_intent(author, bad, bake, identity), "entire table is validated, including unrelated entry " + str(pair))
	var bad := resources.duplicate(true)
	bad[0]["extra"] = true
	_rejected(Binder.bind_intent(author, bad, bake, identity), "ResourceEntry is closed to extra fields")
	bad = resources.duplicate(true)
	bad.erase(_entry(bad, F.uuid(4)))
	_rejected(Binder.bind_intent(author, bad, bake, identity), "author declaration must have a matching INTENT table entry")

func _resource_cases(base_docs: Array[Dictionary], level_ref: Dictionary) -> void:
	for scenario in ["optional", "milestones", "bypasses", "mixed"]:
		var docs: Array[Dictionary] = base_docs.duplicate(true)
		var root: Dictionary = _entry(docs[3].resources, F.uuid(4))
		if scenario in ["optional", "mixed"]:
			root.fields.optional_mechanics = [7, 1]
		if scenario in ["milestones", "mixed"]:
			for item in [
				[200, &"visit", {"kind": 0, "face_ref": {"cube_id": &"floor", "face": 4}}],
				[201, &"layer", {"kind": 1, "layer": 0}],
				[202, &"shadow", {"kind": 2, "light_state": 1}],
				[203, &"used", {"kind": 3, "mechanic": 0}],
				[204, &"goal", {"kind": 4}]]:
				docs[3].resources.append(F.resource("MILESTONE", "intent.tres", item[0], {"milestone_id": item[1], "required": true, "predicate": item[2]}))
				root.fields.expected_milestones.append({"resource_ref": F.uuid(item[0])})
		if scenario in ["bypasses", "mixed"]:
			for item in [[205, &"avoid_shift", [7, 1]], [206, &"avoid_move", [0]]]:
				docs[3].resources.append(F.resource("BYPASS", "intent.tres", item[0], {"bypass_id": item[1], "disabled_mechanics": item[2]}))
				root.fields.forbidden_bypasses.append({"resource_ref": F.uuid(item[0])})
		# Projection repeats the same Resource identity in dependent documents.
		# Keep every captured copy consistent before assembling the scenario.
		for doc in docs:
			for entry in doc.resources:
				if entry.authoring_id == F.uuid(4):
					entry.fields = root.fields.duplicate(true)
		var assembled := Assembler.assemble_payload(docs, level_ref)
		check(assembled.ok, scenario + " same-Payload author declarations are valid")
		if not assembled.ok:
			continue
		var identity := F.identity()
		identity.run_id = scenario + "-unit-run"
		identity.snapshot_id = scenario + "-unit-snapshot"
		var bake := Adapter.bake_authoring(assembled.value, F.options(), identity)
		check(bake.ok, scenario + " uses formal Reader/Baker/Validator")
		if not bake.ok:
			continue
		var table: Array[Dictionary] = []
		table.assign(assembled.value.resource_table)
		var before := table.duplicate(true)
		var author: Dictionary = _entry(table, F.uuid(4)).fields
		var result := Binder.bind_intent(author, table, bake, identity)
		check(result.ok and result.bound_intent is Dictionary, scenario + " references bind successfully")
		if result.ok:
			check(IntentValidation.validate(bake.level, result.bound_intent).ok, scenario + " real IntentValidation passes")
			check(result.source_intent_digest == identity.source_intent_digest, scenario + " retains the supplied 4D digest")
			if scenario in ["optional", "mixed"]:
				check(result.bound_intent.optional_mechanics == [1, 7], "optional-only is preserved and normalized, never erased as empty")
			if scenario in ["milestones", "mixed"]:
				check(result.bound_intent.expected_milestones[0] == {"milestone_id": &"visit", "required": true, "predicate": {"kind": 0, "face_id": &"floor/TOP"}}, "AT_FACE becomes the formal local TOP face without source metadata")
				check(result.bound_intent.expected_milestones.map(func(m: Dictionary) -> StringName: return m.milestone_id) == [&"visit", &"layer", &"shadow", &"used", &"goal"], "milestone order follows declarations")
				check(result.bound_intent.expected_milestones[2].predicate == {"kind": 2, "light_state": 1}, "FACE_LIGHT only describes the sample player face")
			if scenario in ["bypasses", "mixed"]:
				check(result.bound_intent.forbidden_bypasses == [{"bypass_id": &"avoid_shift", "disabled_mechanics": [1, 7]}, {"bypass_id": &"avoid_move", "disabled_mechanics": [0]}], "bypass declarations preserve order and normalize only tag sets")
		var reordered := table.duplicate(true)
		reordered.reverse()
		var again := Binder.bind_intent(author, reordered, bake, identity)
		check(result.ok and again.ok and again.bound_intent == result.bound_intent, "table order never selects resources or changes output")
		check(table == before, scenario + " leaves all authored arrays and entries unchanged")
		if scenario == "mixed":
			_reference_boundaries(author, table, bake, identity)

func _reference_boundaries(author: Dictionary, table: Array[Dictionary], bake: Dictionary, identity: Dictionary) -> void:
	for pair in [["expected_milestones", F.uuid(205)], ["forbidden_bypasses", F.uuid(200)], ["expected_milestones", F.uuid(999)]]:
		var changed := author.duplicate(true)
		changed[pair[0]][0] = {"resource_ref": pair[1]}
		var bad := table.duplicate(true)
		_entry(bad, F.uuid(4)).fields = changed.duplicate(true)
		_rejected(Binder.bind_intent(changed, bad, bake, identity), "reference must resolve exactly to its declared resource kind: " + str(pair))
	for field in ["expected_milestones", "forbidden_bypasses"]:
		var changed := author.duplicate(true)
		changed[field].append(changed[field][0].duplicate(true))
		var bad := table.duplicate(true)
		_entry(bad, F.uuid(4)).fields = changed.duplicate(true)
		_rejected(Binder.bind_intent(changed, bad, bake, identity), "duplicate semantic constraint rejects " + field)
	for predicate in [{"kind": 0, "face_ref": {"cube_id": &"floor", "face": 6}}, {"kind": 0, "face_ref": {"cube_id": "floor", "face": 4}}, {"kind": 0, "face_ref": {"cube_id": &"absent", "face": 4}}, {"kind": 2, "light_state": 1, "face_ref": {"cube_id": &"floor", "face": 4}}]:
		var bad := table.duplicate(true)
		_entry(bad, F.uuid(200)).fields.predicate = predicate
		_rejected(Binder.bind_intent(author, bad, bake, identity), "invalid predicate fails before Geometry assertion or through real IntentValidation: " + str(predicate))
	for tags in [[], [1, 1], [99]]:
		var bad := table.duplicate(true)
		_entry(bad, F.uuid(205)).fields.disabled_mechanics = tags
		_rejected(Binder.bind_intent(author, bad, bake, identity), "invalid bypass tag set rejects " + str(tags))
	var bad := table.duplicate(true)
	_entry(bad, F.uuid(200)).fields["resource_ref"] = F.uuid(4)
	_rejected(Binder.bind_intent(author, bad, bake, identity), "unknown nested reference cannot introduce a semantic cycle")
	bad = table.duplicate(true)
	_entry(bad, F.uuid(201)).fields.milestone_id = &"visit"
	_rejected(Binder.bind_intent(author, bad, bake, identity), "duplicate formal milestone ID cannot produce partial binding")
	var absent := table.duplicate(true)
	_entry(absent, F.uuid(200)).fields.predicate.face_ref.cube_id = &"absent"
	var formal_failure := Binder.bind_intent(author, absent, bake, identity)
	check(not formal_failure.ok and not formal_failure.issues.is_empty() and not formal_failure.issues[0].upstream.is_empty(), "formal validation failure retains original AnalysisIssue upstream")
	var foreign := table.duplicate(true)
	_entry(foreign, F.uuid(4)).fields.intent_id = &"foreign_intent"
	_rejected(Binder.bind_intent(author, foreign, bake, identity), "another Payload root cannot replace this source Intent")

func _entry(table: Array, authoring_id: String) -> Dictionary:
	for item in table:
		if item.authoring_id == authoring_id:
			return item
	return {}





## Real always consumes the D2-verified sealed payload and its actual identity.
## Saved RunRequest URIs must remain inside the active source project even when
## the formal Harness keeps evidence outside its disposable project root.
func _real_saved() -> void:
	var capture = load("res://tools/foundation/authoring_acceptance/snapshot_capture.gd")
	var execution = load("res://tools/foundation/authoring_acceptance/execution_project.gd")
	var records = load("res://tools/foundation/authoring_acceptance/run_records.gd")
	var source_root := ProjectSettings.globalize_path("res://").replace("\\", "/").trim_suffix("/")
	var source_before := {}
	for name in ["level.tscn", "surface.tscn", "inner.tscn", "intent.tres"]:
		source_before[name] = FileAccess.get_file_as_bytes(F.BASE + name)
	var observations := {}
	var source_base := "res://.godot/foundation-authoring-tests/binder_sources/%s_%s/" % [OS.get_process_id(), Time.get_ticks_usec()]
	for scenario in ["empty", "optional", "mixed", "missing"]:
		var base: String = source_base + scenario + "/"
		check(DirAccess.make_dir_recursive_absolute(base) == OK, scenario + " disposable saved source directory")
		for name in source_before:
			var text: String = source_before[name].get_string_from_utf8().replace(F.BASE, base)
			if name == "intent.tres":
				text = _real_intent_text(text, scenario)
			if name == "level.tscn" and scenario == "missing":
				text = text.replace('intent = ExtResource("Intent")', 'intent = null')
			var source := FileAccess.open(base + name, FileAccess.WRITE)
			check(source != null, scenario + " saved source opens: " + name)
			if source == null: return
			source.store_string(text)
			source.close()
		var request := {"entry_kind": "ACCEPT_SAVED", "level_ref": {"level_authoring_id": F.uuid(1), "level_id": &"authoring_minimal", "root_source_uri": base + "level.tscn"}, "policy": records.default_execution_policy("ACCEPT_SAVED")}
		var captured: Dictionary = capture.capture_saved(request, source_root)
		check(captured.ok, scenario + " actual current D2 saved capture succeeds")
		if not captured.ok:
			print("BINDER_REAL_CAPTURE_FAILURE ", captured.issues)
			return
		var snapshot: Dictionary = captured.value
		var verified: Dictionary = execution.verify(snapshot)
		check(verified.ok, scenario + " actual sealed payload and source digest verify")
		if not verified.ok: return
		var payload: Dictionary = verified.value.authoring
		var identity: Dictionary = snapshot.identity
		var bake := Adapter.bake_authoring(payload, request.policy.bake_options, identity)
		check(bake.ok, scenario + " captured payload uses formal Reader/Baker/Validator")
		if not bake.ok: return
		var table: Array[Dictionary] = []
		table.assign(payload.resource_table)
		var author: Dictionary = {} if scenario == "missing" else _entry(table, F.uuid(4)).fields
		var source_values := payload.duplicate(true)
		var result := Binder.bind_intent(author, table, bake, identity)
		observations[scenario] = {"snapshot": snapshot, "content_hash": bake.level.content_hash, "binding": result}
		if scenario == "missing":
			check(identity.source_intent_digest == null, "missing saved Intent has null D2 digest")
			_rejected(result, "missing saved Intent never becomes explicit empty")
			continue
		check(result.ok and result.bound_intent is Dictionary and result.bound_intent.size() == 8, scenario + " captured author binds to exactly eight fields")
		if not result.ok: return
		check(IntentValidation.validate(bake.level, result.bound_intent).ok, scenario + " real formal IntentValidation passes")
		check(identity.source_intent_digest != null and result.source_intent_digest == identity.source_intent_digest, scenario + " original D2 digest is returned")
		check(payload == source_values, scenario + " sealed author values remain unchanged")
		if scenario == "empty":
			check(result.bound_intent.expected_milestones.is_empty() and result.bound_intent.forbidden_bypasses.is_empty() and result.bound_intent.required_mechanics.is_empty() and result.bound_intent.optional_mechanics.is_empty(), "saved explicit empty remains explicit empty")
			_bake_boundaries(author, table, bake, identity)
			_author_boundaries(author, table, bake, identity)
		elif scenario == "optional":
			check(result.bound_intent.optional_mechanics == [1, 7], "saved optional-only declaration is retained and normalized")
		else:
			check(result.bound_intent.expected_milestones == [{"milestone_id": &"visit", "required": true, "predicate": {"kind": 0, "face_id": &"floor/TOP"}}, {"milestone_id": &"shadow", "required": false, "predicate": {"kind": 2, "light_state": 1}}], "saved milestones retain order and formal Geometry/ FACE_LIGHT meaning")
			check(result.bound_intent.forbidden_bypasses == [{"bypass_id": &"avoid_shift", "disabled_mechanics": [1, 7]}], "saved bypass retains constraints and normalizes tags")
			check(result.bound_intent.optional_mechanics == [1, 7], "saved mixed optional declaration is preserved")
		var second: Dictionary = capture.capture_saved(request, source_root)
		check(second.ok, scenario + " second actual D2 capture succeeds")
		if not second.ok: return
		check(second.value.identity.run_id != identity.run_id and second.value.identity.snapshot_id != identity.snapshot_id, scenario + " second capture allocates new execution identity")
		check(second.value.identity.source_fingerprint == identity.source_fingerprint and second.value.identity.source_intent_digest == identity.source_intent_digest, scenario + " unchanged source digests survive new run")
		_rejected(Binder.bind_intent(author, table, bake, second.value.identity), scenario + " old Bake cannot bind against new actual capture")
		var tampered := snapshot.duplicate(true)
		tampered.identity.source_intent_digest = "0".repeat(64)
		check(not execution.verify(tampered).ok, scenario + " actual D2 rejects tampered sealed digest before binding")
	for name in source_before:
		check(FileAccess.get_file_as_bytes(F.BASE + name) == source_before[name], "original source untouched: " + name)
	var evidence := FileAccess.open(evidence_dir().path_join("binder-real-captures.json"), FileAccess.WRITE)
	check(evidence != null, "actual D2 capture identities recorded")
	if evidence != null:
		evidence.store_string(JSON.stringify(observations, "\t"))
		evidence.close()

func _real_intent_text(original: String, scenario: String) -> String:
	if scenario in ["empty", "missing"]: return original
	var root := original.substr(original.find("[resource]")).replace("optional_mechanics = []", "optional_mechanics = [7, 1]")
	var prefix := '[gd_resource type="Resource" load_steps=2 format=3]\n[ext_resource type="Script" path="res://foundation/authoring/intent_authoring_resource.gd" id="Intent"]\n'
	if scenario == "mixed":
		prefix = prefix.replace("load_steps=2", "load_steps=7")
		prefix += '[ext_resource type="Script" path="res://foundation/authoring/milestone_authoring_resource.gd" id="Milestone"]\n[ext_resource type="Script" path="res://foundation/authoring/bypass_authoring_resource.gd" id="Bypass"]\n'
		prefix += '[sub_resource type="Resource" id="Visit"]\nscript = ExtResource("Milestone")\nauthoring_id = "00000000-0000-4000-8000-000000000200"\nmilestone_id = &"visit"\nrequired = true\npredicate = {"kind": 0, "face_ref": {"cube_id": &"floor", "face": 4}}\n'
		prefix += '[sub_resource type="Resource" id="Shadow"]\nscript = ExtResource("Milestone")\nauthoring_id = "00000000-0000-4000-8000-000000000202"\nmilestone_id = &"shadow"\nrequired = false\npredicate = {"kind": 2, "light_state": 1}\n'
		prefix += '[sub_resource type="Resource" id="Bypass"]\nscript = ExtResource("Bypass")\nauthoring_id = "00000000-0000-4000-8000-000000000205"\nbypass_id = &"avoid_shift"\ndisabled_mechanics = [7, 1]\n'
		root = root.replace("expected_milestones = []", 'expected_milestones = [SubResource("Visit"), SubResource("Shadow")]').replace("forbidden_bypasses = []", 'forbidden_bypasses = [SubResource("Bypass")]')
	return prefix + root
