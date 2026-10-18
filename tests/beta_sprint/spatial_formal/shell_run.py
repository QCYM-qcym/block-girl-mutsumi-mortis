"""Bounded headless checks; saves stay in explicit isolated beta_sprint slots."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import time

parser = argparse.ArgumentParser()
parser.add_argument("--stage", choices=("catalog", "settings", "landing", "fresh", "continue"), required=True)
parser.add_argument("--run-id", required=True)
parser.add_argument("--evidence", type=Path, required=True)
parser.add_argument("--godot", default="D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe")
args = parser.parse_args()
if not re.fullmatch(r"[a-zA-Z0-9_-]+", args.run_id):
    parser.error("run-id must be an isolated alphanumeric identifier")
root = Path(__file__).resolve().parents[3]
args.evidence.mkdir(parents=True, exist_ok=True)
if any((args.evidence / (args.stage + suffix)).exists() for suffix in (".stdout.log", ".stderr.log", ".process.json", ".sources.json")):
    parser.error("refusing to overwrite existing stage evidence; use a new evidence directory")
profile = args.evidence.resolve() / "profiles" / args.run_id
env = os.environ.copy()
for key, folder in {"APPDATA":"Roaming", "LOCALAPPDATA":"Local", "TEMP":"Temp", "TMP":"Temp"}.items():
    target = profile / folder
    target.mkdir(parents=True, exist_ok=True)
    env[key] = str(target)
source_paths = [root / "project.godot"]
for folder in ["game/shell", "game/levels/mutsumi", "experiments/spatial_puzzle_batch_01", "experiments/game_feel_01/host", "game/feel", "foundation"]:
    source_paths += [p for p in (root / folder).rglob("*") if p.suffix in (".gd", ".tscn", ".tres", ".json")]
source_paths += list(Path(__file__).parent.glob("shell_*.gd"))
source_paths += [Path(__file__).parent / "shell_legacy_rows.json"]
source_paths += [root / "tests/playtest/test_batch_01_runtime.gd", root / "tests/beta_sprint/shell_batch_02/delivered_routes.json"]
source_hashes = {p.relative_to(root).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in source_paths}
with Path(args.godot).open("rb") as engine_file:
    engine_sha = hashlib.file_digest(engine_file, "sha256").hexdigest()
head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root).decode().strip()
(args.evidence / (args.stage + ".sources.json")).write_text(json.dumps({"head":head,"engine_sha256":engine_sha,"files":source_hashes}, indent=2), encoding="utf-8")
script = {"catalog":"shell_catalog.gd", "settings":"shell_settings.gd", "landing":"shell_goal_landing.gd"}.get(args.stage, "shell_lifecycle.gd")
save_name = args.run_id + ("_settings" if args.stage == "settings" else "")
command = [args.godot, "--headless", "--audio-driver", "Dummy", "--path", str(root), "--script", "res://tests/beta_sprint/spatial_formal/" + script, "--", "--phase=" + args.stage, "--shell-save=user://beta_sprint/spatial_formal/" + save_name + ".json", "--evidence-dir=" + str(args.evidence.resolve())]
started = time.monotonic()
try:
    result = subprocess.run(command, cwd=root, env=env, capture_output=True, timeout=210, creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
    code, stdout, stderr = result.returncode, result.stdout, result.stderr
except subprocess.TimeoutExpired as error:
    code, stdout, stderr = 124, error.stdout or b"", error.stderr or b""
(args.evidence / (args.stage + ".stdout.log")).write_bytes(stdout)
(args.evidence / (args.stage + ".stderr.log")).write_bytes(stderr)
report = {"command":command,"exit_code":code,"elapsed_seconds":round(time.monotonic() - started, 3),"stage":args.stage,"evidence_type":"HEADLESS_NOT_HUMAN_QA"}
report["engine_error_lines"] = len(re.findall(rb"(?m)^(?:SCRIPT ERROR|ERROR):", stderr))
report["engine_sha256"] = engine_sha
report["isolated_profile"] = str(profile)
report["changed_sources_during_run"] = [name for name, digest in source_hashes.items() if hashlib.sha256((root / name).read_bytes()).hexdigest() != digest]
(args.evidence / (args.stage + ".process.json")).write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
print(json.dumps(report, ensure_ascii=False))
print(stdout.decode("utf-8", errors="replace"))
if stderr:
    print(stderr.decode("utf-8", errors="replace")[:6000])
raise SystemExit(code or (1 if report["engine_error_lines"] or report["changed_sources_during_run"] else 0))
