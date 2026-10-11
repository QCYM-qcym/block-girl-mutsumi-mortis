# Stage 3 — restore saved Authoring entry compatibility

Owner01. Base: a2a716734dab0a63ff8de397087665ef704337fd (Owner09 PARTIAL candidate). Worktree: E:/godot/worktrees/bg-authoring-rt02. Branch: fix/spatial-authoring-entry-02.

Authority: Coordinator00's Stage3 instruction, maps/AUTHORING_OWNER_01_EXTENSION_REQUEST.md and AUTHORING_STAGE2_HANDOFF.md. Preserve schema3 Loop/Fork, schema4 Gate/Lock/Combined, exact canonical levels/hashes and frozen witness state keys.

1. Reproduce immutable Owner09 saved migration and live typed diagnostic RED using Owner01 append-only evidence paths. Distinguish behavior failures from script/setup errors.
2. Add focused Owner01 tests for supported version tuples, closed fields, saved SceneState versus live declarations, required field types, script digest whitelist and instance override rejection.
3. Minimal production changes only in authoring_schema.gd, document_projector.gd and authoring_adapter.gd: accept the existing schema3 cubic tuple; select SceneState fields from actual version declarations; forward camera/falls for schema3/4 and gates/derived locks only for schema4. No new schema2 authoring support or new gameplay rules.
4. Run saved migration, typed diagnostics and Fork matrix against the original immutable resources/baselines. Run affected legacy Authoring negative suites and selected real Reader/Baker/Runtime/Solver/Safety/Replay compatibility checks. No GUI, large full graph rerun, old five-level content changes or overwritten Owner09 evidence.
5. Fresh whole-change review; repair actual findings with targeted RED/GREEN. Inspect allowlist, source drift, private data, resources and sizes; commit Owner01 paths only, ordinary push the one branch, independently verify exact remote SHA, hand off to00 for09/03 verification. Do not merge into playable integration.

Success is Stage3 Owner Local GREEN, not Integration, graphical, build or Human QA acceptance. Every failed attempt remains recorded. Runtime raw evidence lives under runtime/authoring_entry_02/evidence; generated profiles/negative fixtures stay ignored under .godot/ae02.
