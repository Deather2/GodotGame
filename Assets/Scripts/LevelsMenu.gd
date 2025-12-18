extends Control

@export var level_button_scene: PackedScene  # сюда потом подставим LevelButton.tscn
@export var level_previews: Array[Texture2D] = []

@onready var grid: GridContainer = $GridContainer
@onready var back_btn: Button = $BackButton
@onready var reset_btn: Button = $ResetButton
@onready var confirm_reset: ConfirmationDialog = $ConfirmReset

func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	reset_btn.pressed.connect(_on_reset_pressed)
	_build_grid()

func _build_grid() -> void:
	for c in grid.get_children():
		c.queue_free()

	for i in range(GameState.LEVEL_COUNT):
		var btn = level_button_scene.instantiate()
		grid.add_child(btn)
		btn.setup(i) 
		if i < level_previews.size() and level_previews[i] != null:
			btn.set_preview(level_previews[i])
		btn.pressed.connect(func(): _on_level_pressed(i))

func _on_level_pressed(i: int) -> void:
	# пока просто проверка, что кликается
	print("level pressed:", i)

func _on_back_pressed() -> void:
	# тут потом сделаем переход в главное меню
	print("back")

func _on_reset_pressed() -> void:
	confirm_reset.confirmed.connect(func():
		GameState.reset_level_progress()
		_build_grid()
	, CONNECT_ONE_SHOT)
	confirm_reset.popup_centered()
