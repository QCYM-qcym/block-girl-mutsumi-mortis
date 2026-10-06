extends Resource
## Batch-local map declarations. This is not a Foundation LevelDefinition.
@export var level_id: String = ""
@export var display_title: String = ""
@export var quality: String = "GREYBOX"
@export_multiline var intent: String = ""
@export var spawn: Vector2i = Vector2i.ZERO
@export var goal: Vector2i = Vector2i.ZERO
@export var surface_cells: Array[Vector2i] = []
@export var inner_cells: Array[Vector2i] = []
@export var platform_b_cells: Array[Vector2i] = []
@export var link_enabled: bool = false
@export var link_a: Vector2i = Vector2i(3,0)
@export var link_b: Vector2i = Vector2i(9,0)
@export var link_worlds: Array[int] = [0]
@export var gate_enabled: bool = false
