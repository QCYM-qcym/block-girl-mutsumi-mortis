extends Node
## Last sibling: receives input before the older gameplay subtree.
var shell: Node

func _input(event: InputEvent) -> void:
	if shell.handle_shell_input(event):
		get_viewport().set_input_as_handled()
