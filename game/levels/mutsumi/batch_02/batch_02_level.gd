extends "res://game/levels/mutsumi/batch_01/l01_3d/l01_presented.gd"
## Batch-local content attachment. All runtime and presentation rules are inherited.
const GenericPresenter = preload("res://game/levels/mutsumi/batch_01/levels_3d/presenter.gd")
const BatchHints = preload("res://game/levels/mutsumi/batch_02/batch_02_hints.gd")

func _create_presenter() -> Node3D:
	return super._create_presenter() if content.gate_enabled else GenericPresenter.new()

func _ready() -> void:
	super._ready()
	hints = BatchHints.new(content)
	hints.reset()
	visual_container.name = "Batch02Presentation3D"
	presenter.name = "Batch02Presenter3D"
	approved_hud.name = "Batch02HUD"
	refresh()
	approved_hud.sync()
