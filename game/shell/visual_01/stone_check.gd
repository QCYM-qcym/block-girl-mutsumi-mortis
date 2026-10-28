extends CheckButton
const Tokens = preload("res://game/shell/visual_01/tokens.gd")
const Palette = preload("res://game/shell/visual_02/palette.gd")
var _palette: Dictionary = {}
var bracket_visible: bool:
	get: return has_focus() and not disabled

func _ready() -> void:
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)

func _draw() -> void:
	draw_line(Vector2(0, size.y), Vector2(size.x, size.y), _color("seam"), 1)
	if bracket_visible:
		draw_polyline(PackedVector2Array([Vector2(-5, 10), Vector2(-5, -5), Vector2(10, -5)]), _color("ink"), 1.5)
		draw_polyline(PackedVector2Array([Vector2(size.x - 10, size.y + 5), Vector2(size.x + 5, size.y + 5), Vector2(size.x + 5, size.y - 10)]), _color("ink"), 1.5)

func _color(role: String) -> Color:
	return _palette.get(role,Tokens.COLORS[role])

func set_palette(value: Dictionary) -> void:
	_palette = value.duplicate()
	for role in ["font_color","font_hover_color","font_focus_color","font_pressed_color"]:
		add_theme_color_override(role,_color("ink"))
	add_theme_color_override("font_disabled_color",_color("disabled"))
	add_theme_stylebox_override("hover",Tokens.flat(_color("hover")))
	for state in ["checked","unchecked"]:
		add_theme_icon_override(state,Palette.control_icon(Tokens.icon(state),_palette))
	queue_redraw()
