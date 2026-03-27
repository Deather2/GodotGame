extends Control

func _ready() -> void:
	GameState.show_cursor()

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel") or event.is_echo():
		return

	get_viewport().set_input_as_handled()
	SceneManager.goto_main_menu(SceneManager.Transition.DROP_UP)
