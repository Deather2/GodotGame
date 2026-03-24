extends CanvasLayer

@onready var dim: ColorRect = $Dim
@onready var panel: Control = $Panel
@onready var settings_panel: Control = $SettingsPanel

@onready var continue_button: Button = $Panel/VBox/ContinueButton
@onready var restart_button: Button = $Panel/VBox/RestartButton
@onready var settings_button: Button = $Panel/VBox/SettingsButton
@onready var menu_button: Button = $Panel/VBox/MenuButton

@onready var back_button: Button = $SettingsPanel/Panel/BackButton

@onready var UIButtonSound: AudioStreamPlayer = $SettingsPanel/UIButtonSound

var panel_target_pos: Vector2
var settings_target_pos: Vector2

var is_open := false
var showing_settings := false
var switching := false


func _ready() -> void:
	visible = false
	dim.modulate.a = 0.0

	panel_target_pos = panel.position
	settings_target_pos = settings_panel.position

	panel.position = Vector2(panel_target_pos.x, -800)

	settings_panel.visible = false
	settings_panel.position = settings_target_pos + Vector2(_slide_offset(), 0)


func _slide_offset() -> float:
	return get_viewport().get_visible_rect().size.x + 200.0


func _on_button_mouse_entered() -> void:
	Cursor.set_hover()


func _on_button_mouse_exited() -> void:
	Cursor.set_normal()


func open_pause() -> void:
	if is_open:
		return

	is_open = true
	showing_settings = false
	switching = false

	visible = true
	get_tree().paused = true

	panel.visible = true
	settings_panel.visible = false

	panel.position = Vector2(panel_target_pos.x, -800)
	settings_panel.position = settings_target_pos + Vector2(_slide_offset(), 0)
	dim.modulate.a = 0.0

	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.set_parallel(true)
	tw.tween_property(dim, "modulate:a", 1.0, 0.25)
	tw.tween_property(panel, "position", panel_target_pos, 0.35) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_IN_OUT)


func close_pause(play_sound := true) -> void:
	if play_sound:
		UIButtonSound.play()

	if not is_open or switching:
		return

	is_open = false
	switching = true

	var current_page: Control = settings_panel if showing_settings else panel
	var current_target: Vector2 = settings_target_pos if showing_settings else panel_target_pos

	current_page.visible = true

	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.set_parallel(true)
	tw.tween_property(dim, "modulate:a", 0.0, 0.20)
	tw.tween_property(current_page, "position", Vector2(current_target.x, -800), 0.28) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_IN_OUT)

	await tw.finished

	get_tree().paused = false
	visible = false
	showing_settings = false
	switching = false


func open_settings() -> void:
	if not is_open or showing_settings or switching:
		return

	switching = true

	var dx := _slide_offset()

	settings_panel.visible = true
	settings_panel.position = settings_target_pos + Vector2(dx, 0)

	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.set_parallel(true)
	tw.tween_property(panel, "position", panel_target_pos + Vector2(-dx, 0), 0.35) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(settings_panel, "position", settings_target_pos, 0.35) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_IN_OUT)

	await tw.finished

	panel.visible = false
	showing_settings = true
	switching = false


func close_settings_screen(play_sound := true) -> void:
	if play_sound:
		UIButtonSound.play()

	if not is_open or not showing_settings or switching:
		return

	switching = true

	var dx := _slide_offset()

	panel.visible = true
	panel.position = panel_target_pos + Vector2(-dx, 0)

	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.set_parallel(true)
	tw.tween_property(settings_panel, "position", settings_target_pos + Vector2(dx, 0), 0.35) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(panel, "position", panel_target_pos, 0.35) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_IN_OUT)

	await tw.finished

	settings_panel.visible = false
	showing_settings = false
	switching = false


func retry_level() -> void:
	UIButtonSound.play()
	SceneManager.reload_current_level()


func go_to_menu() -> void:
	var level := get_parent()
	if level != null and level.has_method("stop_level_music"):
		level.stop_level_music()
	
	UIButtonSound.play()
	await get_tree().create_timer(0.15).timeout
	get_tree().paused = false
	is_open = false
	showing_settings = false
	switching = false
	SceneManager.goto_levels_menu()


func _on_settings_button_pressed() -> void:
	UIButtonSound.play()
	open_settings()


func _on_back_button_pressed() -> void:
	close_settings_screen()


func _input(event: InputEvent) -> void:
	if not is_open or switching:
		return

	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()

		if showing_settings:
			close_settings_screen(false)
		else:
			close_pause(false)
