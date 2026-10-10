"""Unit synthetic receipt metadata only; never asserts Real Runtime success."""
import unittest
from run_yellow_target import classify


class ReceiptTests(unittest.TestCase):
    def record(self):
        return dict(exit_code=0, checks=20, failures=[], doubles=[], stderr_bytes=0,
                    source_drift=[], candidate="a" * 40, profile="foundation.game_feel.v2",
                    scope="NEW_PROFILE_REAL", dependency_pending=[], capture_verified=True)

    def test_preparation_probe_cannot_issue_real_pass(self):
        r = self.record()
        r.update(scope="DEPENDENCY_PROBE", candidate=None)
        self.assertEqual(classify(r), "PENDING")

    def test_absent_dependencies_remain_pending(self):
        r = self.record()
        r.update(exit_code=3, dependency_pending=["REAL_01_TRAJECTORY_SAMPLER"])
        self.assertEqual(classify(r), "PENDING")

    def test_old_profile_and_old_matches_do_not_qualify(self):
        r = self.record()
        r.update(profile="foundation.game_feel.v1", matched_steps=8)
        self.assertEqual(classify(r), "FAIL")

    def test_bound_new_profile_receipt_qualifies_only_its_job(self):
        self.assertEqual(classify(self.record()), "PASS")

    def test_fail_closed_corrupted_receipts(self):
        for field, value in [("candidate", None), ("candidate", "not-a-sha"),
                             ("doubles", ["FakeSolver"]), ("checks", 0),
                             ("stderr_bytes", 1), ("source_drift", ["runtime.gd"]),
                             ("exit_code", "TIMEOUT"), ("failures", ["bad pose"]),
                             ("capture_verified", False)]:
            with self.subTest(field=field):
                r = self.record()
                r[field] = value
                self.assertEqual(classify(r), "FAIL")

    def test_script_error_is_not_hidden_as_dependency_pending(self):
        r = self.record()
        r.update(scope="DEPENDENCY_PROBE", dependency_pending=["SAMPLER"], stderr_bytes=9)
        self.assertEqual(classify(r), "FAIL")


if __name__ == "__main__":
    unittest.main()
