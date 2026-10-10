"""Focused 03 launcher: unchanged production consumers, fresh evidence, exact source/profile identity."""
from pathlib import Path
from datetime import datetime, timezone
import argparse, hashlib, json, os, re, subprocess
from v2_reports import classify_execution, legacy_checks, execution_identity_failures

ROOT = Path(__file__).resolve().parents[3]
ENGINE = Path("D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe")
JOBS = {
    "formal_graphical": ("tests/beta_sprint/game_feel_owner_03/test_v2_graphical_trace.gd", True, "report.json", []),
    "formal_lifecycle": ("tests/beta_sprint/game_feel_owner_03/test_v2_replay_lifecycle.gd", True, "report.json", []),
    "full_slice_graphical": ("tests/beta_sprint/game_feel_full_slice/test_matrix.gd", True, "matrix.json", ["--phase=matrix", "--size=1280x720"]),
    "natural": ("tests/beta_sprint/pfall_integration/test_core.gd", True, "report.json", []),
    "spam": ("tests/beta_sprint/pfall_v2_integration/test_spam.gd", True, "report.json", []),
    "lifecycle": ("tests/beta_sprint/game_feel_owner_03/test_v2_lifecycle.gd", True, "report.json", []),
    "audio_lifecycle": ("tests/beta_sprint/game_feel_owner_03/test_v2_audio_lifecycle.gd", True, "report.json", []),
    "feedback": ("tests/beta_sprint/game_feel_owner_03/test_v2_feedback.gd", False, "report.json", []),
    "legacy_focused": ("tests/beta_sprint/game_feel_owner_03/test_v2_legacy_focused.gd", True, "report.json", []),
    "swept_safety": ("tests/beta_sprint/game_feel_owner_03/test_v2_swept_safety.gd", False, "report.json", []),
    "permissions": ("tests/beta_sprint/game_feel_owner_03/test_v2_permissions.gd", False, "report.json", []),
    "logical_path": ("tests/beta_sprint/pfall_v2_integration/test_path.gd", False, "report.json", []),
    "legacy_pconn": ("tests/gameplay/test_perspective_logic.gd", False, None, []),
    "ui_lifecycle": ("tests/beta_sprint/ui_host_integration/test_host.gd", True, "unit.json", []),
    "settings_seed": ("tests/beta_sprint/ui_host_integration/test_host.gd", True, "seed.json", ["--phase=seed"]),
    "settings_restore": ("tests/beta_sprint/ui_host_integration/test_host.gd", True, "restore.json", ["--phase=restore"]),
    "quit_seed": ("tests/beta_sprint/ui_host_integration/test_quit.gd", True, "seed.json", ["--phase=seed"]),
    "quit_restore": ("tests/beta_sprint/ui_host_integration/test_quit.gd", True, "restore.json", ["--phase=restore"]),
    **{f"ui_{w}x{h}": ("tests/beta_sprint/game_feel_owner_03/test_v2_ui_matrix.gd", True, "matrix.json", ["--phase=matrix", f"--size={w}x{h}"])
       for w, h in ((960, 720), (1280, 720), (1920, 1080))},
}

def digest(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()

def git(*args):
    return subprocess.check_output(["git", "-C", str(ROOT), *args], encoding="utf-8").strip()

def run(job, name, profile_from=None):
    script, graphical, report_name, extras = JOBS[job]
    out = ROOT / "docs/beta-sprint/game-feel-owner-03/v2/evidence" / name
    out.mkdir(parents=True, exist_ok=False)
    env = os.environ.copy()
    profile = out / "profile" if profile_from is None else out.parent / profile_from / "profile"
    if profile_from is not None and not profile.is_dir():
        raise ValueError("Cold restore requires the actual earlier isolated seed profile")
    for key, leaf in (("APPDATA", "Roaming"), ("LOCALAPPDATA", "Local"), ("TEMP", "Temp"), ("TMP", "Temp")):
        folder = profile / leaf
        folder.mkdir(parents=True, exist_ok=True)
        env[key] = str(folder)
    env["FOUNDATION_TEST_EVIDENCE"] = str(out)
    source_roots = ["foundation", "game/feel", "game/shell", "experiments/game_feel_01", "prototype/perspective",
                    "production/experimental/game_feel_01", "production/ui/beta_shell_01", "game/levels",
                    "production/art_3d", "game/player", "tests/playtest", "tests/beta_sprint/shell_batch_02",
                    "tests/beta_sprint/game_feel_owner_01",
                    "tests/beta_sprint/game_feel_full_slice", "tests/beta_sprint/graphical_bridge_02",
                    "tests/beta_sprint/game_feel", "tests/beta_sprint/game_feel_owner_03", "tests/beta_sprint/pfall_integration",
                    "tests/beta_sprint/pfall_v2_integration", "tests/beta_sprint/ui_host_integration", "tests/gameplay", "tests/foundation/level"]
    paths = git("ls-files", "--cached", "--others", "--exclude-standard", "-z", "--", *source_roots,
                "project.godot", "default_bus_layout.tres").split("\0")
    sources = {p: digest(ROOT / p) for p in sorted(set(paths)) if p and (ROOT / p).is_file()}
    head = git("rev-parse", "HEAD")
    args = [str(ENGINE)] + ([] if graphical else ["--headless"]) + ["--path", str(ROOT), "--script", "res://" + script,
            "--max-fps", "60", "--", "--evidence=" + out.as_posix(), "--evidence-dir=" + out.as_posix(),
            "--profile=" + profile.as_posix(), "--execution-head=" + head, *extras]
    record = {"job": job, "execution_head": head, "dirty": git("status", "--porcelain=v1"), "arguments": args,
              "engine_sha256": digest(ENGINE), "source_sha256": sources, "profile_environment": {k: env[k] for k in ("APPDATA", "LOCALAPPDATA", "TEMP", "TMP")},
              "started_utc": datetime.now(timezone.utc).isoformat(), "mode": "GRAPHICAL" if graphical else "LOGICAL_HEADLESS"}
    record["profile_saves_before"] = {p.relative_to(profile).as_posix(): digest(p) for p in profile.rglob("*.json")}
    startup = subprocess.STARTUPINFO()
    startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = 0
    with (out / "stdout.log").open("wb") as stdout, (out / "stderr.log").open("wb") as stderr:
        process = subprocess.Popen(args, cwd=ROOT, env=env, stdout=stdout, stderr=stderr,
                                   startupinfo=startup, creationflags=subprocess.CREATE_NO_WINDOW)
        record["pid"] = process.pid
        try:
            code = process.wait(timeout=120)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
            code = "TIMEOUT"
    if report_name:
        report_file = out / report_name
        report = json.loads(report_file.read_text(encoding="utf-8-sig")) if report_file.exists() else {}
    else:
        text = (out / "stdout.log").read_text(encoding="utf-8", errors="replace")
        count = legacy_checks(text)
        report = {"checks": count, "failures": [] if count else ["missing exact legacy marker"], "doubles": []}
        (out / "report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    drift = [p for p, sha in sources.items() if not (ROOT / p).is_file() or digest(ROOT / p) != sha]
    stderr_bytes = (out / "stderr.log").stat().st_size
    status = classify_execution(report, code, stderr_bytes, drift)
    capture = report.get("capture", report)
    user_dir = capture.get("user_data_dir", report.get("user_dir"))
    startup_text = (out / "stdout.log").read_text(encoding="utf-8", errors="replace")
    identity_failures = execution_identity_failures(report, graphical, profile, startup_text, process.pid)
    if capture.get("execution_head") and capture["execution_head"] != head:
        identity_failures.append("reported execution HEAD differs from launched source")
    if identity_failures:
        status = "FAIL"
    record.update(exit_code=code, checks=report.get("checks", 0), failures=report.get("failures", ["missing report"]) + identity_failures,
                  identity_failures=identity_failures, renderer_device_line=next((line for line in startup_text.splitlines() if " - Using Device" in line), None),
                  doubles=report.get("doubles"), stderr_bytes=stderr_bytes, source_drift=drift, status=status,
                  display=capture.get("display"), renderer=capture.get("renderer", report.get("observations", {}).get("renderer")),
                  user_data_dir=user_dir, finished_utc=datetime.now(timezone.utc).isoformat())
    record["profile_saves_after"] = {p.relative_to(profile).as_posix(): digest(p) for p in profile.rglob("*.json")}
    (out / "process.json").write_text(json.dumps(record, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({k: record[k] for k in ("job", "status", "checks", "failures", "doubles", "stderr_bytes", "pid", "execution_head")}, ensure_ascii=False))
    return 1 if status == "FAIL" else 0

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("job", choices=JOBS)
    parser.add_argument("name")
    parser.add_argument("--profile-from")
    options = parser.parse_args()
    if not re.fullmatch(r"[a-zA-Z0-9_-]{1,64}", options.name):
        parser.error("Use a simple fresh evidence name")
    if options.profile_from and not re.fullmatch(r"[a-zA-Z0-9_-]{1,64}", options.profile_from):
        parser.error("Use an exact earlier seed evidence name")
    raise SystemExit(run(options.job, options.name, options.profile_from))
