# Historical 814a sealed-manifest rejection fixture

This input.ready is an exact archived copy from the actual 8289 D_SAVED delivery's 814a-protocol run, not a current run edited to look historical.

SHA-256: 134c9495d5d38345c8b9ddf9f7b5cc06d84c5825fca07e22408ec354589cb2ed
Original run evidence: E:/godot/worktrees/block-girl-foundation-runtime-saved-closure/.godot/foundation-authoring-tests/4d_dsaved_source_intent_green_real_20260929/4D-2/project/.godot/foundation-authoring/runs/31505727-9c6b-4d7f-8811-40deb921d6a0
Original delivery metadata: .godot/dsaved-source-intent-delivery/delivery.json in the D_SAVED Owner worktree.
Protocol: 814a1d7264140eec44a6b32752166832beb8ce75
D_SAVED delivery: 8289d804c3b5b42a2e6c2cf76e965679a0f83af8

Only the exact sealed manifest is archived. This is a rejection fixture, not a complete executable input package. Current 8f7 schema validation must reject it before accessing omitted attachments. The test checks the historical schema lacks all four mandatory new registry keys, formal decode and snapshot reconstruction reject identically with WIRE_SCHEMA_INVALID, and input.ready bytes remain unchanged.

An explicit FOUNDATION_D2_LEGACY_RUN still selects external evidence and must pass the same exact SHA checks. Without that variable, the committed fixture is used. Missing or altered fixture is a failure, never a skip or automatic pass.