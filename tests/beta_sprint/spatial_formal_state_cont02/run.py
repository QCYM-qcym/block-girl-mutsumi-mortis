"""Fresh isolated finite evidence. Never runs the source project or modifies old evidence."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[3]
BASE = "763f0132bc58360fab0e224d0e9c54e00c92ae90"
OLD = Path("E:/godot/beta-sprint-builds/spatial_closure04_quality_20261019_01")
BUILD = Path("E:/godot/beta-sprint-builds/beta_spatial_formal_chapter_20261019_01")
ENGINE = Path("D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe")
MAPS = ["world_shift_gate_lab", "orientation_loop_lab", "face_lock_lab", "perspective_fork_lab", "rubik_spatial_puzzle_01"]
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def write(p,v): p.write_text(json.dumps(v,ensure_ascii=False,indent=2),encoding="utf-8")

def main(out, selected=None, prior_seconds=0.0):
    out.mkdir(parents=True,exist_ok=False)
    shutil.copy2(Path(__file__),out/"tested_runner.py")
    project=out/"project"
    project.mkdir()
    old=json.loads((OLD/"source_binding.json").read_text())
    binding={"base":BASE,"source_root":str(ROOT),"old_evidence":str(OLD),"immutable_build":str(BUILD),"copied_sha256":{},"historical_mismatches":[],"build_mismatches":[]}
    for rel, old_hash in old["copied_sha256"].items():
        source=ROOT/rel
        if not source.exists(): raise RuntimeError("Missing dependency: "+rel)
        blob=subprocess.check_output(["git","-C",str(ROOT),"show",BASE+":"+rel])
        if hashlib.sha256(blob).hexdigest()!=sha(source): raise RuntimeError("Dependency differs from exact baseline: "+rel)
        target=project/rel
        target.parent.mkdir(parents=True,exist_ok=True)
        shutil.copy2(source,target)
        actual=sha(source)
        binding["copied_sha256"][rel]=actual
        if actual!=old_hash: binding["historical_mismatches"].append(rel)
        if not (BUILD/"project"/rel).exists() or sha(BUILD/"project"/rel)!=actual: binding["build_mismatches"].append(rel)
    # Fixture has no Art, UI, autoload, or gameplay implementation changes.
    (project/"project.godot").write_text('config_version=5\n[application]\nconfig/name="Formal State Continuation02"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
    shutil.copy2(Path(__file__).with_name("graph.gd"),project/"graph.gd")
    binding["harness_sha256"]=sha(project/"graph.gd")
    binding["engine_sha256"]=sha(ENGINE)
    binding["old_results_sha256"]=sha(OLD/"RESULTS.json")
    binding["build_identity_sha256"]=sha(BUILD/"BUILD_IDENTITY.json")
    write(out/"source_binding.json",binding)
    t=time.monotonic()
    receipts=[]
    jobs=[("setup",["--editor","--quit"],45)]
    jobs += [(m,["--script","res://graph.gd","--","--map="+m,"--budget-ms="+str(200000 if i==4 else 110000),"--execution-head="+BASE],240 if i==4 else 150) for i,m in enumerate(MAPS) if selected is None or m in selected]
    for name,tail,cap in jobs:
        run=out/name
        run.mkdir()
        env=os.environ.copy()
        for k in ["APPDATA","LOCALAPPDATA","TEMP","TMP"]:
            p=run/"profile"/k;p.mkdir(parents=True);env[k]=str(p)
        args=[str(ENGINE),"--headless","--path",str(project)]+tail
        if name!="setup": args += ["--evidence="+run.as_posix()]
        timeout=min(cap,850-prior_seconds-(time.monotonic()-t))
        if timeout<=0: break
        receipt={"arguments":args,"timeout_seconds":timeout,"started":time.time(),"profile":str(run/"profile")}
        with (run/"stdout.log").open("wb") as stdout,(run/"stderr.log").open("wb") as stderr:
            p=subprocess.Popen(args,stdout=stdout,stderr=stderr,env=env,creationflags=subprocess.CREATE_NO_WINDOW)
            receipt["pid"]=p.pid;write(run/"running.json",receipt)
            try: receipt["exit_code"]=p.wait(timeout=timeout)
            except subprocess.TimeoutExpired: p.kill();p.wait();receipt["exit_code"]="TIMEOUT"
        receipt["elapsed_seconds"]=time.time()-receipt["started"]
        receipt["stderr_bytes"]=(run/"stderr.log").stat().st_size
        receipt["source_drift"]=[rel for rel,h in binding["copied_sha256"].items() if sha(project/rel)!=h]
        if (run/"report.json").exists():
            report=json.loads((run/"report.json").read_text());receipt["checks"]=report["checks"];receipt["failures"]=report["failures"]
            capture=report["capture"]
            receipt["capture_verified"]=capture["pid"]==p.pid and capture["display"]=="headless" and Path(capture["user_data_dir"]).is_relative_to(run/"profile") and capture["execution_head"]==BASE
        write(run/"process.json",receipt);receipts.append({"map":name,**receipt})
        write(out/"processes.json",{"elapsed_seconds":time.monotonic()-t,"prior_seconds":prior_seconds,"total_elapsed_seconds":prior_seconds+time.monotonic()-t,"limit_seconds":850,"runs":receipts})
        print(name,receipt["exit_code"],round(receipt["elapsed_seconds"],2),receipt.get("checks"),flush=True)
        if name=="setup" and receipt["exit_code"]!=0: break
if __name__=="__main__":
    import argparse
    parser=argparse.ArgumentParser()
    parser.add_argument("out",type=Path)
    parser.add_argument("--maps",nargs="+",choices=MAPS)
    parser.add_argument("--prior-seconds",type=float,default=0.0)
    args=parser.parse_args()
    main(args.out.resolve(),args.maps,args.prior_seconds)
