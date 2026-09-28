# Updated D_SAVED registration R6

Owner: `7cbdae3d0d04ed6b2dc8fc4d05eb6e49472b2664`.
Previous D_SAVED: `a8ac1d4e05d9b9ff4f5b0df0a400677e413d88e0`.
Integration pre-merge HEAD/common ancestor: `37c6e9b1cb97bf0725543d506141dc8a6a03d4db`.
Fast-forward merge preserved Owner history and bytes.

## Scope and evidence

Owner inventory: `E:/godot/worktrees/block-girl-foundation-runtime-saved-closure/.godot/d2-closure-update/delivery-inventory.json`.
Exactly three D2 files changed: execution_project.gd, execution_dependencies.json, test_saved_snapshot.gd. Commit SHA-256 equals inventory and final Unit/Real tested source copies. No D3 duplicate change, D4, Integration, Spec or Plan change. Existing protocol ef1b0b8 and Host Source 96043a0 are ancestors and retain their bytes.
Owner raw final regressions verified: D1 1101, D2 Unit165, D2 Real194; failures=[], exit0, import/run stderr empty. D2 doubles=[]. D1 retains its declared in-memory BoundaryControl status provider, not an algorithm double.

Execution closure uses explicit canonical res:// whitelists for .gd and .tscn, Script/PackedScene external resources and corresponding UID bindings. It rejects missing/ambiguous UID, unsupported resources, embedded resources, absolute/escaping paths and scene cycles. This is the approved minimal Host closure, not general arbitrary Resource support. All four Host files are sealed from formal Git source. No whole-repository copying or active-source fallback. SnapshotRef/input.ready shapes remain unchanged; snapshot_capture.gd bytes remain unchanged, including ready-last publication.

## Final run verification and handoff

Full real paths, SnapshotRef and both ArtifactRefs are committed in `FOUNDATION_4_D_SAVED_EXECUTION_CLOSURE_HANDOFF.json` beside this record. Values come from Owner `d2_closure_real_final_20260928/4D-2/run/d2-delivery.json`, not from Integration regression runs.

The final run is dd0dcb8c-68e5-472c-bcf0-b9386b066a04, snapshot75ee6338-2a42-4e7d-b266-cddba6f4b505. Compared with the original preflight evidence: source fingerprint matches, canonical bytes are identical (4171 bytes), formal content_hash matches. Both identities are new; execution_digest binds updated closure. Old4286c860 run remains PREFLIGHT_ONLY.

Independently checked input.ready/stage_result/canonical lengths and SHA-256, formal typed wire envelope and identity/canonical ArtifactRef binding, all122 execution module hashes. Owner's formal ToolWire/loader tests validate BAKE storage, same-run identities and Codec. No cross-run ArtifactRef or JSON sidecar fallback. Cross-run negative transplants actual identical canonical bytes and foreign stage/message into another run and is rejected.

Controlled Host log contains D_HOST_READY and expected snapshot/hash. Owner test removes active closure sources before importing/launching the sealed execution project, then restores its disposable test sources. This proves CONTROLLED_HOST_ENTRY_CLOSURE_READY only; it issues no Tween action. Final LOCAL/GLOBAL Tween remain NOT_RUN.

D3 must consume exactly the committed handoff run; no recapture or rebake of another fixture. Owner final Graphical run is authorized by neither this receipt nor this execution.

## Integration checks

See appended actual results. Commands use tests/foundation/authoring_integration/run_module.ps1 with the listed Module/Case/Mode and unique EvidenceName. Boundary uses the existing external verify_boundaries.ps1 with RunName r6_boundary_20260928_01; its intentional FAIL aggregation injection is expected, not a waived failure.

D3 Graphical dependency classification used the Harness Get-Missing function only: missing=[]. Approved formal Stage Result, updated execution closure and Host Source are present. D3 dependency: READY_FOR_FINAL_GRAPHICAL_OWNER_RUN. No final Graphical case was executed.

Formal slots remain BASE, I_HARNESS, A_SCHEMA, A_BAKE, D_PROTOCOL, C_QUALITY, D_SAVED. Only D_SAVED commit and three changed file hashes are updated. D_PROTOCOL remains ef1b0b8a3a16b04037eb5ac49faaa55e296b31e8; D3_HOST_SOURCE remains PHASE_EVIDENCE_ONLY. No D_HOST/D_JOBS/D_FULL registration.

D_HOST: NOT_DELIVERED
I1: NOT_STARTED
Push: NOT_RUN

| Case | EvidenceName | Checks | Result |
| --- | --- | --- | --- |
| Integration/I0/Unit | r6_i0_20260928_01 | 15/15 | PASS / exit0 |
| 4D/4D-1/Unit | r6_d1_20260928_01 | 1101/1101 | PASS / exit0 |
| 4D/4D-2/Unit | r6_d2unit_20260928_01 | 165/165 | PASS / exit0 |
| 4D/4D-2/Real | r6_d2real_20260928_01 | 194/194 | PASS / exit0 |

D1/D2 import/run stderr empty. Boundary: 28/28 PASS; exit0.

Recorded at: 2026-09-29T00:03:56.870523+08:00
