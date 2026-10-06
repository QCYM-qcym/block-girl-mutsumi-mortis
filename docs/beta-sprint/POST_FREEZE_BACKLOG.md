# Post-Freeze backlog

Foundation Core is FROZEN_FOR_BETA under [the current Freeze Decision](FOUNDATION_4_CORE_FREEZE_20261006.md). Deferred tooling does not block Level production, 3D integration, Shell, QA or Beta builds. D5/D6 implementation remains post-Beta unless a reproduced level-production blocker meets the explicit P0/P1 reopening rule in that decision.

| ID | Owner | Deferred scope | Priority / reopening condition |
| --- | --- | --- | --- |
| F4-D5 | 01 Runtime | Analyze Current live/unsaved capture | POST_BETA; only reopen for a real Beta level-production blocker |
| F4-D6 | 01 Runtime | Archive / formal report delivery, full Accept Saved ARCHIVE path | POST_BETA; only reopen for a real Beta level-production blocker |
| F4-EDITOR | 04 Editor | Full report UI, advanced error presentation, authoring polish | POST_BETA; full acceptance remains NOT_ACHIEVED |

The minimal 4B-local disable/unavailable-label guard is a bounded UX safeguard. It does not deliver any backlog capability. Original Editor47/8 failures remain recorded as failed full-acceptance evidence.

| Item | Owner | Evidence / scope |
| --- | --- | --- |
| Record daily smoke wrapper/source hashes and pre/post source stability | 00 / QA | Minor review finding: current smoke records end HEAD/status and engine SHA. The final daily package separately pins 731 source files, including the executed wrappers. Improve smoke provenance for future concurrent integration writes |
| Coordinate overlapping graphical QA/build invocations | 00 / QA | Minor review finding: current wrappers rely on sequential use. Preserve all Owner-local work; consider a narrowly scoped graphical-test lock if future automation requires it. The first keyboard-route failure remains an unconfirmed interference hypothesis |
| Windows exported package | 00 / QA | P2 dependency: current worktree has no export preset and installed export templates were not found. Current SOURCE_PLAYABLE_NOT_EXE package is independently verified. Add reviewed export configuration when executable delivery is needed |

Public formats, Runtime semantics, Solver/Safety results and public API contracts are outside this backlog's change authority. The latest Freeze Decision permits only reproduced P0/P1 correctness or Beta production/playability blockers to reopen the affected Foundation Owner scope; it supersedes the earlier Phase1 Freeze prerequisites.
