# Non-P0 tooling backlog

These items are deferred. They do not block Owner-local development, the current daily package, or Foundation Freeze. Reclassify only if a reproducible effect meets the sprint's data/semantic/core-playability stop conditions.

| Item | Owner | Evidence / scope |
| --- | --- | --- |
| Record daily smoke wrapper/source hashes and pre/post source stability | 00 / QA | Minor review finding: current smoke records end HEAD/status and engine SHA. The final daily package separately pins 731 source files, including the executed wrappers. Improve smoke provenance for future concurrent integration writes |
| Coordinate overlapping graphical QA/build invocations | 00 / QA | Minor review finding: current wrappers rely on sequential use. Preserve all Owner-local work; consider a narrowly scoped graphical-test lock if future automation requires it. The first keyboard-route failure remains an unconfirmed interference hypothesis |
| Windows exported package | 00 / QA | P2 dependency: current worktree has no export preset and installed export templates were not found. Current SOURCE_PLAYABLE_NOT_EXE package is independently verified. Add reviewed export configuration when executable delivery is needed |

Public formats, Runtime semantics, Solver/Safety results and public API contracts are outside this backlog's change authority. See PHASE_1_REQUEST.txt for Freeze exceptions and exact stop rules.
