extends Control

@export var db: CharacterDB
@export var card_scene: PackedScene
@export var prices: Array[int] = []

@onready var stars_count: Label = $Background/StarsUI/StarsCount
@onready var back_button: Button = $Background/BackButton
@onready var grid: GridContainer = $Background/Grid

@onready var details_popup: Control = $Background/DetailsPopup
@onready var details_sprite: TextureRect = $Background/DetailsPopup/Panel/CharacterSprite
@onready var details_name: Label = $Background/DetailsPopup/Panel/NameLabel
@onready var details_story: Label = $Background/DetailsPopup/Panel/StoryLabel
@onready var details_status: Label = $Background/DetailsPopup/Panel/StatusLabel
@onready var buy_button: Button = $Background/DetailsPopup/Panel/BuyButton
@onready var close_button: Button = $Background/DetailsPopup/Panel/CloseButton
@onready var left_arrow: Button = $Background/DetailsPopup/Panel/LeftArrow
@onready var right_arrow: Button = $Background/DetailsPopup/Panel/RightArrow

@onready var confirm_popup: Control = $Background/ConfirmPopup
@onready var confirm_label: Label = $Background/ConfirmPopup/Panel/ConfirmLabel
@onready var yes_button: Button = $Background/ConfirmPopup/Panel/YesButton
@onready var no_button: Button = $Background/ConfirmPopup/Panel/NoButton

var current_id: int = 0
var pending_buy_id: int = -1


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

	back_button.pressed.connect(_on_back_pressed)
	close_button.pressed.connect(_close_details)
	left_arrow.pressed.connect(_prev_character)
	right_arrow.pressed.connect(_next_character)
	buy_button.pressed.connect(_on_buy_pressed)

	yes_button.pressed.connect(_confirm_yes)
	no_button.pressed.connect(_confirm_no)

	if GameState.has_signal("unlocks_changed"):
		GameState.connect("unlocks_changed", Callable(self, "_refresh_all"))
	if GameState.has_signal("stars_spent_changed"):
		GameState.connect("stars_spent_changed", Callable(self, "_refresh_all"))

	details_popup.visible = false
	confirm_popup.visible = false


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

	for id in range(db.textures.size()):
		var card := card_scene.instantiate() as ShopCard
		grid.add_child(card)

		card.setup(id, db.textures[id], _card_text(id))
		card.card_pressed.connect(_open_details)


func _card_text(id: int) -> String:
	if GameState.is_character_unlocked(id):
		return "KUPLENO"
	var price := prices[id] if id < prices.size() else 0
	return str(price) + " ★"


func _open_details(id: int) -> void:
	current_id = id
	_show_details(id)
	details_popup.visible = true
	confirm_popup.visible = false


func _show_details(id: int) -> void:
	details_sprite.texture = db.textures[id]
	details_name.text = db.names[id] if id < db.names.size() else ""
	details_story.text = db.stories[id] if id < db.stories.size() else ""

	if GameState.is_character_unlocked(id):
		details_status.text = "KUPLENO"
		buy_button.disabled = true
	else:
		var price := prices[id] if id < prices.size() else 0
		details_status.text = str(price) + " ★"
		buy_button.disabled = not GameState.can_afford(price)


func _close_details() -> void:
	details_popup.visible = false
	confirm_popup.visible = false
	pending_buy_id = -1


func _prev_character() -> void:
	var count := db.textures.size()
	current_id = (current_id - 1 + count) % count
	_show_details(current_id)


func _next_character() -> void:
	var count := db.textures.size()
	current_id = (current_id + 1) % count
	_show_details(current_id)


func _on_buy_pressed() -> void:
	if GameState.is_character_unlocked(current_id):
		return

	var price := prices[current_id] if current_id < prices.size() else 0
	if not GameState.can_afford(price):
		return

	pending_buy_id = current_id
	confirm_label.text = "Pirkt par " + str(price) + " ★ ?"
	confirm_popup.visible = true


func _confirm_yes() -> void:
	if pending_buy_id == -1:
		return

	var id := pending_buy_id
	var price := prices[id] if id < prices.size() else 0

	if GameState.spend_stars(price):
		GameState.unlock_character(id)

	pending_buy_id = -1
	confirm_popup.visible = false

	_show_details(current_id)
	_build_grid()
	_refresh_top()


func _confirm_no() -> void:
	pending_buy_id = -1
	confirm_popup.visible = false


func _on_back_pressed() -> void:
	SceneManager.goto_main_menu(SceneManager.Transition.DROP_UP)
