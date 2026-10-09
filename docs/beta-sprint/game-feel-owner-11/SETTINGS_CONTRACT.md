# Audio settings contract for 07 / 00

`AudioDirector.apply_settings(values: Dictionary) -> void` accepts the existing keys master/music/sfx (finite 0..1 numbers), muted (bool) and ignores fullscreen. It merges valid partial previews into its last effective values; full existing Shell snapshots are the preferred input. Invalid numbers diagnose silently. It writes neither SaveStore nor Window/fullscreen state.

| Existing key | Existing bus | Gain at value 1 | Zero/mute behavior |
| --- | --- | --- | --- |
| master | Master | 0 dB | zero or muted=true mutes Master |
| music | Ambience | -12 dB | zero mutes Ambience |
| sfx | SFX | -6 dB | zero mutes SFX |
| muted | Master | gain unchanged | does not bypass a zero master value |
| fullscreen | ignored by audio | none | remains owned by Shell |

Gain is `linear_to_db(max(value,0.0001)) + existing base`. Music and SFX therefore remain independent; UI SFX follow the same SFX slider. Existing ambient sounds also follow the legacy music/Ambience slider. There is no new music/UI bus and no second settings file.

07/00 flow: send a full original settings snapshot on binding; preview through apply_settings; persist through the EXISTING Shell SaveStore on Apply; pass the original persisted snapshot again on Cancel/save failure. The director does not know whether values are saved. During pause/resume call set_paused while preserving settings; clear stops playback without reverting user bus settings.

Compatibility was verified by two distinct Godot processes against unchanged `game/shell/save_store.gd`. The writer stores master=.42, music=.31, sfx=.67, muted=true, fullscreen=false in an isolated `user://owner11_volume_contract/profile.json`; the reader verifies exact values/5 keys and applies those values to actual AudioServer buses. This is existing storage/API evidence, not actual Shell widget or Save/Continue gameplay integration. Test profiles live only below fresh Owner 11 evidence directories through child-process APPDATA overrides. The production default save slot was never opened.
