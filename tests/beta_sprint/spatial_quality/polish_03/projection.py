"""Receipt projection only; never constructs or analyzes a state graph."""
def summarize(scenarios, searches):
    failed = any(s.get("status") == "FAIL" for s in scenarios) or any(s.get("status") not in (0,2) for s in searches)
    pending = not scenarios or any(s.get("status") != "PASS" for s in scenarios) or any(s.get("status") == 2 for s in searches)
    return {"sample_status":"FAIL" if failed else ("PENDING" if pending else "PASS"),
            "overall":"PARTIAL", "complete_runtime_denominator":"UNKNOWN",
            "original_domain":{"states":908,"edges":3916,"goals":96,"softlocks":0},
            "reset_only_conclusion":None,"post_goal_softlocks":"UNKNOWN"}
