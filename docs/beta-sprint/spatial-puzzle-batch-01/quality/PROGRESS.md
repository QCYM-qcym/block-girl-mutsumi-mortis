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

### Gated native observation RED and expensive original graph

`gate_core_01` and `lock_core_01` retained native-observation failures: the test incorrectly expected movement STARTED events for Shift. Production Facade explicitly publishes nonmovement neutral FEEDBACK and the separate native `transition_started` signal. The consumer now captures full identity with public `get_pending_identity` from that native signal. No production edit or defect inferred.

`combined_core_01`: actual full graph process hit the 240-second runner deadline, was terminated by that deadline, and produced no report; stderr empty, no source drift. This run yields no Solver/Softlock/bypass conclusion. Do not repeat combined FULL_GRAPH while09's same-process official proof runs. Its exact external receipt will be cited as Owner09 evidence, with zero independent03 assertions added. Owner03 may generate FIRST_SHORTEST selected witnesses for independent Runtime/Replay; these cannot establish full-graph safety/softlock/absence of bypass.

`mechanics_01`: 437 production native Facade assertions passed across all five maps. First preparation version; expanding adversarial unsafe/ordinary-Roll inputs and explicit global Shift lifecycle while preserving this original receipt. UNIT author-bake checks will be separately labeled, not REAL_RUNTIME.

### Intake after first graphical window

Approved Runtime697a31ed85e29b1d37ec882e712d323751bd90a1 and map9debc8e33efc32593f33888a7d30e0e69a873fb6 were normally merged. Combined HEAD48808896965ddc9d1817c96dd1bb5cbc8fa05f37. Initial evidence staging encountered Windows path length on generated shader caches; no receipt commit was created in that attempt. Ignored shader caches in this exclusive quality directory, preserving them physically and keeping raw logs/reports. No public source or Git global/repository configuration changed.

### Strict diagnostics remain part of acceptance

Gated native-observation correction produced 54/97/62 passing assertions for Gate/Lock/combined-selected, but all three receipts correctly FAIL strict admission due to ObjectDB/resource leaks on stderr. Root cause: native callback captured its own RefCounted Facade, retaining a cycle; changed the observer to WeakRef. No production changes.

mechanics_02 retained failures in two adversarial Core variants: authoring dictionaries lacked the required content_hash placeholder before formal Codec hashing. This is a test input mistake, not missing Runtime dependencies. Added the placeholder before computing the actual formal hash and guarded failed setup.

Combined original-graph reference is Owner09 report combined_runtime_02: 908 states /3916 edges, complete,103checks,0failures,0softlocks,0bypasses; UNFILTERED FULL_GRAPH. Raw report SHA e17d8f50dbdae072830434d6f1b84c23c9a152f7b55ba66d121ea22d06faa9e5. No independent03 count is added. Binding process/source receipt still to inspect before final registration.

### Final integration intake and five-map formal GRAPHICAL gate

Approved00 composite0075819b2f6f7c93fa38c733792afff5d094dc93 normally merged; execution candidate dee229c76f48b2fa3dbfaaa30bebed7e982f63ce. Includes01finalb78d07c,09finalfd162d5,07menu and Bridge27f57be. Five actual mode1 original traces repeated twice: Loop77/Fork55/Gate73/Lock117/combined165 =487 independent assertions. Old Camera formal extension44. All exit0/stderr0/drift[]/doubles[] and actual Windows capture. Combined trace FIRST_SHORTEST is selected witness only; not complete graph proof.

Owner03 harness RED: explicit WeakRef type missing; corrected parse warning. New isolated main_scene invalidates implicit legacy recipe entry; process42516 matched exact own command before termination; old receipt retained. Ruling: select the frozen real game_shell.tscn in the test process before invoking unchanged L01-L05 native recipe; no production project setting change or new-menu regression claim.

### Fresh whole-branch review and bounded fix pass

Reviewer found two Important coverage gaps, no Critical/Minor production findings: held input was released before completion and UNLOAD reused a Reset-invalidated token. Quality receipt coverage RED10missing measured certificates retained. Added genuinely held native input through natural completion without Reset, and real currently-live pending identity UNLOAD with public retirement checks. Native GREEN500/stderr0. Natural Loop RED199: actual q0 W points to unsupported edge, so setup starts no transition; corrected to D at the actual q0. This job was mistakenly launched after03had releasedGUI; it completed, is rejected as FAIL and is not admitted. Current03processes exited. Next GUI window requested while00retains ownership.

Legacy L01-L05 fresh final206exit0/stderr0/PIDverified, profile isolated. UID pairs registered via actual .import; no imported bytes or public sources modified. Natural initial882/screens19 retained; lifecycle rows returned to PENDING until the review fix passes.

### Task5 completed within Owner03 scope

00explicitlyre-granted a single exclusive graphical round. Natural reviewGREEN947all5maps, exit0stderr0/drift[]/doubles[]; nativeGREEN500. Review coverage markers10/10 now present from actual raw reports. Held physical key remains pressed through natural completion and post-completion echoes; no Reset masks queues. UNLOAD captures a new live accepted identity, then retires it; natural Host exit observes unloaded actual Runtime and empty public identity without completion injection. No new production algorithm. No re-review or additional predicates. Deferred minors: NONE. GUI RELEASEDto00; own processes exited.

Final selected independent03 assertions2547; Python12UNIT and10receipt-coverageUNIT kept separate.98rows:80independentPASS,8explicit externalREFERENCE_PASS,10NOT_RUN (5Human,4unneeded alternativeFIRST_SHORTEST,1combined independentfull-edgecensus). Old94and69 sealedunchanged. No dependency fabricated for unexecuted cases. Ruling correction: actual frozen legacy scene is game_feel_shell.tscn (prior ledger game_shell name was corrected in test), exactly the old project entry including real feel integration.

Final: fixed held/queue and pendingUNLOAD evidence gaps — actual receipt coverage RED10→GREEN10; native500/natural947 green. Declined-to-judge: otherOwnersproduction, package completeness andHuman accepted as their responsibility; external09/07 receipts separately inspected and sources/hash/PID/rawstderr bindings audited; no03counts added. No Critical/Important findings remain within reviewed scope.
