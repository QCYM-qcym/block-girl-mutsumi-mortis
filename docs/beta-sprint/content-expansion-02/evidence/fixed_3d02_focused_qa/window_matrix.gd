extends SceneTree

# QA-only entry, outside the project. No gameplay/UI/save access or input injection.
var config_path := "E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/window_config.json"
var evidence_dir := "E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01"
var sample_seq := 0

func _initialize() -> void:
	call_deferred("start_formal_scene")

func start_formal_scene() -> void:
	var result := change_scene_to_file(str(ProjectSettings.get_setting("application/run/main_scene")))
	if result != OK:
		push_error("QA formal main scene load failed: %s" % result)
		quit(1)
		return
	await process_frame
	sample_geometry()

func sample_geometry() -> void:
	while true:
		var config = JSON.parse_string(FileAccess.get_file_as_string(config_path))
		if config is Dictionary:
			var requested := Vector2i(int(config.get("width", 0)), int(config.get("height", 0)))
			if requested in [Vector2i(1920,1080), Vector2i(1280,720), Vector2i(960,720)]:
				if root.size != requested:
					root.size = requested
				if root.position != Vector2i(50, 70):
					root.position = Vector2i(50, 70)
				await process_frame
				var data := {
					"sample": sample_seq,
					"unix_time": Time.get_unix_time_from_system(),
					"pid": OS.get_process_id(),
					"requested": [requested.x, requested.y],
					"window_size": [root.size.x, root.size.y],
					"client_size": [DisplayServer.window_get_size().x, DisplayServer.window_get_size().y],
					"viewport_size": [root.get_visible_rect().size.x, root.get_visible_rect().size.y],
					"render_size": [root.get_texture().get_size().x, root.get_texture().get_size().y],
					"outer_size": [root.get_size_with_decorations().x, root.get_size_with_decorations().y],
					"content_scale_mode": root.content_scale_mode,
					"content_scale_factor": root.content_scale_factor,
					"window_mode": root.mode,
					"title": root.title
				}
				sample_seq += 1
				var current := FileAccess.open(evidence_dir + "/geometry.json", FileAccess.WRITE)
				current.store_string(JSON.stringify(data))
				current.close()
				var history := FileAccess.open(evidence_dir + "/geometry_history.jsonl", FileAccess.READ_WRITE)
				if history == null:
					history = FileAccess.open(evidence_dir + "/geometry_history.jsonl", FileAccess.WRITE)
				history.seek_end()
				history.store_line(JSON.stringify(data))
				history.close()
		await create_timer(0.25, true).timeout


