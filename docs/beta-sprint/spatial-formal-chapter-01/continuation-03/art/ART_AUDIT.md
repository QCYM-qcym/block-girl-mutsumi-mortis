# Owner 05 — Continuation 03 incremental read-only Art audit

Task: SPATIAL_FORMAL_CHAPTER_01_CONTINUATION_03. Checked 2026-10-21 (Asia/Shanghai); exact UTC in `ART_INCREMENTAL_EVIDENCE.json`.

Owner branch: `docs/spatial-formal-art-cont03`; worktree: `E:/godot/worktrees/bg-art-cont03`; base: `f972cb850845cb2c31da6975ac7466437aafdec2`. Allowed repository writes: this `continuation-03/art/` directory only. External evidence: `E:/godot/beta-sprint-builds/spatial_formal_cont03_art_20261021_01`.

## Actual increment over continuation 02

1. **Contact Sheet composition now has exact pixel evidence.** All 28 existing 480×270 tiles match their current indexed PNGs after the documented resize and `#f1f2eb` background composition: 0 differing pixels and channels for every tile, covering all 3,628,800 sheet pixels. The source hashes of 27 tiles match the original manifest; tile index 3 (`face_lock_D`, origin 1440,0) uses the changed PNG. This establishes current composition consistency, not original-sheet equivalence or a historical one-tile-only change.
2. **Transparent corners explain a comparison trap.** Comparing raw resized PNGs directly to the opaque sheet initially gives exactly 22 differing pixels per tile (maximum channel difference 144). Applying the generator's documented background composite in memory eliminates all differences. Those 616 corner pixels are an expected compositing effect, not evidence of a new art alteration. No encoded image or reconstructed sheet was saved.
3. **Face Lock PNG contains the edited layout, not merely an unexplained byte mismatch.** Across all six panels, a point inside only the modified rail footprint is RGBA (185,201,199,255), the rail color. A point inside only the original script's rail footprint is the panel background. For panel 0 the points are (180,308) and (520,330); subsequent panel coordinates and RGBA values are in JSON. This corroborates actual current image content against the previously established script/SVG layout edit. It does not substitute for a missing original PNG pixel diff.
4. **Bounded Git provenance was actually checked.** The external package is not inside a Git repository. Repository `git log --all` for the three exact filenames returns no history; the reachable-object name scan examined 13,062 objects with no matching filename. No original candidate was recovered. This excludes the checked local reachable paths only; it does not exclude alternate names, unreachable blobs, unfetched remote refs, archives or owner-held backups.

The existing cause evidence remains: the earlier out-of-scope board generator run changed Face Lock text baselines from y+211 to y+233 and the rail from (x+100,y+146,width385) to (x+124,y+128,width340), then emitted SVG, PNG and Contact Sheet. The generator was restored to its original hash while these exports were not. That established source edit is **historical evidence**, not presented as a new discovery here.

## Exact identities and recommendation

Source root: `E:/Study/方块娘项目/若叶睦/model/art/production/work/GAME_ART_MECHANICS_BATCH_01`.

Backup root: `E:/Study/方块娘项目/若叶睦/model/art/production/work/GAME_ART_MECHANICS_BATCH_01_SCOPE_RECOVERY_20261013`.

Original manifest: source root + `tests/PACKAGE_SHA256.json`, SHA256 `0a4eba41609a75ecda0dbdc33979da543968bf613f3f37a6dba4f77c10f62313`. Trust level remains CORROBORATED_LOCAL_PREINCIDENT_MANIFEST_NO_INDEPENDENT_IMMUTABLE_ANCHOR. Current and backup hashes were freshly rechecked; their equality with continuation 02 is continuity evidence, not the incremental result.

| Relative file | Original SHA256 | Current SHA256 | Backup SHA256 |
| --- | --- | --- | --- |
| `design/states/face_lock_D.svg` | `5482941575c67f1be0b5e83ff0dd3fde067c1b8b4bb31424b7a905d000aaa45b` | `8fe6caa92e1de5db0ea79e3e05b1fd8a341e625b4bb737544b07f8b71ebb14fc` | `8fe6caa92e1de5db0ea79e3e05b1fd8a341e625b4bb737544b07f8b71ebb14fc` |
| `design/states/face_lock_D.png` | `cb619b6d77cc838295fca8c57d36255dbcf4f0280895bda8056819465b680b69` | `f2fa9426f7a27552f2aa91af8714c29ff1cdeed516f78f257ae00ad19511e27d` | `f2fa9426f7a27552f2aa91af8714c29ff1cdeed516f78f257ae00ad19511e27d` |
| `reports/DRAWING_CONTACT_SHEET.png` | `8a503ee044ccbd54210754c840ddb957be6d1bace43096b66f1dfec46b5cc51e` | `30bba2f66d99031b4fb027e9e2f17d0e14136908b58165ee098aeeddfaefcad3` | `30bba2f66d99031b4fb027e9e2f17d0e14136908b58165ee098aeeddfaefcad3` |

| File | Classification across requested categories | Recommended version and recovery risk |
| --- | --- | --- |
| SVG | Actual layout/content edit corroborated by restored vs incident script and current SVG; non-expected modification under prior task scope. Metadata/encoding-only explanation is insufficient. Approved re-export: NOT ESTABLISHED. Original full text unavailable. | Preserve current and post-incident backup pending decision; neither is an exact-original recovery candidate. Prefer a trusted owner-provided candidate matching the original hash before considering replacement. Reconstructing from source could conceal other differences. |
| Face Lock PNG | Current decoded pixels corroborate edited rail geometry; content-changing downstream export is supported. Expected/approved re-export: NOT ESTABLISHED. Contribution of historical encoding changes remains UNKNOWN because original bytes are absent. | Preserve current and backup. No original-v-current pixel diff can be computed. A source-correct SVG alone does not prove historical PNG reproducibility: renderer, fonts and encoder environment remain unanchored. |
| Contact Sheet PNG | Current pixel composition fully explained by 28 current indexed PNGs and documented background; this is an expected generation dependency, **not approval of the prior modification**. Current sheet includes edited Face Lock tile. Historical content-versus-encoding delta remains UNKNOWN. | Preserve current and backup. Do not restore/re-export the sheet alone from an unverified replacement tile. Exact original requires matching original sheet bytes, or separately authorized reconstruction clearly labeled as such. |

Both existing PNGs contain only IHDR, pHYs, IDAT and IEND chunks; no embedded timestamp, text, EXIF or ICC profile was found. Chunk payload hashes are recorded. Current and backup decoded pixels match exactly. Absence of current metadata does not prove what metadata or compression the missing originals had. Current audit library versions are Sharp 0.35.5 and libvips 8.18.7; these are **not asserted to be the original rendering versions**.

## Formal Build impact and proof limits

Specified immutable Build: `E:/godot/beta-sprint-builds/beta_spatial_formal_chapter_20261019_01`; source `763f0132bc58360fab0e224d0e9c54e00c92ae90`.

Its `BUILD_IDENTITY.json` freshly hashes to `1c6fdc2baa4c058733cd2c2ede3532d41d569f7d7236be78689acf8c8d7b5336`, equal to continuation 02. The prior audit checked 1,783 payload hashes, found no target asset path/content-hash matches, no production literal references, and no match in a 148-text-resource static closure. Those prior results are reused and explicitly **not rerun** here. Identity-file equality alone does not verify current payload contents.

For each of the three exports, no formal Build reference was found in that checked static scope; no impact was demonstrated. Runtime I/O, dynamic path construction, binary/UID references, native extensions, caches, saves and unmanifested files remain outside proof. No Build or GUI was launched. This audit cannot claim universal non-use or graphical acceptance.

## Verification, limits and smallest next action

PASS: all 28 current sheet tiles exactly match composited source pixels; 27 source tiles match original manifest; six panel rail samples match edited geometry; both current/backup PNG pairs have zero decoded-pixel difference; bounded Git queries completed; 37 watched external files have no before/after hash drift. The expected external `rev-parse` exit 128 records absence of a Git worktree, not a tool execution failure.

NOT_RUN: source restoration, original reconstruction, SVG rasterization, any generator execution, image encoding/export, broad filesystem search, new Build, gameplay/graphical tests, Human QA. Original PNG comparison is BLOCKED_BY_MISSING_ORIGINAL_BYTES. No original was synthesized or relabeled restored. No PNG/SVG artwork is included in this commit.

Smallest next action: Owner 05 supplies one trusted pre-incident package/archive or exact original files in a named location. Read and hash only the three candidates against the table; then compute actual original/current SVG and pixel differences. If no originals exist, any reconstruction must be separately authorized and placed in a fresh candidate directory, with per-file review before replacement. Current read-only permission does not authorize recovery.

Art Recovery = **PENDING**. Floating Cube = **PENDING_USER_REVIEW** (A opaque coarse material, B inset edge markings, C necessary use explanation). Art Implementation = **NOT_AUTHORIZED**. Production Changes = **NONE**. Human QA = **NOT_RUN**, no qualified first-time player. Incremental audit evidence is delivered; original-byte recovery remains unresolved.
