# Incremental formal Runtime DTO compatibility fix

Owner11 parent: 4afbd068fae74a826dae4db04c2c612af23fa861. Reviewed native Runtime candidate: 26387d6c34a869ad7035ee13ee77d8d5c24d796a; 00 reports it merged at63eb5b3385cf3eff9c97a0c5991378e8115575a9. No Runtime dependency was merged into this Audio branch, and no Runtime result was rewritten.

Only the Audio event-policy consumption boundary changed:

- Fall accepts the native Safety dictionary with status=SAFE, empty issues and an evidence_ref bound to level_hash/connection_id/profile_hash. Malformed, unsafe, unresolved or mismatched evidence stays silent. Historical synthetic SAFE-string fixtures remain compatible.
- Explicit EDGE accepts native Rules.rejected.next_state=null while retaining status=REJECTED, changed=false, reason_category=EDGE and absent target/transition. Null by itself never classifies EDGE. Legacy synthetic unchanged-state fixtures remain compatible.
- Explicit kind8 Fall retains intended_move_direction=null; ordinary MOVE and EDGE still require a resolved FaceAxis0..3. The consumer uses the authorized path/source_frame, never invents an input direction.
- Native connection_id/motion_profile_id are StringName; the consumer accepts String or StringName identifiers without coercing or mutating the event.

## RED / GREEN and actual inputs

`runtime_shapes_red_01` ran79 checks before changing production policy and had3 behavioral failures, exit1, stderr0, no source drift: native-shaped Fall STARTED, matching COMMITTED and null-next-state EDGE. Snapshot values are synthetic and explicitly PRESENTATION_CONTRACT_UNIT, not actual Safety evidence.

`runtime_shapes_green_01`:79 checks,0 failures,exit0,stderr0,no source drift. Added unsafe/unresolved/missing-reference/wrong-connection/wrong-profile negatives, eight-field-result immutability and preserved null-direction assertions.

`runtime_shapes_director_green_01`:48 existing actual local playback checks,0 failures,exit0,stderr0,no source drift. Existing music/SFX assets were not regenerated or changed.

`runtime_shapes_settings_green_01`:10 unchanged SaveStore/API assertions across distinct PID15548/10668,0 failures. No new persistence schema.

`native_shapes_green_02`:16 checks,0 failures,exit0,stderr0,no source drift,doubles=[]. The runner copied exact Git source bytes from candidate26387d6 into an isolated project BELOW Owner11's evidence root, plus the current Audio policy and test script. It generated immutable events through the real facade with default Kernel/Safety dependencies and author fixture data, never altered any Runtime record. Observed native EDGE's8 fields/null next_state, structured Safety evidence, StringName IDs, nullable explicit Fall direction, no impact on acceptance, matching native COMMITTED and duplicate handling.

The native test invokes `finish_transition(captured_token)` directly to exercise the DTO/native completion API. It is **not natural motion, Graphical character playback, host/Core audio integration, Solver parity or Human QA evidence**. Those cases remain pending their actual host integration. Source commit, copied execution file SHA values, actual HEAD/WIP/command/engine/PID/user directory are in process.json; the runner is also fingerprinted. No fake next_state or direction is supplied to00.

The first native-run harness used nonexistent `facade.unload()` for cleanup; its raw error/timeout and own-source drift are preserved at native_shapes_green_01 as a harness failure, never counted as behavioral RED or GREEN. Cleanup now uses the existing formal `interrupt("UNLOAD")` API.

## Preservation and delivery

Original source recipe/score/manifest/WAV/source/audio import sidecars and original evidence remain byte-identical to parent4afbd06. FILES_SHA256.json remains the ORIGINAL delivery inventory, not silently relabeled current. FILES_SHA256_DTO_FIX.json fingerprints the incremental updated/new files; its self-entry is excluded. verify_delivery.py now binds to current regression/native source evidence while preserving the original4388 shared-baseline files and checking every original Audio asset byte against parent.

Production diff: game/feel/audio/event_policy.gd only. Test/receipt/evidence changes are confined to tests/beta_sprint/game_feel_owner_11/** and docs/beta-sprint/game-feel-owner-11/**. AudioDirector, Audio buses, Shell, Save, Foundation, shared contracts, assets and other Owner worktrees remain unchanged. No global import, reset/rebase/squash/merge or push. Full shared hookup stays owned by00.
