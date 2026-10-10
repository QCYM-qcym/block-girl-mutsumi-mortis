import unittest
from v2_reports import classify_execution, core_mapping, legacy_checks, execution_identity_failures
from pathlib import Path

# Synthetic process/receipt records; no real Runtime, replay or graphical authority.
class V2ReceiptGuards(unittest.TestCase):
    def test_graphical_positive_counter_without_actual_identity_is_rejected(self):
        report = {"checks": 8, "failures": [], "doubles": []}
        self.assertTrue(execution_identity_failures(report, True, Path.cwd(), "", 123))

    def test_graphical_profile_pid_and_renderer_cannot_be_forged(self):
        profile = Path.cwd() / "profile"
        report = {"display": "Windows", "pid": 123, "user_dir": str(profile / "Godot")}
        renderer = "D3D12 12_0 - Forward+ - Using Device #0: NVIDIA - actual GPU"
        self.assertEqual(execution_identity_failures(report, True, profile, renderer, 123), [])
        for bad in ({**report, "user_dir": str(Path.cwd() / "personal-save")}, {**report, "pid": 321}, {**report, "display": "headless"}):
            self.assertTrue(execution_identity_failures(bad, True, profile, renderer, 123))
        self.assertTrue(execution_identity_failures(report, True, profile, "", 123))
    def test_actual_legacy_marker_preserves_semicolon_shape(self):
        self.assertEqual(legacy_checks("PERSPECTIVE_LOGIC: 66 checks; 24 orientations; failures=[]\n"), 66)
        self.assertEqual(legacy_checks("PERSPECTIVE_LOGIC: 66 checks; 24 orientations; failures=[wrong_pose]"), 0)
        self.assertEqual(legacy_checks("PERSPECTIVE_LOGIC: 66 checks; 24 orientations; failures=[]\n" * 2), 0)
    def test_graphical_block_is_not_a_pass(self):
        report = {"checks": 8, "failures": [], "doubles": [], "formal_graphical": "BLOCKED"}
        self.assertEqual(classify_execution(report, 0, 0, []), "BLOCKED")

    def test_logical_match_does_not_override_formal_graphical_block(self):
        report = {"checks": 8, "failures": [], "doubles": [], "formal_graphical": "BLOCKED", "logical_replay": "PASS", "natural_presenter": "PASS"}
        self.assertEqual(classify_execution(report, 0, 0, []), "BLOCKED")

    def test_errors_and_algorithm_doubles_fail(self):
        good = {"checks": 8, "failures": [], "doubles": []}
        for report, code, stderr, drift in ((good, 1, 0, []), (good, 0, 1, []), (good, 0, 0, ["source.gd"]),
                                          ({**good, "doubles": ["runtime_double"]}, 0, 0, []),
                                          ({**good, "failures": ["wrong_key"]}, 0, 0, [])):
            self.assertEqual(classify_execution(report, code, stderr, drift), "FAIL")

    def test_zero_checks_cannot_pass(self):
        self.assertEqual(classify_execution({"checks": 0, "failures": [], "doubles": []}, 0, 0, []), "FAIL")

    def test_complete_production_run_passes(self):
        self.assertEqual(classify_execution({"checks": 8, "failures": [], "doubles": []}, 0, 0, []), "PASS")

    def test_69_checks_map_to_three_unique_rows(self):
        receipt = {"registered_quality_cases": [{"case": name, "checks": checks, "formal_result": "PASS"} for name, checks in
                   (("CORE_A_NATURAL_FALL", 26), ("CORE_B_NATURAL_FALL", 26), ("CORE_CAMERA_REJECT", 17))]}
        result = core_mapping(receipt)
        self.assertEqual(result["checks"], 69)
        self.assertEqual(result["cases"], 3)
        self.assertEqual(result["counting"], "Each matrix row counted once; assertions belong to shared execution evidence")

    def test_forged_core_identity_or_counter_is_rejected(self):
        rows = [{"case": name, "checks": checks, "formal_result": "PASS"} for name, checks in
                (("CORE_A_NATURAL_FALL", 26), ("CORE_B_NATURAL_FALL", 26), ("CORE_CAMERA_REJECT", 17))]
        for update in ({"case": "NON_EXISTENT_CASE"}, {"checks": -1}, {"checks": True}, {"formal_result": "FAIL"}):
            with self.assertRaises(ValueError):
                core_mapping({"registered_quality_cases": [{**rows[0], **update}, *rows[1:]]})

if __name__ == "__main__":
    unittest.main()
