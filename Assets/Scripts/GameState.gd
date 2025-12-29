extends Node

const SAVE_PATH := "user://player_settings.cfg"

const PLAYER_SECTION := "player"
const PROGRESS_SECTION := "progress"

const LEVEL_COUNT := 13

var selected_character_index: int = 0
var stars_per_level: Array[int] = []

func _ready() -> void:
	_load_selected_character()
	_load_level_progress()

# --------------------------
# Персонаж
# --------------------------
func set_selected_character(index: int) -> void:
	selected_character_index = index
	_save_selected_character()

func _save_selected_character() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH) # если файла нет — ок

	cfg.set_value(PLAYER_SECTION, "selected_character_index", selected_character_index)
	cfg.save(SAVE_PATH)

func _load_selected_character() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err == OK:
		selected_character_index = int(cfg.get_value(PLAYER_SECTION, "selected_character_index", 0))
	else:
		selected_character_index = 0

# --------------------------
# Прогресс уровней
# --------------------------
func _init_default_progress() -> void:
	stars_per_level.resize(LEVEL_COUNT)
	for i in range(LEVEL_COUNT):
		stars_per_level[i] = 0

func _save_level_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH) # если файла нет — ок

	cfg.set_value(PROGRESS_SECTION, "stars_per_level", stars_per_level)
	cfg.save(SAVE_PATH)

func _load_level_progress() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		_init_default_progress()
		return

	var arr = cfg.get_value(PROGRESS_SECTION, "stars_per_level", null)
	if arr == null:
		_init_default_progress()
		return

	stars_per_level = arr

	if stars_per_level.size() < LEVEL_COUNT:
		while stars_per_level.size() < LEVEL_COUNT:
			stars_per_level.append(0)
	elif stars_per_level.size() > LEVEL_COUNT:
		stars_per_level = stars_per_level.slice(0, LEVEL_COUNT)

func is_level_unlocked(level_index: int) -> bool:
	if level_index <= 0:
		return true
	return stars_per_level[level_index - 1] > 0

func set_level_stars(level_index: int, stars: int) -> void:
	if level_index < 0 or level_index >= LEVEL_COUNT:
		return

	stars = clamp(stars, 0, 3)
	stars_per_level[level_index] = max(stars_per_level[level_index], stars)
	_save_level_progress()

func reset_level_progress() -> void:
	_init_default_progress()
	_save_level_progress()
