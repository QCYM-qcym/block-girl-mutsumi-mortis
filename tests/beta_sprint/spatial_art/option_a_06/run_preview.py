"""New copied-project render only. Never touches a foreign process/window/profile.

Run from the assigned worktree with Python -B; output must be a fresh absolute
directory below E:/godot/beta-sprint-builds/QA/floating_cube_a06.
"""
import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import time

REPO = Path(__file__).resolve().parents[4]
HARNESS = Path("tests/beta_sprint/spatial_art/option_a_06")
BUILD = Path("E:/godot/beta-sprint-builds/beta_spatial_formal_chapter_20261019_01")
ENGINE = Path("D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe")
PRIOR = Path("E:/godot/beta-sprint-builds/floating_cube_scoring05_20261021_01/PRESERVATION_BEFORE.json")
OUTPUT_ROOT = Path("E:/godot/beta-sprint-builds/QA/floating_cube_a06").resolve()


def sha(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def save(path, value):
    with path.open("x", encoding="utf-8", newline="\n") as stream:
        stream.write(json.dumps(value, ensure_ascii=False, indent=2) + "\n")


def git(*args):
    return subprocess.check_output(["git", *args], cwd=REPO, text=True).strip()


def profile_snapshot():
    result = {}
    prior = json.loads(PRIOR.read_text(encoding="utf-8-sig"))
    for name in prior["profile_snapshots"]:
        path = Path(name)
        result[name] = {"exists": path.exists(), "files": {
            p.relative_to(path).as_posix(): sha(p) for p in sorted(path.rglob("*")) if p.is_file()
        } if path.exists() else {}}
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    out = args.output.resolve()
    assert out.is_relative_to(OUTPUT_ROOT) and out != OUTPUT_ROOT and not out.exists(), "fresh isolated output required"
    base = git("rev-parse", "HEAD")
    branch = git("branch", "--show-current")
    assert branch == "feat/spatial-formal-chapter-01"
    identity = json.loads((BUILD / "BUILD_IDENTITY.json").read_text(encoding="utf-8-sig"))
    scopes = ["foundation", "game", "experiments", "production", "prototype", "project.godot", "default_bus_layout.tres", "icon.svg"]
    assert not git("diff", "--name-only", identity["integration_commit"], "HEAD", "--", *scopes), "production differs from verified Build"
    assert not git("diff", "--name-only", "HEAD", "--", *scopes), "local production changes"
    watched = {str(BUILD / row["path"]): sha(BUILD / row["path"]) for row in identity["files"]}
    assert all(watched[str(BUILD / row["path"])] == row["sha256"] for row in identity["files"]), "Build manifest mismatch"
    prior = json.loads(PRIOR.read_text(encoding="utf-8-sig"))
    for bucket in ["preview_hashes", "watched_hashes"]:
        for name in prior[bucket]:
            assert Path(name).is_file(), name
            watched[name] = sha(Path(name))
    for p in (REPO / "docs/beta-sprint/spatial-formal-chapter-01/continuation-05").rglob("*"):
        if p.is_file(): watched[str(p)] = sha(p)
    for folder in scopes:
        root = REPO / folder
        paths = [root] if root.is_file() else root.rglob("*")
        for p in paths:
            if p.is_file(): watched[str(p)] = sha(p)
    art_root = Path("E:/Study/方块娘项目/若叶睦/model/art/production/work")
    for folder in ["GAME_ART_MECHANICS_BATCH_01", "GAME_ART_MECHANICS_BATCH_01_SCOPE_RECOVERY_20261013"]:
        for p in (art_root / folder).rglob("*"):
            if p.is_file(): watched[str(p)] = sha(p)
    zip_path = BUILD.with_suffix(".zip")
    if zip_path.is_file(): watched[str(zip_path)] = sha(zip_path)
    refs = {ref: git("rev-parse", ref) for ref in prior["git_refs"]}
    profiles = profile_snapshot()
    out.mkdir(parents=True)
    save(out / "PRESERVATION_BEFORE.json", {"base":base,"branch":branch,"hashes":watched,"refs":refs,"profiles":profiles})
    project = out / "project"
    shutil.copytree(BUILD / "project", project)
    target = project / HARNESS
    target.mkdir(parents=True, exist_ok=False)
    for name in ["preview.gd", "roof_coarse_a2.gdshader"]:
        shutil.copyfile(REPO / HARNESS / name, target / name)
    legacy = Path("tests/beta_sprint/spatial_art/polish_03/roof_coarse.gdshader")
    (project / legacy).parent.mkdir(parents=True, exist_ok=True)
    assert not (project / legacy).exists(), "new legacy comparison copy only"
    shutil.copyfile(REPO / legacy, project / legacy)
    original_copy = {row["path"]: sha(out / row["path"]) for row in identity["files"] if row["path"].startswith("project/")}
    assert all(original_copy[row["path"]] == row["sha256"] for row in identity["files"] if row["path"] in original_copy)
    captures = out / "captures"
    captures.mkdir()
    env = os.environ.copy()
    for name in ["APPDATA", "LOCALAPPDATA", "TEMP", "TMP"]:
        path = out / "profile" / name
        path.mkdir(parents=True)
        env[name] = str(path)
    command = [str(ENGINE), "--path", str(project), "--position", "30000,30000", "--max-fps", "60",
               "--audio-driver", "Dummy", "--log-file", str(out / "godot.log"),
               "--script", "res://" + HARNESS.as_posix() + "/preview.gd", "--", "--evidence=" + captures.as_posix()]
    record = {"task":"FLOATING_CUBE_OPTION_A_06","source_head":base,"branch":branch,"build_source":identity["integration_commit"],
              "arguments":command,"engine_sha256":sha(ENGINE),"build_manifest_sha256":sha(BUILD / "BUILD_IDENTITY.json"),
              "preview_code_sha256":{name:sha(target/name) for name in ["preview.gd","roof_coarse_a2.gdshader"]},
              "a1_sha256":sha(project/legacy),"started_utc":dt.datetime.now(dt.timezone.utc).isoformat(),
              "profile_environment":{name:env[name] for name in ["APPDATA","LOCALAPPDATA","TEMP","TMP"]}}
    save(out / "START.json", record)
    print(json.dumps({"output":str(out),"phase":"OWN_ISOLATED_RENDER"}), flush=True)
    startup = subprocess.STARTUPINFO()
    startup.dwFlags = subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = 0
    started = time.monotonic()
    with (out/"stdout.log").open("xb") as stdout, (out/"stderr.log").open("xb") as stderr:
        process = subprocess.Popen(command, cwd=project, env=env, stdout=stdout, stderr=stderr, startupinfo=startup,
                                   creationflags=subprocess.CREATE_NO_WINDOW)
        record["pid"] = process.pid
        try:
            record["exit_code"] = process.wait(timeout=180)
        except subprocess.TimeoutExpired:
            process.kill()  # Only the child created above.
            process.wait()
            record["exit_code"] = "TIMEOUT_OWN_CHILD_ONLY"
    record["elapsed_seconds"] = time.monotonic()-started
    record["stderr_bytes"] = (out/"stderr.log").stat().st_size
    changed = [name for name,digest in watched.items() if not Path(name).is_file() or sha(Path(name))!=digest]
    record["protected_files_changed"] = changed
    record["copied_production_drift"] = [name for name,digest in original_copy.items() if sha(out/name)!=digest]
    record["protected_refs_match"] = refs == {ref:git("rev-parse",ref) for ref in refs}
    record["old_profiles_match"] = profiles == profile_snapshot()
    report_file = captures / "report.json"
    report = json.loads(report_file.read_text(encoding="utf-8-sig")) if report_file.exists() else {}
    record["checks"] = report.get("checks",0)
    record["failures"] = report.get("failures",["Missing graphical report"])
    record["capture_count"] = len(report.get("captures",[]))
    record["status"] = "PASS" if (record["exit_code"]==0 and record["stderr_bytes"]==0 and record["checks"]>0
        and not record["failures"] and record["capture_count"]==36 and not changed and not record["copied_production_drift"]
        and record["protected_refs_match"] and record["old_profiles_match"]) else "FAIL"
    save(out/"PROCESS.json", record)
    print(json.dumps({k:record[k] for k in ["status","exit_code","checks","failures","capture_count","stderr_bytes","elapsed_seconds","protected_files_changed","copied_production_drift","protected_refs_match","old_profiles_match"]}),flush=True)
    if record["stderr_bytes"]: print((out/"stderr.log").read_text(encoding="utf-8",errors="replace"),flush=True)
    raise SystemExit(0 if record["status"]=="PASS" else 1)


if __name__ == "__main__":
    main()
