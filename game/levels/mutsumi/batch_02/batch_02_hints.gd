extends "res://game/levels/mutsumi/p01_hints.gd"
## Text is local to L04/L05; no changes to the existing three levels' hints.
var definition: Resource

func _init(data: Resource) -> void:
	definition = data

func update(mover, view, delta: float, rotation_committed: bool) -> void:
	if mover.moves > 0: moved = true
	if mover.world == 1: shifted = true
	if rotation_committed: rotated = true
	var desired := ""
	if not moved: desired = "W A S D"
	elif mover.cell == definition.link_a:
		if mover.world == 0: desired = "Space"
		elif view.current != 1:
			desired = "Q / E    ·    鼠标左右拖动"
			rotation_hint_seen = true
	elif definition.level_id == "mutsumi_l04":
		if (mover.cell == Vector2i(0,4) and mover.world == 0) or (mover.cell == Vector2i(10,2) and mover.world == 1): desired = "Space"
	else:
		if (mover.cell == Vector2i(0,3) and mover.world == 0) or (mover.cell == Vector2i(1,2) and mover.world == 1) or (mover.cell == Vector2i(11,0) and mover.world == 1): desired = "Space"
	if mover.phase == "complete": desired = ""
	if desired != text:
		alpha = move_toward(alpha,0,delta*4)
		if alpha == 0: text = desired
	else:
		alpha = move_toward(alpha,1 if not text.is_empty() else 0,delta*4)

func objective(mover, view) -> String:
	if mover.phase == "complete": return "已到达出口。按 R 再次游玩。"
	if mover.cell == definition.link_a:
		if mover.world == 0: return "连接属于里世界。在这个共同落脚点切换到里世界。"
		if view.current != 1: return "保留里世界，转到 EAST，让连接两端相接。"
		return "连接已成立。向相接的另一端翻滚，落定后再选择出口道路。"
	if definition.level_id == "mutsumi_l04":
		if mover.cell == Vector2i(0,4) and mover.world == 0: return "前方的道路只在里世界出现。这里可以安全切换。"
		if mover.cell.x >= 9: return "桥在里世界，出口道路在表世界。共同岸边可以切换。"
	else:
		if mover.cell == Vector2i(0,3) and mover.world == 0: return "借里世界的桥前进，寻找下一处共同落脚点。"
		if mover.cell == Vector2i(1,2) and mover.world == 1: return "桥的入口属于表世界；走到连接端点后还要重新选择世界。"
		if mover.cell.x >= 9: return "踏板和门属于表世界。里世界不能开门；踏板压下后向前翻滚。"
	return definition.intent
