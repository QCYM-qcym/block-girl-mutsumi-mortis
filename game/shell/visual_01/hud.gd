extends CanvasLayer
## Read-only view of the inherited ContentLevel's existing hints and state.
const Tokens = preload("res://game/shell/visual_01/tokens.gd")
const Strip = preload("res://game/shell/visual_01/hint_strip.gd")
var root: Control
var title_label: Label
var world_label: Label
var objective_label: Label
var hint_label: Label
var footer: Label
var feedback_label: Label
var level: Node
var active := true
var _decor: Control
var _strip: Control

func _ready() -> void:
	layer = 20
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_decor = Control.new()
	_decor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_decor)
	_decor.draw.connect(_draw_panels)
	title_label = _label("", 32, true)
	world_label = _label("", 22)
	objective_label = _label("", 24)
	hint_label = _label("", 32)
	hint_label.self_modulate.a = 0.0
	_strip = Strip.new()
	root.add_child(_strip)
	footer = _label("", 22)
	feedback_label = _label("", 22)
	get_viewport().size_changed.connect(_layout)
	_layout()

func _label(text: String, pixels: int, serif: bool = false) -> Label:
	var result := Tokens.label(text, pixels, serif)
	root.add_child(result)
	return result

func bind(owner_level: Node) -> void:
	level = owner_level
	if not is_node_ready():
		await ready
	sync()

func set_active(enabled: bool) -> void:
	active = enabled
	visible = enabled

func sync() -> void:
	if not is_instance_valid(level) or not is_node_ready():
		return
	title_label.text = level.content.display_title
	world_label.text = ("表世界 · 若叶睦" if level.mover.world == 0 else "里世界 · Mortis") + "  /  " + ["NORTH", "EAST", "SOUTH", "WEST"][level.view.current]
	objective_label.text = level.hints.objective(level.mover, level.view)
	hint_label.text = level.hints.text
	hint_label.modulate.a = level.hints.alpha
	_strip.text = level.hints.text
	_strip.modulate.a = level.hints.alpha
	_strip.queue_redraw()
	footer.text = level.footer.text
	feedback_label.text = level.feedback.text
	feedback_label.visible = level.feedback.visible
	_layout()

func _layout() -> void:
	if not is_inside_tree() or root == null:
		return
	var area := get_viewport().get_visible_rect().size
	var unit := minf(area.x / 1920.0, area.y / 1080.0)
	var pad := maxf(24, 48 * unit)
	title_label.position = Vector2(pad + 16, 20)
	title_label.size = Vector2(area.x * 0.64 - pad, 48)
	title_label.add_theme_font_size_override("font_size", maxi(22, roundi(32 * unit)))
	world_label.position = Vector2(pad + 16, 58)
	world_label.size = Vector2(area.x * 0.64 - pad, 32)
	objective_label.position = Vector2(pad + 16, 106)
	objective_label.size = Vector2(area.x - pad * 2 - 32, 60)
	objective_label.add_theme_font_size_override("font_size", maxi(16, roundi(24 * unit)))
	hint_label.position = Vector2(pad, area.y - 136)
	hint_label.size = Vector2(area.x - pad * 2, 44)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", maxi(22, roundi(32 * unit)))
	_strip.position = Vector2((area.x - minf(area.x - pad * 2, maxf(480, 700 * unit))) / 2, area.y - 136)
	_strip.size = Vector2(minf(area.x - pad * 2, maxf(480, 700 * unit)), 64)
	_strip.pixels = maxi(22, roundi(32 * unit))
	footer.position = Vector2(pad, area.y - 34)
	footer.size = Vector2(area.x - pad * 2, 26)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.position = Vector2(pad, area.y - 68)
	feedback_label.size = Vector2(area.x - pad * 2, 28)
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for label in [world_label, footer, feedback_label]:
		label.add_theme_font_size_override("font_size", maxi(16, roundi(22 * unit)))
	_decor.queue_redraw()
	_strip.queue_redraw()

func _draw_panels() -> void:
	var area := get_viewport().get_visible_rect().size
	var unit := minf(area.x / 1920.0, area.y / 1080.0)
	var pad := maxf(24, 48 * unit)
	_decor.draw_rect(Rect2(pad, 16, minf(area.x - pad * 2, maxf(480, 700 * unit)), 78), Tokens.COLORS.face)
	_decor.draw_rect(Rect2(pad, 100, area.x - pad * 2, 70), Tokens.COLORS.face)
	_decor.draw_rect(Rect2(pad, 100, maxf(2, 4 * unit), 70), Tokens.COLORS.accent)
