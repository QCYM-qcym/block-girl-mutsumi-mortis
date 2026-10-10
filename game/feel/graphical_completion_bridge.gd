extends Node3D
## Registered formal graphical view; the bound Facade is the sole gameplay owner.
const Lab=preload("res://experiments/game_feel_01/host/core_lab.gd")
const Key=preload("res://foundation/contracts/state_key.gd")
signal motion_completed(identity:Dictionary,evidence:Dictionary)
signal motion_cancelled(identity:Dictionary,reason:String)
var lab:Node3D
var runtime:RefCounted
var _records:Array=[]
var _connections:Array=[]
var _closed:=false
var _serial:=0

func bind_runtime(facade:RefCounted,level:Dictionary)->Dictionary:
	if runtime!=null or not is_inside_tree() or facade==null or not facade.is_loaded() or facade.get_level()!=level:
		return {"ok":false,"issues":[{"path":"bridge.bind_runtime","message":"Requires the same loaded formal Facade and canonical Level."}]}
	runtime=facade
	lab=Lab.new()
	lab.name="FormalGraphicalView"
	lab.runtime=facade
	lab.external_runtime=true
	add_child(lab)
	# CoreLab already owns real event-to-sampler wiring and natural native finish.
	_connect(runtime.game_feel_event,_on_event)
	_connect(runtime.committed,_on_committed)
	_connect(lab.presenter.motion_completed,_on_terminal)
	_connect(lab.presenter.motion_cancelled,_on_cancelled)
	return {"ok":lab.host_issues.is_empty(),"issues":lab.host_issues.duplicate(true)}

func _connect(value:Signal,callback:Callable)->void:
	value.connect(callback)
	_connections.append([value,callback])

func _event_order()->int:
	_serial+=1
	return _serial

func _find(identity:Dictionary)->Dictionary:
	for record in _records:
		if record.transition_identity==identity: return record
	return {}

func _current(identity:Dictionary)->bool:
	if runtime==null or _closed: return false
	var scope:Dictionary=runtime.get_presentation_scope()
	for key in ["session_id","level_run_id","generation"]:
		if identity.get(key)!=scope.get(key): return false
	return true

func _on_event(event:Dictionary)->void:
	if _closed: return
	var identity:Variant=event.get("transition_identity")
	if not identity is Dictionary or not _current(identity): return
	if event.phase=="STARTED":
		if not _find(identity).is_empty(): return
		_records.append({"transition_identity":identity.duplicate(true),"presentation_identity":event.presentation_identity.duplicate(true),"source_pose":event.source_pose.duplicate(true),"target_pose":event.target_pose.duplicate(true),"semantic":event.semantic,"started_order":_event_order(),"committed_order":0,"completion_order":0,"cancelled_order":0,"frames":[],"terminal":{},"delivered":false,"result":event.result.duplicate(true)})
	elif event.phase=="COMMITTED":
		var record:=_find(identity)
		if not record.is_empty() and record.committed_order==0: record.committed_order=_event_order()

func _process(_delta:float)->void:
	if _closed or lab==null or runtime==null or not runtime.is_loaded(): return
	var view:Dictionary=lab.presenter.snapshot()
	if view.transition_identity.is_empty(): return
	var record:=_find(view.transition_identity)
	if record.is_empty(): return
	record.frames.append({"phase":view.phase,"elapsed":view.elapsed,"pose":_pose(lab.actor.transform),"statekey":Key.build(runtime.get_level(),runtime.get_state()).get("key","")})

func _on_terminal(identity:Dictionary,evidence:Dictionary)->void:
	if not _current(identity): return
	var record:=_find(identity)
	if record.is_empty() or record.delivered or record.cancelled_order!=0: return
	record.terminal=evidence.duplicate(true)
	# Roll terminal arrives inside the COMMITTED event dispatch. Wait for the
	# actual Facade committed notification, never substitute a scheduled timer.
	_flush(record)

func _on_committed(_state:Dictionary)->void:
	for record in _records:
		if not record.terminal.is_empty(): _flush(record)

func _flush(record:Dictionary)->void:
	if record.delivered or record.committed_order==0 or record.cancelled_order!=0 or record.terminal.is_empty() or not _current(record.transition_identity): return
	var state:Dictionary=runtime.get_state()
	var projected:Dictionary=lab.project_pose(state.player)
	if not projected.ok or state.player!=record.target_pose or not lab.actor.transform.is_equal_approx(projected.transform) or lab.presenter.snapshot().phase!="IDLE": return
	record.delivered=true
	record.completion_order=_event_order()
	record.final_state=state.duplicate(true)
	record.final_statekey=Key.build(runtime.get_level(),state).get("key","")
	record.commit_count=runtime.get_commit_count()
	record.final_visual_pose=_pose(lab.actor.transform)
	record.expected_visual_pose=_pose(projected.transform)
	record.camera_quadrant=state.camera_quadrant
	record.world_id=state.player.location.layer
	record.orientation=state.player.orientation
	motion_completed.emit(record.transition_identity.duplicate(true),record.duplicate(true))

func _on_cancelled(identity:Dictionary,reason:String)->void:
	var record:=_find(identity)
	if _closed or record.is_empty() or record.delivered or record.cancelled_order!=0: return
	record.cancelled_order=_event_order()
	record.cancellation_reason=reason
	motion_cancelled.emit(identity.duplicate(true),reason)

func snapshot()->Dictionary:
	return {"records":_records.duplicate(true),"scope":runtime.get_presentation_scope() if runtime!=null else {},"presenter":lab.presenter.snapshot() if is_instance_valid(lab) else {},"host_issues":lab.host_issues.duplicate(true) if is_instance_valid(lab) else [],"closed":_closed}

func clear_previews()->void:
	# Legacy Replayer cleanup name: teardown owns the visual lifecycle here.
	close()

func close()->void:
	if _closed: return
	if is_instance_valid(lab): lab._close("UNLOAD")
	_closed=true
	for pair in _connections:
		if pair[0].is_connected(pair[1]): pair[0].disconnect(pair[1])
	_connections.clear()

func _exit_tree()->void: close()

static func _pose(value:Transform3D)->Dictionary:
	return {"origin":[value.origin.x,value.origin.y,value.origin.z],"basis":[[value.basis.x.x,value.basis.x.y,value.basis.x.z],[value.basis.y.x,value.basis.y.y,value.basis.y.z],[value.basis.z.x,value.basis.z.y,value.basis.z.z]]}
