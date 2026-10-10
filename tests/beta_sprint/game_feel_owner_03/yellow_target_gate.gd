extends RefCounted
## Availability/admission only; no replacement curve, permissions, or Safety.
const Maps = preload("res://experiments/game_feel_01/maps/map_factory.gd")
const Capture = preload("res://tests/beta_sprint/game_feel_owner_03/capture_identity.gd")
const SAMPLER := "res://foundation/game_feel/trajectory_profile.gd"

static func probe() -> Dictionary:
	var pending: Array[String] = []
	var observations: Array = []
	var exists := ResourceLoader.exists(SAMPLER)
	if not exists: pending.append("REAL_01_TRAJECTORY_SAMPLER: " + SAMPLER)
	else:
		var sampler: Variant = load(SAMPLER)
		if sampler == null or not sampler.has_method("sample_actor_center"):
			pending.append("REAL_01_SAMPLE_ACTOR_CENTER_API")
	for letter in ["a", "b"]:
		var data := Maps.read_spec(letter)
		var candidate: Dictionary = data.get("opt_in_candidate", {})
		observations.append({"map": letter, "candidate_schema": candidate.get("schema_version"),
			"candidate_contract": candidate.get("contract_version"), "source": data.get("source_center2"),
			"target": data.get("target_center2"), "exit": data.get("exit_center2")})
		if candidate.get("schema_version") != 3 or candidate.get("contract_version") != "foundation.game_feel.v2" or candidate.get("rule_version") != "foundation.rules.game_feel.v2":
			pending.append("REAL_09_SCHEMA3_MAP_" + letter.to_upper() + "_AND_BAKER")
	var capture := Capture.snapshot("NEW_PROFILE_DEPENDENCY_PROBE")
	capture.fixture_kind = "ACTUAL_AUTHOR_DATA_AND_RESOURCE_AVAILABILITY_PROBE"
	return {"checks": 3, "failures": [], "doubles": [], "scope": "DEPENDENCY_PROBE",
		"profile": "foundation.game_feel.v2", "dependency_pending": pending,
		"sampler_exists": exists, "observations": observations,
		"capture": capture,
		"authority": "Actual ResourceLoader and author Map versions; availability probes are not gameplay assertions or Real PASS"}

static func blocked(tree: SceneTree, evidence: String) -> bool:
	var report := probe()
	if report.dependency_pending.is_empty(): return false
	FileAccess.open(evidence.path_join("report.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	tree.quit(3)
	return true

static func real_capture(input_profile: String) -> Dictionary:
	var capture := Capture.snapshot(input_profile)
	capture.fixture_kind = "REAL_CANONICAL_SCHEMA3_MAP_AB"
	capture.authoritative_runtime = true
	return capture
