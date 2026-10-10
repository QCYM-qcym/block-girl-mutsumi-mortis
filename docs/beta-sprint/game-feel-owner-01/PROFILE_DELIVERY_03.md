# PFALL curve Runtime Owner01 delivery

Status: PFALL_CURVE_RUNTIME_DELIVERY_READY; CONTRACT_MISMATCH: NONE.
Task: PFALL_TARGET_PLATFORM_AND_TRAJECTORY_FIX_01. Approved supplemental registration ec826753435458abc41cc365e4b57dba27767fbd. Base c60912b494baccb942e3f37f7c28d0c0c035dcc8. This is the Runtime/permission/proof/codecs delivery, not integrated new-profile graphical or Human QA acceptance.

The frozen GAME_FEEL_CONTRACT.md remains byte-identical, SHA-256 6224f8cd364f98da41822eabe7ba2973fa2db01d030373e7b3e94d69f35f23de. Old schema1/schema2 meanings and canonical key/text/hash were compared against pre-change evidence and remain identical.

## Implementation and consumer interfaces

Single formal LevelCodec supports explicit schema3/foundation.game_feel.v2/foundation.rules.game_feel.v2; no migration, fallback or second decoder. Closed pfall.departure_cubic.v1 trajectory has exactly two departure_points2 and four descent_control_points2 (Vector3i, doubled world units, bounded ±1000000). Arrays preserve geometric order. Actor follows the line over parameter[0,1/4], then the cubic over[1/4,1], with exact C1 join and downward target-normal approach.

10A public pure API: res://foundation/game_feel/trajectory_profile.gd, sample_actor_center(trajectory:Dictionary,parameter:float)->{ok,position,issues}; position is ordinary world units. Reject unknown/malformed payloads and nonfinite/out-of-range parameters. Sampling does not grant permission or Safety.

Only new Fall events are game_feel.event.v2/schema_version2 and carry recursively immutable authorized_trajectory. STARTED, native COMMITTED and captured ANIMATION_INTERRUPTED preserve version and native five-field identity. Roll/Edge/neutral feedback remain event.v1. Native eight-field result and local transaction semantics are unchanged. No new animation state enters PuzzleState/StateKey. Solver/Trace/Replayer implementations are reused.

Safety performs exact bounded dyadic line/cubic unit-cube sweep against every same-world entity, including source, target, visible blue_reference and exit. It proves SAFE only by complete separation, UNSAFE only by exact curve-interior collision witness, UNPROVEN on unresolved hull/depth/budget. Scale2^36, depth12, max100000 tests; root integer filtering precedes scaling; validated bounds keep all sums/products within int64. No sampled/epsilon SAFE. New-rule-only directed quarter-turn half-space separation allows the genuine landing→exit Roll past the rear blue entity; old conservative refusal remains unchanged.

## Authority and A/B results

Inputs are Owner-local synthetic author DATA matching the approved four-platform geometry, processed by actual Baker/Validator/Kernel/Runtime/Safety/Explorer/Softlock/Trace/Replayer. No 09 factory or other Owner algorithm is copied. This is not 09 production author integration evidence.

Source[0,4,0], target[-6,y,8], visible nonwalkable blue[-8,y,8], distinct exit[-4,y,8]; A y0, B y8. Camera EAST1; Fall U_NEG2 preserves orientation/World; target is not Goal; U_POS0 Roll reaches exit.

- Physically lower A and physically higher B both APPLIED with full continuous SAFE proof and one local authoritative commit.
- Wrong Camera, missing connection, invalid/cross-world/blocked target, bad endpoints/C1/contact and projected reversal reject without a next state.
- Endpoints/chord-clear interior-curve collision rejects; nondyadic tangency/depth and root/hull budgets return UNPROVEN. Near ±1000000 endpoints still detect penetration; out-of-range control reports1105; far int32 entity never overflows scaled arithmetic.
- Repeated/Busy input cannot queue landing. Reset/cancel/unload/quit/reload preserves captured v2 interruption identity and invalidates old completion. Duplicate completion cannot commit again. Pause/edge legacy behavior passes existing Runtime tests; Edge changes no authoritative StateKey.
- Actual complete Solver finds exactly Fall→Roll (2 actions), zero irreversible softlocks, correct directed graph and no premature Goal. Actual Kernel trace semantics validate. Two fresh logical Session Replay runs agree on full final StateKey.

A level_hash: 5bb12863ca4780529430733cc4be6d176d660e4ca10dcdda98d4612845266999.
B level_hash: 6f20611cb15220e13799fc99858be487c08193b26775e4fe2d2e00cef27d8cbb.
Full before/landing/final keys and event/trace evidence: .godot/game-feel-owner-01/c03_runtime_green01/results.json.

## RED/GREEN and evidence

All evidence is append-only under .godot/game-feel-owner-01/ with source SHA, exact arguments, PID/process exit, raw stdout/stderr and result records. It is ignored and excluded from commit.

| Task | RED | Final GREEN |
| --- | --- | --- |
| Closed schema/sampler | c03_profile_red01:6 checks/3 behavioral failures, exit1, stderr0 | c03_profile_green01:62/62, exit0, stderr0 |
| Safety/new-rule Roll | c03_safety_red01:9 checks/3 behavioral failures, exit1, stderr0 | c03_safety_review01:47/47, exit0, stderr0 |
| Runtime/event/chain | c03_runtime_red02:96 checks/14 behavioral failures, exit1, stderr0 | c03_runtime_green01:96/96, exit0, stderr0 |

Earlier compile/runtime-test errors are retained separately as c03_safety_green01 and c03_runtime_red01; neither counts as behavioral RED or GREEN. Both exited via normal SceneTree guards. PID28988 was absent when the latest scoped termination authorization arrived; no process was force-terminated in this resumed segment.

New tests205/205. Legacy/applicable regression4125/4125 across28 suites. Final total4330/4330, all exit0, failures empty, stderr empty. Count uses one final accepted run per suite; it does not add reruns or RED assertions. Current unchanged FOUNDATION-2 graphical suite is116 checks; the historical83 count is not substituted. Runtime logical old parity169, graphical77, old native graphical replay44 and lifecycle48 all pass. These remain old-profile evidence.

New curve Real chain doubles=[]; completion authority is LOGICAL_SESSION. Existing legacy unit suites intentionally retain their pre-existing test doubles (e.g. RuntimeSession, controlled graph/clock unit tests and replay completion adapter). No blanket double-free claim is made for legacy Unit suites.

| Regression evidence name | Checks | Mode |
| --- | ---: | --- |
| c03_reg_owner_contracts | 35 | HEADLESS |
| c03_reg_owner_rules | 59 | HEADLESS |
| c03_reg_owner_runtime | 63 | HEADLESS |
| c03_reg_owner_solver_replay | 24 | HEADLESS |
| c03_reg_owner_maps | 30 | HEADLESS |
| c03_reg_owner_graphical_replay_unit | 25 | HEADLESS |
| c03_reg_graphical_replay_real | 44 | GRAPHICAL |
| c03_reg_graphical_replay_lifecycle | 48 | GRAPHICAL |
| c03_reg_contracts | 733 | HEADLESS |
| c03_reg_key | 546 | HEADLESS |
| c03_reg_codec | 75 | HEADLESS |
| c03_reg_baker | 65 | HEADLESS |
| c03_reg_static | 171 | HEADLESS |
| c03_reg_safety | 199 | HEADLESS |
| c03_reg_kernel_safety | 161 | HEADLESS |
| c03_reg_kernel | 532 | HEADLESS |
| c03_reg_busy | 113 | HEADLESS |
| c03_reg_mapper | 330 | HEADLESS |
| c03_reg_session | 63 | HEADLESS |
| c03_reg_action_gen | 9 | HEADLESS |
| c03_reg_explorer | 103 | HEADLESS |
| c03_reg_trace | 50 | HEADLESS |
| c03_reg_softlock | 115 | HEADLESS |
| c03_reg_softlock_real | 117 | HEADLESS |
| c03_reg_parity_logical | 169 | HEADLESS |
| c03_reg_real3a | 53 | HEADLESS |
| c03_reg_parity_graphical | 77 | GRAPHICAL |
| c03_reg_runtime_graphical | 116 | GRAPHICAL |

## Review, ownership and remaining dependent acceptance

One fresh read-only final review found no Critical/Important issue; its Minor proof-boundary gap was filled and verified (PROFILE_REVIEW_03.md). Only Owner01 allowlisted production/test/docs paths changed. No shared Spec, map09, UI07, Audio11, animation10A/10B, Presenter/Host00, Quality03, project config or legacy test was edited. No Solver/Replay algorithm was duplicated or changed in this increment.

CASE_DEPENDENCY_PENDING: NEW_PROFILE_GRAPHICAL_00_10A. 00/10A must consume the exact new pure sampler and event.v2 authorized_trajectory in the single production Presenter/Host writer, then verify actual new-profile per-frame movement, natural completion/contact/landing and pixel/3D StateKey parity with09 production author data. Runtime-only logical completion is not a visual PASS, and no ghost/linear fallback/forced endpoint is used.

Integrated yellow-target/trajectory acceptance: NOT_ISSUED here. Existing historical timer-before-first-Tween-update watchpoint remains unchanged; no old timer/assertion was relaxed.

Local commit only after this verified delivery; exact file hashes in PROFILE_FILES_SHA256_03.json (excluding that manifest itself). Push: NOT_RUN. Merge/rebase/reset/squash: NOT_RUN. Working tree expected CLEAN after local commit; final Git closeout checks are recorded in the ignored evidence ledger.
