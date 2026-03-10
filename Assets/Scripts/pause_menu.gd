extends CanvasLayer

@onready var dim: ColorRect = $Dim
@onready var panel: Control = $Panel

@onready var continue_button: Button = $Panel/VBox/ContinueButton
@onready var restart_button: Button = $Panel/VBox/RestartButton
@onready var menu_button: Button = $Panel/VBox/MenuButton

var panel_target_pos: Vector2
var is_open := false

func _ready() -> void:
	visible = false
	dim.modulate.a = 0.0
	panel_target_pos = panel.position
	panel.position = Vector2(panel_target_pos.x, -800)

func _on_button_mouse_entered() -> void:
	Cursor.set_hover()

func _on_button_mouse_exited() -> void:
	Cursor.set_normal()

func open_pause() -> void:
	if is_open:
		return

	is_open = true
	visible = true
	get_tree().paused = true

	panel.position = Vector2(panel_target_pos.x, -800)
	dim.modulate.a = 0.0

	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.set_parallel(true)
	tw.tween_property(dim, "modulate:a", 1.0, 0.25)
	tw.tween_property(panel, "position", panel_target_pos, 0.35) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_IN_OUT)

func close_pause() -> void:
	if not is_open:
		return

	is_open = false

	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.set_parallel(true)
	tw.tween_property(dim, "modulate:a", 0.0, 0.20)
	tw.tween_property(panel, "position", Vector2(panel_target_pos.x, -800), 0.28) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_IN_OUT)

	await tw.finished

	get_tree().paused = false
	visible = false

func retry_level() -> void:
	SceneManager.reload_current_level()

func go_to_menu() -> void:
	get_tree().paused = false
	is_open = false
	SceneManager.goto_levels_menu()

func _input(event: InputEvent) -> void:
	if not is_open:
		return

	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_pause()
