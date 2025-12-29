extends Control

const PER_PAGE := 6
var page: int = 0

@export var level_button_scene: PackedScene  # сюда потом подставим LevelButton.tscn
@export var level_previews: Array[Texture2D] = []

@onready var grid: GridContainer = $LevelsContainer/GridContainer
@onready var back_btn: Button = $BackButton
@onready var reset_btn: Button = $ResetButton
@onready var confirm_reset: ConfirmationDialog = $ConfirmReset
@onready var prev_page = $PrevPage
@onready var next_page = $NextPage

func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	reset_btn.pressed.connect(_on_reset_pressed)
	prev_page.pressed.connect(_on_prev_page)
	next_page.pressed.connect(_on_next_page)
	_build_grid()

func _build_grid() -> void:
	for c in grid.get_children():
		c.queue_free()

	var start: int = page * PER_PAGE
	var end: int = start + PER_PAGE
	if end > GameState.LEVEL_COUNT:
		end = GameState.LEVEL_COUNT

	for i in range(start, end):
		var btn: LevelButton = level_button_scene.instantiate() as LevelButton
		grid.add_child(btn)

		btn.mouse_entered.connect(Cursor.set_hover)
		btn.mouse_exited.connect(Cursor.set_normal)

		btn.setup(i)

		if i < level_previews.size() and level_previews[i] != null:
			btn.set_preview(level_previews[i])

		btn.pressed.connect(func(): _on_level_pressed(i))

	prev_page.visible = page > 0
	next_page.visible = page < _page_count() - 1


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

func _on_button_mouse_entered() -> void:
	Cursor.set_hover()

func _on_button_mouse_exited() -> void:
	Cursor.set_normal()

func _page_count() -> int:
	return (GameState.LEVEL_COUNT + PER_PAGE - 1) / PER_PAGE

func _on_prev_page() -> void:
	page = max(0, page - 1)
	_build_grid()

func _on_next_page() -> void:
	page = min(_page_count() - 1, page + 1)
	_build_grid()
