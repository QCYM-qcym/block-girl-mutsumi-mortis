# INTEGRATION_REQUEST — Owner 09 maps

To 00 / 01 / 03, for later integration; no shared changes made here.

1. 00 host loads A or B via `res://experiments/game_feel_01/maps/map_factory.gd`, uses `read_spec("a"|"b")`, then `bake(spec)` for baseline geometry. No project.godot/InputMap/main scene or shared Presenter edit is needed from 09.
2. 01 supplies an explicit versioned conversion from `spec.connection` plus baked geometry to its actual opt-in Fall schema. Current JSON is not that schema. Preserve connection IDs `pfall_a` / `pfall_b`, Surface source/TOP→target/TOP, EAST quadrant, active operation and PRESERVE orientation. Do not reinterpret ordinary MOVE 2000 as EDGE or a legal Fall. No numeric action alias is assigned by 09.
3. 01 must return authoritative path points2, path/profile identity, SAFE motion proof and deterministic target state through the shared event contract. Exact actor-center endpoints: source [0,6,0], A target [-8,2,8], B target [-8,10,8]. Source/target support clearance and the entire path remain unproven; no blanket collision exemption. Wrong camera, Inner/world mismatch, invalid target, path obstruction and BUSY must produce proper categories. If the fixed map geometry cannot support a legal continuous departure under the agreed Safety model, report the precise constraint to 09 for an owner-local map revision.
4. 00 routes real accepted motion to its shared host/Presenter and completion bridge. No 09 mock host, camera authority, fake transition or state mutation is supplied.
5. 03 may register Owner09's focused script and raw evidence. Keep the eleven listed Fall-dependent cases pending until actual dependencies are present. Run real Fall Solver/Replay and no-softlock checks then; ordinary control PASS cannot fill those rows. Current isolated headless tests do not cover new camera gating or continuous animation.
6. 08 remains WAITING_FOR_INTEGRATED_BUILD. Prior blind-play plan is only planning material; no HumanQA PASS or old QA package modification is authorized by this map delivery.

The map line can merge independently as authoring inputs. It is not playable Fall delivery and should not be listed in the accepted five-level catalog.
