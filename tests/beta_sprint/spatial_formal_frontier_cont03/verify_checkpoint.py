"""Read-only final typed checkpoint admission in a fresh isolated engine process."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time
sys.dont_write_bytecode = True
from run import ROOT, BASE, ENGINE, sha, write

def main(out):
    project = out / "project"
    relative = "tests/beta_sprint/spatial_formal_frontier_cont03/checkpoint_check.gd"
    shutil.copy2(ROOT / relative, project / relative)
    run = out / "checkpoint_verification"
    run.mkdir(exist_ok=False)
    final = sorted((out / "incremental").glob("checkpoint_*.bin"))[-1]
    env = os.environ.copy()
    for key in ["APPDATA", "LOCALAPPDATA", "TEMP", "TMP"]:
        directory = run / "profile" / key
        directory.mkdir(parents=True)
        env[key] = str(directory)
    args = [str(ENGINE), "--headless", "--path", str(project), "--script", "res://" + relative, "--", "--checkpoint=" + final.as_posix(), "--evidence=" + run.as_posix(), "--execution-head=" + BASE]
    receipt = {"name": "checkpoint_verification", "arguments": args, "cap_seconds": 40, "checkpoint_sha256": sha(final), "harness_sha256": sha(ROOT / relative), "started_unix": time.time()}
    started = time.monotonic()
    with (run / "stdout.log").open("wb") as stdout, (run / "stderr.log").open("wb") as stderr:
        process = subprocess.Popen(args, stdout=stdout, stderr=stderr, env=env, creationflags=subprocess.CREATE_NO_WINDOW)
        receipt["pid"] = process.pid
        write(run / "running.json", receipt)
        try:
            receipt["exit_code"] = process.wait(timeout=40)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
            receipt["exit_code"] = "TIMEOUT"
    receipt["elapsed_seconds"] = time.monotonic() - started
    receipt["stderr_bytes"] = (run / "stderr.log").stat().st_size
    if (run / "report.json").exists():
        report = json.loads((run / "report.json").read_text(encoding="utf-8"))
        receipt["checks"] = report["checks"]
        receipt["failures"] = report["failures"]
        capture = report["capture"]
        receipt["capture_verified"] = capture["pid"] == process.pid and capture["display"] == "headless" and Path(capture["user_data_dir"]).is_relative_to(run / "profile")
    write(run / "process.json", receipt)
    print(json.dumps(receipt, indent=2))

if __name__ == "__main__":
    main(Path(sys.argv[1]).resolve())
