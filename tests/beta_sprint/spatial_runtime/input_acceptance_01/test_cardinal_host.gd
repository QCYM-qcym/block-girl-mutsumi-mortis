extends SceneTree
## Headless actual Host/Presenter/frame/Tween lifecycle; never graphical or Human QA evidence.
const Host = preload("res://experiments/spatial_puzzle_batch_01/host/spatial_lab.gd")
const Maps = preload("res://experiments/spatial_puzzle_batch_01/maps/map_factory.gd")
const Key = preload("res://foundation/contracts/state_key.gd")
const Kernel = preload("res://foundation/rules/puzzle_rule_kernel.gd")
const Rules = preload("res://foundation/rules/rule_records.gd")
var checks := 0
var failures: Array[String] = []
var rows: Array[Dictionary] = []
var host: Node3D
var starts: Array = []
var natural_completions: Array = []
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func _initialize() -> void:
	create_timer(150).timeout.connect(func(): printerr("CARDINAL_HOST_TIMEOUT"); quit(2))
	call_deferred("run")
func settle() -> Dictionary:
	var deadline := Time.get_ticks_msec()+5000
	var samples := 0
	var started := Time.get_ticks_msec()
	while Time.get_ticks_msec() < deadline:
		if host.runtime.is_idle() and host.presenter.snapshot().phase == "IDLE":
			return {"ok":true,"frames":samples,"elapsed_ms":Time.get_ticks_msec()-started}
		samples += 1
		await process_frame
	check(false,"formal natural completion timeout")
	return {"ok":false,"frames":samples,"elapsed_ms":Time.get_ticks_msec()-started}
func run() -> void:
	host = Host.new()
	host.lab_id = &"world_shift_gate_lab"
	root.add_child(host)
	await process_frame
	check(host.runtime.is_loaded(),"actual saved Gate loaded by official Host")
	if not host.runtime.is_loaded(): _finish(); return
	host.runtime.transition_started.connect(func(_r,t,g,b): starts.append([t,g,b]))
	host.presenter.motion_completed.connect(func(identity,e): natural_completions.append({"identity":identity,"evidence":e}))
	var level: Dictionary = host.runtime.get_level()
	var witness: Array = Maps.witnesses(&"world_shift_gate_lab").solution
	for prefix in [0,1,2,3]:
		for quadrant in 4:
			var accepted := 0
			var axes: Array[int] = []
			for direction in [Vector2.UP,Vector2.LEFT,Vector2.DOWN,Vector2.RIGHT]:
				host.reset_lab()
				for index in prefix:
					check(host.runtime.request_action(witness[index]).status == 0,"real official witness prefix")
					await settle()
				var physical_before: Dictionary = host.runtime.get_state()
				check(host.runtime.request_action({"kind":9,"camera_quadrant":quadrant}).status == 0,"formal camera action")
				await settle()
				var before: Dictionary = host.runtime.get_state()
				check(before.player == physical_before.player and before.world_orientations == physical_before.world_orientations,"Camera preserves physical pose")
				var count: int = host.runtime.get_commit_count()
				var started_count := starts.size()
				var completed_count := natural_completions.size()
				var result: Dictionary = host.runtime.request_move(direction)
				var phase: String = host.presenter.snapshot().phase
				axes.append(result.action.face_axis)
				check(result == Kernel.evaluate_action(level,before,result.action,Rules.idle_context()),"actual input retains formal Kernel permission")
				var timing: Dictionary = await settle()
				var after: Dictionary = host.runtime.get_state()
				var captured: Array = starts[-1] if starts.size()>started_count else []
				if result.status == 0 and result.changed:
					accepted += 1
					check(phase == "ROLL" and starts.size() == started_count+1 and not captured[2],"real local Roll starts")
					check(timing.ok and timing.frames>0 and natural_completions.size() == completed_count+1,"natural Presenter frames and completion")
					check(after == result.next_state and host.runtime.get_commit_count() == count+1,"exactly one authoritative commit")
					var identity: Dictionary = natural_completions[-1].identity
					check(host.runtime.finish_transition(identity).ignored and host.runtime.get_commit_count() == count+1,"late actual completion identity ignored")
				else:
					check(result.status == 1 and before == after and Key.build(level,before).key == Key.build(level,after).key and host.runtime.get_commit_count() == count,"rejected edge cannot move or commit")
					check(starts.size() == started_count,"rejected edge has no authoritative transition")
				rows.append({"prefix":prefix,"layer":before.player.location.layer,"quadrant":quadrant,"input":str(direction),"action":result.action,"status":result.status,"before_key":Key.build(level,before).key,"after_key":Key.build(level,after).key,"start_token_generation_global":captured,"start_phase":phase,"commit_delta":host.runtime.get_commit_count()-count,"natural_wait":timing})
				host.presenter.release_edge_intent()
			check(axes.has(0) and axes.has(1) and axes.has(2) and axes.has(3),"real Host all four cardinal axes")
			check(accepted == 1,"real Host exactly one legal road reachable at every camera/position")
	check(host.host_issues.is_empty(),"official Host issues empty")
	host.queue_free()
	host = null
	await process_frame
	await process_frame
	_finish()
func _finish() -> void:
	FileAccess.open(OS.get_environment("FOUNDATION_TEST_EVIDENCE").path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"doubles":[],"rows":rows,"mode":"HEADLESS_NATURAL_HOST_NOT_GRAPHICAL_QA"},"\t"))
	print("CARDINAL_HOST checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
