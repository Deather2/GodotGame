extends Node

signal selected_character_changed(new_index: int)
signal unlocks_changed
signal stars_spent_changed

const SETTINGS_PATH := "user://settings.cfg"
const PROGRESS_PATH := "user://progress.cfg"

const PLAYER_SECTION := "player"
const PROGRESS_SECTION := "progress"
const VIDEO_SECTION := "video"

const LEVEL_COUNT := 13

const WINDOW_MODE_WINDOWED := 0
const WINDOW_MODE_FULLSCREEN := 1
const WINDOW_MODE_BORDERLESS := 2

const RESOLUTION_MODE_16_9 := 0
const RESOLUTION_MODE_4_3 := 1
const RESOLUTION_MODE_1_1 := 2

var selected_character_index: int = 0
var stars_per_level: Array[int] = []
var best_time_per_level: Array[float] = []
var unlocked_characters: Array[int] = []
var stars_spent: int = 0

var window_mode: int = WINDOW_MODE_WINDOWED
var resolution_mode: int = RESOLUTION_MODE_16_9

var _window_apply_busy: bool = false
var _window_reapply_requested: bool = false
var _last_windowed_size: Vector2i = Vector2i(1152, 648)


func _ready() -> void:
	_load_video_settings()

	if not Engine.is_embedded_in_editor():
		call_deferred("_apply_window_mode_setting")

	_load_selected_character()
	_load_level_progress()
	_load_shop_progress()


func _init_default_video_settings() -> void:
	window_mode = WINDOW_MODE_WINDOWED
	resolution_mode = RESOLUTION_MODE_16_9


func _save_video_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value(VIDEO_SECTION, "window_mode", window_mode)
	cfg.set_value(VIDEO_SECTION, "resolution_mode", resolution_mode)
	cfg.save(SETTINGS_PATH)


func _load_video_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	var err: int = cfg.load(SETTINGS_PATH)

	if err != OK:
		_init_default_video_settings()
		_save_video_settings()
		return

	window_mode = int(cfg.get_value(VIDEO_SECTION, "window_mode", WINDOW_MODE_WINDOWED))
	resolution_mode = int(cfg.get_value(VIDEO_SECTION, "resolution_mode", RESOLUTION_MODE_16_9))

	if window_mode < WINDOW_MODE_WINDOWED or window_mode > WINDOW_MODE_BORDERLESS:
		window_mode = WINDOW_MODE_WINDOWED

	if resolution_mode < RESOLUTION_MODE_16_9 or resolution_mode > RESOLUTION_MODE_1_1:
		resolution_mode = RESOLUTION_MODE_16_9


func set_window_mode_setting(mode: int) -> void:
	if mode < WINDOW_MODE_WINDOWED or mode > WINDOW_MODE_BORDERLESS:
		return

	var win := get_tree().root
	if win != null and win.mode == Window.MODE_WINDOWED and not win.borderless:
		if win.size.x > 0 and win.size.y > 0:
			_last_windowed_size = win.size

	window_mode = mode
	_save_video_settings()

	if not Engine.is_embedded_in_editor():
		_apply_window_mode_setting()


func set_resolution_mode_setting(mode: int) -> void:
	if mode < RESOLUTION_MODE_16_9 or mode > RESOLUTION_MODE_1_1:
		return

	resolution_mode = mode
	_save_video_settings()


func _apply_video_settings() -> void:
	if Engine.is_embedded_in_editor():
		return

	_apply_window_mode_setting()


func _apply_resolution_setting() -> void:
	return


func _wait_window_frames(count: int = 2) -> void:
	for _i in range(count):
		await get_tree().process_frame


func _apply_window_mode_setting() -> void:
	if Engine.is_embedded_in_editor():
		return

	if _window_apply_busy:
		_window_reapply_requested = true
		return

	var win := get_tree().root
	if win == null:
		return

	_window_apply_busy = true

	var screen := win.current_screen
	var screen_pos := DisplayServer.screen_get_position(screen)
	var screen_size := DisplayServer.screen_get_size(screen)
	var usable_rect := DisplayServer.screen_get_usable_rect(screen)

	if _last_windowed_size.x <= 0 or _last_windowed_size.y <= 0:
		_last_windowed_size = Vector2i(
			int(usable_rect.size.x / 2),
			int(usable_rect.size.y / 2)
		)

	match window_mode:
		WINDOW_MODE_WINDOWED:
			win.mode = Window.MODE_WINDOWED
			await _wait_window_frames(2)

			win.borderless = false
			win.unresizable = false
			await _wait_window_frames(2)

			win.size = _last_windowed_size
			await _wait_window_frames(2)

			win.move_to_center()

		WINDOW_MODE_FULLSCREEN:
			win.borderless = false
			await _wait_window_frames(1)

			win.mode = Window.MODE_FULLSCREEN

		WINDOW_MODE_BORDERLESS:
			win.mode = Window.MODE_WINDOWED
			await _wait_window_frames(2)

			win.unresizable = false
			win.borderless = true
			await _wait_window_frames(2)

			win.position = screen_pos
			win.size = screen_size

	_window_apply_busy = false

	if _window_reapply_requested:
		_window_reapply_requested = false
		call_deferred("_apply_window_mode_setting")


func _get_resolution_base_size() -> Vector2i:
	match resolution_mode:
		RESOLUTION_MODE_16_9:
			return Vector2i(320, 180)
		RESOLUTION_MODE_4_3:
			return Vector2i(240, 180)
		RESOLUTION_MODE_1_1:
			return Vector2i(180, 180)
		_:
			return Vector2i(320, 180)


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
