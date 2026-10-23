"""Strict EXPANDED MATERIAL PREVIEW copied-project render. Fresh output, no foreign input/processes."""
import argparse
import datetime as dt
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import time

REPO = Path(__file__).resolve().parents[4]
HARNESS = Path("tests/beta_sprint/spatial_art/a2_west_expanded")
BUILD = Path("E:/godot/beta-sprint-builds/beta_spatial_formal_chapter_20261019_01")
ENGINE = Path("D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe")
PRIOR = Path("E:/godot/beta-sprint-builds/QA/floating_cube_a06/run_20261023_03/PRESERVATION_BEFORE.json")
OUTPUT_ROOT = Path("E:/godot/beta-sprint-builds/QA/floating_cube_expanded").resolve()
spec = importlib.util.spec_from_file_location("unchanged_capture_helpers", REPO/"tests/beta_sprint/spatial_art/option_a_06/run_preview.py")
helpers = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helpers)
sha, save, git = helpers.sha, helpers.save, helpers.git


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    out = args.output.resolve()
    assert out.is_relative_to(OUTPUT_ROOT) and out!=OUTPUT_ROOT and not out.exists()
    identity = json.loads((BUILD/"BUILD_IDENTITY.json").read_text(encoding="utf-8-sig"))
    scopes = ["game","foundation","experiments","production","prototype","project.godot","default_bus_layout.tres","icon.svg"]
    assert not git("diff","--name-only",identity["integration_commit"],"HEAD","--",*scopes)
    assert not git("diff","--name-only","HEAD","--",*scopes)
    prior = json.loads(PRIOR.read_text(encoding="utf-8-sig"))
    watched = {name:sha(Path(name)) for name in prior["hashes"]}
    for source in [REPO/"docs/beta-sprint/spatial-formal-chapter-01/continuation-06",REPO/"tests/beta_sprint/spatial_art/option_a_06",REPO/"tests/beta_sprint/spatial_art/polish_03",REPO/"tests/beta_sprint/spatial_art/a2_west_b2",REPO/"docs/beta-sprint/spatial-formal-chapter-01/floating_cube/option_a2_west_view",Path("E:/godot/beta-sprint-builds/QA/floating_cube_b2/run_20261023_01")]:
        for path in source.rglob("*"):
            if path.is_file(): watched[str(path)]=sha(path)
    assert all(sha(BUILD/row["path"])==row["sha256"] for row in identity["files"])
    refs={ref:git("rev-parse",ref) for ref in prior["refs"]}
    profiles=helpers.profile_snapshot()
    out.mkdir(parents=True)
    save(out/"PRESERVATION_BEFORE.json",{"hashes":watched,"refs":refs,"profiles":profiles})
    project=out/"project"
    shutil.copytree(BUILD/"project",project)
    files=[HARNESS/"preview.gd",HARNESS/"roof_coarse_a2.gdshader",Path("tests/beta_sprint/spatial_art/polish_03/roof_coarse.gdshader"),Path("tests/beta_sprint/spatial_art/option_a_06/preview.gd")]
    for path in files:
        target=project/path
        assert not target.exists()
        target.parent.mkdir(parents=True,exist_ok=True)
        shutil.copyfile(REPO/path,target)
    original_copy={row["path"]:sha(out/row["path"]) for row in identity["files"] if row["path"].startswith("project/")}
    assert all(original_copy[row["path"]]==row["sha256"] for row in identity["files"] if row["path"] in original_copy)
    captures=out/"captures"
    captures.mkdir()
    env=os.environ.copy()
    for name in ["APPDATA","LOCALAPPDATA","TEMP","TMP"]:
        path=out/"profile"/name
        path.mkdir(parents=True)
        env[name]=str(path)
    command=[str(ENGINE),"--path",str(project),"--position","30000,30000","--max-fps","60","--audio-driver","Dummy","--log-file",str(out/"godot.log"),"--script","res://"+HARNESS.as_posix()+"/preview.gd","--","--evidence="+captures.as_posix()]
    record={"task":"FLOATING_CUBE_A2_WEST_VIEW_READABILITY","source_head":git("rev-parse","HEAD"),"branch":git("branch","--show-current"),"build_source":identity["integration_commit"],"arguments":command,
            "engine_sha256":sha(ENGINE),"build_manifest_sha256":sha(BUILD/"BUILD_IDENTITY.json"),"preview_code_sha256":{path.as_posix():sha(REPO/path) for path in files},"started_utc":dt.datetime.now(dt.timezone.utc).isoformat(),
            "profile_environment":{name:env[name] for name in ["APPDATA","LOCALAPPDATA","TEMP","TMP"]}}
    save(out/"START.json",record)
    print(json.dumps({"output":str(out),"phase":"OWN_ISOLATED_RENDER"}),flush=True)
    startup=subprocess.STARTUPINFO()
    startup.dwFlags=subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow=0
    started=time.monotonic()
    with (out/"stdout.log").open("xb") as stdout,(out/"stderr.log").open("xb") as stderr:
        process=subprocess.Popen(command,cwd=project,env=env,stdout=stdout,stderr=stderr,startupinfo=startup,creationflags=subprocess.CREATE_NO_WINDOW)
        record["pid"]=process.pid
        try: record["exit_code"]=process.wait(timeout=180)
        except subprocess.TimeoutExpired:
            process.kill()  # Our child only.
            process.wait()
            record["exit_code"]="TIMEOUT_OWN_CHILD_ONLY"
    record["elapsed_seconds"]=time.monotonic()-started
    record["stderr_bytes"]=(out/"stderr.log").stat().st_size
    record["protected_files_changed"]=[name for name,digest in watched.items() if not Path(name).is_file() or sha(Path(name))!=digest]
    record["copied_production_drift"]=[name for name,digest in original_copy.items() if sha(out/name)!=digest]
    record["protected_refs_match"]=refs=={ref:git("rev-parse",ref) for ref in refs}
    record["old_profiles_match"]=profiles==helpers.profile_snapshot()
    report_file=captures/"report.json"
    report=json.loads(report_file.read_text(encoding="utf-8-sig")) if report_file.exists() else {}
    record["checks"]=report.get("checks",0)
    record["failures"]=report.get("failures",["Missing report"])
    record["capture_count"]=len(report.get("captures",[]))
    record["status"]="PASS" if (record["exit_code"]==0 and record["stderr_bytes"]==0 and record["checks"]>0 and not record["failures"] and record["capture_count"]==12 and not record["protected_files_changed"] and not record["copied_production_drift"] and record["protected_refs_match"] and record["old_profiles_match"]) else "FAIL"
    save(out/"PROCESS.json",record)
    print(json.dumps({k:record[k] for k in ["status","checks","failures","capture_count","exit_code","stderr_bytes","protected_files_changed","copied_production_drift","protected_refs_match","old_profiles_match"]}),flush=True)
    if record["stderr_bytes"]: print((out/"stderr.log").read_text(encoding="utf-8",errors="replace"),flush=True)
    raise SystemExit(0 if record["status"]=="PASS" else 1)


if __name__=="__main__": main()
