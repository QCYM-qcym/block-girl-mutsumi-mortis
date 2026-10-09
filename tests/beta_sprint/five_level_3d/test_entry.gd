extends SceneTree
## Real scene/layout regression: support uses approved logical footprints.
var checks := 0
var failures: Array[String] = []
var evidence := ""
var baseline_layout := false

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures.append(label)
		printerr("FAIL: ", label)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="): evidence = arg.trim_prefix("--evidence-dir=")
		elif arg == "--baseline-layout": baseline_layout = true
	if evidence.is_empty():
		quit(2)
		return
	for name in ["l04_borrowed_path", "l05_gate_home"]:
		var game
		if baseline_layout:
			game = load("res://game/levels/mutsumi/batch_02/batch_02_level.gd").new()
			game.content = load("res://game/levels/mutsumi/batch_02/" + name + ".tres")
		else:
			game = load("res://game/levels/mutsumi/batch_02/" + name + ".tscn").instantiate()
		root.add_child(game)
		await process_frame
		await process_frame
		check(game.presenter is Node3D and game.using_3d, name + " native entry constructs 3D")
		var p = game.presenter
		check(p.get("link_markers") != null and p.get("link_markers").size() == 2, name + " renders both actual authored connection endpoints")
		for world in 2:
			var cells = game.content.surface_cells if world == 0 else game.content.inner_cells
			var floors: Array = p.assets.filter(func(row: Dictionary) -> bool: return row.world == world and row.walkable)
			var observed: Array[Vector2i] = []
			for row in floors:
				var id: String = row.node.get_meta("approved_asset_id")
				var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://production/art_3d/"+id+"/reports/asset_manifest.json"))
				var span: Array = manifest.logical_footprint.grid_reservation_cells
				for x in int(span[0]):
					for z in int(span[1]):
						var offset: Vector3 = row.node.basis * Vector3(x-(float(span[0])-1)/2,0,z-(float(span[1])-1)/2)
						var point: Vector2 = row.cell + Vector2(offset.x,offset.z)
						var cell := Vector2i(roundi(point.x),roundi(point.y))
						check(point.is_equal_approx(Vector2(cell)) and cell in cells and row.platform == game.graph.nodes.get(cell), name + " approved footprint reserves actual native supported cell/platform")
						check(cell not in observed, name + " visual support footprints do not overlap")
						observed.append(cell)
			check(observed.size() == cells.size() and cells.all(func(cell:Vector2i)->bool:return cell in observed), name + " exact native support coverage world " + str(world))
			if game.content.goal in cells:
				var passage: Vector3 = p.mechanisms[world].exit.basis.z
				var approach := Vector3.FORWARD if name.begins_with("l04") else Vector3.RIGHT
				check(absf(passage.dot(approach)) > 0.99, name + " approved Exit local Z passage aligns native final approach")
			if name.begins_with("l05"):
				var carriers: Array = floors.filter(func(row: Dictionary) -> bool: return row.cell == Vector2(11, 0))
				check(carriers.size() == 1 and str(carriers[0].node.get_meta("approved_asset_id")).contains("PRESSURE_PLATE"), "L05 plate replaces exactly its floor without overlapping support")
				check(p.mechanisms[world].has("gate") and p.mechanisms[world].has("plate"), "L05 actual optional mechanism instances")
		game.queue_free()
		await process_frame
		# Audio mixing runs independently of process_frame. Allow native queued
		# destruction and the mixer to release WAV playback before the next scene.
		await create_timer(0.2).timeout
	var report := {"checks":checks, "failures":failures, "pid":OS.get_process_id(), "display":DisplayServer.get_name(),"baseline_layout":baseline_layout,"doubles":[]}
	FileAccess.open(evidence.path_join("report.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("FIVE3D ENTRY: ", checks, " checks; failures=", failures)
	quit(0 if failures.is_empty() else 1)
