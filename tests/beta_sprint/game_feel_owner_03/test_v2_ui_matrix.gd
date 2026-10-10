extends "res://tests/beta_sprint/ui_host_integration/test_matrix.gd"
## Guard an existing consumer's unsafe post-Apply field access; no UI behavior repair.
func click(control: Control) -> void:
	var apply := false
	var shell: Node = null
	for child in root.get_children():
		if child.get_script() != null and "game_feel" in child:
			shell = child
			apply = shell.game_feel != null and control == shell.game_feel.ui.buttons.apply
			break
	await super.click(control)
	if apply and shell != null and shell.game_feel.ui.settings_open:
		check(false, "native Apply did not close settings at actual viewport")
		observations = {"failure": "NATIVE_APPLY_NO_SAVE", "actual_viewport": [root.size.x, root.size.y],
			"apply_rect": str(control.get_global_rect()), "panel_rect": str(shell.game_feel.ui.settings_panel.get_global_rect()),
			"settings": shell.progress.settings.duplicate(true), "error_label": shell.game_feel.ui.error_label.text,
			"focus": str(root.gui_get_focus_owner()), "native_inputs": native_inputs, "captures": captures,
			"renderer": RenderingServer.get_current_rendering_method()}
		await capture("failed_apply")
		finish()
		# Leave this coroutine suspended while the process quits; the inherited
		# consumer must not dereference settings.game_feel after a failed Apply.
		await process_frame
