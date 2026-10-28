extends "res://tests/beta_sprint/spatial_formal/shell_lifecycle.gd"
## Single-entry integration fixture, no claim of natural progression or human QA.
func run() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--shell-save="): save_path = arg.trim_prefix("--shell-save=")
  elif arg.begins_with("--evidence-dir="): evidence = arg.trim_prefix("--evidence-dir=")
 phase = "native_menu_seam"
 var catalog = load("res://game/shell/level_catalog.gd").new()
 shell = load("res://game/shell/game_feel_shell.tscn").instantiate()
 shell.save_path = save_path
 shell.catalog_entries.assign([catalog.find("spatial_world_shift_gate_lab")])
 root.add_child(shell)
 await process_frame
 check(shell.view.has_method("set_world_layer"), "approved native menu is actually wired")
 if not shell.view.has_method("set_world_layer"):
  await finish()
  return
 check(shell.view.backdrop.debug_state().active, "main backdrop active")
 shell.view.world_buttons[1].pressed.emit()
 await process_frame
 check(shell.view.debug_snapshot().world_layer == 1 and shell.game_feel.ui._presentation_world == 1, "menu selector routes real UI and backdrop palette")
 check(shell.state == shell.State.MAIN_MENU and shell.adapter.level == null, "menu selector never creates gameplay action")
 shell.open_settings()
 await process_frame
 check(shell.view.debug_snapshot().settings_overlay and not shell.view._content.visible, "settings owns foreground while avatar remains")
 var prior: Dictionary = shell.progress.settings.duplicate(true)
 shell.game_feel.ui.buttons.reduced_motion.button_pressed = true
 await process_frame
 check(shell.view.backdrop.debug_state().reduced_motion, "real reduced-motion preview reaches menu actor")
 shell.cancel_settings()
 await process_frame
 check(not shell.view.debug_snapshot().settings_overlay and shell.progress.settings == prior, "cancel restores real transaction and menu visibility")
 check(not shell.view.backdrop.debug_state().reduced_motion, "cancel restores actor motion")
 shell.new_game()
 await process_frame
 var level = shell.adapter.level
 check(not shell.view.backdrop.debug_state().active, "enter gameplay disables menu rendering")
 check(level.has_method("get_presentation_world"), "formal level exposes read-only integer world")
 var witness: Array = Factory.witnesses(level.map_id).solution
 var shifted := false
 for step in witness:
  var result: Dictionary = level.host.runtime.request_action(step)
  check(result.status == 0, "formal action accepted")
  await settle(level.host)
  await process_frame
  if level.get_presentation_world() == 1:
   shifted = true
   check(shell.view.debug_snapshot().world_layer == 1 and shell.game_feel.ui._presentation_world == 1, "committed Inner reaches native palette")
   break
 check(shifted, "actual witness reaches Inner")
 shell.pause_game()
 await process_frame
 check(not shell.view.backdrop.debug_state().active, "pause keeps gameplay background")
 shell.open_settings()
 await process_frame
 check(shell.game_feel.ui._presentation_world == 1, "runtime settings use committed Inner")
 shell.cancel_settings()
 shell.reset_current()
 await process_frame
 check(level.get_presentation_world() == 0 and shell.view.debug_snapshot().world_layer == 0, "Reset restores Surface palette")
 shell.show_main_menu()
 await process_frame
 check(shell.view.backdrop.debug_state().active, "return menu restarts private actor")
 await finish()
