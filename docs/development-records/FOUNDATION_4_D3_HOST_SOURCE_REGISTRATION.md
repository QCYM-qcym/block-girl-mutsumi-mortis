# D3 Host Source registration

D3_HOST_SOURCE: PHASE_EVIDENCE_ONLY

- Owner commit: `96043a0b4c0b1ec8c095eb7fcf62247132eed466`
- Purpose: EXECUTION_CLOSURE_SOURCE_HANDOFF
- Previous Integration receipt and common ancestor: `6dc1605bf54b90f39059e13d24c80360486b945e`
- Integration method: verified `git merge --ff-only`; no conflict or Owner byte change.
- Formal D_PROTOCOL: `ef1b0b8a3a16b04037eb5ac49faaa55e296b31e8`
- dependency_receipts and all formal slots: UNCHANGED. No D3_HOST_SOURCE or D_HOST slot added.

## Evidence verification

Owner inventory: `.godot/d3-source-staging/static-verification.json` in `E:/godot/worktrees/block-girl-foundation-authoring-runtime`.
Owner GREEN evidence: `.godot/foundation-authoring-tests/4d_4d3_source_staging_green_20260928_delivery/4D-3` in that worktree.
Owner RED evidence: `.godot/foundation-authoring-tests/4d_d3_source_staging_red_20260927/4D-3`.

Independently checked commit blobs, inventory SHA-256, tested project bytes and integrated checkout bytes: 9/9 equal. Commit delta is exactly the nine D3 files below. No D4, Integration, Spec or Plan changes in Owner commit.
Raw RED results: 50 checks / 3 failures. Raw GREEN results: 88 checks / zero failures / exit 0 / doubles=[] / stderr 0 bytes. Import process exit 0 and stderr 0 bytes. This registration audits existing source-staging evidence; it does not rerun or claim final D3 acceptance.
Original rejection/error checks remain, with formal wire fixtures replacing JSON fixtures. All original assertion labels and the three RED assertion labels are retained; source inspection confirms failure/clearing behavior rather than assertion removal.

## Source boundaries

Formal stage_result loader: PASS within source-staging scope. `load_run` reads input.ready, verifies the sealed source/execution closure, discovers same-run published WorkerMessage ArtifactRefs, decodes ToolWire, checks stage identity/length/hash/input policy, reads canonical ArtifactRef bytes, uses LevelCodec.decode and verifies canonical re-encoding and SourceMap content hash. No custom JSON, coordination-handoff path, direct absolute canonical or historical-success fallback. Failed load clears the candidate.

SESSION_WRITE_EXPOSURE: RESOLVED at the host capability boundary. RuntimeSession and live completion authority are closure captures. The fixed read-only capability dictionary returns detached observations and input-frame values; there is no finish/arbitrary dispatcher capability. Presenter is an internal child; Godot engine child reflection can still access display objects, and the test explicitly verifies that mutating the reflected display frame cannot alter authoritative input mapping. This is not a sandbox against arbitrary engine reflection. RuntimeSession transition_started -> PrototypePresenter.animate_transition -> actual Tween.finished -> finish_local/finish_global remains in source. External on_visual_finished notifications do not authorize commits.

whitebox_entry accepts only --run-dir, validates formal same-run evidence and requires the materialized execution project and D3 closure. Scene resource references resolve in the committed source closure. Source availability is not evidence that the updated sealed execution closure has been delivered.

## Deferred gates

- Final LOCAL Tween: NOT_RUN
- Final GLOBAL Tween: NOT_RUN
- Controlled execution_project startup: NOT_RUN
- D_HOST: NOT_DELIVERED
- Remaining dependency: UPDATED_D_SAVED_EXECUTION_CLOSURE
- Updated D_SAVED closure: READY_TO_CONSUME_SOURCE
- I1: NOT_STARTED
- Push: NOT_RUN

No 4D-3 PASS, D_HOST delivery, final Tween pass or I1 readiness is asserted.

## Registered source inventory

| File | SHA-256 |
| --- | --- |
| `tests/foundation/authoring_acceptance/test_whitebox_host.gd` | `866cf7139e5f6d0ca3f47fe14b92b6427ea6942a9cbc9574b811c41334d36dc3` |
| `tests/foundation/authoring_acceptance/test_whitebox_host.gd.uid` | `cffd8c991279a4f8f3403657ea05889218352634f1c8f4a9e348736798db3531` |
| `tools/foundation/authoring_acceptance/canonical_loader.gd` | `0cb4bca6ebe4ab668eb2408d9da0a8188acf36c2ead7c12939d293f139329292` |
| `tools/foundation/authoring_acceptance/canonical_loader.gd.uid` | `15fdf7d8bc3f6bad3526b56bc72c845d99b790628262cdc449c72c8007f079de` |
| `tools/foundation/authoring_acceptance/whitebox_host.gd` | `035127c5c04fa4e025697298cd626fcdea8a1d385d9449d66bf723042e61f640` |
| `tools/foundation/authoring_acceptance/whitebox_host.gd.uid` | `16083ad0d645538a3eef28ac623c5c808017d1c4eb5b5421d8002f5f5e828016` |
| `tools/foundation/authoring_acceptance/whitebox_entry.gd` | `31595622857092912f0a538def07f89f3594609d797b31798fcc58d58998ed86` |
| `tools/foundation/authoring_acceptance/whitebox_entry.gd.uid` | `378e10336d57ba8b9c8a6241a4850690613e154c2055f9eb58a2526968c65182` |
| `tools/foundation/authoring_acceptance/whitebox_host.tscn` | `d4de30b814ddd7f6e63f66d55c95307cb56898b4679d7dafa2e6aed4ce3424ed` |

Recorded at: 2026-09-28T23:38:21.820906+08:00
