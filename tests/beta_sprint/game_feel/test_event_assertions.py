from copy import deepcopy
import unittest
from event_assertions import event_failures, sample_failures

# These immutable recorded fixtures have no Runtime or Safety authority.
FIXTURE_META = dict(fixture_kind="PRESENTATION_CONTRACT_UNIT", authoritative_runtime=False,
                    doubles=["synthetic_event_snapshot", "synthetic_motion_sample"])


def event():
    source = dict(location=dict(layer=0, cube_id="a", face=0), orientation=7)
    target = dict(location=dict(layer=0, cube_id="b", face=0), orientation=7)
    return dict(schema_version=1, contract_version="game_feel.event.v1", semantic="PERSPECTIVE_FALL_APPLIED",
                phase="STARTED", event_id=1, session_id="s", level_run_id="run", attempt_id=1,
                presentation_identity=dict(session_id="s", level_run_id="run", generation=2, attempt_id=1),
                transition_identity=dict(session_id="s", level_run_id="run", generation=2, transaction_id=3, is_global=False),
                result=dict(status=0, previous_state=dict(player=source), next_state=dict(player=target),
                            action={"fixture_versioned_action": True}, changed=True, rejection_code=0, issues=[], global_kind=0),
                reason_category="NONE", source_pose=source, target_pose=target,
                source_face=source["location"], target_face=target["location"], world_id=0,
                camera_quadrant=1, authoritative_final_orientation=7, intended_move_direction=0,
                interruption_reason=None, connection_id="fixture_connection", authorized_path_points2=[[0, 4, 0], [8, 0, 8]],
                motion_profile_id="fixture_profile", motion_profile_hash="f" * 64,
                safety_verdict=dict(status="SAFE", issues=[], evidence_ref=dict(kind="exact_linear_cube_sweep.v1",
                    query="Safety.validate_perspective_motion", before_statekey="fixture_before_key", after_statekey="fixture_after_key",
                    level_hash="fixture_level_hash", connection_id="fixture_connection", profile_hash="f" * 64)),
                orientation_policy="PRESERVE", presentation_duration_seconds=0.4, source_frame={"fixture_frame": True})


def sample():
    return dict(active=True, identity=deepcopy(event()["presentation_identity"]), phase="fall", progress=1.0,
                motion_done=True, position=[4.0, 0.0, 4.0], rotation_offset=[0, 0, 0, 1], scale_multiplier=[1, 1, 1])


def refusal(semantic="ACTION_FEEDBACK", reason="SAFETY_REJECTED"):
    value = event()
    value.update(semantic=semantic, phase="REJECTED" if semantic == "MOVE_REJECTED_EDGE" else "FEEDBACK",
                 reason_category=reason, transition_identity=None, target_pose=None, target_face=None,
                 authoritative_final_orientation=None)
    for field in ("authorized_path_points2", "connection_id", "motion_profile_id", "motion_profile_hash",
                  "safety_verdict", "orientation_policy", "presentation_duration_seconds"):
        value.pop(field)
    value["result"].update(status=1, changed=False, next_state=None)
    if semantic == "ACTION_FEEDBACK":
        value["presentation_identity"] = None
    return value


class EventAssertions(unittest.TestCase):
    def test_malformed_snapshots_fail_closed(self):
        for value in (None, {}, [], 1):
            self.assertTrue(event_failures(value, "PERSPECTIVE_FALL_APPLIED", "NONE"))
        for field in ("presentation_identity", "transition_identity", "source_pose", "target_pose", "result"):
            bad = event()
            bad[field] = 5
            self.assertTrue(event_failures(bad, "PERSPECTIVE_FALL_APPLIED", "NONE"), field)
        for field in ("semantic", "reason_category"):
            for value in ([], {}):
                bad = event()
                bad[field] = value
                self.assertTrue(event_failures(bad, "PERSPECTIVE_FALL_APPLIED", "NONE"), field)

    def test_refusals_preserve_entire_native_state_without_authorized_motion(self):
        for semantic, reason in (("MOVE_REJECTED_EDGE", "EDGE"), ("ACTION_FEEDBACK", "SAFETY_REJECTED"),
                                 ("ACTION_FEEDBACK", "BUSY"), ("ACTION_FEEDBACK", "ERROR")):
            good = refusal(semantic, reason)
            if reason == "ERROR":
                good["result"]["status"] = 2
            before = deepcopy(good["result"]["previous_state"])
            self.assertEqual(event_failures(good, semantic, reason, before, deepcopy(before)), [])
            for field, value in (("target_pose", event()["target_pose"]),
                                 ("transition_identity", event()["transition_identity"]),
                                 ("authorized_path_points2", [[0, 4, 0], [8, 0, 8]])):
                bad = deepcopy(good)
                bad[field] = value
                self.assertTrue(event_failures(bad, semantic, reason, before, deepcopy(before)), field)
            bad = deepcopy(good)
            bad["result"]["next_state"] = deepcopy(before)
            self.assertTrue(event_failures(bad, semantic, reason, before, deepcopy(before)), "forged native next_state")
            after = deepcopy(before)
            after["fixture_camera"] = 3
            self.assertTrue(event_failures(good, semantic, reason, before, after), "actual non-player state change")
            self.assertTrue(event_failures(good, semantic, reason), "missing actual Runtime snapshots cannot prove preservation")
            bad = deepcopy(good)
            bad["result"].update(status=0, changed=True)
            self.assertTrue(event_failures(bad, semantic, reason, before, deepcopy(before)), "false accepted refusal")

    def test_fall_cannot_change_world_or_use_bool_orientation(self):
        bad = event()
        bad["target_pose"]["location"]["layer"] = 1
        self.assertTrue(event_failures(bad, "PERSPECTIVE_FALL_APPLIED", "NONE"))
        bad = event()
        bad["target_pose"]["orientation"] = 1
        bad["source_pose"]["orientation"] = 1
        bad["authoritative_final_orientation"] = True
        self.assertTrue(event_failures(bad, "PERSPECTIVE_FALL_APPLIED", "NONE"))

    def test_valid_snapshot_and_fixture_has_no_authority(self):
        self.assertFalse(FIXTURE_META["authoritative_runtime"])
        self.assertTrue(FIXTURE_META["doubles"])
        self.assertEqual(event_failures(event(), "PERSPECTIVE_FALL_APPLIED", "NONE"), [])

    def test_bad_envelope_or_missing_classification(self):
        for key, value in (("schema_version", True), ("contract_version", "other"),
                           ("reason_category", None), ("world_id", 1), ("camera_quadrant", 4),
                           ("event_id", -1), ("attempt_id", True)):
            bad = event()
            bad[key] = value
            self.assertTrue(event_failures(bad, "PERSPECTIVE_FALL_APPLIED", "NONE"), key)

    def test_full_identity_mismatch(self):
        for key, value in (("session_id", "old"), ("level_run_id", "old"), ("generation", -1), ("attempt_id", 9)):
            bad = event()
            bad["presentation_identity"][key] = value
            self.assertTrue(event_failures(bad, "PERSPECTIVE_FALL_APPLIED", "NONE"), key)

    def test_no_render_orientation_or_height_permission_invention(self):
        for orientation in range(24):
            good = event()
            good["source_pose"]["orientation"] = orientation
            good["target_pose"]["orientation"] = orientation
            good["authoritative_final_orientation"] = orientation
            self.assertEqual(event_failures(good, "PERSPECTIVE_FALL_APPLIED", "NONE"), [])
        bad = event()
        bad["target_pose"]["orientation"] = 24
        self.assertTrue(event_failures(bad, "PERSPECTIVE_FALL_APPLIED", "NONE"))
        bad = event()
        bad["authoritative_final_orientation"] = 8
        self.assertTrue(event_failures(bad, "PERSPECTIVE_FALL_APPLIED", "NONE"))
        # A higher real target is equally valid structural event data; legality
        # comes only from 01, not a downward-Y heuristic in Quality.
        good = event()
        good["authorized_path_points2"][-1][1] = 8
        self.assertEqual(event_failures(good, "PERSPECTIVE_FALL_APPLIED", "NONE"), [])

    def test_missing_path_and_unproven_safety_are_not_evidence(self):
        for key, value in (("authorized_path_points2", []), ("safety_verdict", "SAFE"), ("safety_verdict", "UNKNOWN"),
                           ("presentation_duration_seconds", float("nan")), ("motion_profile_hash", "")):
            bad = event()
            bad[key] = value
            self.assertTrue(event_failures(bad, "PERSPECTIVE_FALL_APPLIED", "NONE"), key)
        for key, value in (("issues", ["unresolved"]), ("evidence_ref", {}), ("status", "UNPROVEN")):
            bad = event()
            bad["safety_verdict"][key] = value
            self.assertTrue(event_failures(bad, "PERSPECTIVE_FALL_APPLIED", "NONE"), key)

    def test_non_edge_feedback_cannot_be_presented_as_edge(self):
        for reason in ("MECHANISM_LOCKED", "BUSY", "INVALID_FACE", "SAFETY_REJECTED", "INVALID_ACTION", "UNCLASSIFIED_REJECTION"):
            bad = event()
            bad.update(semantic="MOVE_REJECTED_EDGE", phase="REJECTED", reason_category="EDGE")
            self.assertTrue(event_failures(bad, "ACTION_FEEDBACK", reason))


class SampleAssertions(unittest.TestCase):
    def test_exact_authorized_endpoint(self):
        self.assertEqual(sample_failures(sample(), event()["presentation_identity"], [4.0, 0.0, 4.0]), [])
        bad = sample()
        bad["position"][0] += 0.01
        self.assertTrue(sample_failures(bad, event()["presentation_identity"], [4.0, 0.0, 4.0]))

    def test_late_old_identity_cannot_match_new_launch(self):
        new_identity = deepcopy(event()["presentation_identity"])
        for key in ("generation", "attempt_id"):
            new_identity[key] += 1
        self.assertTrue(sample_failures(sample(), new_identity, [4.0, 0.0, 4.0]))

    def test_cleared_decorative_sample_is_neutral(self):
        good = sample()
        good.update(active=False, identity=None, position=None, rotation_offset=[0, 0, 0, 1], scale_multiplier=[1, 1, 1])
        self.assertEqual(sample_failures(good, None, neutral=True), [])
        for key, value in (("rotation_offset", [0, 0.1, 0, 1]), ("scale_multiplier", [1, 0.9, 1]), ("position", [4, 0, 4])):
            bad = deepcopy(good)
            bad[key] = value
            self.assertTrue(sample_failures(bad, None, neutral=True), key)


if __name__ == "__main__":
    unittest.main()
