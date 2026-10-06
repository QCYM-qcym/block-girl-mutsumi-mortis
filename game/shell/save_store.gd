extends RefCounted
## One versioned progress slot. All writes stage and verify before replacement.
const VERSION := 1
const DEFAULT_PATH := "user://mutsumi_veilshift/beta_progress.json"
var path: String
var first_id: String
var last_error := ""
var read_only := false

func _init(save_path: String = DEFAULT_PATH, first_level: String = "p01") -> void:
	path = save_path
	first_id = first_level

func defaults() -> Dictionary:
	return {"has_progress": false, "unlocked": [first_id], "recent": "",
		"completed": [], "settings": {"master": 1.0, "music": 1.0, "sfx": 1.0, "fullscreen": false, "muted": false}}

func load_save() -> Dictionary:
	last_error = ""
	read_only = false
	var primary := _read(path)
	if primary.future:
		read_only = true
		last_error = "存档来自更新版本，已保留原文件；请使用对应版本。"
		return defaults()
	if primary.valid:
		return primary.data.duplicate(true)
	var backup := _read(path + ".bak")
	if backup.future:
		read_only = true
		last_error = "备份来自更新版本，已保留原文件。"
		return defaults()
	if backup.valid:
		last_error = "主存档损坏，已恢复上一份有效备份。"
		return backup.data.duplicate(true)
	if FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak"):
		last_error = "无法读取有效存档；原文件将保留，可重新开始。"
	return defaults()

func save(data: Dictionary) -> bool:
	last_error = ""
	if not path.begins_with("user://"):
		return _fail("存档位置必须是 user://。")
	if read_only or _read(path).future or _read(path + ".bak").future:
		read_only = true
		return _fail("更新版本的存档受保护，未写入。")
	if not _valid(data):
		return _fail("进度数据无效，原存档未修改。")
	var folder := ProjectSettings.globalize_path(path.get_base_dir())
	if DirAccess.make_dir_recursive_absolute(folder) != OK:
		return _fail("无法创建存档目录；请检查磁盘和权限。")
	var temporary := _temp_name(path)
	var payload := JSON.stringify(data)
	var envelope := JSON.stringify({"version": VERSION, "payload": payload, "checksum": payload.sha256_text()})
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return _fail("无法写入临时存档，原存档未修改。")
	file.store_string(envelope)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK or not _read(temporary).valid:
		DirAccess.remove_absolute(temporary)
		return _fail("临时存档校验失败，原存档未修改。")
	# Protect old data before replacing it. A corrupt primary never replaces a good backup.
	var primary := _read(path)
	if primary.valid:
		var backup_temp := _temp_name(path + ".bak")
		if DirAccess.copy_absolute(path, backup_temp) != OK or not _read(backup_temp).valid:
			DirAccess.remove_absolute(temporary)
			DirAccess.remove_absolute(backup_temp)
			return _fail("无法保留备份，原存档未修改。")
		if DirAccess.rename_absolute(backup_temp, path + ".bak") != OK:
			DirAccess.remove_absolute(temporary)
			DirAccess.remove_absolute(backup_temp)
			return _fail("备份替换失败，原存档未修改。")
	else:
		for old_path in [path, path + ".bak"]:
			if FileAccess.file_exists(old_path) and not _read(old_path).valid:
				var recovered: String = old_path + ".recovery-" + str(OS.get_process_id()) + "-" + str(Time.get_ticks_usec())
				if DirAccess.copy_absolute(old_path, recovered) != OK:
					DirAccess.remove_absolute(temporary)
					return _fail("无法保留损坏文件，原存档未修改。")
	# Godot's same-directory rename replaces an existing file. Never remove the primary first.
	if DirAccess.rename_absolute(temporary, path) != OK:
		DirAccess.remove_absolute(temporary)
		return _fail("存档替换失败，原存档与备份仍保留；请重试。")
	return true

func _temp_name(base: String) -> String:
	return base + ".tmp-" + str(OS.get_process_id()) + "-" + str(Time.get_ticks_usec())

func _fail(message: String) -> bool:
	last_error = message
	return false

func _read(source: String) -> Dictionary:
	var result := {"valid": false, "future": false, "data": {}}
	if not FileAccess.file_exists(source):
		return result
	var file := FileAccess.open(source, FileAccess.READ)
	if file == null:
		return result
	# Small progress files only. Do not allocate arbitrary-sized malformed input.
	if file.get_length() > 1048576:
		file.close()
		return result
	var text := file.get_as_text()
	file.close()
	var parser := JSON.new()
	if parser.parse(text) != OK or not parser.data is Dictionary:
		return result
	var envelope: Dictionary = parser.data
	var version = envelope.get("version")
	if (version is int or version is float) and version > VERSION:
		result.future = true
		return result
	if version != VERSION or not envelope.get("payload") is String or not envelope.get("checksum") is String:
		return result
	var payload: String = envelope.payload
	if payload.sha256_text() != envelope.checksum or parser.parse(payload) != OK or not parser.data is Dictionary:
		return result
	if not _valid(parser.data):
		return result
	result.valid = true
	result.data = parser.data
	return result

func _valid(data: Dictionary) -> bool:
	if not data.get("has_progress") is bool or not data.get("recent") is String:
		return false
	if not _ids(data.get("unlocked")) or data.unlocked.is_empty() or not _ids(data.get("completed")):
		return false
	for id in data.completed:
		if id not in data.unlocked:
			return false
	if data.has_progress and data.recent not in data.unlocked:
		return false
	if not data.has_progress and data.recent != "":
		return false
	if not data.get("settings") is Dictionary:
		return false
	var settings: Dictionary = data.settings
	if settings.has("muted") and not settings.muted is bool:
		return false
	for key in ["master", "music", "sfx"]:
		var value = settings.get(key)
		if not (value is int or value is float) or not is_finite(float(value)) or value < 0 or value > 1:
			return false
	return settings.get("fullscreen") is bool

func _ids(value: Variant) -> bool:
	if not value is Array:
		return false
	var seen: Dictionary = {}
	for id in value:
		if not id is String or id.is_empty() or id.length() > 128 or seen.has(id):
			return false
		seen[id] = true
	return true
