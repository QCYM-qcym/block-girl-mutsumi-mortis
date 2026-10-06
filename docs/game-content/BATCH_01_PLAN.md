# Game Content Batch 01 Implementation Plan

> Execute inline using executing-plans; the user explicitly requires direct BUILD. All working records live inside content owner roots.

**Goal:** One formal vertical slice and two independently playable greyboxes.

**Architecture:** Resource-configured content adapters inherit P-01 presentation and state APIs. Shared movement, view, input, polish and production assets remain unchanged.

**Tech Stack:** Godot 4.7.2, GDScript, TSCN/TRES.

**Spec:** `docs/game-content/BATCH_01_SPEC.md`.

## Global Constraints

Write only to the three CONTENT_OWNER_ROOTS in the spec. Independent scenes, no Foundation changes, no push. Native managed-worktree tool returned Not a git repository; Git worktree fallback created `E:/godot/worktrees/block-girl-beta-game-content` at baseline. Original working tree is untouched.

## Review Focus

- Reset during in-flight movement, shift and view snap must restore all state.
- Inner-only tiles must reject unsafe shifts with visible feedback.
- Greybox UI must not expose invisible plate/door state or stale P-01 goal text.
- Completion must stop movement and rotation while leaving R available.
- All four views at the minimum window size must keep the map clear of HUD.

## Task 1: Production content and topology

Files: `game/levels/mutsumi/batch_01/{content_level_data,content_state,content_board,content_hints,content_level}.gd`, three `.tres`, three `.tscn`; `tests/playtest/test_batch_01_state.gd`.

Interfaces: consume existing P-01 graph/view/mover/board APIs; produce `definition` Resource with spawn/goal/floors/link fields and compatible graph `configure(definition)`. Scene exports `content: Resource`.

- [x] Add missing-scene and real-route/mandatory-mechanic/all-reachable-state checks; run headless, expect explicit missing formal scenes.
- [x] Implement resources and local adapters; no public algorithm changes.
- [x] Run state test: no failures; Goal reachable from every reachable state on each map.

## Task 2: Graphical input playthrough acceptance

Files: `tests/playtest/test_batch_01_runtime.gd`, `tests/playtest/run_batch_01.ps1`, `tests/playtest/evidence/batch_01/**`.

Interfaces: consume independent scene paths and real input adapter. Produce input-driven state checkpoints and PNGs.

- [x] Exercise L-01 three playthroughs, continuous input, actual link crossing, unsafe shifts, Goal lock and all transition Reset cases.
- [x] Exercise L-02/L-03 normal and alternate-view playthroughs and Reset.
- [x] Verify graphical Windows rendering and all-view minimum-size layout; inspect screenshots.
- [x] Run pre-existing non-mutating gameplay/logic regression fixtures; record every failure.

## Task 3: Delivery

Files: `docs/game-content/BATCH_01_REPORT.md`, `docs/game-content/BATCH_01_FILES.json`, `docs/game-content/LEVEL_TEMPLATE.md`, `game/levels/mutsumi/batch_01/level_order.json`.

- [x] Document actual routes, resource template, owner requests, limitations and validation counts.
- [x] Hash modified delivery files and verify no prohibited tracked path changed.
- [x] Commit only owner-root changes; confirm clean isolated working tree and Push NOT_RUN.

## Execution ledger

Pre-flight: resources feed graph/board/hints; scene provides original polish-compatible interface. No public contract changes needed.

Ruling: user direct BUILD instruction supersedes skill approval handoffs; no second design/plan approval. Keep ledger under docs/game-content rather than skill scratch paths to honor owner boundaries.

Task 1: complete. Initial baseline: P01 state 31 checks/108 solvable. RED: three independent scenes absent. GREEN: batch state 43 checks; 108/48/56 reachable states all solvable. Existing regression: perspective 66 checks, prototype state 50 checks, input PASS.

Task 2: first graphical run completed all seven routes; failed only harness assertions. Ruling: check painted alpha bounds rather than transparent atlas padding, and use D to start L03's horizontal spawn route. No production change required. Preserve initial_harness_report.json and initial_harness.stderr.log as historical failed evidence; final runtime_report.json is authoritative.

Task 2: complete. Corrected full run: 429 checks, seven successful graphical playthroughs, zero failures. Original P01 graphical regression: 167 checks, zero failures. Editor import: exit 0 and empty error log. Added import to the repeatable wrapper so a fresh checkout can load PNG assets before runtime; complete wrapper run also exited 0 with 43 state and 429 runtime checks, seven routes, zero failures.

Final review: independent read-only reviewer inspected adapters, all three maps and all 12 minimum-size view screenshots; no Critical, Important or Minor findings. Ruling: future arbitrary configurations, relocated gates, non-EAST links, Foundation migration, menu/catalog wiring, final art and first-player comprehension remain explicit owner/template/playtest boundaries; treating this batch as a general configuration guarantee would risk future unsolvable content, so the template and report record those limits.

Task 3: complete. Delivery report, resource template, ordered stable ids, SHA-256 manifest and evidence are included in the delivery commit. Keeping branch/worktree for 00/07 integration, no merge and no push. Only owner-root files are committed. Original main checkout's seven untracked README imports are untouched; isolated auto-generated copies and tests/playtest check logs are removed as temporary validation outputs.

Final integration audit: read-only inspection of 07's current level_catalog.gd and level_adapter.gd confirmed registration belongs in DEFAULT_ENTRIES with adapter="p01". Added that metadata and exact integration request; no Shell production file changed. Legacy p01 progress remains 07's decision, no save migration in this batch.
