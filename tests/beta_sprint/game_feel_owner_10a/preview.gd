extends SceneTree
const Stage = preload("res://tests/beta_sprint/game_feel_owner_10a/preview_stage.gd")
var evidence := ""
var checks := 0
var failures: Array = []
var rows: Array = []
var screenshots: Array = []
var curved := false

func _initialize() -> void:
	Engine.max_fps = 60
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="): evidence = arg.trim_prefix("--evidence-dir=")
		if arg == "--curve": curved = true
	call_deferred("run")

func check(value: bool, text: String) -> void:
	checks += 1
	if not value:
		failures.append(text)
		printerr("FAIL 10A PREVIEW: ", text)

func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(evidence.path_join(name + ".png"))
	screenshots.append(name + ".png")

func key(code: int) -> void:
	for pressed in [true, false]:
		var input := InputEventKey.new()
		input.physical_keycode = code
		input.keycode = code
		input.pressed = pressed
		root.push_input(input, true)
		await process_frame

func run() -> void:
	check(DisplayServer.get_name() != "headless", "actual 3D graphical sampler demonstration")
	for higher in [false, true]:
		var letter := "B" if higher else "A"
		var stage = Stage.new()
		stage.higher = higher
		stage.curved = curved
		root.add_child(stage)
		await create_timer(0.3).timeout
		var initial_event: Dictionary = stage.event.duplicate(true)
		var source: Vector3 = stage.endpoint(false)
		var target: Vector3 = stage.endpoint(true)
		check(target.y - source.y == (2.0 if higher else -2.0), "real height retained " + letter)
		for quadrant in 4:
			stage.set_quadrant(quadrant)
			await process_frame
			var dy: float = stage.camera.unproject_position(target).y - stage.camera.unproject_position(source).y
			rows.append({"map": letter, "camera_quadrant": quadrant, "static_dy": dy})
			if quadrant == 1: check(dy > 0.0, "fixed EAST view shows screen-down target " + letter)
		stage.set_quadrant(1)
		var fixed_camera: Transform3D = stage.camera.transform
		await capture("map_" + letter + "_source")
		stage.launch()
		var previous_y: float = stage.camera.unproject_position(source).y
		var captured: Dictionary = {}
		while not stage.settled:
			await process_frame
			var phase: String = stage.sample_state.get("phase", "IDLE")
			var screen: Vector2 = stage.camera.unproject_position(stage.visual.position)
			if not stage.is_committed:
				check(screen.y + 0.001 >= previous_y, "continuous screen descent " + letter)
				previous_y = screen.y
			check(stage.camera.transform == fixed_camera and stage.event == initial_event, "camera/World/DTO remain unchanged " + letter)
			rows.append({"map": letter, "elapsed": stage.elapsed, "landing_elapsed": stage.landing_elapsed,
				"phase": phase, "position": str(stage.visual.position), "screen": [screen.x, screen.y],
				"scale": str(stage.visual.scale), "commit_kind": "SYNTHETIC_DOUBLE"})
			if phase in ["ANTICIPATION", "FORWARD", "DEPARTURE", "FALL_MOVING", "LANDING_IMPACT", "LANDING_REBOUND"] and not captured.has(phase):
				captured[phase] = true
				await capture("map_" + letter + "_" + phase.to_lower())
			if not stage.is_committed and stage.elapsed >= 0.5 and not captured.has("MID_FALL"):
				captured.MID_FALL = true
				await capture("map_" + letter + "_mid_fall")
			if curved and not stage.is_committed and stage.elapsed >= 0.74 and not captured.has("NEAR_CONTACT"):
				captured.NEAR_CONTACT = true
				await capture("map_" + letter + "_near_contact")
		check(stage.visual.position == target and stage.visual.basis == stage.authoritative_basis, "exact final rendered transform " + letter)
		await capture("map_" + letter + "_settled")
		# Native input delivery into PRIVATE host double, no Runtime Busy proof.
		stage.launch()
		await create_timer(0.3).timeout
		await key(KEY_P)
		var paused_transform: Transform3D = stage.visual.transform
		var paused_time: float = stage.elapsed
		await create_timer(0.08).timeout
		check(stage.visual.transform == paused_transform and stage.elapsed == paused_time, "Pause suspends elapsed without cancellation " + letter)
		await key(KEY_P)
		for code in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_SPACE, KEY_Q, KEY_E]: await key(code)
		var drag := InputEventMouseMotion.new()
		drag.relative = Vector2(50,20)
		root.push_input(drag, true)
		await process_frame
		check(stage.busy_inputs >= 8 and stage.camera.transform == fixed_camera, "delivered conflicting inputs/drag cannot change private Camera " + letter)
		await key(KEY_R)
		check(stage.reset_inputs == 1 and stage.visual.position == source and stage.visual.basis == stage.authoritative_basis, "Reset input neutralizes private Visual Root " + letter)
		check(not stage.motion.sample(2.0).active and not stage.landing.sample(2.0).active, "Reset clears samplers " + letter)
		stage.launch()
		await process_frame
		root.remove_child(stage)
		check(not stage.motion.sample(2.0).active and not stage.landing.sample(2.0).active, "scene exit clears in-flight sampler " + letter)
		stage.free()
	FileAccess.open(evidence.path_join("report.json"), FileAccess.WRITE).store_string(JSON.stringify({
		"fixture_kind": "PRESENTATION_CONTRACT_UNIT", "authoritative_runtime": false,
		"doubles": ["01 DTO", "Safety attestation", "native commit", "private input gate"],
		"checks": checks, "failures": failures, "pid": OS.get_process_id(), "user_data_dir": OS.get_user_data_dir(),
		"display": DisplayServer.get_name(), "renderer": RenderingServer.get_current_rendering_method(),
		"input": "native viewport events to private host double; no Gameplay input acceptance",
		"rows": rows, "screenshots": screenshots, "scope": "continuous 3D sampler playback; NOT real legal Fall gameplay acceptance"}, "\t"))
	print("10A_PRIVATE_GRAPHICAL_UNIT checks=", checks, " failures=", failures.size(), " authority=false")
	quit(0 if failures.is_empty() else 1)
