# Five-Level 3D Slice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans within the user's already-authorized BUILD / PARALLEL execution. Steps use checkbox syntax.

**Goal:** Deliver formally presented L04/L05 with unchanged gameplay, concurrent L06 design and a new independent five-level08 QA candidate.

**Architecture:** Batch02 presentation subclass reuses the accepted Generic/L01 runtime-observer Presenter. NativeContent/P01 remains the sole state owner; scene Script attachment selects the new renderer.06 writes design in a separate branch.00 normalmerges audited Owner histories and packages the current formalShell entry.

**Tech Stack:** Godot4.7.2, GDScript, PowerShell, Git worktrees.

**Spec:** docs/beta-sprint/five-level-3d-slice/REQUEST.md and the user's Phase3 task.

## Global Constraints

- Baseline9e2e9c29a73272d431795f12db1fefaff2433b05; Integration branch integration/foundation-4-authoring.
- ApprovedArt remains byte-frozen; no Kernel/Runtime/Foundation/Save/puzzle/hint changes. L04Inner(0,5) retained.
- New3D worktree E:/godot/worktrees/block-girl-five-level-3d, branch feat/beta-five-level-3d.
- 3DOwner owns new game/levels/mutsumi/batch_02/levels_3d/**, onlyL04/L05 .tscn Script attachments, tests/beta_sprint/five_level_3d/** and docs/beta-sprint/five-level-3d-owner/**.
-06 owns docs/beta-sprint/l06-preproduction/** and optional tests/beta_sprint/l06_preproduction/** in E:/godot/worktrees/block-girl-l06-preproduction; no production registration.
-00 owns thisplan, docs/beta-sprint/QA_CHECKPOINTS.json, docs/beta-sprint/five-level-3d-slice/** and tests/beta_sprint/five_level_3d_integration/**. Sharedfiles only if a demonstrated integration need exists.
- New build name beta_five_level_3d_20261009_01; isolated user://beta_sprint/beta_five_level_3d_20261009_01/qa_progress.json; never overwrite oldQA.
- No push/reset/rebase/squash. Normalmerge preserves Owner history. L03first-time QA may remain RETEST_PENDING without blocking.

## Review Focus

- L04Exit approach is alongZ: render approved Exit opening along native approach, preserving floor(0,5).
- L05 connection cue must follow actual graph.link.active and view.busy; no physicalbridge makes a six-cell unconnected gap appear walkable.
- Gate/plate visibility must reflect actualSurface-only pressure mechanics; Mesh transforms never influence occupancy or unlock.
- Reset during roll/camera/shift must settle visuals to native state; completedShell return/Save must remain real.
- Exact Pixel/3D parity covers per-commit native serialization,world,cubeorientation,mechanisms andGoal; P01 serialization is not Foundation StateKey.

## Tasks

### 1. Baseline and parallel ownership

- [x] Read currentIntegration9e2e9c29/CLEAN, L04/L05 actual attachments and latest08 COMPLETE result.
- [x] Create independent3D and06L06 Gitworktrees. Native app worktree returned Not a git repository because app cwd is the parent directory; Gitfallback uses verifiedactualrepo.
- [x] Dispatch independent read-only presentation/approvedAsset and QA/protection audits; dispatch06 L06 design and08 qualification through existingOwnerthreads.
- [x] Captured635frozenproduction sources,6146oldQA entries across5roots; sealed121approvedasset bindingfiles and4byte-exact08report copies. Registeredlatest fixedhotfix HumanQA checkpoint separately from historicalreceipts.

### 2. L04/L05 formal3D Owner deliverable

**Files:** new batch_02/levels_3d/presenter.gd and presented_level.gd; only two existing scene Script references; own tests/docs.
**Consumes:** accepted Presenter.bind(graph,mover,view,content),sync(delta),reset_visuals(),approvedassets and native Content state.
**Produces:** presentation factory _create_presenter()->Node3D and actual scene entries, without new Runtime semantics.

- [ ] Add meaningful presentation coverage/parity assertions; record the baseline missing L05 connection cue/incorrect L04Exit orientation before change.
- [ ] Implement batch-local asset layout and real mechanism observations, retaining inherited roll/camera/Shift/occlusion and allgameplay.
- [ ] Run real graphical normal/Reset/alternate-camera full routes for bothlevels and exact retainedPixel parity; inspect actualscreens and naturaltransition samples.
- [ ] Verify nativeGoal/Shellreturn/unlock/persistence and unchangedresource/Art/Foundation SHA; commit preciseOwner candidate/CLEAN.
- [ ] Fresh independent scope/spec/code/evidence review; repair actual defects before00 merge.

### 3.06 L06 design

- [ ] Read and review06 complete objective/mechanisms/difficulty/route/recovery design and actualcommit; no L04/L05/gameplay changes.
- [ ] Normalmerge design history when delivered; missingfutureL06implementation does not block current3D.

### 4.00 focused integration and new build

- [ ] AuditOwnerunique diff and normalbatchmerge within thisintegrationwindow. Keep mainintegration runnable.
- [ ] Focused currentL01/L02/L03 3D regressions, newL04/L05 formalmenu smokes, realunlock/Save/Continue; avoid unchangedUIresolutionmatrix repetition.
- [ ] Use existing sourcebuilder through a new00wrapper to create the namedfive-level3D QA candidate; preserve underlyingknownbaseline logs and originalpre-handoff archives. Record actualsource,1270+/actualcopiedSHA,engine,ZIP,stages and startup.
- [ ] Verify exactoldQA/frozenproduction/sourcepayload preservation, finalReview and fileSHA; commitdocs-onlyreceipt and verifyrealHEAD/CLEAN.
- [ ] Handoff exactnewsource/ZIP/receipt to08 for changed3D routes,Reset,normalprogression,ColdContinue and necessaryUIfocusedchecks. HumanQA NOT_RUN until actual08result.
