"""Run native settings writer/reader in distinct owned, headless Godot processes."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def inside(path, parent):
    return Path(path).resolve().is_relative_to(parent.resolve())


parser = argparse.ArgumentParser()
parser.add_argument("--evidence", required=True)
parser.add_argument("--engine", default="D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe")
args = parser.parse_args()
root = Path(__file__).resolve().parents[3]
out = Path(args.evidence).resolve()
out.mkdir(parents=True, exist_ok=False)
engine = Path(args.engine).resolve()
env = os.environ.copy()
profile = out / "profile"
for key in ["APPDATA", "LOCALAPPDATA", "TEMP", "TMP"]:
    folder = profile / key
    folder.mkdir(parents=True)
    env[key] = str(folder)
save_path = "user://native_menu/persistence/progress.json"
source_paths = [
    "tests/beta_sprint/ui_motion_native/test_persistence.gd",
    "tests/beta_sprint/ui_motion_native/persistence.py",
    "game/shell/game_feel_shell.gd", "game/shell/game_shell.gd",
    "game/shell/game_feel_host.gd", "game/shell/save_store.gd",
    "game/shell/settings.gd", "game/feel/ui/game_feel_ui.gd",
    "game/feel/audio/audio_director.gd", "game/shell/visual_02/menu_view.gd",
    "game/shell/visual_02/character_backdrop.gd",
]
sources = {path: digest(root / path) for path in source_paths}
rows = []
for phase in ["write", "restore"]:
    command = [str(engine), "--path", str(root), "--headless", "--audio-driver", "Dummy",
               "--script", "res://tests/beta_sprint/ui_motion_native/test_persistence.gd", "--",
               "--phase=" + phase, "--shell-save=" + save_path, "--evidence-dir=" + str(out)]
    started = time.monotonic()
    stdout_path = out / (phase + ".stdout.log")
    stderr_path = out / (phase + ".stderr.log")
    with stdout_path.open("wb") as stdout, stderr_path.open("wb") as stderr:
        process = subprocess.Popen(command, cwd=root, env=env, stdout=stdout, stderr=stderr,
                                   creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0)
        (out / (phase + "_running.json")).write_text(json.dumps({"pid": process.pid, "command": command}), encoding="utf-8")
        timed_out = False
        try:
            code = process.wait(timeout=75)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
            code = -1
            timed_out = True
    report_path = out / ("persistence_" + phase + ".json")
    report = json.loads(report_path.read_text(encoding="utf-8-sig")) if report_path.exists() else None
    stderr_text = stderr_path.read_text(encoding="utf-8", errors="replace")
    row = {"phase": phase, "pid": process.pid, "exit_code": code,
           "seconds": round(time.monotonic() - started, 3), "timed_out": timed_out,
           "stderr_empty": not stderr_text.strip(), "command": command, "report": report}
    row["passed"] = bool(code == 0 and row["stderr_empty"] and report
                         and report["checks"] >= (70 if phase == "write" else 25)
                         and not report["failures"] and report["pid"] == process.pid
                         and report["display"] == "headless"
                         and inside(report["user_data_dir"], profile / "APPDATA")
                         and inside(report["save_path"], profile / "APPDATA"))
    rows.append(row)
    print(json.dumps({key: value for key, value in row.items() if key not in ["command", "report"]}), flush=True)
    if not row["passed"]:
        print(stdout_path.read_text(encoding="utf-8", errors="replace")[-10000:], flush=True)
        print(stderr_text[-6000:], flush=True)
        break
source_drift = {path: sources[path] != digest(root / path) for path in source_paths}
passed = (len(rows) == 2 and all(row["passed"] for row in rows)
          and rows[0]["pid"] != rows[1]["pid"]
          and rows[0]["report"]["save_path"] == rows[1]["report"]["save_path"]
          and rows[0]["report"]["save_sha256"] == rows[1]["report"]["save_sha256"]
          and not any(source_drift.values()))
summary = {"status": "PASS" if passed else "FAIL", "checks": sum(row["report"]["checks"] for row in rows if row["report"]),
           "pids": [row["pid"] for row in rows], "engine_sha256": digest(engine),
           "source_sha256": sources, "source_drift": source_drift,
           "profile_environment": {key: env[key] for key in ["APPDATA", "LOCALAPPDATA", "TEMP", "TMP"]},
           "head": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip(),
           "scope": "HEADLESS_REAL_NATIVE_SETTINGS_FAILURE_RETRY_CANCEL_COLD_RESTORE", "human_qa": "NOT_RUN", "rows": rows}
(out / "process.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(json.dumps({key: summary[key] for key in ["status", "checks", "pids", "scope"]}), flush=True)
sys.exit(0 if passed else 1)
