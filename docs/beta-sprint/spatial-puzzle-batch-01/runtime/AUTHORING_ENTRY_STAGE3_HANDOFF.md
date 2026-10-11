# Stage3 — Saved Authoring entry Owner handoff

Task: SPATIAL_PUZZLE_BATCH_01_FULL_DEVELOPMENT / Stage3 / Owner01 Runtime.

Worktree: E:/godot/worktrees/bg-authoring-rt02. Branch: fix/spatial-authoring-entry-02. Base: a2a716734dab0a63ff8de397087665ef704337fd (Owner09 saved-authoring PARTIAL candidate, itself descending from Integration baseline088d4ba815884a431f44e73d93cfb6881ff7faa3).

Stage Status: OWNER_LOCAL_GREEN; Integration: PENDING_00. No GUI, build or Human QA claim. Commit and independently verified remote SHA are supplied in the delivery message; a report cannot contain its own future commit SHA.

## Implementation

Only three production entrance files changed. AuthoringSchema selects the already approved schema3/4 camera/falls fields, requires the exact existing contract/rule/orientation tuples, and permits gates only for schema4. DocumentProjector reads the closed property set using actual stored version declarations. Adapter forwards camera/falls for3/4 and gates plus derived locks only for4.

Public method shapes, gameplay contracts, saved maps, stable UUIDs, curves, permissions and all production Kernel/Runtime/Safety/Solver/Replay algorithms remain unchanged. The real saved entry never falls back to live nodes, another map factory or a direct Baker call. Closed-field, unknown-version/type, digest-whitelist and instance-override rejection are preserved. No typed schema2 support is added.

## TDD and final tests

Real behavior RED on exact09 base: saved_red01 15 checks/10 failures; typed_red01 156/2; entry_red01 99/14. These are ordinary exit1 assertion failures, not parser/setup errors; stderr empty. Evidence is append-only in Owner01 runtime/authoring_entry_02/evidence, never in09 frozen evidence.

Final suite: **901/901 checks PASS**, eight runs, all exit0, stderr empty, failures=[], doubles=[], source_drift=[]. All final runs record the same SHA256 for the three shipped production files, the engine, their public test entrypoints and every protected map/Foundation source. Their actual command lines, isolated profiles, PID and UTC timestamps are in process.json.

| Evidence case | checks | exit | stderr | source drift |
|---|---:|---:|---|---|
| entry_final01 | 99/99 | 0 | empty | [] |
| saved_final01 | 236/236 | 0 | empty | [] |
| typed_final01 | 264/264 | 0 | empty | [] |
| fork_final01 | 37/37 | 0 | empty | [] |
| consumers_final01 | 37/37 | 0 | empty | [] |
| docs_final01 | 110/110 | 0 | empty | [] |
| bake_final01 | 105/105 | 0 | empty | [] |
| typed_reg_final01 | 13/13 | 0 | empty | [] |

Commands: `python tests/beta_sprint/spatial_owner_01/run_authoring_entry.py <case> <res://script>`; exact script/arguments in each process.json. Actual engine: Godot4.7.2.stable.steam.ed1daf0bf, D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe. Headless only, CREATE_NO_WINDOW, isolated APPDATA/LOCALAPPDATA/TEMP/TMP. Normal `--quit-after5000` guard; asynchronous selected consumer test also has a60-second normal-exit guard. No force-kill in the runner.

The immutable09 migration test verifies complete canonical equality against frozen .gdvar oracles, all witness Action/status/StateKey/orientation steps, Reset and exact real SourceMap UUID/resource/node provenance for all five levels. Typed diagnostics stay labeled diagnostics and do not replace the saved entry. Fork matrix exercises all four Cameras, real directed branches, Reset and rejected cross-world/unwalkable/overlapping declarations.

Selected formal consumers use the real saved Maps.bake result. All five formal canonical Codec and initial Safety checks pass. Gate/Fork call actual FIRST_SHORTEST Explorer, actual SolutionTrace semantic Kernel validation and actual Safety; Gate solution3 actions, Fork2 actions. Each real logical RuntimeSession Replayer is run twice and returns MATCH with exact Goal StateKey. No fake traces, graph, Kernel or legality doubles. This is logical evidence, not graphical Tween evidence.

Affected legacy suites are unchanged: authoring documents110, bake105, existing spatial typed authoring13. Initial docs_reg01 had4/110 persistence failures because temporary resources were written beneath res://, acquiring an authoritative evidence URI. A single test-runner change uses the isolated user:// profile, preserving the old suite's intended original document URI. docs_reg02 and docs_final01 then passed110/110 with identical production and assertions. The failure is preserved as FAILED; not called a historical gameplay bug. Generated persistence scenes/resources remain ignored diagnostics, never new production authoring inputs.

## Exact canonical identities

All five complete levels equal the frozen pre-migration baseline. Versions are preserved; no forced schema upgrade.

| Level | schema | content_hash |
|---|---:|---|
| world_shift_gate_lab | 4 | `7a636b38301dff74027b2d5e80364d30b943b24f961cd73a2179b9ee7798acd4` |
| orientation_loop_lab | 3 | `45bc655f778ae214e8ca830c4e8be59b618b2b854c808f3741d4e6f277d56a70` |
| face_lock_lab | 4 | `8bcd1b0708c8dca145ea67e5559e216745135c0a34bac41f16f99b1167a7e1e5` |
| perspective_fork_lab | 3 | `8b485492113fec9f1ee74d347b88d31a6012f50359b97f9d26fee4c1e603054a` |
| rubik_spatial_puzzle_01 | 4 | `5b4de9ca172f39ea537ceb00f3f56074d83f136cc768c66b9f4669764187d2c8` |

## Boundaries / pending

- No changes to Owner09 assets, immutable migration_baseline, tests, evidence or handoff; no03/07/00 files changed; L01–L05 and previous QA untouched.
- No algorithm rewritten or copied; no public contract or Host/Presenter/project/InputMap changes.
- NOT_RUN: full Combined graph, large old matrices, graphical replay, build and Human QA. Current whole-canonical/witness equality permits referencing the original Combined908states/3916edges result as historical only, never a fresh graph run.
- Next:00 receives the exact commit;09 performs its own saved-authoring revalidation, then03 adapts the removed old Maps.authoring call sites and starts focused Quality. Integration merge/playable replacement is00's responsibility.
- Ordinary Push is only to fix/spatial-authoring-entry-02, never main/shared Integration; no PR/tag/force/rebase.

## Recorded decisions

1. Native worktree creation was unavailable from chat's repository-parent cwd; authorized Git fallback created only the new Owner branch. Cost if wrong: native app attachment absent.
2. Shorter worktree path plus per-command core.longpaths avoided Windows checkout path limits; no global Git config changed. Cost if wrong: future longer evidence paths still need scrutiny.
3. Restore existing typed3/4 only and retain schema2 rejection. Cost if wrong: any future schema2 request needs a separate authorized extension.
4. Use isolated user:// for old persistence fixtures, retain both failing and passing evidence. Cost if wrong: temporary URI semantics would need renewed provenance investigation; no production fallback introduced.

Review result and exact file hashes are recorded alongside this handoff. Push/remote status is reported after the real command, never inferred from CLEAN.

Final housekeeping removed only this run's generated Python bytecode cache. It had been included in final before/after fingerprints and was stable during tests; its removal is not a source change. All delivered source fingerprints still match final evidence. The inherited legacy Harness fingerprint gap remains the review's deferred Minor; the Harness itself is unchanged from baseline.

Runtime evidence logs use scoped Git attributes to retain exact raw output bytes (including the engine's CRLF and trailing blank line), rather than rewrite captured process output for source whitespace lint.
