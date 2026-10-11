# Spatial Batch 01 Full Development — incremental completion plan

> **For agentic workers:** Use superpowers:executing-plans for ordered integration; delegate only disjoint Owner scopes after their input gates pass.

**Goal:** Deliver the four existing spatial mechanisms and Rubik experiment through formal author resources, complete required feedback/audio, and publish verified Owner and integration branches with an immutable playable build.
**Architecture:** Retain the existing opt-in Runtime, Baker, Solver, Safety, Replay and natural Presenter. Replace executable map construction with formal author documents while preserving canonical gameplay data. Host consumes formal results for feedback and existing AudioDirector for sound.
**Tech Stack:** Godot 4.7.2, GDScript, Python evidence runners, Git worktrees.
**Spec:** User attachment f7239509-4492-4b85-9344-7be57c0f78a3; existing docs/beta-sprint/spatial-puzzle-batch-01/CONTRACT.md retained where compatible.

## Global Constraints
- Strict dependency gates: 13 Design → 09 Map → 01 Runtime → 03 Quality → 00 final Integration → 08 Human QA. Existing verified deliveries may satisfy gates after identity/scope verification. Independent support audits may run concurrently.
- No main/Release Tag/L01–L05/frozen Art/SaveStore changes. No fabricated human or graphical evidence. Old builds and evidence remain immutable.
- Every new Owner stage commits, ordinary-pushes its own branch, verifies remote SHA, and hands off exact scope. Never use dirty worktrees or rewrite shared history.
- No gameplay decision in UI, animations, or level-specific scripts. Formal Runtime remains authoritative.

## Review Focus
1. Resource migration preserves canonical maps, typed face/anchor identities, StateKey, witness routes and recoverable Fork branch.
2. Wrong-face arrival remains accepted movement without latch; repeat latch and Reset do not produce duplicate feedback.
3. Audio observes committed state and actual Fall lifecycle; interrupted/old callbacks cannot emit Landing or lock success.
4. Save/Continue restores the documented level start without inventing mid-animation state or a second persistence system.
5. New package imports, audio paths and F5 entry work with isolated user data; old five-level content/QA remains unchanged.

### Stage 1 — Design gate (13)
- [ ] Reuse the existing three design notes; publish a spec covering goal/input/state/failure/teaching/example/composition for all four mechanisms on a clean design branch.
- [ ] Validate document links/content and source provenance; commit, push, verify SHA. Keep old dirty design tree untouched.

### Stage 2 — Formal author maps (09)
**Scope:** experiments/spatial_puzzle_batch_01/maps/**; tests/beta_sprint/spatial_owner_09/**; maps delivery documents.
**Consumes:** confirmed Design spec and existing foundation/authoring/{document_projector,payload_assembler,authoring_adapter}.gd; formal Authoring nodes/resources.
**Produces:** same map_factory ids/bake/describe/witnesses API backed by saved author resources, not conditional geometry construction.
- [ ] Prove existing topology/state/path baselines; add a failing resource-backed load/provenance check.
- [ ] Store the five lab maps with formal author resources and bake through the real authoring adapter; preserve gameplay data and metadata separation.
- [ ] Verify canonical parity, all requested witnesses, invalid Camera and source provenance. Publish exact delivery.

### Stage 3 — Runtime gate (01)
**Scope:** existing spatial Owner01 tests/report; production only for an established missing formal interface.
- [ ] Verify delivered author resources traverse existing Reader/Baker/Runtime/Solver/Safety/Replay with current formal opt-in semantics.
- [ ] Resolve only proven contract/behavior gaps with scoped RED/GREEN; otherwise publish a measured no-production-change receipt.

### Supporting presentation after dependency readiness
- [ ] 05 reuse existing research; no new Art replacement or main edits.
- [ ] 11 verify/reuse AudioDirector and approved cues; add only necessary Face Lock consumer API/tests if absent. Publish before 00 wiring.
- [ ] 07 verify runtime-derived Gate/Lock/Fork feedback; no local eligibility logic. 10A/10B reuse verified motion and cancellation contract.
- [ ] 00 changes only spatial Host/audio routing and its tests; covers actual commit/dedupe/reset/unload/pause and no state mutation.

### Stage 4 — Independent Quality gate (03)
- [ ] On the exact staged source, verify matrix requirements including Loop Save semantics and all four mechanism positive/negative cases, full Rubik route, Solver/Safety/Logical Replay, real natural and formal graphical Replay.
- [ ] Reuse identity-matched prior evidence for unchanged expensive graphs; keep unexecuted scopes explicit. Publish clean Owner branch and remote SHA.

### Stage 5 — Integration / package (00)
- [ ] Review and merge only Owner-approved diffs; targeted production review; affected regression and audio/UI checks.
- [ ] Commit and push verified integration source; generate a fresh unique build via tests/beta_sprint/spatial_integration/package.py, never overwrite old package.
- [ ] Execute real package F5/main entry, menu labs, new feedback/audio and affected save/reset lifecycle checks. Record engine/source/hash, exact build path and known issues.

### Stage 6 — QA handoff
- [ ] Give08 the immutable new Build and evidence; Human QA stays NOT_RUN unless an eligible human actually tests.
- [ ] Final report separates all Owner status and verification layers; push final receipt and independently verify remote SHA.
