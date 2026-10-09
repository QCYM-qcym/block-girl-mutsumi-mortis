# GAME_AUDIO_FOUNDATION_01 actual audio sources

5 actual music exports and 13 actual SFX exports are in `exports/`. The complete deterministic composition/synthesis source is in `source/`, together with the PCM24 originals. This is a restrained synthesis foundation, not orchestral studio recording. The music shares a newly written D-F-A-E motif and D Dorian / suspended ninth harmony.

| Music key | Export | Duration | Loop |
| --- | --- | --- | --- |
| menu | bgm_menu.wav | 26.666667 s | 8 bars, 72 BPM |
| surface | bgm_surface.wav | 40 s | 12 bars, 72 BPM |
| inner | bgm_inner.wav | 40 s | 12 bars, 72 BPM |
| discovery | bgm_discovery.wav | 3.5 s | No |
| complete | bgm_complete.wav | 5 s | No |
| ending | None | None | PLANNED_ONLY in score |

Surface uses gentle damped harmonics with rounded pluck attacks; Inner uses the identical note/timing structure with airy detuning and a quiet upper minor-second pad color. Both exploratory tracks contain exactly 1,764,000 stereo frames. Play them from the same initial position, keep both running, and crossfade gain to avoid restarting a phrase on World Shift. Wrapped instrument/echo tails retain sound across the loop boundary.

| SFX key | Duration | Sound design / lifecycle |
| --- | --- | --- |
| cube_roll | 0.36 s | soft wooden two-part turn |
| cube_contact | 0.16 s | small muted support tick |
| edge_lean | 0.32 s | quiet descending friction tone |
| edge_recoil | 0.45 s | restrained recoil with rounded bell detail |
| fall_start | 0.38 s | gentle released tension / descent onset |
| fall_whoosh | 1.5 s | periodic low-pass airflow loop; identity scoped |
| landing_impact | 0.55 s | rounded low body plus gentle surface noise; COMMITTED only |
| perspective_connect | 0.55 s | rising soft harmonic connection |
| perspective_disconnect | 0.50 s | falling paired harmonic connection |
| world_shift | 1.1 s | slow swelling harmonic shimmer |
| goal | 2.2 s | shared theme rising fragment |
| ui_select | 0.12 s | very quiet rounded high click |
| ui_back | 0.17 s | lower paired UI click |

`manifest.json` uses schema version 1: music and sfx maps provide `res://` export paths, exact frame counts, duration, channel count, source/export SHA-256, gain trim and explicit forward-loop frame endpoints. `gain_db` is an additional conservative player trim; do not normalize each cue to full scale. Music loops and fall airflow need `AudioStreamWAV.LOOP_FORWARD`, begin 0, end the manifest frame count. All other files are one-shots. Loading does not change global buses or import settings. Source and previews have `.gdignore` to avoid duplicate runtime imports.

`previews/asset_audition.wav` is an offline listening aid: Surface begins at 0 s; a same-position equal-power fade to Inner runs at 10–12 s; music ends at 24 s, then 1 s silence, then SFX in the table's order separated by 0.45 s silence. This constructed audition is not recorded Godot playback or Runtime evidence.

Reproduce from the repository root:

```powershell
& 'C:/Users/QCYM/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' 'production/experimental/game_feel_01/audio/source/synthesize.py'
& 'C:/Users/QCYM/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' 'tests/beta_sprint/game_feel_owner_11/assets/validate_assets.py'
```

The analyzer verifies actual decoded PCM peaks, sample jumps, DC, silence endpoints, forward-loop endpoints, stereo pair sync, source/export hashes and crossfade headroom. It does not listen. Human listening, Godot device playback, full Shell/game-event wiring and integrated gameplay QA remain separate checks.
