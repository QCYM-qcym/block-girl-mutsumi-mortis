# FOUNDATION-4 D4 Worker IPC Lifecycle — Approval Record

Status: APPROVED
Recorded at: 2026-09-29T11:05:25+08:00
Authority: User explicit authorization, APPROVE EXACT CURRENT CLARIFICATION; local documentation commit only.

Clarification path: docs/development-records/FOUNDATION_4_D4_WORKER_IPC_LIFECYCLE_CLARIFICATION.md
Clarification SHA-256: C3086988452E6DFB13AFCE60196C33F9FAD69CECF38E4F5C259A08629024583B

This approval binds the exact existing bytes. The previous 63-character value ending in 24583 is invalid and is not approved. The clarification body is unchanged; its review status remains historical text, with approval expressed by this independent record.

## Approved scope

HELLO, STAGE_STARTED, HEARTBEAT, EXIT, ERROR, CANCEL and LEASE use the clarification's exact inline closed payload branches in WorkerMessage.payload_ref_or_inline. Their fields, types, enums, validation and lifecycle relations are approved as written. STAGE_RESULT remains ArtifactRef-only under its existing approved contract.

Each launch and direction has one writer and an independent sequence starting at 0. Parent begins with LEASE sequence 0; worker begins with HELLO sequence 0. Successful publication increments by exactly 1. Duplicate delivery, gap and wrong direction are protocol errors: stop-chain, revoke PASS eligibility, no gap repair or repeated execution. Ordinary polling of an unchanged consumed file is not a duplicate delivery.

HELLO/EXIT/CANCEL/LEASE stage_id is exactly the empty String. STAGE_STARTED requires a registered formal stage ID. HEARTBEAT/ERROR use the current active stage, or the empty String when none. IPC, NONE, null and other aliases are not substitutes.

The approved draft's continuous lease backlog validation and delayed in-flight STAGE_STARTED cancellation handling remain binding. They preserve cancellation and never restore PASS eligibility. Restart and planned process handoff follow the exact clarification rules.

Single heavy slot; BUSY does not queue. Cancellation enters CANCELLING, not immediate CANCELLED. Synchronous formal calls may return naturally. No forced kill or bounded reclamation guarantee. Lease renewal is 1000ms; valid_for_ms is 30000. Lease loss stops work at the next checkable boundary. EXIT alone cannot release the slot: actual process exit, file handles closed, callbacks disconnected and preview/resources released must all be confirmed.

## Impact and limits

D_PROTOCOL: UPDATE_REQUIRED
D_JOBS: IMPLEMENTATION_REQUIRED
foundationworkeripc.v1: UNCHANGED
WorkerMessage common envelope: UNCHANGED
STAGE_RESULT: UNCHANGED
Stage Result schema: UNCHANGED
B_EDITOR: WAIT_FOR_D_JOBS
I1: FROZEN_PASS
I1 commit: 14936504ae4245cc1822786937f021afce4a7fd9
I2: WAIT_FOR_A_EDIT_AND_D_JOBS

TRACK_A approval: 21c23df2ac549a6c998cd2a3604ff55c2f891684
TRACK_A clarification SHA-256: E1DF9D6DA305C764BFFC53CB930EF7149A8EF734BB2585E10D2AECA69137CDEE
Next implementation: CONSOLIDATED_D_PROTOCOL_UPDATE

One consolidated protocol update must consume both approved tracks; do not start competing source-intent and lifecycle protocol implementation worktrees. This record neither implements nor registers protocol capabilities. Non-BAKE native storage branches remain subject to the separate schema boundaries recorded in the clarification.

This turn changes only the Track D clarification's Git registration and this approval record. No Owner source, receipts, case manifest, frozen Spec/Plans or I1 files are changed. No implementation starts. A_EDIT and D_JOBS remain NOT_DELIVERED; I2 remains NOT_STARTED. Product tests: NOT_RUN (documentation-only approval). Push: NOT_RUN.
