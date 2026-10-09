# 00 explicit shared settings binding

Task GAME_FEEL_UI_HOST_INTEGRATION_01 explicitly authorizes persistent Reduced Motion/Hint/Contrast/Input hints. Shared2938d6 contract stays unchanged; this00-owned supplemental binding makes persistence explicit.

The existing SaveStore version1 envelope and same progress/settings slot remain the sole writer. Optional settings.game_feel is a dictionary: version=1,reduced_motion:bool,hint_strength:int0..2,contrast:bool,input_hints:bool. Old saves without it use false/1/false/true defaults. Unknown/future or malformed configuration is not overwritten; Apply fails closed for that configuration. Existing master/music/sfx/fullscreen/muted and progress identifiers retain their semantics. Preview/cancel never persist; actual save failure restores saved audio/options and keeps the draft for retry.

11 apply_settings(values) handles gains/mute; set_music(context,world_id) is routed separately.07 settings_apply is acknowledged only after successful existing SaveStore.save.00 owns scene/scope and stale callback gates.

10A's real motion_parameters.reduced_motion is selected for the next accepted Fall and retained through its Landing; changing a setting cannot change an active authorized path, duration, final orientation or native completion identity.10B consumption remains PENDING until its formal host feedback is wired; settings UI states that limit. Hint Strength/Contrast/Input hints control07 presentation and approved authored operation text only; no new solution text or Runtime permission computation.

01 currently has no connection-preparedness query. Pre-departure connection eligibility feedback is PENDING_RUNTIME_INTERFACE. Actual STARTED/COMMITTED and typed native rejection events alone supply delivered feedback. No inferred eligibility or Mock port is registered.
