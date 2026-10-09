# Edge Lean / Recoil Implementation Plan

> For agentic workers: execute inline using superpowers:executing-plans and test-driven-development. Owner allowlist overrides the default plan/ledger directories.

**Goal:** Weighty, interruptible edge refusal decoration with no rule or orientation mutation.
**Architecture:** `edge_lean.gd` owns admission, held-intent latch and cue lifecycle; `recoil_motion.gd` samples the return; `edge_event.gd` validates the shared DTO and resolves the formal FaceAxis in source_frame. All modules are RefCounted, no Node or Runtime ownership.
**Tech Stack:** Godot 4.7.2, GDScript, isolated PowerShell process runner.
**Spec:** ../game-feel/GAME_FEEL_CONTRACT.md at 2938d6e534f5b596bb320ce79d72b69f5923f3cd plus EDGE_LEAN_RECOIL_01 user request.

## Global Constraints

- Only the three 10B allowlist roots; no shared/frozen files, push or legacy QA/profile writes.
- Native EDGE semantic + category + unchanged REJECTED result required. No Runtime token for recoil.
- Sample position remains null. Source-world rotation is applied around the support-front edge by the sole writer 00, using a separate pivot query.
- Explicit synthetic fixture metadata; rendered Unit evidence cannot claim formal Runtime Graphical/HumanQA PASS.

## Review Focus

- Stale event after Reset/clear; retain run-scoped monotonic watermarks.
- Synchronous cue observer cancels/starts a new attempt; old cleanup cannot clear new effect.
- Late cancel from an old run/generation/attempt; full identity match only.
- Source face can have any signed-axis normal; no world-UP assumption.
- Model origin and size differ; compute pivot relative to actor center with host-supplied half extent, left-compose world rotation.

## Task 1 — sampler and contract boundary

Files: game/feel/animation/edge_recoil/{edge_event,edge_lean,recoil_motion}.gd; tests/beta_sprint/game_feel_owner_10b/{fixture,test_unit,run}.gd/ps1.
Interfaces: begin(event)->{ok,issues}; sample(elapsed)->contract sample; cancel(presentation_identity); clear(). EdgeLean adds cue(name,identity), set_intent(FaceAxis|null), support_pivot_offset(half_extent=0.5). Recoil adds support_pivot_offset with same units.

- [x] Write and run behavioral RED: explicit classification, source mapping, bottom pivot, no mutation, neutral endpoint, duplicate/held suppression, release/opposite intent, preemption, stale identity, reentrant cues.
- [x] Implement 12-degree lean (0.13s), blocked hold (0.045s), cubic ease-out return (0.265s), total 0.44s. Samples are absolute, not accumulating transforms.
- [x] Run GREEN and unchanged formal input_mapper/runtime_session regression in isolated profiles.

## Task 2 — rendered verification and integration handoff

- [x] Add private rendered sampler fixture using native mapper, formal orientation table and read-only approved model assets; four camera quadrants, Surface/Inner, six support normals, 24 orientations, actual timed motion, held/opposite/cancel cases.
- [x] Capture and inspect rendered lean/blocked/recoil/neutral images. Save raw WIP identity, process/profile/source hashes; preserve RED and failed harness runs.
- [x] Document exact 00 pivot formula, origin normalization, input rearm/preemption and cue routing. Register formal Runtime Roll/Fall integration as pending, zero checks.
- [x] Fresh-context review, necessary RED/GREEN fixes, then commit only allowlist files. Record actual delivery SHA separately from original test WIP identity.
