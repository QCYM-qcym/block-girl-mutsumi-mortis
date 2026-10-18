"""Audit evidence and project compact, scope-preserving results; no gameplay search."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[3]
DOC=ROOT/"docs/beta-sprint/spatial-formal-chapter-01/continuation-02/quality"
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p): return json.loads(p.read_text(encoding="utf-8"))
def main(roots):
    DOC.mkdir(parents=True,exist_ok=True)
    all_runs=[]; selected={}; files={}; total=0
    bindings=[]
    for root in roots:
        binding=read(root/"source_binding.json")
        bindings.append({"path":str(root/"source_binding.json"),"sha256":sha(root/"source_binding.json"),"dependencies":len(binding["copied_sha256"]),"historical_mismatches":binding["historical_mismatches"],"build_mismatches":binding["build_mismatches"]})
        for rel,h in binding["copied_sha256"].items():
            blob=subprocess.check_output(["git","-C",str(ROOT),"show",binding["base"]+":"+rel])
            assert hashlib.sha256(blob).hexdigest()==h,(rel,"base mismatch")
            assert sha(root/"project"/rel)==h,(rel,"fixture drift")
        for receipt in read(root/"processes.json")["runs"]:
            total+=receipt["elapsed_seconds"]
            name=receipt["map"]; run=root/name
            all_runs.append({"map":name,"path":str(run),"exit_code":receipt["exit_code"],"elapsed_seconds":receipt["elapsed_seconds"],"stderr_bytes":receipt["stderr_bytes"],"checks":receipt.get("checks"),"failures":receipt.get("failures"),"capture_verified":receipt.get("capture_verified")})
            if (run/"summary.json").exists():
                row=read(run/"summary.json")
                row["evidence"]=str(run);row["process_seconds"]=receipt["elapsed_seconds"]
                row["checks"]=receipt.get("checks",0)
                row["admitted"]=receipt["exit_code"] in [0,3] and receipt["stderr_bytes"]==0 and receipt.get("failures")==[] and receipt.get("capture_verified") is True and receipt["source_drift"]==[]
                selected[name]=row
            for p in run.iterdir():
                if p.is_file(): files[str(p)]=sha(p)
        for p in [root/"source_binding.json",root/"processes.json",root/"project/graph.gd"]: files[str(p)]=sha(p)
    assert total<=900,total
    output={"status":"PARTIAL_SCOPE_BOUND","base":"763f0132bc58360fab0e224d0e9c54e00c92ae90","total_godot_process_seconds_all_attempts":total,"bindings":bindings,"runs":all_runs,"maps":selected,"evidence_sha256":files,
      "scope":"Fresh formal Goal-terminal public-action graphs; logical native shortest witness and Reset. No public search expands Goal nodes.",
      "uncovered":["post-Goal fresh full-action closure","pending/busy/cancel/interrupted lifecycle combinations","UI keyboard and Presenter interactions","Human QA","arbitrary malformed state/action dictionaries"],
      "historical_reference":{"path":"E:/godot/beta-sprint-builds/spatial_closure04_quality_20261019_01","map":"rubik_spatial_puzzle_01","states":908,"changed_edges":4300,"fresh_formal_graph":False,"note":"Exact dependency binding permits separately cited prior finite stable-action certificate; it is not a fresh current-Build full state-graph PASS."}}
    (DOC/"RESULTS.json").write_text(json.dumps(output,ensure_ascii=False,indent=2),encoding="utf-8")
    print(json.dumps({"total_seconds":total,"maps":[{"map":m,"states":v["census"]["states"],"edges":v["census"]["edges"],"actions":v["metrics"]["action_evaluations"],"complete":v["graph_complete"],"softlock_count":v["softlock_count"],"admitted":v["admitted"],"seconds":v["process_seconds"],"checks":v["checks"]} for m,v in selected.items()]},indent=2))
if __name__=="__main__": main([Path(p).resolve() for p in sys.argv[1:]])
