extends CheckButton
const Tokens = preload("res://game/shell/visual_01/tokens.gd")
var bracket_visible: bool:
	get: return has_focus() and not disabled

func _ready() -> void:
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)

func _draw() -> void:
	draw_line(Vector2(0, size.y), Vector2(size.x, size.y), Tokens.COLORS.seam, 1)
	if bracket_visible:
		draw_polyline(PackedVector2Array([Vector2(-5, 10), Vector2(-5, -5), Vector2(10, -5)]), Tokens.COLORS.ink, 1.5)
		draw_polyline(PackedVector2Array([Vector2(size.x - 10, size.y + 5), Vector2(size.x + 5, size.y + 5), Vector2(size.x + 5, size.y - 10)]), Tokens.COLORS.ink, 1.5)
