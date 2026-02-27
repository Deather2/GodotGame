extends Control

@export var db: CharacterDB
@export var card_scene: PackedScene
@export var prices: Array[int] = []

@onready var stars_count: Label = $Background/StarsUI/StarsCount
@onready var top_star_icon: TextureRect = $Background/StarsUI/StarBox/StarIcon

@onready var back_button: Button = $Background/BackButton
@onready var grid: GridContainer = $Background/GridCenter/Grid

@onready var details_popup: Control = $Background/DetailsPopup
@onready var details_dim: ColorRect = $Background/DetailsPopup/Dim
@onready var details_panel: Control = $Background/DetailsPopup/Panel

@onready var details_preview_center: Control = $Background/DetailsPopup/Panel/CharacterPreviewCenter
@onready var details_preview_sprite: Sprite2D = $Background/DetailsPopup/Panel/CharacterPreviewCenter/CharacterPreviewSprite

@onready var details_name: Label = $Background/DetailsPopup/Panel/Name
@onready var details_story: Label = $Background/DetailsPopup/Panel/StoryBox/Story
@onready var story_scroll: ScrollContainer = $Background/DetailsPopup/Panel/StoryBox

@onready var buy_button: Button = $Background/DetailsPopup/Panel/BuyButton
@onready var buy_button_label: Label = $Background/DetailsPopup/Panel/BuyButton/ButtonLabel
@onready var close_button: Button = $Background/DetailsPopup/Panel/CloseButton

@onready var confirm_popup: Control = $Background/ConfirmPopup
@onready var confirm_dim: ColorRect = $Background/ConfirmPopup/Dim
@onready var confirm_panel: Control = $Background/ConfirmPopup/Panel
@onready var confirm_label: Label = $Background/ConfirmPopup/Panel/ConfirmLabel
@onready var yes_button: TextureButton = $Background/ConfirmPopup/Panel/YesButton
@onready var no_button: TextureButton = $Background/ConfirmPopup/Panel/NoButton

var current_id: int = 0
var pending_buy_id: int = -1

const OWNED_TEXT := "Ir nopirkts"
const NOT_ENOUGH_TEXT := "Nepietiek zvaigžņu"
const BUY_TEXT := "Pirkt"

const POP_DUR := 0.6
const DIM_ALPHA := 0.65
const POP_FROM_SCALE := 0.1

# details preview tuning
const DETAILS_PREVIEW_TARGET_H := 180.0
const DETAILS_PREVIEW_Y_BIAS := -20.0

var _details_anim := false
var _confirm_anim := false


func _ready() -> void:
	if db == null or card_scene == null:
		return

	if prices.size() < db.textures.size():
		var old := prices.duplicate()
		prices.resize(db.textures.size())
		for i in range(prices.size()):
			prices[i] = int(old[i]) if i < old.size() else 0

	_build_grid()
	_refresh_top()


	if GameState.has_signal("unlocks_changed"):
		GameState.connect("unlocks_changed", Callable(self, "_refresh_all"))
	if GameState.has_signal("stars_spent_changed"):
		GameState.connect("stars_spent_changed", Callable(self, "_refresh_all"))

	_prepare_popup(details_popup, details_dim, details_panel)
	_prepare_popup(confirm_popup, confirm_dim, confirm_panel)


func _center_pivot(c: Control) -> void:
	await get_tree().process_frame
	c.pivot_offset = c.size * 0.5


func _prepare_popup(popup: Control, dim: ColorRect, panel: Control) -> void:
	popup.visible = false
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if is_instance_valid(dim):
		dim.modulate.a = 0.0
		dim.mouse_filter = Control.MOUSE_FILTER_STOP

	if is_instance_valid(panel):
		panel.modulate.a = 1.0
		panel.scale = Vector2.ONE
		_center_pivot(panel)


func _refresh_top() -> void:
	stars_count.text = str(GameState.get_available_stars())


func _refresh_all() -> void:
	_refresh_top()
	_build_grid()
	if details_popup.visible:
		_show_details(current_id)


func _build_grid() -> void:
	for c in grid.get_children():
		c.queue_free()

	var star_tex: Texture2D = top_star_icon.texture

	for id in range(db.textures.size()):
		var card := card_scene.instantiate() as ShopCard
		grid.add_child(card)

		card.setup(id, db.textures[id], _card_text(id), star_tex)
		card.card_pressed.connect(_open_details)


func _card_text(id: int) -> String:
	if GameState.is_character_unlocked(id):
		return OWNED_TEXT
	var price := prices[id] if id < prices.size() else 0
	return str(price)


func _open_details(id: int) -> void:
	if _details_anim:
		return

	current_id = id
	_show_details(id)
	_reset_story_scroll()

	confirm_popup.visible = false
	_show_popup(details_popup, details_dim, details_panel)


func _show_details(id: int) -> void:
	details_preview_sprite.texture = db.textures[id]
	_apply_details_preview()

	details_name.text = db.names[id] if id < db.names.size() else ""
	details_story.text = db.stories[id] if id < db.stories.size() else ""

	var price := prices[id] if id < prices.size() else 0

	if GameState.is_character_unlocked(id):
		_set_buy_button_state(OWNED_TEXT, true)
		return

	if GameState.can_afford(price):
		_set_buy_button_state(BUY_TEXT + " (" + str(price) + " ★)", false)
	else:
		_set_buy_button_state(NOT_ENOUGH_TEXT, true)


func _apply_details_preview() -> void:
	call_deferred("_apply_details_preview_deferred")


func _apply_details_preview_deferred() -> void:
	if details_preview_center.size == Vector2.ZERO:
		call_deferred("_apply_details_preview_deferred")
		return

	details_preview_sprite.centered = true
	details_preview_sprite.position = details_preview_center.size * 0.5 + Vector2(0.0, DETAILS_PREVIEW_Y_BIAS)

	var tex := details_preview_sprite.texture
	if tex != null:
		var k := (details_preview_center.size.y * 0.85) / 64.0
		details_preview_sprite.scale = Vector2(k, k)
	else:
		details_preview_sprite.scale = Vector2.ONE


func _set_buy_button_state(text_value: String, disabled_value: bool) -> void:
	buy_button.disabled = disabled_value
	if is_instance_valid(buy_button_label):
		buy_button_label.text = text_value
	else:
		buy_button.text = text_value


func _close_details() -> void:
	if _details_anim:
		return
	pending_buy_id = -1
	confirm_popup.visible = false
	_hide_popup(details_popup, details_dim, details_panel)


func _on_buy_pressed() -> void:
	if buy_button.disabled or _confirm_anim:
		return

	var price := prices[current_id] if current_id < prices.size() else 0
	pending_buy_id = current_id
	confirm_label.text = "Vai tiešām vēlaties nopirkt?"
	_show_popup(confirm_popup, confirm_dim, confirm_panel)


func _confirm_yes() -> void:
	if pending_buy_id == -1:
		return

	var id := pending_buy_id
	var price := prices[id] if id < prices.size() else 0

	if GameState.spend_stars(price):
		GameState.unlock_character(id)

	pending_buy_id = -1
	_hide_popup(confirm_popup, confirm_dim, confirm_panel)

	_show_details(current_id)
	_build_grid()
	_refresh_top()


func _confirm_no() -> void:
	pending_buy_id = -1
	_hide_popup(confirm_popup, confirm_dim, confirm_panel)


func _on_back_pressed() -> void:
	SceneManager.goto_main_menu(SceneManager.Transition.DROP_UP)


func _on_button_mouse_entered() -> void:
	Cursor.set_hover()


func _on_button_mouse_exited() -> void:
	Cursor.set_normal()


func _reset_story_scroll() -> void:
	await get_tree().process_frame
	story_scroll.scroll_vertical = 0


func _show_popup(popup: Control, dim: ColorRect, panel: Control) -> void:
	if popup == details_popup:
		_details_anim = true
	if popup == confirm_popup:
		_confirm_anim = true

	popup.visible = true
	popup.mouse_filter = Control.MOUSE_FILTER_STOP

	if is_instance_valid(dim):
		dim.modulate.a = DIM_ALPHA

	if is_instance_valid(panel):
		await _center_pivot(panel)
		panel.modulate.a = 1.0
		panel.scale = Vector2.ONE * POP_FROM_SCALE

	var t := create_tween()
	if is_instance_valid(panel):
		t.tween_property(panel, "scale", Vector2.ONE, POP_DUR).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t.finished

	if popup == details_popup:
		_details_anim = false
	if popup == confirm_popup:
		_confirm_anim = false


func _hide_popup(popup: Control, dim: ColorRect, panel: Control) -> void:
	if popup == details_popup:
		_details_anim = true
	if popup == confirm_popup:
		_confirm_anim = true

	if is_instance_valid(panel):
		await _center_pivot(panel)

	var t := create_tween()
	t.set_parallel(true)

	if is_instance_valid(panel):
		t.tween_property(panel, "scale", Vector2.ONE * POP_FROM_SCALE, POP_DUR).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	if is_instance_valid(dim):
		t.tween_property(dim, "modulate:a", 0.0, POP_DUR).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await t.finished

	popup.visible = false
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if popup == details_popup:
		_details_anim = false
	if popup == confirm_popup:
		_confirm_anim = false
