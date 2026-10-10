"""03 receipt assembly only: preserve the sealed 94 inventory and count each row once."""
import argparse
from collections import Counter
from copy import deepcopy
import hashlib
import json
from pathlib import Path

from matrix import cases, CONTRACT_SHA256
from v2_reports import execution_identity_failures

ROOT = Path(__file__).resolve().parents[3]
OLD = ROOT / "docs/beta-sprint/game-feel-owner-03/v2"
OUT = ROOT / "docs/beta-sprint/game-feel-owner-03/graphical-bridge-02"


def read(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def relative(path):
    return path.relative_to(ROOT).as_posix()


def require(condition, message="Invalid quality evidence"):
    if not condition:
        raise ValueError(message)


def receipt(name):
    folder = OLD / "evidence" / name
    process = read(folder / "process.json")
    raw_path = folder / ("matrix.json" if process["job"] == "full_slice_graphical" else "report.json")
    raw = read(raw_path)
    require(process["status"] == "PASS" and process["exit_code"] == 0)
    require(type(process["checks"]) is int and process["checks"] > 0)
    require(process["checks"] == raw["checks"] and raw["failures"] == process["failures"] == [])
    require(raw["doubles"] == process["doubles"] == [])
    require(process["stderr_bytes"] == (folder / "stderr.log").stat().st_size == 0)
    require(process["source_drift"] == [] and process["identity_failures"] == [])
    if process["mode"] == "GRAPHICAL":
        profile = Path(process["profile_environment"]["APPDATA"]).parent
        require(execution_identity_failures(raw, True, profile, (folder / "stdout.log").read_text(encoding="utf-8"), process["pid"]) == [])
    return {
        "name": name, "job": process["job"], "execution_source": process["execution_head"],
        "checks": process["checks"], "status": "PASS", "mode": process["mode"], "pid": process["pid"],
        "process": relative(folder / "process.json"), "process_sha256": sha(folder / "process.json"),
        "report": relative(raw_path), "report_sha256": sha(raw_path),
        "source_sha256": process["source_sha256"], "doubles": [], "stderr_bytes": 0,
    }, raw


def build(formal_name, lifecycle_name, regressions):
    baseline_path = OLD / "MATRIX_94.json"
    baseline = read(baseline_path)
    require(sha(ROOT / "docs/beta-sprint/game-feel/GAME_FEEL_CONTRACT.md") == CONTRACT_SHA256)
    require(baseline["matrix_counts"] == {"PASS": 51, "PENDING": 43, "FAIL": 0})
    require([row["id"] for row in baseline["cases"]] == [row["id"] for row in cases()])
    names = [formal_name, lifecycle_name, *regressions]
    require(len(set(names)) == len(names))
    records, reports = {}, {}
    for name in names:
        records[name], reports[name] = receipt(name)
    require({records[n]["job"] for n in regressions} == {"natural", "spam", "lifecycle", "audio_lifecycle", "legacy_pconn", "logical_path", "swept_safety", "legacy_focused", "full_slice_graphical"}, "Require the exact focused regression job set")
    require(all(r["execution_source"] == records[formal_name]["execution_source"] for r in records.values()), "New selected receipts must share the exact candidate execution HEAD")
    # Every captured non-test input participates, including project/input/audio
    # settings, native player scenes and logical level/camera assets.
    production = {p: h for p, h in records[formal_name]["source_sha256"].items() if not p.startswith("tests/")}
    require(all({p: h for p, h in r["source_sha256"].items() if not p.startswith("tests/")} == production for r in records.values()), "New selected receipts must consume identical captured production bytes")
    formal = reports[formal_name]
    lifecycle = reports[lifecycle_name]
    require(records[formal_name]["job"] == "formal_graphical")
    require(records[lifecycle_name]["job"] == "formal_lifecycle")
    require(formal["formal_graphical"] == "PASS")
    graphical = [r for r in formal["rows"] if r.get("mode") != "LOGICAL_SESSION"]
    logical = [r for r in formal["rows"] if r.get("mode") == "LOGICAL_SESSION"]
    require({(r["map"], r["repeat"]) for r in graphical} == {("a", 0), ("a", 1), ("b", 0), ("b", 1)})
    require(len(graphical) == 4 and len(logical) == 2)
    sealed_probe = read(OLD / "evidence/formal_gfx_04/report.json")
    endpoints = []
    for row in graphical:
        original = next(r for r in sealed_probe["rows"] if r["map"] == row["map"])["trace"]
        require(row["trace"] == original, "Ablation/rebuilt trace must not replace the selected original witness")
        require(row["result"]["status"] == 0 and row["result"]["matched_steps"] == 2)
        require(len(row["steps"]) == 2 and row["result"]["actual_statekey"] == original["goal_statekey"])
        for index, step in enumerate(row["steps"]):
            complete = step["completion_evidence"]
            expected = original["steps"][index]
            require(step["status"] == 0 and step["commit_delta"] == step["commit_signals"] == 1 and step["completion_received"])
            require(complete["transition_identity"] == step["transition_identity"])
            require(complete["delivered"] and complete["cancelled_order"] == 0)
            require(complete["started_order"] < complete["committed_order"] < complete["completion_order"])
            require(complete["final_state"] == expected["expected_state"])
            require(complete["final_statekey"] == step["actual_statekey"] == step["expected_statekey"] == expected["resulting_statekey"])
            require(complete["final_visual_pose"] == complete["expected_visual_pose"])
        endpoints.append({"map": row["map"], "repeat": row["repeat"], "matched_steps": 2,
                          "goal_statekey": row["result"]["actual_statekey"],
                          "native_identities": [s["transition_identity"] for s in row["steps"]]})
    for row in logical:
        require(row["result"]["status"] == 0 and row["result"]["matched_steps"] == 2)
        require(row["result"]["actual_statekey"] == row["trace"]["goal_statekey"])
    expected_lifecycle = {(m, p, op) for m in ("a", "b") for p in ("FALL", "LANDING")
                          for op in ("reset", "remove_readd", "exit", "free_active")}
    actual_lifecycle = {(r["map"], r.get("phase"), r["operation"]) for r in lifecycle["rows"] if r["operation"] != "step_timeout"}
    require(actual_lifecycle == expected_lifecycle and len(lifecycle["rows"]) == 18)
    require({r["map"] for r in lifecycle["rows"] if r["operation"] == "step_timeout"} == {"a", "b"})
    for row in lifecycle["rows"]:
        if row["operation"] == "free_active" and not row["old_coroutine_returned"]:
            require(row["old_node_freed"] and row["old_result"] == {}, "Destroyed coroutine must not invent a replay result")
        else:
            require(row["old_result"]["status"] in (2, 3) and row["old_result"]["matched_steps"] == 0)
        require(row["new_result"]["status"] == 0 and row["new_result"]["matched_steps"] == 2)
        require(len(row["new_steps"]) == 2)
        require(all(s["transition_identity"] != row["old_identity"] for s in row["new_steps"]))
        require(row["old_late_completions"] == [])
        require(len(row["old_actual_cancellations"]) == 1 and row["old_actual_cancellations"][0]["identity"] == row["old_identity"])
    full_name = next(n for n in regressions if records[n]["job"] == "full_slice_graphical")
    full = reports[full_name]
    require({(r["map"], r["reduced_motion"]) for r in full["observations"]["routes"]} == {("a", False), ("a", True), ("b", False), ("b", True)}, "Require actual A/B normal/reduced full-slice paths")
    inventory = deepcopy(baseline["cases"])
    upgrades = {"FORMAL_REPLAY", "CORE_SAFETY_SOLVER_REPLAY", "A_POSE_EDGE_RECOIL"}
    for row in inventory:
        row["baseline_evidence"] = deepcopy(row["evidence"])
        row["evidence"] = [relative(OLD / "evidence" / name) for name in row["evidence"]]
        row["evidence_origin"] = "SEALED_BASELINE; exact execution_source retained"
        if row["id"] in upgrades:
            require(row["status"] == "PENDING")
            row["previous_status"] = "PENDING"
            row["status"] = "PASS"
            row["execution_source"] = records[formal_name]["execution_source"]
            if row["id"] == "A_POSE_EDGE_RECOIL":
                row["evidence"] += [records[full_name]["report"]]
                row["evidence_origin"] = "Actual integrated10B shared Presenter; real Shell inputs and renderer"
                row["scope_or_missing"] = "Actual A/B normal/reduced EDGE lean and neutral endpoint; complete StateKey/Orientation unchanged, actual physical source transform restored. Release/rearm, Reset, Fall and Roll preemption observed. This pose row does not establish all Edge input/audio/VFX predicates."
            else:
                row["evidence"] += [records[formal_name]["report"], records[lifecycle_name]["report"]]
                row["evidence_origin"] = "Baseline real Solver/Safety plus new formal graphical original-witness proof"
                row["scope_or_missing"] = "Actual original FULL_GRAPH witness; A/B Fall→natural Landing→Roll U_POS→Goal, two matched steps/map, repeated deterministic state/key with fresh identity; public native Reset/exit/remove-readd/timeout isolation. No algorithm doubles."
            row["dependencies"] = []
        elif row["status"] == "PENDING":
            row["current_scope_note"] = "Pending complete row evidence. Bridge/Replayer are now delivered; baseline missing-dependency text is historical. Native lifecycle assertions alone do not establish full VFX/audio/drag/focus/Human predicates. Integrated 10B/Audio/UI availability does not confer Real PASS."
    counts = dict(Counter(r["status"] for r in inventory))
    counts.setdefault("FAIL", 0)
    require(counts == {"PASS": 54, "PENDING": 40, "FAIL": 0})
    report = {
        "task": "PFALL_GRAPHICAL_COMPLETION_BRIDGE_02", "report": "PFALL_V2_QUALITY_MATRIX_REPORT",
        "contract_mismatch": "NONE", "contract_sha256": CONTRACT_SHA256,
        "sealed_baseline": {"path": relative(baseline_path), "sha256": sha(baseline_path),
                            "execution_source": baseline["execution_source"], "counts": baseline["matrix_counts"]},
        "core_69": baseline["core_69"], "matrix_counts": counts, "cases": inventory,
        "counting": "Cumulative 94 distinct predicates; 51 retained baseline rows and 3 upgraded rows. Not 54 fresh candidate executions. Historical Core69 assertions remain exactly three rows; no totals added across shared row references.",
        "upgraded_rows": sorted(upgrades), "formal_graphical": "PASS",
        "formal_graphical_endpoints": endpoints, "formal_graphical_matched_steps": 8,
        "formal_graphical_lifecycle_new_run_matched_steps": 36,
        "logical_replay": "PASS / separate mode0 / A+B two steps each",
        "natural_presenter": "PASS / focused real candidate regression; separate from FORMAL_GRAPHICAL",
        "runtime_parity": "PASS / original A/B witness complete state, native single commits, full StateKey",
        "graphical_parity": "PASS / actual native Bridge Fall/Landing/Roll completion, physical Pose and Camera direction",
        "executions": records, "new_unique_pass_assertions": sum(r["checks"] for r in records.values()),
        "new_confirmed_runtime_presenter_failures": [],
        "known_owner_observation": "00 reported direct Facade.reset cancellation label CANCEL vs native Runtime RESET; native keyR is checked separately. No new 03 production defect inferred.",
        "not_run": ["Full 94-case acceptance", "100-cycle and30-minute soak", "Fresh GLB import/whole VFX lifecycle", "Full Audio/UI/drag/focus predicates", "conditional L06", "Human visual/audio acceptance", "formal Integration ref promotion", "push"],
        "push": "NOT_RUN",
    }
    OUT.mkdir(exist_ok=True, parents=True)
    (OUT / "MATRIX_94.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
    lines = ["# PFALL_V2_QUALITY_MATRIX_REPORT", "",
             "Cumulative matrix: **54 PASS / 0 FAIL / 40 PENDING**. FORMAL_REPLAY, CORE_SAFETY_SOLVER_REPLAY and A_POSE_EDGE_RECOIL are upgraded. The prior 51 rows retain their historical execution identity; this is not a fresh 94-case acceptance.", "",
             "Formal Graphical: **PASS**, A/B original witness ×2, 8 matched steps. Native Reset, scene exit, active driver free, remove→readd→immediate new replay and expiry isolation: 18 cases, 36 successful new-run steps. LOGICAL_SESSION and natural Presenter are separately recorded.", "",
             f"New selected receipts: {report['new_unique_pass_assertions']} unique PASS assertions. Historical Core69 remains three rows; neither earlier1311 nor Unit38 is added to this total.", "",
             "| Case | Status | Execution source | Scope / evidence |", "|---|---|---|---|"]
    for row in inventory:
        scope = row["scope_or_missing"].replace("|", "/").replace("\n", " ")
        paths = " · ".join(f"[{Path(p).name}]({(ROOT / p).as_posix()})" for p in row["evidence"])
        lines.append(f"| {row['id']} | {row['status']} | {row['execution_source'][:12]} | {scope}; {paths} |")
    lines += ["", "Remaining PENDING rows require their complete predicates. Bridge/Replayer dependency text retained in old rows is historical; production10B/Audio/UI availability alone is not a new execution receipt. The formal Integration ref is unchanged by this Owner candidate verification.", "", "CONTRACT_MISMATCH: NONE", "Push: NOT_RUN", ""]
    (OUT / "MATRIX_94.md").write_text("\n".join(lines), encoding="utf-8", newline="\n")
    print(json.dumps({"matrix_counts": counts, "new_unique_pass_assertions": report["new_unique_pass_assertions"], "formal_graphical": "PASS"}))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--formal", required=True)
    parser.add_argument("--lifecycle", required=True)
    parser.add_argument("--regressions", nargs="+", required=True)
    args = parser.parse_args()
    build(args.formal, args.lifecycle, args.regressions)
