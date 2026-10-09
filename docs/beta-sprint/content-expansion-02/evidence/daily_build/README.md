# Beta Sprint Phase2 — Content Batch02 Daily Build

Source snapshot: 991140292ac67e87d1751a062e7e96c7b9fee553. SOURCE_PLAYABLE_NOT_EXE; Godot 4.7.2 required.
Run ./play.ps1. Isolated save: user://beta_sprint/beta_content_batch_02_20261009_01/qa_progress.json.
All registered levels enter through the formal Main Menu / Level Select, using normal completion to unlock the next level:
- mutsumi_l01: 另一个世界 (FORMAL)
- mutsumi_l02: 两岸之间 (GREYBOX)
- mutsumi_l03: 视线相接 (GREYBOX)
- mutsumi_l04: 借来的道路 (GREYBOX)
- mutsumi_l05: 归途的门 (GREYBOX)

L01/L02/L03 reuse approved3D presentation; delivered Batch02 levels use greybox presentation and the original Content/P01 Runtime.
Continue restores the most recently entered unlocked level at its authored spawn. Save/Continue algorithms are unchanged.
WASD move; Q/E four90-degree views; Space world; R Reset; Esc Pause/Resume.

Copied-source, catalog and boot checks are recorded in build-manifest.json and QA_BUILD_VERIFICATION.json.
Smoke evidence reference: p2_final_focused_02 (see the separate Integration receipt for actual route results).
Independent Human QA for this new Daily Build: NOT_RUN. Previous fixed3D02 matrix/Cold Continue evidence belongs to that earlier Build only.
Known baseline import/exit notes: Existing standalone --quit-after ObjectDB exit warning: content_mutsumi_l02_boot
STAIR_CLEARANCE=PARTIAL_PASS; STAIR_TRAVERSAL=NOT_RUN. Frozen Art and Foundation remain unchanged.
