"""Verify receipts, immutable input, checkpoint accounting and compact new evidence."""
import hashlib
import json
from collections import Counter
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[3]
DOC = ROOT / "docs/beta-sprint/spatial-formal-chapter-01/continuation-03/quality"

def read(path):
    return json.loads(path.read_text(encoding="utf-8"))

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main(out):
    binding = read(out / "source_binding.json")
    assert sha(Path(binding["prior"])) == binding["prior_sha256"]
    for rel, expected in binding["copied_sha256"].items():
        assert sha(out / "project" / rel) == expected
    for rel, expected in binding["harness_sha256"].items():
        assert sha(ROOT / rel) == expected == sha(out / "project" / rel)
    processes = read(out / "processes.json")
    checkpoint_receipt = read(out / "checkpoint_verification/process.json")
    assert checkpoint_receipt["exit_code"] == 0 and checkpoint_receipt["stderr_bytes"] == 0
    assert checkpoint_receipt["failures"] == [] and checkpoint_receipt["capture_verified"]
    assert checkpoint_receipt["harness_sha256"] == sha(ROOT / "tests/beta_sprint/spatial_formal_frontier_cont03/checkpoint_check.gd")
    processes["runs"].append(checkpoint_receipt)
    processes["total_engine_seconds"] += checkpoint_receipt["elapsed_seconds"]
    processes["maximum_engine_seconds"] += 40
    assert processes["total_engine_seconds"] <= 1200
    run = out / "incremental"
    receipt = read(run / "process.json")
    assert receipt["exit_code"] == 3 and receipt["stderr_bytes"] == 0
    assert receipt["capture_verified"] and receipt["prior_unchanged"]
    assert receipt["failures"] == [] and receipt["source_drift"] == []
    summary = read(run / "summary.json")
    assert summary["live_frontier_explorer_status"] != 3
    outcomes = read(run / "frontier_outcomes.json")
    checkpoints = []
    for path in sorted(run.glob("checkpoint_*.json")):
        checkpoint = read(path)
        graph = checkpoint["graph"]
        assert graph["complete"] is False and graph["stop_reason"] == 2
        assert len(checkpoint["queue"]) == len(set(checkpoint["queue"]))
        assert set(checkpoint["queue"]) == {key for key, node in graph["nodes"].items() if not node["expanded"] and not node["is_goal"]}
        assert all(not graph["forward"][key] for key, node in graph["nodes"].items() if node["is_goal"])
        assert len(checkpoint["initial_frontiers"]) == 56
        checkpoints.append({"path": str(path), "sha256": sha(path), "typed_path": str(path.with_suffix(".bin")), "typed_sha256": sha(path.with_suffix(".bin")), "states": len(graph["nodes"]), "edges": len(graph["edges"]), "expanded": len(checkpoint["outcomes"]), "remaining": len(checkpoint["queue"]), "elapsed_ms": checkpoint["elapsed_ms"]})
    final = read(Path(checkpoints[-1]["path"]))
    graph = final["graph"]
    prior = read(Path(binding["prior"]))["graph"]
    assert graph["edges"][:1666] == prior["edges"]
    assert all(graph["nodes"][key]["state"] == node["state"] for key, node in prior["nodes"].items())
    assert len({row["state_key"] for row in outcomes}) == len(outcomes) == summary["expanded_frontiers"]
    assert sum(row["new_states"] for row in outcomes) == summary["new_states"]
    assert sum(row["new_edges"] for row in outcomes) == summary["new_edges"]
    assert all(row["expanded"] for row in outcomes)
    assert [row["state_key"] for row in outcomes[:56]] == final["initial_frontiers"][:len(outcomes[:56])]
    rejected = Counter()
    accepted_kinds = Counter()
    duplicates = 0
    evaluations = 0
    safety_unproven = 0
    frontier_rows = []
    for row in outcomes:
        for action in row["actions"]:
            evaluations += 1
            assert action["status"] in [0, 1]
            if action["status"] == 1:
                rejected[str(action["rejection_code"])] += 1
                safety_unproven += any(issue["code"] == 1601 for issue in action["issues"])
            elif action["changed"]:
                accepted_kinds[str(action["action"]["kind"])] += 1
                duplicates += action["previously_saved"]
        frontier_rows.append({key: value for key, value in row.items() if key != "actions"} | {"action_count": len(row["actions"]), "changed_count": sum(action["changed"] for action in row["actions"]), "rejected_count": sum(action["status"] == 1 for action in row["actions"])})
    soft = read(run / "softlock_observation.json")
    assert soft["status"] == 1 and soft["softlock_count"] is None
    goals = {key for key, node in graph["nodes"].items() if node["is_goal"]}
    # Evidence audit only: verify public analyzer's reverse reachability against
    # its saved edges. This traversal does not generate gameplay transitions.
    proven = set(goals)
    pending = list(goals)
    while pending:
        key = pending.pop()
        for edge_id in graph["reverse"][key]:
            source = graph["edges"][edge_id]["from_key"]
            if source not in proven:
                proven.add(source)
                pending.append(source)
    assert proven == set(soft["goal_reachable_states"])
    assert set(graph["nodes"]) - proven == set(soft["unknown_states"])
    unknown = set(soft["unknown_states"])
    # Unknown regions cannot be called dead ends merely because no current
    # witness is known. Retain official incomplete/null conclusions.
    result = {"task": "SPATIAL_FORMAL_CHAPTER_01_CONTINUATION_03", "owner": "03 Quality", "base": binding["base"], "build_source": binding["build_source"], "branch": "test/spatial-formal-frontier-cont03", "evidence": str(out), "summary": summary, "processes": processes, "checks": receipt["checks"], "failures": receipt["failures"], "dependency_count": len(binding["copied_sha256"]), "frontier_action_evaluations": evaluations, "rejection_codes": rejected, "changed_action_kinds": accepted_kinds, "deduplicated_prior_edges": duplicates, "safety_unproven_rejections": safety_unproven, "initial_frontier_results": frontier_rows[:56], "checkpoints": checkpoints, "goal_proof_delta": len(proven) - 355, "old_states_with_new_goal_witness": sorted(set(prior["nodes"]) & proven - set(read(Path(binding["prior"]).with_name("softlock.json"))["goal_reachable_states"])), "softlock_classification": {"A_ordinary_dead_end": "NONE_PROVEN" if unknown else "ZERO_WITHIN_OBSERVED_STATES_ALL_HAVE_GOAL_PATH", "B_reset_only_recovery": "NONE_PROVEN; native Reset sampled separately", "C_implementation_blocks_legal_operation": "NONE_OBSERVED; no independent exhaustive legality oracle", "D_non_design_unrecoverable_softlock": "NONE_PROVEN; formal complete-space conclusion unavailable", "official_softlock_count": None, "unknown_observed_states": len(unknown)}, "scope": "Goal-terminal stable public actions, unfiltered; Reset is a lifecycle operation and is not a graph edge. Test-orchestrated continuation lacks live Explorer completeness provenance.", "not_run": ["TraceReplayer for assembled graph: no supported provenance; public replayer accepts only official spawn traces", "post-Goal outgoing exploration", "GUI input and first-time Human QA", "S01-S04 rerun: prior scope preserved"], "evidence_sha256": {str(path): sha(path) for path in out.rglob("*") if path.is_file() and "project" not in path.parts and "profile" not in path.parts}}
    initial_phase = next(row for row in checkpoints if "initial_frontiers_done" in row["path"])
    live = read(run / "live_frontier_explorer.json")
    result["phase_timing"] = {"recovery_ms": summary["recovery_ms"], "initial_frontier_phase_end_ms": initial_phase["elapsed_ms"], "initial_frontier_phase_duration_ms": initial_phase["elapsed_ms"] - summary["recovery_ms"], "continuation_search_duration_ms": summary["search_end_ms"] - summary["recovery_ms"], "search_end_ms": summary["search_end_ms"], "public_softlock_ms": soft["metrics"]["elapsed_ms"], "public_live_frontier_explorer_ms": live["metrics"]["elapsed_ms"], "native_replay_reset_ms": "NOT_SEPARATELY_TIMED", "main_process_seconds": receipt["elapsed_seconds"], "checkpoint_verification_seconds": checkpoint_receipt["elapsed_seconds"], "total_engine_seconds": processes["total_engine_seconds"]}
    result["limits"] = {"search_deadline_ms_including_recovery": 800000, "max_nodes": 2500, "max_edges": 15000, "live_frontier_explorer_ms": 60000, "main_process_cap_seconds": 1050, "all_process_caps_seconds": 1125, "user_engine_limit_seconds": 1200, "stop_reason": summary["stop_reason"]}
    result["action_counts"] = {"evaluated": evaluations, "rejected": sum(rejected.values()), "accepted_changed": sum(accepted_kinds.values()), "accepted_unchanged": evaluations - sum(rejected.values()) - sum(accepted_kinds.values()), "new_edges": summary["new_edges"], "prior_edges_replayed_not_inserted": duplicates}
    result["checkpoint_verification_checks"] = checkpoint_receipt["checks"]
    result["state_graph"] = "PARTIAL"
    result["softlock_classification"]["evidence_source"] = "Incremental test-orchestrated graph only; its official analyzer count remains null"
    if (out / "live_certification/process.json").exists():
        certification_receipt = read(out / "live_certification/process.json")
        assert certification_receipt["exit_code"] in [0, 3]
        assert certification_receipt["stderr_bytes"] == 0 and certification_receipt["failures"] == []
        assert certification_receipt["capture_verified"] and certification_receipt["source_drift"] == [] and certification_receipt["prior_unchanged"]
        assert certification_receipt["harness_sha256"] == sha(ROOT / "tests/beta_sprint/spatial_formal_frontier_cont03/certify.gd")
        certification = read(out / "live_certification/summary.json")
        certified_graph = read(out / "live_certification/explorer.json")["graph"]
        same_keys = set(graph["nodes"]) == set(certified_graph["nodes"])
        same_edges = graph["edges"] == certified_graph["edges"]
        same_states = same_keys and all(graph["nodes"][key]["state"] == certified_graph["nodes"][key]["state"] for key in graph["nodes"])
        matching_known_states = set(certified_graph["nodes"]).issubset(graph["nodes"]) and all(graph["nodes"][key]["state"] == node["state"] for key, node in certified_graph["nodes"].items())
        matching_edge_prefix = certified_graph["edges"] == graph["edges"][:len(certified_graph["edges"])]
        assert matching_known_states and matching_edge_prefix
        if certification["state_graph"] == "PASS":
            assert same_keys and same_edges and same_states
            assert certification["graph_complete"] and certification["softlock_status"] == 0 and certification["softlock_count"] == 0
        result["live_certification"] = {"summary": certification, "process": certification_receipt, "identical_state_keys": same_keys, "identical_full_states": same_states, "identical_ordered_edges": same_edges, "all_native_states_match_incremental": matching_known_states, "native_edges_match_incremental_prefix": matching_edge_prefix, "scope": "Independent fresh public Explorer/Analyzer; test-orchestrated graph itself remains incomplete and unchanged"}
        result["state_graph"] = certification["state_graph"]
        result["scope"] = "S05 first-Goal-terminal stable public actions only. Incremental test-orchestrated evidence and independent live Explorer certification are separate products; Reset lifecycle and post-Goal actions are outside graph scope."
        result["formal_certified_softlocks"] = {"source": "live_certification/softlock.json", "count": certification["softlock_count"], "status": certification["softlock_status"], "unknown_states": certification["unknown_states"], "scope": certification["scope"]}
        processes["runs"].append(certification_receipt)
        processes["total_engine_seconds"] += certification_receipt["elapsed_seconds"]
        processes["maximum_engine_seconds"] = certification_receipt["prior_engine_seconds"] + certification_receipt["cap_seconds"]
        assert abs(processes["total_engine_seconds"] - certification_receipt["total_engine_seconds"]) < 0.001
        assert processes["total_engine_seconds"] <= 1200
        result["phase_timing"]["total_engine_seconds"] = processes["total_engine_seconds"]
        result["phase_timing"]["live_certification_process_seconds"] = certification_receipt["elapsed_seconds"]
        result["limits"]["certification_explorer_ms"] = 580000
        result["limits"]["certification_analyzer_ms"] = 60000
        result["limits"]["actual_spent_plus_certification_cap_seconds"] = processes["maximum_engine_seconds"]
    DOC.mkdir(parents=True, exist_ok=True)
    (DOC / "RESULTS.json").write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({key: result[key] for key in ["checks", "failures", "frontier_action_evaluations", "deduplicated_prior_edges", "safety_unproven_rejections", "goal_proof_delta"]}, indent=2))
    print(json.dumps(summary, ensure_ascii=False, indent=2))

if __name__ == "__main__":
    main(Path(sys.argv[1]).resolve())
