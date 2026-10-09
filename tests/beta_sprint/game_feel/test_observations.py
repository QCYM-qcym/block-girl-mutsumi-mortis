"""UNIT: hostile recorded samples, not simulated Runtime/Solver/Replay executions."""

from copy import deepcopy
import unittest

from observations import audio_failures, frame_statistics, motion_failures, rejection_failures


def pose(position=None):
    return {"position": position or [0, 2, 0], "orientation": [1, 0, 0, 0, 1, 0, 0, 0, 1]}


def motion(kind="fall"):
    before = {"state_key": "source", "face": "surface/source/TOP", "pose": pose()}
    after = {"state_key": "target", "face": "surface/target/TOP", "pose": pose([4, 0, 4])}
    if kind == "edge_recoil":
        after = deepcopy(before)
    return dict(kind=kind, runtime_before=before, expected_after=after, runtime_after=deepcopy(after),
                model_start=deepcopy(before["pose"]), model_end=deepcopy(after["pose"]),
                started_ids=["visual1"], committed_ids=[] if kind == "edge_recoil" else ["tx1"],
                expected_commit_ids=[] if kind == "edge_recoil" else ["tx1"],
                finished_ids=["visual1"], max_active_transitions=1, stale_commit_count=0,
                owned_tweens_after=0, owned_vfx_after=0, next_legal_input_accepted=True)


def audio():
    return dict(events=[{"cue": "land", "transaction_id": "tx1", "time_ms": 320.0}],
                expected_counts={"land": 1}, contact={"transaction_id": "tx1", "time_ms": 320.0},
                landing_cue="land", tolerance_ms=5.0)


class MotionAssertions(unittest.TestCase):
    def test_complete_fall_landing_and_recoil(self):
        for kind in ("fall", "landing", "edge_recoil"):
            with self.subTest(kind=kind):
                self.assertEqual(motion_failures(motion(kind)), [])

    def test_detects_each_forbidden_motion_outcome(self):
        defects = {
            "duplicate_commit": lambda s: s["committed_ids"].append("tx1"),
            "duplicate_finish": lambda s: s["finished_ids"].append("tx1"),
            "overlap": lambda s: s.update(max_active_transitions=2),
            "stale_callback": lambda s: s.update(stale_commit_count=1),
            "tween_residue": lambda s: s.update(owned_tweens_after=1),
            "vfx_residue": lambda s: s.update(owned_vfx_after=1),
            "stuck_input": lambda s: s.update(next_legal_input_accepted=False),
            "wrong_face": lambda s: s["runtime_after"].update(face="other/FRONT"),
            "orientation_drift": lambda s: s["model_end"]["orientation"].__setitem__(0, 0.99),
            "wrong_start_pose": lambda s: s["model_start"]["position"].__setitem__(1, 9),
            "wrong_end_position": lambda s: s["model_end"]["position"].__setitem__(1, 9),
        }
        for defect, mutate in defects.items():
            with self.subTest(defect=defect):
                sample = motion()
                mutate(sample)
                self.assertTrue(motion_failures(sample), defect)

    def test_recoil_cannot_mutate_or_commit(self):
        sample = motion("edge_recoil")
        sample["runtime_after"]["pose"]["position"][0] = 1
        self.assertTrue(motion_failures(sample))
        sample = motion("edge_recoil")
        sample["committed_ids"] = ["tx1"]
        self.assertTrue(motion_failures(sample))

    def test_missing_or_nonfinite_evidence_is_not_success(self):
        self.assertTrue(motion_failures({}))
        for value in (float("nan"), float("inf"), True):
            sample = motion()
            sample["model_end"]["position"][0] = value
            self.assertTrue(motion_failures(sample))


class AudioAssertions(unittest.TestCase):
    def test_contact_synchronized_single_cue(self):
        self.assertEqual(audio_failures(audio()), [])

    def test_duplicate_early_late_and_wrong_transaction_cues(self):
        sample = audio()
        sample["events"].append(deepcopy(sample["events"][0]))
        self.assertTrue(audio_failures(sample))
        for value in (290.0, 350.0):
            sample = audio()
            sample["events"][0]["time_ms"] = value
            self.assertTrue(audio_failures(sample))
        sample = audio()
        sample["events"][0]["transaction_id"] = "stale"
        self.assertTrue(audio_failures(sample))

    def test_unexpected_cue_and_missing_evidence(self):
        sample = audio()
        sample["events"].append(dict(cue="recoil", transaction_id="tx1", time_ms=320.0))
        self.assertTrue(audio_failures(sample))
        self.assertTrue(audio_failures({}))


class RejectionAssertions(unittest.TestCase):
    def test_rejected_action_preserves_entire_state(self):
        sample = dict(status="REJECTED", reason="OWNER_REASON", before={"key": "source", "camera": 1},
                      after={"key": "source", "camera": 1}, accepted_ids=[], committed_ids=[])
        self.assertEqual(rejection_failures(sample), [])
        sample["after"]["camera"] = 2
        self.assertTrue(rejection_failures(sample))

    def test_missing_reason_and_side_effects_are_rejected(self):
        for field, value in (("reason", ""), ("accepted_ids", ["tx1"]), ("committed_ids", ["tx1"])):
            sample = dict(status="REJECTED", reason="OWNER_REASON", before={"key": "source"},
                          after={"key": "source"}, accepted_ids=[], committed_ids=[])
            sample[field] = value
            self.assertTrue(rejection_failures(sample))
        self.assertTrue(rejection_failures({}))


class PerformanceAssertions(unittest.TestCase):
    def test_loading_is_separate_from_fall(self):
        stats = frame_statistics([dict(phase="load", frame_ms=111.111),
                                  dict(phase="fall", frame_ms=16.0), dict(phase="fall", frame_ms=18.0)])
        self.assertEqual(stats["load"]["count"], 1)
        self.assertEqual(stats["fall"]["max_ms"], 18.0)
        self.assertEqual(stats["fall"]["p95_ms"], 18.0)
        self.assertNotIn("verdict", stats["fall"])

    def test_invalid_frame_samples_cannot_be_hidden(self):
        for value in (-1, 0, True, float("nan"), float("inf")):
            with self.assertRaises(ValueError):
                frame_statistics([dict(phase="fall", frame_ms=value)])
        with self.assertRaises(ValueError):
            frame_statistics([])


if __name__ == "__main__":
    unittest.main()
