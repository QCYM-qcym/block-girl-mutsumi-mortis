extends "res://game/levels/mutsumi/p01_another_world.gd"
const ContentState = preload("res://game/levels/mutsumi/batch_01/content_state.gd")
const ContentBoard = preload("res://game/levels/mutsumi/batch_01/content_board.gd")
const ContentHints = preload("res://game/levels/mutsumi/batch_01/content_hints.gd")
@export var content: Resource
var objective_label: Label

func _ready() -> void:
	graph = ContentState.new()
	graph.configure(content)
	mover = Movement.new(graph, view)
	# The inherited board is an unbuilt node; release it before using this map's board.
	board.player.free()
	board.free()
	board = ContentBoard.new()
	hints = ContentHints.new(content)
	super._ready()
	get_window().title = "方块少女 · " + content.display_title
	for child in get_children():
		if child is CanvasLayer:
			child.get_child(0).text = content.display_title + ("  /  灰盒试玩" if content.quality == "GREYBOX" else "")
			objective_label = label(child, 16)
			objective_label.position = Vector2(33,100)
			objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			break
	debug.position.y = 175
	completion.title.text = content.display_title + "\n\n关卡完成\n\n[R] 再次游玩"
	layout()
	refresh()

func layout() -> void:
	super.layout()
	if objective_label:
		objective_label.size = Vector2(get_viewport_rect().size.x-66,64)

func refresh() -> void:
	super.refresh()
	footer.text = "WASD  翻滚    Q / E  视角    Space  世界    R  重置    M  声音"
	if objective_label: objective_label.text = hints.objective(mover,view)
