# Independent audio review and resolutions

Fresh read-only reviewer inspected actual WIP sources/contract/assets and ran read-only PCM validation. No files were changed by the reviewer. Review is about audio presentation correctness; not gameplay/Human QA.

Important findings, all addressed:

- Paused interruption/commit was dropped: process captured interruption immediately, stop the scoped loop, defer committed one-shot to resume; cancellation removes deferred sound. `director_review_red_02` reproduces; `director_review_green_01` passes.
- Late UI completion bypassed run lifecycle: reject captured identity after cancel/clear/retired-run/old-generation. Same RED/GREEN evidence.
- Reentrant new start could revive old whoosh, while stale cancel could suppress new whoosh: guard accepted lifecycle changes with epoch, make stale cancel scoped. `director_regression_red_01` reproduces; `director_regression_green_01` passes.
- Evidence omitted test/runner hashes: fresh runner inventory includes executed assertion script, fixture script, runner and production source/assets. Earlier retained runs preserve their original weaker inventories; final runs contain complete inventories.

Minor findings:

- Partial settings may unexpectedly unmute Master: fixed and verified in the reentrancy RED/GREEN pass; zero Master remains muted, effective settings are merged.
- Retired-run tombstones grow with loads: retained deliberately for fail-closed stale-callback rejection, documented in EVENT_MAPPING. Metadata is released on director teardown. Deferred bounded-lifetime optimization; no unbounded voice creation.

Additional final checks compare accepted target/source and local/global token on COMMITTED, exercise actual paired WAV endpoint wrapping, and use unchanged SaveStore across distinct processes. Source/assets independently reviewed against user-requested categories; no external sample or unsupported subjective-hearing claims were found.
