"""Test-only observation assertions. Not an Owner interface or gameplay implementation.

Synthetic samples exercise these assertions only; they never earn REAL or GRAPHICAL PASS.
Owner-specific capture/binding must be added after the formal delivery, without guessing APIs.
"""

from collections import Counter, defaultdict
from math import ceil, isfinite


def _number(value):
    return type(value) in (int, float) and isfinite(value)


def _ids(value):
    return isinstance(value, list) and all(isinstance(item, str) and item for item in value)


def _pose(value):
    return (isinstance(value, dict) and
            isinstance(value.get("position"), list) and len(value["position"]) == 3 and
            isinstance(value.get("orientation"), list) and len(value["orientation"]) == 9 and
            all(_number(item) for item in value["position"] + value["orientation"]))


def _state(value):
    return (isinstance(value, dict) and isinstance(value.get("state_key"), str) and value["state_key"] and
            isinstance(value.get("face"), str) and value["face"] and _pose(value.get("pose")))


def motion_failures(sample):
    if not isinstance(sample, dict):
        return ["missing_motion_evidence"]
    if (sample.get("kind") not in ("fall", "landing", "edge_recoil") or
            not all(_state(sample.get(key)) for key in ("runtime_before", "expected_after", "runtime_after")) or
            not all(_pose(sample.get(key)) for key in ("model_start", "model_end")) or
            not all(_ids(sample.get(key)) for key in ("started_ids", "committed_ids", "expected_commit_ids", "finished_ids")) or
            not all(type(sample.get(key)) is int and sample[key] >= 0 for key in
                    ("max_active_transitions", "stale_commit_count", "owned_tweens_after", "owned_vfx_after")) or
            type(sample.get("next_legal_input_accepted")) is not bool):
        return ["invalid_motion_evidence"]
    failures = []
    # One completed visual window, not a whole held-input session. A Landing window
    # can include the parent Fall transaction; expected commits come from the bound
    # case, never from a guess about how the Owner splits animation phases.
    if len(sample["started_ids"]) != 1 or sample["max_active_transitions"] != 1:
        failures.append("duplicate_or_missing_transition")
    if sample["finished_ids"] != sample["started_ids"]:
        failures.append("duplicate_or_missing_finish")
    if (len(set(sample["committed_ids"])) != len(sample["committed_ids"]) or
            sample["committed_ids"] != sample["expected_commit_ids"]):
        failures.append("wrong_commits")
    if sample["stale_commit_count"]:
        failures.append("stale_commit")
    if sample["runtime_after"] != sample["expected_after"]:
        failures.append("wrong_runtime_state")
    if sample["model_start"] != sample["runtime_before"]["pose"]:
        failures.append("wrong_start_pose")
    if sample["model_end"] != sample["runtime_after"]["pose"]:
        failures.append("wrong_end_pose")
    if sample["kind"] == "edge_recoil" and sample["runtime_after"] != sample["runtime_before"]:
        failures.append("recoil_mutated_state")
    if sample["owned_tweens_after"] or sample["owned_vfx_after"]:
        failures.append("animation_residue")
    if not sample["next_legal_input_accepted"]:
        failures.append("input_not_restored")
    return failures


def audio_failures(sample):
    if not isinstance(sample, dict):
        return ["missing_audio_evidence"]
    events, expected, contact = sample.get("events"), sample.get("expected_counts"), sample.get("contact")
    if (not isinstance(events, list) or not isinstance(expected, dict) or not expected or
            not all(isinstance(cue, str) and cue and type(count) is int and count >= 0
                    for cue, count in expected.items()) or
            not isinstance(contact, dict) or not _number(contact.get("time_ms")) or
            not isinstance(contact.get("transaction_id"), str) or not contact["transaction_id"] or
            not isinstance(sample.get("landing_cue"), str) or not sample["landing_cue"] or
            not _number(sample.get("tolerance_ms")) or sample["tolerance_ms"] < 0 or
            not all(isinstance(event, dict) and isinstance(event.get("cue"), str) and event["cue"] and
                    _number(event.get("time_ms")) and isinstance(event.get("transaction_id"), str) and
                    event["transaction_id"] for event in events)):
        return ["invalid_audio_evidence"]
    failures = []
    if Counter(event["cue"] for event in events) != Counter(expected):
        failures.append("wrong_cue_counts")
    for event in events:
        if event["transaction_id"] != contact["transaction_id"]:
            failures.append("uncorrelated_cue")
        if (event["cue"] == sample["landing_cue"] and
                abs(event["time_ms"] - contact["time_ms"]) > sample["tolerance_ms"]):
            failures.append("landing_contact_desync")
    return failures


def rejection_failures(sample):
    if (not isinstance(sample, dict) or not isinstance(sample.get("before"), dict) or
            not sample["before"] or not isinstance(sample.get("after"), dict) or
            not _ids(sample.get("accepted_ids")) or not _ids(sample.get("committed_ids"))):
        return ["invalid_rejection_evidence"]
    failures = []
    if sample.get("status") != "REJECTED" or not isinstance(sample.get("reason"), str) or not sample["reason"]:
        failures.append("missing_rejection_reason")
    if sample["before"] != sample["after"] or sample["accepted_ids"] or sample["committed_ids"]:
        failures.append("rejection_has_side_effects")
    return failures


def frame_statistics(samples):
    if not isinstance(samples, list) or not samples:
        raise ValueError("Actual frame samples required")
    grouped = defaultdict(list)
    for sample in samples:
        if (not isinstance(sample, dict) or not isinstance(sample.get("phase"), str) or not sample["phase"] or
                not _number(sample.get("frame_ms")) or sample["frame_ms"] <= 0):
            raise ValueError("Invalid phase/frame sample")
        grouped[sample["phase"]].append(sample["frame_ms"])
    result = {}
    for phase, values in grouped.items():
        values.sort()
        result[phase] = {"count": len(values), "max_ms": values[-1]}
        for percentile in (50, 95, 99):
            result[phase][f"p{percentile}_ms"] = values[ceil(len(values) * percentile / 100) - 1]
    # Measurements only. No FPS attribution or invented acceptance budget.
    return result
