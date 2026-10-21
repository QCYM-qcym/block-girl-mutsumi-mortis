"""Run isolated S05 continuation with byte-bound dependencies and process caps."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import time

ROOT = Path(__file__).resolve().parents[3]
BASE = "f972cb850845cb2c31da6975ac7466437aafdec2"
BUILD_BASE = "763f0132bc58360fab0e224d0e9c54e00c92ae90"
OLD = Path("E:/godot/beta-sprint-builds/spatial_formal_state_cont02_20261019_01")
BUILD = Path("E:/godot/beta-sprint-builds/beta_spatial_formal_chapter_20261019_01")
ENGINE = Path("D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe")

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def write(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2), encoding="utf-8")

def main(out):
    out.mkdir(parents=True, exist_ok=False)
    project = out / "project"
    project.mkdir()
    old = json.loads((OLD / "source_binding.json").read_text())
    prior = OLD / "rubik_spatial_puzzle_01/explorer.json"
    binding = {"base": BASE, "build_source": BUILD_BASE, "source_root": str(ROOT), "prior": str(prior), "prior_sha256": sha(prior), "build_identity_sha256": sha(BUILD / "BUILD_IDENTITY.json"), "copied_sha256": {}, "harness_sha256": {}}
    for rel, expected in old["copied_sha256"].items():
        source = ROOT / rel
        assert sha(source) == expected, (rel, "historical source differs")
        assert sha(BUILD / "project" / rel) == expected, (rel, "build differs")
        blob = subprocess.check_output(["git", "-C", str(ROOT), "show", BASE + ":" + rel])
        assert hashlib.sha256(blob).hexdigest() == expected
        target = project / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
        binding["copied_sha256"][rel] = expected
    for rel in ["tests/beta_sprint/spatial_formal_state_cont02/graph.gd", "tests/beta_sprint/spatial_formal_frontier_cont03/frontier.gd"]:
        target = project / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / rel, target)
        binding["harness_sha256"][rel] = sha(target)
    shutil.copy2(__file__, out / "tested_runner.py")
    (project / "project.godot").write_text('config_version=5\n[application]\nconfig/name="S05 Frontier Continuation03"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
    binding["engine_sha256"] = sha(ENGINE)
    write(out / "source_binding.json", binding)
    receipts = []
    for name, tail, cap in [("setup", ["--editor", "--quit"], 35), ("incremental", ["--script", "res://tests/beta_sprint/spatial_formal_frontier_cont03/frontier.gd", "--", "--prior=" + prior.as_posix(), "--execution-head=" + BASE], 1050)]:
        run = out / name
        run.mkdir()
        env = os.environ.copy()
        for key in ["APPDATA", "LOCALAPPDATA", "TEMP", "TMP"]:
            directory = run / "profile" / key
            directory.mkdir(parents=True)
            env[key] = str(directory)
        args = [str(ENGINE), "--headless", "--path", str(project)] + tail
        if name == "incremental":
            args += ["--evidence=" + run.as_posix()]
        started = time.monotonic()
        receipt = {"name": name, "arguments": args, "cap_seconds": cap, "started_unix": time.time()}
        with (run / "stdout.log").open("wb") as stdout, (run / "stderr.log").open("wb") as stderr:
            process = subprocess.Popen(args, stdout=stdout, stderr=stderr, env=env, creationflags=subprocess.CREATE_NO_WINDOW)
            receipt["pid"] = process.pid
            write(run / "running.json", receipt)
            try:
                receipt["exit_code"] = process.wait(timeout=cap)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()
                receipt["exit_code"] = "TIMEOUT"
        receipt["elapsed_seconds"] = time.monotonic() - started
        receipt["stderr_bytes"] = (run / "stderr.log").stat().st_size
        receipt["source_drift"] = [rel for rel, expected in binding["copied_sha256"].items() if sha(project / rel) != expected]
        receipt["prior_unchanged"] = sha(prior) == binding["prior_sha256"]
        if (run / "report.json").exists():
            report = json.loads((run / "report.json").read_text(encoding="utf-8"))
            capture = report["capture"]
            receipt["checks"] = report["checks"]
            receipt["failures"] = report["failures"]
            receipt["capture_verified"] = capture["pid"] == process.pid and capture["display"] == "headless" and Path(capture["user_data_dir"]).is_relative_to(run / "profile") and capture["execution_head"] == BASE
        write(run / "process.json", receipt)
        receipts.append(receipt)
        write(out / "processes.json", {"runs": receipts, "total_engine_seconds": sum(row["elapsed_seconds"] for row in receipts), "maximum_engine_seconds": 1085})
        print(name, receipt["exit_code"], round(receipt["elapsed_seconds"], 3), receipt.get("failures"), flush=True)
        if name == "setup" and receipt["exit_code"] != 0:
            break

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("out", type=Path)
    main(parser.parse_args().out.resolve())
