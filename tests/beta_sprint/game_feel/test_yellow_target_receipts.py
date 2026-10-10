"""Unit synthetic receipt metadata only; never asserts Real Runtime success."""
import unittest
import subprocess
import tempfile
from pathlib import Path
from run_yellow_target import classify, source_snapshot, verify_candidate, source_drift


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


class SourceAdmissionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        subprocess.run(["git", "init", "-q", str(self.root)], check=True)
        self.git("config", "core.autocrlf", "false")
        self.production = self.root / "foundation/input.gd"
        self.production.parent.mkdir()
        self.production.write_bytes(b"actual candidate input\n")
        self.git("add", "foundation/input.gd")
        # write-tree needs no synthetic commit or other worktree.
        self.candidate = self.git("write-tree")

    def git(self, *args):
        return subprocess.check_output(["git", "-C", str(self.root), *args], encoding="utf-8").strip()

    def test_unstaged_deleted_tracked_source_is_not_omitted(self):
        self.production.unlink()
        with self.assertRaisesRegex(ValueError, "missing"):
            source_snapshot(self.root)

    def test_staged_deletion_is_rejected_against_candidate_tree(self):
        self.production.unlink()
        self.git("add", "-u")
        with self.assertRaisesRegex(ValueError, "missing"):
            verify_candidate(self.candidate, source_snapshot(self.root), self.root)

    def test_preexisting_rename_cannot_omit_original_candidate_path(self):
        self.git("mv", "foundation/input.gd", "foundation/renamed.gd")
        with self.assertRaisesRegex(ValueError, "missing"):
            verify_candidate(self.candidate, source_snapshot(self.root), self.root)

    def test_new_source_during_run_is_reported_as_drift(self):
        before = source_snapshot(self.root)
        (self.root / "foundation/extra.gd").write_bytes(b"added during run\n")
        self.assertEqual(source_drift(before, self.root), ["foundation/extra.gd"])

    def test_rename_during_run_inventories_both_paths(self):
        before = source_snapshot(self.root)
        self.production.rename(self.root / "foundation/new.gd")
        self.assertEqual(source_drift(before, self.root), ["foundation/input.gd", "foundation/new.gd"])

    def test_owner03_test_preparation_is_allowed_above_candidate(self):
        test = self.root / "tests/beta_sprint/game_feel_owner_03/new.gd"
        test.parent.mkdir(parents=True)
        test.write_bytes(b"new Owner03 test\n")
        verify_candidate(self.candidate, source_snapshot(self.root), self.root)

    def test_other_owner_dependency_change_is_not_exempt(self):
        test = self.root / "tests/foundation/level/baker_fixture.gd"
        test.parent.mkdir(parents=True)
        test.write_bytes(b"unregistered author dependency\n")
        with self.assertRaisesRegex(ValueError, "additional"):
            verify_candidate(self.candidate, source_snapshot(self.root), self.root)

if __name__ == "__main__":
    unittest.main()
