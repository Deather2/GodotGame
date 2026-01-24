extends Control

const PER_PAGE := 6

var page: int = 0
var animating: bool = false
var current_container: Control

var confirm_animating: bool = false

@export var level_button_scene: PackedScene
@export var level_previews: Array[Texture2D] = []

@onready var pages_holder: Control = $PagesHolder
@onready var back_btn: Button = $BackButton
@onready var reset_btn: Button = $ResetButton
@onready var prev_page: Button = $PrevPage
@onready var next_page: Button = $NextPage

@onready var dim: ColorRect = $Dim

@onready var confirm_reset: Control = $ConfirmReset
@onready var confirm_yes: Button = $ConfirmReset/Panel/VBoxContainer/Buttons/YesButton
@onready var confirm_no: Button = $ConfirmReset/Panel/VBoxContainer/Buttons/NoButton


func _ready() -> void:
	current_container = $PagesHolder/LevelsContainer

	back_btn.pressed.connect(_on_back_pressed)
	reset_btn.pressed.connect(_on_reset_pressed)
	prev_page.pressed.connect(_on_prev_page)
	next_page.pressed.connect(_on_next_page)

	confirm_yes.pressed.connect(_on_reset_confirmed)
	confirm_no.pressed.connect(_on_reset_canceled)

	dim.visible = false
	dim.modulate.a = 0.0

	confirm_reset.visible = false
	confirm_reset.modulate.a = 0.0
	confirm_reset.scale = Vector2(0.9, 0.9)

	_build_grid()
	reset_btn.visible = GameState.has_any_progress()


func _page_count() -> int:
	return int(ceil(float(GameState.LEVEL_COUNT) / float(PER_PAGE)))


func _update_arrows_for(p: int) -> void:
	prev_page.visible = p > 0
	next_page.visible = p < _page_count() - 1


func _build_grid() -> void:
	var grid: GridContainer = current_container.get_node("GridContainer") as GridContainer

	for c in grid.get_children():
		c.queue_free()

	var start: int = page * PER_PAGE
	var end: int = start + PER_PAGE
	if end > GameState.LEVEL_COUNT:
		end = GameState.LEVEL_COUNT

	for i in range(start, end):
		var btn: LevelButton = level_button_scene.instantiate() as LevelButton
		grid.add_child(btn)

		btn.mouse_entered.connect(func():
			if not btn.disabled:
				Cursor.set_hover()
		)
		btn.mouse_exited.connect(Cursor.set_normal)

		btn.setup(i)

		if i < level_previews.size() and level_previews[i] != null:
			btn.set_preview(level_previews[i])

		btn.pressed.connect(func(): _on_level_pressed(i))

	_update_arrows_for(page)

#ZDESJ SDELATJ
func _on_level_pressed(i: int) -> void:
	print("level pressed:", i)

func _on_back_pressed() -> void:
	SceneManager.goto_main_menu(SceneManager.Transition.DROP_UP)

func _show_confirm() -> void:
	if confirm_animating:
		return
	confirm_animating = true

	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	confirm_reset.mouse_filter = Control.MOUSE_FILTER_STOP

	dim.visible = true
	confirm_reset.visible = true

	dim.modulate.a = 0.0
	confirm_reset.modulate.a = 0.0
	confirm_reset.scale = Vector2(0.1, 0.1)

	var t := create_tween()
	t.set_trans(Tween.TRANS_QUAD)
	t.set_ease(Tween.EASE_OUT)

	t.tween_property(dim, "modulate:a", 0.55, 0.35)
	t.parallel().tween_property(confirm_reset, "modulate:a", 1.0, 0.35)
	t.parallel().tween_property(confirm_reset, "scale", Vector2(1.0, 1.0), 0.35)

	await t.finished
	confirm_animating = false


func _hide_confirm() -> void:
	if confirm_animating:
		return
	confirm_animating = true

	var t := create_tween()
	t.set_trans(Tween.TRANS_QUAD)
	t.set_ease(Tween.EASE_IN)

	t.tween_property(confirm_reset, "modulate:a", 0.0, 0.3)
	t.parallel().tween_property(confirm_reset, "scale", Vector2(0.9, 0.9), 0.3)
	t.parallel().tween_property(dim, "modulate:a", 0.0, 0.3)

	await t.finished

	confirm_reset.visible = false
	dim.visible = false

	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	confirm_reset.mouse_filter = Control.MOUSE_FILTER_IGNORE

	confirm_animating = false

func _on_reset_pressed() -> void:
	await _show_confirm()


func _on_reset_confirmed() -> void:
	await _hide_confirm()
	GameState.reset_all_progress_keep_settings()
	page = 0
	_build_grid()
	reset_btn.visible = GameState.has_any_progress()


func _on_reset_canceled() -> void:
	await _hide_confirm()

func _on_button_mouse_entered() -> void:
	Cursor.set_hover()

func _on_button_mouse_exited() -> void:
	Cursor.set_normal()

func _on_prev_page() -> void:
	if page <= 0:
		return
	_animate_to_page(page - 1, -1)

func _on_next_page() -> void:
	if page >= _page_count() - 1:
		return
	_animate_to_page(page + 1, +1)

func _animate_to_page(new_page: int, dir: int) -> void:
	if animating:
		return
	if new_page == page:
		return

	animating = true
	_update_arrows_for(new_page)

	var old_container: Control = current_container
	var new_container: Control = old_container.duplicate() as Control
	pages_holder.add_child(new_container)

	var w: float = pages_holder.size.x
	new_container.position = old_container.position + Vector2(w * dir, 0)

	var new_grid: GridContainer = new_container.get_node("GridContainer") as GridContainer

	for c in new_grid.get_children():
		c.queue_free()

	var start: int = new_page * PER_PAGE
	var end: int = start + PER_PAGE
	if end > GameState.LEVEL_COUNT:
		end = GameState.LEVEL_COUNT

	for i in range(start, end):
		var btn: LevelButton = level_button_scene.instantiate() as LevelButton
		new_grid.add_child(btn)

		btn.mouse_entered.connect(func():
			if not btn.disabled:
				Cursor.set_hover()
		)
		btn.mouse_exited.connect(Cursor.set_normal)

		btn.setup(i)

		if i < level_previews.size() and level_previews[i] != null:
			btn.set_preview(level_previews[i])

		btn.pressed.connect(func(): _on_level_pressed(i))

	var t := create_tween()
	t.set_trans(Tween.TRANS_SINE)
	t.set_ease(Tween.EASE_IN_OUT)

	t.tween_property(old_container, "position", old_container.position - Vector2(w * dir, 0), 0.25)
	t.parallel().tween_property(new_container, "position", old_container.position, 0.25)

	t.finished.connect(func():
		page = new_page
		old_container.queue_free()
		current_container = new_container
		animating = false
	)
