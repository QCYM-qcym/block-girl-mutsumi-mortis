extends RefCounted
## Binds a canonical LevelCodec artifact to one sealed saved snapshot.
## This adapter validates identity and bytes; it owns no level decoding rules.
const S = preload("res://tools/foundation/authoring_acceptance/wire_schemas.gd")
const Wire = preload("res://tools/foundation/authoring_acceptance/tool_wire.gd")
const Execution = preload("res://tools/foundation/authoring_acceptance/execution_project.gd")
const Codec = preload("res://foundation/level/level_codec.gd")
const BAKE_STAGE_PATH := "artifacts/stages/BAKE/stage_result.wire"

var _loaded_hash := ""
var _snapshot_identity: Dictionary = {}

func load_artifact(snapshot_ref: Dictionary, canonical_ref: Dictionary) -> Dictionary:
	return _load(snapshot_ref,canonical_ref)

func load_run(run_root: String) -> Dictionary:
	_clear()
	# D2 reconstructs the full identity from validated sealed authoring bytes.
	var snapshot := Execution.snapshot_from_run(run_root)
	if not snapshot.ok: return snapshot
	return _load(snapshot.value,null)

func _load(snapshot_ref: Dictionary, expected_canonical: Variant) -> Dictionary:
	_clear()
	if not Execution.snapshot_shape(snapshot_ref):
		return S.failure("SNAPSHOT_INVALID", "Invalid closed SnapshotRef")
	if not _same_run_root(snapshot_ref):
		return S.failure("SNAPSHOT_IDENTITY_MISMATCH", "Run directory does not identify this snapshot")
	if expected_canonical != null and not S._stage_ref(expected_canonical,"artifacts/stages/BAKE/canonical.level","levelcanonical.v1"):
		return S.failure("ARTIFACT_INVALID", "Expected a canonical artifact reference from this run")
	if snapshot_ref.input_mode != "ACCEPT_SAVED": return S.failure("SNAPSHOT_INVALID", "D3 requires a sealed saved input")

	# Verify input.ready, the complete saved source closure, engine identity and
	# every sealed execution dependency before consuming any Bake result.
	var verified: Dictionary = Execution.verify(snapshot_ref)
	if not verified.ok:
		return verified
	var publication: Dictionary = _published_bake(snapshot_ref.root_path,verified.value.manifest.identity)
	if not publication.ok: return publication
	var stage: Dictionary = publication.value.stage_record
	if stage.execution != "COMPLETED" or stage.native_result == null:
		return S.failure("BAKE_RESULT_INCOMPLETE", "A completed successful BAKE is required")
	if stage.input_refs.input_manifest != snapshot_ref.input_manifest or stage.input_refs.authoring_payload != verified.value.manifest.authoring_payload or stage.actual_policy != verified.value.policy.bake_options:
		return S.failure("SNAPSHOT_IDENTITY_MISMATCH", "BAKE inputs or policy differ from input.ready")
	for entry in stage.native_result.source_map.entries:
		if not entry.document_uri.begins_with("res://"): return S.failure("SNAPSHOT_INVALID", "Saved BAKE SourceMap cannot refer to editor buffers")
	var canonical_ref: Dictionary = stage.native_result.level
	if expected_canonical != null and expected_canonical != canonical_ref:
		return S.failure("SNAPSHOT_IDENTITY_MISMATCH", "Caller canonical reference differs from formal BAKE publication")
	var active_root := ProjectSettings.globalize_path("res://").replace("\\", "/").trim_suffix("/")
	var active: Dictionary = Execution.prepare(active_root)
	if not active.ok:
		return active
	if active.value.execution_digest != snapshot_ref.execution_digest:
		return S.failure("EXECUTION_VERSION_MISMATCH", "Current runtime dependency closure differs from the sealed snapshot")

	var bytes_result: Dictionary = Execution.read_artifact(snapshot_ref.root_path, canonical_ref)
	if not bytes_result.ok:
		return bytes_result
	var bytes: PackedByteArray = bytes_result.value
	if Execution.sha(bytes) != canonical_ref.sha256:
		return S.failure("ARTIFACT_DIGEST_MISMATCH", "Canonical bytes do not match their ArtifactRef")
	if not Wire._valid_utf8(bytes): return S.failure("CANONICAL_INVALID", "Canonical artifact is not UTF-8")
	var text := bytes.get_string_from_utf8()
	var decoded: Dictionary = Codec.decode(text)
	if not decoded.ok:
		return {"ok": false, "value": null, "issues": decoded.issues.duplicate(true)}
	if String(decoded.level.level_id) != String(snapshot_ref.level_ref.level_id):
		return S.failure("SNAPSHOT_IDENTITY_MISMATCH", "Canonical level id differs from the saved snapshot")
	var encoded: Dictionary = Codec.encode(decoded.level)
	if not encoded.ok or encoded.text != text:
		return S.failure("CANONICAL_DIGEST_MISMATCH", "Artifact bytes are not the exact LevelCodec canonical serialization")
	if decoded.level.content_hash != stage.native_result.source_map.level_hash:
		return S.failure("CANONICAL_DIGEST_MISMATCH", "Canonical content hash differs from BAKE SourceMap")

	_loaded_hash = String(decoded.level.content_hash)
	_snapshot_identity = snapshot_ref.identity.duplicate(true)
	return S.success({"level": decoded.level.duplicate(true), "loaded_hash": _loaded_hash,
		"canonical_digest": canonical_ref.sha256, "snapshot_identity": _snapshot_identity.duplicate(true),
		"run_identity":verified.value.manifest.identity.duplicate(true),
		"input_refs":{"bake_stage_result":publication.value.artifact_ref.duplicate(true),
			"canonical_content_hash":_loaded_hash,"snapshot_id":_snapshot_identity.snapshot_id,
			"source_fingerprint":_snapshot_identity.source_fingerprint}})

func loaded_hash() -> String:
	return _loaded_hash

func snapshot_identity() -> Dictionary:
	return _snapshot_identity.duplicate(true)

func _clear() -> void:
	_loaded_hash = ""
	_snapshot_identity = {}

func _same_run_root(snapshot_ref: Dictionary) -> bool:
	var root: String = snapshot_ref.root_path.replace("\\", "/").trim_suffix("/")
	return root.ends_with("/.godot/foundation-authoring/runs/" + snapshot_ref.identity.run_id)

func _published_bake(run_root: String, identity: Dictionary) -> Dictionary:
	# Offline discovery consumes only published wire messages, never a guessed
	# stage hash or JSON sidecar. No IPC sequence-stream/lifecycle is implemented.
	var listed := _message_files(run_root.path_join("ipc"))
	if not listed.ok: return listed
	var result := {}
	for path in listed.value:
		var read := Execution.read_bytes(path)
		if not read.ok: return read
		var message := Wire.decode_wire("worker_message",read.value)
		if not message.ok:
			if message.issues[0].code == "DEPENDENCY_PENDING": continue
			return message
		if message.value.identity != identity: return S.failure("SNAPSHOT_IDENTITY_MISMATCH", "Published worker identity differs from input.ready")
		if message.value.stage_id != "BAKE": continue
		if not result.is_empty(): return S.failure("BAKE_RESULT_INVALID", "Ambiguous or duplicate BAKE publication")
		var ref: Dictionary = message.value.payload_ref_or_inline
		var bytes := Execution.read_artifact(run_root,ref)
		if not bytes.ok: return bytes
		var checked := Wire.verify_stage_result(message.value,bytes.value)
		if not checked.ok: return checked
		result = {"stage_record":checked.value.stage_record,"artifact_ref":ref}
	return S.failure("BAKE_RESULT_MISSING", "Formal BAKE STAGE_RESULT publication is required",BAKE_STAGE_PATH) if result.is_empty() else S.success(result)

func _message_files(directory: String) -> Dictionary:
	if not Execution.safe_path(directory): return S.failure("PATH_INVALID", "Unsafe IPC publication directory")
	if not DirAccess.dir_exists_absolute(directory): return S.success([])
	var dir := DirAccess.open(directory)
	if dir == null: return S.failure("IO_ERROR", "Cannot inspect IPC publications")
	var paths: Array = []
	for name in dir.get_files():
		if not name.ends_with(".wire"): continue # Unpublished temporary files are not consumed.
		var path := directory.path_join(name)
		if not Execution.safe_path(path): return S.failure("PATH_INVALID", "Linked IPC publication")
		paths.append(path)
	for name in dir.get_directories():
		var nested := _message_files(directory.path_join(name))
		if not nested.ok: return nested
		paths.append_array(nested.value)
	paths.sort()
	return S.success(paths)
