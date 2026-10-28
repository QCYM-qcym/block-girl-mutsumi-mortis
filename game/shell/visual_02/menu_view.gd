extends "res://game/shell/visual_01/approved_shell_view.gd"
## Presentation only. All actions, catalog state and save gating remain in ApprovedView.
signal presentation_world_selected(layer: int)
const Palette = preload("res://game/shell/visual_02/palette.gd")
const MenuRow = preload("res://game/shell/visual_02/menu_row.gd")
const Backdrop = preload("res://game/shell/visual_02/character_backdrop.gd")
var backdrop
var world_buttons: Array[Button] = []
var _menu_veil: TextureRect
var _toolbar: HBoxContainer
var _world_layer := 0
var _contrast := false
var _reduced_motion := false
var _settings_overlay := false

func _ready() -> void:
	super._ready()
	backdrop = Backdrop.new()
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(backdrop)
	overlay.move_child(backdrop, 0)
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.28, 0.62, 1.0])
	gradient.colors = PackedColorArray([Color(0.025, 0.055, 0.075, 0.86), Color(0.025, 0.055, 0.075, 0.64), Color(0.025, 0.055, 0.075, 0.08), Color(0.025, 0.055, 0.075, 0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2.ZERO
	texture.fill_to = Vector2.RIGHT
	_menu_veil = TextureRect.new()
	_menu_veil.texture = texture
	_menu_veil.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_menu_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(_menu_veil)
	overlay.move_child(_menu_veil, 1)
	_toolbar = HBoxContainer.new()
	_toolbar.add_theme_constant_override("separation", 12)
	root.add_child(_toolbar)
	root.theme = Palette.theme(_world_layer, _contrast)
	for item in [["表", 0], ["里", 1]]:
		var button := Button.new()
		button.text = item[0]
		button.tooltip_text = "展示表世界" if item[1] == 0 else "展示里世界"
		button.custom_minimum_size = Vector2(48, 48)
		button.pressed.connect(func():
			set_world_layer(item[1])
			presentation_world_selected.emit(item[1]))
		_toolbar.add_child(button)
		world_buttons.append(button)
	for item in [["转", "turn"], ["倾", "lean"]]:
		var button := Button.new()
		button.text = item[0]
		button.tooltip_text = "轻轻转身" if item[1] == "turn" else "轻轻侧倾"
		button.custom_minimum_size = Vector2(48, 48)
		button.pressed.connect(func(): backdrop.request_motion(item[1]))
		_toolbar.add_child(button)
	_layout()

func _button(id: String, text: String, action: String, disabled: bool = false,
		level_id: String = "", icon_name: String = "arrow", detail: String = "", parent: Node = null):
	var button := MenuRow.new()
	button.text = text
	button.display_text = text.replace("  [Esc]", "").replace("  [R]", "")
	button.detail = detail
	button.glyph = Tokens.icon(icon_name)
	button.disabled = disabled
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.tooltip_text = text + ("\n" + detail if not detail.is_empty() else "")
	button.set_palette(Palette.colors(_world_layer, _contrast))
	button.pressed.connect(func(): action_requested.emit(action, level_id))
	(parent if parent != null else body).add_child(button)
	button.set_reduced_motion(_reduced_motion)
	buttons[id] = button
	_rows.append({"node":button,"height":64.0})
	if not disabled: focus_order.append(button)
	return button

func set_world_layer(value: int) -> void:
	_world_layer = clampi(value, 0, 1)
	if root: root.theme = Palette.theme(_world_layer, _contrast)
	if backdrop: backdrop.set_world_layer(_world_layer)
	_layout()

func set_accessibility(value: Dictionary) -> void:
	_contrast = bool(value.get("contrast", false))
	_reduced_motion = bool(value.get("reduced_motion", false))
	if root: root.theme = Palette.theme(_world_layer, _contrast)
	if backdrop: backdrop.set_reduced_motion(_reduced_motion)
	for row in _rows:
		if row.node.has_method("set_reduced_motion"): row.node.set_reduced_motion(_reduced_motion)
	_layout()

func set_settings_overlay(value: bool) -> void:
	_settings_overlay = value
	_layout()

func _update_preview(entry: Dictionary, _unlocked: bool) -> void:
	_preview_id = str(entry.id)
	_preview_caption.visible = false
	_background.visible = false

func _process(_delta: float) -> void:
	pass

func _connect_focus() -> void:
	# Persistent toolbar controls join each fresh page loop without accumulating
	# closures pointing at controls freed by the previous page.
	if is_instance_valid(_toolbar) and _toolbar.visible:
		for control in _toolbar.get_children():
			if not control.disabled: focus_order.append(control)
	for index in focus_order.size():
		var control := focus_order[index]
		var previous := focus_order[posmod(index - 1, focus_order.size())]
		var next := focus_order[(index + 1) % focus_order.size()]
		control.focus_neighbor_top = control.get_path_to(previous)
		control.focus_neighbor_bottom = control.get_path_to(next)
		control.focus_previous = control.get_path_to(previous)
		control.focus_next = control.get_path_to(next)

func _layout() -> void:
	if root == null: return
	var area := get_viewport().get_visible_rect().size
	var width := clampf(area.x * 0.30, 330.0, 440.0)
	var colors := Palette.colors(_world_layer, _contrast)
	var unit := clampf(area.y / 720.0, 0.8, 1.3)
	if screen == "select" and buttons.has("main") and buttons.has("settings"):
		var navigation: Node = buttons.main.get_parent()
		if navigation is HBoxContainer:
			# The inherited wide-screen footer becomes two legible full-width rows.
			buttons.main.reparent(body, false)
			buttons.settings.reparent(body, false)
			navigation.get_parent().remove_child(navigation)
			navigation.queue_free()
	panel_rect = Rect2(0, 0, width, area.y)
	context_is_runtime = screen in ["pause", "complete"] or (_current_level() != null and (screen == "settings" or _settings_overlay))
	var show_character := not context_is_runtime and (screen in ["main", "select", "confirm_new", "settings"] or _settings_overlay)
	_background.visible = false
	_world_field.visible = false
	_identity.visible = screen == "main"
	if screen == "main":
		_identity.text = "方块少女"
		heading.text = "若叶睦"
		_subtitle.text = "存档只读，暂不能开始新游戏" if not _data.get("writable", true) else ""
	_identity.position = Vector2(28, 76)
	_identity.size = Vector2(width - 56, 30)
	_identity.add_theme_font_size_override("font_size", 18)
	_identity.add_theme_color_override("font_color", colors.secondary)
	_identity_icon.visible = false
	_world_label.visible = false
	_preview_caption.visible = false
	_footnote.visible = false
	_shade.visible = context_is_runtime and screen != "playing"
	_panel.position = Vector2.ZERO
	_panel.size = Vector2(width, area.y)
	_panel.color = colors.face
	_panel.visible = screen != "main"
	if _menu_veil: _menu_veil.visible = show_character
	_content.visible = not _settings_overlay
	heading.position = Vector2(28, 118 if screen == "main" else 48)
	heading.size = Vector2(width - 56, 58)
	heading.add_theme_font_size_override("font_size", 44 if screen == "main" else 28)
	_subtitle.position = Vector2(28, 180 if screen == "main" else 110)
	_subtitle.size = Vector2(width - 56, 80)
	_subtitle.add_theme_font_size_override("font_size", 16)
	var body_top := 250.0 if screen == "main" else 196.0
	var available := Rect2(24, body_top, width - 48, maxf(80, area.y - body_top - 112))
	var scroll := screen in ["select", "complete", "settings"]
	_select_scroll.visible = scroll
	var parent: Node = _select_scroll if scroll else _content
	if body.get_parent() != parent: body.reparent(parent, false)
	if scroll:
		_select_scroll.position = available.position
		_select_scroll.size = available.size
		body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		body.position = available.position
		body.size = available.size
	body.add_theme_constant_override("separation", 6 if screen == "main" else 10)
	for row in _rows:
		var node: Control = row.node
		if node.has_method("configure"): node.configure(unit)
		if node.has_method("set_palette"): node.set_palette(colors)
		node.custom_minimum_size.y = 78 if node is MenuRow and node.catalog_row else 56 if screen == "main" else 64
	for item in _sliders_rows:
		item.row.custom_minimum_size.y = 80
		item.label.position = Vector2(8, 0)
		item.label.size = Vector2(available.size.x * 0.65, 32)
		item.label.add_theme_font_size_override("font_size", 18)
		item.amount.position = Vector2(available.size.x * 0.65, 0)
		item.amount.size = Vector2(available.size.x * 0.35 - 8, 32)
		item.amount.add_theme_font_size_override("font_size", 16)
		item.slider.position = Vector2(8, 40)
		item.slider.size = Vector2(available.size.x - 16, 28)
		for label in [item.label, item.amount]: label.add_theme_color_override("font_color", colors.ink)
	if _note:
		_note.add_theme_font_size_override("font_size", 16)
		_note.custom_minimum_size.y = 36
		_note.add_theme_color_override("font_color", colors.secondary)
	for label in [heading, _subtitle, status]:
		label.add_theme_color_override("font_color", colors.ink)
	status.position = Vector2(24, area.y - 108)
	status.size = Vector2(width - 48, 72)
	status.add_theme_font_size_override("font_size", 16)
	status.visible = not status.text.is_empty() and not _settings_overlay
	pause_button.position = Vector2(area.x - 208, 24)
	pause_button.size = Vector2(184, 48)
	pause_button.configure(0.7)
	_pause_surface.position = pause_button.position
	_pause_surface.size = pause_button.size
	if backdrop:
		backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		backdrop.visible = show_character
		backdrop.set_active(show_character)
	if _toolbar:
		_toolbar.position = Vector2(28, area.y - 72)
		_toolbar.visible = show_character or context_is_runtime
		for button in _toolbar.get_children():
			button.disabled = context_is_runtime
			var style := Palette.panel(colors)
			style.corner_radius_top_left = 24
			style.corner_radius_top_right = 24
			style.corner_radius_bottom_left = 24
			style.corner_radius_bottom_right = 24
			button.add_theme_stylebox_override("normal", style)
			var focus := style.duplicate() as StyleBoxFlat
			focus.bg_color = Color.TRANSPARENT
			focus.border_color = colors.accent
			focus.set_border_width_all(2)
			button.add_theme_stylebox_override("focus", focus)
			button.add_theme_color_override("font_color", colors.ink)

func _animate_page(_name: String) -> void:
	if _page_tween and _page_tween.is_valid(): _page_tween.kill()
	_content.position = Vector2.ZERO
	_content.modulate.a = 1.0

func debug_snapshot() -> Dictionary:
	var value := super.debug_snapshot()
	value["world_layer"] = _world_layer
	value["settings_overlay"] = _settings_overlay
	return value
