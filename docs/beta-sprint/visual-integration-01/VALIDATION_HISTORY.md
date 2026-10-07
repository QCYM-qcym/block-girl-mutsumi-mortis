# Visual integration validation history

Earlier failed evidence is preserved under the actual Integration project's .godot/beta-sprint/visual-integration directory. Failed runs are not delivery receipts.

| Evidence | Actual PID / result | Finding |
| --- | --- | --- |
| ui_red01 | 14556, exit 1, stderr empty, 5 checks / 2 expected failures | Previous Shell View and palette were not approved UI. |
| ui_entry01 | import 20220, entry 33292, exit 0 / stderr empty, 5 PASS | New approved entry and old action contracts passed initial headless gate. |
| ui_graph01 | seed 26560, exit 1, 1144 checks / 24 failures | Harness mixed logical and physical coordinates while Shell inherited 1152×648 canvas stretch. Physical font sizing was also below the approved native minimum at 960×720. No real L01 entry was claimed. |
| coords01 | 28360, exit 0 / stderr empty | Actual final scale was 1.666667 at 1920×1080, 1.111111 at 1280×720, 0.833333 at 960×720. Existing L01 already used native coordinates. |
| native_red01 | 24188, exit 1 / stderr empty, 7 checks / 2 expected failures | Native Window mode and logical/physical dimensions failed; previous five entry checks passed. |
| ui_graph02 | import 4184, entry 14408, seed 27492 | Entry 7 PASS. Seed 2583 checks / 3 numeric comparison failures, exit 1 with errors; real L01 Goal, unlock and Next were reached. Native 40-pixel button heights transformed to 39.99997 through floating-point rectangle subtraction. A detached L01 still received Window resize callbacks during replacement scene initialization. Visual inspection additionally found action-label spill, transient right-arrow textures, and zero-height slider tracks. This run is RED, not acceptance. |

Fix scope: 00 sets Shell CONTENT_SCALE_MODE_DISABLED after the existing Window size/minimum assignments and guards detached L01 presentation layout before inherited layout. UI Owner fixes only new visual-layer resource lifetime, row text layout, slider styling, HUD callback bounds and world-label reset. Harness Owner corrects coordinate transforms and 0.01-pixel comparison tolerance, waits for natural status animation, and adds owning-button text containment and actual Inner→Main world reset assertions. Save, completion, unlock, input and puzzle algorithms remain frozen.

Final acceptance evidence and exact tested commit are recorded separately after fresh strict runs. P01 parity remains observational gameplay state parity, not Foundation statekey.v1.

Packaging byte preservation: upstream NotoSansSC OFL line 21 contains a trailing space. The official license remains byte-for-byte intact; a license-only whitespace attribute documents that imported-file exception. The test runner's extra blank EOF is removed and its local attributes preserve recorded source bytes. These are packaging/formatting changes, not gameplay behavior.

Daily Build visual_daily_20261007_01 stopped before Godot launch: Windows Hidden .editorconfig was copied and its SHA matched, but Get-Item without -Force could not return its Length. 00 adds -Force only to this copied-file metadata read in existing build_source_daily.ps1; preserve the failed build/evidence directory and run a fresh named build. This is a packaging Harness defect, not an Owner production failure.
