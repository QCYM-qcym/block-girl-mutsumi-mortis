# Continuation 05 — Floating Cube scoring handoff

Task: `SPATIAL_FORMAL_CHAPTER_01_CONTINUATION_05_ACCEPTANCE_SCORING` / `FLOATING_CUBE_SCORING_JSON_SCHEMA_01`.

Owner: 00 Integration Coordinator. Worktree: `E:/godot/worktrees/bg-formal01`. Branch: `feat/spatial-formal-chapter-01`. Audited base: `8a8745d4b840e46ab1be5068c26a93b424753539`. The input/schema and source/render investigations used independent read-only reviewers; they did not create separate Owner commits or change assets.

## Actual delivery

- [SCORING_RESULTS.schema.json](SCORING_RESULTS.schema.json): valid JSON Schema Draft 2020-12, completed from the supplied fragment that ended inside `review_mode`. Keeps the supplied top-level fields and explicit E1–E6 rules. No claim that the missing fragment was supplied in full.
- [SCORING_RESULTS.json](SCORING_RESULTS.json): actual structured visual observations, fixed weights, null/NOT_ASSESSED semantics, camera identities, source hashes, 49 existing evidence references, hard gates and independent readiness/execution states.
- [SCORING_RESULTS.md](SCORING_RESULTS.md): deterministically generated from the same JSON. Scores, arithmetic, observations, deductions, view coverage and file identities agree.
- [validate_scoring.py](validate_scoring.py): schema validation plus arithmetic, references, real file/hash checks, missing-evidence behavior, hard-gate propagation and Markdown consistency. It does not infer visual scores or run Godot.

Actual image review: 24 original viewport PNGs, three variants × four fixed camera quadrants × two native resolutions. All 32 historical PNG hashes were checked; the additional eight C frames are not scored. No image editing, generated substitute image, Blender/Godot launch, user-window operation or new gameplay input took place.

## Outcome

`OVERALL_VISUAL_REVIEW=PARTIAL`. Current material / A / B assessed subtotals are **46.0 / 61.0 / 50.0**, using the common **90%** of original weights. Complete totals and complete-score differences are **NOT_ASSESSED / null**, because V5 lacks Inner and formal-world Art context. These subtotals are not normalized to 100. A's common-subtotal improvement is +15.0 over current; B's is +4.0. A is +11.0 over B on this partial basis only.

Per-view recognition: current `[2,2,2,2]`, A `[3,3,3,2]`, B `[2,2,2,2]` in the project's NORTH/EAST/SOUTH/WEST order. A has clearer non-color texture cues, but WEST's dark sides weaken them. B's closed top frame can suggest a standable/interactive panel. These are Codex visual judgments, not measured player comprehension. B was not penalized for lacking a high-detail model; its actual lightweight shader preview was assessed.

G1–G8 pass only in the explicitly bounded same-object historical static Surface/source preview context. The six underlying roof/Host/map/view source files match current integration and formal Build exactly. The old experiment wrapper differs from today's formal Shell background/HUD; no entire-current-Build screenshot equivalence is asserted. Color/exposure share engine defaults without a recorded numeric sample; no exposure value was invented.

Input protocol preparation and combined Human QA protocol preparation are PASS. Actual execution readiness remains PARTIAL; input cause UNKNOWN, graphical diagnostic NOT_RUN, Human QA NOT_RUN. The inherited blank player template must be copied and updated with the future actual verified new Build and session identity; no old Build identity can be blindly reused.

`FORMAL_ASSET_APPROVAL=NOT_GRANTED`, `ART_CHANGE=PROPOSAL_ONLY`, `GAME_INTEGRATION=NOT_RUN`, `PRODUCTION_CHANGES=NONE`, `NEW_BUILD=NOT_REQUIRED`. Floating Cube direction remains for user review. Separate original-Art recovery remains blocked on trusted source availability.

## Validation and preservation

Validation used an isolated installation of jsonschema 4.26.0 under `E:/godot/beta-sprint-builds/floating_cube_scoring05_20261021_01/python_deps`; no global package or project dependency was changed. Draft202012Validator + FormatChecker passed. Seventeen intentionally invalid examples were rejected, including false full totals, wrong weights, missing paths, wrong hashes, hidden hard failures, contradictory execution PASS and unauthorized Art approval. All 49 evidence paths/hashes and 24 PNG headers/dimensions match, and Markdown exactly matches the JSON renderer.

Recheck without rewriting artifacts:

```powershell
python docs/beta-sprint/spatial-formal-chapter-01/continuation-05/floating_cube/validate_scoring.py --dependency-dir E:/godot/beta-sprint-builds/floating_cube_scoring05_20261021_01/python_deps
```

With an independently installed `jsonschema` supporting Draft 2020-12, omit `--dependency-dir`. `--write-markdown` explicitly updates only this task's Markdown from validated JSON. Optional `--receipt` requires a fresh absolute output file and refuses overwrite. Old local evidence paths must remain available for full byte verification; schema validity alone does not prove them or grant approval.

Fresh before/after preservation checks cover 1,783 formal Build payload files, its ZIP, 1,759 existing preview files, 25 watched historical/source records, original Build profile absence and 69 old QA-profile files. All match. This is manifest-bounded preservation, not a claim to scan the whole filesystem. Protected main/release/tag/old experiment refs remain unchanged.

External evidence: `E:/godot/beta-sprint-builds/floating_cube_scoring05_20261021_01`. `PRESERVATION_BEFORE.json`, `PRESERVATION_AFTER.json` and `VALIDATION_RELEASE.json` retain the actual checks. Earlier validation receipts are preserved; the release receipt additionally reflects removal of Markdown trailing-space hard breaks for Git whitespace compatibility. The post-commit `FINAL_DELIVERY.json` records the real commit, normal branch push, independent remote SHA and clean working tree, without inserting a self-referential commit hash here.

## Minimum next actions

1. 05/09 and 00: retain these proposals; prepare isolated Inner/formal-world-context comparisons and address the weak WEST view only under appropriate preview authorization. Do not replace production assets as a consequence of this score.
2. 08: once an eligible first-time player exists, observe whether the pattern actually reduces platform/interaction misreading using the existing protocol. No automated score substitutes for that observation.
3. 00/08: establish supported independent input control and a correlated game-receipt channel before executing the prepared diagnostic. Preserve UNKNOWN/NOT_RUN until real evidence exists.
4. User review determines whether A, B, another proposal or the current design should proceed. No choice or formal asset approval is made by this handoff.
