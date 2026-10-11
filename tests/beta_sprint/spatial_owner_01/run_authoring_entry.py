"""Owner01 append-only headless evidence; never writes Owner09 evidence."""
from pathlib import Path
import datetime, hashlib, json, os, re, shutil, subprocess, sys

root = Path(__file__).resolve().parents[3]
case, script = sys.argv[1:3]
if not re.fullmatch(r"[a-zA-Z0-9_]+", case):
    raise SystemExit("Invalid evidence name")
if not re.fullmatch(r"res://tests/(?:beta_sprint/spatial_owner_0[19]|foundation/authoring)/[a-zA-Z0-9_]+\.gd", script):
    raise SystemExit("Script outside approved test entry points")
out = root / "docs/beta-sprint/spatial-puzzle-batch-01/runtime/authoring_entry_02/evidence" / case
profile = root / ".godot/ae02" / case / "p"
out.mkdir(parents=True, exist_ok=False)
profile.mkdir(parents=True, exist_ok=False)
engine = Path("D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe")
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
paths = subprocess.check_output(["git", "ls-files", "--cached", "--others", "--exclude-standard", "--", "foundation", "experiments/spatial_puzzle_batch_01/maps", "tests/beta_sprint/spatial_owner_01", "tests/beta_sprint/spatial_owner_09", "tests/foundation/authoring"], cwd=root).decode().splitlines()
paths = sorted(set(paths))
sources = {p: sha(root / p) for p in paths if (root / p).is_file()}
env = os.environ.copy()
for name in ("APPDATA", "LOCALAPPDATA", "TEMP", "TMP"):
    env[name] = profile.as_posix()
legacy_user_evidence = script.startswith("res://tests/foundation/authoring/")
# Persistence tests intentionally retain their original author document URI.
# Saving their temporary resources beneath res:// makes those resources acquire
# a different authoritative URI; user:// preserves the existing test contract.
env["FOUNDATION_TEST_EVIDENCE"] = "user://" if legacy_user_evidence else out.as_posix()
args = [str(engine), "--headless", "--path", str(root), "--quit-after", "5000", "--script", script, "--", out.as_posix(), profile.as_posix()]
record = {"head": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root).decode().strip(), "dirty": subprocess.check_output(["git", "status", "--porcelain"], cwd=root).decode(), "sources_sha256": sources, "engine_sha256": sha(engine), "arguments": args, "profile": profile.as_posix(), "started_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(), "doubles": [], "guard": "Godot --quit-after 5000 normal exit; no forced termination"}
with (out / "stdout.log").open("wb") as stdout, (out / "stderr.log").open("wb") as stderr:
    proc = subprocess.Popen(args, cwd=root, env=env, stdout=stdout, stderr=stderr, creationflags=subprocess.CREATE_NO_WINDOW)
    record["pid"] = proc.pid
    (out / "process.json").write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8", newline="\n")
    record["exit_code"] = proc.wait()
record["finished_utc"] = datetime.datetime.now(datetime.timezone.utc).isoformat()
record["test_evidence_uri"] = env["FOUNDATION_TEST_EVIDENCE"]
if legacy_user_evidence:
    results = list(profile.rglob("results.json"))
    if len(results) == 1:
        shutil.copyfile(results[0], out / "results.json")
        record["saved_test_artifacts"] = {p.relative_to(profile).as_posix(): sha(p) for p in results[0].parent.iterdir() if p.is_file()}
record["source_drift"] = [p for p, digest in sources.items() if sha(root / p) != digest]
summary_path = next((out / f for f in ("report.json", "results.json") if (out / f).exists()), None)
summary = json.loads(summary_path.read_text(encoding="utf-8-sig")) if summary_path else {}
text = (out / "stdout.log").read_text(encoding="utf-8-sig")
match = re.search(r'(?:checks=|"checks"\s*:\s*)(\d+)', text)
record["checks"] = summary.get("checks", int(match.group(1)) if match else 0)
record["failures"] = summary.get("failures", [] if "failures=[]" in text else ["Missing structured results"])
record["status"] = "PASS" if record["exit_code"] == 0 and record["checks"] > 0 and not record["failures"] and not record["source_drift"] and not (out / "stderr.log").read_bytes() else "FAILED"
(out / "process.json").write_text(json.dumps(record, indent=2, ensure_ascii=False) + "\n", encoding="utf-8", newline="\n")
print(case, record["status"], "checks", record["checks"], "failures", record["failures"], "exit", record["exit_code"], "PID", proc.pid)
print((out / "stderr.log").read_text(encoding="utf-8-sig"))
sys.exit(0 if record["status"] == "PASS" else 1)
