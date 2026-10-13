"""Bounded headless Owner03 receipt runner; no gameplay/search implementation."""
import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import re
import subprocess
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import run_quality as common
from receipts import admit

ROOT = common.ROOT
BASE = "e4fe5365334e93138dc9b8856d09670478789abc"
OUT = ROOT / "docs/beta-sprint/spatial-puzzle-batch-01/quality/polish_03"


def run(name):
    if not re.fullmatch(r"[A-Za-z0-9_-]{1,48}", name):
        raise ValueError("Fresh short receipt name required")
    if common.git("branch", "--show-current").decode().strip() != "test/spatial-polish-03":
        raise ValueError("Wrong Owner branch")
    subprocess.run(["git", "-C", str(ROOT), "merge-base", "--is-ancestor", BASE, "HEAD"], check=True)
    sources = common.snapshot()
    common.verify_source(BASE, sources)
    extra = [OUT / "COVERAGE_AUDIT.json", ROOT / "docs/beta-sprint/spatial-puzzle-batch-01/quality/acceptance_01/evidence/full_graph_03/selected_trace.gdvar"]
    sources.update({p.relative_to(ROOT).as_posix(): common.sha(p) for p in extra})
    out = OUT / "evidence" / name
    out.mkdir(parents=True, exist_ok=False)
    env = os.environ.copy()
    profile = out / "profile"
    for key in ["APPDATA", "LOCALAPPDATA", "TEMP", "TMP"]:
        directory = profile / key
        directory.mkdir(parents=True)
        env[key] = str(directory)
    head = common.git("rev-parse", "HEAD").decode().strip()
    args = [str(common.ENGINE), "--headless", "--path", str(ROOT), "--script",
            "res://tests/beta_sprint/spatial_quality/polish_03/test_recovery.gd", "--",
            "--evidence="+out.as_posix(), "--execution-head="+head]
    record = {"candidate":BASE,"execution_head":head,"graphical":False,"arguments":args,
              "source_sha256":sources,"source_verified":True,"timeout_seconds":360,
              "engine_sha256":common.sha(common.ENGINE),"profile_environment":{k:env[k] for k in ["APPDATA","LOCALAPPDATA","TEMP","TMP"]},
              "dirty":common.git("status","--porcelain=v1").decode("utf-8"),"started_utc":datetime.now(timezone.utc).isoformat()}
    with (out/"stdout.log").open("wb") as stdout, (out/"stderr.log").open("wb") as stderr:
        proc = subprocess.Popen(args,cwd=ROOT,env=env,stdout=stdout,stderr=stderr,creationflags=subprocess.CREATE_NO_WINDOW)
        record["pid"] = proc.pid
        common.write(out/"running.json",record)
        try:
            code = proc.wait(timeout=360)
        except subprocess.TimeoutExpired:
            proc.kill();proc.wait();code="TIMEOUT"
    raw = out/"report.json"
    report = json.loads(raw.read_text(encoding="utf-8-sig")) if raw.exists() else {}
    capture = report.get("capture",{})
    try:
        isolated = bool(capture.get("user_data_dir")) and Path(capture["user_data_dir"]).resolve().is_relative_to(profile.resolve())
    except (KeyError, ValueError):
        isolated = False
    after = common.snapshot()
    after.update({p.relative_to(ROOT).as_posix():common.sha(p) for p in extra})
    record.update(exit_code=code,checks=report.get("checks",0),failures=report.get("failures",["missing report"]),
                  doubles=report.get("doubles"),report=report,stderr_bytes=(out/"stderr.log").stat().st_size,
                  raw_report_sha256=common.sha(raw) if raw.exists() else None,
                  source_drift=[p for p in sorted(set(sources)|set(after)) if sources.get(p)!=after.get(p)],
                  capture_verified=isolated and capture.get("pid")==proc.pid and capture.get("execution_head")==head and capture.get("display")=="headless",
                  finished_utc=datetime.now(timezone.utc).isoformat())
    record["status"] = admit(record)
    common.write(out/"process.json",record)
    print(json.dumps({k:record[k] for k in ["status","pid","checks","failures","exit_code","stderr_bytes","source_drift"]}))
    return 0 if record["status"]=="PASS" else 1


if __name__ == "__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("name")
    raise SystemExit(run(parser.parse_args().name))
