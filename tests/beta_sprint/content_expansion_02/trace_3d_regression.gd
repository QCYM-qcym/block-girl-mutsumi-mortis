extends "res://tests/beta_sprint/three_d_02/test_gameplay.gd"
## Observe the unchanged native regression when it stops progressing. No state/input repair.
var trace_stage := "startup"
var trace_last_ms := 0
var trace_progress_ms := 0
var trace_checks := -1
var trace_shots := -1
var trace_stopped := false

func _process(_delta: float) -> bool:
	if evidence.is_empty() or trace_stopped:
		return false
	var now := Time.get_ticks_msec()
	if trace_checks != checks or trace_shots != screenshots:
		trace_checks = checks
		trace_shots = screenshots
		trace_progress_ms = now
	if now - trace_last_ms >= 2000:
		trace_last_ms = now
		write_trace("heartbeat")
	if now - trace_progress_ms > 15000:
		trace_stopped = true
		write_trace("stalled_no_checks_or_screenshots_15s")
		printerr("FAIL: native regression made no progress for 15 seconds; see trace.jsonl")
		quit(2)
	return false

func write_trace(event: String) -> void:
	var row := {"event":event, "stage":trace_stage, "ticks_ms":Time.get_ticks_msec(), "checks":checks, "failures":failures, "screenshots":screenshots, "pid":OS.get_process_id()}
	if is_instance_valid(shell):
		row.shell_state = shell.state
		row.shell_screen = shell.view.screen
	if is_instance_valid(game):
		row.state = native_snapshot()
		row.moving = game.mover.moving
		row.fraction = game.mover.fraction
		row.elapsed = game.mover.elapsed
		row.process_mode = game.process_mode
	var path := evidence.path_join("trace.jsonl")
	var file := FileAccess.open(path, FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE)
	if file != null:
		file.seek_end()
		file.store_line(JSON.stringify(row))

func shot(label: String) -> void:
	trace_stage = "shot:" + label
	write_trace("before_shot")
	await super.shot(label)
	write_trace("after_shot")

func sample_roll(direction: Vector2i) -> void:
	trace_stage = "sample_roll:" + str(direction)
	write_trace("before_sample_roll")
	await super.sample_roll(direction)
	trace_stage = "sample_roll_landed:" + str(direction)
	write_trace("after_sample_roll")
