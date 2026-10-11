"""Receipt admission only. Contains no gameplay, search or parity algorithm."""
import re

FACETS = {"UNIT", "REAL_RUNTIME", "SOLVER", "SAFETY", "LOGICAL_REPLAY",
          "NATURAL_GRAPHICAL", "FORMAL_GRAPHICAL", "INTEGRATION", "HUMAN_QA"}


def admit(receipt):
    report = receipt.get("report", {})
    if (receipt.get("exit_code") not in (0, 3) or
            receipt.get("stderr_bytes") != 0 or receipt.get("failures") != [] or
            receipt.get("doubles") != [] or receipt.get("source_drift") != [] or
            receipt.get("capture_verified") is not True or
            receipt.get("source_verified") is not True or
            not re.fullmatch(r"[0-9a-f]{40}", receipt.get("candidate") or "") or
            not re.fullmatch(r"[0-9a-f]{40}", receipt.get("execution_head") or "") or
            report.get("scope") != "SPATIAL_OWNER_03_REAL" or
            report.get("checks") != receipt.get("checks") or
            type(receipt.get("checks")) is not int or receipt["checks"] <= 0 or
            report.get("failures") != [] or report.get("doubles") != []):
        return "FAIL"
    cases = report.get("cases", [])
    ids = set()
    assertions = 0
    for case in cases:
        if (case.get("id") in ids or not case.get("id") or
                case.get("facet") not in FACETS or
                type(case.get("checks")) is not int or case["checks"] <= 0 or
                case.get("status") != "PASS" or case.get("failures") != [] or
                case["facet"] == "HUMAN_QA"):
            return "FAIL"
        if case["facet"] in {"NATURAL_GRAPHICAL", "FORMAL_GRAPHICAL", "INTEGRATION"} and receipt.get("graphical") is not True:
            return "FAIL"
        ids.add(case["id"])
        assertions += case["checks"]
    if assertions != receipt["checks"]:
        return "FAIL"
    pending = report.get("dependency_pending")
    if not isinstance(pending, list):
        return "FAIL"
    if pending:
        return "PENDING" if receipt["exit_code"] == 3 else "FAIL"
    return "PASS" if receipt["exit_code"] == 0 else "FAIL"


def register(planned, receipt, path):
    status = admit(receipt)
    if status == "FAIL":
        raise ValueError("Rejected receipt: measured evidence gates failed")
    updates = {}
    for case in receipt["report"]["cases"]:
        key = case["id"]
        if key not in planned or planned[key]["facet"] != case["facet"]:
            raise ValueError(f"Unknown case or evidence facet mismatch: {key}")
        updates[key] = {"status": "PASS", "receipt": path,
                        "assertions": case["checks"], "candidate": receipt["candidate"]}
    return updates
