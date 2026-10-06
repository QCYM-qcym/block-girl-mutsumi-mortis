# Game Content Batch 01 playtest

From the project root, run `./tests/playtest/run_batch_01.ps1` (PowerShell). The default Godot executable matches the existing project tooling; override `-Godot` for another installation. The wrapper first imports assets, then checks logical routes and finally runs real Windows graphical input. It needs a working graphical desktop/GPU and writes deterministic evidence paths under `tests/playtest/evidence/batch_01`; reruns replace the latest evidence.

`state_report.json` and `runtime_report.json` are the current acceptance results. `initial_harness_*` intentionally records the first run's superseded test assertion mistakes. These historical failures are explained in `docs/game-content/BATCH_01_REPORT.md` and are not used to decide current acceptance.

Runtime test does not teleport the character or set graph/world/view to solve a route. WASD, Q/E, Space, R and mouse drag go through the existing input adapter. State-only exhaustive reachability deliberately selects abstract cell/world/view states to test the actual graph policy; this is confined to the fixture and does not add a production Solver.

No Foundation tests, production assets or shared game configuration are changed. The checked-in regression evidence comes from the existing non-mutating P01 state/runtime, perspective logic and early prototype state/input scripts. The production visual harness that re-saves a shared tileset sample is outside this batch's execution scope.
