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

### Dependency intake and Safety consumer correction

Preparation commits: `5cb2d5e` (admission UNIT) and `8fb5558` (matrix/public consumers).
Normal merges consumed the approved 01 interface, 00 Bridge `43c34bb74f6b8fda72ad2cf38e37483cf065385a`, and 09 maps `84f733f37ca2fbd351b058cca056e58ae491bc00`.
Combined execution HEAD: `d897be888b480d09d0864efa92f1249d4e8879fb`.

`orientation_01`: 33 real public interface UNIT assertions passed.
`legacy_core_01`: 162 bounded existing MAP A/B API assertions passed. Not five-level regression or new-mechanism acceptance.

`loop_core_01` / `fork_core_01`: each retained one failed Safety assertion, exit1, empty stderr, no source drift or doubles. Native Runtime events confirm PERSPECTIVE_FALL_APPLIED with the formal cubic Safety proof. Root cause is Owner03 calling generic `validate_motion` for a MOVE that is an authored Fall; that API handles MOVE as Roll. Corrected the consumer to use the actual formal Fall motion descriptor and `validate_perspective_motion`. Camera actions separately validate safe states and unchanged physical state. No production defect or production change inferred.

Ruling: Loop/Fork may use the delivered schema3 cubic profile. Only Gate/FaceLock/combined require schema4. This follows explicit opt-in compatibility and the actual 09 delivery, rather than forcing a nonexistent migration.

### Receipt admission: RED → GREEN

12 Python UNIT tests pass. RED (15 failed assertions) and GREEN raw processes are preserved. Zero synthetic records were registered as gameplay evidence. Admission rejects doubles, zero/mismatched checks, drift, stderr, wrong facets and duplicate cases.

### Loop/Fork first independent gate: GREEN

Corrected headless: Loop37 / Fork31. Formal GRAPHICAL mode1: Loop77 / Fork55, original traces repeated twice; no manual graphical completion. All six selected native receipts have exit0, empty stderr, source drift=[], doubles=[] and verified PID/profile/candidate capture. This is only the executed rows, not all 83 cases or five-level regression.

03 graphical window RELEASED to00/07 after native processes exited. Further gated graphics will require a new coordinated window.

### Intake after first graphical window

Approved Runtime697a31ed85e29b1d37ec882e712d323751bd90a1 and map9debc8e33efc32593f33888a7d30e0e69a873fb6 were normally merged. Combined HEAD48808896965ddc9d1817c96dd1bb5cbc8fa05f37. Initial evidence staging encountered Windows path length on generated shader caches; no receipt commit was created in that attempt. Ignored shader caches in this exclusive quality directory, preserving them physically and keeping raw logs/reports. No public source or Git global/repository configuration changed.
