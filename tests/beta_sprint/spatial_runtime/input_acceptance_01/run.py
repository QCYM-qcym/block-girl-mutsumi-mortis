"""Owner01 headless evidence, isolated profile, no forced process termination."""
from pathlib import Path
import datetime, hashlib, json, os, re, subprocess, sys

root = Path(__file__).resolve().parents[4]
case, script = sys.argv[1:3]
if not re.fullmatch(r"[a-z0-9_]+", case) or not re.fullmatch(r"res://tests/[a-zA-Z0-9_/]+\.gd", script):
    raise SystemExit("Invalid evidence name or test path")
out = root / "docs/beta-sprint/spatial-puzzle-batch-01/runtime/input_acceptance_01/evidence" / case
profile = root / ".godot/ci01" / case / "p"
out.mkdir(parents=True, exist_ok=False)
profile.mkdir(parents=True, exist_ok=False)
engine = Path("D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe")
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
paths = subprocess.check_output(["git", "ls-files", "--cached", "--others", "--exclude-standard", "--", "foundation", "game/feel", "experiments/spatial_puzzle_batch_01", "experiments/game_feel_01", "tests/foundation", "tests/beta_sprint/spatial_runtime/input_acceptance_01", "tests/beta_sprint/spatial_owner_01", "tests/beta_sprint/spatial_owner_09", "tests/beta_sprint/game_feel_owner_01"], cwd=root).decode().splitlines()
sources = {p: sha(root / p) for p in sorted(set(paths)) if (root / p).is_file()}
env = os.environ.copy()
for name in ("APPDATA", "LOCALAPPDATA", "TEMP", "TMP"): env[name] = profile.as_posix()
env["FOUNDATION_TEST_EVIDENCE"] = out.as_posix()
args = [str(engine), "--headless", "--path", str(root), "--max-fps", "60", "--quit-after", "10000", "--script", script, "--", out.as_posix(), profile.as_posix()]
record = {"head":subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root).decode().strip(), "sources_sha256":sources, "engine_sha256":sha(engine), "arguments":args, "profile":profile.as_posix(), "started_utc":datetime.datetime.now(datetime.timezone.utc).isoformat(), "guard":"normal --quit-after10000 at max60FPS, after the Host's150second timer; no force kill", "doubles":[]}
with (out / "stdout.log").open("wb") as stdout, (out / "stderr.log").open("wb") as stderr:
    proc = subprocess.Popen(args, cwd=root, env=env, stdout=stdout, stderr=stderr, creationflags=subprocess.CREATE_NO_WINDOW)
    record["pid"] = proc.pid
    (out / "process.json").write_text(json.dumps(record, indent=2)+"\n", encoding="utf-8", newline="\n")
    record["exit_code"] = proc.wait()
record["finished_utc"] = datetime.datetime.now(datetime.timezone.utc).isoformat()
record["source_drift"] = [p for p,d in sources.items() if not (root/p).is_file() or sha(root/p)!=d]
structured = next((out/f for f in ("report.json", "results.json") if (out/f).is_file()), None)
summary = json.loads(structured.read_text(encoding="utf-8-sig")) if structured else {}
stdout = (out/"stdout.log").read_text(encoding="utf-8-sig")
count = re.search(r"checks=(\d+)", stdout)
record["checks"] = summary.get("checks", int(count.group(1)) if count else 0)
record["failures"] = summary.get("failures", [] if re.search(r"failures=(?:0\b|\[\])", stdout) else ["No successful structured result"])
record["stderr_bytes"] = (out/"stderr.log").stat().st_size
record["status"] = "PASS" if record["exit_code"]==0 and record["checks"]>0 and not record["failures"] and not record["source_drift"] and record["stderr_bytes"]==0 else "FAILED"
(out/"process.json").write_text(json.dumps(record, indent=2)+"\n", encoding="utf-8", newline="\n")
print(case, record["status"], "checks", record["checks"], "failures", record["failures"], "exit", record["exit_code"], "stderr", record["stderr_bytes"], "PID", proc.pid)
if record["stderr_bytes"]: print((out/"stderr.log").read_text(encoding="utf-8-sig"))
sys.exit(0 if record["status"]=="PASS" else 1)
