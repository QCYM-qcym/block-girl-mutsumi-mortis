extends "res://tests/beta_sprint/spatial_quality/polish_03/test_recovery.gd"
## Tests-only request-result double; exercises recorder guard, no Runtime/search authority.
var request_result := {"status":1,"changed":false}
var captured_guard_failures: Array = []

func act(_action: Dictionary, _expected_key: String = "", _record_trace: bool = true) -> Dictionary:
	return request_result.duplicate(true)

func guard_case(label: String, value: Dictionary) -> void:
	begin(label,"UNIT")
	request_result = value
	var failure_before := failures.size()
	var checks_before := checks
	var proceeded := route([{"kind":0,"face_axis":0}])
	var observed: Array = failures.slice(failure_before)
	var expected := label+": planned setup route must apply a changed action"
	var detected: bool = not proceeded and observed == [expected]
	captured_guard_failures.append({"case":label,"double_result":value,"proceeded":proceeded,"actual_captured_failures":observed,"expected":expected})
	# A recorder failure is the expected object under test, like an exception.
	# Remove only the exact expected UNIT failure; never touch Real receipts.
	if detected:
		failures.resize(failure_before)
		checks = checks_before
		current.checks = 0
		current.failures = []
		current.status = "PASS"
	check(detected,"non-applied setup cannot silently skip required scenario")

func run() -> void:
	guard_case("rejected_setup",{"status":1,"changed":false})
	guard_case("noop_setup",{"status":0,"changed":false})
	FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({
		"scope":"QUALITY_HARNESS_UNIT_ONLY","checks":checks,"failures":failures,
		"doubles":["REQUEST_RESULT_DOUBLE_UNIT_ONLY"],"runtime_authority":false,"captured_guard_failures":captured_guard_failures,
		"capture":capture()},"\t"))
	quit(0 if failures.is_empty() else 1)
