extends "res://tests/playtest/test_batch_01_runtime.gd"
## Reuses delivered native input recipes, not a Solver or Replay implementation.
const Store = preload("res://game/shell/save_store.gd")
const Recipes = "res://tests/beta_sprint/shell_batch_02/delivered_routes.json"
var evidence := ""
var shell: Node
var rows: Array = []
var native_commits: Array = []
var goal_events := 0
func snapshot() -> Dictionary:
	return {"id": game.content.level_id, "cell": str(game.mover.cell), "world": game.mover.world,
		"orientation": game.mover.orientation.key(), "view": game.view.current, "goal": game.graph.complete,
		"phase": game.mover.phase, "moves": game.mover.moves}
func observe_commit() -> void:
	native_commits.append(snapshot())
func shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(evidence.path_join(game.content.level_id + "_" + label + ".png"))
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): evidence = arg.trim_prefix("--evidence=")
	check(DisplayServer.get_name() == "Windows", "real legacy graphical renderer")
	var ids: Array = ["mutsumi_l01", "mutsumi_l02", "mutsumi_l03", "mutsumi_l04", "mutsumi_l05"]
	var save_path := "user://beta_sprint/v2_quality_legacy_focused.json"
	var store := Store.new(save_path, ids[0])
	var fixture := store.defaults()
	fixture.has_progress = true
	fixture.unlocked = ids.duplicate()
	fixture.recent = ids[0]
	check(store.save(fixture), "explicit already-unlocked save setup; no gameplay state writes")
	shell = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	shell.save_path = save_path
	root.add_child(shell)
	shell.adapter.completed.connect(func(): goal_events += 1)
	await delay(0.2)
	var recipes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Recipes))
	for id in ids:
		var first_check := checks
		var first_failure := failures.size()
		var first_goal := goal_events
		shell.start_level(id)
		await delay(0.4)
		game = shell.adapter.level
		check(game != null and game.content.level_id == id and shell.state == shell.State.PLAYING, "actual catalog level entry " + id)
		if game == null: continue
		native_commits = []
		game.mover.committed.connect(observe_commit)
		var initial := snapshot()
		await shot("spawn")
		await view_checks()
		await key(KEY_D if id == "mutsumi_l03" else KEY_W, true)
		await delay(0.05)
		await key(KEY_D if id == "mutsumi_l03" else KEY_W, false)
		await key(KEY_ESCAPE, true)
		await key(KEY_ESCAPE, false)
		check(shell.state == shell.State.PAUSED, "native legacy Pause")
		var frozen := snapshot()
		var frozen_pose: Transform3D = game.presenter.actor.transform
		await delay(0.15)
		check(snapshot() == frozen and game.presenter.actor.transform == frozen_pose, "legacy Pause freezes Runtime and actual visual pose")
		await tap(KEY_ESCAPE)
		check(shell.state == shell.State.PLAYING, "native legacy Resume")
		await reset_check()
		check(snapshot() == initial, "native Reset restores exact legacy observable state")
		native_commits = []
		match id:
			"mutsumi_l01": await route_l01("quality_normal")
			"mutsumi_l02": await route_l02("quality_normal")
			"mutsumi_l03": await route_l03("quality_normal")
			_:
				check(recipes.routes.has(id), "delivered Owner06 input recipe")
				if recipes.routes.has(id):
					for step in recipes.routes[id]:
						match step.action:
							"move":
								var directions := {"UP": Vector2i.UP, "DOWN": Vector2i.DOWN, "LEFT": Vector2i.LEFT, "RIGHT": Vector2i.RIGHT}
								await move(directions[step.direction], int(step.get("count", 1)))
							"shift": await tap(KEY_SPACE)
							"view": await tap(KEY_E if step.direction == "E" else KEY_Q)
		await delay(0.2)
		var final := snapshot()
		check(game.graph.complete and game.mover.cell == game.content.goal and game.mover.world == 0, "actual native authored Goal " + id)
		check(goal_events == first_goal + 1 and shell.state == shell.State.LEVEL_COMPLETE, "one genuine Goal event reaches Shell")
		check(game.mover.orientation.valid() and game.presenter.actor.basis.is_equal_approx(game.mover.orientation.as_basis()), "actual legacy final physical Orientation parity")
		check(not native_commits.is_empty() and native_commits[-1].goal, "Goal appears in actual commit observations")
		await shot("goal")
		await reset_check()
		check(snapshot() == initial and shell.state == shell.State.PLAYING, "Goal Reset restores usable original state")
		var old_level: WeakRef = weakref(game)
		shell.show_main_menu()
		game = null
		await process_frame
		await process_frame
		check(old_level.get_ref() == null and shell.adapter.level == null and shell.state == shell.State.MAIN_MENU, "real Shell exit releases actual level")
		rows.append({"id": "REG_" + id.trim_prefix("mutsumi_").to_upper(), "checks": checks - first_check,
			"status": "PASS" if failures.size() == first_failure else "FAIL", "initial": initial, "final": final,
			"native_commits": native_commits.duplicate(true), "scope": "actual catalog/Shell/native input recipes/natural P01 Runtime and 3D Presenter; start/exit use public Shell API; no Foundation replay claim"})
	shell.queue_free()
	await process_frame
	FileAccess.open(evidence.path_join("report.json"), FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures,
		"rows": rows, "doubles": [], "pid": OS.get_process_id(), "display": DisplayServer.get_name(),
		"renderer": RenderingServer.get_current_rendering_method(), "user_data_dir": OS.get_user_data_dir(),
		"state_key_scope": "actual legacy P01 observable identity; not Foundation StateKey", "human_qa": "NOT_RUN"}, "\t"))
	quit(0 if failures.is_empty() else 1)
