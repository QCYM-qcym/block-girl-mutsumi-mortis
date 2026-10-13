"""Create a NEW isolated graphical preview; never executes external art generators.

Run with Python -B from the assigned worktree. One fresh directory per invocation.
Only the process launched here is waited on (or terminated on timeout).
"""
from pathlib import Path
import datetime as dt
import hashlib
import json
import os
import shutil
import subprocess
import sys

BASE = "e4fe5365334e93138dc9b8856d09670478789abc"
REPO = Path.cwd().resolve()
HARNESS = Path("tests/beta_sprint/spatial_art/polish_03")
DOCS = REPO / "docs/beta-sprint/spatial-puzzle-batch-01/art/polish_03"
BUILD = Path(r"E:\godot\beta-sprint-builds\beta_spatial_acceptance_input_fix_20261013_01")
ENGINE = Path(r"D:\APP\steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe")
stamp = dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
OUT = Path(r"E:\godot\beta-sprint-builds\QA\art_preview_polish03") / ("run_" + stamp)
assert not OUT.exists(), "Never overwrite an existing preview"
assert (REPO / HARNESS / "roof_preview.gd").is_file()


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def save(p, value):
    p.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")


identity = json.loads((BUILD / "BUILD_IDENTITY.json").read_text(encoding="utf-8-sig"))
diff = subprocess.check_output(["git", "diff", "--name-only", identity["integration_commit"], BASE,
                               "--", "foundation", "game", "experiments", "production", "prototype",
                               "project.godot", "default_bus_layout.tres", "icon.svg"], cwd=REPO, text=True)
assert not diff.strip(), "Package production sources differ from current approved baseline"
source_hashes = {}
for entry in identity["files"]:
    p = BUILD / entry["path"]
    assert p.is_file() and sha(p) == entry["sha256"], entry["path"]
    source_hashes[entry["path"]] = entry["sha256"]
OUT.mkdir(parents=True)
project = OUT / "project"
shutil.copytree(BUILD / "project", project)
target = project / HARNESS
target.mkdir(parents=True, exist_ok=False)
for name in ["roof_preview.gd", "roof_coarse.gdshader", "roof_inset.gdshader"]:
    shutil.copyfile(REPO / HARNESS / name, target / name)
copied_hashes = {e["path"]: sha(OUT / e["path"]) for e in identity["files"] if e["path"].startswith("project/")}
assert all(h == source_hashes[n] for n, h in copied_hashes.items())
captures = OUT / "captures"
captures.mkdir()
env = os.environ.copy()
for key, leaf in [("APPDATA", "Roaming"), ("LOCALAPPDATA", "Local"), ("TEMP", "Temp"), ("TMP", "Temp")]:
    p = OUT / "profile" / leaf
    p.mkdir(parents=True, exist_ok=True)
    env[key] = str(p)
args = [str(ENGINE), "--path", str(project), "--max-fps", "60", "--audio-driver", "Dummy",
        "--position", "30,60", "--log-file", str(OUT / "godot.log"),
        "--script", "res://" + HARNESS.as_posix() + "/roof_preview.gd", "--", "--evidence=" + captures.as_posix()]
record = {"task": "SPATIAL_PUZZLE_BATCH_01_POLISH_AND_ACCEPTANCE_03", "base_commit": BASE,
          "build_source": identity["integration_commit"], "project": str(project), "external_output": str(OUT),
          "arguments": args, "engine_sha256": sha(ENGINE), "original_build_manifest_sha256": sha(BUILD / "BUILD_IDENTITY.json"),
          "original_build_files_checked": len(source_hashes), "copy_files_checked": len(copied_hashes),
          "production_diff_between_build_and_base": [], "source_sha256": source_hashes,
          "preview_code_sha256": {n: sha(target / n) for n in ["roof_preview.gd", "roof_coarse.gdshader", "roof_inset.gdshader"]},
          "profile_environment": {k: env[k] for k in ["APPDATA", "LOCALAPPDATA", "TEMP", "TMP"]},
          "started_utc": dt.datetime.now(dt.timezone.utc).isoformat(), "art_change": "PROPOSAL_ONLY"}
save(OUT / "process_started.json", record)
print(json.dumps({"preview_root": str(OUT), "phase": "STARTING_OWN_GUI"}), flush=True)
with (OUT / "stdout.log").open("wb") as stdout, (OUT / "stderr.log").open("wb") as stderr:
    process = subprocess.Popen(args, cwd=project, env=env, stdout=stdout, stderr=stderr,
                               creationflags=subprocess.CREATE_NO_WINDOW)
    record["pid"] = process.pid
    try:
        record["exit_code"] = process.wait(timeout=180)
        record["natural_exit"] = True
    except subprocess.TimeoutExpired:
        process.kill()  # Only our own known child; no process enumeration or foreign PID.
        process.wait()
        record.update(exit_code="TIMEOUT", natural_exit=False)
record["gui_released_utc"] = dt.datetime.now(dt.timezone.utc).isoformat()
record["original_build_drift"] = [p for p, h in source_hashes.items() if sha(BUILD / p) != h]
record["copied_production_drift"] = [p for p, h in copied_hashes.items() if sha(OUT / p) != h]
record["stderr_bytes"] = (OUT / "stderr.log").stat().st_size
report = json.loads((captures / "report.json").read_text(encoding="utf-8-sig")) if (captures / "report.json").exists() else {}
record["checks"] = report.get("checks", 0)
record["failures"] = report.get("failures", ["Missing graphical report"])
record["captures"] = len(report.get("captures", []))
record["status"] = "PASS" if (record["exit_code"] == 0 and record["checks"] > 0 and not record["failures"]
    and record["captures"] == 32 and not record["original_build_drift"] and not record["copied_production_drift"]
    and record["stderr_bytes"] == 0) else "FAIL"
save(OUT / "process.json", record)
save(DOCS / ("RUN_" + stamp + ".json"), {k: v for k, v in record.items() if k != "source_sha256"})
print(json.dumps({k: record[k] for k in ["external_output", "pid", "exit_code", "status", "captures", "checks", "failures", "stderr_bytes", "gui_released_utc"]}), flush=True)
if record["stderr_bytes"]:
    print((OUT / "stderr.log").read_text(encoding="utf-8", errors="replace"), flush=True)
raise SystemExit(0 if record["status"] == "PASS" else 1)
