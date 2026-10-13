"""Metadata tests only; no Runtime or search authority."""
import unittest
from prepare import select_representatives, bounded_projection


class ReferenceTests(unittest.TestCase):
    def test_selection_is_repeatable_and_records_predecessors(self):
        nodes = {"spawn": {"is_goal": False}}
        edges = []
        for camera in range(4):
            for offset in range(2):
                key = f"goal_{camera}_{offset}"
                edges.append({"from_key": "spawn", "to_key": key, "action": {"kind": 0, "face_axis": 2}})
                nodes[key] = {"is_goal": True, "depth": 1, "predecessor_edge": len(edges)-1,
                              "state": {"camera_quadrant": camera, "player": {"orientation": camera*2+offset}}}
        graph = {"initial_key": "spawn", "nodes": nodes, "edges": edges}
        selected = select_representatives(graph)
        self.assertEqual(selected, select_representatives(graph))
        self.assertEqual(len(selected), 8)
        self.assertEqual({r["camera"] for r in selected}, set(range(4)))
        self.assertEqual(len({r["orientation"] for r in selected}), 8)
        self.assertTrue(all(len(r["recipe"]) == 1 for r in selected))

    def test_sample_never_becomes_complete_denominator(self):
        result = bounded_projection(8, 16)
        self.assertEqual(result["overall"], "PARTIAL")
        self.assertEqual(result["post_goal_total_states"], "UNKNOWN")
        self.assertEqual(result["post_goal_total_edges"], "UNKNOWN")
        self.assertEqual(result["original_goal_terminal"], {"states": 908, "edges": 3916, "goals": 96})

    def test_corrupt_predecessor_cycle_is_rejected(self):
        graph = {"initial_key": "spawn", "nodes": {"g": {"is_goal": True, "depth": 1,
                 "predecessor_edge": 0, "state": {"camera_quadrant": 0, "player": {"orientation": 0}}}},
                 "edges": [{"from_key": "g", "to_key": "g", "action": {"kind": 0, "face_axis": 0}}]}
        with self.assertRaises(ValueError):
            select_representatives(graph)


if __name__ == "__main__":
    unittest.main()
