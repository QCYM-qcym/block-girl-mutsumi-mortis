extends RefCounted
## Existing version1 Store only; no mid-puzzle state or formal unlock progression.
const Store = preload("res://game/shell/save_store.gd")
const DEFAULT_PATH := "user://spatial_puzzle_batch_01/progress.json"
var active_id: StringName = &""
var last_error := ""
var read_only: bool:
	get: return _store.read_only or _catalog_read_only
var dirty: bool:
	get: return not _pending.is_empty()
var _store
var _ids: Array[String] = []
var _data: Dictionary
var _pending: Dictionary = {}
var _pending_start: StringName = &""
var _catalog_read_only := false

func _init(ids: Array[StringName], path: String = DEFAULT_PATH) -> void:
	for id in ids:
		if id.is_empty() or String(id) in _ids:
			_catalog_read_only = true
		else: _ids.append(String(id))
	_store = Store.new(path,_ids[0] if not _ids.is_empty() else "unknown_lab")
	_data = _store.load_save()
	last_error = _store.last_error
	for id in _data.unlocked + _data.completed:
		if id not in _ids: _catalog_read_only = true
	if _data.has_progress and _data.recent not in _ids: _catalog_read_only = true
	if _catalog_read_only: last_error = "实验存档包含未知实验或目录无效，已保留原文件；请使用对应版本。"

func snapshot() -> Dictionary:
	return _data.duplicate(true)

func continue_id() -> StringName:
	return StringName(_data.recent) if not read_only and _data.has_progress and _data.recent in _ids else &""

func begin_level(id: StringName) -> bool:
	if String(id) not in _ids:
		last_error = "实验未注册，进度未修改。"
		return false
	var candidate: Dictionary = (_data if _pending.is_empty() else _pending).duplicate(true)
	candidate.has_progress = true
	candidate.recent = String(id)
	# SaveStore requires this compatibility field; it is the fixed independent catalog, not unlock logic.
	candidate.unlocked = _ids.duplicate()
	return _write(candidate,id)

func mark_goal(id: StringName) -> bool:
	if id.is_empty() or id != active_id:
		last_error = "已失效或不匹配的实验完成通知，进度未修改。"
		return false
	var candidate: Dictionary = (_data if _pending.is_empty() else _pending).duplicate(true)
	if String(id) in candidate.completed: return not dirty
	candidate.completed.append(String(id))
	return _write(candidate)

func retry() -> bool:
	if read_only:
		last_error = "存档处于只读保护，未写入；请使用对应版本。"
		return false
	if _pending.is_empty(): return true
	return _write(_pending.duplicate(true),_pending_start)

func leave_level() -> void:
	active_id = &""

func _write(candidate: Dictionary, start: StringName = &"") -> bool:
	if read_only:
		last_error = "存档处于只读保护，未写入；请使用对应版本。"
		return false
	_pending = candidate.duplicate(true)
	_pending_start = start
	if not _store.save(candidate):
		last_error = _store.last_error
		return false
	_data = candidate.duplicate(true)
	if not start.is_empty(): active_id = start
	_pending = {}
	_pending_start = &""
	last_error = ""
	return true
