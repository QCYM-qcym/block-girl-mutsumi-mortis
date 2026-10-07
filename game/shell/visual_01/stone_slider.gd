extends HSlider
const Tokens = preload("res://game/shell/visual_01/tokens.gd")
var bracket_visible: bool:
	get: return has_focus()

func _ready() -> void:
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)

func _draw() -> void:
	if has_focus():
		draw_rect(Rect2(-8, -34, size.x + 16, size.y + 38), Tokens.COLORS.hover, false, 1)
		draw_polyline(PackedVector2Array([Vector2(-8, -24), Vector2(-8, -38), Vector2(8, -38)]), Tokens.COLORS.ink, 1.5)
		draw_polyline(PackedVector2Array([Vector2(size.x - 8, size.y + 8), Vector2(size.x + 8, size.y + 8), Vector2(size.x + 8, size.y - 8)]), Tokens.COLORS.ink, 1.5)
