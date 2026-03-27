extends Node

signal selected_character_changed(new_index: int)
signal unlocks_changed
signal stars_spent_changed

signal controls_changed

const SETTINGS_PATH := "user://settings.cfg"
const PROGRESS_PATH := "user://progress.cfg"

const PLAYER_SECTION := "player"
const PROGRESS_SECTION := "progress"
const VIDEO_SECTION := "video"
const AUDIO_SECTION := "audio"
const MIN_BUS_DB := -80.0

const LEVEL_COUNT := 13

const WINDOW_MODE_WINDOWED := 0
const WINDOW_MODE_FULLSCREEN := 1
const WINDOW_MODE_BORDERLESS := 2

var selected_character_index: int = 0
var stars_per_level: Array[int] = []
var best_time_per_level: Array[float] = []
var unlocked_characters: Array[int] = []
var stars_spent: int = 0

var window_mode: int = WINDOW_MODE_WINDOWED
var vsync_enabled: bool = true

var brightness_percent: int = 50

var _brightness_layer: CanvasLayer
var _brightness_black: ColorRect
var _brightness_white: ColorRect

var _window_apply_busy: bool = false
var _window_reapply_requested: bool = false
var _last_windowed_size: Vector2i = Vector2i(1152, 648)
var _last_windowed_was_maximized: bool = false

var show_fps: bool = false

var menu_music_volume_percent: int = 100
var ui_volume_percent: int = 100
var sfx_volume_percent: int = 100
var level_music_volume_percent: int = 100

const CONTROLS_SECTION := "controls"
const CONTROLS_BINDS_KEY := "bindings"

var _controls_actions: Array[StringName] = [
	&"move_left",
	&"move_right",
	&"jump",
	&"crouch",
	&"ui_cancel"
]

var _default_controls: Dictionary = {}

func _ready() -> void:
	_load_video_settings()
	_load_audio_settings()
	_capture_default_controls()
	_load_controls_settings()

	call_deferred("_setup_brightness_overlay")

	if not Engine.is_embedded_in_editor():
		call_deferred("_apply_video_settings")

	call_deferred("_apply_audio_settings")

	_load_selected_character()
	_load_level_progress()
	_load_shop_progress()

func _setup_brightness_overlay() -> void:
	_ensure_brightness_overlay()
	_apply_brightness_setting()


func _init_default_video_settings() -> void:
	window_mode = WINDOW_MODE_WINDOWED
	vsync_enabled = true
	brightness_percent = 50
	show_fps = false

	menu_music_volume_percent = 100
	ui_volume_percent = 100
	sfx_volume_percent = 100
	level_music_volume_percent = 100


func _save_video_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value(VIDEO_SECTION, "window_mode", window_mode)
	cfg.set_value(VIDEO_SECTION, "vsync_enabled", vsync_enabled)
	cfg.set_value(VIDEO_SECTION, "brightness_percent", brightness_percent)
	cfg.set_value(VIDEO_SECTION, "show_fps", show_fps)
	cfg.save(SETTINGS_PATH)


func _load_video_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	var err: int = cfg.load(SETTINGS_PATH)

	if err != OK:
		_init_default_video_settings()
		_save_video_settings()
		return

	window_mode = int(cfg.get_value(VIDEO_SECTION, "window_mode", WINDOW_MODE_WINDOWED))
	vsync_enabled = bool(cfg.get_value(VIDEO_SECTION, "vsync_enabled", true))
	brightness_percent = int(cfg.get_value(VIDEO_SECTION, "brightness_percent", 50))
	brightness_percent = clamp(brightness_percent, 0, 100)
	show_fps = bool(cfg.get_value(VIDEO_SECTION, "show_fps", false))

	if window_mode < WINDOW_MODE_WINDOWED or window_mode > WINDOW_MODE_BORDERLESS:
		window_mode = WINDOW_MODE_WINDOWED


func set_window_mode_setting(mode: int) -> void:
	if mode < WINDOW_MODE_WINDOWED or mode > WINDOW_MODE_BORDERLESS:
		return

	var win := get_tree().root
	if win != null and not win.borderless:
		if win.mode == Window.MODE_MAXIMIZED:
			_last_windowed_was_maximized = true
		elif win.mode == Window.MODE_WINDOWED:
			_last_windowed_was_maximized = false
			if win.size.x > 0 and win.size.y > 0:
				_last_windowed_size = win.size

	window_mode = mode
	_save_video_settings()

	if not Engine.is_embedded_in_editor():
		_apply_window_mode_setting()


func set_vsync_enabled_setting(enabled: bool) -> void:
	vsync_enabled = enabled
	_save_video_settings()

	if not Engine.is_embedded_in_editor():
		_apply_vsync_setting()


func _apply_video_settings() -> void:
	if Engine.is_embedded_in_editor():
		return

	_apply_vsync_setting()
	_apply_window_mode_setting()


func _apply_vsync_setting() -> void:
	if vsync_enabled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)


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

	if win.mode == Window.MODE_MAXIMIZED or win.mode == Window.MODE_FULLSCREEN:
		win.mode = Window.MODE_WINDOWED
		await _wait_window_frames(2)

	if win.borderless:
		win.borderless = false
		await _wait_window_frames(1)

	match window_mode:
		WINDOW_MODE_WINDOWED:
			win.mode = Window.MODE_WINDOWED
			await _wait_window_frames(2)

			win.borderless = false
			win.unresizable = false
			await _wait_window_frames(1)

			if _last_windowed_was_maximized:
				win.mode = Window.MODE_MAXIMIZED
			else:
				win.size = _last_windowed_size
				await _wait_window_frames(2)

				win.move_to_center()
				await _wait_window_frames(1)

				win.size = _last_windowed_size

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

func set_brightness_percent_setting(value: int) -> void:
	brightness_percent = clamp(value, 0, 100)
	_save_video_settings()
	_apply_brightness_setting()


func _ensure_brightness_overlay() -> void:
	if _brightness_layer != null and is_instance_valid(_brightness_layer):
		return

	var root := get_tree().root
	if root == null:
		return

	_brightness_layer = CanvasLayer.new()
	_brightness_layer.name = "BrightnessOverlayLayer"
	_brightness_layer.layer = 1000

	_brightness_black = ColorRect.new()
	_brightness_black.name = "BrightnessBlack"
	_brightness_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_brightness_black.color = Color(0, 0, 0, 0)
	_brightness_black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_brightness_white = ColorRect.new()
	_brightness_white.name = "BrightnessWhite"
	_brightness_white.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_brightness_white.color = Color(1, 1, 1, 0)
	_brightness_white.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	root.add_child(_brightness_layer)
	root.move_child(_brightness_layer, root.get_child_count() - 1)
	_brightness_layer.add_child(_brightness_black)
	_brightness_layer.add_child(_brightness_white)


func _apply_brightness_setting() -> void:
	_ensure_brightness_overlay()

	if _brightness_black == null or _brightness_white == null:
		return

	if brightness_percent < 50:
		var t := float(50 - brightness_percent) / 50.0
		_brightness_black.color = Color(0, 0, 0, t * 0.85)
		_brightness_white.color = Color(1, 1, 1, 0.0)
	elif brightness_percent > 50:
		var t := float(brightness_percent - 50) / 50.0
		_brightness_black.color = Color(0, 0, 0, 0.0)
		_brightness_white.color = Color(1, 1, 1, t * 0.45)
	else:
		_brightness_black.color = Color(0, 0, 0, 0.0)
		_brightness_white.color = Color(1, 1, 1, 0.0)

func set_show_fps_setting(enabled: bool) -> void:
	if show_fps == enabled:
		return

	show_fps = enabled
	_save_video_settings()
	SceneManager.update_fps_counter()


func _capture_default_controls() -> void:
	_default_controls.clear()

	for action_name in _controls_actions:
		_default_controls[String(action_name)] = _serialize_action_events(action_name)

func _serialize_action_events(action_name: StringName) -> Array:
	var result: Array = []

	for event in InputMap.action_get_events(action_name):
		var data := _event_to_data(event)
		if not data.is_empty():
			result.append(data)

	return result

func _event_to_data(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		return {
			"type": "key",
			"keycode": int(key_event.keycode),
			"physical_keycode": int(key_event.physical_keycode),
			"shift": key_event.shift_pressed,
			"ctrl": key_event.ctrl_pressed,
			"alt": key_event.alt_pressed,
			"meta": key_event.meta_pressed
		}

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		return {
			"type": "mouse",
			"button_index": int(mouse_event.button_index),
			"shift": mouse_event.shift_pressed,
			"ctrl": mouse_event.ctrl_pressed,
			"alt": mouse_event.alt_pressed,
			"meta": mouse_event.meta_pressed
		}

	return {}

func _data_to_event(data: Dictionary) -> InputEvent:
	var event_type := String(data.get("type", ""))

	if event_type == "key":
		var key_event := InputEventKey.new()
		key_event.keycode = int(data.get("keycode", 0))
		key_event.physical_keycode = int(data.get("physical_keycode", 0))
		key_event.shift_pressed = bool(data.get("shift", false))
		key_event.ctrl_pressed = bool(data.get("ctrl", false))
		key_event.alt_pressed = bool(data.get("alt", false))
		key_event.meta_pressed = bool(data.get("meta", false))
		return key_event

	if event_type == "mouse":
		var mouse_event := InputEventMouseButton.new()
		mouse_event.button_index = int(data.get("button_index", 0))
		mouse_event.shift_pressed = bool(data.get("shift", false))
		mouse_event.ctrl_pressed = bool(data.get("ctrl", false))
		mouse_event.alt_pressed = bool(data.get("alt", false))
		mouse_event.meta_pressed = bool(data.get("meta", false))
		return mouse_event

	return null


func _apply_serialized_events(action_name: StringName, saved_events: Array) -> void:
	var other_events: Array[InputEvent] = []

	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey or event is InputEventMouseButton:
			continue
		other_events.append(event)

	InputMap.action_erase_events(action_name)

	for event in other_events:
		InputMap.action_add_event(action_name, event)

	for item in saved_events:
		if item is Dictionary:
			var restored_event := _data_to_event(item)
			if restored_event != null:
				InputMap.action_add_event(action_name, restored_event)

func _bind_arrays_equal(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false

	for i in range(a.size()):
		if not _bind_data_equal(a[i], b[i]):
			return false

	return true


func _bind_data_equal(a: Variant, b: Variant) -> bool:
	if not (a is Dictionary) or not (b is Dictionary):
		return false

	var da := a as Dictionary
	var db := b as Dictionary

	return (
		String(da.get("type", "")) == String(db.get("type", "")) and
		int(da.get("keycode", 0)) == int(db.get("keycode", 0)) and
		int(da.get("physical_keycode", 0)) == int(db.get("physical_keycode", 0)) and
		int(da.get("button_index", 0)) == int(db.get("button_index", 0)) and
		bool(da.get("shift", false)) == bool(db.get("shift", false)) and
		bool(da.get("ctrl", false)) == bool(db.get("ctrl", false)) and
		bool(da.get("alt", false)) == bool(db.get("alt", false)) and
		bool(da.get("meta", false)) == bool(db.get("meta", false))
	)

func save_controls_overrides() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)

	var overrides := {}

	for action_name in _controls_actions:
		var key := String(action_name)
		var current_events := _serialize_action_events(action_name)
		var default_events: Array = _default_controls.get(key, [])

		if not _bind_arrays_equal(current_events, default_events):
			overrides[key] = current_events

	cfg.set_value(CONTROLS_SECTION, CONTROLS_BINDS_KEY, overrides)
	cfg.save(SETTINGS_PATH)

func _load_controls_settings() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SETTINGS_PATH)
	if err != OK:
		return

	var overrides: Variant = cfg.get_value(CONTROLS_SECTION, CONTROLS_BINDS_KEY, {})
	if not (overrides is Dictionary):
		return

	var binds_dict := overrides as Dictionary

	for action_name in _controls_actions:
		var key := String(action_name)

		if not binds_dict.has(key):
			continue

		var saved_events: Variant = binds_dict[key]
		if saved_events is Array:
			_apply_serialized_events(action_name, saved_events as Array)

func reset_controls_to_default() -> void:
	for action_name in _controls_actions:
		var key := String(action_name)
		var default_events_variant: Variant = _default_controls.get(key, [])
		var default_events: Array = default_events_variant as Array
		_apply_serialized_events(action_name, default_events)

	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value(CONTROLS_SECTION, CONTROLS_BINDS_KEY, {})
	cfg.save(SETTINGS_PATH)

func notify_controls_changed() -> void:
	controls_changed.emit()

func show_cursor() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func hide_cursor() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _save_audio_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value(AUDIO_SECTION, "menu_music_volume_percent", menu_music_volume_percent)
	cfg.set_value(AUDIO_SECTION, "ui_volume_percent", ui_volume_percent)
	cfg.set_value(AUDIO_SECTION, "sfx_volume_percent", sfx_volume_percent)
	cfg.set_value(AUDIO_SECTION, "level_music_volume_percent", level_music_volume_percent)
	cfg.save(SETTINGS_PATH)


func _load_audio_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	var err: int = cfg.load(SETTINGS_PATH)

	if err != OK:
		menu_music_volume_percent = 100
		ui_volume_percent = 100
		sfx_volume_percent = 100
		level_music_volume_percent = 100
		_save_audio_settings()
		return

	menu_music_volume_percent = clampi(int(cfg.get_value(AUDIO_SECTION, "menu_music_volume_percent", 100)), 0, 100)
	ui_volume_percent = clampi(int(cfg.get_value(AUDIO_SECTION, "ui_volume_percent", 100)), 0, 100)
	sfx_volume_percent = clampi(int(cfg.get_value(AUDIO_SECTION, "sfx_volume_percent", 100)), 0, 100)
	level_music_volume_percent = clampi(int(cfg.get_value(AUDIO_SECTION, "level_music_volume_percent", 100)), 0, 100)


func _apply_audio_settings() -> void:
	_apply_bus_volume_percent("MenuMusic", menu_music_volume_percent)
	_apply_bus_volume_percent("UI", ui_volume_percent)
	_apply_bus_volume_percent("SFX", sfx_volume_percent)
	_apply_bus_volume_percent("LevelMusic", level_music_volume_percent)


func _apply_bus_volume_percent(bus_name: String, percent: int) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return

	var linear: float = clampf(float(percent) / 100.0, 0.0, 1.0)
	var db: float = MIN_BUS_DB if linear <= 0.0 else linear_to_db(linear)
	AudioServer.set_bus_volume_db(bus_index, db)


func set_menu_music_volume_setting(value: int) -> void:
	menu_music_volume_percent = clampi(value, 0, 100)
	_apply_bus_volume_percent("MenuMusic", menu_music_volume_percent)
	_save_audio_settings()


func set_ui_volume_setting(value: int) -> void:
	ui_volume_percent = clampi(value, 0, 100)
	_apply_bus_volume_percent("UI", ui_volume_percent)
	_save_audio_settings()


func set_sfx_volume_setting(value: int) -> void:
	sfx_volume_percent = clampi(value, 0, 100)
	_apply_bus_volume_percent("SFX", sfx_volume_percent)
	_save_audio_settings()


func set_level_music_volume_setting(value: int) -> void:
	level_music_volume_percent = clampi(value, 0, 100)
	_apply_bus_volume_percent("LevelMusic", level_music_volume_percent)
	_save_audio_settings()
