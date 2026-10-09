import unittest
from matrix import INPUTS, PHASES, cases


class MatrixCoverage(unittest.TestCase):
    def test_each_phase_has_every_requested_stress_input(self):
        ids = {row["id"] for row in cases()}
        for phase in PHASES:
            for input_id in INPUTS:
                self.assertIn(f"A_INPUT_{phase.upper()}_{input_id.upper()}", ids)

    def test_both_actual_height_signs_in_both_worlds(self):
        ids = {row["id"] for row in cases()}
        for height in ("LOWER", "HIGHER"):
            for world in ("SURFACE", "INNER"):
                self.assertIn(f"G_FALL_{height}_{world}", ids)

    def test_no_unearned_real_pass_or_unconditional_l06(self):
        rows = cases()
        self.assertEqual(len(rows), len({row["id"] for row in rows}))
        for row in rows:
            self.assertEqual(row["status"], "case_pending")
            self.assertEqual(row["checks"], 0)
            self.assertIsNone(row["source_sha"])
            self.assertIsNone(row["delivery_sha"])
            self.assertEqual(row["doubles"], [])
            for field in ("dependencies", "setup", "action", "expected", "evidence"):
                self.assertTrue(row[field], row["id"] + ": " + field)
        l06 = next(row for row in rows if row["id"] == "REG_L06")
        self.assertEqual(l06["dependencies"], ["L06_INTEGRATION_RECEIPT"])
        self.assertEqual(l06["scope"], "conditional_L06")

    def test_independent_domains_and_all_legacy_levels(self):
        rows = cases()
        self.assertEqual({row["area"] for row in rows},
                         {"Runtime", "Animation", "Graphical", "Audio", "UI", "Solver", "Legacy regression"})
        ids = {row["id"] for row in rows}
        for level in range(1, 6):
            self.assertIn(f"REG_L0{level}", ids)

    def test_core_execution_does_not_wait_for_its_own_final_receipt(self):
        for row in cases():
            if row["scope"] == "CORE_PLAYABLE":
                self.assertNotIn("CORE_PLAYABLE_RECEIPT", row["dependencies"])
                self.assertEqual(row["registration_requirements"], ["CORE_PLAYABLE_RECEIPT"])
                for unrelated in ("AUDIO_UI", "ART", "SHELL"):
                    self.assertNotIn(unrelated, row["dependencies"])


if __name__ == "__main__":
    unittest.main()
