# 07 Game Shell / Batch02 plan

Base: `b910167becee2194c0cfc724d8f0fe47578836a9`. Branch: `feat/beta-shell-batch-02`. Date: 2026-10-09.

## Scope and design

Append only playable rows delivered by 06 to the existing formal `game/levels/mutsumi/batch_01/level_order.json`. Preserve the original first three rows and their order exactly. Consume 06's committed Batch02 catalog and actual stable-ID handoff; the suggested L04/L05 IDs are not registration authority. Merge the precise playable Content dependency normally, preserving history. Never copy Content production code or cherry-pick the entire Owner branch.

Catalog, Shell completion and SaveStore already derive progression from catalog order. Retain SaveStore/version 1 and all flow semantics. Allow a minimal select-list capacity change only after real Control layout evidence demonstrates that additional rows hide entries/navigation. Preserve approved Row styling, tokens, assets and font roles. Do not repair either existing P2 art backlog.

Owner tests: `tests/beta_sprint/test_beta_catalog.gd`, `tests/beta_sprint/test_content_shell.gd`, `tests/beta_sprint/shell_batch_02/**`. Owner documentation: this directory. Builder and new 00 integration scripts remain owned by 00. No Runtime/Puzzle/Foundation, Save, Content design/solution/hint, shared project or Art source edits.

## Verification

1. Catalog contract: unchanged legacy prefix, metadata identity/title/quality, all registered scenes load, unique IDs, order/last/unknown lookup; appended rows must come from the playable Batch02 catalog.
2. Owner Unit fixtures: explicitly artificial signal levels exercise a five-entry menu, locked selection, completion-to-next unlock/save, Pause/Settings/Reset/return, keyboard focus and logical layout. Fixture results never count as real L04/L05 completion or Human acceptance.
3. Save compatibility: unchanged schema and legacy values, appended-ID persistence using named Unit fixtures, original actual default progress read-only/copy checks if present. All writes use fresh isolated `user://beta_sprint/` paths.
4. Real headless Runtime: seed an explicit legacy-unlocked progress fixture; enter the real L03 through formal Shell buttons and finish via native input actions. Verify the genuine completion signal and L03-to-playable-L04 unlock. New-level routes and L04-to-playable-L05 remain pending until 06 delivers their resources and approved input recipes. Continue must reload the recent real level at its original spawn, without assigning Runtime state.
5. Update the existing graphical three-route test to accept an unchanged three-level prefix and the actual successor of L03; keep its original three route functions. Do not run it until the graphical slot is released.

Every process launched here is `--headless`; 00 owns graphical focus. Import the frozen defs-only SVG with its historical initial-import P2 recorded honestly and restore the exact original `.import` bytes; do not edit the source or relax real test failure gates. Record source hashes, fresh raw evidence, actual checks and pending cases. Preserve the old Shell worktree and old 08 QA packages/evidence.

## Initial dependency state

06 worktree initially has no `docs/beta-sprint/content-batch-02/STABLE_LEVEL_IDS.json` or playable Batch02 catalog. Only those dependent Real cases are PENDING. Proceed with Owner Unit work and integration preparation; do not publish an unavailable L05 as a selectable level.
