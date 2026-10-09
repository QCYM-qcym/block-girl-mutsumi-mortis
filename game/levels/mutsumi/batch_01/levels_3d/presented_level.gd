extends "res://game/levels/mutsumi/batch_01/l01_3d/l01_presented.gd"
## Reuses the accepted attachment, HUD and native ContentLevel lifecycle.
const ContentPresenter = preload("res://game/levels/mutsumi/batch_01/levels_3d/presenter.gd")

func _create_presenter() -> Node3D:
	return ContentPresenter.new()

func _ready() -> void:
	super._ready()
	visual_container.name = "ContentPresentation3D"
	presenter.name = "ContentPresenter3D"
	approved_hud.name = "ApprovedContentHUD"
