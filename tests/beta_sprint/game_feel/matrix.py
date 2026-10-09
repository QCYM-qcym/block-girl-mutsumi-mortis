"""03 registered test inventory, bound to game_feel.event.v1; no capability receipts yet."""

import argparse
import json
from pathlib import Path

INPUTS = ("held_wasd", "edge_spam", "reverse", "camera_qe", "mouse_drag",
          "space", "reset", "pause", "exit_level")
PHASES = ("fall", "landing", "edge_recoil")
CONTRACT_COMMIT = "2938d6e534f5b596bb320ce79d72b69f5923f3cd"
CONTRACT_SHA256 = "6224f8cd364f98da41822eabe7ba2973fa2db01d030373e7b3e94d69f35f23de"


def cases():
    rows = []

    def add(case_id, area, dependencies, setup, action, expected, evidence,
            mode="REAL", scope="new_owner_delivery"):
        rows.append(dict(id=case_id, area=area, mode=mode, scope=scope,
                         dependencies=dependencies.split(), setup=setup,
                         action=action, expected=expected, evidence=evidence,
                         status="case_pending", checks=0, source_sha=None,
                         delivery_sha=None, doubles=[], authoritative_runtime=None))
        if scope == "CORE_PLAYABLE":
            rows[-1]["registration_requirements"] = ["CORE_PLAYABLE_RECEIPT"]

    core_dependencies = "RUNTIME_FALL AUTHOR_CONNECTION FALL_LANDING HOST_NATIVE_INPUT"
    for map_id, height, target in (("a", "lower", [-8, 2, 8]), ("b", "higher", [-8, 10, 8])):
        add("CORE_" + map_id.upper() + "_NATURAL_FALL", "Runtime", core_dependencies,
            f"Owner09 pfall_{map_id}; Surface TOP; actual target {height}; source actor center2 [0,6,0], target {target}",
            "Registered native input sequence in actual 00 CORE_PLAYABLE host, EAST then explicit departure",
            "Real STARTED→natural Presenter→native finish bridge→one COMMITTED→settled Landing; exact target/PRESERVE, visible continuous descent",
            ["00 registered binding/receipt", "01/09/10A actual delivery commits", "native input", "event/result snapshots", "actor/camera trajectory", "commit count"], "GRAPHICAL", "CORE_PLAYABLE")
    for name, action, expected in (
        ("CAMERA_REJECT", "Try each of three forbidden quadrants", "CAMERA_NOT_ALLOWED; unchanged full state and body; no accepted Fall"),
        ("NO_CONNECTION", "Use official no-author-connection fixture", "FALL_NOT_AVAILABLE; no Runtime transition or decorative Fall"),
        ("CROSS_WORLD", "Request Surface connection from Inner", "WORLD_NOT_ALLOWED; do not reinterpret as EDGE"),
        ("CONSECUTIVE_FALL", "Two authorized Fall runs using actual Reset/reload between runs", "Unique identities; exactly one natural commit per accepted run; no stale callback"),
        ("LANDING_NEXT_MOVE", "Land then issue next legal native movement", "Landing neutral endpoint, physical orientation preserved, subsequent input accepted"),
        ("RESET_INPUT", "Reset in flight; then new native movement/Fall", "Old identity invalidated; no old commit/landing; new input/effect remains usable"),
        ("HELD_REVERSE_BUSY", "Held/repeated/opposite movement, Q/E/drag/Space during flight", "BUSY preserves captured camera/path/token and prevents overlapping motion"),
        ("STATEKEY", "Compare full canonical state/key before and after actual natural completion", "Official versioned StateKey and Orientation exactly match authorized result"),
        ("SAFETY_SOLVER_REPLAY", "Real swept Safety negatives, formal Solver witness and native Runtime Replay", "Real version dispatch and semantic validation; no fabricated edges or state writes"),
        ("ORDINARY_CONTROLS", "Native ordinary Roll and original authored PerspectiveConnection control", "Original production permissions/physical pose/commit behavior unchanged; distinguish P01 observation identity from formal StateKey"),
    ):
        add("CORE_" + name, "Solver" if name == "SAFETY_SOLVER_REPLAY" else "Runtime",
            core_dependencies + (" SOLVER REPLAY SAFETY" if name == "SAFETY_SOLVER_REPLAY" else ""),
            "Actual default pipeline / official fixture and exact registered Build identity", action, expected,
            ["actual delivery/binding source SHA", "native inputs", "formal result/key/trace", "body/phase observations", "raw logs"],
            "GRAPHICAL", "CORE_PLAYABLE")

    for semantic, reason in (("MOVE_APPLIED_NORMAL", "NONE"), ("MOVE_REJECTED_EDGE", "EDGE"),
                             ("ACTION_FEEDBACK", "MECHANISM_LOCKED"), ("ACTION_FEEDBACK", "BUSY"),
                             ("ACTION_FEEDBACK", "INVALID_FACE"), ("ACTION_FEEDBACK", "SAFETY_REJECTED"),
                             ("ACTION_FEEDBACK", "INVALID_ACTION"), ("ACTION_FEEDBACK", "UNCLASSIFIED_REJECTION")):
        add("G_EVENT_" + reason, "Runtime", "RUNTIME_EVENT_PORT HOST_NATIVE_INPUT",
            "Real authored fixture with explicit native result/reason", "Request action through actual default Runtime/native input",
            f"Authoritative {semantic}/{reason}; preserve original status/code/issues; MOVE_BLOCKED alone never implies EDGE",
            ["immutable game_feel.event.v1 snapshots", "native result", "input and identities", "canonical before/after"])

    for height in ("lower", "higher"):
        for world in ("Surface", "Inner"):
            add(f"G_FALL_{height.upper()}_{world.upper()}", "Runtime",
                "RUNTIME_FALL AUTHOR_CONNECTION SAFETY",
                f"Real authored {world} connection, actual target height {height}, permitted view",
                "Explicit departure input; wait for stable completion",
                "Accepted exactly once; canonical target, world, Face and Orientation match Runtime",
                ["author resource/hash", "actual source/target heights", "view", "permission", "transition and commit signals", "full canonical before/after"])
    for defect in ("invalid_view", "invalid_landing", "no_connection",
                   "swept_obstacle", "unknown_safety", "wrong_world"):
        add("G_REJECT_" + defect.upper(), "Runtime", "RUNTIME_FALL AUTHOR_CONNECTION SAFETY",
            "Owner-authored negative fixture: " + defect, "Request Fall through official action interface",
            "Explicit rejection reason, zero accepted transitions and zero commits; entire canonical state unchanged",
            ["negative author resource/hash", "request and rejection", "safety result", "canonical before/after"])
    add("G_NO_AUTO_FALL", "Runtime", "RUNTIME_FALL AUTHOR_CONNECTION",
        "Valid connection and view, idle actor at departure", "No departure input",
        "No automatic Fall, no transition or commit", ["idle observation duration", "signals", "canonical states"])
    add("G_WORLD_PERMISSIONS", "Runtime", "RUNTIME_FALL AUTHOR_CONNECTION",
        "Separate legal and illegal Surface/Inner connection permissions",
        "Try each connection from both worlds", "Author permissions govern; no blanket Inner prohibition",
        ["four permission cases", "author config", "rejections and commits"])
    for index in range(3):
        add(f"G_FALL_FORBIDDEN_QUADRANT_{index + 1}", "Runtime", "RUNTIME_FALL AUTHOR_CONNECTION",
            f"Excluded author quadrant #{index + 1}; actual quadrant bound from delivered author data",
            "Explicit Fall attempt", "CAMERA_NOT_ALLOWED, no accepted motion/commit, canonical state unchanged",
            ["allowed/excluded author quadrants", "captured authoritative camera", "feedback and full state"])
    add("G_CUBE24_ENDPOINTS", "Runtime", "RUNTIME_FALL AUTHOR_CONNECTION SAFETY",
        "24 actual cube24.v1 source orientations", "Run authorized Fall and Landing for each orientation",
        "PRESERVE policy: source/target/final IDs identical, exact canonical endpoint and StateKey",
        ["24 source/target/COMMITTED orientation IDs", "formal math pose", "state/key evidence"])

    for phase in PHASES:
        phase_dependencies = core_dependencies if phase != "edge_recoil" else "RUNTIME_EVENT_PORT EDGE_RECOIL HOST_NATIVE_INPUT"
        add("A_POSE_" + phase.upper(), "Animation", phase_dependencies,
            "Official transition/path and actor model", "Sample start, contact, end and settled frame",
            "Fall start/end match Runtime; Landing ends at exact orientation; Recoil preserves position/orientation",
            ["timestamped Runtime and model poses", "canonical Face/Orientation", "transition IDs", "settled frame"], "GRAPHICAL")
        for input_id in INPUTS:
            add(f"A_INPUT_{phase.upper()}_{input_id.upper()}", "Animation",
                phase_dependencies,
                f"Reach {phase} using real input; instrument actual signals and model",
                input_id,
                "Follow delivered interruption policy; no overlapping transitions, stale commits, leaked Tween, orientation drift, wrong Face or stuck input; audio evaluated separately when its delivery exists",
                ["timestamped input/phase log", "all accepted/committed IDs and generations", "model poses", "owned Tween/VFX counts", "audio events", "next legal input result"], "GRAPHICAL")
    add("A_REPEAT_100", "Animation", "RUNTIME_FALL ANIMATION AUDIO_UI",
        "Resettable official Fall/Recoil fixture", "100 complete cycles with mixed input interruptions",
        "No accumulated rotation error, stale callbacks, orphan effects or input lock",
        ["per-cycle canonical/model poses", "owned object counts", "script log", "cue counts"], "GRAPHICAL")
    add("A_SIX_VISIBLE_FACES", "Animation", "RUNTIME_EVENT_PORT ANIMATION ART HOST_NATIVE_INPUT",
        "Formal pose cases exposing all six marked-face directions", "Play ordinary Roll and new motions",
        "Rendered physical marker agrees with formal math; support face is never mistaken for painted face",
        ["six screenshots", "formal Orientation and physical face direction", "model transforms"], "GRAPHICAL")
    add("A_CANCEL_LATE_NEW_LAUNCH", "Animation", "RUNTIME_EVENT_PORT ANIMATION AUDIO_UI HOST_NATIVE_INPUT",
        "Active old motion then Reset/reload/unload/cancel and a new launch",
        "Deliver late old sample/tween/audio/completion callbacks in separate expected-failure probe",
        "Full captured identity invalidated; old cleanup cannot clear new effect; no stale commit/Landing/Goal/Save",
        ["old/new full identities", "cancel and callback log", "new effect sample", "state/Save deltas"], "GRAPHICAL")
    add("A_PAUSE_IDENTITY", "Animation", "RUNTIME_EVENT_PORT ANIMATION AUDIO_UI HOST_NATIVE_INPUT",
        "Each active Fall/Landing/Recoil effect", "Pause then resume; lose focus and end drag",
        "Elapsed motion/audio suspended; same token resumes; held input clears; no artificial EDGE/cancel/Landing",
        ["elapsed and full identity samples", "audio playback pause", "native focus/input events"], "GRAPHICAL")

    for case_id, setup, action, expected, evidence in (
        ("ART_GLB", "Delivered GLB files in clean worktree", "Fresh Godot import, instantiate every referenced model", "Real imported PackedScene/mesh/material resources; no missing refs or errors", ["engine/version", "GLB and import hashes", "import log", "instantiated resources", "screenshot"]),
        ("ART_SHADER", "All delivered Fall/Landing/Recoil VFX and materials", "Render all stages in actual target renderer", "No shader/script errors, missing textures or invisible required effects", ["renderer", "complete stderr", "per-stage captures"]),
        ("ART_VFX", "Each VFX with actual lifecycle", "Finish, Reset, Pause/resume and leave level", "Owned particles/effects stop or free according to policy; no residue after teardown", ["owned nodes/particles before/during/after", "weak reference after exit", "video"]),
        ("PERF_SOAK", "Official fixture and device/renderer/settings", "30 minute graphical session with repeated transitions", "No errors or progressive memory/object/Tween growth; input remains usable", ["duration", "frame samples", "memory/object trend", "log", "last legal input"]),
        ("PERF_PHASES", "Same scene/hardware/resolution and warm cache for comparison", "Measure idle, departure, Fall, contact, Landing, Recoil and load separately", "Report p50/p95/p99/max milliseconds by phase and sample counts; judge only delivered budget", ["raw timestamped phase/frame samples", "render config", "owner performance budget", "baseline and candidate SHAs"]),
        ("PERF_L04_LOAD", "L04 only once formally in integrated catalog", "Capture cold/warm loading separately from animations", "Historical loading minimum 9 FPS remains a loading observation; no unsupported attribution to new Fall", ["load boundaries", "L04 identity/hash", "animation phase boundaries", "separate distributions"]),
    ):
        add(case_id, "Graphical", "ART ANIMATION INTEGRATED_CONTENT", setup, action, expected, evidence, "GRAPHICAL")

    for case_id, setup, action, expected, evidence in (
        ("AU_EVENTS", "Delivered event-to-cue mapping", "One Fall/Landing/Recoil plus held/spammed inputs", "Cue multiplicity matches actual accepted transition/contact/rejection policy, no input-repeat spam", ["cue policy", "input/transition/contact/cue timestamps and IDs"]),
        ("AU_CONTACT", "Official contact event and declared sync tolerance", "Fall into Landing", "Landing cue matches actual contact timestamp within declared tolerance", ["contact and cue times", "declared tolerance", "audio recording"]),
        ("AU_PAUSE", "Audio active during each animation", "Pause/resume, Reset and exit", "Actual playback obeys delivered pause/cancel policy without duplicate restart", ["policy", "stream playback/paused states", "cue counts", "recording"]),
        ("AU_VOLUME", "Isolated save and actual AudioServer buses", "Apply/cancel Master, Music, SFX and mute values", "Correct bus volume/mute and cancel restoration; no gameplay mutation", ["settings", "bus levels/mutes", "canonical state"]),
        ("AU_COLD_RESTORE", "Unique isolated settings save", "Seed settings, exit process, start independent process", "Saved settings and actual buses restore; PID changes, same save path/hash", ["seed/restore PIDs", "save path/hash", "values", "bus states"]),
        ("UI_REDUCED_MOTION", "Delivered accessibility setting and actual presentation", "Toggle, play all motions, restart application", "Motion follows declared reduced policy; logic/Orientation/Face/timing guarantees preserved; persistence follows contract", ["setting policy", "normal/reduced poses", "canonical final state", "cold restoration"]),
        ("UI_HUD_RESOLUTIONS", "Actual HUD, pause and settings screens", "960x720, 1280x720, 1920x1080; mouse and keyboard navigation", "Readable unclipped HUD, operable controls/focus, no input leakage", ["actual viewport/window sizes", "screenshots", "Control rectangles", "focus/navigation actions"]),
        ("AU_DEDUP_THROTTLE", "STARTED/COMMITTED/feedback and held rejected attempts", "Duplicate event IDs, feedback, UI-complete signals and rapid held edge input", "One committed landing; EDGE throttled per declared policy; non-edge feedback never reuses EDGE cue", ["event/attempt/presentation identities", "cue multiplicity", "AudioDirector throttle policy"]),
        ("UI_REASON_SETTINGS", "Lab HUD and separate presentation config", "Show each real reason/locked status; preview/apply/cancel settings, Reduced Motion and Hint Strength", "Correct reason/focus/values; use unchanged legacy keys; no implicit Save schema expansion", ["actual event reason", "signal payloads", "focus", "legacy Save/hash"]),
    ):
        add(case_id, "UI" if case_id.startswith("UI_") else "Audio", "AUDIO_UI SHELL ANIMATION", setup, action, expected, evidence, "GRAPHICAL")

    for feature in ("SOLVER", "REPLAY", "SAFETY"):
        add("FORMAL_" + feature, "Solver", "RUNTIME_FALL AUTHOR_CONNECTION " + feature,
            "Exact integrated author artifacts and official production modules",
            "Real solver witness + validate_semantics + Runtime replay; real swept Safety negatives",
            "No substituted search/replay/safety algorithms; Camera/connection conditions reproduced and every state/commit matches",
            ["owner receipt/commits", "canonical hash", "official call reports", "semantic trace", "step StateKeys and commits"])
    for level in range(1, 6):
        add(f"REG_L0{level}", "Legacy regression", "INTEGRATED_CONTENT RUNTIME ANIMATION SHELL",
            f"Actual catalog L0{level}, isolated save", "Focused normal Roll/Shift/view/reset/pause/exit and Goal route",
            "Original permissions, commits, physical orientation, Goal and inputs preserved",
            ["catalog/scene hash", "actual input sequence", "per-commit state", "Goal", "screenshots"], "GRAPHICAL", "L01-L05")
    add("REG_L06", "Legacy regression", "L06_INTEGRATION_RECEIPT", "Only if L06 is officially in this integration",
        "Focused regression agreed with its Owner", "No inferred L06 coverage from L01-L05", ["integration scope receipt", "real run evidence"], "GRAPHICAL", "conditional_L06")
    return rows


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps({"task": "GAME_FEEL_INTEGRATION_QUALITY_01",
                                      "contract_commit": CONTRACT_COMMIT, "contract_sha256": CONTRACT_SHA256,
                                      "cases": cases()}, ensure_ascii=False, indent=2), encoding="utf-8")
