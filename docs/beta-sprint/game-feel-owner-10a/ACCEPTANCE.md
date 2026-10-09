# PFALL_ANIMATION_LANDING_01 — Owner-local delivery

2026-10-10. Branch feat/pfall-animation; contract baseline 2938d6e534f5b596bb320ce79d72b69f5923f3cd. Push NOT_RUN.

Continuation: [structured Owner01 Safety DTO compatibility](CONTINUATION_01.md) is implemented and freshly verified (Unit 2011/0, private graphical 253/0). The original evidence counts and delivery receipt below refer to the original delivery and are retained unchanged. Formal integrated cases remain pending for the actual Runtime facade/00 host.

Implemented: independent FallMotion, LandingMotion, FallVisualState and configurable MotionParameters. No shared Presenter, real Actor, Runtime, Camera, Gameplay event bus, Save, InputMap or project.godot edits. Modules only return visual samples. Anticipation/departure/main fall/committed impact/damped rebound/settle are continuous and deterministic; every cleared or settled offset is exact neutral. Experimental defaults are not formal art acceptance.

| Case | Owner-local result | Formal integrated result |
| --- | --- | --- |
| A, real target lower | Unit PASS, private continuous 3D playback | case_pending, checks=0 |
| B, real target higher but screen lower | Unit PASS, private continuous 3D playback | case_pending, checks=0 |
| Landing | Unit PASS, only COMMITTED; null position | case_pending, checks=0 |
| Orientation | 24 synthetic authoritative Basis endpoints MATCH exactly | Runtime parity case_pending, checks=0 |
| World/state | Immutable DTO/player snapshots unchanged; no Runtime write | StateKey parity case_pending, checks=0 |
| Reset/cancel/exit/late cancel/new launch | Unit PASS; private native Reset/exit input PASS | Real generation lifecycle case_pending, checks=0 |
| WASD/Shift/Q/E/mouse/Pause | Delivered private native inputs and frozen clock PASS | Runtime BUSY/pause case_pending, checks=0 |
| Reduced Motion | Unit PASS, continuous path without lean/squash/rock | Integrated setting case_pending, checks=0 |
| Safety/Solver/Replay/Audio/VFX/HumanQA | NOT_RUN | dependency pending |

All executed cases are **PRESENTATION_CONTRACT_UNIT, authoritative_runtime=false**, using declared 01 DTO / Safety attestation / native commit doubles; the preview also uses a private input gate double. The actual approved Wakaba asset is copied read-only into an isolated test project, with actual source SHA and engine/PID/display/renderer/input recorded. Profile names are fresh UUIDs; actual user_data_dir is checked. Original WIP HEAD/dirty state is retained; final source binding is recorded separately, never substituted for the original run identity.

Fresh evidence: [Unit 2003 checks/0 failures](evidence/unit_final_01/process.json), [Graphical Unit 251 checks/0 failures](evidence/graphical_final_01/process.json), [actual frame trace and screenshot inventory](evidence/graphical_final_01/report.json). Both original/copied source drift lists are empty. Raw earlier failures remain append-only, including the separately labelled parser failure. [RED raw stderr](evidence/red_01/stderr.log).

Actual rendered examples: [A mid-fall](evidence/graphical_final_01/map_A_mid_fall.png), [B mid-fall](evidence/graphical_final_01/map_B_mid_fall.png), [B impact](evidence/graphical_final_01/map_B_landing_impact.png), [B settled](evidence/graphical_final_01/map_B_settled.png). These screenshots are private sampler evidence, not proof of a legal gameplay Fall.

Reproduce: `./tests/beta_sprint/game_feel_owner_10a/run.ps1 -Case <fresh>`; graphical: add `-Mode preview`. Runner uses a separately named/copied project and imports approved resources there; it leaves original source/worktree saves untouched.

Read-only code review found no Critical/Important defects. Integration notes: [00 wiring request](INTEGRATION_REQUEST.md) specifies event-ID deduplication, the exact captured completion identity, cue schedule crossings, world-frame composition and initial same-normal TOP->TOP landing support. Shared registration belongs to 03; actual public wiring belongs to 00.
