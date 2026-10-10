# Implementation ledger — IMPLEMENTATION_PLAN.md

Baseline: 2938d6e534f5b596bb320ce79d72b69f5923f3cd; branch feat/game-feel-audio; initially CLEAN; existing linked worktree verified.

Authority: human userMessage in 00 chat 01a11125-280e-7403-98f9-98b92911c8f7 explicitly starts BUILD/PARALLEL and original 11 audio development. 00 supplied matching committed contract/allowlist. This replaces additional approval rounds for this implementation.

Pre-flight: event policy produces cue commands; director consumes those commands. Asset manifest supplies fixed music/SFX entries. Source/assets/test writes are disjoint between parent and asset worker.

Ruling: keep ledger/plan/evidence under the explicit owner allowlist rather than default .superpowers/docs/superpowers directories; the scope matrix forbids writes elsewhere. Cost if wrong: document relocation only.

Ruling: expose audio-only set_music(context,world_id) in addition to the six required APIs, since the v1 movement event cannot describe Main Menu or every native World Shift lifecycle. 00 receives exact optional hookup request. Cost if wrong: revise caller-facing audio method; no Runtime/shared changes.

Task 1 complete: policy_red_01 has 56 checks/12 expected behavioral failures/empty stderr; final policy_final_02 has 63 checks/0 failures/empty stderr, with assertion+fixture+runner source hashes and no source drift. Safe Fall, EDGE classification, duplicate/local/global/endpoint/cancel/generation/run tests use synthetic immutable events, no authoritative Runtime.

Task 2 complete: 5 actual music WAV exports, 13 SFX WAV exports, 18 PCM24 sources, score/recipe/provenance/audition. Reproduction evidence records 38 byte-identical files; actual PCM analyzer passed 18 assets with no clipping. OGG not produced; Ending planned only; subjective listening NOT_RUN.

Task 3 complete: director_red_01 35 checks/26 expected failures/empty stderr; initial implementation parser error director_green_01 retained separately, source drift during its timed-out execution retained (never used as GREEN). director_regression_red_01 proves 3 reentrancy/settings regressions; director_review_red_02 proves 7 paused/lifecycle regressions. director_final_01 passes 48 checks/0 failures, empty stderr, unchanged executed source inventory, actual WASAPI PCM peak 0.113657116889954. settings_final_02 passes 10 checks with writer PID25860/reader PID3836 on the same isolated profile; actual unchanged SaveStore schema, no production save access.

Final review: fresh independent read-only reviewer; all 4 Important findings covered by RED/GREEN and final suite. Minor partial settings also fixed. Deferred minor: retained lifecycle tombstones grow with loads/cancels until director teardown; fixed voice population remains18.

Ruling: the shared contract's monotonic event_id is implemented as int>=0, fail-silent for other types; request explicit 00/01 acknowledgement. Cost if wrong: update the audio consumer id type and re-run policy tests; no gameplay changes.

Ruling: available runtime had no audio encoder, so deliver verified PCM16 WAV loops and retained PCM24 sources instead of claiming OGG. Cost if wrong: later encoding/package-size optimization; actual audio is present.

Import preflight: engine exit0, old SVG dimension WARNING retained. Generated new .uid/.import sidecars within audio roots retained; 31 new untracked sidecars outside Owner scope identified/hashes recorded and removed by exact-file patches, restoring tracked baseline. This is CONFIG_IMPORT evidence only. The wrapper initially hit stdout GBK encoding error after writing process.json; corrected UTF-8 decoding/output before final tests. Import was not claimed as clean behavioral/Graphical PASS.

Task 4: event mapping, settings contract, integration request, independent review and actual evidence complete. Commit and final scope/hash/clean checks follow; formal host/Fall/Shell UI/Human listening remain case_pending.

2026-10-10 incremental DTO compatibility: verified Runtime candidate26387d6 native Safety dictionary, null rejection next_state, nullable kind8 direction and StringName connection/profile ids. RED runtime_shapes_red_01:79checks/3behavioral failures. GREEN policy79 + physical playback48 + unchanged SaveStore10 + native Facade API16 =153 checks,0 failures. Exact candidate files copied only into owner-local isolated evidence project; no Runtime merge or modification. Audio assets and original evidence unchanged. Native direct completion is API/DTO evidence, motion/Graphical NOT_RUN. Initial native harness cleanup error preserved separately. Details: DTO_COMPATIBILITY_20261010.md.

## 2026-10-10 — explicit curve event.v2 consumer delta

Implemented only Owner11 event-policy compatibility against supplemental registration ec826753435458abc41cc365e4b57dba27767fbd. Final202 checks PASS; actual new-curve Runtime and graphical contact remain pending01/00/10A. Original63 audio files and all baseline files unchanged. See V2_EVENT_COMPATIBILITY.md; original receipts/evidence remain historical and untouched. No push.
