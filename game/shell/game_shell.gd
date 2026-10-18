extends Node
signal state_changed(state: int)
signal ui_cue_requested(cue: String)
const SaveStore = preload("res://game/shell/save_store.gd")
const Catalog = preload("res://game/shell/level_catalog.gd")
const Settings = preload("res://game/shell/settings.gd")
const Adapter = preload("res://game/shell/level_adapter.gd")
const View = preload("res://game/shell/visual_01/approved_shell_view.gd")
const InputGate = preload("res://game/shell/shell_input.gd")
enum State { BOOT, MAIN_MENU, LEVEL_SELECT, PLAYING, PAUSED, LEVEL_COMPLETE }
@export var save_path := SaveStore.DEFAULT_PATH
@export var catalog_entries: Array[Dictionary] = []
var state := State.BOOT
var store
var catalog
var progress: Dictionary = {}
var preview_settings: Dictionary = {}
var settings_open := false
var current_id := ""
var dirty := false
var adapter
var view

func _ready() -> void:
	get_tree().auto_accept_quit = false
	get_window().title = "Mutsumi Veilshift · 方块少女 · Beta"
	get_window().size = Vector2i(1280, 900)
	get_window().min_size = Vector2i(900, 700)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shell-save=user://"):
			save_path = arg.trim_prefix("--shell-save=")
	catalog = Catalog.new(catalog_entries)
	store = SaveStore.new(save_path, catalog.first_id())
	progress = store.load_save()
	adapter = Adapter.new()
	add_child(adapter)
	adapter.completed.connect(_on_completed)
	adapter.pause_requested.connect(pause_game)
	view = View.new()
	add_child(view)
	view.action_requested.connect(_on_action)
	view.settings_changed.connect(_on_setting_preview)
	var input_gate := InputGate.new()
	input_gate.shell = self
	add_child(input_gate)
	Settings.apply(progress.settings, get_window())
	show_main_menu()
	view.set_status(store.last_error)

func _set_state(value: State) -> void:
	state = value
	state_changed.emit(state)

func _can_continue() -> bool:
	return progress.has_progress and progress.recent in progress.unlocked and catalog.is_available(progress.recent)

func _save_progress() -> bool:
	dirty = not store.save(progress)
	view.set_status(store.last_error if dirty else "")
	return not dirty

func request_new_game() -> void:
	if progress.has_progress:
		view.show_screen("confirm_new")
	else:
		new_game()

func cancel_new_game() -> void:
	show_main_menu()

func new_game() -> void:
	var candidate: Dictionary = store.defaults()
	candidate.settings = progress.settings.duplicate(true)
	candidate.has_progress = true
	candidate.recent = catalog.first_id()
	if not catalog.is_available(candidate.recent):
		view.set_status("第一关尚未注册可运行场景。")
		return
	if not store.save(candidate):
		view.set_status(store.last_error)
		return
	progress = candidate
	dirty = false
	start_level(candidate.recent)

func continue_game() -> void:
	if _can_continue():
		start_level(progress.recent)
	else:
		view.set_status("暂无可继续的关卡，请开始游戏或选择已解锁关卡。")

func start_level(id: String) -> void:
	if id not in progress.unlocked or not catalog.is_available(id):
		view.set_status("该关卡尚未解锁或未注册可运行场景。")
		return
	var candidate := progress.duplicate(true)
	candidate.has_progress = true
	candidate.recent = id
	if not store.save(candidate):
		view.set_status(store.last_error)
		return
	progress = candidate
	dirty = false
	settings_open = false
	current_id = id
	adapter.enter(catalog.find(id))
	Settings.apply(progress.settings, get_window())
	get_window().title = "Mutsumi Veilshift · " + catalog.find(id).title
	_set_state(State.PLAYING)
	view.show_screen("playing")
	view.set_status("")

func pause_game() -> void:
	if state != State.PLAYING:
		return
	adapter.suspend(true)
	_set_state(State.PAUSED)
	_render_state()

func resume_game() -> void:
	if state != State.PAUSED or settings_open:
		return
	adapter.suspend(false)
	_set_state(State.PLAYING)
	_render_state()

func reset_current() -> void:
	if state not in [State.PAUSED, State.LEVEL_COMPLETE]:
		return
	adapter.reset()
	_set_state(State.PLAYING)
	_render_state()

func show_main_menu() -> void:
	_leave_level()
	_set_state(State.MAIN_MENU)
	get_window().title = "Mutsumi Veilshift · 方块少女 · Beta"
	_render_state()

func show_level_select() -> void:
	_leave_level()
	_set_state(State.LEVEL_SELECT)
	_render_state()

func _leave_level() -> void:
	if settings_open:
		Settings.apply(progress.settings, get_window())
	settings_open = false
	if dirty:
		_save_progress()
	adapter.unload()
	current_id = ""

func _on_completed() -> void:
	if state != State.PLAYING:
		return
	adapter.suspend(true)
	if current_id not in progress.completed:
		progress.completed.append(current_id)
	var next: String = catalog.next_id(current_id)
	if next != "" and catalog.is_available(next) and next not in progress.unlocked:
		progress.unlocked.append(next)
	dirty = true
	_save_progress()
	_set_state(State.LEVEL_COMPLETE)
	ui_cue_requested.emit("complete")
	_render_state()

func start_next_level() -> void:
	if state != State.LEVEL_COMPLETE:
		return
	var next: String = catalog.next_id(current_id)
	if next != "":
		start_level(next)

func open_settings() -> void:
	if state == State.PLAYING:
		pause_game()
	if settings_open:
		return
	settings_open = true
	preview_settings = progress.settings.duplicate(true)
	preview_settings.muted = preview_settings.get("muted", false)
	view.show_screen("settings", {"values": preview_settings})

func _on_setting_preview(key: String, value: Variant) -> void:
	if not settings_open or not preview_settings.has(key):
		return
	preview_settings[key] = value
	Settings.apply(preview_settings, get_window())

func save_settings() -> void:
	if not settings_open:
		return
	var candidate := progress.duplicate(true)
	candidate.settings = preview_settings.duplicate(true)
	if not store.save(candidate):
		view.set_status(store.last_error)
		return
	progress = candidate
	dirty = false
	Settings.apply(progress.settings, get_window())
	settings_open = false
	view.set_status("")
	_render_state()

func cancel_settings() -> void:
	if not settings_open:
		return
	Settings.apply(progress.settings, get_window())
	settings_open = false
	_render_state()

func _render_state() -> void:
	match state:
		State.MAIN_MENU:
			view.show_screen("main", {"can_continue": _can_continue(), "writable": not store.read_only})
		State.LEVEL_SELECT:
			var entries: Array[Dictionary] = []
			for entry in catalog.entries:
				var row: Dictionary = entry.duplicate()
				row.available = catalog.is_available(entry.id)
				entries.append(row)
			view.show_screen("select", {"entries": entries, "unlocked": progress.unlocked, "completed": progress.completed})
		State.PLAYING:
			view.show_screen("playing")
		State.PAUSED:
			view.show_screen("pause", {"title": catalog.find(current_id).title})
		State.LEVEL_COMPLETE:
			var next: String = catalog.next_id(current_id)
			view.show_screen("complete", {"title": catalog.find(current_id).title, "saved": not dirty,
				"has_next": next in progress.unlocked and catalog.is_available(next)})

func _on_action(action: String, id: String) -> void:
	ui_cue_requested.emit("select")
	match action:
		"new": request_new_game()
		"confirm_new": new_game()
		"cancel_new": cancel_new_game()
		"continue": continue_game()
		"level": start_level(id)
		"pause": pause_game()
		"resume": resume_game()
		"reset": reset_current()
		"main": show_main_menu()
		"select": show_level_select()
		"next": start_next_level()
		"settings": open_settings()
		"apply_settings": save_settings()
		"cancel_settings": cancel_settings()
		"retry_save":
			_save_progress()
			_render_state()
		"quit": request_quit()

func handle_shell_input(event: InputEvent) -> bool:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if state == State.PLAYING and view.pause_button.get_global_rect().has_point(event.position):
			if event.pressed:
				pause_game()
			return true
	if not event is InputEventKey or not event.pressed or event.echo:
		return false
	var key: int = event.keycode if event.keycode != 0 else event.physical_keycode
	if key == KEY_ESCAPE:
		if settings_open:
			cancel_settings()
		elif view.screen == "confirm_new":
			cancel_new_game()
		elif state == State.PLAYING:
			pause_game()
		elif state == State.PAUSED:
			resume_game()
		elif state in [State.LEVEL_SELECT, State.LEVEL_COMPLETE]:
			show_main_menu() if state == State.LEVEL_SELECT else show_level_select()
		return true
	if key == KEY_R and state == State.LEVEL_COMPLETE:
		reset_current()
		return true
	if key == KEY_M and state == State.PLAYING:
		var candidate := progress.duplicate(true)
		candidate.settings.muted = not candidate.settings.get("muted", false)
		if store.save(candidate):
			progress = candidate
			Settings.apply(progress.settings, get_window())
		else:
			view.set_status(store.last_error)
		return true
	return false

func request_quit() -> void:
	if settings_open:
		cancel_settings()
	if dirty and not _save_progress():
		return
	get_tree().quit()

func _notification(what: int) -> void:
	if not is_instance_valid(view):
		return
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		request_quit()
	elif what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and state == State.PLAYING:
		pause_game()
