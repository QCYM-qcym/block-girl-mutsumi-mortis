extends "res://game/levels/mutsumi/batch_01/content_level.gd"
## L01-only presentation attachment. The inherited level owns every action.
const Presenter3D = preload("res://game/levels/mutsumi/batch_01/l01_3d/presenter.gd")
const ApprovedHUD = preload("res://game/shell/visual_01/hud.gd")
const UITokens = preload("res://game/shell/visual_01/tokens.gd")
var presenter: Node3D
var approved_hud: CanvasLayer
var legacy_hud: CanvasLayer
var visual_container: SubViewportContainer
var visual_viewport: SubViewport
var using_3d := true

func _create_presenter() -> Node3D:
	return Presenter3D.new()

func _ready() -> void:
	super._ready()
	for child in get_children():
		if child is CanvasLayer:
			legacy_hud = child
			break
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
	presenter = _create_presenter()
	presenter.name = "L01Presenter3D"
	visual_viewport.add_child(presenter)
	presenter.bind(graph, mover, view, content)
	approved_hud = ApprovedHUD.new()
	approved_hud.name = "ApprovedL01HUD"
	add_child(approved_hud)
	approved_hud.bind(self)
	layout()
	display_3d(true)

func display_3d(enabled: bool) -> void:
	using_3d = enabled
	board.visible = not enabled
	RenderingServer.set_default_clear_color(UITokens.COLORS.water if enabled else Color("172327"))
	if legacy_hud:
		legacy_hud.visible = not enabled
	if approved_hud:
		approved_hud.set_active(enabled)
		approved_hud.sync()
	if visual_container:
		visual_container.visible = enabled

func layout() -> void:
	# A replacement level can resize the Window before this detached view is freed.
	if not is_inside_tree():
		return
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
	if approved_hud:
		approved_hud.sync()

func reset_level() -> void:
	super.reset_level()
	if presenter:
		presenter.reset_visuals()
	if approved_hud:
		approved_hud.sync()
