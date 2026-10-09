extends SceneTree
## Owner headless persistence units. Fixture IDs are not delivered L04/L05 Content.
const Store = preload("res://game/shell/save_store.gd")
const LEGACY_IDS := ["mutsumi_l01", "mutsumi_l02", "mutsumi_l03"]
const APPENDED_FIXTURE_IDS := ["fixture_shell_append_alpha", "fixture_shell_append_omega"]

var checks := 0
var failures: Array[String] = []
var pending: Array[String] = []
var cases: Array[Dictionary] = []
var save_path := ""
var evidence_dir := ""
var tested_head := ""
var original_path := Store.DEFAULT_PATH
var explicit_legacy := false
var legacy_provenance := ""
var protected_original_directory := ""
var evidence_allowed := false
var original_hashes: Dictionary = {}
var actual_save: Dictionary = {"compatibility": "NOT_RUN", "source": "NOT_READ"}

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shell-save="):
			save_path = arg.trim_prefix("--shell-save=")
		elif arg.begins_with("--evidence-dir="):
			evidence_dir = arg.trim_prefix("--evidence-dir=")
		elif arg.begins_with("--head="):
			tested_head = arg.trim_prefix("--head=")
		elif arg.begins_with("--legacy-save="):
			original_path = arg.trim_prefix("--legacy-save=")
			explicit_legacy = true
		elif arg.begins_with("--legacy-provenance="):
			legacy_provenance = arg.trim_prefix("--legacy-provenance=")
	if not explicit_legacy:
		legacy_provenance = "SaveStore.DEFAULT_PATH in the current user profile"
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	cases.append({"case": label, "status": "PASS" if ok else "FAIL"})
	if not ok:
		failures.append(label)
		printerr("FAIL: ", label)

func mark_pending(label: String) -> void:
	pending.append(label)
	cases.append({"case": label, "status": "PENDING"})

func normalized_absolute(location: String) -> String:
	return ProjectSettings.globalize_path(location).replace("\\", "/").simplify_path().trim_suffix("/").to_lower()

func directories_overlap(left: String, right: String) -> bool:
	return left == right or left.begins_with(right + "/") or right.begins_with(left + "/")

func run() -> void:
	check(DisplayServer.get_name() == "headless", "save compatibility runs headlessly")
	var path_ok := save_path.begins_with("user://beta_sprint/") and save_path.ends_with(".json")
	path_ok = path_ok and ".." not in save_path.split("/") and "\\" not in save_path and save_path.get_base_dir() != "user://beta_sprint"
	check(path_ok, "runner supplies an isolated user://beta_sprint/<fresh>/...json save path")
	var source_ok := original_path.begins_with("user://") or (original_path.is_absolute_path() and not original_path.contains("://"))
	source_ok = source_ok and original_path.ends_with(".json") and ".." not in original_path.replace("\\", "/").split("/")
	check(source_ok and not legacy_provenance.is_empty(), "original read-only source is explicit and its provenance is recorded")
	var copy_path := save_path.get_basename() + ".actual-copy.json"
	var original_directory := normalized_absolute(original_path.get_base_dir())
	protected_original_directory = original_directory
	# An archived report path also protects its complete archive from test writes.
	if explicit_legacy and legacy_provenance.is_absolute_path() and not legacy_provenance.contains("://"):
		var archive_directory := normalized_absolute(legacy_provenance.get_base_dir())
		if original_directory == archive_directory or original_directory.begins_with(archive_directory + "/"):
			protected_original_directory = archive_directory
	var isolated_directory := normalized_absolute(save_path.get_base_dir())
	check(not directories_overlap(protected_original_directory, isolated_directory), "normalized original source/archive and isolated write/copy directories are disjoint")
	evidence_allowed = not evidence_dir.is_empty()
	if evidence_allowed:
		var destination := normalized_absolute(evidence_dir)
		var default_directory := normalized_absolute(Store.DEFAULT_PATH.get_base_dir())
		evidence_allowed = not directories_overlap(destination, default_directory) and not directories_overlap(destination, protected_original_directory)
		evidence_allowed = evidence_allowed and not directories_overlap(destination, isolated_directory)
	check(evidence_allowed, "normalized evidence directory is disjoint from original, default and isolated save directories")
	if not failures.is_empty():
		finish()
		return
	var fresh := true
	for location in [save_path, save_path + ".bak", copy_path, copy_path + ".bak"]:
		fresh = fresh and not FileAccess.file_exists(location) and not DirAccess.dir_exists_absolute(location)
	check(fresh, "isolated fixture and copied-save destinations are unused")
	if not fresh:
		finish()
		return
	var before := snapshot_pair(original_path)
	original_hashes["original_path"] = original_path
	original_hashes["selection"] = "EXPLICIT_LEGACY_SOURCE" if explicit_legacy else "CURRENT_PROFILE_DEFAULT"
	original_hashes["provenance"] = legacy_provenance
	original_hashes["before"] = before
	check(Store.VERSION == 1, "existing SaveStore schema VERSION remains 1")
	test_fixtures()
	test_actual_copy(copy_path, before)
	var after := snapshot_pair(original_path)
	original_hashes["after"] = after
	original_hashes["preserved"] = before == after
	check(before == after, "selected original primary and backup existence, size and SHA256 remain unchanged")
	if before != after:
		actual_save["compatibility"] = "FAIL"
	finish()

func test_fixtures() -> void:
	var legacy := {"has_progress": true, "unlocked": LEGACY_IDS.duplicate(), "recent": LEGACY_IDS[2],
		"completed": [LEGACY_IDS[0], LEGACY_IDS[1]],
		"settings": {"master": 0.42, "music": 0.23, "sfx": 0.67, "fullscreen": true, "muted": true}}
	var writer = Store.new(save_path, LEGACY_IDS[0])
	if not save_fixture(writer, legacy, "legacy three-ID progress and saved settings are accepted"):
		return
	var reader = Store.new(save_path, LEGACY_IDS[0])
	check(reader.load_save() == legacy, "legacy three-ID progress and all saved settings roundtrip unchanged")
	check(not reader.read_only and reader.last_error.is_empty(), "valid legacy generation loads without recovery or read-only mode")
	check(envelope_version(save_path) == 1, "legacy save uses the existing version-1 envelope")
	# muted was optional in the existing validator; loading must not add a default key.
	var old_settings := legacy.duplicate(true)
	old_settings.settings.erase("muted")
	if not save_fixture(writer, old_settings, "legacy settings without optional muted remain accepted"):
		return
	var old_restored: Dictionary = Store.new(save_path, LEGACY_IDS[0]).load_save()
	check(old_restored == old_settings and not old_restored.settings.has("muted"), "legacy optional setting omission roundtrips without adding or resetting settings")
	var appended := old_settings.duplicate(true)
	appended.unlocked.append_array(APPENDED_FIXTURE_IDS)
	appended.completed.append(LEGACY_IDS[2])
	appended.completed.append(APPENDED_FIXTURE_IDS[0])
	appended.recent = APPENDED_FIXTURE_IDS[1]
	if not save_fixture(writer, appended, "opaque appended Unit fixture IDs use the existing valid progress format"):
		return
	check(Store.new(save_path, LEGACY_IDS[0]).load_save() == appended,
		"appended Unit fixture unlocked, completed, recent and settings roundtrip unchanged")
	check(envelope_version(save_path) == 1, "appended Unit fixtures require no schema bump")
	check(Store.new(save_path + ".bak", LEGACY_IDS[0]).load_save() == old_settings,
		"appended fixture save retains the previous legacy generation as its backup")
	var retained := snapshot_pair(save_path)
	var duplicate_id := appended.duplicate(true)
	duplicate_id.unlocked.append(APPENDED_FIXTURE_IDS[0])
	check(not writer.save(duplicate_id), "duplicate appended fixture IDs retain the existing rejection semantics")
	var locked_recent := appended.duplicate(true)
	locked_recent.recent = "fixture_shell_not_unlocked"
	check(not writer.save(locked_recent), "unlocked membership still guards an opaque fixture recent ID")
	var locked_completed := appended.duplicate(true)
	locked_completed.completed.append("fixture_shell_not_unlocked")
	check(not writer.save(locked_completed), "unlocked membership still guards opaque fixture completed IDs")
	check(snapshot_pair(save_path) == retained, "rejected appended fixtures preserve both valid isolated generations byte for byte")
	check(Store.new(save_path, LEGACY_IDS[0]).load_save() == appended, "rejected fixture writes leave the latest valid progress loadable")

func save_fixture(writer, data: Dictionary, label: String) -> bool:
	var saved: bool = writer.save(data)
	check(saved, label)
	return saved

func envelope_version(location: String) -> Variant:
	var envelope: Variant = JSON.parse_string(FileAccess.get_file_as_string(location))
	return envelope.get("version") if envelope is Dictionary else null

func snapshot_file(location: String) -> Dictionary:
	var exists := FileAccess.file_exists(location)
	var result := {"exists": exists, "readable": false, "bytes": 0, "sha256": ""}
	if not exists:
		return result
	var file := FileAccess.open(location, FileAccess.READ)
	if file == null:
		return result
	result.bytes = file.get_length()
	file.close()
	result.sha256 = FileAccess.get_sha256(location)
	result.readable = not result.sha256.is_empty()
	return result

func snapshot_pair(location: String) -> Dictionary:
	return {"primary": snapshot_file(location), "backup": snapshot_file(location + ".bak")}

func test_actual_copy(copy_path: String, before: Dictionary) -> void:
	actual_save["present"] = before.primary.exists or before.backup.exists
	actual_save["original_path"] = original_path
	actual_save["selection"] = "EXPLICIT_LEGACY_SOURCE" if explicit_legacy else "CURRENT_PROFILE_DEFAULT"
	actual_save["provenance"] = legacy_provenance
	actual_save["current_default_path"] = Store.DEFAULT_PATH
	actual_save["isolated_copy_path"] = copy_path
	if not actual_save.present:
		actual_save["source"] = "ABSENT"
		actual_save["compatibility"] = "PENDING"
		mark_pending("selected original save compatibility: primary and backup are absent; real saved progress was not tested")
		return
	for generation in ["primary", "backup"]:
		if before[generation].exists:
			check(before[generation].readable, "selected original " + generation + " is readable and hashed")
			if not before[generation].readable:
				actual_save["compatibility"] = "FAIL"
				return
	# All original access is read-only, including the existing production load algorithm.
	var original = Store.new(original_path, LEGACY_IDS[0])
	var primary: Dictionary = original._read(original_path)
	var backup: Dictionary = original._read(original_path + ".bak")
	var original_data: Dictionary = original.load_save()
	actual_save["source"] = load_source(primary, backup)
	actual_save["original_access"] = "READ_ONLY"
	actual_save["store_future_format_read_only"] = original.read_only
	actual_save["load_message"] = original.last_error
	actual_save["primary"] = {"valid_v1": primary.valid, "future": primary.future}
	actual_save["backup"] = {"valid_v1": backup.valid, "future": backup.future}
	var expected_data: Dictionary = original.defaults()
	if actual_save.source == "PRIMARY_VALID_V1":
		expected_data = primary.data
	elif actual_save.source == "BACKUP_VALID_V1":
		expected_data = backup.data
	var original_matches: bool = original_data == expected_data
	check(original_matches, "original load returns the selected valid generation unchanged, or its protected/default result")
	check(original.read_only == (primary.future or (not primary.valid and backup.future)),
		"original load retains existing future-format protection priority")
	var copied := true
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(copy_path.get_base_dir())) != OK:
		copied = false
	else:
		for suffix in ["", ".bak"]:
			var source: String = original_path + suffix
			if FileAccess.file_exists(source):
				copied = DirAccess.copy_absolute(source, copy_path + suffix) == OK and copied
	check(copied, "selected original save generations are copied only into the fresh isolated destination")
	if not copied:
		actual_save["compatibility"] = "FAIL"
		return
	var copy_before := snapshot_pair(copy_path)
	check(copy_before == before, "isolated copies contain the exact original primary and backup bytes")
	var isolated = Store.new(copy_path, LEGACY_IDS[0])
	var copied_data: Dictionary = isolated.load_save()
	var same_result: bool = copied_data == original_data and isolated.read_only == original.read_only and isolated.last_error == original.last_error
	check(same_result, "existing SaveStore load preserves original progress/settings and fallback behavior on the isolated copy")
	var copy_unchanged := snapshot_pair(copy_path) == copy_before
	check(copy_unchanged, "Store.load_save leaves the isolated copied generations unchanged")
	if actual_save.source in ["PRIMARY_VALID_V1", "BACKUP_VALID_V1"]:
		actual_save["compatibility"] = "PASS" if original_matches and same_result and copy_before == before and copy_unchanged else "FAIL"
	else:
		actual_save["compatibility"] = "PENDING"
		mark_pending("selected original save compatibility: no usable version-1 generation; observed " + str(actual_save.source))

func load_source(primary: Dictionary, backup: Dictionary) -> String:
	if primary.future:
		return "FUTURE_PRIMARY_PROTECTED"
	if primary.valid:
		return "PRIMARY_VALID_V1"
	if backup.future:
		return "FUTURE_BACKUP_PROTECTED"
	if backup.valid:
		return "BACKUP_VALID_V1"
	return "NO_VALID_GENERATION_DEFAULTS"

func report() -> Dictionary:
	return {"suite": "BETA_SHELL_BATCH_02_SAVE_COMPAT", "evidence_type": "OWNER_HEADLESS_UNIT",
		"human_acceptance": "NOT_RUN", "checks": checks, "failures": failures, "pending": pending, "cases": cases,
		"status": "FAIL" if not failures.is_empty() else ("PASS_WITH_PENDING" if not pending.is_empty() else "PASS"),
		"head": tested_head, "pid": OS.get_process_id(), "display": DisplayServer.get_name(), "save_path": save_path,
		"original_source": {"path": original_path, "selection": "EXPLICIT_LEGACY_SOURCE" if explicit_legacy else "CURRENT_PROFILE_DEFAULT", "provenance": legacy_provenance, "protected_directory": protected_original_directory},
		"fixtures": {"classification": "UNIT_FIXTURE_ONLY", "legacy_ids": LEGACY_IDS, "appended_ids": APPENDED_FIXTURE_IDS,
			"acceptance": "NOT_REAL_L04_L05_ACCEPTANCE", "runtime_completion": "NOT_RUN"},
		"original_saved_file_hashes": original_hashes, "actual_save": actual_save,
		"scope": "Existing SaveStore progression/settings persistence only; selected original and default primary/backup are never written."}

func finish() -> void:
	if evidence_allowed:
		var folder_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(evidence_dir))
		check(folder_error == OK, "explicit evidence directory is available")
		if folder_error == OK:
			var file := FileAccess.open(evidence_dir.path_join("save_compat_report.json"), FileAccess.WRITE)
			check(file != null, "structured save compatibility evidence can be opened")
			if file != null:
				file.store_string(JSON.stringify(report(), "\t"))
				file.flush()
				var error := file.get_error()
				file.close()
				if error != OK:
					check(false, "structured save compatibility evidence is written successfully")
	print(JSON.stringify(report()))
	quit(0 if failures.is_empty() else 1)
