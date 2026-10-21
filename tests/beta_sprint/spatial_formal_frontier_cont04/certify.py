"""One bounded native provenance certification; never overwrites continuation."""
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
    processes = json.loads((out / "processes.json").read_text(encoding="utf-8-sig"))
    checked = json.loads((out / "checkpoint_verification/process.json").read_text(encoding="utf-8-sig"))
    spent = processes["total_engine_seconds"] + checked["elapsed_seconds"]
    cap = 1000
    assert 1600 - spent >= cap, ("insufficient remaining engine budget", spent, cap)
    summary = json.loads((out / "incremental/summary.json").read_text(encoding="utf-8-sig"))
    report = json.loads((out / "incremental/report.json").read_text(encoding="utf-8-sig"))
    assert summary["queue_exhausted"] and summary["census"]["states"] == 908 and summary["census"]["edges"] == 3916
    assert report["failures"] == []
    final = json.loads(next((out / "incremental").glob("*search_end.json")).read_text(encoding="utf-8-sig"))["graph"]
    historical = Path("E:/godot/beta-sprint-builds/spatial_formal_frontier_cont03_20261021_01/incremental/checkpoint_062_search_end.json")
    candidate = json.loads(historical.read_text(encoding="utf-8-sig"))["graph"]
    assert final["edges"] == candidate["edges"]
    assert final["nodes"].keys() == candidate["nodes"].keys()
    assert all(final["nodes"][k]["state"] == n["state"] for k,n in candidate["nodes"].items())
    relative = "tests/beta_sprint/spatial_formal_frontier_cont04/certify.gd"
    shutil.copy2(ROOT / relative, out / "project" / relative)
    run = out / "live_certification"
    run.mkdir(exist_ok=False)
    env = os.environ.copy()
    for key in ["APPDATA", "LOCALAPPDATA", "TEMP", "TMP"]:
        directory = run / "profile" / key
        directory.mkdir(parents=True)
        env[key] = str(directory)
    args = [str(ENGINE), "--headless", "--path", str(out / "project"), "--script", "res://" + relative, "--", "--evidence=" + run.as_posix(), "--execution-head=" + BASE]
    receipt = {"name": "live_certification", "arguments": args, "cap_seconds": cap, "prior_engine_seconds": spent, "harness_sha256": sha(ROOT / relative), "started_unix": time.time(), "authorization": "Root conditional authorization after verified 908/3916 closure; one attempt only; stage cap 1600 s", "estimated_search_seconds": 9744 * 580.026 / 8265}
    started = time.monotonic()
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
    receipt["total_engine_seconds"] = spent + receipt["elapsed_seconds"]
    receipt["stderr_bytes"] = (run / "stderr.log").stat().st_size
    binding = json.loads((out / "source_binding.json").read_text(encoding="utf-8-sig"))
    receipt["source_drift"] = [rel for rel, expected in binding["copied_sha256"].items() if sha(out / "project" / rel) != expected]
    receipt["prior_unchanged"] = sha(Path(binding["prior"])) == binding["prior_sha256"]
    if (run / "report.json").exists():
        report = json.loads((run / "report.json").read_text(encoding="utf-8-sig"))
        receipt["checks"] = report["checks"]
        receipt["failures"] = report["failures"]
        capture = report["capture"]
        receipt["capture_verified"] = capture["pid"] == process.pid and capture["display"] == "headless" and Path(capture["user_data_dir"]).is_relative_to(run / "profile") and capture["execution_head"] == BASE
    write(run / "process.json", receipt)
    print(json.dumps(receipt, indent=2))

if __name__ == "__main__":
    main(Path(sys.argv[1]).resolve())
