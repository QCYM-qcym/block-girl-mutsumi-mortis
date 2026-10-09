"""Assertions over captured event/sample records; no classification, permission or motion algorithm.

Vectors/quaternions below are JSON measurement arrays captured by a future Quality
observer. They do not change the native Vector3i/Vector3/Quaternion port ABI.
"""

from math import isfinite


def _int(value, lower=0, upper=None):
    return type(value) is int and value >= lower and (upper is None or value <= upper)


def _text(value):
    return isinstance(value, str) and bool(value)


def _vector(value, count):
    return (isinstance(value, list) and len(value) == count and
            all(type(item) in (int, float) and isfinite(item) for item in value))


def _location(value):
    return (isinstance(value, dict) and _int(value.get("layer"), 0, 1) and
            _text(value.get("cube_id")) and _int(value.get("face"), 0, 5))


def _pose(value):
    return isinstance(value, dict) and _location(value.get("location")) and _int(value.get("orientation"), 0, 23)


def _identity(value, field):
    return (isinstance(value, dict) and _text(value.get("session_id")) and _text(value.get("level_run_id")) and
            _int(value.get("generation")) and _int(value.get(field)))


def _safe(value, event):
    if not isinstance(value, dict) or value.get("status") != "SAFE" or value.get("issues") != []:
        return False
    ref = value.get("evidence_ref")
    return (isinstance(ref, dict) and
            all(_text(ref.get(key)) for key in ("kind", "query", "before_statekey", "after_statekey", "level_hash")) and
            ref.get("connection_id") == event.get("connection_id") and ref.get("profile_hash") == event.get("motion_profile_hash"))


def event_failures(event, expected_semantic, expected_reason, runtime_before=None, runtime_after=None):
    required = {"schema_version", "contract_version", "semantic", "phase", "event_id", "session_id", "level_run_id",
                "attempt_id", "presentation_identity", "transition_identity", "result", "reason_category",
                "source_pose", "target_pose", "source_face", "target_face", "world_id", "camera_quadrant",
                "authoritative_final_orientation", "intended_move_direction", "interruption_reason"}
    if not isinstance(event, dict) or not required <= event.keys():
        return ["missing_event_evidence"]
    errors = []
    semantics = {"MOVE_APPLIED_NORMAL", "PERSPECTIVE_FALL_APPLIED", "MOVE_REJECTED_EDGE", "ANIMATION_INTERRUPTED", "ACTION_FEEDBACK"}
    reasons = {"NONE", "EDGE", "MECHANISM_LOCKED", "BUSY", "INVALID_FACE", "SAFETY_REJECTED", "INVALID_ACTION",
               "CAMERA_NOT_ALLOWED", "WORLD_NOT_ALLOWED", "FALL_NOT_AVAILABLE", "UNCLASSIFIED_REJECTION", "ERROR"}
    if (type(event["schema_version"]) is not int or event["schema_version"] != 1 or
            event["contract_version"] != "game_feel.event.v1" or not _int(event["event_id"]) or
            not _int(event["attempt_id"]) or not _text(event["session_id"]) or not _text(event["level_run_id"]) or
            not _int(event["camera_quadrant"], 0, 3) or not _int(event["world_id"], 0, 1) or
            not _text(event["semantic"]) or event["semantic"] not in semantics or
            not _text(event["reason_category"]) or event["reason_category"] not in reasons):
        errors.append("invalid_event_envelope")
    if event["semantic"] != expected_semantic or event["reason_category"] != expected_reason:
        errors.append("wrong_authoritative_classification")
    if not _pose(event["source_pose"]) or event["source_face"] != event["source_pose"].get("location"):
        errors.append("invalid_source_pose")
    elif event["world_id"] != event["source_pose"]["location"]["layer"]:
        errors.append("wrong_world")
    presentation = event["presentation_identity"]
    if presentation is not None:
        if not _identity(presentation, "attempt_id"):
            errors.append("invalid_presentation_identity")
        elif event["semantic"] != "ANIMATION_INTERRUPTED" and any(
                presentation[key] != event[key] for key in ("session_id", "level_run_id", "attempt_id")):
            errors.append("uncorrelated_presentation_identity")
    result = event["result"]
    result_fields = {"status", "previous_state", "next_state", "action", "changed", "rejection_code", "issues", "global_kind"}
    if (not isinstance(result, dict) or not result_fields <= result.keys() or
            not _int(result["status"], 0, 2) or type(result["changed"]) is not bool or not isinstance(result["issues"], list)):
        errors.append("invalid_native_result")
        return errors
    accepted = event["semantic"] in ("MOVE_APPLIED_NORMAL", "PERSPECTIVE_FALL_APPLIED")
    if accepted:
        transition = event["transition_identity"]
        if (event["phase"] not in ("STARTED", "COMMITTED") or result["status"] != 0 or not result["changed"] or
                presentation is None or not _identity(transition, "transaction_id") or
                type(transition.get("is_global")) is not bool):
            errors.append("invalid_accepted_transition")
        elif isinstance(presentation, dict) and all(key in presentation for key in ("session_id", "level_run_id", "generation")):
            if any(transition[key] != presentation[key] for key in ("session_id", "level_run_id", "generation")):
                errors.append("uncorrelated_transition_identity")
        target = event["target_pose"]
        if (not _pose(target) or event["target_face"] != target.get("location") or
                not _int(event["authoritative_final_orientation"], 0, 23) or
                event["authoritative_final_orientation"] != target.get("orientation")):
            errors.append("invalid_target_pose")
        if not isinstance(result["previous_state"], dict) or result["previous_state"].get("player") != event["source_pose"]:
            errors.append("source_differs_from_native_result")
        if not isinstance(result["next_state"], dict) or result["next_state"].get("player") != target:
            errors.append("target_differs_from_native_result")
        if event["semantic"] == "PERSPECTIVE_FALL_APPLIED":
            if _pose(target) and target["location"]["layer"] != event["world_id"]:
                errors.append("fall_changed_world")
            if _pose(target) and _pose(event["source_pose"]) and target["orientation"] != event["source_pose"]["orientation"]:
                errors.append("preserve_orientation_mismatch")
            if event["phase"] == "STARTED":
                points = event.get("authorized_path_points2")
                duration = event.get("presentation_duration_seconds")
                if (not isinstance(points, list) or len(points) < 2 or
                        not all(isinstance(point, list) and len(point) == 3 and all(type(v) is int for v in point) for point in points) or
                        not _text(event.get("connection_id")) or not _text(event.get("motion_profile_id")) or
                        not _text(event.get("motion_profile_hash")) or not _safe(event.get("safety_verdict"), event) or
                        event.get("orientation_policy") != "PRESERVE" or type(duration) not in (int, float) or
                        not isfinite(duration) or duration <= 0 or not event.get("source_frame")):
                    errors.append("missing_authorized_path_evidence")
    if event["semantic"] == "MOVE_REJECTED_EDGE":
        if (event["phase"] != "REJECTED" or event["reason_category"] != "EDGE" or result["status"] != 1 or result["changed"] or
                presentation is None or event["transition_identity"] is not None or event["target_pose"] is not None or
                event["target_face"] is not None or event["authoritative_final_orientation"] is not None or
                not _int(event["intended_move_direction"], 0, 3) or not event.get("source_frame")):
            errors.append("edge_has_authority_or_missing_direction")
    refusal = event["semantic"] == "MOVE_REJECTED_EDGE" or (
        event["semantic"] == "ACTION_FEEDBACK" and event["reason_category"] != "NONE")
    if refusal:
        if (result["status"] not in (1, 2) or result["changed"] or
                not isinstance(result["previous_state"], dict) or result["next_state"] is not None or
                result["previous_state"].get("player") != event["source_pose"]):
            errors.append("invalid_native_refusal_shape")
        if (not isinstance(runtime_before, dict) or not isinstance(runtime_after, dict) or
                runtime_before != runtime_after or result["previous_state"] != runtime_before):
            errors.append("missing_or_changed_actual_runtime_state")
        if (event["transition_identity"] is not None or event["target_pose"] is not None or
                event["target_face"] is not None or event["authoritative_final_orientation"] is not None or
                event.get("authorized_path_points2") is not None):
            errors.append("refusal_has_accepted_motion_authority")
    if event["semantic"] == "ACTION_FEEDBACK" and event["phase"] != "FEEDBACK":
        errors.append("wrong_feedback_phase")
    if event["semantic"] == "ANIMATION_INTERRUPTED" and (
            event["phase"] != "INTERRUPTED" or presentation is None or
            event["interruption_reason"] not in ("RESET", "RELOAD", "UNLOAD", "QUIT", "CANCEL")):
        errors.append("invalid_interruption")
    return errors


def sample_failures(sample, expected_identity, expected_position=None, neutral=False):
    if (not isinstance(sample, dict) or type(sample.get("active")) is not bool or
            type(sample.get("motion_done")) is not bool or not _text(sample.get("phase")) or
            type(sample.get("progress")) not in (int, float) or not isfinite(sample["progress"]) or
            not 0 <= sample["progress"] <= 1 or not _vector(sample.get("rotation_offset"), 4) or
            not _vector(sample.get("scale_multiplier"), 3) or
            (sample.get("position") is not None and not _vector(sample["position"], 3))):
        return ["invalid_motion_sample"]
    errors = []
    if sample["active"] and (not _identity(sample.get("identity"), "attempt_id") or sample.get("identity") != expected_identity):
        errors.append("wrong_captured_identity")
    if sample.get("position") != expected_position:
        errors.append("wrong_sampled_position")
    if neutral and (sample["active"] or sample["rotation_offset"] != [0, 0, 0, 1] or sample["scale_multiplier"] != [1, 1, 1]):
        errors.append("non_neutral_cleared_sample")
    return errors
