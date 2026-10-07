extends Button
## Native Button owns interaction; its children draw the approved flat row.
const Tokens = preload("res://game/shell/visual_01/tokens.gd")
var glyph: Texture2D
var number := ""
var detail := ""
var display_text := ""
var catalog_row := false
var scale_unit := 1.0
var bracket_visible: bool:
	get: return has_focus() and not disabled
var _canvas: Control
var _title: Label
var _detail: Label
var _number: Label
var _focus_amount := 0.0
var _press_amount := 0.0
var _focus_tween: Tween
var _press_tween: Tween

func _ready() -> void:
	clip_text = true
	self_modulate.a = 0.0
	_canvas = Control.new()
	_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_canvas)
	_canvas.draw.connect(_draw_row)
	_title = Tokens.label(display_text, 32, catalog_row)
	_detail = Tokens.label(detail, 22)
	_number = Tokens.label(number, 64, true)
	# Row actions occupy one line; wrapping may otherwise cache the initial
	# zero-width Label's tall minimum before its Container assigns the row width.
	for label in [_title, _detail, _number]:
		label.clip_text = true
		label.max_lines_visible = 1
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_canvas.add_child(_title)
	_canvas.add_child(_detail)
	_canvas.add_child(_number)
	resized.connect(_layout)
	focus_entered.connect(_animate_focus)
	focus_exited.connect(_animate_focus)
	mouse_entered.connect(_animate_focus)
	mouse_exited.connect(_animate_focus)
	button_down.connect(func(): _animate_press(2.0, 0.08))
	button_up.connect(func(): _animate_press(0.0, 0.10))
	_layout()

func configure(unit: float) -> void:
	scale_unit = unit
	if is_node_ready():
		_layout()

func _layout() -> void:
	var unit := scale_unit
	_title.text = display_text
	_detail.text = detail
	_number.text = number
	_title.add_theme_font_override("font", Tokens.font(catalog_row))
	_title.max_lines_visible = 2 if catalog_row else 1
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if catalog_row else TextServer.AUTOWRAP_OFF
	var left := 76.0 * unit if catalog_row else 64.0 * unit
	var right := 40.0 * unit
	_title.add_theme_font_size_override("font_size", maxi(22, roundi((36 if catalog_row else 32) * unit)))
	_detail.add_theme_font_size_override("font_size", maxi(16, roundi(22 * unit)))
	_number.add_theme_font_size_override("font_size", maxi(36, roundi(64 * unit)))
	if catalog_row:
		left = 156 * unit
		_number.position = Vector2(30, 16) * unit
		_number.size = Vector2(94 * unit, size.y - 20 * unit)
		_title.position = Vector2(left, 16 * unit + _press_amount)
		_title.size = Vector2(maxf(1, size.x - left - right), size.y * 0.56)
		_detail.position = Vector2(left + 36 * unit, size.y * 0.65 + _press_amount)
		_detail.size = Vector2(maxf(1, size.x - left - right - 36 * unit), size.y * 0.30)
	else:
		_title.position = Vector2(left, _press_amount)
		_title.size = Vector2(maxf(1, size.x - left - right), size.y if detail.is_empty() else size.y * 0.58)
		_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_detail.position = Vector2(left, size.y * 0.59 + _press_amount)
		_detail.size = Vector2(maxf(1, size.x - left - right), size.y * 0.38)
	_detail.visible = not detail.is_empty()
	_number.visible = catalog_row
	var color: Color = Tokens.COLORS.disabled if disabled else Tokens.COLORS.ink
	for label in [_title, _detail, _number]:
		label.add_theme_color_override("font_color", color)
	_canvas.queue_redraw()

func _draw_row() -> void:
	var unit := scale_unit
	var full := Rect2(Vector2(0, _press_amount), size)
	if catalog_row:
		_canvas.draw_rect(full, Tokens.COLORS.edge)
	if (is_hovered() or has_focus()) and not disabled:
		_canvas.draw_rect(full, Tokens.COLORS.hover)
	_canvas.draw_line(Vector2(0, size.y), Vector2(size.x, size.y), Tokens.COLORS.seam, 1)
	if catalog_row:
		_canvas.draw_line(Vector2(124 * unit, 20 * unit), Vector2(124 * unit, size.y - 20 * unit), Tokens.COLORS.seam, 1)
	if glyph:
		var position := Vector2(26 * unit, (size.y - 32 * unit) / 2 + _press_amount)
		if catalog_row:
			position = Vector2(156 * unit, size.y * 0.67)
		_canvas.draw_texture_rect(glyph, Rect2(position, Vector2.ONE * 28 * unit), false,
			Tokens.COLORS.disabled if disabled else Color.WHITE)
	if not disabled and not catalog_row:
		_canvas.draw_texture_rect(Tokens.icon("arrow"), Rect2(Vector2(size.x - 48 * unit, (size.y - 24 * unit) / 2), Vector2.ONE * 24 * unit), false)
	if _focus_amount > 0.001:
		var ink: Color = Tokens.COLORS.ink
		ink.a *= _focus_amount
		var gap := 6.0 * unit + (1.0 - _focus_amount) * 4
		var length := 12.0 * unit
		_canvas.draw_rect(Rect2(0, 0, maxf(2, 4 * unit), size.y), Tokens.COLORS.accent)
		_canvas.draw_polyline(PackedVector2Array([Vector2(-gap, length), Vector2(-gap, -gap), Vector2(length, -gap)]), ink, 1.5)
		_canvas.draw_polyline(PackedVector2Array([Vector2(size.x - length, size.y + gap), Vector2(size.x + gap, size.y + gap), Vector2(size.x + gap, size.y - length)]), ink, 1.5)

func _animate_focus() -> void:
	if _focus_tween and _focus_tween.is_valid():
		_focus_tween.kill()
	_focus_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_focus_tween.tween_method(func(value: float): _focus_amount = value; _canvas.queue_redraw(),
		_focus_amount, 1.0 if has_focus() and not disabled else 0.0, 0.12)

func _animate_press(value: float, seconds: float) -> void:
	if _press_tween and _press_tween.is_valid():
		_press_tween.kill()
	_press_tween = create_tween()
	_press_tween.tween_method(func(amount: float): _press_amount = amount; _layout(), _press_amount, value, seconds)
