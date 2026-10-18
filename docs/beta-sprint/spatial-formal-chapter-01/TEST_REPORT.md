# Spatial Formal Chapter 01 — measured integration evidence

2026-10-19, branch `feat/spatial-formal-chapter-01`, base `7259917c83a9ba26b5d3b39fe14265dc8d4627f3`. Final commit identity is supplied by the independently generated `BUILD_IDENTITY.json`. This change registers the five verified spatial maps after L05; it does not redesign their puzzles or replace L06.

## Verification

Godot 4.7.2 executable SHA-256: `12310c74bdda7dcd43f28e971f33047dcecadd436b68169d61ce41009006df38`.

| Evidence | Actual result | Preserved directory |
| --- | --- | --- |
| Catalog and unchanged original five rows | 79 PASS | `E:/godot/qa/spatial-formal-shell/final-01/` |
| Existing catalog regression | 68 PASS | `E:/godot/qa/spatial-formal-shell/old-catalog-green/` |
| Actual ten-level Headless progression, pause, Reset, save, replay | 198 PASS; 11 real Goals | `E:/godot/qa/spatial-formal-shell/final-02/` |
| Separate process Cold Continue and final-map Goal | 22 PASS | `E:/godot/qa/spatial-formal-shell/final-02/` |
| Settings preview/cancel/persistence and approved default ink | 9 PASS | `E:/godot/qa/spatial-formal-shell/ink-green/` |
| Real D3D12 graphical progression, HUD/pause matrix | 348 PASS; 11 real Goals; 26 PNGs | `E:/godot/beta-sprint-builds/spatial_formal_graphical_20261019_03/` |
| Final three-size menu/default-HUD supplement | 44 PASS; 6 PNGs | `E:/godot/beta-sprint-builds/spatial_formal_graphical_menu_20261019_03/` |
| Wrapper lifecycle, paused Goal and actual landing completion | 124 PASS, shutdown warnings retained | `E:/godot/qa/spatial-formal-host/20261019_012400_bb8a0290/` |

Final integrated Shell and graphical processes exited 0, stderr empty, source drift empty. The isolated wrapper harness has six audio resource/playback shutdown warnings; its minimal raw-Host comparison does not reproduce them. This remains an unresolved P2 in that isolated lifecycle context, not a proven inherited defect or a clean-stderr result. The integrated Shell shutdowns did not reproduce it.

Real rendering used the Windows DisplayServer, D3D12 Forward+, NVIDIA RTX 5060 Ti, isolated profiles and an offscreen window. The 348-check raw report inherited a misleading `HEADLESS...` evidence-type string; its PROCESS.json, stdout renderer, Windows display receipt and actual PNGs establish graphical execution. The generator now labels future real-display runs correctly. Original evidence was not rewritten.

The ten-level tests earn every unlock through actual Goals, without editing saves or emitting synthetic completion. Legacy routes use Godot input events. Spatial routes invoke the authoritative Runtime action API and wait for the natural Presenter; they are not human keyboard comprehension tests. Menu actions use real controls/signals and keyboard focus traversal, not physical mouse testing. The final menu supplement uses a SHA-identical copy of the naturally earned graphical run03 save, and makes no new unlock claim. Its three sizes are 1920×1080, 1280×720 and 960×720.

## Fixes and failed attempts retained

- Pending Goal now waits for real Runtime idle, Presenter IDLE, camera and World Shift completion before Shell suspension. The original failing landing seam and passing rerun are preserved under `E:/godot/qa/spatial-formal-shell/landing-*`.
- Goal committed while paused remains pending until resume; Reset/unload retires it using existing scope/count/state and wrapper epoch.
- Paused/completed Shell hides the new chapter HUD and restores it on resume.
- Default contrast cancellation restores approved ink, rather than deleting the existing color override; `ink-red` contains the real failing assertion. Direct spatial entry establishes the same approved backdrop as entry after L05.
- Graphical run01 had an unreproduced first-route timing deviation. The separate L01 probe passed without production changes. Sequential route inputs now wait on actual motion completion; explicit in-flight tests remain separate. Run02's five failures were a test assertion that omitted the legacy `complete` terminal phase. Run03 passed after correcting that assertion. Failed logs remain intact; no old Input P1 was reopened.
- Run03's last-menu screenshots were superseded by the final menu supplement because a deferred initial focus replaced an immediate capture request. The supplement waits for actual focus. All raw images remain preserved.

The final color/backdrop-only adjustments received focused settings and graphical supplement verification; the complete ten-level route was not needlessly repeated for those visual changes. No complete state-graph or whole Foundation rerun is claimed.

## Remaining acceptance and protected scope

New formal Build Human QA: **NOT_RUN**. Previous experiment Human QA: user/organizer-reported all-five success, **PARTIAL** observation detail. The closure report remains at `E:/godot/beta-sprint-builds/spatial_closure04_00_20261019_01/REPORT.md`.

State Graph remains **PARTIAL** overall; scoped stable public-action closure has 908 states / 4300 changed edges, with coverage and exclusions in the Closure04 quality report. Floating-cube Art remains **PENDING_USER_REVIEW / PROPOSAL_ONLY**. Three external Art export differences remain **RECOVERY_PENDING**, with no restore performed. Existing Input P1 and Goal Reset P2 stay closed.

Runtime/Foundation, SaveStore, all map definitions, L01–L05 puzzle logic, L06 design, frozen Art, old QA packages/evidence/profiles, main and release tags are unchanged. New chapter is formally registered **GREYBOX playable**, not a claim of new approved final Art. Use the separately generated package identity and handoff receipt for exact source, archive and push verification.
