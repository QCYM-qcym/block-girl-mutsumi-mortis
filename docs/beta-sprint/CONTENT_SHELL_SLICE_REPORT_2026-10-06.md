# Beta Content + Shell Slice — 2026-10-06

**BETA_CONTENT_SHELL_SLICE_READY**

Request: [CONTENT_SHELL_SLICE_REQUEST.txt](CONTENT_SHELL_SLICE_REQUEST.txt). This milestone is the integrated Content → Shell → Save → QA → Daily Build product chain. Foundation Freeze and 3D visual integration remain separate milestones.

## Accepted commits and boundaries

| Item | Full SHA |
| --- | --- |
| Game Content delivery | `608a18a8c0627bb8a8a57f3cde554e723016dbb7` |
| Game Shell delivery | `7abf98d1e184fda5801c9271ebf02951ed6ecadd` |
| Content normal merge | `c4d67d0d6b256912f7993e5ccb14cce34be7cbf3` |
| Shell normal merge | `c084e30ac43bbb03f56c1dacaf288cad69412747` |
| Tested, packaged Integration code | `e22d0255e8a974c1f87445516b16ddcb71af465e` |

Branch: `integration/foundation-4-authoring`. Initial Foundation baseline: `9d23882638d2c491d68d58cbc360c3e60f56a894`. Owner ancestry is retained through ordinary merges; no rebase, squash or rewritten Owner commits. The inherited public README/assets arrive with the main-based Owner ancestry; the actual Owner deltas are confined to their approved roots.

06: 195 paths under Content/docs/playtest; 194 manifest entries (self-excluded) verified. 07: 41 paths under Shell/docs/tests plus the Main Scene line; 40 SHA manifest entries verified. Foundation production, common gameplay and original P-01 scene/script diff from the starting baseline are **NONE**.

00's production adaptation is only `game/shell/level_catalog.gd`: consume the existing Content `level_order.json`, retain stable IDs/scene/resources/order, and take display titles from the formal `.tres` metadata. Explicit test catalog injection remains supported. The existing adapter, Save system/format, input semantics, Reset and completion handlers are unchanged.

Main Scene is `res://game/shell/game_shell.tscn`. P-01 remains `res://game/levels/mutsumi/p01_another_world.tscn` for development/regression. Godot-generated documentation sidecars are ignored by exact documentation paths; no game asset is excluded by those additions.

## Slice acceptance

| Requirement | Result |
| --- | --- |
| L-01《另一个世界》 | FORMAL_PLAYABLE / SHELL_INTEGRATED |
| L-02《两岸之间》 | GREYBOX_PLAYABLE / SHELL_INTEGRATED |
| L-03《视线相接》 | GREYBOX_PLAYABLE / SHELL_INTEGRATED |
| Main Menu / Level Select | PASS; actual default three-level catalog, only L-01 initially selectable, correct locked/unlocked/completed text |
| Pause / Resume / Reset | PASS; a real roll freezes, resumes, then formal Reset retains the same level instance and allows actual completion |
| Save | PASS; ordinary completion events persist unlocked/completed/recent/settings using the existing store |
| L-01 → L-02 unlock | PASS; actual gameplay Goal, exactly one completion event and disk state checked |
| L-02 → L-03 unlock | PASS; actual gameplay Goal and Next Level checked |
| L-03 final completion | PASS; completed persists, Next disabled, no L-04 generated |
| Continue / cold restart | PASS; independent OS process reopens the same isolated save and enters L-02's authored spawn; settings applied to real audio buses |
| Human QA | READY / NOT_RUN; handoff below contains no routes |
| BETA_3D_MAIN_GAME_INTEGRATION | PENDING |
| Confirmed P0 / P1 | 0 / 0 within this scoped automated acceptance; not a claim of complete human QA coverage |

## Fresh evidence

Authoritative non-verbose run:

`E:/godot/worktrees/block-girl-foundation-4-integration/.godot/beta-sprint/content-shell/content_shell_20261006_211349_f5f66abe/run_report.json`

| Stage | Checks | PID | Exit | stderr |
| --- | ---: | ---: | ---: | --- |
| Import | unnumbered | 13592 | 0 | empty |
| Existing Save safety, including absent/corrupt/future save | 19 | 21244 | 0 | empty |
| Existing Shell fixture flow regression | 20 | 32460 | 0 | empty |
| Real three-level seed process | 62 | 21924 | 0 | empty |
| Independent Continue + remaining real levels | 43 | 31980 | 0 | empty |
| Original P-01 graphical regression | 167 | 31360 | 0 | empty |

All stdout is free of SCRIPT ERROR/ERROR/FAIL markers. The six user-requested cases are covered across the two real-catalog processes: first start, L-01 completion, L-02 completion, Continue, Reset and Level Select. Scene/graph/cell/progress are not directly set to fake these outcomes. Corrupt-save synthetic writes remain confined to the existing isolated Save safety test, not the real progression chain.

Seed requested the production Shell menu exit; Restore used a new process and the exact same isolated save. Both unloaded their active level before exiting. 41 executing source SHA-256 values and the engine executable hash were bound before the run and checked afterward. The run predates the code commit; its recorded working-tree source hashes match the committed code. Engine: Godot 4.7.2 stable Steam, Windows/Forward+/D3D12; executable SHA `12310c74bdda7dcd43f28e971f33047dcecadd436b68169d61ce41009006df38`.

Catalog TDD: `catalog_red_02` had six semantic failures with the old default P-01-only catalog; `catalog_green_01` passed 21 checks with the actual three-level default. `catalog_red_01` has null process exit/empty native logs and is retained as setup NOT_RUN, not behavioral RED.

Early seed runs `content_shell_20261006_211029_cf4c4787` and `content_shell_20261006_211200_17d62d6d` passed their assertions but produced four ObjectDB exit warnings. Verbose `content_shell_20261006_211217_6ebaf125` did not reproduce them. The fixture was then made to use the normal menu unload/quit and wait for queued releases; the authoritative non-verbose run is clean. No production lifecycle code was changed, and the exact early warning cause is not established. Keep it as a P2 observation if it reappears; do not label a production leak fixed.

Fresh-context read-only review found **Critical 0 / Important 0**. No review finding required further production changes.

## Daily Build and QA handoff

Build: `E:/godot/beta-sprint-builds/beta_slice_20261006_content_shell_01.zip`

Directory: `E:/godot/beta-sprint-builds/beta_slice_20261006_content_shell_01/`

Package type: **SOURCE_PLAYABLE_NOT_EXE**; Godot 4.7.2 required separately. Default F5/`play.ps1` entry is the Shell. The source package contains the three actual Content scenes, current runtime, progress store and UI. Prior daily packages remain intact. Windows executable export remains the existing P2 preset/templates dependency.

Snapshot code commit: `e22d0255e8a974c1f87445516b16ddcb71af465e`; source status at packaging: CLEAN. 816 source files verified after copied-project import; zero SHA mismatches. ZIP has 828 entries, no `.git`, `.godot` or evidence directories. Launcher parses successfully. Independent copied-project import, configured Main Scene, Foundation fixture and each of the three Content scenes all exit 0/PASS.

ZIP SHA-256: `1e58712cf25300468ae3afee2a3bb09dbe360df22c843622f5a941fb8d811aa4`.

Package evidence: `.godot/beta-sprint/beta_slice_20261006_content_shell_01/{build-manifest.json,archive.json,integrity-verification.json}`. Package manifest records the exact Main Scene, canonical catalog path/hash, level IDs/quality/entry paths, engine hash and source hashes.

**QA_HANDOFF_READY:** [08 blind-play handoff](QA_HANDOFF_CONTENT_SHELL_2026-10-06.md). It gives only the build, controls, names, confirmed P0/P1 and greybox status. No automated acceptance is presented as human playtesting.

This was the second observed batch on 2026-10-06 after the 19:41 pre-kickoff Foundation registration batch. No third integration window is started. Local commits and package verification belong to this batch. Push: NOT_RUN. Documentation closeout is a separate local commit above the packaged code; it does not change runtime bytes. Stop after this slice delivery; no L-04 work started.
