"""Read-only expanded A2 validation using the unchanged strict B2 contract.

The sibling B2 validator owns the scoring, history and readiness checks. This
wrapper only binds the new report directory and verifies its authorized revision
and immutable strict-B2 score snapshot. The original CLI remains available.
"""
from pathlib import Path
import importlib.util
import json
import sys

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
STRICT_B2 = HERE.parent / "option_a2_west_view"
STRICT_B2_RESULTS = STRICT_B2 / "SCORING_RESULTS.json"
STRICT_B2_SHA256 = "83819b3440c68b0a58f9cafb28efb3b57931f48b85d6ffb3f2424a608538ca1a"

spec = importlib.util.spec_from_file_location(
    "floating_cube_strict_b2_validator", STRICT_B2 / "validate_results.py")
if spec is None or spec.loader is None:
    raise ImportError("Cannot load the immutable strict B2 validator")
B2 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(B2)
B2.HERE = HERE
B2.SCHEMA = HERE / "SCORING_RESULTS.schema.json"
_strict_semantic_check = B2.semantic_check


def semantic_check(data, check_files=True):
    result = _strict_semantic_check(data, check_files=check_files)
    B2.require(data["review"].get("material_revision") == "A2_EXPANDED_01",
               "Expanded report requires material revision A2_EXPANDED_01")
    B2.require(data["review"].get("authority")
               == "EXPANDED_COARSE_TEXTURE_AND_MATERIAL_RESPONSE_PREVIEW_ONLY",
               "Expanded report requires its authorized preview-only scope")
    descriptor = data["provenance"].get("strict_b2")
    B2.require(isinstance(descriptor, dict), "Missing immutable strict-B2 provenance")
    B2.require(isinstance(descriptor.get("path"), str), "Missing strict-B2 results path")
    path = B2.resolve_path(descriptor["path"])
    B2.require(path == STRICT_B2_RESULTS.resolve(),
               "Strict-B2 provenance points outside the immutable source")
    B2.require(descriptor.get("sha256") == STRICT_B2_SHA256
               and path.is_file() and B2.digest(path) == STRICT_B2_SHA256,
               "Strict-B2 results hash differs from the immutable baseline")
    scores = B2.retained_scores(B2.load(path))
    B2.require(json.dumps(descriptor.get("retained_scores"), sort_keys=True, allow_nan=False)
               == json.dumps(scores, sort_keys=True, allow_nan=False),
               "Strict-B2 retained scores differ from the immutable source")
    return result


B2.semantic_check = semantic_check


if __name__ == "__main__":
    raise SystemExit(B2.main())
