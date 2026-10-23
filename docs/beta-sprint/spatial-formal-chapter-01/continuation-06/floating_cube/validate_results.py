"""Read-only validation of the 06 scoring document and its actual evidence.

Run from any directory. Paths in JSON may be absolute, relative to this file,
or repo-relative; ambiguous existing relative paths are rejected. Requires jsonschema with Draft 2020-12;
--dependency-dir can select an existing isolated installation. --self-test first
validates the real report, then checks that deliberate corruptions are rejected.
No captures, reports, dependency installations or output files are written.
"""
from pathlib import Path
import argparse
import copy
import hashlib
import json
import math
import re
import struct
import sys

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
REPO = HERE.parents[4]
WEIGHTS = {"V1": 30, "V2": 20, "V3": 15, "V4": 15, "V5": 10, "V6": 10}
VARIANTS = {"CURRENT", "A1", "A2"}
CONTEXTS = {"FORMAL_SURFACE", "FORMAL_INNER", "INNER_MATERIAL_STUDY"}
CAMERAS = ("NORTH", "EAST", "SOUTH", "WEST")


def require(condition, message):
    if not condition:
        raise ValueError(message)


def load(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def resolve_path(value):
    path = Path(value)
    if path.is_absolute():
        return path.resolve()
    candidates = {(base / path).resolve() for base in (HERE, REPO)}
    existing = [candidate for candidate in candidates if candidate.exists()]
    require(len(existing) <= 1, "Ambiguous relative evidence path: " + value)
    return existing[0] if existing else (HERE / path).resolve()


def digest(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def equal_number(actual, expected, label):
    require(isinstance(actual, (int, float)) and not isinstance(actual, bool)
            and math.isfinite(actual) and math.isclose(actual, expected, abs_tol=1e-9, rel_tol=0),
            f"{label}: expected {expected}, got {actual}")


def keyed(rows, key, expected, label):
    result = {row[key]: row for row in rows}
    require(len(result) == len(rows) and set(result) == set(expected),
            f"{label}: duplicate or missing {key}")
    return result


def semantic_check(data, check_files=True):
    require(not re.search(r"TODO|TBD|待填写|待评估|待填充|<实际>",
                          json.dumps(data, ensure_ascii=False)), "Unfilled placeholder")
    evidence = {row["id"]: row for row in data["evidence"]}
    require(len(evidence) == len(data["evidence"]) == 36, "Expected 36 unique capture IDs")
    expected = {(context, variant, q) for context in CONTEXTS for variant in VARIANTS for q in range(4)}
    actual = {(row["context"], row["variant"], row["quadrant"]) for row in evidence.values()}
    require(actual == expected and len(actual) == len(evidence), "Capture coverage must be 3 contexts x 3 variants x 4 views")
    require(len({resolve_path(row["path"]) for row in evidence.values()}) == 36,
            "Capture paths must identify 36 distinct files")
    for row in evidence.values():
        require(row["camera_name"] == CAMERAS[row["quadrant"]], "Capture camera/quadrant mismatch: " + row["id"])
        surface = row["context"] == "FORMAL_SURFACE"
        study = row["context"] == "INNER_MATERIAL_STUDY"
        require(row["roof_visible_in_gameplay"] is surface and row["artificial_study"] is study,
                "Formal hidden target and artificial study conflated: " + row["id"])

    def walk(value, label="document"):
        if isinstance(value, dict):
            for key, item in value.items():
                if key.endswith("evidence_ids"):
                    require(isinstance(item, list) and all(i in evidence for i in item), "Unknown evidence reference at " + label + "." + key)
                elif key.endswith("evidence_id"):
                    require(item in evidence, "Unknown evidence reference at " + label + "." + key)
                walk(item, label + "." + key)
        elif isinstance(value, list):
            for index, item in enumerate(value):
                walk(item, f"{label}[{index}]")
    walk(data)

    def refs_for(row, context, variant=None, q=None):
        rows = [evidence[i] for i in row["evidence_ids"]]
        require(rows and all(e["context"] == context for e in rows), "Wrong evidence context")
        if variant is not None:
            require(all(e["variant"] == variant for e in rows), "Wrong candidate evidence")
        if q is not None:
            require(all(e["quadrant"] == q for e in rows), "Wrong view evidence")

    def assessment(row, label):
        if row["status"] == "NOT_ASSESSED":
            require(row["score"] is None, label + ": NA must have null score")
        else:
            require(type(row["score"]) is int and 0 <= row["score"] <= 5,
                    label + ": assessed score must be an integer 0..5")

    def views_check(rows, context, variant=None):
        views = keyed(rows, "quadrant", range(4), "Four-view coverage")
        for q, view in views.items():
            require(view["camera_name"] == CAMERAS[q], "View camera/quadrant mismatch")
            assessment(view, f"{context} Q{q}")
            refs_for(view, context, variant, q)
        return views

    candidates = keyed(data["candidates"], "id", VARIANTS, "Candidates")
    metric_sets = {}
    view_sets = {}
    for variant, candidate in candidates.items():
        metrics = keyed(candidate["metrics"], "id", WEIGHTS, variant + " metrics")
        metric_sets[variant] = metrics
        require({key: m["weight"] for key, m in metrics.items()} == WEIGHTS
                and sum(m["weight"] for m in metrics.values()) == 100, "Wrong rubric weights")
        assessed = []
        for key, metric in metrics.items():
            assessment(metric, variant + " " + key)
            refs_for(metric, "FORMAL_SURFACE", variant)
            if metric["status"] == "ASSESSED":
                equal_number(metric["weighted"], round(metric["score"] / 5 * metric["weight"], 1), variant + " " + key + " weighted")
                assessed.append(metric)
            else:
                require(metric["weighted"] is None, "NA must have null weighted value")
        require(metrics["V5"]["status"] == "NOT_ASSESSED", "Missing full art context cannot be scored as V5")
        weight = sum(m["weight"] for m in assessed)
        subtotal = round(sum(m["weighted"] for m in assessed), 1)
        equal_number(candidate["assessed_weight_percent"], weight, variant + " assessed weight")
        equal_number(candidate["assessed_subtotal"], subtotal, variant + " subtotal (not normalized)")
        require(candidate["total"] is None and candidate["status"] == "PARTIAL",
                "Incomplete review must retain null full total and PARTIAL status")
        view_sets[variant] = views_check(candidate["views"], "FORMAL_SURFACE", variant)

    inner = data["inner_formal"]
    require(inner["status"] == "NOT_ASSESSED", "Formal Inner target is hidden")
    inner_views = views_check(inner["views"], "FORMAL_INNER")
    require(all(v["score"] is None and v["status"] == "NOT_ASSESSED" for v in inner_views.values()),
            "Hidden formal Inner target cannot be scored")
    study = data["inner_material_study"]
    require(study["status"] == "VISUAL_STUDY_ONLY", "Artificial study must stay separate")
    refs_for(study, "INNER_MATERIAL_STUDY")

    def unscored(value):
        if isinstance(value, dict):
            for key, item in value.items():
                if key in {"score", "weighted", "total", "assessed_subtotal"}:
                    require(item is None, "Artificial Inner study cannot supply formal scores")
                unscored(item)
        elif isinstance(value, list):
            for item in value:
                unscored(item)
    unscored(study)

    common = [key for key in WEIGHTS if all(metric_sets[v][key]["status"] == "ASSESSED" for v in VARIANTS)]
    comparison = data["comparison"]
    equal_number(comparison["common_assessed_weight_percent"], sum(WEIGHTS[key] for key in common), "Common assessed weight")
    for field, left, right in [("a2_minus_a1", "A2", "A1"), ("a2_minus_current", "A2", "CURRENT")]:
        difference = round(sum(metric_sets[left][key]["weighted"] - metric_sets[right][key]["weighted"] for key in common), 1)
        equal_number(comparison[field], difference, field)
    west = [view_sets[v][3] for v in ("A2", "A1")]
    if all(v["status"] == "ASSESSED" for v in west):
        equal_number(comparison["west_delta_vs_a1"], west[0]["score"] - west[1]["score"], "WEST delta")
    else:
        require(comparison["west_delta_vs_a1"] is None, "Unassessed WEST delta must be null")
    require(comparison["full_total_delta"] is None, "Partial review cannot claim a full-total delta")
    gates = keyed(data["hard_gates"], "id", {f"G{i}" for i in range(1, 9)}, "Hard gates")
    overall = "FAIL" if any(g["status"] == "FAIL" for g in gates.values()) else "PARTIAL"
    require(data["final_status"]["overall_visual_review"] == overall, "Overall status hides a failure or missing assessment")

    checked_provenance = 0
    if check_files:
        for row in evidence.values():
            path = resolve_path(row["path"])
            require(path.is_file(), "Missing evidence: " + str(path))
            require(digest(path) == row["sha256"], "Evidence SHA-256 mismatch: " + row["id"])
            with path.open("rb") as stream:
                header = stream.read(33)
            require(len(header) == 33 and header[:8] == b"\x89PNG\r\n\x1a\n"
                    and header[8:16] == b"\x00\x00\x00\x0dIHDR", "Not a PNG: " + row["id"])
            require(struct.unpack(">II", header[16:24]) == (row["width"], row["height"]) == (1280, 720),
                    "Native PNG dimension mismatch: " + row["id"])

        def provenance_files(value):
            nonlocal checked_provenance
            if isinstance(value, dict):
                pairs = [("path", "sha256")] if "path" in value and "sha256" in value else []
                pairs += [(key, key[:-5] + "_sha256") for key in value if key.endswith("_path") and key[:-5] + "_sha256" in value]
                for path_key, hash_key in pairs:
                    path = resolve_path(value[path_key])
                    require(path.is_file(), "Missing provenance file: " + str(path))
                    require(digest(path) == value[hash_key], "Provenance SHA-256 mismatch: " + str(path))
                    checked_provenance += 1
                for item in value.values():
                    provenance_files(item)
            elif isinstance(value, list):
                for item in value:
                    provenance_files(item)
        provenance_files(data["provenance"])
    return {"captures": 36, "contexts": 3, "variants": 3, "quadrants": 4,
            "provenance_files": checked_provenance, "full_total": None,
            "review_status": data["final_status"]["overall_visual_review"]}


def validate_document(data, validator, check_files=True):
    errors = sorted(validator.iter_errors(data), key=lambda e: tuple(str(x) for x in e.absolute_path))
    if errors:
        error = errors[0]
        location = ".".join(str(x) for x in error.absolute_path) or "document"
        raise ValueError(f"Schema {location}: {error.message}")
    return semantic_check(data, check_files=check_files)


def self_test(data, validator):
    """Reject real-report mutations without altering its files or stored scores."""
    cases = []
    changed = copy.deepcopy(data)
    changed["candidates"][0]["total"] = 100
    cases.append(("fabricated complete total", changed, False))
    changed = copy.deepcopy(data)
    metric = next(m for m in changed["candidates"][0]["metrics"] if m["id"] == "V5")
    metric["score"], metric["weighted"] = 0, 0
    cases.append(("NA replaced with zero", changed, False))
    changed = copy.deepcopy(data)
    changed["evidence"].pop()
    cases.append(("missing native capture", changed, False))
    changed = copy.deepcopy(data)
    changed["evidence"][0]["camera_name"] = CAMERAS[(changed["evidence"][0]["quadrant"] + 1) % 4]
    cases.append(("wrong project camera mapping", changed, False))
    changed = copy.deepcopy(data)
    changed["candidates"][0]["metrics"][1] = copy.deepcopy(changed["candidates"][0]["metrics"][0])
    cases.append(("duplicate rubric item", changed, False))
    changed = copy.deepcopy(data)
    metric = next(m for m in changed["candidates"][0]["metrics"] if m["status"] == "ASSESSED")
    metric["weighted"] += 0.1
    cases.append(("incorrect weighted arithmetic", changed, False))
    changed = copy.deepcopy(data)
    changed["comparison"]["a2_minus_a1"] += 0.1
    cases.append(("incorrect comparison", changed, False))
    changed = copy.deepcopy(data)
    study_id = next(e["id"] for e in changed["evidence"] if e["context"] == "INNER_MATERIAL_STUDY")
    changed["candidates"][0]["metrics"][0]["evidence_ids"] = [study_id]
    cases.append(("study passed off as gameplay scoring", changed, False))
    changed = copy.deepcopy(data)
    inner = next(e for e in changed["evidence"] if e["context"] == "FORMAL_INNER")
    inner["roof_visible_in_gameplay"] = True
    cases.append(("hidden formal target claimed visible", changed, False))
    changed = copy.deepcopy(data)
    old_hash = changed["evidence"][0]["sha256"]
    changed["evidence"][0]["sha256"] = ("0" if old_hash[0] != "0" else "1") + old_hash[1:]
    cases.append(("actual file hash tampering", changed, True))
    for label, changed, check_files in cases:
        try:
            validate_document(changed, validator, check_files=check_files)
        except ValueError:
            continue
        raise ValueError("Negative self-test was accepted: " + label)
    return len(cases)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dependency-dir", type=Path, help="Existing isolated directory containing jsonschema")
    parser.add_argument("--self-test", action="store_true", help="Also reject deliberate corruptions of the real report")
    args = parser.parse_args()
    if args.dependency_dir:
        sys.path.insert(0, str(args.dependency_dir.resolve()))
    try:
        from jsonschema import Draft202012Validator, FormatChecker
        schema = load(HERE / "SCORING_RESULTS.schema.json")
        Draft202012Validator.check_schema(schema)
        validator = Draft202012Validator(schema, format_checker=FormatChecker())
        data = load(HERE / "SCORING_RESULTS.json")
        result = validate_document(data, validator)
        if args.self_test:
            result["negative_mutations_rejected"] = self_test(data, validator)
        print(json.dumps({"validation": "PASS", **result}, ensure_ascii=False, separators=(",", ":")))
        return 0
    except (ImportError, OSError, ValueError, KeyError, TypeError) as error:
        print(json.dumps({"validation": "FAIL", "reason": str(error)}, ensure_ascii=False, separators=(",", ":")))
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
