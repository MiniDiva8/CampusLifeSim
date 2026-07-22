class_name PauseMenuController
extends Node
## Signal-based adaptation of Maaack's pause-menu controller (MIT).

signal pause_requested


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		pause_requested.emit()
		get_viewport().set_input_as_handled()
