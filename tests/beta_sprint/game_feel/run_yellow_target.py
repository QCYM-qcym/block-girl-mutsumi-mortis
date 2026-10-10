"""Owner03 append-only receipts. Probe/Unit results cannot sign new-profile Real PASS."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parents[3]
ENGINE = Path("D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe")
OUT_ROOT = ROOT / "docs/beta-sprint/game-feel-owner-03/yellow-target-01/evidence"
JOBS = {
    "probe": ("test_yellow_target_dependencies.gd", False),
    "core": ("test_yellow_target_core.gd", False),
    "formal": ("test_yellow_target_graphical.gd", True),
    "lifecycle": ("test_yellow_target_lifecycle.gd", True),
    "input": ("test_yellow_target_input.gd", True),
    "legacy_profile": ("test_yellow_target_legacy_profile.gd", False),
    "legacy_pconn": ("test_yellow_target_pconn.gd", False),
    "legacy_graphical": ("test_yellow_target_legacy_graphical.gd", True),
}
SOURCE_ROOTS = ["foundation", "game", "experiments/game_feel_01", "prototype/perspective",
                "production", "tests", "project.godot", "default_bus_layout.tres"]
OWNER_TEST_ROOTS = ("tests/beta_sprint/game_feel/", "tests/beta_sprint/game_feel_owner_03/")


def classify(r):
    if (r.get("exit_code") not in (0, 3) or r.get("stderr_bytes") != 0 or
            r.get("source_drift") != [] or r.get("doubles") != [] or
            r.get("failures") != [] or not r.get("checks", 0) > 0 or
            r.get("capture_verified") is not True):
        return "FAIL"
    if r.get("scope") == "DEPENDENCY_PROBE" or r.get("dependency_pending"):
        return "PENDING"
    if (r.get("exit_code") == 0 and r.get("scope") == "LEGACY_FOCUSED_REAL" and
            r.get("profile") == "LEGACY_EXPLICIT" and re.fullmatch(r"[0-9a-f]{40}", r.get("candidate") or "")):
        return "PASS" # Candidate-bound affected legacy job only.
    if (r.get("exit_code") != 0 or r.get("scope") != "NEW_PROFILE_REAL" or
            not re.fullmatch(r"[0-9a-f]{40}", r.get("candidate") or "") or
            r.get("profile") != "foundation.game_feel.v2"):
        return "FAIL"
    return "PASS"  # Qualifies this executed job, not all twelve matrix rows.


def git(*args):
    return subprocess.check_output(["git", "-C", str(ROOT), *args], encoding="utf-8").strip()


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write(path, value):
    path.write_bytes((json.dumps(value, ensure_ascii=False, indent=2) + "\n").encode("utf-8"))


def source_paths(root=ROOT, candidate=None):
    command = (["ls-tree", "-r", "--name-only", "-z", candidate] if candidate else
               ["ls-files", "--cached", "--others", "--exclude-standard", "-z"])
    raw = subprocess.check_output(["git", "-C", str(root), *command, "--", *SOURCE_ROOTS], encoding="utf-8")
    return {p for p in raw.split("\0") if p and "/evidence/" not in p}


def source_snapshot(root=ROOT):
    paths = source_paths(root)
    missing = sorted(p for p in paths if not (root / p).is_file())
    if missing:
        raise ValueError(f"missing tracked source files: {missing}")
    return {p: sha(root / p) for p in sorted(paths)}


def verify_candidate(candidate, current, root=ROOT):
    expected_paths = {p for p in source_paths(root, candidate) if not p.startswith(OWNER_TEST_ROOTS)}
    current_paths = {p for p in current if not p.startswith(OWNER_TEST_ROOTS)}
    missing = sorted(expected_paths - current_paths)
    additional = sorted(current_paths - expected_paths)
    if missing or additional:
        raise ValueError(f"candidate source set differs; missing={missing}, additional={additional}")
    for p in sorted(expected_paths):
        expected = subprocess.check_output(["git", "-C", str(root), "show", f"{candidate}:{p}"])
        if hashlib.sha256(expected).hexdigest() != current[p]:
            raise ValueError(f"Production/dependency bytes differ from supplied candidate: {p}")


def source_drift(before, root=ROOT):
    after_paths = source_paths(root)
    changed = set(before).symmetric_difference(after_paths)
    for p in set(before).intersection(after_paths):
        if not (root / p).is_file() or sha(root / p) != before[p]:
            changed.add(p)
    return sorted(changed)


def run(job, name, candidate=None):
    if not re.fullmatch(r"[A-Za-z0-9_-]{1,64}", name):
        raise ValueError("Fresh simple evidence name required")
    script, graphical = JOBS[job]
    if job != "probe":
        if not re.fullmatch(r"[0-9a-f]{40}", candidate or ""):
            raise ValueError("Real execution requires the supplied combined candidate SHA")
        subprocess.run(["git", "-C", str(ROOT), "merge-base", "--is-ancestor", candidate, "HEAD"], check=True)
    # No intake is performed here. Capture ALL tracked/nonignored source inputs.
    sources = source_snapshot()
    if job != "probe":
        verify_candidate(candidate, sources)
    out = OUT_ROOT / name
    out.mkdir(parents=True, exist_ok=False)
    env = os.environ.copy()
    profile = out / "profile"
    for k, leaf in [("APPDATA", "Roaming"), ("LOCALAPPDATA", "Local"), ("TEMP", "Temp"), ("TMP", "Temp")]:
        directory = profile / leaf
        directory.mkdir(parents=True, exist_ok=True)
        env[k] = str(directory)
    head = git("rev-parse", "HEAD")
    args = [str(ENGINE)] + ([] if graphical else ["--headless"]) + ["--path", str(ROOT), "--script",
            "res://tests/beta_sprint/game_feel_owner_03/" + script, "--max-fps", "60", "--",
            "--evidence=" + out.as_posix(), "--execution-head=" + head]
    startup = subprocess.STARTUPINFO()
    startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = 0
    receipt = dict(job=job, candidate=candidate, execution_head=head, dirty=git("status", "--porcelain=v1"),
                   arguments=args, engine_sha256=sha(ENGINE), source_sha256=sources,
                   profile_environment={k: env[k] for k in ("APPDATA", "LOCALAPPDATA", "TEMP", "TMP")},
                   started_utc=datetime.now(timezone.utc).isoformat())
    with (out / "stdout.log").open("wb") as stdout, (out / "stderr.log").open("wb") as stderr:
        proc = subprocess.Popen(args, cwd=ROOT, env=env, stdout=stdout, stderr=stderr,
                                startupinfo=startup, creationflags=subprocess.CREATE_NO_WINDOW)
        receipt["pid"] = proc.pid
        try:
            code = proc.wait(timeout=120)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait()
            code = "TIMEOUT"
    report_path = out / "report.json"
    report = json.loads(report_path.read_text(encoding="utf-8-sig")) if report_path.exists() else {}
    capture = report.get("capture", {})
    user_dir = capture.get("user_data_dir", "")
    try:
        Path(user_dir).resolve().relative_to(profile.resolve())
        isolated = bool(user_dir)
    except ValueError:
        isolated = False
    receipt.update(exit_code=code, checks=report.get("checks", 0), failures=report.get("failures", ["missing report"]),
                   doubles=report.get("doubles"), stderr_bytes=(out / "stderr.log").stat().st_size,
                   source_drift=source_drift(sources),
                   scope=report.get("scope"), profile=report.get("profile"), dependency_pending=report.get("dependency_pending", []),
                   capture_verified=(capture.get("pid") == proc.pid and capture.get("execution_head") == head and
                                     isolated and (not graphical or capture.get("display") == "Windows")),
                   capture=capture, finished_utc=datetime.now(timezone.utc).isoformat())
    receipt["status"] = classify(receipt)
    write(out / "process.json", receipt)
    print(json.dumps({k: receipt[k] for k in ("status", "job", "checks", "failures", "dependency_pending", "exit_code", "stderr_bytes", "execution_head")}))
    return 3 if receipt["status"] == "PENDING" else (0 if receipt["status"] == "PASS" else 1)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("job", choices=JOBS)
    parser.add_argument("name")
    parser.add_argument("--candidate")
    opts = parser.parse_args()
    raise SystemExit(run(opts.job, opts.name, opts.candidate))
