extends CanvasLayer
## Approved presentation of the existing Shell contract; no state or Save owner.
signal action_requested(action: String, id: String)
signal settings_changed(key: String, value: Variant)
const Tokens = preload("res://game/shell/visual_01/tokens.gd")
const Row = preload("res://game/shell/visual_01/stone_row.gd")
const Check = preload("res://game/shell/visual_01/stone_check.gd")
const StoneSlider = preload("res://game/shell/visual_01/stone_slider.gd")
var screen := ""
var buttons: Dictionary = {}
var sliders: Dictionary = {}
var root: Control
var overlay: Control
var body: VBoxContainer
var status: Label
var pause_button: Button
var _pause_surface: ColorRect
var heading: Label
var ui_theme: Theme
var focus_order: Array[Control] = []
var context_is_runtime := false
var panel_rect := Rect2()
var _data: Dictionary = {}
var _content: Control
var _panel: ColorRect
var _shade: ColorRect
var _background: TextureRect
var _world_field: ColorRect
var _identity: Label
var _identity_icon: TextureRect
var _subtitle: Label
var _footnote: Label
var _world_label: Label
var _preview_caption: Label
var _preview_id := ""
var _label_specs: Array[Dictionary] = []
var _rows: Array[Dictionary] = []
var _sliders_rows: Array[Dictionary] = []
var _settings_source := ""
var _page_tween: Tween
var _status_tween: Tween
var _note: Label
var _select_scroll: ScrollContainer

func _ready() -> void:
	layer = 100
	ui_theme = Tokens.theme()
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = ui_theme
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)
	_world_field = _rect(overlay, Tokens.COLORS.water)
	_background = TextureRect.new()
	_background.texture = load(Tokens.ROOT + "surface_identity.png")
	_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(_background)
	_shade = _rect(overlay, Color(0, 0, 0, 0.12))
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content = Control.new()
	_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(_content)
	_panel = _rect(_content, Tokens.COLORS.face)
	_identity_icon = TextureRect.new()
	_identity_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_identity_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(_identity_icon)
	_identity = _label(_content, "MUTSUMI VEILSHIFT", 20)
	heading = _label(_content, "", 56, true)
	_subtitle = _label(_content, "", 24)
	_select_scroll = ScrollContainer.new()
	_select_scroll.follow_focus = true
	_select_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_select_scroll.visible = false
	_content.add_child(_select_scroll)
	body = VBoxContainer.new()
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(body)
	_footnote = _label(_content, "", 22)
	_world_label = _label(overlay, "SURFACE WORLD", 20)
	_preview_caption = _label(overlay, "", 24)
	status = _label(root, "", 24)
	status.visible = false
	# The approved Row draws ink over its parent's surface. Gameplay backgrounds
	# can be dark (L-02 greybox), so this entry must carry its own approved stone.
	_pause_surface = _rect(root, Tokens.COLORS.face)
	_pause_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_button = Row.new()
	pause_button.text = "暂停  [Esc]"
	pause_button.display_text = "暂停  Esc"
	pause_button.glyph = Tokens.icon("pause")
	pause_button.pressed.connect(func(): action_requested.emit("pause", ""))
	root.add_child(pause_button)
	get_viewport().size_changed.connect(_layout)
	_layout()

func _rect(parent: Node, color: Color) -> ColorRect:
	var result := ColorRect.new()
	result.color = color
	result.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(result)
	return result

func _label(parent: Node, text: String, font_size: int, serif: bool = false) -> Label:
	var result := Tokens.label(text, font_size, serif)
	parent.add_child(result)
	_label_specs.append({"node": result, "size": font_size})
	return result

func show_screen(name: String, data: Dictionary = {}) -> void:
	var previous_screen := screen
	if name == "settings":
		_settings_source = previous_screen
	screen = name
	_data = data.duplicate(true)
	buttons.clear()
	sliders.clear()
	focus_order.clear()
	_rows.clear()
	_sliders_rows.clear()
	_note = null
	_select_scroll.scroll_vertical = 0
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	overlay.visible = name != "playing"
	pause_button.visible = name == "playing"
	_pause_surface.visible = name == "playing"
	_preview_caption.visible = name == "select"
	_world_label.visible = name != "playing"
	if name == "playing":
		get_viewport().gui_release_focus()
		_layout()
		return
	_identity.text = "MUTSUMI VEILSHIFT"
	_world_label.text = "SURFACE WORLD"
	_identity_icon.texture = Tokens.icon("arch")
	_footnote.text = "方向键 / Tab 选择 · Enter 确认"
	_subtitle.text = ""
	match name:
		"main":
			heading.text = "方块少女"
			_subtitle.text = "若 叶 睦"
			_button("new", "开始游戏", "new", not data.get("writable", true), "", "arch")
			_button("continue", "继续游戏", "continue", not data.get("can_continue", false), "", "arrow",
				"从最近关卡起点继续" if data.get("can_continue", false) else "暂无可继续的关卡进度")
			_button("select", "关卡选择", "select", false, "", "steps")
			_button("settings", "设置", "settings", false, "", "settings")
			_button("quit", "退出游戏", "quit", false, "", "quit")
			if not data.get("writable", true):
				_subtitle.text += "\n存档只读，暂不能开始新游戏"
		"pause":
			_identity.text = "PAUSE"
			_identity_icon.texture = Tokens.icon("pause")
			heading.text = "暂停"
			_subtitle.text = str(data.get("title", ""))
			_button("resume", "继续  [Esc]", "resume", false, "", "arrow")
			_button("reset", "重置关卡", "reset", false, "", "reset")
			_button("settings", "设置", "settings", false, "", "settings")
			_button("select", "返回关卡选择", "select", false, "", "steps")
			_button("main", "返回主菜单", "main", false, "", "return")
		"select":
			heading.text = "关卡选择"
			_subtitle.text = "已通关关卡可随时重玩"
			var index := 0
			for entry in data.entries:
				index += 1
				var unlocked: bool = entry.id in data.unlocked
				var state := "已通关" if entry.id in data.completed else "可游玩" if unlocked else "未解锁"
				if not entry.available:
					state = "场景不可用"
				var item = _button("level:" + entry.id, entry.title + "  ·  " + state, "level",
					not unlocked or not entry.available, entry.id, "check" if entry.id in data.completed else "arch" if unlocked else "lock")
				item.catalog_row = true
				item.number = "%02d" % index
				item.display_text = entry.title
				item.detail = state
				item.focus_entered.connect(func(): _update_preview(entry, unlocked))
			var navigation := HBoxContainer.new()
			body.add_child(navigation)
			_button("main", "返回主菜单  [Esc]", "main", false, "", "return", "", navigation)
			_button("settings", "设置", "settings", false, "", "settings", "", navigation)
			if not data.entries.is_empty():
				_update_preview(data.entries[0], data.entries[0].id in data.unlocked)
		"complete":
			_identity.text = "LEVEL COMPLETE"
			_identity_icon.texture = Tokens.icon("check")
			heading.text = "关卡完成"
			_subtitle.text = str(data.get("title", "")) + "\n" + ("进度已保存" if data.get("saved", false) else "进度暂未写入磁盘，请重试保存")
			_button("next", "下一关" if data.get("has_next", false) else "当前 Beta 关卡已完成", "next", not data.get("has_next", false), "", "arch")
			_button("select", "返回关卡选择", "select", false, "", "steps")
			_button("replay", "再次游玩  [R]", "reset", false, "", "reset")
			_button("main", "返回主菜单", "main", false, "", "return")
			if not data.get("saved", false):
				_button("retry_save", "重试保存", "retry_save", false, "", "reset")
		"confirm_new":
			heading.text = "开始新游戏？"
			_subtitle.text = "将重置解锁与通关进度；设置会保留。"
			_button("cancel_new", "保留进度，返回  [Esc]", "cancel_new", false, "", "return")
			_button("confirm_new", "确认开始新游戏", "confirm_new", false, "", "arch")
		"settings":
			_identity.text = "SETTINGS"
			_identity_icon.texture = Tokens.icon("settings")
			heading.text = "设置"
			_subtitle.text = "音量即时预览 · 应用后保存"
			for item in [["master", "总音量"], ["music", "环境音乐"], ["sfx", "音效"]]:
				_slider(item[0], item[1], data.values[item[0]])
			_check("muted", "静音", data.values.get("muted", false))
			_check("fullscreen", "全屏", data.values.fullscreen, DisplayServer.get_name() == "headless")
			_note = Tokens.label("环境音乐音量目前控制环境声。", 22)
			body.add_child(_note)
			_button("apply", "应用并返回", "apply_settings", false, "", "check")
			_button("cancel", "取消  [Esc]", "cancel_settings", false, "", "return")
	_layout()
	_connect_focus()
	var preferred := "settings" if previous_screen == "settings" and name == _settings_source else ""
	_focus_initial.call_deferred(preferred)
	_animate_page(name)

func _button(id: String, text: String, action: String, disabled: bool = false,
		level_id: String = "", icon_name: String = "arrow", detail: String = "", parent: Node = null):
	var button := Row.new()
	button.text = text
	button.display_text = text.replace("  [Esc]", "").replace("  [R]", "")
	button.detail = detail
	button.glyph = Tokens.icon(icon_name)
	button.disabled = disabled
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.tooltip_text = text + ("\n" + detail if not detail.is_empty() else "")
	button.pressed.connect(func(): action_requested.emit(action, level_id))
	(parent if parent != null else body).add_child(button)
	buttons[id] = button
	_rows.append({"node": button, "height": 116.0 if not detail.is_empty() else 72.0})
	if not disabled:
		focus_order.append(button)
	return button

func _slider(key: String, text: String, value: float) -> void:
	var row := Control.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(row)
	var label := Tokens.label(text, 32)
	row.add_child(label)
	var amount := Tokens.label("%d%%" % roundi(value * 100), 24)
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(amount)
	var slider := StoneSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = roundi(value * 100)
	row.add_child(slider)
	slider.value_changed.connect(func(number: float):
		amount.text = "%d%%" % roundi(number)
		settings_changed.emit(key, number / 100.0))
	sliders[key] = slider
	focus_order.append(slider)
	_sliders_rows.append({"row": row, "label": label, "amount": amount, "slider": slider})

func _check(key: String, text: String, value: bool, disabled: bool = false) -> void:
	var button := Check.new()
	button.text = text
	button.button_pressed = value
	button.disabled = disabled
	button.toggled.connect(func(enabled: bool): settings_changed.emit(key, enabled))
	body.add_child(button)
	buttons[key] = button
	_rows.append({"node": button, "height": 72.0})
	if not disabled:
		focus_order.append(button)

func _connect_focus() -> void:
	for index in focus_order.size():
		var node := focus_order[index]
		var previous := focus_order[posmod(index - 1, focus_order.size())]
		var next := focus_order[posmod(index + 1, focus_order.size())]
		node.focus_neighbor_top = node.get_path_to(previous)
		node.focus_neighbor_bottom = node.get_path_to(next)
		node.focus_previous = node.get_path_to(previous)
		node.focus_next = node.get_path_to(next)
		node.gui_input.connect(func(event: InputEvent):
			if event.is_action_pressed("ui_down"):
				next.grab_focus(); node.accept_event()
			elif event.is_action_pressed("ui_up"):
				previous.grab_focus(); node.accept_event())

func _focus_initial(preferred: String) -> void:
	if not overlay.visible:
		return
	if buttons.has(preferred) and not buttons[preferred].disabled:
		buttons[preferred].grab_focus()
	elif not focus_order.is_empty():
		focus_order[0].grab_focus()

func _current_level():
	var shell := get_parent()
	if shell and shell.has_method("_can_continue") and shell.adapter:
		return shell.adapter.level
	return null

func _update_preview(entry: Dictionary, unlocked: bool) -> void:
	_preview_id = str(entry.id)
	_background.visible = unlocked and entry.available and entry.id == "mutsumi_l01"
	_background.texture = load(Tokens.ROOT + "previews/l01.png") if _background.visible else null
	_preview_caption.text = entry.title + "\n" + ("L-01 · 正式关卡画面" if _background.visible else "未解锁 · 不展示地图" if not unlocked else "灰盒试玩 · 尚无正式环境预览" if entry.available else "场景不可用")

func _process(_delta: float) -> void:
	if screen in ["pause", "complete", "settings"] and context_is_runtime:
		var level = _current_level()
		if level and level.has_method("get_world_label"):
			_world_label.text = level.get_world_label()
		elif level and level.get("mover"):
			_world_label.text = "表世界 · Mutsumi" if level.mover.world == 0 else "里世界 · Mortis"

func _layout() -> void:
	if root == null:
		return
	var area := get_viewport().get_visible_rect().size
	var unit := minf(area.x / 1920.0, area.y / 1080.0)
	var vertical := area.y / 1080.0
	var narrow := area.x / area.y < 1.5
	var compact := screen in ["pause", "complete", "confirm_new"]
	var panel_width := 560.0 * unit if compact else 800.0 * unit if screen == "settings" else 896.0 * unit if screen == "select" else 720.0 * unit
	if narrow:
		panel_width = 440.0 if screen == "settings" else 420.0
	var margin := 64.0 * unit if compact else 0.0
	panel_rect = Rect2(margin, margin, panel_width, area.y - margin * 2)
	_panel.position = panel_rect.position
	_panel.size = panel_rect.size
	context_is_runtime = _current_level() != null and screen in ["pause", "complete", "settings"]
	_shade.visible = context_is_runtime
	_world_field.visible = not context_is_runtime
	_background.visible = not context_is_runtime
	if not context_is_runtime:
		_background.texture = load(Tokens.ROOT + "surface_identity.png")
		_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_world_field.position = Vector2(panel_width, 0)
	_world_field.size = Vector2(maxf(1, area.x - panel_width), area.y)
	_background.position = _world_field.position
	_background.size = _world_field.size
	var text_x := margin + (48.0 if compact else 96.0 if screen == "settings" else 80.0 if screen == "select" else 112.0) * unit
	if narrow:
		text_x = margin + 32
	var text_width := panel_width - (text_x - margin) * 2
	var identity_y := (112.0 if compact else 80.0) * vertical
	_identity_icon.position = Vector2(text_x, identity_y)
	_identity_icon.size = Vector2.ONE * 32 * unit
	_identity.position = Vector2(text_x + 64 * unit, identity_y)
	_identity.size = Vector2(maxf(1, text_width - 64 * unit), 40 * unit)
	heading.position = Vector2(text_x, 188 * vertical)
	heading.size = Vector2(text_width, 110 * vertical)
	_subtitle.position = Vector2(text_x, 284 * vertical)
	_subtitle.size = Vector2(text_width, (96 if screen == "complete" else 64) * vertical)
	var body_y := 428.0 * vertical if screen == "main" else 400.0 * vertical
	if screen == "settings":
		body_y = 312 * vertical
	if screen == "select":
		body_y = 368 * vertical
		text_width = panel_width - text_x * 2
	if narrow and screen == "select":
		panel_rect = Rect2(0, 0, area.x, area.y)
		_panel.position = Vector2.ZERO
		_panel.size = area
		text_x = 32
		text_width = area.x - 64
		_identity_icon.position.y = 24
		_identity.position.y = 24
		heading.position = Vector2(32, 66)
		heading.size = Vector2(text_width, 52)
		_subtitle.position = Vector2(32, 118)
		_subtitle.size = Vector2(text_width, 32)
		_world_field.visible = true
		_world_field.position = Vector2(32, 160)
		_world_field.size = Vector2(text_width, 176)
		_background.position = _world_field.position
		_background.size = _world_field.size
		_world_field.z_index = 1
		_background.z_index = 2
		body_y = 352
	else:
		_world_field.z_index = 0
		_background.z_index = 0
	var list_area := Rect2(text_x, body_y, text_width, maxf(1, area.y - body_y - 96 * unit))
	var extended_list: bool = screen == "select" and _data.get("entries", []).size() > 3
	_select_scroll.visible = extended_list
	var body_parent: Node = _select_scroll if extended_list else _content
	if body.get_parent() != body_parent:
		body.reparent(body_parent, false)
	if extended_list:
		_select_scroll.position = list_area.position
		_select_scroll.size = list_area.size
		body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		body.position = list_area.position
		body.size = list_area.size
	body.add_theme_constant_override("separation", roundi((20 if screen == "main" else 32 if screen == "select" else 36 if compact else 5) * unit))
	for spec in _label_specs:
		var minimum := 16 if spec.size < 32 else 22
		var pixels := maxi(minimum, roundi(spec.size * unit))
		if spec.node == heading and screen == "main":
			pixels = maxi(42, roundi(76 * unit))
		spec.node.add_theme_font_size_override("font_size", pixels)
	_subtitle.size.y = maxf(_subtitle.size.y, _text_height(_subtitle, text_width) + 4)
	var status_height := maxf(32, _text_height(status, text_width) + 8) if not status.text.is_empty() else 0.0
	status.position = Vector2(text_x, area.y - maxf(16, 24 * unit) - status_height)
	status.size = Vector2(maxf(1, text_width), status_height)
	status.visible = not status.text.is_empty()
	if screen == "complete":
		body_y = maxf(body_y, _subtitle.position.y + _subtitle.size.y + 16 * unit)
		body.position.y = body_y
		var action_bottom := status.position.y - 16 * unit if status.visible else area.y - 96 * unit
		var gap := maxf(8, 24 * unit)
		var target_height := (action_bottom - body_y - gap * (_rows.size() - 1)) / maxf(1, _rows.size())
		if target_height < 72 * unit:
			gap = 8
			target_height = (action_bottom - body_y - gap * (_rows.size() - 1)) / maxf(1, _rows.size())
		body.add_theme_constant_override("separation", roundi(gap))
		for row in _rows:
			row.height = minf(72, maxf(40, target_height) / unit)
	for row in _rows:
		var node: Control = row.node
		var height: float = row.height * unit
		if node is Row:
			if node.catalog_row:
				height = 132 * unit
				node.configure(unit)
			else:
				node.configure(unit)
		elif node is CheckButton:
			node.add_theme_font_size_override("font_size", maxi(22, roundi(32 * unit)))
		node.custom_minimum_size.y = maxf(40, height)
		if narrow and screen == "select" and node is Row and node.catalog_row:
			node.custom_minimum_size.y = 76
	for item in _sliders_rows:
		item.row.custom_minimum_size.y = maxf(60, 100 * unit)
		item.label.position = Vector2(12 * unit, 0)
		item.label.size = Vector2(text_width * 0.68, maxf(36, 42 * unit))
		item.label.add_theme_font_size_override("font_size", maxi(22, roundi(32 * unit)))
		item.amount.position = Vector2(text_width * 0.7, 0)
		item.amount.size = Vector2(text_width * 0.3 - 12 * unit, maxf(36, 42 * unit))
		item.amount.add_theme_font_size_override("font_size", maxi(16, roundi(24 * unit)))
		item.slider.position = Vector2(12 * unit, maxf(40, 50 * unit))
		item.slider.size = Vector2(text_width - 24 * unit, maxf(22, 30 * unit))
	if _note:
		_note.add_theme_font_size_override("font_size", maxi(16, roundi(22 * unit)))
		_note.custom_minimum_size.y = maxf(28, 52 * unit)
	_footnote.position = Vector2(text_x, area.y - 88 * unit)
	_footnote.size = Vector2(text_width, 48 * unit)
	_footnote.visible = screen not in ["settings", "select"] and status.text.is_empty()
	_world_label.position = Vector2(area.x - 320 * unit, 80 * vertical)
	_world_label.size = Vector2(248 * unit, 56 * unit)
	_world_label.visible = not (screen == "select" and narrow) and screen != "playing"
	_preview_caption.position = Vector2(panel_width + 80 * unit, area.y - 150 * unit)
	_preview_caption.size = Vector2(maxf(1, area.x - panel_width - 120 * unit), 104 * unit)
	if screen == "select":
		_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_preview_caption.visible = not narrow
		if _data.has("entries") and not _data.entries.is_empty():
			var selected: Dictionary = _data.entries[0]
			for entry in _data.entries:
				if entry.id == _preview_id:
					selected = entry
			_update_preview(selected, selected.id in _data.unlocked)
	pause_button.position = Vector2(area.x - maxf(160, 240 * unit) - 32 * unit, 32 * unit)
	pause_button.size = Vector2(maxf(160, 240 * unit), maxf(44, 64 * unit))
	pause_button.configure(unit)
	_pause_surface.position = pause_button.position
	_pause_surface.size = pause_button.size

func _text_height(label: Label, width: float) -> float:
	return label.get_theme_font("font").get_multiline_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT,
		width, label.get_theme_font_size("font_size")).y

func set_status(message: String) -> void:
	status.text = message
	status.visible = not message.is_empty()
	_layout()
	if _status_tween and _status_tween.is_valid():
		_status_tween.kill()
	status.modulate.a = 0.0 if not message.is_empty() else 1.0
	_status_tween = create_tween()
	_status_tween.tween_property(status, "modulate:a", 1.0, 0.12)

func _animate_page(name: String) -> void:
	if _page_tween and _page_tween.is_valid():
		_page_tween.kill()
	_content.modulate.a = 0.0
	_content.position = Vector2(-16 if name == "pause" else -12, 0)
	_page_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_page_tween.set_parallel(true)
	_page_tween.tween_property(_content, "modulate:a", 1.0, 0.24 if name == "main" else 0.18)
	_page_tween.tween_property(_content, "position", Vector2.ZERO, 0.24 if name == "main" else 0.18)

func debug_snapshot() -> Dictionary:
	var ids: Array[String] = []
	for node in focus_order:
		for key in buttons:
			if buttons[key] == node:
				ids.append(key)
		for key in sliders:
			if sliders[key] == node:
				ids.append(key)
	return {"screen": screen, "focus_ids": ids, "panel_rect": panel_rect,
		"context_is_runtime": context_is_runtime, "preview_id": _preview_id}
