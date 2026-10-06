extends CanvasLayer
signal action_requested(action: String, id: String)
signal settings_changed(key: String, value: Variant)
var screen := ""
var buttons: Dictionary = {}
var sliders: Dictionary = {}
var root: Control
var overlay: Control
var body: VBoxContainer
var status: Label
var pause_button: Button
var heading: Label
var ui_theme: Theme

func _ready() -> void:
	layer = 100
	ui_theme = _make_theme()
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = ui_theme
	add_child(root)
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.035, 0.065, 0.075, 0.94)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(480, 0)
	center.add_child(card)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 26)
	card.add_child(margin)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	margin.add_child(body)
	pause_button = Button.new()
	pause_button.text = "暂停  [Esc]"
	pause_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	pause_button.offset_left = -164
	pause_button.offset_right = -24
	pause_button.offset_top = 24
	pause_button.offset_bottom = 66
	pause_button.pressed.connect(func(): action_requested.emit("pause", ""))
	root.add_child(pause_button)
	status = Label.new()
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	status.offset_top = -72
	status.offset_bottom = -18
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 15)
	root.add_child(status)

func show_screen(name: String, data: Dictionary = {}) -> void:
	screen = name
	buttons.clear()
	sliders.clear()
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	overlay.visible = name != "playing"
	pause_button.visible = name == "playing"
	if name == "playing":
		get_viewport().gui_release_focus()
		return
	match name:
		"main":
			_title("方块少女 · 若叶睦", "MUTSUMI VEILSHIFT  /  BETA")
			_button("new", "开始游戏", "new", not data.get("writable", true))
			_button("continue", "继续游戏", "continue", not data.get("can_continue", false))
			_button("select", "关卡选择", "select")
			_button("settings", "设置", "settings")
			_button("quit", "退出游戏", "quit")
			_note("方向键 / Tab 选择 · Enter 确认\nContinue 从最近关卡的起点继续")
		"pause":
			_title("暂停", data.get("title", ""))
			_button("resume", "继续  [Esc]", "resume")
			_button("reset", "重置关卡", "reset")
			_button("settings", "设置", "settings")
			_button("select", "返回关卡选择", "select")
			_button("main", "返回主菜单", "main")
		"select":
			_title("关卡选择", "已通关关卡可随时重玩")
			for entry in data.entries:
				var unlocked: bool = entry.id in data.unlocked
				var suffix := "  ·  已通关" if entry.id in data.completed else ("  ·  可游玩" if unlocked else "  ·  未解锁")
				_button("level:" + entry.id, entry.title + suffix, "level", not unlocked or not entry.available, entry.id)
			_button("settings", "设置", "settings")
			_button("main", "返回主菜单  [Esc]", "main")
		"complete":
			_title("关卡完成", data.get("title", ""))
			_note("进度已保存" if data.get("saved", false) else "进度暂未写入磁盘，请重试保存")
			_button("next", "下一关" if data.get("has_next", false) else "当前 Beta 关卡已完成", "next", not data.get("has_next", false))
			_button("select", "返回关卡选择", "select")
			_button("replay", "再次游玩  [R]", "reset")
			_button("main", "返回主菜单", "main")
			if not data.get("saved", false):
				_button("retry_save", "重试保存", "retry_save")
		"confirm_new":
			_title("开始新游戏？", "将重置解锁与通关进度；设置会保留。")
			_button("cancel_new", "保留进度，返回  [Esc]", "cancel_new")
			_button("confirm_new", "确认开始新游戏", "confirm_new")
		"settings":
			_title("设置", "音量即时预览 · 应用后保存")
			for item in [["master", "Master Volume / 总音量"], ["music", "Music Volume / 环境音乐"], ["sfx", "SFX Volume / 音效"]]:
				_slider(item[0], item[1], data.values[item[0]])
			var muted := CheckButton.new()
			muted.text = "静音  [M]"
			muted.button_pressed = data.values.get("muted", false)
			muted.toggled.connect(func(value: bool): settings_changed.emit("muted", value))
			body.add_child(muted)
			buttons["muted"] = muted
			var fullscreen := CheckButton.new()
			fullscreen.text = "Fullscreen / 全屏"
			fullscreen.button_pressed = data.values.fullscreen
			fullscreen.disabled = DisplayServer.get_name() == "headless"
			fullscreen.toggled.connect(func(value: bool): settings_changed.emit("fullscreen", value))
			body.add_child(fullscreen)
			buttons["fullscreen"] = fullscreen
			_note("音乐音量目前控制环境声。")
			_button("apply", "应用并返回", "apply_settings")
			_button("cancel", "取消  [Esc]", "cancel_settings")
	var focusable: Array[Control] = []
	for value in buttons.values():
		if not value.disabled:
			focusable.append(value)
	for slider in sliders.values():
		focusable.push_front(slider)
	for i in focusable.size():
		var previous: Control = focusable[posmod(i - 1, focusable.size())]
		var next: Control = focusable[(i + 1) % focusable.size()]
		focusable[i].focus_neighbor_top = focusable[i].get_path_to(previous)
		focusable[i].focus_neighbor_bottom = focusable[i].get_path_to(next)
		focusable[i].focus_previous = focusable[i].get_path_to(previous)
		focusable[i].focus_next = focusable[i].get_path_to(next)
	if not focusable.is_empty():
		_focus_if_visible.call_deferred(focusable[0])

func _focus_if_visible(control) -> void:
	if is_instance_valid(control) and control.is_inside_tree() and control.is_visible_in_tree():
		control.grab_focus()

func set_status(message: String) -> void:
	status.text = message

func _title(text: String, subtitle: String) -> void:
	heading = Label.new()
	heading.text = text
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 30)
	body.add_child(heading)
	_note(subtitle)

func _note(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color("9cb6b1"))
	body.add_child(label)

func _button(id: String, text: String, action: String, disabled: bool = false, level_id: String = "") -> void:
	var button := Button.new()
	button.text = text
	button.disabled = disabled
	button.custom_minimum_size.y = 44
	button.pressed.connect(func(): action_requested.emit(action, level_id))
	body.add_child(button)
	buttons[id] = button

func _slider(key: String, text: String, value: float) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var amount := Label.new()
	amount.text = "%d%%" % roundi(value * 100)
	row.add_child(amount)
	body.add_child(row)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = roundi(value * 100)
	slider.custom_minimum_size.y = 28
	slider.value_changed.connect(func(number: float):
		amount.text = "%d%%" % roundi(number)
		settings_changed.emit(key, number / 100.0))
	body.add_child(slider)
	sliders[key] = slider

func _make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 18
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("142629")
	panel.border_color = Color("4f7870")
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(10)
	theme.set_stylebox("panel", "PanelContainer", panel)
	for pair in [["normal", "29413e"], ["hover", "365951"], ["pressed", "1d3431"], ["disabled", "1c292a"]]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(pair[1])
		box.set_corner_radius_all(5)
		box.content_margin_left = 16
		box.content_margin_right = 16
		theme.set_stylebox(pair[0], "Button", box)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("b7d9b0")
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(5)
	theme.set_stylebox("focus", "Button", focus)
	theme.set_color("font_color", "Button", Color("e0eee0"))
	theme.set_color("font_disabled_color", "Button", Color("7b908a"))
	theme.set_color("font_color", "Label", Color("e0eee0"))
	return theme
