extends Node

const SAVE_PATH := "user://player_settings.cfg"
const SECTION := "player"

var selected_character_index: int = 0

func _ready() -> void:
	_load_selected_character()


func set_selected_character(index: int) -> void:
	selected_character_index = index
	_save_selected_character()


func _save_selected_character() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		pass

	cfg.set_value(SECTION, "selected_character_index", selected_character_index)
	cfg.save(SAVE_PATH)


func _load_selected_character() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err == OK:
		selected_character_index = int(
			cfg.get_value(SECTION, "selected_character_index", 0)
		)
	else:
		selected_character_index = 0
