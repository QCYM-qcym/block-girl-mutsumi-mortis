"""Owner03 acceptance orchestration, actual production APIs only."""
import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import re
import subprocess
import sys

PARENT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PARENT))
import run_quality as common
from receipts import admit

ROOT = common.ROOT
OUT = ROOT / "docs/beta-sprint/spatial-puzzle-batch-01/quality/acceptance_01/evidence"
BASE = "d3b131440600048006ccc7679962fb7fc546a63f"
JOBS = {"contracts": "test_contracts.gd", "graph": "test_graph.gd"}

def execute(job, name, timeout):
    if not re.fullmatch(r"[A-Za-z0-9_-]{1,48}", name):
        raise ValueError("Fresh short evidence name required")
    if common.git("branch", "--show-current").decode().strip() != "test/spatial-acceptance-01":
        raise ValueError("Wrong acceptance Owner branch")
    subprocess.run(["git", "-C", str(ROOT), "merge-base", "--is-ancestor", BASE, "HEAD"], check=True)
    sources = common.snapshot()
    common.verify_source(BASE, sources)
    out = OUT / name
    out.mkdir(parents=True, exist_ok=False)
    env = os.environ.copy()
    profile = out / "profile"
    for key in ["APPDATA", "LOCALAPPDATA", "TEMP", "TMP"]:
        directory = profile / key
        directory.mkdir(parents=True)
        env[key] = str(directory)
    head = common.git("rev-parse", "HEAD").decode().strip()
    args = [str(common.ENGINE), "--headless", "--path", str(ROOT), "--script",
            "res://tests/beta_sprint/spatial_quality/acceptance_01/" + JOBS[job], "--",
            "--evidence=" + out.as_posix(), "--execution-head=" + head]
    receipt = {"job": job, "candidate": BASE, "execution_head": head, "arguments": args,
               "source_sha256": sources, "source_verified": True, "graphical": False,
               "timeout_seconds": timeout, "engine_sha256": common.sha(common.ENGINE),
               "started_utc": datetime.now(timezone.utc).isoformat()}
    with (out / "stdout.log").open("wb") as stdout, (out / "stderr.log").open("wb") as stderr:
        process = subprocess.Popen(args, cwd=ROOT, env=env, stdout=stdout, stderr=stderr,
                                   creationflags=subprocess.CREATE_NO_WINDOW)
        receipt["pid"] = process.pid
        common.write(out / "running.json", receipt)
        try:
            code = process.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
            code = "TIMEOUT"
    raw = out / "report.json"
    report = json.loads(raw.read_text(encoding="utf-8-sig")) if raw.exists() else {}
    capture = report.get("capture", {})
    try:
        Path(capture.get("user_data_dir", "")).resolve().relative_to(profile.resolve())
        isolated = bool(capture.get("user_data_dir"))
    except ValueError:
        isolated = False
    after = common.snapshot()
    receipt.update(exit_code=code, report=report, checks=report.get("checks", 0),
                   failures=report.get("failures", ["missing report"]), doubles=report.get("doubles"),
                   stderr_bytes=(out / "stderr.log").stat().st_size,
                   raw_report_sha256=common.sha(raw) if raw.exists() else None,
                   source_drift=[p for p in sorted(set(sources) | set(after)) if sources.get(p) != after.get(p)],
                   capture_verified=(isolated and capture.get("pid") == process.pid and
                                     capture.get("execution_head") == head and capture.get("display") == "headless"),
                   finished_utc=datetime.now(timezone.utc).isoformat())
    receipt["status"] = admit(receipt)
    common.write(out / "process.json", receipt)
    print(json.dumps({k: receipt[k] for k in ["status", "pid", "checks", "failures", "exit_code", "stderr_bytes", "source_drift"]}))
    return {"PASS": 0, "PENDING": 3, "FAIL": 1}[receipt["status"]]

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("job", choices=JOBS)
    parser.add_argument("name")
    parser.add_argument("--timeout", type=int, default=1800)
    options = parser.parse_args()
    if not 1 <= options.timeout <= 3600:
        raise SystemExit("Finite process timeout1..3600 seconds required")
    raise SystemExit(execute(options.job, options.name, options.timeout))
