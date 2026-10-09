extends SceneTree
## Test-only result protocol. Derived run() may await; finish() is explicit.
var checks: int = 0
var failures: Array[String] = []
var doubles: Array[String] = []
var _finished := false

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	finish()

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)

func evidence_dir() -> String:
	return OS.get_environment("FOUNDATION_TEST_EVIDENCE")

func mode() -> String:
	return OS.get_environment("FOUNDATION_TEST_MODE")

func finish() -> void:
	if _finished:
		return
	_finished = true
	if checks == 0:
		failures.append("NOT_RUN: no checks executed")
	var result := {"checks": checks, "failures": failures, "mode": mode(),
		"display": DisplayServer.get_name(), "doubles": doubles}
	var file := FileAccess.open(evidence_dir().path_join("results.json"), FileAccess.WRITE)
	if file == null:
		quit(1)
		return
	file.store_string(JSON.stringify(result))
	file.close()
	quit(0 if failures.is_empty() else 1)
