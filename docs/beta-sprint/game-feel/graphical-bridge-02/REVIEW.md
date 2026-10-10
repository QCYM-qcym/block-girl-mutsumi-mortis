# Focused independent review

00 production review: current A/B Fall→Landing→Roll scope has no remaining P0/P1. Review is read-only and limited to shared Presenter/Host/Bridge. It does not confer Human QA or unrelated Camera/WorldShift trace acceptance.

Resolved findings:

- A synchronous cancellation listener could Reset/unload, after which the outer STARTED installed an obsolete motion or overwrote the inner scope. Scope is now assigned before clearing; STARTED checks epoch and current native scope after cancellation callbacks. Host state/pose continuation also rechecks captured authority.
- Direct native CANCEL advances generation without committed. After committed Landing there may be no pending interruption event. Host observes actual scope before ticking and before accepting a new event, so immediate CANCEL→Roll works in the same call stack.
- Native Reset/scene close paths now preserve RESET/UNLOAD/QUIT cancellation reasons and restore visual state before notification.

Actual reviewed evidence: cancellation67, interruption59, registered bridge19, natural core62, all PASS with empty stderr/doubles/source drift. Direct Landing CANCEL→immediate Roll uses genuine Facade actions, no Reset/await between them. Synchronous preemption observer UNLOAD cannot install an obsolete Roll.

One nonblocking P2 remains: direct `runtime.reset()` (rather than the Host's native KEY_R path) can first emit committed and clear the visual motion with cancellation label CANCEL before the later Runtime RESET interruption. Cancellation/completion remain distinct and the authoritative reset is correct. Native KEY_R records RESET correctly. Keep this diagnostic reason issue in backlog; do not reopen Runtime rules for it.

01 formal Replay WIP review found no normal A/B path P0/P1; requested stable-source verification for active driver removal/re-add, old await/callback isolation and external Bridge disposal. Signal emitter validity must be checked before disconnecting an already freed emitter. Final Owner delivery and real tests, rather than controlled Unit adapter results, determine acceptance.

Final stable-source review of Owner01 c60912b on merged source f3bd68a: no remaining P0/P1. Verified FrameRelay waking/disconnecting before driver destruction, emitter instance validity, serial/owned run isolation, true complete native identity and terminal-only step advancement, recursively read-only get_step_evidence, unchanged v1/closed options/eight result fields. Rechecked all14 delivered hashes and627 Owner checks; Root101 checks/8 matched steps confirms actual integrated path. No reviewer edits or synthetic events. Direct Facade Reset reason P2 remains separate from authoritative state and native KEY_R correctness.
