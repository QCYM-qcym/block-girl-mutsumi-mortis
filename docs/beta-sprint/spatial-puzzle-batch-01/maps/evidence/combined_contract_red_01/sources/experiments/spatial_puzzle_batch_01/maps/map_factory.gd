extends RefCounted
## Owner09 author data only. Every acceptance result comes from the real Baker.
const Baker=preload("res://foundation/level/level_baker.gd")
const Geometry=preload("res://foundation/spatial/surface_geometry.gd")
const Records=preload("res://foundation/contracts/contract_records.gd")

static func ids()->Array[StringName]:
	return [&"world_shift_gate_lab",&"orientation_loop_lab",&"face_lock_lab",&"perspective_fork_lab",&"rubik_spatial_puzzle_01"]

static func bake(id:StringName)->Dictionary:
	return Baker.bake(authoring(id),{"max_configurations":4096,"max_checks":100000})

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

static func authoring(id:StringName)->Dictionary:
	if id in [&"world_shift_gate_lab",&"face_lock_lab",&"rubik_spatial_puzzle_01"]:
		return _gated_map(id)
	if id not in ids():return {"level_id":id}
	var l:Dictionary=_base(id)
	if id==&"orientation_loop_lab":
		_add(l,&"source",Vector3i(0,4,0))
		_add(l,&"east",Vector3i(2,4,0))
		_add(l,&"corner",Vector3i(2,4,2))
		_add(l,&"south",Vector3i(0,4,2))
		_add(l,&"goal",Vector3i(8,0,10))
		l.camera_initial_quadrant=0
		var exit_path:Dictionary=_fall(&"loop_exit",&"corner/TOP",&"goal/TOP",0,Vector3i.ZERO,0)
		exit_path.source_edge=0
		exit_path.trajectory={"trajectory_version":"pfall.departure_cubic.v1","departure_points2":[Vector3i(2,6,2),Vector3i(4,6,2)],"descent_control_points2":[Vector3i(4,6,2),Vector3i(6,6,2),Vector3i(8,4,10),Vector3i(8,2,10)]}
		l.perspective_falls.append(exit_path)
	else:
		_add(l,&"source",Vector3i(0,4,0))
		_add(l,&"target_a",Vector3i(-6,0,8))
		_add(l,&"goal",Vector3i(-4,0,8))
		_add(l,&"target_b",Vector3i(-6,0,-12))
		_add(l,&"return",Vector3i(-4,0,-12))
		l.perspective_falls.append(_fall(&"fork_a",&"source/TOP",&"target_a/TOP",1,Vector3i.ZERO,8))
		l.perspective_falls.append(_fall(&"fork_b",&"source/TOP",&"target_b/TOP",2,Vector3i.ZERO,-12))
		var recovery:Dictionary=_fall(&"return_path",&"return/TOP",&"source/TOP",0,Vector3i.ZERO,0)
		recovery.source_edge=0
		recovery.trajectory={"trajectory_version":"pfall.departure_cubic.v1","departure_points2":[Vector3i(-4,2,-12),Vector3i(-2,2,-12)],"descent_control_points2":[Vector3i(-2,2,-12),Vector3i(0,2,-12),Vector3i(0,8,0),Vector3i(0,6,0)]}
		l.perspective_falls.append(recovery)
	return l

static func _base(id:StringName)->Dictionary:
	var worlds:Array=[]
	for layer in [0,1]:worlds.append({"layer":layer,"pivot2":Vector3i.ZERO,"initial_orientation":0,"allowed_states":[0],"allowed_rotation_deltas":[],"allowed_rotation_intents":[]})
	return {"schema_version":3,"contract_version":"foundation.game_feel.v2","orientation_version":"cube24.v1","rule_version":"foundation.rules.game_feel.v2","level_id":id,"cell_size":1,"worlds":worlds,"cubes":[],"faces":[],"groups":[],"celestial":{"slots":[{"slot_id":&"sky","position2":Vector3i(0,30,0)}],"slot_order":[&"sky"],"wrap":false,"initial_slot_id":&"sky","edges":[]},"mechanisms":[],"face_transitions":[],"shift_compatibilities":[0],"spawn":Records.make_player_state(Records.make_player_location(0,&"source",4),0),"goal":{"face_id":&"goal/TOP","required_flags":[]},"flag_definitions":[],"build_info":{},"camera_initial_quadrant":1,"perspective_falls":[]}

static func _add(level:Dictionary,id:StringName,position:Vector3i,layer:int=0,walkable:bool=true)->void:
	level.cubes.append({"cube_id":id,"layer":layer,"center2":position,"orientation":0,"group_id":&"","occludes_light":true,"tags":[]})
	for face in Geometry.make_face_nodes(id):
		face.walkable=walkable and face.face==4
		level.faces.append(face)

static func _fall(id:StringName,source:StringName,target:StringName,quadrant:int,offset:Vector3i,z:int)->Dictionary:
	return {"connection_id":id,"source_face_id":source,"source_edge":2,"target_face_id":target,"allowed_camera_quadrants":[quadrant],"allowed_world_orientations":[0],"required_flags":[],"trajectory":{"trajectory_version":"pfall.departure_cubic.v1","departure_points2":[Vector3i(0,6,0)+offset,Vector3i(-2,6,0)+offset],"descent_control_points2":[Vector3i(-2,6,0)+offset,Vector3i(-4,6,0)+offset,Vector3i(-6,4,z)+offset,Vector3i(-6,2,z)+offset]},"orientation_policy":&"PRESERVE","motion_profile_id":StringName(String(id)+"_cubic"),"presentation_duration_ms":600}

static func _moves(axes:Array)->Array:
	var actions:Array=[]
	for axis in axes:actions.append({"kind":0,"face_axis":axis})
	return actions

static func _gated_map(id:StringName)->Dictionary:
	var l:Dictionary=_base(id)
	l.schema_version=4
	l.contract_version="foundation.spatial_puzzle.v1"
	l.rule_version="foundation.rules.spatial_puzzle.v1"
	l["shift_gates"]=[]
	l["face_locks"]=[]
	_add(l,&"source",Vector3i(0,4,0))
	if id==&"world_shift_gate_lab":
		_add(l,&"gate",Vector3i(2,4,0))
		_add(l,&"inner_gate",Vector3i(2,4,0),1)
		_add(l,&"goal",Vector3i(2,4,2),1)
		_add(l,&"roof",Vector3i(2,12,0),0,false)
		l.shift_gates=[_gate(&"enter",&"gate/TOP",&"inner_gate/TOP"),_gate(&"leave",&"inner_gate/TOP",&"gate/TOP")]
		return l
	_add(l,&"east",Vector3i(2,4,0))
	_add(l,&"corner",Vector3i(2,4,2))
	_add(l,&"south",Vector3i(0,4,2))
	_add(l,&"roof",Vector3i(0,12,0),0,false)
	l.mechanisms=[{"mechanism_id":&"contact_lock","face_id":&"corner/TOP","trigger":&"ENTER","action":{"kind":5,"mechanism_id":&"contact_lock"},"priority":0,"initial_state":&"idle","allowed_states":[&"idle",&"latched"]}]
	l.face_locks=[{"mechanism_id":&"contact_lock","required_local_face":3,"activation_mode":&"LATCH_ON_SUCCESS","latched_state":&"latched"}]
	for face in l.faces:
		if face.face_id==&"corner/TOP":face.mechanism_ids.append(&"contact_lock")
	var inner_id:StringName=&"goal" if id==&"face_lock_lab" else &"inner_source"
	_add(l,inner_id,Vector3i(0,4,0),1)
	var enter:Dictionary=_gate(&"enter",&"source/TOP",StringName(String(inner_id)+"/TOP"))
	enter.required_mechanism_states=[{"mechanism_id":&"contact_lock","state":&"latched"}]
	l.shift_gates=[enter,_gate(&"leave",StringName(String(inner_id)+"/TOP"),&"source/TOP")]
	if id==&"rubik_spatial_puzzle_01":
		var fork:Dictionary=authoring(&"perspective_fork_lab")
		for cube in fork.cubes:
			if cube.cube_id!=&"source":_add(l,cube.cube_id,cube.center2,1)
		for fall in fork.perspective_falls:
			if fall.source_face_id==&"source/TOP":fall.source_face_id=&"inner_source/TOP"
			if fall.target_face_id==&"source/TOP":fall.target_face_id=&"inner_source/TOP"
			l.perspective_falls.append(fall)
	return l

static func _gate(id:StringName,source:StringName,target:StringName)->Dictionary:
	return {"gate_id":id,"source_face_id":source,"target_face_id":target,"required_flags":[],"required_mechanism_states":[]}
