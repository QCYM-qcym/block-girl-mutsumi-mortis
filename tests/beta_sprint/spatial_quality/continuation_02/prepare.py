"""Read historical first-predecessor recipes only. Does not search/build/analyze graphs."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
OLD = ROOT / "docs/beta-sprint/spatial-puzzle-batch-01/quality/acceptance_01/evidence/full_graph_03"
OUT = ROOT / "docs/beta-sprint/spatial-puzzle-batch-01/quality/continuation_02"


def select_representatives(graph):
    goals = [(key, node) for key, node in graph["nodes"].items() if node["is_goal"]]
    goals.sort(key=lambda row: (row[1]["depth"], row[1]["state"]["player"]["orientation"], row[0]))
    selected, orientations = [], set()
    for camera in range(4):
        candidates = [(key, n) for key, n in goals if n["state"]["camera_quadrant"] == camera]
        taken = 0
        for key, node in candidates:
            orientation = node["state"]["player"]["orientation"]
            if orientation in orientations:
                continue
            recipe, seen, cursor = [], set(), key
            while cursor != graph["initial_key"]:
                if cursor in seen or len(recipe) >= 32:
                    raise ValueError("Historical predecessor cycle or prefix bound exceeded")
                seen.add(cursor)
                edge = graph["edges"][graph["nodes"][cursor]["predecessor_edge"]]
                if edge["to_key"] != cursor:
                    raise ValueError("Historical predecessor does not reach referenced node")
                recipe.append({"action": edge["action"], "expected_key": cursor})
                cursor = edge["from_key"]
            recipe.reverse()
            selected.append({"reference_goal_key": key, "camera": camera,
                             "orientation": orientation, "reference_depth": node["depth"], "recipe": recipe})
            orientations.add(orientation)
            taken += 1
            if taken == 2:
                break
        if taken != 2:
            raise ValueError("Need two bounded representatives per Camera with distinct Orientations")
    return selected


def bounded_projection(representatives, accepted_departures):
    return {"overall": "PARTIAL", "post_goal_total_states": "UNKNOWN", "post_goal_total_edges": "UNKNOWN",
            "sampled_goal_representatives": representatives, "sampled_accepted_departures": accepted_departures,
            "original_goal_terminal": {"states": 908, "edges": 3916, "goals": 96},
            "counting": "Historic Goal-terminal graph retained; sample is not added to graph/softlock counts"}


if __name__ == "__main__":
    raw = OLD / "explorer.json"
    graph = json.loads(raw.read_text(encoding="utf-8-sig"))["graph"]
    if not graph["complete"] or len(graph["nodes"]) != 908 or len(graph["edges"]) != 3916:
        raise ValueError("Wrong historical reference")
    payload = {"purpose": "Historical recipe reference only; no disk graph passed to formal algorithms",
               "original_explorer_sha256": hashlib.sha256(raw.read_bytes()).hexdigest(),
               "original_typed_trace_sha256": hashlib.sha256((OLD / "selected_trace.gdvar").read_bytes()).hexdigest(),
               "level_hash": graph["level_hash"], "representatives": select_representatives(graph)}
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "REFERENCE_RECIPES.json").write_bytes((json.dumps(payload, ensure_ascii=False, indent=2)+"\n").encode("utf-8"))
    print(json.dumps({"selected": len(payload["representatives"]),
                      "camera_orientation_depth": [(r["camera"],r["orientation"],r["reference_depth"]) for r in payload["representatives"]]}))
