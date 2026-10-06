extends "res://game/levels/mutsumi/p01_hints.gd"
var definition: Resource

func _init(data: Resource) -> void:
	definition = data

func update(mover, view, delta: float, rotation_committed: bool) -> void:
	if definition.level_id == "mutsumi_l01":
		super.update(mover, view, delta, rotation_committed)
		return
	if mover.moves > 0: moved = true
	if mover.world == 1: shifted = true
	if rotation_committed: rotated = true
	var desired = ""
	if not moved: desired = "W A S D"
	elif definition.level_id == "mutsumi_l02":
		if (mover.cell == Vector2i(0,3) and mover.world == 0) or (mover.cell == Vector2i(1,1) and mover.world == 1): desired = "Space"
	elif mover.cell == definition.link_a and view.current != 1:
		desired = "Q / E    ·    鼠标左右拖动"
		rotation_hint_seen = true
	if mover.cell == definition.goal and mover.world == 1: desired = "Space"
	if mover.phase == "complete": desired = ""
	if desired != text:
		alpha = move_toward(alpha, 0, delta*4)
		if alpha == 0: text = desired
	else:
		alpha = move_toward(alpha, 1 if not text.is_empty() else 0, delta*4)

func objective(mover, view) -> String:
	if mover.phase == "complete": return "已到达出口。按 R 可以重新开始。"
	if definition.level_id == "mutsumi_l01":
		if mover.cell.x >= 9:
			return "出口属于表世界。踏上圆形踏板，在门打开时向前翻滚。"
		if mover.cell == Vector2i(3,0):
			return "转动视角，寻找两个标记相接的位置；里世界的 EAST 视角可以通过。"
		if mover.cell == Vector2i(0,2) and mover.world == 0:
			return "前方断路。这里在两个世界都能落脚，试着切换到里世界。"
	elif definition.level_id == "mutsumi_l02":
		if mover.cell == Vector2i(0,3) and mover.world == 0:
			return "前方的桥只在里世界出现。在岸边按 Space 切换。"
		if mover.cell == Vector2i(1,1) and mover.world == 1:
			return "已到达另一岸。前往出口的道路只在表世界出现。"
		if mover.world == 1: return "沿里世界的桥前进；没有另一世界地面的格子不能切换。"
	elif mover.cell == definition.link_a:
		if mover.world == 1: return "这对连接标记属于表世界。先按 Space 返回表世界。"
		return "两个圆点是连接端点。用 Q / E 转到 EAST，然后向相接的另一端翻滚。"
	if mover.cell == definition.goal and mover.world == 1:
		return "出口属于表世界。按 Space 返回后即可完成。"
	return definition.intent
