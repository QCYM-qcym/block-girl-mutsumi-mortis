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
func run() -> void:
	for letter in ["a","b"]:
		var baked: Dictionary = Factory.bake_game_feel(Factory.read_spec(letter))
		check(baked.ok,"exact 09 production bake_game_feel supplies canonical map "+letter)
		if not baked.ok: observations.append(baked); continue
		var level: Dictionary = baked.level
		var solved: Dictionary = Explorer.explore(level,Records.initial_state(level),Search.default_policy(1),Search.default_budget())
		check(solved.status == 0 and solved.graph.complete and solved.solution_trace.total_actions == 2,"real Solver trace requires Fall then Exit Roll "+letter)
		if solved.solution_trace == null: continue
		var driver := Driver.new()
		root.add_child(driver)
		var result: Dictionary = await driver.replay(level,solved.solution_trace,{"mode":1})
		check(result.status == 0 and result.matched_steps == 2 and result.actual_statekey == solved.solution_trace.goal_statekey,"unchanged formal mode1 API naturally completes exact A/B endpoint "+letter)
		var steps: Array = driver.call("get_step_evidence") if driver.has_method("get_step_evidence") else []
		check(steps.size() == 2,"formal step observation exposes actual completed motion "+letter)
		for i in steps.size():
			var step: Dictionary = steps[i]
			var motion: Dictionary = step.completion_evidence
			check(step.commit_delta == 1 and step.commit_signals == 1 and step.completion_received,"one natural native commit per semantic action")
			check(step.actual_state == solved.solution_trace.steps[i].expected_state and step.actual_statekey == solved.solution_trace.steps[i].resulting_statekey,"full formal state/key endpoint matches Solver")
			check(step.transition_identity == motion.transition_identity and step.transition_identity.size() == 5 and not step.is_global,"actual captured full native local identity survives COMMITTED")
			check(motion.started_order < motion.committed_order and motion.committed_order < motion.completion_order and motion.cancelled_order == 0,"STARTED -> native COMMITTED -> natural terminal; no cancellation")
			check(motion.final_statekey == step.actual_statekey and motion.final_state == step.actual_state and motion.orientation == step.actual_state.player.orientation and motion.world_id == 0 and motion.camera_quadrant == 1,"Bridge final state/orientation/world/camera agree")
			check(motion.terminal.terminal_phase == ("LANDING_SETTLED" if i == 0 else "ROLL_RESTORED"),"Fall waits for Landing; ordinary Roll waits for restored pose")
			check(not motion.frames.is_empty() and motion.frames.any(func(f):return f.phase == ("FALL" if i == 0 else "ROLL")),"real process frames witness the actual motion")
			var expected := Vector3(-4 if i == 0 else -3,1 if letter == "a" else 5,4)
			var origin: Array = motion.final_visual_pose.origin
			check(Vector3(origin[0],origin[1],origin[2]).is_equal_approx(expected) and motion.final_visual_pose == motion.expected_visual_pose,"physical final cube pose is the authored support center")
			check(step.bridge_snapshot.host_issues.is_empty() and step.bridge_snapshot.presenter.phase == "IDLE","formal Bridge is visually settled without host errors")
		observations.append({"map":letter,"level_hash":level.content_hash,"trace":solved.solution_trace,"result":result,"steps":steps})
		driver.free()
	var summary := {"checks":checks,"failures":failures,"doubles":[],"authority":"production replay(mode:1) -> same Facade -> fixed00 Bridge/CoreLab/CubePresenter/10A natural completion","display":"headless" if DisplayServer.get_name()=="headless" else "graphical","observations":observations}
	FileAccess.open(OS.get_environment("FOUNDATION_TEST_EVIDENCE").path_join("results.json"),FileAccess.WRITE).store_string(JSON.stringify(summary))
	print("BRIDGE_REAL checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
