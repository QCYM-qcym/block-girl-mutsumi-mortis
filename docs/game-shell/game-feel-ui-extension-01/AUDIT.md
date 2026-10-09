# GAME_FEEL_UI_EXTENSION_01 — Owner07 audit

2026-10-10. Formal Owner branch `feat/game-feel-ui`, worktree `E:/godot/worktrees/block-girl-game-feel-ui`. Shared contract baseline `2938d6e534f5b596bb320ce79d72b69f5923f3cd`, original five-level baseline `d472885d7375ef73fd36e4abc1847a9ba36cac44`. Contract SHA256 `6224f8cd364f98da41822eabe7ba2973fa2db01d030373e7b3e94d69f35f23de`.

## Approved UI reuse

Read the approved `UI_TOKEN_EXPORT_SUMMARY.md`, `UI_SCREEN_MANIFEST.md` and `UI_INTEGRATION_CHECKLIST.md` in `E:/godot/若叶睦/方块少女-若叶睦/docs/art/BETA_UI_ART_DIRECTION_01/`. Audited `game/shell/game_shell.gd`, `settings.gd`, `save_store.gd`, `visual_01/approved_shell_view.gd`, `hud.gd`, `hint_strip.gd`, native five-level entry/Presenter and existing authored Hint resources. All remain read-only.

- Reuse tokens.gd: opaque stone face, ink text, portable Noto fonts, original icons and theme. Face/ink contrast is approximately12.24:1; no additional contrast palette is needed for these controls.
- Reuse native stone slider/check and row drawing/focus brackets. An Owner-local row subclass suppresses its focus/press tween when Reduced Motion is enabled; approved source is unchanged.
- Reuse original Settings keys and storage lifecycle: `master, music, sfx, fullscreen, muted`. Music maps to existing Ambience with original calibration. No new Settings save or schema expansion.
- Reuse existing Hint content through a host-supplied authored text port. Hint Strength chooses minimum/context/strong presentation; no solver, path, target coordinates or generated hints.
- Preserve Main Menu, Level Select, native HUD, Save/Continue, controls/assets and L01–L05. New lab assembly belongs to00.

`production/ui/beta_shell_01/tokens.json` SHA256 remains `5f342f44dca86436659ce39b6bca45c8a4ab9a9cc94b3f68d879fed3e32b12a5`. Final evidence records actual UI source and approved dependency hashes, with a source-drift guard.

## Scope and production changes

New executable module: `game/feel/ui/**`; tests: `tests/beta_sprint/game_feel_owner_07/**`; Owner docs: this directory. No shared Shell/Save/Presenter/Audio/Runtime/bus/InputMap/catalog/art modification.

The standalone lab UI emits settings_preview/apply/cancel and accessibility_changed. Apply stays open until host persistence acknowledgement; failure remains visible and permits retry/cancel. Cancel restores saved audio and presentation config. Tab follows reading order; arrows adjust sliders; mouse/Esc work. Scrolling keeps the focused slider label visible. Close restores prior visible focus or releases hidden focus.

Passive feedback consumes `game_feel.event.v1` deep snapshots without modifying them. It binds a session/run, rejects duplicate/stale/foreign delivery and clears only matching captured presentation_identity. Accepted SAFE Fall STARTED shows a small status band; matching COMMITTED/INTERRUPTED clears it. Ordinary EDGE, Busy, invalid/safety/unknown refusal produce no repeated road-block popup. Strong authored assistance may explain an explicit mechanism lock; successful normal movement clears that obsolete explanation. A new run clears prior hints; repeated same-run binding preserves deduplication.

## Evidence boundaries

Actual engine: `4.7.2.stable.steam.ed1daf0bf`. All executed Owner stages are hidden headless processes. Runner creates fresh evidence and a separate APPDATA/LOCALAPPDATA profile. Seed/restore are distinct OS processes sharing only that profile; OS.get_user_data_dir is checked. Existing saves and QA packages remain intact.

Cue fixtures declare `PRESENTATION_CONTRACT_UNIT`, `authoritative_runtime=false`. Settings uses an explicit Unit-only00 Save bridge and legacy bus sink: these prove actual old storage/bus behavior with requested values, not an undelivered11 AudioDirector or legal01 Fall. All doubles/pending cases are recorded. Parser/import failures and behavioral RED remain separate.

Fresh logical1920×1080/1280×720/960×720 checks disable project content scaling explicitly and measure actual Controls, focus, mouse/key actions, label/scroll containment and band bounds. They are **not** fresh integrated-build graphical, map occlusion, Pause-return or Human PASS. Existing Shell/save regressions are separate.

Pending:01 readiness/real events;11 actual Audio API/audio behavior;00 formal Presenter notification, lab host, Pause/return and immutable Build;08 visual/Human acceptance. See INTEGRATION_REQUEST.md and CASE_PENDING.json. Overall GAME_FEEL_UI_EXTENSION_READY remains NOT_READY until required integration checks run.

## Preserved exploration

Original `E:/godot/worktrees/block-girl-game-feel-ui-extension-01` exploration and raw RED/GREEN remain intact. Its direct Shell/HUD edits were snapshotted under .godot/game-feel-ui/shared-shell-exploration, then those five exclusively-owned files restored exactly before adopting the committed00 allocation. They are not part of this delivery. The formal Owner branch starts at the shared contract; old size evidence is never inherited.
