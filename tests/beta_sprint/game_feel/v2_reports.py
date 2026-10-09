"""03 evidence classification; never executes or replaces a Replay algorithm."""
import re
from pathlib import Path


def execution_identity_failures(report, graphical, profile, stdout, pid):
    capture = report.get("capture", report)
    failures = []
    reported_pid = capture.get("pid", report.get("pid"))
    if reported_pid is not None and reported_pid != pid:
        failures.append("reported PID differs from launched process")
    user_dir = capture.get("user_data_dir", report.get("user_dir"))
    if user_dir and not Path(user_dir).resolve().is_relative_to(profile.resolve()):
        failures.append("actual OS profile escaped isolation")
    if graphical:
        if capture.get("display") != "Windows":
            failures.append("graphical job requires actual Windows display evidence")
        if not user_dir:
            failures.append("graphical job missing actual isolated user directory")
        if not re.search(r"^(?:D3D12|Vulkan|OpenGL).* - Using Device", stdout, re.MULTILINE):
            failures.append("graphical job missing actual renderer/device startup evidence")
    return failures


def legacy_checks(text):
    rows = [row for row in text.splitlines() if row.startswith("PERSPECTIVE_LOGIC:")]
    match = re.fullmatch(r"PERSPECTIVE_LOGIC: ([1-9][0-9]*) checks; [1-9][0-9]* orientations; failures=\[\]", rows[0]) if len(rows) == 1 else None
    return int(match[1]) if match else 0


def classify_execution(report, exit_code, stderr_bytes, drift):
    if (exit_code != 0 or stderr_bytes != 0 or drift or type(report.get("checks")) is not int or
            report["checks"] <= 0 or report.get("failures") != [] or report.get("doubles") != []):
        return "FAIL"
    if report.get("formal_graphical") == "BLOCKED":
        return "BLOCKED"
    return "PASS"


def core_mapping(receipt):
    rows = receipt["registered_quality_cases"]
    ids = [row["case"] for row in rows]
    if (set(ids) != {"CORE_A_NATURAL_FALL", "CORE_B_NATURAL_FALL", "CORE_CAMERA_REJECT"} or
            len(ids) != len(set(ids)) or any(row["formal_result"] != "PASS" or
                type(row["checks"]) is not int or row["checks"] <= 0 for row in rows)):
        raise ValueError("Core receipt must contain distinct registered PASS cases")
    return {"checks": sum(row["checks"] for row in rows), "cases": len(rows), "matrix_ids": ids,
            "counting": "Each matrix row counted once; assertions belong to shared execution evidence"}
