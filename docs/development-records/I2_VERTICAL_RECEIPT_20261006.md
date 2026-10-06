# I2 actual quality and graphical replay — 2026-10-06

I2_CORE_VERTICAL_PASS
CONTRACT_MISMATCH: NONE
D_JOBS receipt: 96397ea5708e0e87dd05e3d1d4c682ca0a5478b8
D_JOBS: 7836de52866255dd6f9684214b014d9703e7854d
Previous Core: 2c1c4d1b5642c3060a013cabe836fefd9c9ced7e
I2 implementation: 689ef1dd293a7525be6cb29c0bf7f5ead964a454
I1: FROZEN_PASS, unchanged
Foundation Freeze: NOT_FROZEN; I2 prerequisite is now satisfied; basic integrated Editor acceptance remains pending
Push: NOT_RUN

The D_JOBS receipt classified I2 READY_TO_RUN with missing=[], executed=false through28/28 registration checks. It was immediately followed by the actual shared I2 invocation in the same22:00 Integration window. No D_JOBS production feature or second Owner final commit was added.

## Fresh shared acceptance

`pwsh -NoProfile -File tests/foundation/authoring_integration/run_module.ps1 -Module Integration -Case I2 -Mode Graphical -EvidenceName i2_g01`

Actual352 checks, failures=[], exit0, Windows Graphical, doubles=[], stderr0 bytes. Process8868 ran22:13:45–22:15:26 Asia/Shanghai. Source identity records clean committed689ef1; formal receipts are BASE/A_BAKE/A_EDIT/C_QUALITY/D_JOBS/I_HARNESS. The dependency gate was consumed unchanged. No D_FULL or B_EDITOR prerequisite was introduced.

Evidence: `.godot/foundation-authoring-tests/i2_g01/summary.json`, identity/source-copy/run-location at the same evidence root, and `I2/project/.godot/harness-run/{results.json,process.json,stdout.log,stderr.log,i2-job-evidence.json}`. The raw formal StageResult/ArtifactRefs and worker messages remain in each immutable run directory.

| Actual case | Worker PID | Run | Result |
| --- | ---: | --- | --- |
| complete | 21812 | 390369af-411d-4002-a19a-e1f7bcf4dec6 | all10 actual stages COMPLETED, formal Replayer MATCH |
| budget | 6852 | db0e79c8-7096-4efd-8d4d-51e4e25469f6 | seven real stages, original graph/Softlock/Ablation INCOMPLETE; three trace consumers NOT_RUN |

Both workers have durable HELLO/contiguous same-run WorkerMessage sequences/actual start-result pairs/EXIT and all four observed release gates true. Budget max_states1 is sealed and preserved in native original graph and Ablation. Partial exploration cannot claim zero Softlocks, selected trace, milestone evidence or replay. Omitted stages have null native results and no fabricated STAGE_RESULT storage.

The complete chain is actual saved author source → D2 selected-job capture/sealed bytes → AUTHORING → BAKE → INTENT_BIND → INTENT_VALIDATE → ORIGINAL_GRAPH → SOFTLOCK → ABLATION → TRACE_SEMANTICS → MILESTONES → GRAPHICAL_REPLAY. Each StageResult has the exact same RunIdentity, correct producer Owner/module, formal wire, verified attachment lengths/SHA-256 and approved order. Binder/quality/replay use the same canonical/Spawn/BoundIntent/selected OriginalGraph trace. Softlock receives the live original graph inside that worker; no archival graph is restored as trusted input. Ablation retains its distinct baseline. No algorithm or verdict is copied into Integration.

## Actual Runtime mechanics and natural Tween

Approved B author profile is saved under `tests/foundation/authoring_integration/maps/b_mechanics/` as four scene/Resource files, without a map gameplay script. Required MOVE and Goal milestone are real saved Intent fields. The occluding roof has safe height4, and Inner World orientations[0,22] explicitly authorize the tested legal rotation. These are fixture authoring conditions, not Safety exceptions.

An independent formal RuntimeSession/Presenter consumes the complete job's real BAKE canonical ArtifactRef through formal read_artifact and Codec.decode. It does not share Replayer's writable Session or modify the sealed run. Canonical5198 bytes, SHA25651e236c5008330c7dc5da12ce608e584d3074e06e12e27a092a47cc8342ed8e4; level_hash0c38b9c98c30916d10aa3297d91dac0a399b370ed2e1efa64a43881de6737309.

| Actual input | Natural finished | Observed frames | Commit delta | Transition |
| --- | --- | ---: | ---: | --- |
| MOVE | true | 6 | 1 | local |
| legal Inner World rotation | true | 19 | 1 | global |
| condition-satisfied World Shift | true | 18 | 1 | global |

Real Presenter Tween.finished is observed before public finish_local/finish_global with the actual Runtime token/generation. Commit count stays unchanged during animation, then advances exactly once. No seek, forced finished signal or Session.state assignment. Formal Goal succeeds after MOVE. Reset after Goal and after rotation/Shift restores exact formal Spawn StateKey and commit_count0; Presenter follows the actual Reset. Graphical stage elapsed time is only scheduling observation, not a substitute for Tween evidence.

## Preserved preparation failures and review

Local initial test parsing/source placement attempts remain in `.godot/i2local_20261006a/`. The first B roof at height2 produced real PROVEN_UNSOLVABLE and32 Softlocks because it blocked swept MOVE clearance; raw run_d is retained. Fixture authoring was corrected to height4 and limited explicitly allowed orientations. No Safety/quality algorithm or production fix was made.

The provisional manual path attempted D3 Host.load_run on an ANALYZE_CURRENT full job. Read-only review found the legitimate input-mode and saved-only closure guard mismatch before formal acceptance. The final test uses the approved independent Runtime public APIs on the real same-run canonical; no Host gate or sealed identity was relaxed. Local run_e351 checks is preparation evidence, not added to the formal352 total. Final code adds the additional explicit unknown-budget-result assertion and saves the nonempty author Intent directly.

Independent final static review: Critical0/Important0. Its earlier natural-Tween, budget accounting and MOVE-only coverage findings were all addressed before formal execution. I1 frozen script/UID/maps have no diff. Production/Owner test files have no diff from7836. Public contracts and frozen Specs/Plans are unchanged.

Current integrated Shell Main Scene boot at689ef1 also exited0 with empty stderr and no engine errors, PID33380; evidence `.godot/foundation-authoring-tests/jf_main_boot/verified.json`. This is a runnable-branch boot check, not a repeat or replacement of the earlier full Content/Shell gameplay acceptance.

D_JOBS receipt Foundation Freeze status was WAITING_FOR_I2. I2 is now passed; Freeze is not issued before the remaining basic Editor acceptance and the sprint Freeze decision. This does not block current I2 or any independent Owner track.
