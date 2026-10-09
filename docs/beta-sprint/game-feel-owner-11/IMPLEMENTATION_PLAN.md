# GAME_AUDIO_FOUNDATION_01 Implementation Plan

> For agentic workers: use superpowers:executing-plans for the audio consumer; original asset production runs as a disjoint parallel subtask. The user authorized BUILD/PARALLEL through 00. No new approval rounds.

**Goal:** Deliver actual original music/SFX and an independently verified Godot audio consumer for the game-feel laboratory.

**Architecture:** A pure event policy validates the separate game_feel.event.v1 presentation port, deduplicates starts/commits and scopes interruption by presentation_identity. AudioDirector owns a fixed set of local AudioStreamPlayers, paired synchronized exploration streams and lifecycle/settings. Assets contain original deterministic score/synthesis sources, exported PCM/OGG, provenance and measurements.

**Tech Stack:** Godot 4.7.2 GDScript; Python/NumPy original synthesis and PCM checks.

**Spec:** ../game-feel/GAME_FEEL_CONTRACT.md (SHA256 6224f8cd364f98da41822eabe7ba2973fa2db01d030373e7b3e94d69f35f23de) and the user's GAME_AUDIO_FOUNDATION_01 request.

## Global Constraints

- Only game/feel/audio/**, production/experimental/game_feel_01/audio/**, tests/beta_sprint/game_feel_owner_11/** and this document root are writable.
- Reuse Master/SFX/Ambience; unchanged master/music/sfx/fullscreen/muted save keys; no persistence writer in audio.
- Never finish Runtime transitions or infer Fall/EDGE from render/neighbor state. Matching COMMITTED alone may trigger landing.
- Owner-local fixtures declare PRESENTATION_CONTRACT_UNIT, authoritative_runtime=false and doubles. Real Fall/Shell wiring remains pending for 00.
- No push; preserve prior QA packages, saves, source assets and other worktrees.

## Review Focus

- Out-of-order/duplicated COMMITTED or reset feedback must never cause premature/multiple landing.
- Late interruption of an older identity must not stop new voices; reentrant cue callbacks must not replace a new active effect.
- Rejected held input must throttle recoil; BUSY/MECHANISM/SAFETY/invalid data must never sound like EDGE.
- Pause must preserve playback and music blend position; clear/unload must stop every loop synchronously.
- Music/SFX mute, preview/revert and zero-volume must remain independent without touching fullscreen or save storage.

## Task 1 — Pure event policy

Files: game/feel/audio/event_policy.gd; tests/beta_sprint/game_feel_owner_11/test_policy.gd.
Interface: consume(event, elapsed_seconds)->Dictionary {accepted,cues,stop_identity,world_id,issues}; cancel(identity), clear().

- [x] Write policy tests for normal/fall starts and matching landing, deduplication, invalid events, EDGE throttling, stale cancel/new launch and generation/run lifecycle.
- [x] Run with an empty policy scaffold to retain behavioral RED (parser/config errors are separate).
- [x] Implement conservative validation, full identity matching and bounded deduplication.
- [x] Run GREEN; record command/source hashes/profile/PID and raw logs.

## Task 2 — Actual original audio assets (parallel)

Files: production/experimental/game_feel_01/audio/**; tests/beta_sprint/game_feel_owner_11/assets/**.
Interface: manifest.json schema_version=1, sample_rate=44100, music menu/surface/inner/discovery/complete; 13 sfx entries, full res:// paths, loop/gain/duration/hashes/source.

- [x] Compose and synthesize 5 music exports and 13 SFX from retained score/recipe; Ending remains planning.
- [x] Measure decoded output, clipping/DC/loop seams/duration/sample-count equality; retain source/provenance and hashes.
- [x] Subjective listening remains NOT_RUN unless a genuine listening result exists.

## Task 3 — AudioDirector and physical playback verification

Files: game/feel/audio/audio_director.gd; tests/beta_sprint/game_feel_owner_11/test_director.gd; owner-local run_validation.py.
Required interface: consume_event, play_ui, apply_settings, set_paused, cancel, clear. Additional audio-only set_music(context,world_id) supports 00's future menu/world lifecycle glue without shared modifications.

- [x] Tests: fixed voice population; absent resources; pause/resume; synced streams/world shift without restart; real AudioEffectCapture PCM; independent settings/mute/revert; duplicate completion sources; cancel/clear and no lingering voices.
- [x] Observe behavioral RED, implement player lifecycle and crossfade, run GREEN with actual audio driver and isolated process APPDATA/user://.
- [x] Retain actual mixed WAV for optional user listening, not a subjective PASS claim.

## Task 4 — Delivery

- [x] Review contract and source; run fresh combined tests and asset measurements.
- [x] Write EVENT_MAPPING, SETTINGS_CONTRACT, exact INTEGRATION_REQUEST, source/evidence inventory and receipt. Formal Fall/Graphical/Human listening and actual Shell persistence integration remain explicitly pending.
- [x] Fresh independent whole-branch review; fix material findings with RED/GREEN.
- [x] Commit only allowlisted source/assets/tests/docs; verify SHA, clean status and original baseline byte protection. Do not push or merge.
