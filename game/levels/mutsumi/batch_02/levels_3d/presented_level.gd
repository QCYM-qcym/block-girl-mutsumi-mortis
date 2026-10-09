extends "res://game/levels/mutsumi/batch_02/batch_02_level.gd"
## Batch02 keeps its native lifecycle/hints; only its presentation factory varies.
const BatchPresenter = preload("res://game/levels/mutsumi/batch_02/levels_3d/presenter.gd")

func _create_presenter() -> Node3D:
	return BatchPresenter.new()
