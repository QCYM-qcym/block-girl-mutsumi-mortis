extends SceneTree
## Recording only. No permission, graph, motion or gameplay implementation.
var evidence := ""
var checks := 0
var failures: Array[String] = []
var cases: Array[Dictionary] = []
var rows: Array = []
var dependency_pending: Array[String] = []
var current: Dictionary = {}

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): evidence = arg.trim_prefix("--evidence=")
	call_deferred("run")

func begin(id: String, facet: String) -> void:
	current = {"id":id,"facet":facet,"checks":0,"failures":[],"status":"PASS"}
	cases.append(current)

func check(ok: bool, label: String) -> void:
	checks += 1
	current.checks += 1
	if not ok:
		failures.append(current.id + ": " + label)
		current.failures.append(label)
		current.status = "FAIL"

func capture() -> Dictionary:
	var head := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--execution-head="): head = arg.trim_prefix("--execution-head=")
	return {"pid":OS.get_process_id(),"execution_head":head,"engine":Engine.get_version_info(),
		"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),
		"user_data_dir":OS.get_user_data_dir(),"doubles":[],"authority":"PUBLIC_PRODUCTION_APIS"}

func finish() -> void:
	var report := {"scope":"SPATIAL_OWNER_03_REAL","checks":checks,"failures":failures,
		"doubles":[],"cases":cases,"rows":rows,"dependency_pending":dependency_pending,
		"capture":capture()}
	FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	quit(1 if not failures.is_empty() else (3 if not dependency_pending.is_empty() else 0))

func run() -> void:
	finish()
