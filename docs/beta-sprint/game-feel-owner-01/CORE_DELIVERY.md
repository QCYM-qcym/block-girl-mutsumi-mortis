# Perspective Fall Runtime and Edge feedback — Owner01 core delivery

Task: PFALL_RUNTIME_AND_EDGE_FEEDBACK_01. Branch: feat/pfall-runtime.
Execution baseline: 2938d6e534f5b596bb320ce79d72b69f5923f3cd.
Implementation and review are complete. This report is delivered in the code commit; its full SHA is recorded in the final receipt, avoiding a self-referential commit hash.

```text
PFALL_RUNTIME_AND_EDGE_FEEDBACK_READY
CONTRACT_MISMATCH: NONE
Scope: Runtime core / LOGICAL_SESSION parity
Push: NOT_RUN
CASE_DEPENDENCY_PENDING: GAME_FEEL_GRAPHICAL_COMPLETION_BRIDGE (00+10A)
```

The shared GAME_FEEL_CONTRACT is unchanged, SHA-256:
6224f8cd364f98da41822eabe7ba2973fa2db01d030373e7b3e94d69f35f23de.
No shared Presenter/host, old five-level content, Shell/Save, InputMap, project configuration, authoring/jobs, other Owner production, or shared QA registration is changed.

## Action and state contract

Legacy PuzzleActionKind retains exactly 0..7. The separate public GameFeelActionKind enum adds PERSPECTIVE_FALL=8 and SET_CAMERA_QUADRANT=9 only for explicitly opted-in levels. Existing native TransitionResult still has its frozen eight fields; GlobalKind is unchanged. MOVE first attempts the formal ordinary Roll and only resolves a declared Fall after proving ordinary-road absence. A blocked or unsafe road cannot be bypassed. Explicit Fall cannot jump over an existing ordinary road.

The single existing LevelCodec dispatches schema2 / foundation.game_feel.v1 / foundation.rules.game_feel.v1 / cube24.v1. Camera quadrant is a seventh core state field. The versioned canonical key is statekey.game_feel.v1; trace is solutiontrace.game_feel.v1. Old schema1, v1 codec, statekey.v1 goldens and trace semantics remain strict. No rendering transform, animation, lighting, UI or debug state enters a key.

Authored connection records are closed and bind source face/edge, target face, permitted Camera/world orientations, required flags, ordered doubled actor-center path, PRESERVE orientation, motion profile and duration. Unknown fields/versions, invalid references and ambiguous overlapping permission domains are rejected. Initial profiles support same-world upward TOP faces and fixed four-quadrant orthographic view. They reject a target ENTER effect rather than silently bypassing it. Ordinary MOVE+ENTER remains unchanged.

Full public entry and completion examples are in [RUNTIME_INTERFACE.md](RUNTIME_INTERFACE.md). Host entry is res://foundation/game_feel/runtime_facade.gd, consuming the single formal LevelCodec output. State/level getters return deep copies. get_presentation_scope returns the immutable actual session/run/generation scope.

Fall STARTED carries actual native token/generation/is_global and a distinct presentation identity. finish_transition accepts only that full active identity, routes solely by is_global, and permits one native commit. Busy locks conflicting input; Pause preserves the active token. Reset/cancel/unload/quit invalidate old authority. Duplicate, old-token, old-generation and foreign completion are ignored. Reentrant Reset cannot resurrect an accepted proposal or forward stale committed state.

Camera uses the equivalent native lifecycle bridge: neutral ACTION_FEEDBACK has no transition or presentation identity. A real changed Camera transition_started supplies its native token; get_pending_identity(token,generation,is_global) resolves the immutable full active scope. After natural Camera interpolation, the host calls finish_transition on that identity. Neutral feedback never authorizes completion.

## Edge feedback

MOVE_REJECTED_EDGE requires an actual absent ordinary road and no declared eligible Fall candidate, a valid source frame and explicit EDGE classification. The whole state/key and commit count remain unchanged. There is no target or Runtime completion token. Busy, Pause, native mechanism lock, invalid input/face, camera/world denial, Safety rejection, unclassified rejection and ERROR remain distinct neutral/classified feedback. Edge animation/audio may consume the copied presentation identity but cannot finish a Runtime transition.

## Safety, Solver and Replay evidence

Target actual height is not an eligibility test. The fixed rational orthographic projection proves a continuously descending path within one screen column. Every linear segment undergoes an exact rational swept-unit-cube intersection test against every same-world cube, including source and target. Touching is allowed; interior overlap is rejected. Bounded integer path coordinates keep rational cross-products within int64. The evidence reference binds the formal level/profile hashes, connection, before/after StateKeys and actual Safety query. Renderer observations never authorize movement.

Both authored A/B maps are read-only JSON inputs from Owner09 commit 82a8a7dc85205e9391551f24267f35f5abe53393; no 09 algorithm, production file, or test is copied/merged. Actual input identities:

| Input | Git blob | SHA-256 |
| --- | --- | --- |
| map_a.json | 6b17875a9832a421b366fb26cc9a469a95452340 | 5356268df2f2678fb0d3fe074bf23bd1ea5d5ddd13f7b5a6fa12f026a26c6c4a |
| map_b.json | 5ceaea7ba79bbfb6b84c727464ba124e4d3d0848 | 574a3014323bc3e16e47c5f52d2342f2662a7cab1df46883ff13f39a95605822 |

Real Baker/Codec/Kernel/Safety/Runtime/Explorer/Softlock/Replayer produce:

| Map | Target real height / projected descent | Canonical content_hash |
| --- | --- | --- |
| A | lower / descending | 27baf21da393fd7523cae7b011675e0847105504916e57d13e82fc784798260e |
| B | higher / descending | 387af7532d23cf2f9dd9108325d9d48836c89d7b6829e1e28302c94962fcde1c |

Both complete routes are MOVE U_NEG → one local Fall commit → MOVE U_POS → ordinary Roll commit → Exit Goal. Landing target alone is not Goal. Final state is exit/TOP, orientation12, Camera EAST1 and world orientations[0,0]. Reset restores exact spawn. Complete graphs contain 12 states each, with no softlocks. Directed Fall never implies a reverse traversal; real trace semantics and repeated LOGICAL_SESSION replay agree on full StateKeys. Tests reject wrong Camera, unsupported target, absent author connection, cross-world movement, obstructions and an illegal source-edge path. All 24 source cube orientations are preserved by Fall. Ordinary roads retain priority; world/flag permissions select the actual connection before lexical ordering.

The coordinate/view proof and formal StateKey are delivered. Natural Fall graphical parity, visual pixel sampling and human comprehension are not claimed here. GRAPHICAL replay for opted-in levels fails closed with the precise 00+10A dependency and zero matched steps. The old generic linear tween is not used to claim Fall playback. Art/UI/Audio are not core blockers.

## Fresh final verification

Engine: Godot 4.7.2.stable.steam.ed1daf0bf; executable SHA-256:
12310c74bdda7dcd43f28e971f33047dcecadd436b68169d61ce41009006df38.
Owner-local runs isolate environment/user profiles and record actual HEAD/dirty source SHA, engine/PID/arguments, raw stdout/stderr and result artifacts. The final validation confirmed no source drift in every recorded .gd file. Evidence is preserved locally under .godot/game-feel-owner-01 and excluded from Git.

| Owner suite / evidence name | Checks |
| --- | ---: |
| contracts / core_contracts | 35 |
| permission and whole-path Safety / core_rules | 59 |
| real Runtime facade / core_runtime | 63 |
| real Solver/Softlock/logical Replay / core_solver_replay | 24 |
| real authored A/B+Exit routes / core_maps | 30 |
| **Owner subtotal** | **211** |

All Owner suites: failures=[], doubles=[], exit0, stderr empty. Completion evidence is labelled LOGICAL_SESSION; it does not imitate natural graphics.

| Legacy suite / evidence name | Checks |
| --- | ---: |
| Data contracts / core_reg_1 | 733 |
| StateKey / core_reg_2 | 546 |
| LevelCodec / core_reg_3 | 75 |
| Baker / core_reg_4 | 65 |
| Safety / core_reg_5 | 199 |
| StaticValidator / core_reg_6 | 171 |
| Kernel Safety integration / core_reg_7 | 161 |
| Rule Kernel / core_reg_8 | 532 |
| Busy lifecycle / core_reg_9 | 113 |
| InputMapper / core_reg_10 | 330 |
| RuntimeSession / core_reg_11 | 63 |
| ActionGenerator / core_reg_12 | 9 |
| StateExplorer / core_reg_13 | 103 |
| SolutionTrace / core_reg_14 | 50 |
| real trace logical parity / core_reg_15 | 53 |
| legacy Perspective logic / core_reg_16 | 66 |
| legacy Runtime graphical / core_graphic | 116 |
| legacy Perspective graphical bugfix / core_pconn | 172 |
| **Legacy subtotal** | **3557** |
| **Actual total** | **3768** |

All final legacy runs exited0, stderr empty, no assertion failures. Legacy RuntimeSession and Runtime graphical retain their explicitly declared existing test doubles. They are regression evidence, not new Fall authority. Graphical runs used real Windows D3D12/Forward+ SceneTree/Presenter lifecycles. Existing tests and durations were not relaxed.

Actual consolidated evidence: .godot/game-feel-owner-01/core_verification.json, SHA-256 07a0228d254472e046a4d852989f2290d5e2f10ed85738f5fa1b1a0d2d880270. The total excludes behavioral RED, import/setup failures and pending cases.

## TDD and review

Preserved genuine behavioral RED: data15/12 failures; rules17/17; rt_red2 12/7; sol_red2 22/8; connection selection52/1; runtime review53/3; rejection classification56/1; target ENTER54/1; Camera neutral completion60/1. Each has a separate subsequent GREEN artifact. Parser/import failures are retained separately and never counted as behavior RED or success.

Independent final read-only review found no Critical/Important findings after reviewing scope binding, Camera native completion, target ENTER refusal, reentrancy, exact source hashes and A/B complete routes. Review findings were reproduced before minimal fixes. No second Kernel, decoder, BFS, Orientation or Spatial algorithm was introduced.

## Files and delivery binding

FILES_SHA256.json lists every delivered file's byte SHA-256, excluding only its own recursive hash. The post-commit local receipt binds that manifest, the real full commit SHA and unchanged final verification sources. The changed production files are the four foundation/game_feel modules plus formal Types/Data/Records/Key, Codec, Kernel/KernelPort/Session, Safety, ActionGenerator/Trace/Replayer dispatch. Owner-local tests, UID sidecars and these docs are the remaining files.

Raw logs, screenshots, copied immutable map input data, canonical evidence artifacts, engine caches and generated external import metadata are not committed. No push or history integration is performed. Shared formal QA registration and natural graphical completion remain with 03 and 00+10A respectively.
