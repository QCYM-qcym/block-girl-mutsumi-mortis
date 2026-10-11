"""Append-only Owner03 execution. No gameplay, search, completion or intake code."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess

from receipts import admit

ROOT = Path(__file__).resolve().parents[3]
ENGINE = Path("D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe")
OUT = ROOT / "docs/beta-sprint/spatial-puzzle-batch-01/quality/full-development/evidence"
SOURCE_ROOTS = ["foundation", "game", "experiments", "prototype", "production", "tests",
                "project.godot", "default_bus_layout.tres",
                "docs/beta-sprint/spatial-puzzle-batch-01/CONTRACT.md",
                "docs/beta-sprint/spatial-puzzle-batch-01/RUNTIME_INTERFACE.md",
                "docs/beta-sprint/spatial-puzzle-batch-01/design",
                "docs/beta-sprint/spatial-puzzle-batch-01/full-development/REQUEST.md"]
OWNER = "tests/beta_sprint/spatial_quality/"
JOBS = {
    "orientation": (OWNER + "test_orientation_input.gd", False),
    "maps": (OWNER + "test_maps.gd", False),
    "mechanics": (OWNER + "test_mechanics.gd", False),
    "formal": (OWNER + "test_graphical.gd", True),
    "natural": (OWNER + "test_natural.gd", True),
    "camera_graphical": (OWNER + "test_graphical_camera.gd", True),
    "legacy_core": ("tests/beta_sprint/game_feel_owner_03/test_yellow_target_core.gd", False),
    "legacy_profile": ("tests/beta_sprint/game_feel_owner_03/test_yellow_target_legacy_profile.gd", False),
    "legacy_pconn": ("tests/beta_sprint/game_feel_owner_03/test_yellow_target_pconn.gd", False),
    "legacy_graphical": (OWNER + "test_legacy_focused.gd", True),
}


def git(*args):
    return subprocess.check_output(["git", "-C", str(ROOT), *args])


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write(path, value):
    path.write_bytes((json.dumps(value, ensure_ascii=False, indent=2) + "\n").encode("utf-8"))


def paths():
    return sorted(p for p in git("ls-files", "--cached", "--others", "--exclude-standard", "-z", "--", *SOURCE_ROOTS).decode("utf-8").split("\0")
                  if p and "/evidence/" not in p)


def snapshot():
    return {p: sha(ROOT / p) for p in paths()}


def verify_source(candidate, sources):
    entries = git("ls-tree", "-r", "-z", candidate, "--", *SOURCE_ROOTS).decode("utf-8").split("\0")
    expected = {}
    for entry in entries:
        if not entry:
            continue
        metadata, path = entry.split("\t", 1)
        if "/evidence/" not in path and not path.startswith(OWNER):
            expected[path] = metadata.split()[2]
    physical = {p for p in sources if not p.startswith(OWNER)}
    if physical != set(expected):
        raise ValueError(f"Dependency source set differs: {sorted(physical.symmetric_difference(expected))}")
    for p, blob in expected.items():
        data = (ROOT / p).read_bytes()
        actual = hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()
        if actual != blob:
            raise ValueError(f"Dependency bytes differ from candidate: {p}")


def normalize_legacy(job, raw):
    # One bounded historical receipt. Never converts it into a new-map case.
    expected_scope = "NEW_PROFILE_REAL" if job == "legacy_core" else "LEGACY_FOCUSED_REAL"
    expected_profile = "foundation.game_feel.v2" if job == "legacy_core" else "LEGACY_EXPLICIT"
    if raw.get("scope") != expected_scope or raw.get("profile") != expected_profile:
        return raw
    return {**raw, "original_scope": raw["scope"], "scope": "SPATIAL_OWNER_03_REAL",
            "dependency_pending": raw.get("dependency_pending", []),
            "cases": [{"id": "legacy." + job.removeprefix("legacy_"),
                       "facet": "NATURAL_GRAPHICAL" if job == "legacy_graphical" else "REAL_RUNTIME",
                       "checks": raw.get("checks", 0), "failures": raw.get("failures", ["missing report"]),
                       "status": "PASS" if raw.get("failures") == [] else "FAIL"}]}


def run(job, name, candidate, window, map_id=None, search_mode="full"):
    if not re.fullmatch(r"[A-Za-z0-9_-]{1,64}", name) or not re.fullmatch(r"[0-9a-f]{40}", candidate):
        raise ValueError("Fresh simple evidence name and full candidate SHA required")
    subprocess.run(["git", "-C", str(ROOT), "merge-base", "--is-ancestor", candidate, "HEAD"], check=True)
    script, graphical = JOBS[job]
    if graphical and not window:
        raise ValueError("Graphical window must first be coordinated with Owner00")
    sources = snapshot()
    verify_source(candidate, sources)
    out = OUT / name
    out.mkdir(parents=True, exist_ok=False)
    env = os.environ.copy()
    env["PYTHONDONTWRITEBYTECODE"] = "1"
    profile = out / "profile"
    for key, leaf in [("APPDATA", "Roaming"), ("LOCALAPPDATA", "Local"), ("TEMP", "Temp"), ("TMP", "Temp")]:
        directory = profile / leaf
        directory.mkdir(parents=True, exist_ok=True)
        env[key] = str(directory)
    head = git("rev-parse", "HEAD").decode().strip()
    args = [str(ENGINE)] + ([] if graphical else ["--headless"]) + ["--path", str(ROOT), "--script", "res://" + script,
            "--max-fps", "60", "--", "--evidence=" + out.as_posix(), "--execution-head=" + head]
    if map_id:
        args.append("--map=" + map_id)
    args.append("--search-mode=" + search_mode)
    receipt = {"job":job,"candidate":candidate,"execution_head":head,"graphical":graphical,
               "window_coordination":window,"arguments":args,"source_sha256":sources,
               "source_verified":True,"engine_sha256":sha(ENGINE),
               "dirty":git("status","--porcelain").decode("utf-8"),
               "started_utc":datetime.now(timezone.utc).isoformat(),
               "profile_environment":{k:env[k] for k in ("APPDATA","LOCALAPPDATA","TEMP","TMP")}}
    startup = subprocess.STARTUPINFO()
    startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = 0
    with (out / "stdout.log").open("wb") as stdout, (out / "stderr.log").open("wb") as stderr:
        proc = subprocess.Popen(args,cwd=ROOT,env=env,stdout=stdout,stderr=stderr,
                                startupinfo=startup,creationflags=subprocess.CREATE_NO_WINDOW)
        receipt["pid"] = proc.pid
        try:
            code = proc.wait(timeout=240)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait()
            code = "TIMEOUT"
    raw_path = out / "report.json"
    raw = json.loads(raw_path.read_text(encoding="utf-8-sig")) if raw_path.exists() else {}
    report = normalize_legacy(job, raw) if job.startswith("legacy_") else raw
    capture = report.get("capture", {})
    try:
        Path(capture.get("user_data_dir", "")).resolve().relative_to(profile.resolve())
        isolated = bool(capture.get("user_data_dir"))
    except ValueError:
        isolated = False
    after = snapshot()
    drift = sorted(p for p in set(sources).union(after) if sources.get(p) != after.get(p))
    receipt.update(exit_code=code,checks=report.get("checks",0),failures=report.get("failures",["missing report"]),
                   doubles=report.get("doubles"),stderr_bytes=(out/"stderr.log").stat().st_size,
                   report=report,raw_report_sha256=sha(raw_path) if raw_path.exists() else None,
                   source_drift=drift,capture_verified=(capture.get("pid")==proc.pid and capture.get("execution_head")==head
                   and isolated and (not graphical or capture.get("display")=="Windows")),
                   finished_utc=datetime.now(timezone.utc).isoformat())
    receipt["status"] = admit(receipt)
    write(out/"process.json",receipt)
    print(json.dumps({k:receipt[k] for k in ("status","job","checks","failures","exit_code","stderr_bytes","source_drift")}))
    return {"PASS":0,"PENDING":3,"FAIL":1}[receipt["status"]]


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("job", choices=JOBS)
    parser.add_argument("name")
    parser.add_argument("--candidate",required=True)
    parser.add_argument("--window-coordination",default="")
    parser.add_argument("--map")
    parser.add_argument("--search-mode",choices=["full","first"],default="full")
    opts=parser.parse_args()
    raise SystemExit(run(opts.job,opts.name,opts.candidate,opts.window_coordination,opts.map,opts.search_mode))
