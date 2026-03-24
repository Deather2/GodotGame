extends CanvasLayer

@onready var dim: ColorRect = $Dim
@onready var panel = $Panel

@onready var title_label: Label = $Panel/VBox/Title
@onready var time_label: Label = $Panel/VBox/TimeLabel

@onready var star1: TextureRect = $Panel/VBox/Stars/Star1
@onready var star2: TextureRect = $Panel/VBox/Stars/Star2
@onready var star3: TextureRect = $Panel/VBox/Stars/Star3

@onready var retry_button = $Panel/VBox/RepeatButton
@onready var next_button = $Panel/VBox/NextButton
@onready var menu_button = $Panel/VBox/MenuButton

@onready var UIButtonSound: AudioStreamPlayer = $UIButtonSound

@export var star_filled: Texture2D
@export var star_empty: Texture2D

var panel_target_pos: Vector2

var current_level_index := 0

func _ready() -> void:
	visible = false
	dim.modulate.a = 0.0
	panel.modulate.a = 1.0
	panel_target_pos = panel.position
	panel.position = Vector2(panel_target_pos.x, -800)

func _on_button_mouse_entered() -> void:
	Cursor.set_hover()

func _on_button_mouse_exited() -> void:
	Cursor.set_normal()

func set_stars(count: int) -> void:
	var arr := [star1, star2, star3]

	for i in range(3):
		arr[i].texture = star_filled if i < count else star_empty

func set_time_text(value: String) -> void:
	time_label.text = "Laiks: " + value

func setup_result(stars: int, time_text: String, level_index: int) -> void:
	current_level_index = level_index
	next_button.visible = (current_level_index + 1) < GameState.LEVEL_COUNT
	set_stars(stars)
	set_time_text(time_text)

func show_with_anim() -> void:
	visible = true

	panel.position = Vector2(panel_target_pos.x, -800)

	dim.modulate.a = 0.0
	panel.modulate.a = 1.0

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(dim, "modulate:a", 1.0, 0.25)
	tw.tween_property(panel, "position", panel_target_pos, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

func go_to_menu() -> void:
	UIButtonSound.play()
	await get_tree().create_timer(0.15).timeout
	SceneManager.goto_levels_menu()

func retry_level() -> void:
	UIButtonSound.play()
	SceneManager.reload_current_level()

func go_to_next_level() -> void:
	UIButtonSound.play()
	SceneManager.goto_next_level(current_level_index)
