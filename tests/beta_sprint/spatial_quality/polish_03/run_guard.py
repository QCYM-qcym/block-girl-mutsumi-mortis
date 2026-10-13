"""Isolated UNIT guard runner. Never admits a doubled receipt as Real."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import hashlib

ROOT=Path(__file__).resolve().parents[4]
ENGINE=Path("D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe")

def run(name):
    out=ROOT/"docs/beta-sprint/spatial-puzzle-batch-01/quality/polish_03/evidence"/name
    out.mkdir(parents=True,exist_ok=False)
    env=os.environ.copy()
    for key in ["APPDATA","LOCALAPPDATA","TEMP","TMP"]:
        p=out/"profile"/key;p.mkdir(parents=True);env[key]=str(p)
    args=[str(ENGINE),"--headless","--path",str(ROOT),"--script","res://tests/beta_sprint/spatial_quality/polish_03/test_setup_guard.gd","--","--evidence="+out.as_posix()]
    with (out/"stdout.log").open("wb") as stdout,(out/"stderr.log").open("wb") as stderr:
        proc=subprocess.Popen(args,cwd=ROOT,env=env,stdout=stdout,stderr=stderr,creationflags=subprocess.CREATE_NO_WINDOW)
        try: code=proc.wait(timeout=30)
        except subprocess.TimeoutExpired:proc.kill();proc.wait();code="TIMEOUT"
    report=json.loads((out/"report.json").read_text(encoding="utf-8-sig")) if (out/"report.json").exists() else {}
    record={"scope":"QUALITY_HARNESS_UNIT_ONLY","pid":proc.pid,"exit_code":code,"stderr_bytes":(out/"stderr.log").stat().st_size,
            "report":report,"test_source_sha256":{p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in ["tests/beta_sprint/spatial_quality/polish_03/test_recovery.gd","tests/beta_sprint/spatial_quality/polish_03/test_setup_guard.gd"]}}
    ok=code==0 and record["stderr_bytes"]==0 and report.get("scope")=="QUALITY_HARNESS_UNIT_ONLY" and report.get("checks")==2 and report.get("failures")==[] and report.get("runtime_authority") is False and report.get("doubles")==["REQUEST_RESULT_DOUBLE_UNIT_ONLY"]
    record["status"]="UNIT_PASS" if ok else "UNIT_FAIL"
    (out/"process.json").write_bytes((json.dumps(record,ensure_ascii=False,indent=2)+"\n").encode("utf-8"))
    print(json.dumps({k:record[k] for k in ["scope","status","pid","exit_code","stderr_bytes"]}))
    return 0 if ok else 1

if __name__=="__main__":
    p=argparse.ArgumentParser();p.add_argument("name");raise SystemExit(run(p.parse_args().name))
