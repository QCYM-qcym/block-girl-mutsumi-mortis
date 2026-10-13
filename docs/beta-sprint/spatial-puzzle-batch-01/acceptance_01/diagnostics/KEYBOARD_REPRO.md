# Real keyboard reproduction ledger

Immutable old Build source59531adcdffb7a8671bd6aab9a2abdc6fa830b04;00 production baseline unchanged during RED. Test main-menu scene, mouse selection and Input.parse_input_event keyboard; formal action prefixes only establish four real positions. No private state or completion injection, no doubles, isolated profiles.

acc_keys_red01:3checks; test harness failed menu entry because root viewport scale was not disabled. Not a Gameplay conclusion. acc_keys_red02:612checks; mapping failures plus incorrect one-event counting (STARTED and COMMITTED both counted). acc_keys_red03:564checks; correction omitted REJECTED event phase. Not accepted as final count. Raw failures preserved.

acc_keys_red04:612checks,12 targeted assertion failures,exit1,stderr consists of those assertions720bytes,doubles[],source_drift[].64 actual keyboard attempts:Surface source/gate andInner gate/Goal x4Camera x4WASD.8 direction-bijection failures occur atNORTH/EAST acrossall4positions;4 no-legal-direction failures atbothInnerpositions/NORTH+EAST. Surface retainssomeallowedmovementbutcannotexpressallaxes. This matchesreported two-world directional loss; not everySurfacekey is immobile. Runtime rejects nonexistentedge withcode2000. Testrecords real states/transitions; rawlogs are not stripped.

Old first gate_probe has8ObjectDB exit warnings (P2 lifecycle signal),not cleanPASS. The menu-owned keyboard run usesactual UI scene cleanup andhasnoObjectDBwarning. These observations do not prove a production lifecyclefix.

GUI stillreserved byuseractivelyplaying;headless keyboard tests neverbecomeGraphical/HumanPASS. Oldplayerprocessandprofile untouched. Entry-script hash is nowexplicitly includedby00runner because this diagnostic livesoutside priorfixedsource roots.
