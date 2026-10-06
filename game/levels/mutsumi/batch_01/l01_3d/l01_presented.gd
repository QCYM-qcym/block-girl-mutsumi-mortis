extends "res://game/levels/mutsumi/batch_01/content_level.gd"
## L01-only presentation attachment. The inherited level owns every action.
const Presenter3D = preload("res://game/levels/mutsumi/batch_01/l01_3d/presenter.gd")
var presenter: Node3D
var visual_container: SubViewportContainer
var visual_viewport: SubViewport
var using_3d := true

func _ready() -> void:
	super._ready()
	visual_container = SubViewportContainer.new()
	visual_container.name = "L01Presentation3D"
	visual_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual_container.z_index = -5
	visual_container.stretch = true
	add_child(visual_container)
	visual_viewport = SubViewport.new()
	visual_viewport.name = "PresentationViewport"
	visual_viewport.own_world_3d = true
	visual_viewport.handle_input_locally = false
	visual_viewport.msaa_3d = Viewport.MSAA_4X
	visual_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	visual_container.add_child(visual_viewport)
	presenter = Presenter3D.new()
	presenter.name = "L01Presenter3D"
	visual_viewport.add_child(presenter)
	presenter.bind(graph, mover, view, content)
	layout()
	display_3d(true)

func display_3d(enabled: bool) -> void:
	using_3d = enabled
	board.visible = not enabled
	if visual_container:
		visual_container.visible = enabled

func layout() -> void:
	super.layout()
	if visual_container:
		var area := get_viewport_rect().size
		visual_container.position = Vector2(0, 175)
		visual_container.size = Vector2(area.x, maxf(1, area.y - 315))
		presenter.sync(0.0)

func _process(delta: float) -> void:
	super._process(delta)
	if presenter:
		presenter.sync(delta)

func reset_level() -> void:
	super.reset_level()
	if presenter:
		presenter.reset_visuals()
