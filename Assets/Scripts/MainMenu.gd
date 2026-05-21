extends Control

var updating_demo_toggle := false

@onready var UIButtonSound: AudioStreamPlayer = $UIButtonSound
@onready var demo_toggle: CheckButton = $DemoModeToggle
@onready var artifacts_button: Button = $ArtifactsButton


func _ready() -> void:
	GameState.show_cursor()
	Cursor.set_normal()

	_style_demo_toggle()

	demo_toggle.set_pressed_no_signal(GameState.demo_mode_enabled)
	demo_toggle.toggled.connect(_on_demo_mode_toggled)

	artifacts_button.pressed.connect(_on_artifacts_pressed)

	if not GameState.demo_mode_changed.is_connected(_on_demo_mode_changed):
		GameState.demo_mode_changed.connect(_on_demo_mode_changed)


func _style_demo_toggle() -> void:
	demo_toggle.remove_theme_icon_override("unchecked")
	demo_toggle.remove_theme_icon_override("checked")
	demo_toggle.remove_theme_icon_override("unchecked_disabled")
	demo_toggle.remove_theme_icon_override("checked_disabled")
	demo_toggle.remove_theme_icon_override("unchecked_mirrored")
	demo_toggle.remove_theme_icon_override("checked_mirrored")

	var light := Color("e8f3ff")
	var dark := Color("1a0d06")
	var mid := Color("8f9aaa")

	demo_toggle.add_theme_color_override("button_unchecked_color", mid)
	demo_toggle.add_theme_color_override("button_unchecked_hover_color", mid)
	demo_toggle.add_theme_color_override("button_unchecked_pressed_color", mid)
	demo_toggle.add_theme_color_override("button_unchecked_hover_pressed_color", mid)

	demo_toggle.add_theme_color_override("button_checked_color", light)
	demo_toggle.add_theme_color_override("button_checked_hover_color", light)
	demo_toggle.add_theme_color_override("button_checked_pressed_color", light)
	demo_toggle.add_theme_color_override("button_checked_hover_pressed_color", light)

	demo_toggle.add_theme_color_override("button_unchecked_disabled_color", dark)
	demo_toggle.add_theme_color_override("button_checked_disabled_color", dark)


func _on_menu_button_mouse_entered() -> void:
	Cursor.set_hover()


func _on_menu_button_mouse_exited() -> void:
	Cursor.set_normal()


func _on_start_pressed() -> void:
	UIButtonSound.play()
	SceneManager.goto_levels_menu(SceneManager.Transition.DROP_DOWN)


func _on_shop_pressed() -> void:
	UIButtonSound.play()
	SceneManager.goto_shop(SceneManager.Transition.DROP_DOWN)


func _on_locker_pressed() -> void:
	UIButtonSound.play()
	SceneManager.goto_locker(SceneManager.Transition.DROP_DOWN)


func _on_settings_pressed() -> void:
	UIButtonSound.play()
	SceneManager.goto_settings(SceneManager.Transition.DROP_DOWN)


func _on_quit_pressed() -> void:
	UIButtonSound.play()
	SceneManager.quit_game()


func _on_demo_mode_toggled(enabled: bool) -> void:
	if updating_demo_toggle:
		return

	UIButtonSound.play()
	GameState.set_demo_mode_enabled(enabled)


func _on_demo_mode_changed(enabled: bool) -> void:
	updating_demo_toggle = true
	demo_toggle.set_pressed_no_signal(enabled)
	updating_demo_toggle = false

func _on_artifacts_pressed() -> void:
	if UIButtonSound != null:
		UIButtonSound.play()

	SceneManager.goto_artifacts()
