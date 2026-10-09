extends SceneTree
var evidence := ""
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): evidence=arg.trim_prefix("--evidence=")
	call_deferred("run")
func run() -> void:
	var script: Script=load("res://experiments/game_feel_01/host/core_lab.gd")
	var failures: Array=[]
	if not script.can_instantiate(): failures.append("00 isolated Host does not compile")
	else:
		var host: Node=script.new()
		host.free()
	var report: Dictionary={"checks":1,"failures":failures,"doubles":[],"authority":"compile only, no Runtime or gameplay execution","pid":OS.get_process_id()}
	FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	quit(0 if failures.is_empty() else 1)
