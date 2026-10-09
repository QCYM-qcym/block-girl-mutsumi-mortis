# Owner matrix — game-feel bootstrap

All seven code Owners start from the same committed GAME_FEEL_CONTRACT baseline. Exact initial SHA and observed branch/clean state are recorded after creation in WORKTREES.json. Machine-readable allowlists and shared reservations: OWNER_MATRIX.json.

| Owner | Branch | Worktree | Exclusive production scope |
| --- | --- | --- | --- |
| 01 | feat/pfall-runtime | E:/godot/worktrees/block-girl-game-feel-runtime | foundation/game_feel/**; foundation/contracts/foundation_types.gd; foundation/contracts/contract_records.gd; foundation/contracts/contract_validation.gd; foundation/contracts/state_key.gd; foundation/rules/**; foundation/validation/safety_queries.gd; foundation/runtime/runtime_session.gd; foundation/runtime/kernel_port.gd; foundation/runtime/input_mapper.gd; foundation/solver/**; foundation/parity/trace_replayer.gd; foundation/level/level_codec.gd |
| 09 | feat/pfall-map | E:/godot/worktrees/block-girl-game-feel-map | experiments/game_feel_01/maps/** |
| 10A | feat/pfall-animation | E:/godot/worktrees/block-girl-game-feel-fall-animation | game/feel/animation/fall_landing/** |
| 10B | feat/edge-recoil-animation | E:/godot/worktrees/block-girl-game-feel-edge-animation | game/feel/animation/edge_recoil/** |
| 11 | feat/game-feel-audio | E:/godot/worktrees/block-girl-game-feel-audio | game/feel/audio/**; production/experimental/game_feel_01/audio/** |
| 07 | feat/game-feel-ui | E:/godot/worktrees/block-girl-game-feel-ui | game/feel/ui/**; production/experimental/game_feel_01/ui/** |
| 03 | test/game-feel-quality | E:/godot/worktrees/block-girl-game-feel-quality | tests/beta_sprint/game_feel/** |

05 retains its existing independent Art environment and creates only an additive experimental release. 08 remains WAITING_FOR_INTEGRATED_BUILD; no Human QA PASS is claimed here. 06/L06 stays independent.

00 owns the unified Cube Presenter, lab host, contract and all shared wiring. Existing project.godot, InputMap/Autoload, Main, Shell/Save/HUD, legacy polish/audio and accepted L01–L05 presenter chain are reserved. They are not edited in this bootstrap. Current owner allocations are disjoint; existing pre-contract 03/07 exploratory trees remain preserved and are not delivery baselines.
