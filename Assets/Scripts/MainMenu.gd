extends Control

#Cursor

func _ready() -> void:
	Cursor.set_normal()  

func _on_menu_button_mouse_entered() -> void:
	Cursor.set_hover()

func _on_menu_button_mouse_exited() -> void:
	Cursor.set_normal()

#Buttons go to

func _on_start_pressed() -> void:
	SceneManager.goto_levels_menu()

func _on_shop_pressed() -> void:
	SceneManager.goto_shop()

func _on_locker_pressed() -> void:
	SceneManager.goto_locker()

func _on_settings_pressed() -> void:
	SceneManager.goto_settings()

func _on_quit_pressed() -> void:
	SceneManager.quit_game()
