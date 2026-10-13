"""Metadata boundaries, no gameplay/search authority."""
import unittest
from projection import summarize


class ProjectionTests(unittest.TestCase):
    def test_sample_does_not_expand_the_original_domain(self):
        result=summarize([{"status":"PASS"}],[])
        self.assertEqual(result["sample_status"],"PASS")
        self.assertEqual(result["overall"],"PARTIAL")
        self.assertEqual(result["complete_runtime_denominator"],"UNKNOWN")
        self.assertEqual(result["original_domain"],{"states":908,"edges":3916,"goals":96,"softlocks":0})

    def test_budget_does_not_prove_recovery_or_reset_only(self):
        result=summarize([], [{"status":2}])
        self.assertEqual(result["sample_status"],"PENDING")
        self.assertIsNone(result["reset_only_conclusion"])
        self.assertEqual(result["post_goal_softlocks"],"UNKNOWN")

    def test_any_runtime_failure_stays_fail(self):
        self.assertEqual(summarize([{"status":"FAIL"}],[]) ["sample_status"],"FAIL")


if __name__=="__main__": unittest.main()
