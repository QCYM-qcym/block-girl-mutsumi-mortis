# SDD ledger — plan: docs/beta-sprint/spatial-puzzle-batch-01/IMPLEMENTATION_PLAN.md

Owner: 03. Worktree: `E:/godot/worktrees/block-girl-spatial-quality-01`.
Branch: `test/spatial-quality-01`. Initial HEAD: `7442e8172e865d093ff1e73570d891f60d9134af`.

## Task 5: in progress

- Shared contract and complete user request read; linked worktree verified clean.
- Only `tests/beta_sprint/spatial_quality/**` and this quality directory may change.
- Runtime opt-in schema, new maps and Host are parallel deliveries; absence blocks their cases individually.
- Existing Foundation Orientation, Kernel, Solver, Safety and Replayer are real consumers. No test-only gameplay implementation is permitted.
- Logical replay, natural Presenter and formal graphical replay receive separate records.
- Graphical execution has not started; window coordination is required.

Ruling: keep this plan's progress ledger in the exclusive quality directory instead of `.superpowers/` — the shared Owner contract permits exactly two change roots. No other Owner workspace or ledger is modified.

Ruling: run only affected tests — the explicit user requirement overrides the TDD skill's default whole-project-suite instruction.

Ruling: synthetic receipt objects in Python harness tests are UNIT evidence only. They cannot register a Real or Graphical PASS.

## Pending inputs

- 01 `RUNTIME_INTERFACE.md` and reviewed opt-in implementation commit.
- 09 `map_factory.gd` with actual Baker results and authored witnesses.
- 00 Host delivery and an exclusive graphical window.
- Actual eligible human tester: HUMAN_QA remains NOT_RUN.

Push: NOT_RUN.

### Receipt admission: RED → GREEN

12 Python UNIT tests pass. RED (15 failed assertions) and GREEN raw processes are preserved. Zero synthetic records were registered as gameplay evidence. Admission rejects doubles, zero/mismatched checks, drift, stderr, wrong facets and duplicate cases.
