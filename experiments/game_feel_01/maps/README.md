# Owner 09 — independent Fall author data

Base: `2938d6e534f5b596bb320ce79d72b69f5923f3cd`; shared `game_feel.event.v1` contract. Owner 09 grants no traversal permission.

| Map | Source center2 | Target center2 | Real height delta | Candidate view |
|---|---|---|---|---|
| A | [0,4,0] | [-8,0,8] | -2 | EAST (1) |
| B | [0,4,0] | [-8,8,8] | +2 | EAST (1) |

Both anchors are Surface/TOP with identity world orientation and initial player orientation 0. TOP is walkable; other faces are not. Goal is exit/TOP, one U_POS ordinary Roll beyond target/TOP. Exit center2 is [-6,0,8] in A and [-6,8,8] in B. Geometry TOP frame.u=(1,0,0), so exit lies exactly target.position2+2*frame.u. No Shift mapping joins the two worlds. Runtime determines legal traversal, landing and Goal.

`map_factory.gd` exposes `read_spec(letter)`, `authoring(spec)`, `bake(spec)`. It calls the existing real Baker. Its output remains strict `foundation.contract.v1`; connection proposals stay outside that schema. Baked resources and their formal hashes are in the latest evidence directory, generated through real Codec. Connection JSON is design intent, not a `game_feel_event`, accepted Fall result, authorized path or Solver edge.

Each connection names exact source/target/world, EAST-only candidate view, U_NEG departure, explicit player activation and PRESERVE orientation. The source actor-center is [0,6,0] in points2 and target actor-centers are [-8,2,8] / [-8,10,8]. 01 must define and prove the full path, including leaving the source edge before descending. A straight downward line from source center can intersect its support. B rises in world Y but can descend in the fixed EAST projection. Neither geometry nor endpoint SAFE is sufficient to authorize motion.

Original coordinate/authoring source: selected files only from `d5d63f37af8624f332ed4e9ab90b096cab891ff9`; no old branch merge, L03 change or old renderer copied. This worktree does not contain the prior experiment's graphical evidence; that is historical design context only. Current delivery has no new Graphical PASS.

Run from repository root:

```powershell
python tests/beta_sprint/game_feel_owner_09/run.py fresh_case_name
python tests/beta_sprint/game_feel_owner_09/run.py fresh_exit_case validate_exit.gd
```

The runner requires a fresh name, isolates APPDATA/LOCALAPPDATA, verifies actual `OS.get_user_data_dir`, and retains source snapshots and raw evidence. Ordinary positive-control Solver/Replay proves wiring, not Fall capability. A/B remain unsolvable under baseline rules until 01's opt-in extension is integrated by 00.
