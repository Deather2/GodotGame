extends Control

func _ready() -> void:
	Cursor.set_normal()

func _on_menu_button_mouse_entered() -> void:
	Cursor.set_hover()

func _on_menu_button_mouse_exited() -> void:
	Cursor.set_normal()

func _on_start_pressed() -> void:
	SceneManager.goto_levels_menu(SceneManager.Transition.DROP_DOWN)

func _on_shop_pressed() -> void:
	SceneManager.goto_shop(SceneManager.Transition.DROP_DOWN)

func _on_locker_pressed() -> void:
	SceneManager.goto_locker(SceneManager.Transition.DROP_DOWN)

func _on_settings_pressed() -> void:
	SceneManager.goto_settings(SceneManager.Transition.DROP_DOWN)

func _on_quit_pressed() -> void:
	SceneManager.quit_game()
