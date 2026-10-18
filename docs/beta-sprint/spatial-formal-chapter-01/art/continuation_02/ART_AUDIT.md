# Owner 05 — Formal chapter continuation 02 read-only Art audit



SPATIAL_FORMAL_CHAPTER_01_ACCEPTANCE_CONTINUATION_02



Checked UTC: 2026-10-18T18:00:56.738260+00:00

Repository `E:\godot\worktrees\bg-art-cont02`, branch `docs/spatial-formal-art-cont02`, base `763f0132bc58360fab0e224d0e9c54e00c92ae90`.



## Result and boundary



The three files and their post-incident backups match closure04 byte for byte. All three differ from the corroborated original manifest. There is no verified original-byte backup in the available evidence. No restore, overwrite, deletion, export, renderer/generator execution, GUI preview, or source-asset write occurred. FloatingCube A/B/C remains PENDING_USER_REVIEW.



Original manifest `E:\Study\方块娘项目\若叶睦\model\art\production\work\GAME_ART_MECHANICS_BATCH_01\tests\PACKAGE_SHA256.json`: SHA256 `0a4eba41609a75ecda0dbdc33979da543968bf613f3f37a6dba4f77c10f62313`; 177 entries. Local file, repository snapshot and committed snapshot match. Provenance: CORROBORATED_LOCAL_PREINCIDENT_MANIFEST_NO_INDEPENDENT_IMMUTABLE_ANCHOR. The earlier 174/177 full-package comparison and bounded original-copy search are reused historical evidence, not fresh full-package scans.



## Exact file identities



### design/states/face_lock_D.svg

Current `E:\Study\方块娘项目\若叶睦\model\art\production\work\GAME_ART_MECHANICS_BATCH_01\design\states\face_lock_D.svg` — 7179 bytes.

Reliable post-incident backup `E:\Study\方块娘项目\若叶睦\model\art\production\work\GAME_ART_MECHANICS_BATCH_01_SCOPE_RECOVERY_20261013\design\states\face_lock_D.svg` — 7179 bytes. This preserves the modified state, not the original.

Original SHA256 `5482941575c67f1be0b5e83ff0dd3fde067c1b8b4bb31424b7a905d000aaa45b`; original length UNKNOWN.

Current SHA256 `8fe6caa92e1de5db0ea79e3e05b1fd8a341e625b4bb737544b07f8b71ebb14fc`.

Backup SHA256 `8fe6caa92e1de5db0ea79e3e05b1fd8a341e625b4bb737544b07f8b71ebb14fc`.

Classification: SVG_STRUCTURAL_LAYOUT_CHANGE_CORROBORATED; original SVG full element diff unavailable.

Format: `{"parse": "PASS", "width": "1920", "height": "1080", "viewBox": "0 0 1920 1080", "elements": 90, "render": "NOT_RUN"}`.



### design/states/face_lock_D.png

Current `E:\Study\方块娘项目\若叶睦\model\art\production\work\GAME_ART_MECHANICS_BATCH_01\design\states\face_lock_D.png` — 184686 bytes.

Reliable post-incident backup `E:\Study\方块娘项目\若叶睦\model\art\production\work\GAME_ART_MECHANICS_BATCH_01_SCOPE_RECOVERY_20261013\design\states\face_lock_D.png` — 184686 bytes. This preserves the modified state, not the original.

Original SHA256 `cb619b6d77cc838295fca8c57d36255dbcf4f0280895bda8056819465b680b69`; original length UNKNOWN.

Current SHA256 `f2fa9426f7a27552f2aa91af8714c29ff1cdeed516f78f257ae00ad19511e27d`.

Backup SHA256 `f2fa9426f7a27552f2aa91af8714c29ff1cdeed516f78f257ae00ad19511e27d`.

Classification: FILE_BYTES_CHANGED; ORIGINAL_PIXEL_VS_METADATA_VS_COMPRESSION_DIFFERENCE_UNKNOWN.

Format: `{"crc_zlib_full_scanline_decode": "PASS", "size": [1920, 1080], "mode": "RGBA", "bit_depth": 8, "interlace": 0, "pHYs": [2835, 2835, 1], "decoded_rgba_sha256": "14fea46e29c10a4444a62d351019fd65866d42848f7344f774089d7bb95da408", "filters": {"0": 1080}, "image_saved": false}`.



### reports/DRAWING_CONTACT_SHEET.png

Current `E:\Study\方块娘项目\若叶睦\model\art\production\work\GAME_ART_MECHANICS_BATCH_01\reports\DRAWING_CONTACT_SHEET.png` — 1516929 bytes.

Reliable post-incident backup `E:\Study\方块娘项目\若叶睦\model\art\production\work\GAME_ART_MECHANICS_BATCH_01_SCOPE_RECOVERY_20261013\reports\DRAWING_CONTACT_SHEET.png` — 1516929 bytes. This preserves the modified state, not the original.

Original SHA256 `8a503ee044ccbd54210754c840ddb957be6d1bace43096b66f1dfec46b5cc51e`; original length UNKNOWN.

Current SHA256 `30bba2f66d99031b4fb027e9e2f17d0e14136908b58165ee098aeeddfaefcad3`.

Backup SHA256 `30bba2f66d99031b4fb027e9e2f17d0e14136908b58165ee098aeeddfaefcad3`.

Classification: FILE_BYTES_CHANGED; ORIGINAL_PIXEL_VS_METADATA_VS_COMPRESSION_DIFFERENCE_UNKNOWN.

Format: `{"crc_zlib_full_scanline_decode": "PASS", "size": [1920, 1890], "mode": "RGBA", "bit_depth": 8, "interlace": 0, "pHYs": [1000, 1000, 1], "decoded_rgba_sha256": "2a58e1d531263f7dd9e53fe4f2192aa7f644ae49d199268cbc0d2649cda7efcd", "filters": {"0": 1890}, "image_saved": false}`.



## Cause and generation dependencies



Recorded prior out-of-scope generator run after two layout expressions changed. Current SVG text baselines and rail transforms corroborate post-incident generator. Restored generator now matches original manifest; the three exports still differ.

Restored `build_boards.cjs` SHA256 `bf4351a481015c2ad347c1d429d62a69a2437a4e3fe8526b63e5532df2c39fcb` matches the original manifest; post-incident script SHA256 `16af8db73d935af9f839f2446c9008781946da17b6260c6f272c345777027d14`. Source lines 53–54 change text baseline y+211 to y+233 for Face Lock, and rail x+100/y+146/width385 to x+124/y+128/width340. Current SVG corroborates those edited coordinates. This is source/current-output corroboration, not a full original SVG diff.



Line 29 writes SVG, then Sharp renders that SVG string to PNG. The module loads DESIGN_GEOMETRY.json, BLENDER_GEOMETRY.json, FACE_SYMBOL_MAPPING.json and mapped symbol SVGs; the Face Lock state page uses eye.svg. The four named data/symbol input hashes match the original manifest (recorded in JSON). Hard-coded Sharp module path and Microsoft YaHei/Arial font selection do not prove the historical renderer/font versions. The full generator also reads reference renders and emits many other pages; rerunning it is outside scope.

Lines 120–121 read all 28 indexed PNGs, resize each to 480×270, and composite four columns. Face Lock D is tile index 3 at (1440,0). The index SHA256 is `698e5377c5f04b378d74d8a3252367326cacbb7bc6de93e5a95552e7572e5455` and matches the original manifest. Fresh dependency hashing finds 27/28 indexed PNGs matching original entries. This locates dependencies and does not prove only one tile changed.

No original SVG/PNG bytes available for full element or pixel comparison. Exact historical Sharp/libvips/font environment and PNG encoding reproducibility are unestablished. A sole-region pixel change is not proven.



## Exact recovery proposal — not executed



- `design/states/face_lock_D.svg`: accept an owner-supplied trusted original candidate only if SHA256 is `5482941575c67f1be0b5e83ff0dd3fde067c1b8b4bb31424b7a905d000aaa45b`. A future authorized replacement must first confirm the target still hashes to `8fe6caa92e1de5db0ea79e3e05b1fd8a341e625b4bb737544b07f8b71ebb14fc`.

- `design/states/face_lock_D.png`: accept an owner-supplied trusted original candidate only if SHA256 is `cb619b6d77cc838295fca8c57d36255dbcf4f0280895bda8056819465b680b69`. A future authorized replacement must first confirm the target still hashes to `f2fa9426f7a27552f2aa91af8714c29ff1cdeed516f78f257ae00ad19511e27d`.

- `reports/DRAWING_CONTACT_SHEET.png`: accept an owner-supplied trusted original candidate only if SHA256 is `8a503ee044ccbd54210754c840ddb957be6d1bace43096b66f1dfec46b5cc51e`. A future authorized replacement must first confirm the target still hashes to `30bba2f66d99031b4fb027e9e2f17d0e14136908b58165ee098aeeddfaefcad3`.



Preserve all current files and post-incident backups. No original candidate exists in this audit. If exact original bytes cannot be located, only separately authorized reconstruction may write into a fresh candidate directory: SVG needs verified source/data/symbol inputs; state PNG needs verified SVG plus renderer/fonts/encoding; contact sheet needs all indexed PNGs plus resize/composite tooling. A differing hash must be labeled RECONSTRUCTED_DIFFERENT, never exact restore. Present candidate provenance and differences for per-file replacement authorization. Do not run the whole package generator or change the original manifest.



## Specified immutable formal Build



Build `E:\godot\beta-sprint-builds\beta_spatial_formal_chapter_20261019_01`; BUILD_IDENTITY.json SHA256 `1c6fdc2baa4c058733cd2c2ede3532d41d569f7d7236be78689acf8c8d7b5336`; source `763f0132bc58360fab0e224d0e9c54e00c92ae90`; 1783 listed hashes rechecked; 0 drift. Identity art state: `PENDING_USER_REVIEW; no formal replacement`.

Asset path/name matches: 0. Original/current/backup content-hash matches: 0. UTF-8 text resources scanned: 1471; documentation mention lines: 150; non-document mention lines: 0. Static literal text-resource closure: 148; relevant hits: 0.

NO_ASSET_MANIFEST_MATCH_AND_NO_PRODUCTION_LITERAL_REFERENCE_FOUND

Static literal trace is not runtime I/O proof; binary decode, arbitrary dynamic concatenation, UID resolution, native extensions, caches, saves and unmanifested files not audited; Build not launched.



## Verification and handoff



PASS: three current and three backup identities unchanged from closure04; manifest/snapshot/committed snapshot equal; restored generator original hash; SVG XML parse; both PNG CRC/zlib/full scanline decodes; 1783 Build manifest hashes; 10 watched external paths unchanged before/after. All verification predicates: `{"three_current_equal_closure04": true, "three_backups_equal_closure04": true, "manifest_disk_snapshot_committed_equal": true, "watched_paths_no_drift": true, "build_manifest_no_drift": true, "generator_matches_original": true}`.

NOT_RUN: gameplay tests, engine launch, Human QA, original-image pixel comparison, image generation/export, restore, whole-package/full-disk rescan. Human review remains PENDING; no graphical or aesthetic acceptance is inferred.

Stage status: COMPLETE for this read-only audit. Recovery status: PARTIAL / ORIGINAL_BYTES_UNAVAILABLE. Integration: PENDING_00. Development branch documentation delivery is recorded separately in external GIT_DELIVERY.json; no production assets are committed.

Machine evidence: `E:\godot\beta-sprint-builds\spatial_formal_cont02_art_20261019_01\ART_AUDIT.json`. Audit runner: `E:\godot\beta-sprint-builds\spatial_formal_cont02_art_20261019_01\audit_readonly.py`. Source audit code adapted from closure04 without importing or executing any Art script.
