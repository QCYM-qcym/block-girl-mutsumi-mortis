# Phase 0 — read-only audit

2026-10-09 · actual Integration HEAD `d472885d7375ef73fd36e4abc1847a9ba36cac44`, branch `integration/foundation-4-authoring`, CLEAN.

| Feature | Actual source / current behavior |
| --- | --- |
| Five-level entry | project.godot:14 → game/shell/game_shell.tscn; level_catalog.gd and batch_01/level_order.json; five adapter:p01 entries |
| RuntimeSession | foundation/runtime/runtime_session.gd:11–13,64–132; start/commit/feedback, native id/generation and completion |
| Kernel | foundation/runtime/kernel_port.gd:17–31 → foundation/rules/puzzle_rule_kernel.gd:21–32,103–115 |
| Result / rejection | foundation/rules/rule_records.gd:59–70; rule_types.gd MOVE_BLOCKED=2000; result has no events/Fall |
| Formal connectivity | foundation/rules/connectivity_resolver.gd:37–57; same layer/normal and exact adjacent position2; no distant/different-height Fall |
| Formal Safety | foundation/validation/safety_queries.gd:13–49,51–85; unknown profile UNPROVEN; endpoint SAFE does not prove flight |
| Solver / Replay | foundation/solver/action_generator.gd:18–30; state_explorer.gd:75–88; foundation/parity/trace_replayer.gd |
| Formal pose | foundation/contracts/contract_records.gd:5–10; location {layer,cube_id,face}, orientation integer cube24.v1 |
| Formal schema/key | contract_validation.gd:36–42,189–203; state_key.gd:25–36; no Camera. level_codec.gd strict old fields |
| P01 move / input | prototype/perspective/grid_movement.gd:37–77; game/player/grid_input.gd:12–40; many failures silent or cell==cell |
| P01 connection | prototype/perspective/connectivity.gd:23–31; perspective_link.gd requires equal elevation; p01_state.gd:43–48 adds world/gate support |
| P01 orientation | prototype/perspective/cube_orientation.gd:11–24; exact integer basis, roll/as_basis |
| P01 Camera | prototype/perspective/perspective_controller.gd:10–92; four views/busy/interpolation/drag |
| Actual 3D Cube | game/levels/mutsumi/batch_01/l01_3d/presenter.gd:33,70,182,208–219; actor PhysicalCubePose, full transform written each sync |
| 3D layers | batch_01/levels_3d/presenter.gd, batch_02/levels_3d/presenter.gd; factories in their presented_level.gd; l01_presented.gd:69–76 sync/reset |
| Pixel reference | game/player/cube_visual_presenter.gd and orientation_sprite_presenter.gd; no Fall authority |
| Foundation experiment | prototype/foundation/runtime/foundation_runtime.tscn/.gd; actual Session/Kernel composition; existing prototype Presenter ghost tween is not Fall character playback |
| Shell lifecycle | game/shell/game_shell.gd:113–207,291–298; level_adapter.gd:27–54 settle completion/pause/reset/unload |
| Audio | game/polish/p01_audio.gd:10–50, p01_polish.gd:13–34; snapshot diff cues, reset cleanup; native ui_cue_requested currently lacks consumer |
| Audio settings | default_bus_layout.tres: Master/SFX/Ambience; settings.gd:3–13 maps music→Ambience; save_store.gd stable five settings keys |
| UI runtime | game/shell/visual_01/tokens.gd, approved_shell_view.gd, stone_row.gd, hud.gd; approved controls and focus/apply/cancel |
| Art manifest | docs/beta-sprint/playable-art-vertical-01/ART_ASSET_BINDING_MANIFEST.json:18 assets/121 Source–Project bindings |
| Art frozen sources | E:/Study/方块娘项目/若叶睦/model/art/production/releases/batch_05; _runtime_polish/_01; production/art_3d/** |
| UI Art masters | E:/godot/若叶睦/方块少女-若叶睦/docs/art/BETA_UI_ART_DIRECTION_01/**; production/ui/beta_shell_01/ASSET_BINDING_MANIFEST.json |
| Actual formal Harness | tests/foundation/authoring_integration/test_suite.gd, run_module.ps1, case_manifest.json; gate/version/receipt/Real doubles checks; not a universal TestHarness class |
| Scoped native tests | tests/beta_sprint/three_d_02/run_integration.ps1; l04_p1_integration/run_focused.ps1; five_level_3d/run_case.ps1 |

Important lifecycle facts: Runtime feedback may be duplicated across acceptance/commit; committed also occurs on reset/load. Capture local token from transition_started, not public global transaction_id. P01 committed may immediately start another held roll; scene phase polling is insufficient for unique cues. Shell completion suspends its level during synchronous committed handling. All game-feel effects therefore need identity-scoped lifecycle and one visual writer.

Old P01 `tests/gameplay/test_p01_runtime.gd:23` asserts the old project main_scene. It is unsuitable as an unchanged whole-suite current Shell baseline gate. Do not change Main to appease it or change old formal receipt gates.

## Existing experiment and active Owners

Map worktree `E:/godot/worktrees/block-girl-map-spatial-design`, branch `prototype/perspective-fall-01`, HEAD `d5d63f37af8624f332ed4e9ab90b096cab891ff9`, CLEAN at audit. Parent `8a80fbb64eca7e6d7449654f4ace39a35e0f6d41` modifies L03 hint presentation; that parent is not authorized for this bootstrap. d5d63f3 itself adds only isolated experiments/map_spatial/perspective_fall_01 and docs/beta-sprint/perspective-fall-prototype-01. Baker/Camera projection audits do not prove legal Fall; the existing extension request is a useful read-only specification.

01,03,05,07,08,09 and projectless 10A/10B/11 already have distinct threads. No duplicate task is needed. 03's main-based suggestion is superseded by the actual shared Integration contract baseline; main13177bb is older. 10A and 07 explicitly await 00's contract/worktree. 08's missing-integrated-game-feel QA applies only to that case and does not block development.

## Prior five-level Human QA

Actual `E:/godot/beta-sprint-builds/five_level_3d_fps_supplement_20261009T123814Z/BETA_FIVE_LEVEL_3D_HUMAN_QA_01_COMPLETE.json` binds source942b6d4 / integrationd472885 / ZIP409cb38c4b43a1847ed0857e019265fb7ed26eec90fea4691760e2905a1c27c1. L04/L05 3D and same-build genuine Cold Continue PASS; experienced tester, qualifying prior L01–L03 save, no new empty-save full-five chain, no new-player L03 or all-resolution claim. P0/P1/P2/P3=0/0/3/1; entry FPS observations remain scoped short-sample evidence.

Preserve that report and original `five_level_3d_human_qa_20261009T113257Z`, fps supplement, immutable five-level package/ZIP and prior five roots/6146 protection entries. New bootstrap protection inventory captures current bytes, including real accepted save profiles; it does not relabel old gameplay checks as new ones.

Repository has no discovered AGENTS.md/SKILL.md. User's supplied AGENTS preference applies. App's saved project is the non-Git parent E:/godot/若叶睦; actual Git checkout and linked worktrees are beneath/alongside it. Use existing E:/godot/worktrees for verified Git fallback if app-native creation is unavailable. Never reset old branches or overwrite old worktrees.

Bootstrap itself modifies only coordination docs and verifies metadata/protection. It does not launch a new game-feel Build or claim new gameplay/HumanQA checks.

## Final bootstrap capture — 2026-10-10

BASELINE.json freshly verifies all 1324 listed current five-level package files and the original ZIP, 121 Art bindings (source, Integration destination and main destination), 77 UI source files, and captures 639 tracked production files, 3636 accepted five-level QA files and 2256 approved master files. No approved source, immutable QA package or accepted QA evidence drift was found.

The historical 6146-entry protection list includes four live-profile ABSENT sentinels outside the five immutable QA roots: two are still absent and two already exist at bootstrap. Their current bytes are captured separately; no profile is removed, recreated or restored to historical absence. The fresh old_qa group therefore contains 6144 existing files, including these two current live saves. Prior snapshots and reports are unchanged.

Concurrent pre-contract exploration was observed in block-girl-game-feel-quality-01 (older main baseline) and block-girl-game-feel-ui-extension-01 (d472 baseline). Their uncommitted output/raw evidence stays in place. 07 restored its own shared Shell exploration and reported migration to independent game/feel/ui modules. Neither exploratory tree is the new delivery baseline; 00 supplies new contract-based worktrees and disjoint roots, without resetting old work or claiming its exploratory tests as new formal integration PASS.

Read-only final review found and resolved the Edge presentation_identity cancellation seam and ACTION_FEEDBACK/FEEDBACK phase. Owner production/test allocations have no cross-owner overlap. Missing Fall implementation/codec dependencies remain only case_pending.
