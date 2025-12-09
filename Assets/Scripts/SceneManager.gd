extends Node

const MAIN_MENU = "res://Assets/Scenes/main_menu.tscn" 
const LEVELS_MENU = "res://Assets/Scenes/levels_menu.tscn" 
const SHOP = "res://Assets/Scenes/shop.tscn" 
const LOCKER = "res://Assets/Scenes/locker.tscn" 
const SETTINGS = "res://Assets/Scenes/settings.tscn" 

func goto_main_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU)

func goto_levels_menu() -> void:
	get_tree().change_scene_to_file(LEVELS_MENU)

func goto_shop() -> void:
	get_tree().change_scene_to_file(SHOP)
	
func goto_locker() -> void:
	get_tree().change_scene_to_file(LOCKER)
	
func goto_settings() -> void:
	get_tree().change_scene_to_file(SETTINGS)

func quit_game() -> void:
	get_tree().quit()
