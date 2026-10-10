extends SceneTree
const Driver = preload("res://foundation/parity/trace_replayer.gd")
const Factory = preload("res://experiments/game_feel_01/maps/map_factory.gd")
const Explorer = preload("res://foundation/solver/state_explorer.gd")
const Search = preload("res://foundation/solver/search_records.gd")
const Records = preload("res://foundation/contracts/contract_records.gd")
var checks := 0
var failures: Array[String] = []
var observations: Array = []
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func _initialize() -> void:
	create_timer(45).timeout.connect(func():printerr("TEST_TIMEOUT");quit(2))
	call_deferred("run")
func capture(driver: Node, level: Dictionary, trace: Dictionary, box: Dictionary) -> void:
	box.result = await driver.replay(level,trace,{"mode":1,"step_timeout_ms":3000})
	if is_instance_valid(driver): box.steps = driver.get_step_evidence()
func bridge_of(driver: Node) -> Node3D:
	for child in driver.get_children():
		if child.get_script().resource_path == "res://game/feel/graphical_completion_bridge.gd": return child
	return null
func await_phase(driver: Node, phase: String) -> Node3D:
	var started := Time.get_ticks_msec()
	while Time.get_ticks_msec()-started < 3000:
		var bridge := bridge_of(driver)
		if is_instance_valid(bridge) and bridge.snapshot().presenter.get("phase","") == phase: return bridge
		await process_frame
	return null
func await_result(box: Dictionary) -> void:
	var started := Time.get_ticks_msec()
	while not box.has("result") and Time.get_ticks_msec()-started < 4000: await process_frame
func run() -> void:
	var baked: Dictionary = Factory.bake_game_feel(Factory.read_spec("a"))
	var level: Dictionary = baked.level
	var solved: Dictionary = Explorer.explore(level,Records.initial_state(level),Search.default_policy(1),Search.default_budget())
	var trace: Dictionary = solved.solution_trace
	for phase in ["FALL","LANDING"]:
		for operation in ["bridge_free","CANCEL","UNLOAD","RESET","driver_free","readd"]:
			var driver := Driver.new()
			root.add_child(driver)
			var box: Dictionary = {}
			call_deferred("capture",driver,level,trace,box)
			var bridge: Node3D = await await_phase(driver,phase)
			check(is_instance_valid(bridge),"real natural phase reached before lifecycle operation: "+phase+"/"+operation)
			if not is_instance_valid(bridge): driver.free(); continue
			var runtime: RefCounted = bridge.runtime
			var generation: int = runtime.get_generation()
			if operation == "driver_free":
				driver.free()
				await process_frame
				check(not runtime.is_loaded() and runtime.get_generation() > generation,"active driver free unloads its owned real Facade")
				check(box.get("result",{}).get("status") == 3,"active driver free resolves its awaiting consumer before instance destruction")
			elif operation == "readd":
				root.remove_child(driver)
				root.add_child(driver)
				var newer: Dictionary = {}
				call_deferred("capture",driver,level,trace,newer)
				await await_result(newer)
				await await_result(box)
				check(newer.get("result",{}).get("status") == 0 and newer.result.matched_steps == 2 and newer.steps.size() == 2,"removed/readded driver admits a fresh complete replay")
				check(box.get("result",{}).get("status") == 3,"obsolete await returns INCOMPLETE without ending new run")
				observations.append({"phase":phase,"operation":operation,"old":box,"new":newer})
				driver.free()
			else:
				if operation == "bridge_free": bridge.free()
				elif operation == "RESET": runtime.reset()
				else: runtime.interrupt(operation)
				await await_result(box)
				check(box.get("result",{}).get("status") == 2 and box.result.matched_steps == 0,"cancelled motion never counts as completed graphical step: "+phase+"/"+operation)
				check(not runtime.is_loaded(),"cleanup releases the same Facade after non-MATCH: "+phase+"/"+operation)
				observations.append({"phase":phase,"operation":operation,"outcome":box})
				driver.free()
			var recovery := Driver.new()
			root.add_child(recovery)
			var recovered: Dictionary = await recovery.replay(level,trace,{"mode":1})
			check(recovered.status == 0 and recovered.matched_steps == 2,"old lifecycle callbacks cannot poison a subsequent fresh replay")
			recovery.free()
	var summary := {"checks":checks,"failures":failures,"doubles":[],"authority":"real formal mode1/00 Bridge/Facade/10A; deliberate lifecycle fault injection","observations":observations}
	FileAccess.open(OS.get_environment("FOUNDATION_TEST_EVIDENCE").path_join("results.json"),FileAccess.WRITE).store_string(JSON.stringify(summary))
	print("BRIDGE_LIFECYCLE checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
