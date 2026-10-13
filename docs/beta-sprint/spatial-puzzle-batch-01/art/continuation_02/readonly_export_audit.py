"""Read-only external audit. Outputs are restricted to this Git documentation folder.

Run with the bundled Python and -B. Never imports or executes external art scripts;
never renders, regenerates, extracts, restores, deletes, or writes an external asset.
Pillow only verifies and decodes existing PNGs in memory.
"""
from pathlib import Path
import csv
import datetime as dt
import hashlib
from html.parser import HTMLParser
import io
import json
import xml.etree.ElementTree as ET
import zipfile
from PIL import Image

BASE = "295a4702aeb17d6fced11cfdaa221e0ffa90dd12"
OUT = Path(__file__).resolve().parent
REPO = Path.cwd().resolve()
assert OUT == REPO / "docs/beta-sprint/spatial-puzzle-batch-01/art/continuation_02"
MODEL = Path(r"E:\Study\方块娘项目\若叶睦\model")
ART = MODEL / "art/production/work/GAME_ART_MECHANICS_BATCH_01"
BACKUP = ART.with_name(ART.name + "_SCOPE_RECOVERY_20261013")
OLD = ART / "tests/PACKAGE_SHA256.json"
INCIDENT = OUT.parent / "acceptance_01/EXTERNAL_WRITE_MANIFEST.json"
TZ = dt.timezone(dt.timedelta(hours=8))


def now():
    return dt.datetime.now(TZ).isoformat()


def sha_file(p):
    h = hashlib.sha256()
    with p.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def sha_stream(f):
    h = hashlib.sha256()
    for chunk in iter(lambda: f.read(1024 * 1024), b""):
        h.update(chunk)
    return h.hexdigest()


def read_json(p):
    return json.loads(p.read_text(encoding="utf-8-sig"))


def snapshot(root):
    return {p.relative_to(root).as_posix(): sha_file(p)
            for p in root.rglob("*") if p.is_file()}


class References(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.refs = []

    def handle_starttag(self, tag, attrs):
        self.refs.extend(v for k, v in attrs if k in ("src", "href") and v)


def format_check(p):
    if not p.is_file():
        return {"status": "MISSING"}
    try:
        if p.suffix == ".png":
            with Image.open(p) as im:
                dimensions = list(im.size)
                im.verify()
            with Image.open(p) as im:
                im.load()  # Decode existing bytes; do not save/resize/render.
            return {"status": "PASS_PNG_VERIFY_AND_DECODE", "dimensions": dimensions}
        if p.suffix == ".svg":
            xml = ET.parse(p).getroot()
            assert xml.tag == "{http://www.w3.org/2000/svg}svg"
            return {"status": "PASS_XML_PARSE_ONLY", "viewBox": xml.attrib.get("viewBox"),
                    "visual_render": "NOT_RUN"}
        if p.suffix == ".json":
            parsed = read_json(p)
            package_root = BACKUP if p.is_relative_to(BACKUP) else ART
            missing = [f for row in parsed for f in (row.get("svg"), row.get("png"))
                       if f and not (package_root / f).is_file()]
            return {"status": "PASS_JSON_AND_REFERENCES" if not missing else "FAIL_REFERENCES",
                    "parse_status": "PASS", "entries": len(parsed), "missing_references": missing}
        if p.suffix == ".html":
            parser = References()
            parser.feed(p.read_text(encoding="utf-8"))
            local = [s.split("#")[0] for s in parser.refs
                     if not s.startswith(("#", "data:", "http:", "https:"))]
            missing = [s for s in local if not (p.parent / s).is_file()]
            return {"status": "PASS_HTML_PARSE_AND_REFERENCES" if not missing else "FAIL_REFERENCES",
                    "parse_status": "PASS", "references_checked": len(local), "missing_references": missing,
                    "browser_render": "NOT_RUN"}
        return {"status": "NOT_RUN_UNSUPPORTED_FORMAT"}
    except Exception as exc:
        return {"status": "FAIL_FORMAT", "error": str(exc)}


started = now()
before_art, before_backup = snapshot(ART), snapshot(BACKUP)
old_bytes = OLD.read_bytes()
original = {r["path"].replace("\\", "/"): r["sha256"] for r in read_json(OLD)}
incident = read_json(INCIDENT)
post_manifest_path = BACKUP / "POST_EDIT_BACKUP_MANIFEST.json"
post = read_json(post_manifest_path)
post_hashes = {r["path"].replace("\\", "/"): r["sha256"] for r in post["files"]}
scope = [r["path"].replace("\\", "/")
         for r in incident["files_written_before_scope_correction"]
         if r["path"].replace("\\", "/") not in
         ("scripts/build_boards.cjs", "design/revisions/LAYOUT_REVIEW_20261013.md")]
assert len(scope) == len(set(scope)) == 59
rows = []
for name in scope:
    current, backup = ART / name, BACKUP / name
    old_sha, current_sha, backup_sha = original.get(name), before_art.get(name), before_backup.get(name)
    unchanged = old_sha is not None and old_sha == current_sha
    rows.append({"path": name,
                 "original_sha256": old_sha,
                 "original_hash_source": "tests/PACKAGE_SHA256.json" if old_sha else "UNKNOWN",
                 "original_hash_confidence": "CORROBORATED_LOCAL_PREINCIDENT_MANIFEST" if old_sha else "UNKNOWN",
                 "current_sha256": current_sha,
                 "post_edit_backup_sha256": backup_sha,
                 "backup_matches_incident_record": backup_sha == post_hashes.get(name),
                 "current_equals_backup": current_sha is not None and current_sha == backup_sha,
                 "current_equals_original_manifest": unchanged,
                 "current_format": format_check(current),
                 "backup_format": format_check(backup),
                 "current_bytes": current.stat().st_size if current.is_file() else None,
                 "original_bytes_available": "CURRENT_FILE_ALREADY_MATCHES" if unchanged else "NOT_YET_FOUND",
                 "recovery_confidence": "EXACT_BYTES_PRESENT_NO_RESTORE_NEEDED" if unchanged else
                    ("HASH_KNOWN_RESTORE_FEASIBILITY_UNKNOWN" if old_sha else "UNKNOWN")})

# Search model directory, including renamed PNG/SVG copies. No archive extraction.
files = [p for p in MODEL.rglob("*") if p.is_file()]
targets = {r["original_sha256"]: r["path"] for r in rows if not r["current_equals_original_manifest"]
           and r["original_sha256"]}
matches = []
scan_bytes = 0
scanned_images = 0
for p in files:
    if p.suffix.lower() not in (".png", ".svg"):
        continue
    h = sha_file(p)
    scanned_images += 1
    scan_bytes += p.stat().st_size
    if h in targets:
        matches.append({"original_for": targets[h], "path": str(p), "sha256": h})
archives = []
for p in files:
    if p.suffix.lower() not in (".zip", ".7z", ".rar", ".tar", ".gz"):
        continue
    item = {"path": str(p), "status": "NOT_INSPECTED_UNSUPPORTED_ARCHIVE"}
    if p.suffix.lower() == ".zip":
        try:
            with zipfile.ZipFile(p) as z:
                candidates = [i for i in z.infolist() if not i.is_dir()
                              and Path(i.filename).suffix.lower() in (".png", ".svg")]
                assert sum(i.file_size for i in candidates) < 1024 ** 3, "Archive read budget exceeded"
                found = []
                for info in candidates:
                    with z.open(info) as f:
                        h = sha_stream(f)
                    if h in targets:
                        found.append({"original_for": targets[h], "member": info.filename, "sha256": h})
                item.update(status="READ_ONLY_MEMBER_HASH_SEARCH", entries=len(z.infolist()),
                            image_members_hashed=len(candidates), matches=found)
        except Exception as exc:
            item.update(status="INCOMPLETE", error=str(exc))
    archives.append(item)
for row in rows:
    if row["original_bytes_available"] != "NOT_YET_FOUND":
        continue
    found = any(m["original_for"] == row["path"] for m in matches) or any(
        m["original_for"] == row["path"] for a in archives for m in a.get("matches", []))
    row["original_bytes_available"] = "VERIFIED_COPY_FOUND" if found else "NOT_FOUND_IN_SEARCHED_SCOPE"
    if found:
        row["recovery_confidence"] = "EXACT_COPY_AVAILABLE_RESTORE_NOT_AUTHORIZED"

missing_original = [p for p in original if p not in before_art]
different_original = [p for p, h in original.items() if p in before_art and before_art[p] != h]
after_art, after_backup = snapshot(ART), snapshot(BACKUP)
drift_art = sorted(k for k in before_art.keys() | after_art.keys() if before_art.get(k) != after_art.get(k))
drift_backup = sorted(k for k in before_backup.keys() | after_backup.keys() if before_backup.get(k) != after_backup.get(k))
data = {"task": "SPATIAL_PUZZLE_ACCEPTANCE_CONTINUATION_02", "owner": "05", "base_commit": BASE,
        "started_at": started, "finished_at": now(), "external_root": str(ART), "backup_root": str(BACKUP),
        "original_manifest": {"path": str(OLD), "sha256": hashlib.sha256(old_bytes).hexdigest(),
          "entries": len(original), "last_write_time_local": dt.datetime.fromtimestamp(OLD.stat().st_mtime, TZ).isoformat(),
          "in_incident_write_list": False, "signature_or_independent_immutable_anchor": "NOT_FOUND",
          "trust_basis": ["Local manifest predates incident by recorded mtime (not proof alone)",
                         "Incident write list and generator output scope exclude this manifest",
                         "Original finalize script records SHA256 for package files",
                         "174/177 package entries match including restored generator; three mismatches explain observed layout edit"],
          "missing_original_entries": missing_original, "different_original_entries": different_original},
        "post_edit_manifest": {"sha256": sha_file(post_manifest_path),
          "matches_incident_record": sha_file(post_manifest_path) == incident["backup_manifest_sha256"],
          "meaning": "Post-edit evidence ONLY; not original backup"},
        "summary": {"exports": len(rows), "original_hash_known": sum(r["original_sha256"] is not None for r in rows),
          "unchanged_vs_original": sum(r["current_equals_original_manifest"] for r in rows),
          "changed_vs_original": sum(not r["current_equals_original_manifest"] for r in rows),
          "current_equals_post_edit_backup": sum(r["current_equals_backup"] for r in rows),
          "missing_current": sum(r["current_sha256"] is None for r in rows),
          "format_failures": [r["path"] for r in rows if not r["current_format"]["status"].startswith("PASS")],
          "backup_reference_or_format_issues": [r["path"] for r in rows if not r["backup_format"]["status"].startswith("PASS")],
          "restored_script_equals_original": before_art.get("scripts/build_boards.cjs") == original.get("scripts/build_boards.cjs")},
        "copy_search": {"root": str(MODEL), "files_enumerated": len(files), "png_svg_files_hashed": scanned_images,
          "png_svg_bytes_read": scan_bytes, "matching_original_copies": matches, "archives": archives,
          "git_markers": [str(p) for p in MODEL.rglob(".git")],
          "limits": "No OS restore points, deleted-file recovery, remote backup accounts, or unrelated disks were inspected; absence here does not prove permanent loss"},
        "read_only_check": {"art_files_hashed_before_after": len(before_art), "backup_files_hashed_before_after": len(before_backup),
          "art_drift": drift_art, "backup_drift": drift_backup,
          "external_asset_writes": "NONE", "script_execution_or_regeneration": "NOT_RUN", "restore": "NOT_RUN_NOT_AUTHORIZED"},
        "rows": rows}
assert not drift_art and not drift_backup, "External bytes changed during read-only audit; investigate concurrency"
# The only write operations in this tool are to OUT, inside the approved Git path.
(OUT / "ORIGINAL_PACKAGE_SHA256.json").write_bytes(old_bytes)
(OUT / "EXTERNAL_EXPORT_AUDIT.json").write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
csv_rows = []
for r in rows:
    csv_rows.append({k: r[k] for k in ("path", "original_hash_source", "original_sha256", "current_sha256",
        "post_edit_backup_sha256", "current_equals_original_manifest", "current_equals_backup", "original_bytes_available", "recovery_confidence")}
        | {"current_format": r["current_format"]["status"], "backup_format": r["backup_format"]["status"]})
buffer = io.StringIO(newline="")
writer = csv.DictWriter(buffer, fieldnames=list(csv_rows[0]), lineterminator="\n")
writer.writeheader()
writer.writerows(csv_rows)
(OUT / "EXTERNAL_EXPORT_AUDIT.csv").write_text(buffer.getvalue(), encoding="utf-8-sig", newline="\n")
print(json.dumps({"summary": data["summary"], "search_images": scanned_images,
                  "read_only_check": data["read_only_check"]}, ensure_ascii=True))
