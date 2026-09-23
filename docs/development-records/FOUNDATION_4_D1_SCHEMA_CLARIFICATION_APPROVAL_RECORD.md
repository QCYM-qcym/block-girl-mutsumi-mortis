# FOUNDATION-4 D1 Schema Approval Record

status = D1_SCHEMA_CLARIFICATION_APPROVED

Recorded at: 2026-09-23T20:02:27.321319+08:00

Approved document: `docs/development-records/FOUNDATION_4_D1_SCHEMA_CLARIFICATION.md`

Approved SHA-256: `93E0A52F524DAD19925F477B31F8DA12DB2DCEB52CBA81EF78C1B730DB01E79C`

Authority: user's explicit hash-bound approval in this task on 2026-09-23. The approved document remains byte-for-byte unchanged, including its historical proposal status; this separate record supplies the effective approval. Original frozen Specs and five plans remain unchanged.

## Explicit rulings superseding the preceding conditional request

1. EngineIdentity has exactly `version:String` and `executable_sha256:Digest`. Executable path is local launch/diagnostic metadata, outside VersionsRecord and its wire/digest.
2. execution_digest is the SHA-256 of the complete canonical VersionsRecord foundationtoolwire.v1 wire. All canonical fields participate. No second projection or parallel versions identity algorithm is authorized.
3. source_manifest has no embedded manifest_version. Its identity is foundationtoolwire.v1 + source_manifest kind, bound to the frozen schema registry and VersionsRecord.schemas. Future changes require formal schema versioning.

The approved seven-field VersionsRecord and four kinds versions/source_manifest/input_manifest/archive_manifest, closed nested records, ordering, nullability, path rules and acyclic references are binding. ArtifactRef retains its four approved fields. The approval does not expand other public contracts.

## Execution scope

4D may continue existing 4D-1 in its Owner worktree, preserving the ten current files and original test intents; complete RED/GREEN and D1 review. Only after all D1 gates pass and no Important/Critical review findings remain may the ten-file D_PROTOCOL delivery be locally committed. No push and no I1.

4D alone owns wire/schema/digest. 4A owns authoring/source_map values; 4C public run_quality/QualityRunResult stay unchanged; 4B does not interpret or generate product manifests. Existing LevelCodec, StateKey, Solver and Runtime rules remain unchanged.

Existing receipt 01969fed0110ac594fce857d63a438a2a0fc9f67 remains available to 4A A2 and 4B B1 Unit independently. 4C remains DEPENDENCY_PENDING: D_PROTOCOL until a formal new receipt is registered; this approval is not that delivery receipt.
