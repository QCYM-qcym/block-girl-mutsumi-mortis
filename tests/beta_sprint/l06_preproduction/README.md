# L06 design validation fixture

This folder is a retained design spike, not a registered level or a second gameplay implementation. It loads `docs/beta-sprint/l06-preproduction/CANDIDATE.json` into the existing ContentLevelData and exercises unchanged ContentState, GridMovement, PerspectiveController and their existing native queries.

Run `./run.ps1 -RunId <new-name>` from PowerShell. It starts a hidden headless Godot process, records source hashes, PID/exit and raw logs, and verifies all tracked files outside the two L06 owner roots remain byte-identical. No editor import, scenes, Presenter, native InputEvent, player save or catalog writes occur.

`validate_design.gd` separates timed API route execution from a query-only cell/world/view topology audit. State assignments are confined to that audit; the four API routes use ordinary press/release, Shift, camera snap and original timed commits. Orientation does not gate this Content adapter; valid actual poses are checked in the timed routes. Goal means `ContentState.complete`, not a formal Shell completion event.

- `native_01`: PID47168, 485 checks, exit0; retained first-pass evidence.
- `native_02`: PID51476, 500 checks, exit0; final additional gate/view checks, same candidate map.

Both runs protect 3963 existing tracked files. Their HEAD is the baseline at execution, and source hashes identify the actual uncommitted candidate/fixture. Do not rewrite these process identities to later commit IDs or infer Human QA / 3D PASS.

Future production authoring should convert the candidate through current resource fields and rerun against the actual resource bytes, then perform the separately documented formal-input, graphical and human acceptance.
