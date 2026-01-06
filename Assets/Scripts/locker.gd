extends Control

@export var db: CharacterDB
var characters: Array[Texture2D] = []

@onready var character_sprite: TextureRect = $Background/BigSign/CharacterBox/CharacterSprite
@onready var left_button: Button = $Background/LeftButton
@onready var right_button: Button = $Background/RightButton
@onready var select_button: Button = $Background/SelectButton
@onready var name_label: Label = $Background/Name
@onready var story_label: Label = $Background/StoryBox/Story
@onready var info_label: Label = $Background/InfoLabel


var current_index: int = 0

func _ready() -> void:
	Cursor.set_normal()

	if db != null:
		characters = db.textures

	if characters.is_empty():
		return

	current_index = clamp(GameState.selected_character_index, 0, characters.size() - 1)
	_update_character()


func _update_character() -> void:
	character_sprite.texture = characters[current_index]
	_update_select_button()

	if db != null:
		if current_index < db.names.size():
			name_label.text = db.names[current_index]
		else:
			name_label.text = ""

		if current_index < db.stories.size():
			story_label.text = db.stories[current_index]
		else:
			story_label.text = ""


func _update_select_button() -> void:
	if characters.size() <= 1:
		select_button.visible = false
		left_button.visible = false
		right_button.visible = false
		info_label.visible = true
		return

	info_label.visible = false
	left_button.visible = true
	right_button.visible = true
	select_button.visible = current_index != GameState.selected_character_index



func _on_left_button_pressed() -> void:
	if characters.size() <= 1:
		print("Jums pagaidām ir atbloķēts tikai viens tēls.")
		return

	current_index = (current_index - 1 + characters.size()) % characters.size()
	_update_character()


func _on_right_button_pressed() -> void:
	if characters.size() <= 1:
		print("Jums pagaidām ir atbloķēts tikai viens tēls.")
		return

	current_index = (current_index + 1) % characters.size()
	_update_character()


func _on_select_button_pressed() -> void:
	GameState.set_selected_character(current_index)
	_update_select_button()


func _on_button_mouse_entered() -> void:
	Cursor.set_hover()


func _on_button_mouse_exited() -> void:
	Cursor.set_normal()


func _on_back_pressed() -> void:
	SceneManager.goto_main_menu(SceneManager.Transition.DROP_UP)
