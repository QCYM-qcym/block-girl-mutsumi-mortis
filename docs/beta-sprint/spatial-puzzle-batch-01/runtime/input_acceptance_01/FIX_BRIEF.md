# SPATIAL-CARDINAL-01 — Owner01

Date2026-10-13. Worktree E:/godot/worktrees/block-girl-spatial-runtime-01; branch fix/spatial-cardinal-input-01; base3d6cad7f7d07c5bcb36e7fd9ab36ef40260ab2d8. Initial working tree CLEAN. Authority:00 acceptance_01 CURRENT_TASK, OWNER_SCOPE and diagnostics/OWNER_BUG_HANDOFF.

Bounded bug fix: all four fixed-view cardinal keys must address four distinct face axes and preserve opposite pairs. Generic InputMapper tie semantics and View projection are frozen. Input selection never queries road legality or alters permissions. Authoritative movement still passes through the same request_action and official Runtime/Kernel.

First prove RED using real saved Gate -> Facade, formal action prefixes and camera actions. Compare every input result with the unchanged Kernel. Then adapt only the explicit opt-in fixed-view Facade input boundary: preserve horizontal mapping; if horizontal/vertical keys collapse onto one family, select the positive screen-down perpendicular face axis for vertical keys. Non-cardinal and already independent mappings retain generic results. No new public API or gameplay algorithm.

Verify24 discrete frames x4 cameras, key uniqueness/opposites/visual signs, invalid/diagonal/magnitude input and unchanged generic behavior. Reproduce real Host/Presenter natural completion headlessly; preserve old frozen action StateKeys and all five canonical levels. Run focused generic Mapper, Runtime/Fall/Shift and saved-authoring regressions. No GUI, map or old QA edits; no claim to human input/graphical rendering acceptance.00 reruns its Host diagnostic and real UI Build.

Finish with one independent review, exact allowlist/content verification, Owner commit/ordinary push/remote-SHA query and handoff. Integration remains00-owned.
