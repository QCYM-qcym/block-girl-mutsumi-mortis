"""Bind the existing 94 inventory rows to captured executions; no gameplay algorithms."""
from collections import Counter
import hashlib
import json
from pathlib import Path

from matrix import cases, CONTRACT_SHA256
from event_assertions import event_failures
from v2_reports import core_mapping, execution_identity_failures

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / "docs/beta-sprint/game-feel-owner-03/v2"
EVIDENCE = OUT / "evidence"
HEAD = "99f2f1db9d9646d8fc7f3856fc4e64df81ff6cff"
SELECTED = ["natural_01", "spam_01", "logical_path_01", "lifecycle_03", "audio_lifecycle_04",
            "feedback_02", "permissions_01", "swept_safety_01", "legacy_focused_01", "legacy_02",
            "ui_960_guarded_03", "ui_1280_01", "ui_1920_01", "ui_lifecycle_01",
            "cold_seed_03", "cold_restore_03", "quit_seed_01", "quit_restore_01", "formal_gfx_04"]


def read(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def report(name):
    filename = "matrix.json" if name.startswith("ui_") and "guarded" in name or name in ("ui_1280_01", "ui_1920_01") else "report.json"
    return read(EVIDENCE / name / filename)


def build():
    contract = ROOT / "docs/beta-sprint/game-feel/GAME_FEEL_CONTRACT.md"
    assert sha(contract) == CONTRACT_SHA256
    records = {}
    for name in SELECTED:
        folder = EVIDENCE / name
        process = read(folder / "process.json")
        assert process["execution_head"] == HEAD and process["status"] in ("PASS", "BLOCKED")
        assert process["exit_code"] == 0 and process["checks"] > 0 and process["failures"] == []
        assert process["doubles"] == [] and process["stderr_bytes"] == 0 and process["source_drift"] == []
        if process["mode"] == "GRAPHICAL":
            # Audit old receipts using their preserved raw renderer startup evidence.
            raw_name = "matrix.json" if name in ("ui_1280_01", "ui_1920_01", "ui_960_guarded_03") else "unit.json" if name == "ui_lifecycle_01" else "seed.json" if "seed" in name else "restore.json" if "restore" in name else "report.json"
            raw = read(folder / raw_name)
            profile = Path(process["profile_environment"]["APPDATA"]).parent
            assert execution_identity_failures(raw, True, profile, (folder / "stdout.log").read_text(encoding="utf-8"), process["pid"]) == []
        records[name] = {"process": f"evidence/{name}/process.json", "checks": process["checks"],
                         "status": process["status"], "mode": process["mode"], "pid": process["pid"],
                         "process_sha256": sha(folder / "process.json"), "source_sha256": process["source_sha256"],
                         "asset_hashes_captured_during_run": any(p.startswith("production/experimental/game_feel_01/audio/") for p in process["source_sha256"])}
    receipt_path = ROOT / "docs/beta-sprint/game-feel/pfall-first-slice/CORE_PLAYABLE_RECEIPT.json"
    receipt = read(receipt_path)
    old = {**core_mapping(receipt), "receipt": str(receipt_path.relative_to(ROOT)).replace("\\", "/"),
           "receipt_sha256": sha(receipt_path), "registered_source": receipt["validated_integration_source"],
           "baseline_receipt_commit": "4b90a4bdb102550ad99cb3695fd49e394c1c447c",
           "rows": receipt["registered_quality_cases"], "counted_again": False}
    selected_trace_evidence = []
    for route in report("logical_path_01")["routes"]:
        letter = route["map"]
        trace = next(row for row in report("formal_gfx_04")["rows"] if row["map"] == letter)["trace"]
        native = next(row for row in report("natural_01")["rows"] if row["map"] == letter)
        spam = next(row for row in report("spam_01")["rows"] if row["map"] == letter)
        settled = next(row for row in report("lifecycle_03")["cases"] if row["map"] == letter and row["id"] == "A_INPUT_LANDING_REVERSE")
        assert trace == route["trace"] and trace["policy_descriptor"]["mode"] == 1
        assert native["before"] == trace["initial_state"] and native["after"] == trace["steps"][0]["expected_state"]
        assert spam["final_statekey"] == trace["goal_statekey"]
        assert settled["after"] == trace["steps"][1]["expected_state"] and settled["status"] == "PASS"
        selected_trace_evidence.append({"map": letter, "level_hash": route["level_hash"], "original_full_graph_trace_equals_formal_probe_trace": True,
            "natural_before_and_fall_endpoint_match_selected_trace": True, "natural_roll_goal_statekey_matches_selected_trace": True,
            "settled_natural_goal_complete_state_matches_selected_trace": True, "pose_evidence": "lifecycle_03/A_INPUT_LANDING_REVERSE",
            "formal_graphical_match": False})
    inventory = cases()
    assert len(inventory) == 94 and len({c["id"] for c in inventory}) == 94
    results = {c["id"]: {"id": c["id"], "area": c["area"], "requested_mode": c["mode"],
                             "expected": c["expected"], "status": "PENDING", "evidence": [],
                             "scope_or_missing": "NOT_RUN: full requested case not executed; no substitute or mock PASS",
                             "dependencies": c["dependencies"], "execution_source": HEAD,
                             "counting": "one matrix row; assertions belong to shared execution receipts"} for c in inventory}

    def mark(ids, status, evidence, scope, dependencies=()):
        for case_id in ids.split():
            assert case_id in results
            assert all(name in records for name in evidence)
            results[case_id].update(status=status, evidence=list(evidence), scope_or_missing=scope, dependencies=list(dependencies))

    mark("CORE_A_NATURAL_FALL CORE_B_NATURAL_FALL CORE_CAMERA_REJECT CORE_NO_CONNECTION CORE_CONSECUTIVE_FALL CORE_LANDING_NEXT_MOVE CORE_RESET_INPUT CORE_STATEKEY", "PASS",
         ["natural_01", "spam_01", "lifecycle_03"], "Registered A/B source pipeline; real native inputs, natural Fall/Landing, full keys/World/Orientation/physical pose; shared receipts counted once")
    mark("CORE_ORDINARY_CONTROLS", "PASS", ["natural_01", "legacy_focused_01", "legacy_02"],
         "Natural A/B ordinary Roll; real legacy P01 authored connection routes. Legacy observable identity kept separate from Foundation StateKey")
    mark("CORE_CROSS_WORLD", "PENDING", ["logical_path_01"], "Partial direct Kernel negative only; Core lab has no native Shift/Inner binding for complete graphical case", ["00_WORLD_INPUT_BINDING", "09_REAL_CROSS_WORLD_GRAPHICAL_INPUT"])
    mark("CORE_HELD_REVERSE_BUSY", "PENDING", ["spam_01", "lifecycle_03"], "WASD/QE/reverse PASS; Core lab lacks mouse-drag and supported Space flow required by whole row", ["00_CORE_DRAG_SHIFT_BINDING"])
    mark("CORE_SAFETY_SOLVER_REPLAY FORMAL_REPLAY", "PENDING", ["logical_path_01", "swept_safety_01", "formal_gfx_04"],
         "Real Solver/Safety/LOGICAL_SESSION PASS; formal GRAPHICAL mode1 ERROR3016, matched_steps=0", ["00_10A_GAME_FEEL_GRAPHICAL_COMPLETION_BRIDGE", "01_FORMAL_REPLAYER_CONSUMPTION"])

    lifecycle = report("lifecycle_03")["cases"]
    for reason, case_id, semantic in (("BUSY", "A_INPUT_FALL_EDGE_SPAM", "ACTION_FEEDBACK"), ("EDGE", "A_INPUT_LANDING_EDGE_SPAM", "MOVE_REJECTED_EDGE")):
        matching = [c for c in lifecycle if c["id"] == case_id]
        assert {c["map"] for c in matching} == {"a", "b"}
        for c in matching:
            observed = [o for o in c["feedback_observations"] if o["event"]["reason_category"] == reason]
            assert len(observed) == 13
            assert all(event_failures(o["event"], semantic, reason, c["before"], o["actual_state"]) == [] for o in observed)
        mark("G_EVENT_" + reason, "PASS", ["lifecycle_03"], "Actual authoritative native classification/result; 13 attempts per map and full observed state preserved; no inferred EDGE")
    normals = [e for c in lifecycle for e in c["events"] if e["semantic"] == "MOVE_APPLIED_NORMAL"]
    assert normals and all(event_failures(e, "MOVE_APPLIED_NORMAL", "NONE") == [] for e in normals)
    mark("G_EVENT_NONE", "PASS", ["lifecycle_03", "logical_path_01"], "Actual ordinary MOVE STARTED/COMMITTED event envelope, native result and formal target/Orientation")
    feedback = report("feedback_02")["rows"]
    for reason in ("INVALID_ACTION", "MECHANISM_LOCKED"):
        observed = [o for o in feedback if o.get("expected_reason", "INVALID_ACTION") == reason]
        assert observed and all(event_failures(o["event"], "ACTION_FEEDBACK", reason, o["before"], o["after"]) == [] for o in observed)
        mark("G_EVENT_" + reason, "PASS", ["feedback_02"], "Actual default Facade; malformed caller inputs or explicit canonical locked-flag data variant; entire actual state/key and native reason retained")
    sweeps = report("swept_safety_01")["rows"]
    assert len(sweeps) == 2 and all(o["runtime_negative"] == "EXECUTED" for o in sweeps)
    assert all(event_failures(o["events"][0], "ACTION_FEEDBACK", "SAFETY_REJECTED", o["before"], o["after"]) == [] for o in sweeps)
    mark("G_EVENT_SAFETY_REJECTED G_REJECT_SWEPT_OBSTACLE FORMAL_SAFETY", "PASS", ["swept_safety_01", "logical_path_01"],
         "Real Swept Safety/Kernel/default Facade: exact A/B SAFE sweeps plus delivered 01 fixture data with explicit mid-path obstacle, canonical hash, native SAFETY_REJECTED and unchanged complete state; no volume/algorithm double")
    mark("G_EVENT_INVALID_FACE G_EVENT_UNCLASSIFIED_REJECTION", "PENDING", [], "Need reachable default Runtime inputs for these reasons; invalid injected state or manufactured RuleResult is not a real event case", ["01_REACHABLE_NEGATIVE_INPUT_DATA"])

    mark("G_FALL_LOWER_SURFACE G_FALL_HIGHER_SURFACE", "PASS", ["natural_01"], "Real registered author Map A/B + natural Presenter endpoint; actual real height lower/higher, screen descent")
    mark("G_FALL_LOWER_INNER G_FALL_HIGHER_INNER G_WORLD_PERMISSIONS", "PASS", ["permissions_01"],
         "REAL logical Runtime scope: public 09 author/Baker input variants, Surface/Inner × allowed/restricted for both heights; exact native proposal/commit. Captured-identity LOGICAL completion, not natural graphical or registered 09 Inner map delivery")
    mark("G_REJECT_INVALID_VIEW G_FALL_FORBIDDEN_QUADRANT_1 G_FALL_FORBIDDEN_QUADRANT_2 G_FALL_FORBIDDEN_QUADRANT_3", "PASS", ["natural_01"], "Actual native authoritative Camera Q/E; all excluded quadrants 0/2/3 on registered A/B; CAMERA_NOT_ALLOWED and full body/state unchanged")
    mark("G_REJECT_NO_CONNECTION", "PASS", ["natural_01"], "Real default Facade admits canonical no-connection control; Fall rejects without transition/body motion")
    mark("G_REJECT_INVALID_LANDING G_REJECT_WRONG_WORLD", "PENDING", ["logical_path_01"], "Partial direct invalid Kernel inputs only; need complete admitted author negative + actual before/after default Runtime evidence", ["01_09_ADMITTED_NEGATIVE_INPUT_DATA"])
    mark("G_REJECT_UNKNOWN_SAFETY", "PENDING", [], "No official reachable incomplete-Safety input delivered; do not inject fake safety result", ["01_INCOMPLETE_SAFETY_INPUT_DATA"])
    mark("G_NO_AUTO_FALL", "PASS", ["audio_lifecycle_04"], "Real Main native A/B stays idle 0.8s before departure: complete state unchanged, no transition/commit")
    mark("G_CUBE24_ENDPOINTS", "PENDING", ["logical_path_01"], "All24 Kernel preservation controls PASS; full24 Runtime commits/StateKeys and natural graphical endpoints not executed", ["09_24_ORIENTATION_AUTHOR_INPUTS", "03_FULL_ENDPOINT_EXECUTION"])

    mark("A_POSE_FALL A_POSE_LANDING", "PASS", ["natural_01", "lifecycle_03"], "Actual start/intermediate/contact/settled physical actor transforms, exact formal cube24 basis, authorized canonical endpoint and full token")
    inputs = {c["id"] for c in lifecycle}
    assert len(inputs) == 12 and len(lifecycle) == 24 and all(c["status"] == "PASS" for c in lifecycle)
    mark(" ".join(sorted(inputs)), "PASS", ["lifecycle_03"], "Actual A/B Fall/Landing phase, native held/spam/reverse/QE/Reset/Pause; required captured commits, full authorized state/key, no residual scene Tweens, released input, subsequent natural Fall; Audio evaluated separately")
    for phase in ("FALL", "LANDING"):
        mark(" ".join("A_INPUT_" + phase + "_" + key for key in ("MOUSE_DRAG", "SPACE", "EXIT_LEVEL")), "PENDING", [],
             "Core lab has no native drag/Shift flow; mid-phase real Shell exit not executed. Legacy Shift/exit and generic UI exit do not replace this case", ["00_PHASE_INPUT_EXIT_BINDING", "03_MID_PHASE_EXIT_EXECUTION"])
    edge_ids = [key for key in results if key.startswith("A_INPUT_EDGE_RECOIL_") or key == "A_POSE_EDGE_RECOIL"]
    mark(" ".join(edge_ids), "PENDING", ["lifecycle_03"], "Native EDGE rejection is real; tested 99f Core Host does not wire 10B Recoil. 00 candidate1938096 is not consumed in this report", ["00_10B_FULL_SLICE_HOST_INTAKE"])
    mark("A_REPEAT_100 A_CANCEL_LATE_NEW_LAUNCH A_PAUSE_IDENTITY", "PENDING", ["lifecycle_03", "ui_lifecycle_01", "audio_lifecycle_04"],
         "Partial Fall/Landing lifecycle and late callback negatives PASS; whole Recoil/focus/drag/VFX/audio/100-cycle requirements not executed", ["00_10B_FULL_SLICE_HOST_INTAKE", "05_VFX_INTAKE", "03_FULL_SCOPE_EXECUTION"])
    mark("A_SIX_VISIBLE_FACES ART_GLB ART_SHADER ART_VFX PERF_SOAK PERF_PHASES", "PENDING", [], "New 05 art/VFX intake, six-face new motions, 30min soak and full phase/budget observations pending; old imported art and empty current stderr are not substitutes", ["00_05_ART_VFX_INTAKE", "10A_10B_PHASE_BUDGET", "03_FULL_SCOPE_EXECUTION"])
    mark("PERF_L04_LOAD", "PENDING", ["legacy_focused_01"], "Real L04 played; separate cold/warm load and animation distributions not captured. Historical load minimum9FPS is not attributed to new Fall", ["03_SEPARATE_LOAD_PERFORMANCE_CAPTURE"])

    seed, restore = (read(EVIDENCE / name / "process.json") for name in ("cold_seed_03", "cold_restore_03"))
    assert seed["pid"] != restore["pid"] and seed["profile_environment"] == restore["profile_environment"]
    assert seed["profile_saves_after"] and seed["profile_saves_after"] == restore["profile_saves_before"]
    seed_ob = read(EVIDENCE / "cold_seed_03/seed.json")["observations"]
    restore_ob = read(EVIDENCE / "cold_restore_03/restore.json")["observations"]
    assert seed_ob["settings"] == restore_ob["settings"] and seed_ob["audio"]["bus_gains"] == restore_ob["audio"]["bus_gains"]
    mark("AU_VOLUME", "PASS", ["audio_lifecycle_04", "ui_lifecycle_01", "cold_seed_03"], "Actual Master/Music/SFX formal base gains, mute preview/apply/cancel/save-failure rollback; no Gameplay mutation")
    mark("AU_COLD_RESTORE", "PASS", ["cold_seed_03", "cold_restore_03"], "Independent actual PIDs, same isolated SaveStore path and matching seed-after/restore-before SHA; settings, accessibility and actual gains restored. Continue may legitimately update later save bytes")
    mark("UI_HUD_RESOLUTIONS", "PASS", ["ui_960_guarded_03", "ui_1280_01", "ui_1920_01"], "Real Windows 960x720/1280x720/1920x1080 HUD/settings/menu, native mouse/keyboard focus, rendered captures and bounded controls; Human QA NOT_RUN; invalid first960 attempt retained separately")
    mark("AU_EVENTS AU_PAUSE AU_DEDUP_THROTTLE", "PENDING", ["audio_lifecycle_04", "ui_lifecycle_01"], "Actual Fall start/whoosh/landing multiplicity, paused stream flags and Reset cancellation PASS; complete Landing/Recoil/exit/held-edge audio sequence pending", ["00_10B_11_FULL_SLICE_INTAKE", "03_FULL_AUDIO_SEQUENCE"])
    mark("AU_CONTACT", "PENDING", ["audio_lifecycle_04"], "Landing cue callback occurs at actual formal actor contact center; no delivered sync tolerance or hardware A/V recording, so whole row is pending", ["11_CONTACT_SYNC_TOLERANCE", "03_AV_CAPTURE"])
    mark("UI_REDUCED_MOTION UI_REASON_SETTINGS", "PENDING", ["ui_lifecycle_01", "cold_seed_03", "cold_restore_03", "ui_960_guarded_03"], "Actual saved Reduced Motion/Hint Strength and Fall normal/reduced logic PASS; all motions/real reasons/locked UI require Full Slice intake", ["00_07_10B_FULL_SLICE_INTAKE", "03_ALL_REASON_MOTION_EXECUTION"])
    mark("FORMAL_SOLVER", "PASS", ["logical_path_01", "formal_gfx_04"], "Same canonical A/B, official Solver/complete Explorer, structural + semantic selected original witness, matching Goal keys, real Softlock graph; no Solver double")
    legacy = report("legacy_focused_01")["rows"]
    assert len(legacy) == 5 and all(row["status"] == "PASS" and row["final"]["goal"] for row in legacy)
    mark(" ".join(row["id"] for row in legacy), "PASS", ["legacy_focused_01"], "Actual L01-L05 native Roll/Shift/view/Reset/Pause/Goal recipes, visual Orientation parity and released level; public Shell API start/exit; P01 identity not Foundation StateKey")
    mark("REG_L06", "PENDING", [], "CONDITIONAL_NOT_RUN: L06 is absent from tested formal catalog/integration scope", ["00_L06_SCOPE_RECEIPT"])

    counts = dict(Counter(row["status"] for row in results.values()))
    for status in ("PASS", "FAIL", "PENDING"): counts.setdefault(status, 0)
    assert sum(counts.values()) == 94
    failures = [{"evidence": f"evidence/{name}/process.json", "kind": "HARNESS_EXECUTION_FAILURE_NOT_PRODUCT_VERDICT", "record": read(folder / "process.json")} for folder in sorted(EVIDENCE.iterdir()) if (folder / "process.json").exists() for name in [folder.name] if read(folder / "process.json")["status"] == "FAIL"]
    payload = {"task": "PFALL_V2_GRAPHICAL_TRACE_AND_MATRIX_01", "report": "PFALL_V2_QUALITY_MATRIX_REPORT", "execution_source": HEAD,
               "contract_mismatch": "NONE", "contract_sha256": CONTRACT_SHA256, "matrix_definition_sha256": sha(ROOT / "tests/beta_sprint/game_feel/matrix.py"),
               "core_69": old, "matrix_counts": counts, "cases": list(results.values()), "executions": records,
               "selected_original_trace_evidence": selected_trace_evidence,
               "selected_unique_pass_assertions": sum(p["checks"] for p in records.values() if p["status"] == "PASS"),
               "formal_graphical": "BLOCKED", "formal_graphical_probe_checks": 13, "formal_graphical_matched_steps": 0,
               "natural_presenter": "PASS_REGISTERED_MAP_AB", "logical_replay": "PASS_TWO_MATCHED_STEPS_PER_MAP",
               "runtime_parity": "PASS_EXECUTED_SCOPE", "graphical_parity": "NATURAL_AB_PASS; FORMAL_GRAPHICAL_BLOCKED",
               "doubles_in_real_executions": [], "python_unit_test_scope": "38 synthetic/assertion utility tests; not REAL or matrix cases",
               "failed_attempts_preserved": failures, "new_confirmed_runtime_presenter_failures": [],
               "full_slice_candidate_not_consumed": "1938096d48f5edcfc247923a4badf13877c3eb1b; separately reported by00, not03 evidence",
               "commit_identity_note": "execution HEAD plus per-file hashes bind WIP; final Quality commit is reported after commit and must not be backdated as execution HEAD",
               "push": "NOT_RUN"}
    (OUT / "MATRIX_94.json").write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
    lines = ["# PFALL_V2_QUALITY_MATRIX_REPORT", "", f"Execution source: `{HEAD}`. CONTRACT_MISMATCH: NONE. Push: NOT_RUN.", "",
             f"94 rows: **{counts['PASS']} PASS / {counts['FAIL']} FAIL / {counts['PENDING']} PENDING**. Full Game Feel acceptance is pending.", "",
             "69 historical Core checks are **three registered rows**, from source `6074e48a8cfa98e34a2eb8533c37fa3aefdd97be`; included as references, never counted as69 matrix cases or added again to current assertions.", "",
             "FORMAL_GRAPHICAL TraceReplayer: **BLOCKED**, mode1 ERROR3016 / dependencies.GameFeelPresenter / GAME_FEEL_GRAPHICAL_COMPLETION_BRIDGE, zero matched steps. The13 successful dependency-probe assertions do not make graphical replay PASS.", "",
             "NATURAL_GRAPHICAL Presenter: PASS A/B Fall → Landing → Roll → Goal. LOGICAL_SESSION Replay: PASS2 matched steps/map. Runtime/physical pose parity: PASS in executed scope; formal graphical parity remains BLOCKED.", "",
             f"Selected unique successful execution assertions: **{payload['selected_unique_pass_assertions']}**. Shared evidence is counted once, excluding superseded attempts, the historical69, blocked probe and38 synthetic Python tests. See [structured report](MATRIX_94.json) for exact process/source hashes and per-row scope.", "",
             "No confirmed new Runtime/Presenter product failures. Parse/receipt/Audio assertion mistakes were fixed in03; the first960 Apply attempt produced an unsafe inherited test field-access error and timeout with test source drift. It remains preserved as invalid harness evidence, not a Runtime/UI product verdict. Two later guarded960 runs PASS71; three resolutions are recorded. No result here upgrades00's1938096 Full Slice candidate or Human QA.", "",
             "| Case | Result | Evidence | Executed scope / remaining dependency |", "|---|---|---|---|"]
    for row in results.values():
        links = ", ".join(f"[{name}](evidence/{name}/process.json)" for name in row["evidence"]) or "NOT_RUN"
        scope = row["scope_or_missing"].replace("|", "/")
        deps = "; " + ", ".join(row["dependencies"]) if row["dependencies"] else ""
        lines.append(f"| {row['id']} | {row['status']} | {links} | {scope}{deps} |")
    (OUT / "MATRIX_94.md").write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")
    print(json.dumps({"matrix": counts, "unique_pass_checks": payload["selected_unique_pass_assertions"], "formal_graphical": "BLOCKED"}))


if __name__ == "__main__":
    build()
