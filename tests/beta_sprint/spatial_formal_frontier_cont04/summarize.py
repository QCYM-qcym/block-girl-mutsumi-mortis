"""Read-only evidence accounting; never generates gameplay transitions."""
import hashlib
import json
from collections import Counter
from pathlib import Path
import sys
ROOT = Path(__file__).resolve().parents[3]
DOC = ROOT / "docs/beta-sprint/spatial-formal-chapter-01/continuation-04/quality"
def read(p): return json.loads(p.read_text(encoding="utf-8-sig"))
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def lf_sha(p): return hashlib.sha256(p.read_bytes().replace(b"\r\n", b"\n")).hexdigest()
def main(out):
    binding = read(out / "source_binding.json")
    for name, expected in binding["historical_sha256"].items(): assert sha(Path(name)) == expected, name
    for rel, expected in binding["copied_sha256"].items(): assert sha(out / "project" / rel) == expected == sha(ROOT / rel), rel
    source_relationship = {}
    for rel, expected in binding["harness_sha256"].items():
        archived = out / "project" / rel
        assert sha(archived) == expected, rel
        assert lf_sha(archived) == lf_sha(ROOT / rel), rel
        source_relationship[rel] = {"executed_sha256":expected,"delivered_sha256":sha(ROOT / rel),"lf_normalized_content_equal":True}

    native = read(Path(binding["prior"]))["graph"]
    historical = Path(binding["prior"]).parents[1]
    candidate = read(historical / "incremental/checkpoint_062_search_end.json")["graph"]
    assert (len(native["nodes"]),len(native["edges"])) == (785,3328)
    assert (len(candidate["nodes"]),len(candidate["edges"])) == (908,3916)
    for key in ["level_hash","rule_version","initial_key","policy_descriptor","graph_version"]: assert native[key] == candidate[key]
    assert candidate["edges"][:3328] == native["edges"]
    assert all(candidate["nodes"][k]["state"] == n["state"] for k,n in native["nodes"].items())
    checkpoints = []
    run = out / "incremental"
    for path in sorted(run.glob("checkpoint_*.json")):
        snap = read(path); graph = snap["graph"]
        assert graph["complete"] is False and graph["stop_reason"] == 2
        assert set(snap["queue"]) == {k for k,n in graph["nodes"].items() if not n["expanded"] and not n["is_goal"]}
        assert len(snap["queue"]) == len(set(snap["queue"]))
        assert len(snap["initial_frontiers"]) == 17
        assert graph["edges"][:3328] == native["edges"]
        assert all(graph["nodes"][k]["state"] == n["state"] for k,n in native["nodes"].items())
        assert all(not graph["forward"][k] for k,n in graph["nodes"].items() if n["is_goal"])
        checkpoints.append({"path":str(path),"sha256":sha(path),"typed_sha256":sha(path.with_suffix(".bin")),"states":len(graph["nodes"]),"edges":len(graph["edges"]),"expanded":len(snap["outcomes"]),"remaining":len(snap["queue"]),"elapsed_ms":snap["elapsed_ms"]})
    final = read(Path(checkpoints[-1]["path"])); graph = final["graph"]
    summary = read(run / "summary.json"); outcomes = read(run / "frontier_outcomes.json")
    assert summary["live_spawn_witness"] is True and summary["live_spawn_explorer_status"] == 0
    assert summary["live_replay_status"] == 0
    spawn_live = read(run / "live_spawn_explorer.json")
    spawn_replay = read(run / "live_spawn_replay.json")
    assert spawn_live["solution_trace"] is not None and spawn_replay["status"] == 0
    assert spawn_replay["matched_steps"] == spawn_replay["trace_length"] == spawn_live["solution_trace"]["total_actions"] == 7
    assert read(run / "live_spawn_trace_semantics.json")["ok"] is True
    assert summary["native_reset_sample_steps"] == read(run / "native_reset.json")["steps"] == 30
    assert read(run / "native_reset.json")["reset_key"] == native["initial_key"]

    assert [x["state_key"] for x in outcomes[:17]] == final["initial_frontiers"]
    assert len({x["state_key"] for x in outcomes}) == len(outcomes) == summary["expanded_frontiers"]
    assert all(x["expanded"] for x in outcomes)
    assert sum(x["new_states"] for x in outcomes) == len(graph["nodes"]) - 785
    assert sum(x["new_edges"] for x in outcomes) == len(graph["edges"]) - 3328
    def semantic_edges(g): return {(e["from_key"],json.dumps(e["action"],sort_keys=True),e["to_key"],e["global_kind"]) for e in g["edges"]}
    edges = semantic_edges(graph); old_edges = semantic_edges(candidate)
    actions = [a for o in outcomes for a in o["actions"]]
    soft = read(run / "softlock_observation.json")
    proven = {k for k,n in graph["nodes"].items() if n["is_goal"]}; stack = list(proven)
    while stack:
        key = stack.pop()
        for eid in graph["reverse"][key]:
            source = graph["edges"][eid]["from_key"]
            if source not in proven: proven.add(source); stack.append(source)
    assert proven == set(soft["goal_reachable_states"])
    assert set(graph["nodes"]) - proven == set(soft["unknown_states"])
    assert soft["softlock_count"] is None and soft["status"] == 1
    processes = read(out / "processes.json")
    verify = read(out / "checkpoint_verification/process.json")
    assert verify["checkpoint_sha256"] == sha(Path(checkpoints[-1]["path"]).with_suffix(".bin"))
    assert verify["harness_sha256"] == sha(out / "project/tests/beta_sprint/spatial_formal_frontier_cont04/checkpoint_check.gd")
    processes["runs"].append(verify)
    processes["total_engine_seconds"] += verify["elapsed_seconds"]
    processes["maximum_engine_seconds"] += verify["cap_seconds"]
    assert processes["total_engine_seconds"] <= 600
    for rec in processes["runs"]:
        assert rec["stderr_bytes"] == 0, rec
        assert rec["exit_code"] == (3 if rec["name"] == "incremental" else 0), rec
        if rec["name"] != "setup": assert rec["failures"] == [] and rec["capture_verified"], rec
    result = {"task":"SPATIAL_FORMAL_CHAPTER_01_CONTINUATION_04","owner":"03 Quality","base":binding["base"],"build_source":binding["build_source"],"evidence":str(out),"summary":summary,"processes":processes,"dependency_count":len(binding["copied_sha256"]),"checkpoints":checkpoints,"checks":sum(p.get("checks",0) for p in processes["runs"]),"failures":[],"delta_vs_native_785_3328":{"states":len(graph["nodes"])-785,"edges":len(graph["edges"])-3328},"delta_vs_candidate_908_3916":{"new_states":len(set(graph["nodes"])-set(candidate["nodes"])),"new_edges":len(edges-old_edges),"candidate_states_missing":len(set(candidate["nodes"])-set(graph["nodes"])),"candidate_edges_missing":len(old_edges-edges),"same_ordered_edges":graph["edges"]==candidate["edges"],"same_full_states":graph["nodes"].keys()==candidate["nodes"].keys() and all(graph["nodes"][k]["state"]==v["state"] for k,v in candidate["nodes"].items())},"actions":{"evaluated":len(actions),"prior_partial_edges_deduplicated":sum(a["previously_saved"] for a in actions),"rejection_codes":dict(Counter(str(a["rejection_code"]) for a in actions if a["status"]==1)),"safety_unproven":sum(any(i["code"]==1601 for i in a["issues"]) for a in actions)},"continuation_softlock_classification":{"official_count":None,"status":"INCOMPLETE","observed_goal_reachable":len(proven),"observed_unknown":len(soft["unknown_states"]),"ordinary_dead_end":"NONE_PROVEN","reset_only":"UNKNOWN_COMPLETE_SPACE; sampled exact Reset only","erroneous_legal_block":"NONE_OBSERVED; no exhaustive independent legality oracle","non_design_unrecoverable":"UNKNOWN_COMPLETE_SPACE"},"identity_reconciliation":{"same_policy_spawn_hash_rule":True,"native_states_subset_candidate":True,"native_edges_exact_candidate_prefix":True},"forecast":{"candidate_non_goal_nodes":812,"actions_per_non_goal":12,"estimated_total_actions":9744,"native_prior_actions":8265,"native_prior_elapsed_ms":580026,"linear_estimate_seconds":9744*580.026/8265,"closure_validation_copy_seconds_allowance":[35,45],"proposed_single_search_cap_seconds":900,"authorization":"ROOT_CONDITIONALLY_APPROVED_ONCE_AFTER_MATCHING_908_3916_CLOSURE","stop":"one attempt only; report remaining fronts/budget if incomplete"}}
    cert_path = out / "live_certification/process.json"
    if cert_path.exists():
        cert = read(cert_path)
        assert cert["exit_code"] in [0,3] and cert["stderr_bytes"] == 0
        assert cert["failures"] == [] and cert["capture_verified"] and cert["source_drift"] == [] and cert["prior_unchanged"]
        assert cert["harness_sha256"] == sha(out / "project/tests/beta_sprint/spatial_formal_frontier_cont04/certify.gd")
        live = read(out / "live_certification/explorer.json")
        live_graph = live["graph"]
        live_soft = read(out / "live_certification/softlock.json")
        live_summary = read(out / "live_certification/summary.json")
        for key in ["level_hash","rule_version","initial_key","policy_descriptor","graph_version"]: assert live_graph[key] == graph[key]
        assert all(graph["nodes"][k]["state"] == n["state"] for k,n in live_graph["nodes"].items())
        assert graph["edges"][:len(live_graph["edges"])] == live_graph["edges"]
        remaining = sum(not n["expanded"] and not n["is_goal"] for n in live_graph["nodes"].values())
        same_nodes = graph["nodes"].keys() == live_graph["nodes"].keys()
        same_edges = graph["edges"] == live_graph["edges"]
        if live_summary["state_graph"] == "PASS":
            assert live["status"] == 0 and live["budget_reason"] == 0
            assert live_graph["complete"] and live_graph["stop_reason"] == 0 and remaining == 0
            assert live_soft["status"] == 0 and live_soft["softlock_count"] == 0 and live_soft["unknown_states"] == []
            assert same_nodes and same_edges and live["metrics"]["action_evaluations"] == 9744
        processes["runs"].append(cert)
        processes["total_engine_seconds"] += cert["elapsed_seconds"]
        processes["maximum_engine_seconds"] += cert["cap_seconds"]
        assert processes["total_engine_seconds"] <= 1600
        result["checks"] += cert["checks"]
        result["official_certification"] = {"summary":live_summary,"process":cert,"remaining_frontiers":remaining,"same_full_states":same_nodes,"same_ordered_edges":same_edges,"delta_vs_native_785_3328":{"states":len(live_graph["nodes"])-785,"edges":len(live_graph["edges"])-3328},"delta_vs_candidate_908_3916":{"states":len(set(live_graph["nodes"])-set(candidate["nodes"])),"edges":len(semantic_edges(live_graph)-old_edges)},"unknown_states":len(live_soft["unknown_states"]),"goal_reachable_states":len(live_soft["goal_reachable_states"])}
        result["state_graph"] = live_summary["state_graph"]
        result["graph_verdict_basis"] = "SEPARATE_UNCHANGED_PUBLIC_LIVE_EXPLORER_AND_ANALYZER; continuation remains PARTIAL"
        result["forecast"]["authorization"] = "ROOT_APPROVED_ONCE_AFTER_MATCHING_908_3916_CLOSURE"
        result["forecast"]["actual_native_search_ms"] = live["metrics"]["elapsed_ms"]
        result["forecast"]["actual_native_actions"] = live["metrics"]["action_evaluations"]
    else:
        result["state_graph"] = "PARTIAL"
    for name in ["checkpoint_check.gd","certify.gd"]:
        rel = "tests/beta_sprint/spatial_formal_frontier_cont04/" + name
        archived = out / "project" / rel
        if archived.exists():
            assert lf_sha(archived) == lf_sha(ROOT / rel)
            source_relationship[rel] = {"executed_sha256":sha(archived),"delivered_sha256":sha(ROOT / rel),"lf_normalized_content_equal":True}
    result["harness_source_relationship"] = source_relationship
    result["evidence_sha256"] = {str(p):sha(p) for p in out.rglob("*") if p.is_file() and "project" not in p.parts and "profile" not in p.parts}
    (DOC / "RESULTS.json").write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8",newline="\n")
    print(json.dumps({k:result[k] for k in ["checks","delta_vs_native_785_3328","delta_vs_candidate_908_3916","actions","forecast"]},indent=2))
if __name__ == "__main__": main(Path(sys.argv[1]).resolve())
