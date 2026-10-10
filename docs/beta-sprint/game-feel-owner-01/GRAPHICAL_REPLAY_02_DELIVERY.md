# PFALL_GRAPHICAL_COMPLETION_BRIDGE_02 — Owner01 delivery

Status: OWNER01_REPLAY_READY. CONTRACT_MISMATCH: NONE. Push: NOT_RUN.

## Scope and ancestry

Owner worktree: `E:/godot/worktrees/block-girl-game-feel-runtime`, branch `feat/pfall-runtime`.
Original PFALL core: `26387d6c34a869ad7035ee13ee77d8d5c24d796a`.
Consumed normal ancestry: `fcee3299020caf99e396bbb5659d6f630b202f0f` → `3c21f729f129f0e68d58ae970d449d13d4207992` → stable production Bridge `2752803e187073702d16e3e3c45730f71bffa679`.
These incoming commits were consumed with ff-only after checking path overlap and preserving the Owner WIP hashes. No reset/rebase/cherry-pick/squash/push.

The only production change in this delivery is `foundation/parity/trace_replayer.gd`. Shared Bridge, CoreLab, CubePresenter, 10A sampler, Runtime Facade, Kernel, Safety, Solver, codecs, old v1 tests, project configuration and shared contract are unchanged by this Owner diff.
Shared `GAME_FEEL_CONTRACT.md` SHA-256: `6224f8cd364f98da41822eabe7ba2973fa2db01d030373e7b3e94d69f35f23de`.

## Formal route

Unchanged entry: `TraceReplayer.replay(level,trace,{mode:1})`.
Only opt-in game-feel graphical runs create the formal Facade, then bind the fixed production `res://game/feel/graphical_completion_bridge.gd` to that same instance. STARTED captures native session_id, level_run_id, generation, transaction_id and is_global before COMMITTED clears pending authority. No logical finish or legacy prototype tween runs in this branch.

Only a matching live Bridge `motion_completed` sets completion_received. It must still satisfy exactly one authoritative commit/signal, generation, IDLE, full state, StateKey and trace semantics. Cancellation is a separate ERROR/INCOMPLETE path. Old identities, generations, runs and duplicate signals cannot complete a later step. Missing/invalid Bridge fails closed; the closed public options cannot replace it.

The four public options remain mode/max_steps/max_runtime_ms/step_timeout_ms. The frozen eight result fields remain status/trace_length/matched_steps/divergence_step/expected_statekey/actual_statekey/action/issues. New `get_step_evidence()` supplies recursively read-only deep copies of actual full state/key, identity, count and opaque Bridge evidence/snapshot; it has no gameplay mutation API.

## RED evidence and fixes

All raw runs are preserved in `.godot/game-feel-owner-01/b02_*` (ignored, append-only).

| Evidence | Checks | Failure evidence |
|---|---:|---|
| b02_unit_red01 | 15 | 6 behavior failures: original unconditional missing-Bridge gate |
| b02_scope_red01 | 23 | 2 failures: actual bound Bridge snapshot not exposed |
| b02_observe_red01 | 25 | 2 failures: missing public immutable evidence |
| b02_real_red01 | 8 | 2 observation failures; actual A/B mode1 already MATCH |
| b02_life_red01 | 46 | 0 assertion failures but 4 null signal emitters + 2 resumed freed coroutine errors; wrapper rejects this run |
| b02_life_green01 | incomplete | intermediate driver-owned signal locks the emitter during normal post-await free; normal timeout exit2; not PASS |
| b02_owner_solver_red01 | 24 | 2 obsolete Owner-only pending assertions after real Bridge becomes available |

Lifecycle fixes stay in Replay: validate an emitter before disconnecting its Signal; forward actual SceneTree frames through an independent retained RefCounted FrameRelay; resolve active exit waits while the driver is still alive; serial guards keep old continuations from ending a reused driver. The relay does not add a timer or alter frame timing. Cleanup frees the real Bridge and unloads its same Facade, avoiding a second reset after unload.
The Owner Solver test now consumes the actual formal mode1 result; absent dependency remains a dedicated Unit negative case. No v1 expectation was relaxed.

## Final verification

All final runs below have exit0, checks>0, failures=[], stderr0 and current source hashes. Godot `4.7.2.stable.steam.ed1daf0bf`; real graphical runs use D3D12 on NVIDIA GeForce RTX5060Ti.
Engine SHA-256: `12310c74bdda7dcd43f28e971f33047dcecadd436b68169d61ce41009006df38`.
Replay SHA-256: `7770168092f3e056b80b32dab93e9400c976a1fc461c7b2d67f61eb27c66682b`.

| Case | Evidence | Checks |
|---|---|---:|
| Bridge Unit | b02_final_unit | 25 |
| Actual A/B graphical | b02_final_real | 44 |
| Actual graphical lifecycle | b02_final_life | 48 |
| Owner contracts | b02_final_contracts | 35 |
| Owner rules/Safety | b02_final_rules | 59 |
| Owner Runtime | b02_final_runtime | 63 |
| Owner Solver/Replay | b02_owner_solver_green01 | 24 |
| Owner A/B/Exit maps | b02_final_maps | 30 |
| v1 logical parity | b02_final_legacy | 169 |
| v1 graphical parity | b02_legacy_graph01 | 77 |
| Real 3A logical trace integration | b02_final_trace | 53 |
| Total | final independent checks, excluding repeated RED/earlier GREEN | 627 |

Unit declares `UNIT_COMPLETION_SIGNAL_ADAPTER`; it uses real Facade/Kernel/Solver/Replay with synthetic completion signals and is not natural graphical proof. Actual A/B and lifecycle: doubles=[]. Legacy parity retains its original explicitly declared trace fixtures/adapters; real 3A integration consumes its formal Solver/Trace. The map regression reads pinned 09 data blobs at `82a8a7dc85205e9391551f24267f35f5abe53393`; real graphical consumes the current formal MapFactory through production code.

## Actual A/B graphical observations

Both maps use the real formal two-action Solver trace: MOVE(U_NEG) Fall then MOVE(U_POS) Exit Roll. Both actions are local, with native generation1 and token1 then2. STARTED/COMMITTED/completion orders are1/2/3 then4/5/6. Each actual step has commit_delta1, one commit signal, matching full expected state and key, settled Presenter and no host issues. World SURFACE0 and camera EAST1 are unchanged. Fall preserves orientation0; ordinary Roll ends at orientation12.

### Map A

Level content_hash: `f4a5e058ba97ec32edf24116b0a91d6e9196e613ed28fc93d3d71902d4357772`. Replay MATCH, matched_steps2.

Step 1: `LANDING_SETTLED`; 43 actual motion frames; final actor origin [-4.0, 1.0, 4.0]. Final visual pose equals the formal expected pose.

Native identity:
```json
{"generation": 1, "is_global": false, "level_run_id": "a521eea3435e92a60bbb520287ff85d3", "session_id": "efa77c62b4e4590af48f656046035b52", "transaction_id": 1}
```

Actual StateKey (equal to Solver expected):
```text
statekey.game_feel.v1:{"level_hash":"f4a5e058ba97ec32edf24116b0a91d6e9196e613ed28fc93d3d71902d4357772","rule_version":"foundation.rules.game_feel.v1","state":{"camera_quadrant":1,"celestial":{"slot_id":"a"},"group_orientations":{},"level_flags":{},"mechanism_states":{},"player":{"location":{"cube_id":"target","face":"TOP","layer":"SURFACE"},"orientation":0},"world_orientations":[0,0]}}
```

Step 2: `ROLL_RESTORED`; 14 actual motion frames; final actor origin [-3.0, 1.0, 4.0]. Final visual pose equals the formal expected pose.

Native identity:
```json
{"generation": 1, "is_global": false, "level_run_id": "a521eea3435e92a60bbb520287ff85d3", "session_id": "efa77c62b4e4590af48f656046035b52", "transaction_id": 2}
```

Actual StateKey (equal to Solver expected):
```text
statekey.game_feel.v1:{"level_hash":"f4a5e058ba97ec32edf24116b0a91d6e9196e613ed28fc93d3d71902d4357772","rule_version":"foundation.rules.game_feel.v1","state":{"camera_quadrant":1,"celestial":{"slot_id":"a"},"group_orientations":{},"level_flags":{},"mechanism_states":{},"player":{"location":{"cube_id":"exit","face":"TOP","layer":"SURFACE"},"orientation":12},"world_orientations":[0,0]}}
```

### Map B

Level content_hash: `ecbc83dc793ffd9dcbf1ed91f7b1aba647453ac3fd42e1e15dd9469f08dddaf4`. Replay MATCH, matched_steps2.

Step 1: `LANDING_SETTLED`; 51 actual motion frames; final actor origin [-4.0, 5.0, 4.0]. Final visual pose equals the formal expected pose.

Native identity:
```json
{"generation": 1, "is_global": false, "level_run_id": "bb4dec22c4c9deeaa001490d0f52dcb7", "session_id": "0c3abe9b3fed55e8bc68264a01c2b895", "transaction_id": 1}
```

Actual StateKey (equal to Solver expected):
```text
statekey.game_feel.v1:{"level_hash":"ecbc83dc793ffd9dcbf1ed91f7b1aba647453ac3fd42e1e15dd9469f08dddaf4","rule_version":"foundation.rules.game_feel.v1","state":{"camera_quadrant":1,"celestial":{"slot_id":"a"},"group_orientations":{},"level_flags":{},"mechanism_states":{},"player":{"location":{"cube_id":"target","face":"TOP","layer":"SURFACE"},"orientation":0},"world_orientations":[0,0]}}
```

Step 2: `ROLL_RESTORED`; 14 actual motion frames; final actor origin [-3.0, 5.0, 4.0]. Final visual pose equals the formal expected pose.

Native identity:
```json
{"generation": 1, "is_global": false, "level_run_id": "bb4dec22c4c9deeaa001490d0f52dcb7", "session_id": "0c3abe9b3fed55e8bc68264a01c2b895", "transaction_id": 2}
```

Actual StateKey (equal to Solver expected):
```text
statekey.game_feel.v1:{"level_hash":"ecbc83dc793ffd9dcbf1ed91f7b1aba647453ac3fd42e1e15dd9469f08dddaf4","rule_version":"foundation.rules.game_feel.v1","state":{"camera_quadrant":1,"celestial":{"slot_id":"a"},"group_orientations":{},"level_flags":{},"mechanism_states":{},"player":{"location":{"cube_id":"exit","face":"TOP","layer":"SURFACE"},"orientation":12},"world_orientations":[0,0]}}
```

Both frames and final camera/actor Basis/Origin, source/target pose, full native state and actual event order remain in `b02_final_real/results.json`. This is natural Bridge/CoreLab/CubePresenter/10A playback, with no transform write, seek, simulated finished event or fixed wait used to pass.

## Lifecycle and review

Real FALL and LANDING phases each cover Bridge free, CANCEL, UNLOAD, direct RESET, active driver free, and removal/re-add. Cancelled steps never count as completed; active driver free/removal returns INCOMPLETE while alive; fresh replay succeeds after every operation; removal/re-add cannot let an old continuation end the new run. Real timeout guards only bound explicit phase/result waits.

Independent read-only review: approved with no Critical/Important findings. Corrected two Owner document errors: result count eight and actual b02_* evidence location. The final source verification also checks raw process result, empty stderr, all recorded source hashes and unchanged shared contract; details are in ignored `b02_verification.json`.

Known outside-scope Owner00 P2: direct Facade.reset() may cancel motion with reason CANCEL before RESET; native KEY_R reset path uses RESET. Completion/cancellation exclusion is verified. This Owner does not amend Runtime or Bridge semantics. Camera/general World motion, Audio/UI/Art, 03 formal shared QA registration and broad new motion coverage are not included in this verified A/B route.

The four new scripts have their own ResourceUID sidecars generated through Godot ResourceUID. Exact Owner files/SHA-256 are in `GRAPHICAL_REPLAY_02_FILES_SHA256.json` (self excluded). This delivery uses a local Owner commit only; post-commit identity is recorded in ignored `b02_commit_receipt.json` and in the final handoff. No push.
