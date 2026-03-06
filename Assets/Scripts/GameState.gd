extends Node

signal selected_character_changed(new_index: int)
signal unlocks_changed
signal stars_spent_changed

const SETTINGS_PATH := "user://settings.cfg"
const PROGRESS_PATH := "user://progress.cfg"

const PLAYER_SECTION := "player"
const PROGRESS_SECTION := "progress"

const LEVEL_COUNT := 13

var selected_character_index: int = 0
var stars_per_level: Array[int] = []

var best_time_per_level: Array[float] = []

var unlocked_characters: Array[int] = []
var stars_spent: int = 0


func _ready() -> void:
	_load_selected_character()
	_load_level_progress()
	_load_shop_progress()

func set_selected_character(index: int) -> void:
	if index == selected_character_index:
		return

	selected_character_index = index
	_save_selected_character()
	emit_signal("selected_character_changed", selected_character_index)

func _save_selected_character() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(PROGRESS_PATH)
	cfg.set_value(PLAYER_SECTION, "selected_character_index", selected_character_index)
	cfg.save(PROGRESS_PATH)

func _load_selected_character() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	var err: int = cfg.load(PROGRESS_PATH)
	if err == OK:
		selected_character_index = int(cfg.get_value(PLAYER_SECTION, "selected_character_index", 0))
	else:
		selected_character_index = 0

func _init_default_progress() -> void:
	stars_per_level.resize(LEVEL_COUNT)
	for i in range(LEVEL_COUNT):
		stars_per_level[i] = 0

	best_time_per_level.resize(LEVEL_COUNT)
	for i in range(LEVEL_COUNT):
		best_time_per_level[i] = -1.0

func _save_level_progress() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(PROGRESS_PATH)
	cfg.set_value(PROGRESS_SECTION, "stars_per_level", stars_per_level)
	cfg.set_value(PROGRESS_SECTION, "best_time_per_level", best_time_per_level)
	cfg.save(PROGRESS_PATH)

func _load_level_progress() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	var err: int = cfg.load(PROGRESS_PATH)
	if err != OK:
		_init_default_progress()
		return

	var arr: Variant = cfg.get_value(PROGRESS_SECTION, "stars_per_level", null)
	if arr == null:
		_init_default_progress()
		return

	if arr is Array:
		stars_per_level.clear()
		for v in (arr as Array):
			stars_per_level.append(int(v))
	else:
		_init_default_progress()
		return

	var times: Variant = cfg.get_value(PROGRESS_SECTION, "best_time_per_level", null)
	if times is Array:
		best_time_per_level.clear()
		for v in (times as Array):
			best_time_per_level.append(float(v))
	else:
		best_time_per_level.resize(LEVEL_COUNT)
		for i in range(LEVEL_COUNT):
			best_time_per_level[i] = -1.0

	if stars_per_level.size() < LEVEL_COUNT:
		while stars_per_level.size() < LEVEL_COUNT:
			stars_per_level.append(0)
	elif stars_per_level.size() > LEVEL_COUNT:
		stars_per_level = stars_per_level.slice(0, LEVEL_COUNT)

	if best_time_per_level.size() < LEVEL_COUNT:
		while best_time_per_level.size() < LEVEL_COUNT:
			best_time_per_level.append(-1.0)
	elif best_time_per_level.size() > LEVEL_COUNT:
		best_time_per_level = best_time_per_level.slice(0, LEVEL_COUNT)

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


func _init_default_shop() -> void:
	unlocked_characters = [0] 
	stars_spent = 0

func _save_shop_progress() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(PROGRESS_PATH)
	cfg.set_value(PROGRESS_SECTION, "unlocked_characters", unlocked_characters)
	cfg.set_value(PROGRESS_SECTION, "stars_spent", stars_spent)
	cfg.save(PROGRESS_PATH)

func _load_shop_progress() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	var err: int = cfg.load(PROGRESS_PATH)
	if err != OK:
		_init_default_shop()
		_save_shop_progress()
		return

	var unlocked: Variant = cfg.get_value(PROGRESS_SECTION, "unlocked_characters", null)
	if unlocked is Array:
		unlocked_characters.clear()
		for v in (unlocked as Array):
			unlocked_characters.append(int(v))
	else:
		unlocked_characters = [0]

	if not unlocked_characters.has(0):
		unlocked_characters.insert(0, 0)

	stars_spent = int(cfg.get_value(PROGRESS_SECTION, "stars_spent", 0))
	if stars_spent < 0:
		stars_spent = 0

func is_character_unlocked(id: int) -> bool:
	return unlocked_characters.has(id)

func unlock_character(id: int) -> void:
	if id < 0:
		return
	if unlocked_characters.has(id):
		return
	unlocked_characters.append(id)
	_save_shop_progress()
	emit_signal("unlocks_changed")

func get_total_stars() -> int:
	var sum := 0
	for s in stars_per_level:
		sum += int(s)
	return sum

func get_available_stars() -> int:
	return max(get_total_stars() - stars_spent, 0)

func can_afford(price: int) -> bool:
	return get_available_stars() >= price

func spend_stars(price: int) -> bool:
	if price <= 0:
		return true
	if not can_afford(price):
		return false
	stars_spent += price
	_save_shop_progress()
	emit_signal("stars_spent_changed")
	return true

func reset_all_progress_keep_settings() -> void:
	_init_default_progress()
	selected_character_index = 0
	_init_default_shop()

	_save_level_progress()
	_save_selected_character()
	_save_shop_progress()

	emit_signal("selected_character_changed", selected_character_index)
	emit_signal("unlocks_changed")
	emit_signal("stars_spent_changed")

func has_any_progress() -> bool:
	if selected_character_index != 0:
		return true

	for s in stars_per_level:
		if s > 0:
			return true

	if stars_spent > 0:
		return true
	if unlocked_characters.size() > 1:
		return true

	return false

func save_level_result(level_index: int, stars: int, time_sec: float) -> void:
	if level_index < 0 or level_index >= LEVEL_COUNT:
		return

	stars = clamp(stars, 0, 3)

	var old_stars := stars_per_level[level_index]
	var old_time := best_time_per_level[level_index]

	var should_update := false

	if stars > old_stars:
		should_update = true
	elif stars == old_stars:
		if old_time < 0.0 or time_sec < old_time:
			should_update = true

	if should_update:
		stars_per_level[level_index] = stars
		best_time_per_level[level_index] = time_sec
		_save_level_progress()
