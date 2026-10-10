"""Fresh append-only Owner 11 evidence; every child gets isolated APPDATA."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ROOT = Path(__file__).resolve().parents[3]
GODOT = Path("D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe")


def inventory(stage):
    roots = [ROOT / "game/feel/audio"]
    if stage != "policy":
        roots.append(ROOT / "production/experimental/game_feel_01/audio")
    files = sorted(p for base in roots for p in base.rglob("*") if p.is_file() and not p.name.endswith(".import"))
    files += [Path(__file__).resolve()]
    if stage != "import":
        files += [ROOT / "tests/beta_sprint/game_feel_owner_11/test_policy.gd"]
    if stage == "director":
        files += [ROOT / "tests/beta_sprint/game_feel_owner_11/test_director.gd"]
    return {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in files}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--name", required=True)
    parser.add_argument("--stage", choices=["policy", "director", "import"], default="policy")
    parser.add_argument("--godot", type=Path, default=GODOT)
    args = parser.parse_args()
    if not args.name.replace("_", "").replace("-", "").isalnum():
        raise SystemExit("simple evidence name required")
    evidence = ROOT / "tests/beta_sprint/game_feel_owner_11/evidence" / args.name
    evidence.mkdir(parents=True, exist_ok=False)
    (evidence.parent / ".gdignore").touch(exist_ok=True)
    profile = evidence / "profile"
    profile.mkdir()
    env = os.environ.copy()
    env.update(APPDATA=str(profile), LOCALAPPDATA=str(profile), XDG_DATA_HOME=str(profile))
    command = [str(args.godot), "--path", str(ROOT)]
    if args.stage == "import":
        command += ["--headless", "--editor", "--import"]
    else:
        if args.stage == "policy":
            command.append("--headless")
        else:
            command += ["--rendering-method", "gl_compatibility", "--rendering-driver", "opengl3", "--audio-driver", "WASAPI", "--max-fps", "60"]
        command += ["--script", f"res://tests/beta_sprint/game_feel_owner_11/test_{args.stage}.gd", "--", "--evidence-dir=" + str(evidence)]
    source = inventory(args.stage)
    metadata = {"stage": args.stage, "command": command, "cwd": str(ROOT),
                "head": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
                "branch": subprocess.check_output(["git", "branch", "--show-current"], cwd=ROOT, text=True).strip(),
                "dirty": subprocess.check_output(["git", "status", "--porcelain"], cwd=ROOT, text=True).splitlines(),
                "source_sha256": source, "engine_sha256": hashlib.sha256(args.godot.read_bytes()).hexdigest(),
                "profile": str(profile), "fixture_kind": "PRESENTATION_CONTRACT_UNIT", "authoritative_runtime": False,
                "doubles": ["synthetic game_feel.event.v1/v2 snapshots; no Safety proof"], "input": "direct audio API calls; no gameplay/OS input", "human_listening": "NOT_RUN"}
    start = time.monotonic()
    with (evidence / "stdout.log").open("wb") as stdout, (evidence / "stderr.log").open("wb") as stderr:
        child = subprocess.Popen(command, cwd=ROOT, env=env, stdout=stdout, stderr=stderr,
                                 creationflags=subprocess.CREATE_NO_WINDOW if sys.platform == "win32" else 0)
        metadata["pid"] = child.pid
        try:
            metadata["exit_code"] = child.wait(timeout=150)
        except subprocess.TimeoutExpired:
            child.kill()
            metadata["exit_code"] = child.wait()
            metadata["timed_out"] = True
    metadata["seconds"] = time.monotonic() - start
    metadata["source_drift"] = source != inventory(args.stage)
    metadata["stderr_bytes"] = (evidence / "stderr.log").stat().st_size
    out = (evidence / "stdout.log").read_text(encoding="utf-8", errors="replace")
    err = (evidence / "stderr.log").read_text(encoding="utf-8", errors="replace")
    metadata["status"] = "PASS" if metadata["exit_code"] == 0 and not metadata["source_drift"] and not any(s in out + err for s in ["SCRIPT ERROR", "ERROR:", "FAIL:"]) else "FAIL"
    metadata["evidence_class"] = "PARSER_CONFIG_DEPENDENCY_FAILURE" if any(s in out + err for s in ["Parse Error", "Compile Error", "Failed to load script"]) else ("CONFIG_IMPORT_ONLY" if args.stage == "import" else "PRESENTATION_CONTRACT_UNIT")
    if args.stage != "import" and not (evidence / (args.stage + ".json")).exists():
        metadata["status"] = "FAIL"
        metadata["missing_report"] = True
    for key in ["policy", "director"]:
        result = evidence / (key + ".json")
        if result.exists():
            data = json.loads(result.read_text(encoding="utf-8-sig"))
            metadata["checks"] = data["checks"]
            metadata["failures"] = data["failures"]
            metadata["user_data_dir"] = data["user_data_dir"]
            metadata["display"] = data["display"]
            if data["checks"] <= 0 or data["failures"]:
                metadata["status"] = "FAIL"
            if not str(Path(data["user_data_dir"]).resolve()).casefold().startswith(str(profile.resolve()).casefold() + os.sep):
                metadata["status"] = "FAIL"
                metadata["profile_error"] = "actual user directory outside isolated profile"
    (evidence / "process.json").write_text(json.dumps(metadata, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({k: metadata.get(k) for k in ["stage", "status", "pid", "exit_code", "checks", "stderr_bytes", "source_drift"]}))
    print(out[-4000:])
    if err:
        print(err[-2500:])
    return 0 if metadata["status"] == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
