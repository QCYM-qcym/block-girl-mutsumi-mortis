extends HSlider
const Tokens = preload("res://game/shell/visual_01/tokens.gd")
var _palette: Dictionary = {}
var bracket_visible: bool:
	get: return has_focus()

func _ready() -> void:
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)

func _draw() -> void:
	if has_focus():
		draw_rect(Rect2(-8, -34, size.x + 16, size.y + 38), _color("hover"), false, 1)
		draw_polyline(PackedVector2Array([Vector2(-8, -24), Vector2(-8, -38), Vector2(8, -38)]), _color("ink"), 1.5)
		draw_polyline(PackedVector2Array([Vector2(size.x - 8, size.y + 8), Vector2(size.x + 8, size.y + 8), Vector2(size.x + 8, size.y - 8)]), _color("ink"), 1.5)

func _color(role: String) -> Color:
	return _palette.get(role,Tokens.COLORS[role])

func set_palette(value: Dictionary) -> void:
	_palette = value.duplicate()
	add_theme_stylebox_override("slider",Tokens.rail(_color("seam")))
	for role in ["grabber_area","grabber_area_highlight"]:
		add_theme_stylebox_override(role,Tokens.rail(_color("ink")))
	var source := Tokens.icon("slider_grab").get_image()
	source.convert(Image.FORMAT_RGBA8)
	for y in source.get_height():
		for x in source.get_width():
			var color := _color("ink")
			color.a = source.get_pixel(x,y).a
			source.set_pixel(x,y,color)
	var icon := ImageTexture.create_from_image(source)
	add_theme_icon_override("grabber",icon)
	add_theme_icon_override("grabber_highlight",icon)
	queue_redraw()
