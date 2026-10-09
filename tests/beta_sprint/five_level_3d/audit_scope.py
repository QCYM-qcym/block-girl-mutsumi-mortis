"""Read-only exact-byte scope/approved-art audit; writes only owner evidence."""
import argparse
import hashlib
import json
import subprocess
from pathlib import Path

BASE = "9e2e9c29a73272d431795f12db1fefaff2433b05"
SCENES = {
    "game/levels/mutsumi/batch_02/l04_borrowed_path.tscn",
    "game/levels/mutsumi/batch_02/l05_gate_home.tscn",
}
PREFIXES = (
    "game/levels/mutsumi/batch_02/levels_3d/",
    "tests/beta_sprint/five_level_3d/",
    "docs/beta-sprint/five-level-3d-owner/",
)

def sha(data):
    return hashlib.sha256(data).hexdigest()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[3]
    output = Path(args.output).resolve()
    evidence = root / PREFIXES[2]
    if not output.is_relative_to(evidence) or output.exists():
        raise SystemExit("New owner evidence filename required")
    def git(*parts):
        return subprocess.check_output(["git", "-C", str(root), *parts])
    entries = []
    for line in git("ls-tree", "-r", "-z", BASE).split(b"\0"):
        if not line:
            continue
        meta, name = line.split(b"\t", 1)
        if meta.split()[1] == b"blob":
            entries.append((meta.split()[2], name.decode("utf-8")))
    batch = subprocess.Popen(["git", "-C", str(root), "cat-file", "--batch"], stdin=subprocess.PIPE, stdout=subprocess.PIPE)
    frozen = []
    changed = []
    failures = []
    for oid, name in entries:
        batch.stdin.write(oid + b"\n")
        batch.stdin.flush()
        header = batch.stdout.readline().split()
        baseline = batch.stdout.read(int(header[2]))
        assert batch.stdout.read(1) == b"\n"
        path = root / name
        current = path.read_bytes() if path.is_file() else None
        row = {"path": name, "baseline_blob": oid.decode(), "baseline_sha256": sha(baseline), "current_sha256": sha(current) if current is not None else "ABSENT"}
        if name in SCENES:
            old = b'res://game/levels/mutsumi/batch_02/batch_02_level.gd'
            new = b'res://game/levels/mutsumi/batch_02/levels_3d/presented_level.gd'
            row["only_script_attachment_changed"] = current == baseline.replace(old, new)
            if not row["only_script_attachment_changed"]:
                failures.append("scene changed outside Script reference: " + name)
            changed.append(row)
        elif baseline != current:
            # Post-implementation owner docs/tests may be committed before the
            # fresh final run. They are allowed, never counted as frozen.
            if name.startswith(PREFIXES):
                changed.append(row)
            else:
                failures.append("frozen baseline byte mismatch: " + name)
                frozen.append(row)
        else:
            frozen.append(row)
    batch.stdin.close()
    batch.wait()
    assert batch.returncode == 0
    owner = []
    paths = git("ls-files", "--cached", "--others", "--exclude-standard", "-z").decode().split("\0")
    baseline_names = {name for _, name in entries}
    for name in sorted(set(filter(None, paths))):
        if name not in baseline_names and not name.startswith(PREFIXES):
            failures.append("unowned new file: " + name)
        if name in SCENES or name.startswith(PREFIXES):
            if (root / name).is_file():
                owner.append({"path": name, "sha256": sha((root / name).read_bytes())})
    manifest = json.loads((root / "docs/beta-sprint/playable-art-vertical-01/ART_ASSET_BINDING_MANIFEST.json").read_text(encoding="utf-8-sig"))
    art = []
    for row in manifest["rows"]:
        source = Path(row["source_asset"])
        project = root / row["project_relative"]
        checked = {"path": row["project_relative"], "source_path": str(source), "source_sha256": sha(source.read_bytes()), "project_sha256": sha(project.read_bytes()), "expected_source_sha256": row["source_sha256"], "expected_project_sha256": row["destination_sha256"]}
        if checked["source_sha256"] != row["source_sha256"] or checked["project_sha256"] != row["destination_sha256"]:
            failures.append("approved source/project mismatch: " + row["project_relative"])
        art.append(checked)
    report = {"baseline": BASE, "actual_head": git("rev-parse", "HEAD").decode().strip(), "project": str(root), "frozen_files": frozen, "scene_attachments": changed, "owner_files": owner, "approved_asset_count": manifest["asset_count"], "approved_art_files": art, "checks": len(frozen)+len(changed)+len(art)+len(owner), "failures": failures, "doubles": [], "push": "NOT_RUN"}
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
    print(json.dumps({"checks":report["checks"],"frozen":len(frozen),"approved_art":len(art),"failures":failures},ensure_ascii=False))
    raise SystemExit(1 if failures else 0)

if __name__ == "__main__":
    main()
