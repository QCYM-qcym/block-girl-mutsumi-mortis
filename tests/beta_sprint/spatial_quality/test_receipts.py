"""UNIT tests of receipt admission; synthetic records never prove gameplay."""
import copy
import unittest

from receipts import admit, register


def valid_receipt():
    return {
        "candidate": "a" * 40, "execution_head": "b" * 40,
        "exit_code": 0, "checks": 2, "failures": [], "doubles": [],
        "stderr_bytes": 0, "source_drift": [], "capture_verified": True,
        "source_verified": True, "job": "orientation", "graphical": False,
        "report": {"scope": "SPATIAL_OWNER_03_REAL", "checks": 2, "failures": [],
                   "doubles": [], "cases": [{"id": "loop.pose", "facet": "UNIT",
                       "checks": 2, "failures": [], "status": "PASS"}],
                   "dependency_pending": []},
    }


class AdmissionTests(unittest.TestCase):
    def test_measured_real_receipt_is_accepted(self):
        self.assertEqual(admit(valid_receipt()), "PASS")

    def test_no_checks_cannot_pass(self):
        r = valid_receipt()
        r["checks"] = r["report"]["checks"] = 0
        self.assertEqual(admit(r), "FAIL")

    def test_dirty_source_pid_or_stderr_cannot_pass(self):
        for field, value in [("capture_verified", False), ("source_verified", False),
                             ("source_drift", ["kernel.gd"]), ("stderr_bytes", 1)]:
            with self.subTest(field=field):
                r = valid_receipt()
                r[field] = value
                self.assertEqual(admit(r), "FAIL")

    def test_doubles_cannot_sign_real(self):
        r = valid_receipt()
        r["doubles"] = r["report"]["doubles"] = ["kernel_double"]
        self.assertEqual(admit(r), "FAIL")

    def test_partial_delivery_remains_pending(self):
        r = valid_receipt()
        r["exit_code"] = 3
        r["report"]["dependency_pending"] = ["REAL_01_RUNTIME"]
        self.assertEqual(admit(r), "PENDING")

    def test_failure_beats_pending(self):
        r = valid_receipt()
        r["exit_code"] = 3
        r["report"]["dependency_pending"] = ["REAL_01_RUNTIME"]
        r["failures"] = r["report"]["failures"] = ["off-point accepted"]
        self.assertEqual(admit(r), "FAIL")

    def test_graphical_claim_needs_actual_window(self):
        r = valid_receipt()
        r["report"]["cases"][0]["facet"] = "FORMAL_GRAPHICAL"
        self.assertEqual(admit(r), "FAIL")

    def test_logical_cannot_register_graphical_case(self):
        planned = {"loop.pose": {"facet": "FORMAL_GRAPHICAL"}}
        with self.assertRaises(ValueError):
            register(planned, valid_receipt(), "receipt.json")

    def test_assertion_count_mismatch_rejected(self):
        r = valid_receipt()
        r["report"]["cases"][0]["checks"] = 1
        self.assertEqual(admit(r), "FAIL")

    def test_unknown_case_rejected(self):
        with self.assertRaises(ValueError):
            register({}, valid_receipt(), "receipt.json")

    def test_duplicate_case_does_not_inflate_count(self):
        r = valid_receipt()
        r["report"]["cases"].append(copy.deepcopy(r["report"]["cases"][0]))
        r["checks"] = r["report"]["checks"] = 4
        self.assertEqual(admit(r), "FAIL")

    def test_empty_placeholder_cannot_pass(self):
        r = valid_receipt()
        r["report"]["cases"][0]["status"] = "PENDING"
        self.assertEqual(admit(r), "FAIL")


if __name__ == "__main__":
    unittest.main()
