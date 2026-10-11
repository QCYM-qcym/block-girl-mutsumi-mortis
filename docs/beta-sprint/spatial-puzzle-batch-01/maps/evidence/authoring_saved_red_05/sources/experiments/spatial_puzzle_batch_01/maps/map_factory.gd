extends RefCounted
## Saved authoring is authoritative; teaching metadata and witness actions are independent.
const Saved=preload("res://experiments/spatial_puzzle_batch_01/maps/saved_authoring.gd")

static func ids()->Array[StringName]:
	return [&"world_shift_gate_lab",&"orientation_loop_lab",&"face_lock_lab",&"perspective_fork_lab",&"rubik_spatial_puzzle_01"]

static func bake(id:StringName)->Dictionary:
	return Saved.bake(id)

static func describe(id:StringName)->Dictionary:
	match id:
		&"orientation_loop_lab":return {"title":"六面回环","objective":"比较不同路线抵达同一平台时的六面，再走向终点。","hint":"回到同一格，朝下的面也可能不同。"}
		&"perspective_fork_lab":return {"title":"视角岔路","objective":"从标记边缘探索两个视角，落地后沿道路到达终点。","hint":"F 始终向标记边缘前进；尝试改变观察方向。"}
		&"world_shift_gate_lab":return {"title":"世界转换点","objective":"在合法转换点进入另一世界。","hint":"普通道路不是转换点。"}
		&"face_lock_lab":return {"title":"接触之面","objective":"让指定局部面接触感应台。","hint":"位置正确还不够，观察朝下的面。"}
		&"rubik_spatial_puzzle_01":return {"title":"六面归位","objective":"调整姿态、激活转换点，再从另一世界找到归途。","hint":"先理解脚下的面，再理解眼前的路。"}
	return {"title":"未知实验","objective":"","hint":""}

static func witnesses(id:StringName)->Dictionary:
	if id==&"orientation_loop_lab":
		return {"route_a":_moves([0,3]),"route_b":_moves([3,0]),"closed_loop":_moves([0,3,2,1]),"solution_a":_moves([0,3,0]),"solution_b":_moves([3,0,0]),"solution_after_loop":_moves([0,3,2,1,0,3,0])}
	if id==&"perspective_fork_lab":
		var east:Array=[{"kind":9,"camera_quadrant":1},{"kind":0,"face_axis":2}]
		east.append_array(_moves([0]))
		var south:Array=[{"kind":9,"camera_quadrant":2},{"kind":0,"face_axis":2}]
		south.append_array(_moves([0]))
		south.append_array([{"kind":9,"camera_quadrant":0},{"kind":0,"face_axis":0},{"kind":9,"camera_quadrant":1},{"kind":0,"face_axis":2},{"kind":0,"face_axis":0}])
		return {"solution_east":east,"solution_south":south}
	if id==&"world_shift_gate_lab":
		return {"solution": [{"kind":0,"face_axis":0},{"kind":1},{"kind":0,"face_axis":3}]}
	if id==&"face_lock_lab":
		var actions:Array=_moves([3,0,1,2])
		actions.append({"kind":1})
		return {"wrong_face":_moves([0,3]),"correct_face":_moves([3,0]),"solution":actions}
	if id==&"rubik_spatial_puzzle_01":
		var prefix:Array=_moves([3,0,1,2])
		prefix.append({"kind":1})
		var a:Array=prefix.duplicate(true)
		a.append_array(witnesses(&"perspective_fork_lab").solution_east)
		var b:Array=prefix.duplicate(true)
		b.append_array(witnesses(&"perspective_fork_lab").solution_south)
		return {"wrong_face":_moves([0,3]),"correct_face":_moves([3,0]),"solution_east":a,"solution_south":b}
	return {}

static func _moves(axes:Array)->Array:
	var actions:Array=[]
	for axis in axes:actions.append({"kind":0,"face_axis":axis})
	return actions
