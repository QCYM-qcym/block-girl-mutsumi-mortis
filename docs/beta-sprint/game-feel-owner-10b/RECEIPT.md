# EDGE_LEAN_RECOIL_READY — Owner-local sampling delivery

2026-10-10 · 10B · branch `feat/edge-recoil-animation`
Worktree: `E:/godot/worktrees/block-girl-game-feel-edge-animation`
Contract baseline: `2938d6e534f5b596bb320ce79d72b69f5923f3cd`
Contract SHA-256: `6224f8cd364f98da41822eabe7ba2973fa2db01d030373e7b3e94d69f35f23de`

Module: `game/feel/animation/edge_recoil/edge_lean.gd` + `recoil_motion.gd`, with `edge_event.gd`/`edge_admission.gd`.
Integration request: [INTEGRATION_REQUEST.md](INTEGRATION_REQUEST.md).
Code commit: `746ffb3531cb5c9f4c7ebf74f4cfa905f71183d8` (tested physical module/harness bytes bound in DELIVERY_BINDING.json).
Push: NOT_RUN.

## Actual final verification

| Case | Evidence | Actual result | Scope |
| --- | --- | --- | --- |
| DTO/geometry/lifecycle Unit | `evidence/final_unit_01/` | 7247 checks, 0 failures, exit 0, empty stderr, no source drift | Synthetic complete EDGE DTO; actual modules, mapper and cube24 math |
| Rendered Unit | `evidence/final_rendered_02/` | 100 checks, 0 failures, 43 PNGs, 338 natural samples, exit 0, empty stderr, no source drift | Native key events/mapper, approved Wakaba/Mortis, synthetic EDGE; D3D12 Forward+, RTX 5060 Ti |
| Existing InputMapper baseline | `evidence/final_mapper_01/` | 330 checks, 0 failures, exit 0, empty stderr | Unchanged formal input module |
| Existing RuntimeSession baseline | `evidence/final_runtime_01/` | 63 checks, exit 0, empty stderr | Existing test has explicit Kernel double; default real readiness check included; not a new formal EDGE/Fall case |
| Formal Runtime Graphical / Roll / Fall interruption | case_pending | 0 checks | Requires 01 facade + 00 Host; not claimed PASS |
| Human QA | NOT_RUN | 0 checks | Requires immutable integrated lab build |

Matrix covered locally: both worlds; four camera quadrants and all screen directions via native mapper; six support normals × 24 orientations × four FaceAxes; front support-edge stability and all logical corners above support plane; lean/blocked/rebound/rest; two-second natural held input plus 248 repeated DTO attempts; release/rearm, active-cycle throttle, opposite direction; full identity cancel, Clear/Reset during phases, pause/resume, known retired-run guard; duplicate event IDs/attempts and generation regression; source/sampling snapshot ownership; exactly-neutral endpoint; version/native-result poison cases; synchronous cancel/new launch and nested completion; one-shot cues.

Read-only rendered inspection: final w0_q0/q1/q2/q3 blocked, w1_q0 blocked and rest. All are genuine BLOCKED/12-degree or DONE/zero samples. The approved models remain inside their centered logical body; support-side compensation avoids visible floor penetration. Original rendered_01 had a named blocked capture still in LEAN; it remains historical, and rendered_02/final use actual phase waiting. The local scene is an explicit private one-writer demonstration, not the integrated Presenter.

## Evidence qualifications and preserved failures

Every run keeps original execution HEAD/dirty status and actual source SHA-256/PID/engine/profile. All processes use fresh isolated APPDATA/LOCALAPPDATA/USERPROFILE/HOME/XDG roots. Reported user_data_dir is beneath the fresh case directory. No old QA package, saves or original evidence was used as a destination. Profiles/render caches are excluded by this Owner's local .gitignore; stdout/stderr/process/report/capture evidence is preserved.

- `missing_modules_01`: initial absent-module gate, not behavioral RED.
- `behavioral_red_01`: test-harness empty-array access, terminated; stderr/source drift preserved, not behavioral RED.
- `behavioral_red_02`: genuine assertions plus test closure leak; excluded from clean RED.
- `behavioral_red_03`: clean 296 checks / 30 assertion failures / exit 1 / empty stderr against neutral stubs.
- `review_red_01`: 7233 / 3 genuine failures for nested duplicate completion and missing native result fields; `review_green_01`: 7233 / 0.
- `boundary_red_01`: 7244 / 7 failures for numeric type acceptance, standalone Recoil duplicate/clear restart and retired known run; `boundary_green_01`: 7244 / 0.
- `throttle_red_02`: 7246 / 2 failures for rapid release/repress restart and clock rewind; `throttle_green_01`: 7246 / 0.
- `import_01`: engine exit 0 but strict run FAILED due to existing ThorVG failure importing `production/ui/beta_shell_01/icons_source.svg`. Exact raw stderr retained. Imported shared UID/image sidecars were removed and the sole changed tracked SVG import sidecar restored to baseline; generated-file cleanup inventory retained. No broad import PASS is claimed.

Fresh-context review found and drove the reentrancy, DTO and standalone Recoil corrections. The final active-cycle throttle additionally has an observed RED/GREEN. Scope proof and immutable committed-source bindings are recorded separately in delivery binding JSON; original WIP records are not rewritten as clean-commit runs.
