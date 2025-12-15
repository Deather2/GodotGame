extends Control

func _ready() -> void:
	Cursor.set_normal()  

func _on_button_mouse_entered() -> void:
	Cursor.set_hover()

func _on_button_mouse_exited() -> void:
	Cursor.set_normal()

func _on_back_pressed() -> void:
	SceneManager.goto_main_menu()
