# PFALL_FIRST_VERTICAL_SLICE — Owner09 exit route delta

Parent delivery: `54ea24cd50c4bd45b083dc26487ff2b7afd2a703`. Existing 30-check evidence is preserved verbatim; this is a new incremental delivery.

A exit center2=[-6,0,8]; B exit center2=[-6,8,8]. Both are Surface/TOP, identity cube/world orientation, directly adjacent to target in formal TOP Frame U_POS (axis 0). Goal moves from target/TOP to exit/TOP. Intended complete route: authorized Fall → land target/TOP with PRESERVE → ordinary MOVE U_POS → exit/TOP Goal. Source and Fall target positions, height signs, EAST-only candidate permission and landing policy are unchanged.

`map_factory.gd` emits the new third cube and its legal TOP face. The optional exit field lets the old two-cube ordinary-move positive control remain exactly that control. Map source remains unreachable under baseline rules, so adding the exit does not introduce a source-to-Goal shortcut.

## New evidence

- `exit_red_01`: 3 checks, 2 actual design failures because A/B Goal was still target/TOP; stderr empty. Not a parser/dependency failure.
- `exit_green_01`: 17 checks PASS, PID 9132; real Baker; formal resolved anchor/frame adjacency; baseline full-map Solver still unreachable; landing-spawn control Solver yields exactly MOVE U_POS; actual Runtime TraceReplayer MATCH for both maps.
- `exit_regression_01`: 30 checks PASS, PID 38836; refreshed full three-cube baked resources and original baseline validation.

All processes isolate user://, record actual execution HEAD/WIP and exact source snapshots, and use doubles=[]. No original evidence/profile was touched. Landing-spawn controls are separately authored valid levels; they do not assign Runtime state, fake Fall acceptance or prove in-flight behavior. All eleven Fall cases remain pending, zero checks. No Graphical/HumanQA upgrade.

Observed 01 WIP `foundation/game_feel/schema.gd` names source_face_id/source_edge/target_face_id/path_points2. No WIP module was copied or imported. Runtime schema versioning and complete path Safety remain Owner01; this delta does not fabricate path_points2 or claim a legal motion. New exit geometry must be included in full-path Safety once the actual extension is integrated.

00 should merge this delta normally atop the original map delivery; shared contract/host/Presenter/project settings and all L01–L06 content are unchanged. Exact file hashes are in EXIT_FILES_SHA256.json; actual new commit is supplied in the final receipt. Push NOT_RUN.
