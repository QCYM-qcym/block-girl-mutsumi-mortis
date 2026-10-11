extends Node
## Menu/persistence adapter only. Factory and Host own the real experimental content.
const Tokens = preload("res://game/shell/visual_01/tokens.gd")
const Progress = preload("res://experiments/spatial_puzzle_batch_01/ui/progress_adapter.gd")
const FACTORY_PATH := "res://experiments/spatial_puzzle_batch_01/maps/map_factory.gd"
const HOST_PATH := "res://experiments/spatial_puzzle_batch_01/host/spatial_lab.gd"
const LEGACY_SCENE := "res://game/shell/game_feel_shell.tscn"
@export var save_path := Progress.DEFAULT_PATH
var progress
var lab
var entries: Dictionary = {}
var menu_panel: PanelContainer
var menu_scroll: ScrollContainer
var toolbar: PanelContainer
var continue_button: Button
var legacy_button: Button
var pause_button: Button
var reset_button: Button
var hint_button: Button
var return_button: Button
var motion_button: CheckButton
var retry_button: Button
var error_label: Label
var goal_seen := false
var _root: Control
var _error_panel: PanelContainer
var _lab_title: Label
var _factory: Script
var _ids: Array[StringName] = []
var _pending_lab: StringName = &""
var _leaving := false
var _resetting := false
var _paused := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var canvas := CanvasLayer.new()
	canvas.layer = 40
	add_child(canvas)
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = Tokens.theme()
	var focus := Tokens.flat(Tokens.COLORS.light)
	focus.border_color = Tokens.COLORS.accent
	focus.set_border_width_all(2)
	_root.theme.set_stylebox("focus","Button",focus)
	canvas.add_child(_root)
	if ResourceLoader.exists(FACTORY_PATH):
		_factory = load(FACTORY_PATH)
		_ids = _factory.ids()
		progress = Progress.new(_ids,save_path)
	_build_menu()
	_build_toolbar()
	_build_error()
	get_viewport().size_changed.connect(_layout)
	_refresh_menu()
	_set_error(progress.last_error if progress != null else "暂时无法读取实验目录，请重试。")
	_layout()
	_focus_menu()

func _button(text: String, parent: Node) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0,44)
	parent.add_child(button)
	return button

func _panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel",Tokens.flat(Tokens.COLORS.face,true))
	_root.add_child(panel)
	return panel

func _column(panel: PanelContainer, inset: int) -> VBoxContainer:
	var margin := MarginContainer.new()
	for side in ["left","top","right","bottom"]: margin.add_theme_constant_override("margin_"+side,inset)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",10)
	margin.add_child(column)
	return column

func _build_menu() -> void:
	menu_panel = _panel()
	var outer := _column(menu_panel,24)
	menu_scroll = ScrollContainer.new()
	menu_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	menu_scroll.follow_focus = true
	outer.add_child(menu_scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",12)
	menu_scroll.add_child(column)
	var title := Tokens.label("空间魔方 · 独立实验",32,true)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	column.add_child(title)
	column.add_child(Tokens.label("五个实验均可单独选择。继续会从最近实验的起点开始。\n进入后用 WASD 翻滚、Q/E 改变视角、Space 转换；H 或提示按钮查看进阶提示。",18))
	continue_button = _button("继续 · 从实验起点",column)
	continue_button.pressed.connect(func():
		if progress != null: start_lab(progress.continue_id()))
	for id in _ids:
		var row := VBoxContainer.new()
		column.add_child(row)
		var description: Dictionary = _factory.describe(id)
		var button := _button(str(description.title),row)
		button.pressed.connect(start_lab.bind(id))
		button.focus_entered.connect(func(): menu_scroll.ensure_control_visible(row))
		entries[id] = button
		row.add_child(Tokens.label(str(description.get("objective","")),18))
	legacy_button = _button("返回原有五关",column)
	legacy_button.pressed.connect(open_legacy_shell)
	continue_button.focus_entered.connect(func(): menu_scroll.ensure_control_visible(continue_button))
	legacy_button.focus_entered.connect(func(): menu_scroll.ensure_control_visible(legacy_button))

func _build_toolbar() -> void:
	toolbar = _panel()
	var column := _column(toolbar,8)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",12)
	column.add_child(row)
	_lab_title = Tokens.label("",20)
	_lab_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	_lab_title.clip_text = true
	_lab_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_lab_title)
	pause_button = _button("暂停",row)
	reset_button = _button("重置",row)
	hint_button = _button("提示",row)
	motion_button = CheckButton.new()
	motion_button.text = "减少动态"
	row.add_child(motion_button)
	return_button = _button("返回菜单",row)
	pause_button.pressed.connect(func():
		if is_instance_valid(lab): lab.set_lab_paused(not lab.paused))
	reset_button.pressed.connect(reset_current)
	hint_button.pressed.connect(func():
		if is_instance_valid(lab) and lab.has_method("toggle_hint"): lab.toggle_hint())
	motion_button.toggled.connect(func(value: bool):
		if is_instance_valid(lab): lab.set_reduced_motion(value))
	return_button.pressed.connect(func(): return_to_menu(lab))
	toolbar.hide()
	_set_toolbar_focus(false)

func _build_error() -> void:
	_error_panel = _panel()
	var column := _column(_error_panel,8)
	error_label = Tokens.label("",18)
	error_label.max_lines_visible = 3
	column.add_child(error_label)
	retry_button = _button("重试保存",column)
	retry_button.pressed.connect(retry_save)
	_error_panel.hide()

func _layout() -> void:
	var area := get_viewport().get_visible_rect().size
	var width := minf(860,area.x-48)
	toolbar.position = Vector2(24,area.y-76)
	toolbar.size = Vector2(area.x-48,60)
	_error_panel.size = Vector2(width,100)
	var error_bottom := toolbar.position.y-16 if toolbar.visible else area.y-24
	_error_panel.position = Vector2((area.x-width)/2,error_bottom-_error_panel.size.y)
	menu_panel.position = Vector2((area.x-width)/2,24)
	menu_panel.size = Vector2(width,_error_panel.position.y-40 if _error_panel.visible else area.y-48)

func _refresh_menu() -> void:
	continue_button.disabled = progress == null or progress.continue_id().is_empty()
	continue_button.text = "继续 · 从实验起点" if continue_button.disabled else "继续 · "+str(_factory.describe(progress.continue_id()).title)+"（起点）"
	_configure_focus()

func _configure_focus() -> void:
	if retry_button == null: return
	var order: Array[Control] = []
	if menu_panel.visible:
		if not continue_button.disabled: order.append(continue_button)
		for id in _ids: order.append(entries[id])
		order.append(legacy_button)
	elif _paused:
		for control in [pause_button,reset_button,hint_button,motion_button,return_button]:
			if control.visible: order.append(control)
	retry_button.focus_mode = Control.FOCUS_ALL if retry_button.visible and (menu_panel.visible or _paused) else Control.FOCUS_NONE
	if retry_button.focus_mode == Control.FOCUS_ALL: order.append(retry_button)
	for index in order.size():
		order[index].focus_next = order[(index+1)%order.size()].get_path()
		order[index].focus_previous = order[posmod(index-1,order.size())].get_path()

func _focus_menu() -> void:
	if not menu_panel.visible: return
	if not continue_button.disabled: continue_button.grab_focus()
	elif not _ids.is_empty(): entries[_ids[0]].grab_focus()
	else: legacy_button.grab_focus()

func _set_error(message: String) -> void:
	error_label.text = message
	_error_panel.visible = not message.is_empty()
	retry_button.visible = progress != null and progress.dirty and not progress.read_only
	_configure_focus()
	_layout()

func start_lab(id: StringName) -> void:
	if is_instance_valid(lab) or id not in _ids: return
	# Consume real Baker availability, never calculate gameplay permission in UI.
	var baked: Dictionary = _factory.bake(id)
	if not baked.get("ok",false):
		_set_error("实验暂时无法启动，请重试或选择其他实验。")
		return
	if not ResourceLoader.exists(HOST_PATH):
		_set_error("实验暂时无法启动，请重试。")
		return
	_pending_lab = id
	if not progress.begin_level(id):
		_set_error(progress.last_error)
		if retry_button.visible: retry_button.grab_focus()
		return
	_start_saved_lab(id)

func _start_saved_lab(id: StringName) -> void:
	_pending_lab = &""
	goal_seen = false
	_leaving = false
	lab = load(HOST_PATH).new()
	lab.lab_id = id
	lab.menu_requested.connect(_on_menu_requested.bind(lab))
	lab.goal_reached.connect(_on_goal.bind(lab))
	menu_panel.hide()
	var focused := get_viewport().gui_get_focus_owner()
	if focused: focused.release_focus()
	toolbar.show()
	_lab_title.text = str(_factory.describe(id).title)
	_set_error("")
	_set_toolbar_focus(false)
	add_child(lab)
	lab.set_reduced_motion(motion_button.button_pressed)
	hint_button.visible = lab.has_method("toggle_hint")
	if not lab.host_issues.is_empty():
		return_to_menu(lab)
		_set_error("实验未能启动，请重试或选择其他实验。")

func retry_save() -> void:
	if progress == null: return
	if not progress.retry():
		_set_error(progress.last_error)
		return
	_set_error("")
	_refresh_menu()
	if not _pending_lab.is_empty(): _start_saved_lab(_pending_lab)

func reset_current() -> void:
	if not is_instance_valid(lab): return
	_resetting = true
	goal_seen = false
	lab.reset_lab()
	lab.set_lab_paused(false)
	_resetting = false
	_lab_title.text = str(_factory.describe(lab.lab_id).title)

func _on_goal(id: StringName, source: Node) -> void:
	if source != lab or _leaving or _resetting or goal_seen or id != lab.lab_id: return
	goal_seen = true
	_lab_title.text = str(_factory.describe(id).title)+" · 已抵达终点"
	if not progress.mark_goal(id): _set_error(progress.last_error)
	else: _set_error("")
	_refresh_menu()

func _on_menu_requested(source: Node) -> void:
	if source != lab or _leaving: return
	_leaving = true
	lab.set_lab_paused(true)
	return_to_menu.call_deferred(source)

func return_to_menu(source: Node) -> void:
	if source != lab or not is_instance_valid(lab): return
	_leaving = true
	var old: Node = lab
	lab = null
	progress.leave_level()
	old.set_lab_paused(true)
	remove_child(old)
	old.queue_free()
	toolbar.hide()
	menu_panel.show()
	_refresh_menu()
	_layout()
	_focus_menu()

func _set_toolbar_focus(paused: bool) -> void:
	for control in [pause_button,reset_button,hint_button,motion_button,return_button]:
		control.focus_mode = Control.FOCUS_ALL if paused else Control.FOCUS_NONE
	_configure_focus()
	if not paused:
		var focused := get_viewport().gui_get_focus_owner()
		if focused and toolbar.is_ancestor_of(focused): focused.release_focus()

func _process(_delta: float) -> void:
	if not is_instance_valid(lab): return
	if _paused != lab.paused:
		_paused = lab.paused
		pause_button.text = "继续" if _paused else "暂停"
		_set_toolbar_focus(_paused)

func open_legacy_shell() -> void:
	if is_instance_valid(lab): return_to_menu(lab)
	if progress != null and progress.dirty and not progress.retry():
		_set_error(progress.last_error)
		return
	var result := get_tree().change_scene_to_file(LEGACY_SCENE)
	if result != OK: _set_error("暂时无法打开原有五关，请重试。")
