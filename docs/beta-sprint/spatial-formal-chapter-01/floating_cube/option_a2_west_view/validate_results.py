"""Read-only validation of the strict A2 task and immutable scoring history.

Reuses continuation-06 schema definitions and rubric weights. No rendering,
reports, dependency installations or output files are performed. Use an existing
jsonschema installation with --dependency-dir; --self-test rejects deliberate
in-memory corruptions after validating the actual report.
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
CHAPTER = HERE.parents[1]
SCHEMA = HERE / "SCORING_RESULTS.schema.json"
LEGACY_SCHEMA = CHAPTER / "continuation-06/floating_cube/SCORING_RESULTS.schema.json"
WEIGHTS = {"V1": 30, "V2": 20, "V3": 15, "V4": 15, "V5": 10, "V6": 10}
VARIANTS = {"CURRENT", "A1", "A2"}
CAMERAS = ("NORTH", "EAST", "SOUTH", "WEST")
HISTORY = {
    "SPATIAL_FORMAL_CHAPTER_01_CONTINUATION_05": CHAPTER / "continuation-05/floating_cube/SCORING_RESULTS.json",
    "FLOATING_CUBE_OPTION_A_06": CHAPTER / "continuation-06/floating_cube/SCORING_RESULTS.json",
}


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


def retained_scores(source):
    """Extract unchanged scores from either historical document shape."""
    candidates = source["candidates"]
    rows = candidates.items() if isinstance(candidates, dict) else ((row["id"], row) for row in candidates)
    result = {}
    for candidate_id, candidate in rows:
        metrics = candidate["metrics"]
        scores = {key: row["score"] for key, row in metrics.items()} if isinstance(metrics, dict) else {row["id"]: row["score"] for row in metrics}
        totals = candidate.get("totals", candidate)
        result[candidate_id] = {
            "assessed_subtotal": totals["assessed_subtotal"],
            "assessed_weight_percent": totals.get("assessed_weight_percent", totals.get("assessed_weight")),
            "total": totals["total"],
            "metrics": scores,
            "views": [view["score"] for view in sorted(candidate["views"], key=lambda row: row["quadrant"])],
        }
    return result


def build_validator():
    from jsonschema import Draft202012Validator, FormatChecker
    from referencing import Registry, Resource
    schema, legacy = load(SCHEMA), load(LEGACY_SCHEMA)
    Draft202012Validator.check_schema(schema)
    Draft202012Validator.check_schema(legacy)
    resource = Resource.from_contents(legacy)
    registry = Registry().with_resources([(LEGACY_SCHEMA.as_uri(), resource), (legacy["$id"], resource)])
    # A file retrieval base resolves the portable relative refs locally. The
    # stored schema and its task/version constraints remain unchanged on disk.
    local_schema = dict(schema, **{"$id": SCHEMA.as_uri()})
    return Draft202012Validator(local_schema, format_checker=FormatChecker(), registry=registry)


def semantic_check(data, check_files=True):
    require(not re.search(r"TODO|TBD|待填写|待评估|待填充|<实际>",
                          json.dumps(data, ensure_ascii=False)), "Unfilled placeholder")
    evidence = {row["id"]: row for row in data["evidence"]}
    require(len(evidence) == len(data["evidence"]) == 12, "Expected 12 unique capture IDs")
    expected = {(variant, q) for variant in VARIANTS for q in range(4)}
    actual = {(row["variant"], row["quadrant"]) for row in evidence.values()}
    require(actual == expected and len(actual) == len(evidence), "Capture coverage must be 3 variants x 4 Surface views")
    require(len({resolve_path(row["path"]) for row in evidence.values()}) == 12, "Capture paths must identify 12 distinct files")
    for row in evidence.values():
        require(row["context"] == "FORMAL_SURFACE" and row["roof_visible_in_gameplay"] is True
                and row["artificial_study"] is False, "Only actual formal Surface captures may be scored")
        require(row["camera_name"] == CAMERAS[row["quadrant"]], "Capture camera/quadrant mismatch: " + row["id"])

    def walk(value, location="document"):
        if isinstance(value, dict):
            for key, item in value.items():
                if key.endswith("evidence_ids"):
                    require(isinstance(item, list) and all(i in evidence for i in item), "Unknown evidence reference: " + location + "." + key)
                elif key.endswith("evidence_id"):
                    require(item in evidence, "Unknown evidence reference: " + location + "." + key)
                walk(item, location + "." + key)
        elif isinstance(value, list):
            for index, item in enumerate(value):
                walk(item, f"{location}[{index}]")
    walk(data)

    def refs_for(row, variant=None, q=None):
        rows = [evidence[i] for i in row["evidence_ids"]]
        require(rows and all(e["context"] == "FORMAL_SURFACE" for e in rows), "Wrong evidence context")
        if variant is not None:
            require(all(e["variant"] == variant for e in rows), "Wrong candidate evidence")
        if q is not None:
            require(all(e["quadrant"] == q for e in rows), "Wrong view evidence")

    def assessment(row, label):
        if row["status"] == "NOT_ASSESSED":
            require(row["score"] is None, label + ": NA must have null score")
        else:
            require(type(row["score"]) is int and 0 <= row["score"] <= 5, label + ": assessed score must be an integer 0..5")

    candidates = keyed(data["candidates"], "id", VARIANTS, "Candidates")
    metric_sets, view_sets = {}, {}
    for variant, candidate in candidates.items():
        metrics = keyed(candidate["metrics"], "id", WEIGHTS, variant + " metrics")
        metric_sets[variant] = metrics
        require({key: row["weight"] for key, row in metrics.items()} == WEIGHTS
                and sum(row["weight"] for row in metrics.values()) == 100, "Wrong rubric weights")
        assessed = []
        for key, metric in metrics.items():
            assessment(metric, variant + " " + key)
            refs_for(metric, variant)
            if metric["status"] == "ASSESSED":
                equal_number(metric["weighted"], round(metric["score"] / 5 * metric["weight"], 1), variant + " " + key + " weighted")
                assessed.append(metric)
            else:
                require(metric["weighted"] is None, "NA must have null weighted value")
        require(metrics["V5"]["status"] == "NOT_ASSESSED", "Missing full art context cannot be scored as V5")
        equal_number(candidate["assessed_weight_percent"], sum(row["weight"] for row in assessed), variant + " assessed weight")
        equal_number(candidate["assessed_subtotal"], round(sum(row["weighted"] for row in assessed), 1), variant + " subtotal (not normalized)")
        require(candidate["total"] is None and candidate["status"] == "PARTIAL", "Incomplete review must retain null full total and PARTIAL status")
        views = keyed(candidate["views"], "quadrant", range(4), variant + " four-view coverage")
        view_sets[variant] = views
        for q, view in views.items():
            require(view["camera_name"] == CAMERAS[q], "View camera/quadrant mismatch")
            assessment(view, variant + " Q" + str(q))
            refs_for(view, variant, q)

    common = [key for key in WEIGHTS if all(metric_sets[variant][key]["status"] == "ASSESSED" for variant in VARIANTS)]
    comparison = data["comparison"]
    equal_number(comparison["common_assessed_weight_percent"], sum(WEIGHTS[key] for key in common), "Common assessed weight")
    for field, right in [("a2_minus_a1", "A1"), ("a2_minus_current", "CURRENT")]:
        difference = round(sum(metric_sets["A2"][key]["weighted"] - metric_sets[right][key]["weighted"] for key in common), 1)
        equal_number(comparison[field], difference, field)
    west = [view_sets[variant][3] for variant in ("A2", "A1")]
    if all(view["status"] == "ASSESSED" for view in west):
        equal_number(comparison["west_delta_vs_a1"], west[0]["score"] - west[1]["score"], "WEST delta")
    else:
        require(comparison["west_delta_vs_a1"] is None, "Unassessed WEST delta must be null")
    require(comparison["full_total_delta"] is None, "Partial review cannot claim a full-total delta")
    gates = keyed(data["hard_gates"], "id", {f"G{i}" for i in range(1, 9)}, "Hard gates")
    for gate in gates.values():
        refs_for(gate)
    views_ready = all(
        view_sets["A2"][q]["status"] == view_sets["A1"][q]["status"] == "ASSESSED"
        and view_sets["A2"][q]["score"] >= 3
        and view_sets["A2"][q]["score"] >= view_sets["A1"][q]["score"] for q in range(4))
    target_failed = any(
        view_sets["A2"][q]["status"] == "ASSESSED" and (
            view_sets["A2"][q]["score"] < 3 or (
                view_sets["A1"][q]["status"] == "ASSESSED"
                and view_sets["A2"][q]["score"] < view_sets["A1"][q]["score"])) for q in range(4))
    target_status = "PASS" if views_ready else ("FAIL" if target_failed else "NOT_ASSESSED")
    target = data["target_gate"]
    refs_for(target, "A2")
    require({evidence[key]["quadrant"] for key in target["evidence_ids"]} == set(range(4)), "Target gate requires all four actual A2 views")
    require(target["status"] == target_status, "Target gate contradicts actual A2/A1 view scores")
    failed = target_failed or any(gate["status"] == "FAIL" for gate in gates.values())
    require(data["final_status"]["overall_visual_review"] == ("FAIL" if failed else "PARTIAL"), "Overall status hides a failed target/gate or missing assessment")
    ready = views_ready and not failed
    stage = "A2_PREVIEW_READY" if ready else "A2_MATERIAL_ONLY_LIMIT_REACHED"
    require(data["final_status"]["stage_result"] == stage, "Stage result contradicts gates or actual per-view A2/A1 scores")

    history = keyed(data["history"], "task_id", HISTORY, "Historical reports")
    for task, row in history.items():
        path = resolve_path(row["results_path"])
        require(path == HISTORY[task].resolve(), "Historical report points outside the immutable source")
        require(path.is_file() and digest(path) == row["results_sha256"], "Historical report hash mismatch: " + task)
        source = load(path)
        require(source["task_id"] == task, "Wrong historical task")
        scores = retained_scores(source)
        require(json.dumps(row["retained_scores"], sort_keys=True, allow_nan=False)
                == json.dumps(scores, sort_keys=True, allow_nan=False),
                "Historical retained scores differ from original JSON: " + task)
        require(set(row["candidate_aliases"]) == set(scores), "Historical aliases omit a candidate: " + task)

    checked_provenance = 0
    if check_files:
        for row in evidence.values():
            path = resolve_path(row["path"])
            require(path.is_file() and digest(path) == row["sha256"], "Missing evidence or SHA-256 mismatch: " + row["id"])
            with path.open("rb") as stream:
                header = stream.read(33)
            require(len(header) == 33 and header[:8] == b"\x89PNG\r\n\x1a\n" and header[8:16] == b"\x00\x00\x00\x0dIHDR", "Not a PNG: " + row["id"])
            require(struct.unpack(">II", header[16:24]) == (row["width"], row["height"]) == (1280, 720), "Native PNG dimension mismatch: " + row["id"])

        def provenance_files(value):
            nonlocal checked_provenance
            if isinstance(value, dict):
                pairs = [("path", "sha256")] if "path" in value and "sha256" in value else []
                pairs += [(key, key[:-5] + "_sha256") for key in value if key.endswith("_path") and key[:-5] + "_sha256" in value]
                for path_key, hash_key in pairs:
                    if not isinstance(value[path_key], str) or not isinstance(value[hash_key], str):
                        continue
                    path = resolve_path(value[path_key])
                    require(path.is_file() and digest(path) == value[hash_key], "Missing provenance file or SHA-256 mismatch: " + str(path))
                    checked_provenance += 1
                # Inspect descriptors in this report, never recursively inspect
                # the contents of a referenced manifest or its self-hash field.
                for item in value.values():
                    provenance_files(item)
            elif isinstance(value, list):
                for item in value:
                    provenance_files(item)
        provenance_files(data["provenance"])
        provenance_files(data["material_parameters"])
    return {"captures": 12, "contexts": 1, "variants": 3, "quadrants": 4,
            "historical_reports": len(history), "provenance_files": checked_provenance,
            "full_total": None, "review_status": data["final_status"]["overall_visual_review"],
            "target_gate": target_status, "stage_result": stage}


def validate_document(data, validator, check_files=True):
    errors = sorted(validator.iter_errors(data), key=lambda error: tuple(str(value) for value in error.absolute_path))
    if errors:
        error = errors[0]
        location = ".".join(str(value) for value in error.absolute_path) or "document"
        raise ValueError(f"Schema {location}: {error.message}")
    return semantic_check(data, check_files=check_files)


def self_test(data, validator):
    """Mutate the real report in memory; all original files stay untouched."""
    cases = []

    def case(label, mutate, files=False):
        changed = copy.deepcopy(data)
        mutate(changed)
        cases.append((label, changed, files))

    def candidate(document, variant):
        return next(row for row in document["candidates"] if row["id"] == variant)

    case("fabricated complete total", lambda row: candidate(row, "A2").update(total=100))
    case("NA replaced with zero", lambda row: next(metric for metric in candidate(row, "A2")["metrics"] if metric["id"] == "V5").update(score=0, weighted=0))
    case("missing native capture", lambda row: row["evidence"].pop())
    case("wrong camera mapping", lambda row: row["evidence"][0].update(camera_name=CAMERAS[(row["evidence"][0]["quadrant"] + 1) % 4]))
    case("duplicate rubric item", lambda row: candidate(row, "A2")["metrics"].__setitem__(1, copy.deepcopy(candidate(row, "A2")["metrics"][0])))
    case("incorrect weighted arithmetic", lambda row: next(metric for metric in candidate(row, "A2")["metrics"] if metric["status"] == "ASSESSED").update(weighted=0.1))
    case("incorrect comparison", lambda row: row["comparison"].update(a2_minus_a1=row["comparison"]["a2_minus_a1"] + 0.1))
    case("wrong candidate evidence", lambda row: candidate(row, "A2")["views"][0].update(evidence_ids=candidate(row, "A1")["views"][0]["evidence_ids"]))
    case("artificial study used for gameplay", lambda row: row["evidence"][0].update(context="INNER_MATERIAL_STUDY", artificial_study=True))
    case("hidden formal target scored", lambda row: row["evidence"][0].update(roof_visible_in_gameplay=False))
    case("historical score rewritten", lambda row: next(iter(row["history"][0]["retained_scores"].values())).update(assessed_subtotal=-1))
    case("historical hash tampering", lambda row: row["history"][0].update(results_sha256="0" * 64))
    case("actual capture hash tampering", lambda row: row["evidence"][0].update(sha256="0" * 64), True)
    case("actual parameters hash tampering", lambda row: row["material_parameters"].update(sha256="0" * 64), True)
    case("stage label contradicted", lambda row: row["final_status"].update(stage_result="A2_MATERIAL_ONLY_LIMIT_REACHED" if row["final_status"]["stage_result"] == "A2_PREVIEW_READY" else "A2_PREVIEW_READY"))
    case("gate failure hidden", lambda row: (row["hard_gates"][0].update(status="FAIL"), row["final_status"].update(overall_visual_review="PARTIAL")))
    case("target gate contradicted", lambda row: row["target_gate"].update(status="FAIL" if row["target_gate"]["status"] == "PASS" else "PASS"))

    def missing_view(document):
        view = candidate(document, "A2")["views"][3]
        view.update(status="NOT_ASSESSED", score=None)
        document["comparison"]["west_delta_vs_a1"] = None
        document["target_gate"]["status"] = "NOT_ASSESSED"
        document["final_status"]["overall_visual_review"] = "PARTIAL"
        document["final_status"]["stage_result"] = "A2_PREVIEW_READY"
    case("unknown WEST claimed ready", missing_view)

    def weak_west(document):
        view = next(row for row in candidate(document, "A2")["views"] if row["quadrant"] == 3)
        a1 = next(row for row in candidate(document, "A1")["views"] if row["quadrant"] == 3)
        view.update(status="ASSESSED", score=2)
        document["comparison"]["west_delta_vs_a1"] = 2 - a1["score"] if a1["status"] == "ASSESSED" else None
        document["target_gate"]["status"] = "FAIL"
        document["final_status"]["overall_visual_review"] = "FAIL"
        document["final_status"]["stage_result"] = "A2_PREVIEW_READY"
    case("weak WEST claimed ready", weak_west)

    def regression(document):
        for variant, score in (("A1", 5), ("A2", 4)):
            view = next(row for row in candidate(document, variant)["views"] if row["quadrant"] == 0)
            view.update(status="ASSESSED", score=score)
        document["target_gate"]["status"] = "FAIL"
        document["final_status"]["overall_visual_review"] = "FAIL"
        document["final_status"]["stage_result"] = "A2_PREVIEW_READY"
    case("A2 view regression claimed ready", regression)
    for label, changed, files in cases:
        try:
            validate_document(changed, validator, check_files=files)
        except (ValueError, OSError):
            continue
        raise ValueError("Negative self-test was accepted: " + label)
    return len(cases)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dependency-dir", type=Path, help="Existing isolated directory containing jsonschema")
    parser.add_argument("--self-test", action="store_true", help="Also reject deliberate in-memory corruptions")
    args = parser.parse_args()
    if args.dependency_dir:
        sys.path.insert(0, str(args.dependency_dir.resolve()))
    try:
        validator = build_validator()
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
