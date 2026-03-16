extends CenterContainer

@onready var content_scroll: ScrollContainer = $Panel/Pad/Root/Body/RightWrap/ContentPanel/ContentScroll

@onready var video_tab: Button = $Panel/Pad/Root/Body/LeftMenu/VideoTab
@onready var controls_tab: Button = $Panel/Pad/Root/Body/LeftMenu/ControlsTab
@onready var audio_tab: Button = $Panel/Pad/Root/Body/LeftMenu/AudioTab

@onready var video_title: Control = $Panel/Pad/Root/Body/RightWrap/ContentPanel/ContentScroll/ContentPad/Sections/VideoTitle
@onready var controls_title: Control = $Panel/Pad/Root/Body/RightWrap/ContentPanel/ContentScroll/ContentPad/Sections/ControlsTitle
@onready var audio_title: Control = $Panel/Pad/Root/Body/RightWrap/ContentPanel/ContentScroll/ContentPad/Sections/AudioTitle

@onready var window_mode_option: OptionButton = $Panel/Pad/Root/Body/RightWrap/ContentPanel/ContentScroll/ContentPad/Sections/VideoSection/VideoRows/ModeRow/ModeOption
@onready var vsync_option: OptionButton = $Panel/Pad/Root/Body/RightWrap/ContentPanel/ContentScroll/ContentPad/Sections/VideoSection/VideoRows/VSyncRow/VSyncOption
@onready var show_fps_option: OptionButton = $Panel/Pad/Root/Body/RightWrap/ContentPanel/ContentScroll/ContentPad/Sections/VideoSection/VideoRows/ShowFpsRow/ShowFpsOption

@onready var brightness_slider: HSlider = %BrightnessSlider
@onready var brightness_spinbox: SpinBox = %BrightnessSpinBox

@onready var move_left_bind_1: Button = $Panel/Pad/Root/Body/RightWrap/ContentPanel/ContentScroll/ContentPad/Sections/ControlsSection/ControlsList/MoveLeftRow/HBoxContainer/Bind1
@onready var move_left_bind_2: Button = $Panel/Pad/Root/Body/RightWrap/ContentPanel/ContentScroll/ContentPad/Sections/ControlsSection/ControlsList/MoveLeftRow/HBoxContainer/Bind2

@onready var move_right_bind_1: Button = $Panel/Pad/Root/Body/RightWrap/ContentPanel/ContentScroll/ContentPad/Sections/ControlsSection/ControlsList/MoveRightRow/HBoxContainer/Bind1
@onready var move_right_bind_2: Button = $Panel/Pad/Root/Body/RightWrap/ContentPanel/ContentScroll/ContentPad/Sections/ControlsSection/ControlsList/MoveRightRow/HBoxContainer/Bind2

@onready var jump_bind_1: Button = $Panel/Pad/Root/Body/RightWrap/ContentPanel/ContentScroll/ContentPad/Sections/ControlsSection/ControlsList/JumpRow/HBoxContainer/Bind1
@onready var jump_bind_2: Button = $Panel/Pad/Root/Body/RightWrap/ContentPanel/ContentScroll/ContentPad/Sections/ControlsSection/ControlsList/JumpRow/HBoxContainer/Bind2

@onready var crouch_bind_1: Button = $Panel/Pad/Root/Body/RightWrap/ContentPanel/ContentScroll/ContentPad/Sections/ControlsSection/ControlsList/CrouchRow/HBoxContainer/Bind1
@onready var crouch_bind_2: Button = $Panel/Pad/Root/Body/RightWrap/ContentPanel/ContentScroll/ContentPad/Sections/ControlsSection/ControlsList/CrouchRow/HBoxContainer/Bind2

@onready var pause_bind_1: Button = $Panel/Pad/Root/Body/RightWrap/ContentPanel/ContentScroll/ContentPad/Sections/ControlsSection/ControlsList/PauseRow/HBoxContainer/Bind1
@onready var pause_bind_2: Button = $Panel/Pad/Root/Body/RightWrap/ContentPanel/ContentScroll/ContentPad/Sections/ControlsSection/ControlsList/PauseRow/HBoxContainer/Bind2

@onready var reset_controls_button: Button = $Panel/Pad/Root/Body/RightWrap/ContentPanel/ContentScroll/ContentPad/Sections/ControlsSection/ResetControlsButton

var _rebind_action: StringName = &""
var _rebind_slot: int = -1
var _rebind_button: Button = null
var _rebind_armed: bool = false

var _controls_actions: Array[StringName] = [
	&"move_left",
	&"move_right",
	&"jump",
	&"crouch",
	&"ui_cancel"
]

@export var ui_font: Font

func _ready() -> void:
	video_tab.pressed.connect(func(): _scroll_to_section(video_title))
	controls_tab.pressed.connect(func(): _scroll_to_section(controls_title))
	audio_tab.pressed.connect(func(): _scroll_to_section(audio_title))
	
	move_left_bind_1.pressed.connect(func(): _begin_rebind(&"move_left", 0, move_left_bind_1))
	move_left_bind_2.pressed.connect(func(): _begin_rebind(&"move_left", 1, move_left_bind_2))

	move_right_bind_1.pressed.connect(func(): _begin_rebind(&"move_right", 0, move_right_bind_1))
	move_right_bind_2.pressed.connect(func(): _begin_rebind(&"move_right", 1, move_right_bind_2))

	jump_bind_1.pressed.connect(func(): _begin_rebind(&"jump", 0, jump_bind_1))
	jump_bind_2.pressed.connect(func(): _begin_rebind(&"jump", 1, jump_bind_2))

	crouch_bind_1.pressed.connect(func(): _begin_rebind(&"crouch", 0, crouch_bind_1))
	crouch_bind_2.pressed.connect(func(): _begin_rebind(&"crouch", 1, crouch_bind_2))

	pause_bind_1.pressed.connect(func(): _begin_rebind(&"ui_cancel", 0, pause_bind_1))
	pause_bind_2.pressed.connect(func(): _begin_rebind(&"ui_cancel", 1, pause_bind_2))
	
	reset_controls_button.pressed.connect(_on_reset_controls_pressed)

	_fill_video_options()
	_load_video_values_into_ui()
	_load_controls_values_into_ui()
	_style_option_button(window_mode_option)
	_style_option_button(vsync_option)
	_style_option_button(show_fps_option)
	_style_brightness_slider(brightness_slider)
	_style_brightness_spinbox(brightness_spinbox)

	brightness_slider.share(brightness_spinbox)
	brightness_slider.value_changed.connect(_on_brightness_changed)

	window_mode_option.item_selected.connect(_on_window_mode_selected)
	vsync_option.item_selected.connect(_on_vsync_selected)
	show_fps_option.item_selected.connect(_on_show_fps_selected)

	_style_scrollbar()
	_setup_tooltip_theme()
	
	var bind_buttons: Array[Button] = [
		move_left_bind_1, move_left_bind_2,
		move_right_bind_1, move_right_bind_2,
		jump_bind_1, jump_bind_2,
		crouch_bind_1, crouch_bind_2,
		pause_bind_1, pause_bind_2
	]

	for b in bind_buttons:
		_style_bind_button(b)

	_style_reset_button(reset_controls_button)


func _fill_video_options() -> void:
	window_mode_option.clear()
	window_mode_option.add_item("Logs", GameState.WINDOW_MODE_WINDOWED)
	window_mode_option.add_item("Pilnekrāns", GameState.WINDOW_MODE_FULLSCREEN)
	window_mode_option.add_item("Bez apmales", GameState.WINDOW_MODE_BORDERLESS)

	vsync_option.clear()
	vsync_option.add_item("Izsl.", 0)
	vsync_option.add_item("Iesl.", 1)
	
	show_fps_option.clear()
	show_fps_option.add_item("Izsl.", 0)
	show_fps_option.add_item("Iesl.", 1)


func _load_video_values_into_ui() -> void:
	window_mode_option.select(GameState.window_mode)

	if GameState.vsync_enabled:
		vsync_option.select(1)
	else:
		vsync_option.select(0)

	if GameState.show_fps:
		show_fps_option.select(1)
	else:
		show_fps_option.select(0)

	brightness_slider.value = GameState.brightness_percent


func _on_window_mode_selected(index: int) -> void:
	GameState.set_window_mode_setting(index)


func _on_vsync_selected(index: int) -> void:
	GameState.set_vsync_enabled_setting(index == 1)

func _on_show_fps_selected(index: int) -> void:
	GameState.set_show_fps_setting(index == 1)

func _scroll_to_section(section: Control) -> void:
	content_scroll.scroll_vertical = int(section.position.y)


func _style_scrollbar() -> void:
	var vbar := content_scroll.get_v_scroll_bar()

	var track := StyleBoxFlat.new()
	track.bg_color = Color("241614")
	track.border_color = Color("4a302f")
	track.set_border_width_all(1)
	track.corner_radius_top_left = 2
	track.corner_radius_top_right = 2
	track.corner_radius_bottom_left = 2
	track.corner_radius_bottom_right = 2

	var grabber := StyleBoxFlat.new()
	grabber.bg_color = Color("6b4a46")
	grabber.border_color = Color("8a6258")
	grabber.set_border_width_all(1)
	grabber.corner_radius_top_left = 2
	grabber.corner_radius_top_right = 2
	grabber.corner_radius_bottom_left = 2
	grabber.corner_radius_bottom_right = 2

	var grabber_hover := StyleBoxFlat.new()
	grabber_hover.bg_color = Color("8a6258")
	grabber_hover.border_color = Color("a97a6b")
	grabber_hover.set_border_width_all(1)
	grabber_hover.corner_radius_top_left = 2
	grabber_hover.corner_radius_top_right = 2
	grabber_hover.corner_radius_bottom_left = 2
	grabber_hover.corner_radius_bottom_right = 2

	var grabber_pressed := StyleBoxFlat.new()
	grabber_pressed.bg_color = Color("a97a6b")
	grabber_pressed.border_color = Color("e8f3ff")
	grabber_pressed.set_border_width_all(1)
	grabber_pressed.corner_radius_top_left = 2
	grabber_pressed.corner_radius_top_right = 2
	grabber_pressed.corner_radius_bottom_left = 2
	grabber_pressed.corner_radius_bottom_right = 2

	vbar.add_theme_stylebox_override("scroll", track)
	vbar.add_theme_stylebox_override("grabber", grabber)
	vbar.add_theme_stylebox_override("grabber_highlight", grabber_hover)
	vbar.add_theme_stylebox_override("grabber_pressed", grabber_pressed)

	vbar.custom_minimum_size.x = 10


func _on_button_mouse_entered() -> void:
	Cursor.set_hover()


func _on_button_mouse_exited() -> void:
	Cursor.set_normal()


func _style_option_button(ob: OptionButton) -> void:
	ob.alignment = HORIZONTAL_ALIGNMENT_LEFT

	var normal := _make_box("1f1312", "6b4a46")
	var hover := _make_box("2c1a18", "8a6258")
	var pressed := _make_box("3a211f", "a97a6b")
	var focus := _make_box("241614", "e8f3ff")

	normal.content_margin_left = 12
	normal.content_margin_right = 30
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6

	hover.content_margin_left = 12
	hover.content_margin_right = 30
	hover.content_margin_top = 6
	hover.content_margin_bottom = 6

	pressed.content_margin_left = 12
	pressed.content_margin_right = 30
	pressed.content_margin_top = 6
	pressed.content_margin_bottom = 6

	focus.content_margin_left = 12
	focus.content_margin_right = 30
	focus.content_margin_top = 6
	focus.content_margin_bottom = 6

	ob.add_theme_stylebox_override("normal", normal)
	ob.add_theme_stylebox_override("hover", hover)
	ob.add_theme_stylebox_override("pressed", pressed)
	ob.add_theme_stylebox_override("focus", focus)

	ob.add_theme_color_override("font_color", Color("f1f3ff"))
	ob.add_theme_color_override("font_hover_color", Color("ffffff"))
	ob.add_theme_color_override("font_pressed_color", Color("ffffff"))
	ob.add_theme_color_override("font_focus_color", Color("ffffff"))
	ob.add_theme_color_override("font_outline_color", Color("221210"))
	ob.add_theme_font_size_override("font_size", 18)
	ob.add_theme_constant_override("outline_size", 8)

	ob.add_theme_constant_override("arrow_margin", 10)
	ob.add_theme_constant_override("modulate_arrow", 1)

	if ui_font != null:
		ob.add_theme_font_override("font", ui_font)

	var popup := ob.get_popup()
	_style_option_popup(popup)
	
	popup.mouse_entered.connect(_on_button_mouse_entered)
	popup.mouse_exited.connect(_on_button_mouse_exited)
	popup.popup_hide.connect(_on_button_mouse_exited)


func _style_option_popup(popup: PopupMenu) -> void:
	var panel := _make_box("1b100f", "6b4a46")
	panel.content_margin_left = 4
	panel.content_margin_right = 4
	panel.content_margin_top = 4
	panel.content_margin_bottom = 4

	var hover := _make_box("3a211f", "a97a6b")
	hover.content_margin_left = 6
	hover.content_margin_right = 6
	hover.content_margin_top = 3
	hover.content_margin_bottom = 3

	popup.add_theme_stylebox_override("panel", panel)
	popup.add_theme_stylebox_override("hover", hover)

	popup.add_theme_color_override("font_color", Color("f1f3ff"))
	popup.add_theme_color_override("font_hover_color", Color("ffffff"))
	popup.add_theme_color_override("font_disabled_color", Color("9b8f8d"))
	popup.add_theme_color_override("font_outline_color", Color("221210"))

	popup.add_theme_font_size_override("font_size", 18)
	popup.add_theme_constant_override("outline_size", 8)

	popup.add_theme_constant_override("item_start_padding", 10)
	popup.add_theme_constant_override("item_end_padding", 10)
	popup.add_theme_constant_override("v_separation", 4)

	if ui_font != null:
		popup.add_theme_font_override("font", ui_font)

func _style_brightness_slider(sl: HSlider) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = Color("241614")
	track.border_color = Color("4a302f")
	track.set_border_width_all(2)
	track.corner_radius_top_left = 4
	track.corner_radius_top_right = 4
	track.corner_radius_bottom_left = 4
	track.corner_radius_bottom_right = 4

	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("6b4a46")
	fill.border_color = Color("8a6258")
	fill.set_border_width_all(2)
	fill.corner_radius_top_left = 4
	fill.corner_radius_top_right = 4
	fill.corner_radius_bottom_left = 4
	fill.corner_radius_bottom_right = 4

	var fill_hover := StyleBoxFlat.new()
	fill_hover.bg_color = Color("8a6258")
	fill_hover.border_color = Color("a97a6b")
	fill_hover.set_border_width_all(2)
	fill_hover.corner_radius_top_left = 4
	fill_hover.corner_radius_top_right = 4
	fill_hover.corner_radius_bottom_left = 4
	fill_hover.corner_radius_bottom_right = 4

	sl.add_theme_stylebox_override("slider", track)
	sl.add_theme_stylebox_override("grabber_area", fill)
	sl.add_theme_stylebox_override("grabber_area_highlight", fill_hover)

func _style_brightness_spinbox(sb: SpinBox) -> void:
	var normal := _make_box("1f1312", "6b4a46")
	var hover := _make_box("2c1a18", "8a6258")
	var focus := _make_box("1f1312", "6b4a46")

	normal.content_margin_left = 8
	normal.content_margin_right = 8
	normal.content_margin_top = 4
	normal.content_margin_bottom = 4

	hover.content_margin_left = 8
	hover.content_margin_right = 8
	hover.content_margin_top = 4
	hover.content_margin_bottom = 4

	focus.content_margin_left = 8
	focus.content_margin_right = 8
	focus.content_margin_top = 4
	focus.content_margin_bottom = 4

	var line_edit := sb.get_line_edit()
	if line_edit == null:
		return

	line_edit.add_theme_stylebox_override("normal", normal)
	line_edit.add_theme_stylebox_override("hover", hover)
	line_edit.add_theme_stylebox_override("focus", focus)
	line_edit.add_theme_stylebox_override("read_only", normal)

	line_edit.add_theme_color_override("font_color", Color("f1f3ff"))
	line_edit.add_theme_color_override("font_hover_color", Color("ffffff"))
	line_edit.add_theme_color_override("font_focus_color", Color("f1f3ff"))
	line_edit.add_theme_color_override("font_selected_color", Color("ffffff"))
	line_edit.add_theme_color_override("selection_color", Color("6b4a46"))
	line_edit.add_theme_color_override("caret_color", Color("ffffff"))
	line_edit.add_theme_color_override("font_outline_color", Color("221210"))

	line_edit.add_theme_font_size_override("font_size", 16)
	line_edit.add_theme_constant_override("outline_size", 8)

	if ui_font != null:
		line_edit.add_theme_font_override("font", ui_font)

	sb.alignment = HORIZONTAL_ALIGNMENT_CENTER

	sb.add_theme_constant_override("buttons_width", 26)
	sb.add_theme_constant_override("field_and_buttons_separation", 6)
	sb.add_theme_constant_override("buttons_vertical_separation", 2)
	sb.add_theme_constant_override("set_min_buttons_width_from_icons", 0)

	sb.add_theme_icon_override("up", _make_spin_arrow(true, Color("f1f3ff")))
	sb.add_theme_icon_override("down", _make_spin_arrow(false, Color("f1f3ff")))

	sb.add_theme_icon_override("up_hover", _make_spin_arrow(true, Color("ffffff")))
	sb.add_theme_icon_override("down_hover", _make_spin_arrow(false, Color("ffffff")))

	sb.add_theme_icon_override("up_pressed", _make_spin_arrow(true, Color("ffffff")))
	sb.add_theme_icon_override("down_pressed", _make_spin_arrow(false, Color("ffffff")))

	sb.add_theme_icon_override("up_disabled", _make_spin_arrow(true, Color("9b8f8d")))
	sb.add_theme_icon_override("down_disabled", _make_spin_arrow(false, Color("9b8f8d")))

	var btn_normal := _make_spin_btn_box("1a1110", "6b4a46")
	var btn_hover := _make_spin_btn_box("241614", "8a6258")
	var btn_pressed := _make_spin_btn_box("3a211f", "a97a6b")
	var btn_disabled := _make_spin_btn_box("1a1110", "3e2a28")

	sb.add_theme_stylebox_override("up_background", btn_normal)
	sb.add_theme_stylebox_override("down_background", btn_normal)

	sb.add_theme_stylebox_override("up_background_hovered", btn_hover)
	sb.add_theme_stylebox_override("down_background_hovered", btn_hover)

	sb.add_theme_stylebox_override("up_background_pressed", btn_pressed)
	sb.add_theme_stylebox_override("down_background_pressed", btn_pressed)

	sb.add_theme_stylebox_override("up_background_disabled", btn_disabled)
	sb.add_theme_stylebox_override("down_background_disabled", btn_disabled)

	var transparent_sep := StyleBoxFlat.new()
	transparent_sep.bg_color = Color(0, 0, 0, 0)

	sb.add_theme_stylebox_override("field_and_buttons_separator", transparent_sep)
	sb.add_theme_stylebox_override("up_down_buttons_separator", transparent_sep)

func _make_spin_btn_box(bg_hex: String, border_hex: String) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(bg_hex)
	sb.border_color = Color(border_hex)
	sb.set_border_width_all(2)
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	return sb

func _make_spin_arrow(is_up: bool, color: Color) -> Texture2D:
	var img := Image.create(12, 11, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	if is_up:
		for x in range(5, 7):
			img.set_pixel(x, 4, color)
		for x in range(4, 8):
			img.set_pixel(x, 5, color)
		for x in range(3, 9):
			img.set_pixel(x, 6, color)
	else:
		for x in range(3, 9):
			img.set_pixel(x, 4, color)
		for x in range(4, 8):
			img.set_pixel(x, 5, color)
		for x in range(5, 7):
			img.set_pixel(x, 6, color)

	return ImageTexture.create_from_image(img)

func _make_box(bg_hex: String, border_hex: String) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(bg_hex)
	sb.border_color = Color(border_hex)
	sb.set_border_width_all(2)
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	return sb

func _make_spinbox_arrows(color: Color) -> Texture2D:
	var img := Image.create(12, 18, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	img.set_pixel(6, 3, color)
	img.set_pixel(5, 4, color)
	img.set_pixel(6, 4, color)
	img.set_pixel(7, 4, color)
	img.set_pixel(4, 5, color)
	img.set_pixel(5, 5, color)
	img.set_pixel(6, 5, color)
	img.set_pixel(7, 5, color)
	img.set_pixel(8, 5, color)

	img.set_pixel(4, 12, color)
	img.set_pixel(5, 12, color)
	img.set_pixel(6, 12, color)
	img.set_pixel(7, 12, color)
	img.set_pixel(8, 12, color)
	img.set_pixel(5, 13, color)
	img.set_pixel(6, 13, color)
	img.set_pixel(7, 13, color)
	img.set_pixel(6, 14, color)

	return ImageTexture.create_from_image(img)

func _on_brightness_changed(value: float) -> void:
	GameState.set_brightness_percent_setting(int(value))

func _input(event: InputEvent) -> void:
	if _rebind_button != null:
		if not _rebind_armed:
			return

		if event is InputEventKey:
			var key_event := event as InputEventKey

			if not key_event.pressed or key_event.echo:
				return

			if _rebind_slot < 0 or _rebind_action == &"":
				return

			var key_conflict := _find_conflict_action(_rebind_action, key_event)
			if key_conflict != &"":
				var busy_button := _rebind_button
				_rebind_action = &""
				_rebind_slot = -1
				_rebind_button = null
				_rebind_armed = false
				_show_bind_busy(busy_button)
				get_viewport().set_input_as_handled()
				return

			_apply_input_rebind(_rebind_action, _rebind_slot, key_event)
			GameState.save_controls_overrides()
			GameState.notify_controls_changed()
			_load_controls_values_into_ui()

			_rebind_action = &""
			_rebind_slot = -1
			_rebind_button = null
			_rebind_armed = false

			get_viewport().set_input_as_handled()
			return

		if event is InputEventMouseButton:
			var mouse_event := event as InputEventMouseButton

			if not mouse_event.pressed:
				return

			if _rebind_slot < 0 or _rebind_action == &"":
				return

			var mouse_conflict := _find_conflict_action(_rebind_action, mouse_event)
			if mouse_conflict != &"":
				var busy_button := _rebind_button
				_rebind_action = &""
				_rebind_slot = -1
				_rebind_button = null
				_rebind_armed = false
				_show_bind_busy(busy_button)
				get_viewport().set_input_as_handled()
				return

			_apply_input_rebind(_rebind_action, _rebind_slot, mouse_event)
			GameState.save_controls_overrides()
			GameState.notify_controls_changed()
			_load_controls_values_into_ui()

			_rebind_action = &""
			_rebind_slot = -1
			_rebind_button = null
			_rebind_armed = false

			get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton

		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var spin_rect := Rect2(
				brightness_spinbox.global_position,
				brightness_spinbox.size
			)

			if not spin_rect.has_point(mb.global_position):
				get_viewport().gui_release_focus()

func _load_controls_values_into_ui() -> void:
	_set_action_binds(&"move_left", move_left_bind_1, move_left_bind_2)
	_set_action_binds(&"move_right", move_right_bind_1, move_right_bind_2)
	_set_action_binds(&"jump", jump_bind_1, jump_bind_2)
	_set_action_binds(&"crouch", crouch_bind_1, crouch_bind_2)
	_set_action_binds(&"ui_cancel", pause_bind_1, pause_bind_2)

func _set_action_binds(action_name: StringName, bind1: Button, bind2: Button) -> void:
	bind1.text = "—"
	bind2.text = "—"

	var events := InputMap.action_get_events(action_name)
	var shown := 0

	for event in events:
		var text := _input_event_to_text(event)
		if text == "":
			continue

		if shown == 0:
			bind1.text = text
		elif shown == 1:
			bind2.text = text
		else:
			break

		shown += 1

func _input_event_to_text(event: InputEvent) -> String:
	if event is InputEventKey:
		var key_event := event as InputEventKey

		if key_event.physical_keycode != KEY_NONE:
			return OS.get_keycode_string(key_event.physical_keycode)

		if key_event.keycode != KEY_NONE:
			return OS.get_keycode_string(key_event.keycode)

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton

		match mouse_event.button_index:
			MOUSE_BUTTON_LEFT:
				return "LMB"
			MOUSE_BUTTON_RIGHT:
				return "RMB"
			MOUSE_BUTTON_MIDDLE:
				return "MMB"
			MOUSE_BUTTON_XBUTTON1:
				return "X1"
			MOUSE_BUTTON_XBUTTON2:
				return "X2"

	return ""

func _begin_rebind(action_name: StringName, slot: int, button: Button) -> void:
	_rebind_action = action_name
	_rebind_slot = slot
	_rebind_button = button
	_rebind_button.text = "..."
	_rebind_armed = false
	call_deferred("_arm_rebind")

func _apply_input_rebind(action_name: StringName, slot: int, source_event: InputEvent) -> void:
	if slot < 0:
		return

	var events := InputMap.action_get_events(action_name)

	var bindable_events: Array[InputEvent] = []
	var other_events: Array[InputEvent] = []

	for e in events:
		if e is InputEventKey or e is InputEventMouseButton:
			bindable_events.append(e)
		else:
			other_events.append(e)

	var new_event := source_event.duplicate()

	if slot >= 0 and slot < bindable_events.size():
		bindable_events[slot] = new_event
	elif slot == bindable_events.size():
		bindable_events.append(new_event)
	else:
		return

	InputMap.action_erase_events(action_name)

	for e in other_events:
		InputMap.action_add_event(action_name, e)

	for e in bindable_events:
		InputMap.action_add_event(action_name, e)

func _arm_rebind() -> void:
	if _rebind_button != null:
		_rebind_armed = true

func _events_match(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventKey and b is InputEventKey:
		var ak := a as InputEventKey
		var bk := b as InputEventKey

		if ak.physical_keycode != KEY_NONE and bk.physical_keycode != KEY_NONE:
			return ak.physical_keycode == bk.physical_keycode

		return ak.keycode == bk.keycode

	if a is InputEventMouseButton and b is InputEventMouseButton:
		var am := a as InputEventMouseButton
		var bm := b as InputEventMouseButton
		return am.button_index == bm.button_index

	return false


func _find_conflict_action(action_name: StringName, candidate_event: InputEvent) -> StringName:
	for other_action in _controls_actions:
		if other_action == action_name:
			continue

		var events := InputMap.action_get_events(other_action)
		for e in events:
			if _events_match(e, candidate_event):
				return other_action

	return &""

func _show_bind_busy(button: Button) -> void:
	button.text = "Aizņemts"
	await get_tree().create_timer(0.8).timeout
	_load_controls_values_into_ui()

func _on_reset_controls_pressed() -> void:
	_rebind_action = &""
	_rebind_slot = -1
	_rebind_button = null
	_rebind_armed = false

	GameState.reset_controls_to_default()
	GameState.notify_controls_changed()
	_load_controls_values_into_ui()

func _style_bind_button(btn: Button) -> void:
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.custom_minimum_size = Vector2(92, 42)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var normal := _make_box("1a1110", "3e2a28")
	var hover := _make_box("241614", "8a6258")
	var pressed := _make_box("3a211f", "a97a6b")
	var focus := _make_box("241614", "e8f3ff")

	normal.content_margin_left = 8
	normal.content_margin_right = 8
	normal.content_margin_top = 4
	normal.content_margin_bottom = 4

	hover.content_margin_left = 8
	hover.content_margin_right = 8
	hover.content_margin_top = 4
	hover.content_margin_bottom = 4

	pressed.content_margin_left = 8
	pressed.content_margin_right = 8
	pressed.content_margin_top = 4
	pressed.content_margin_bottom = 4

	focus.content_margin_left = 8
	focus.content_margin_right = 8
	focus.content_margin_top = 4
	focus.content_margin_bottom = 4

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", focus)

	btn.add_theme_color_override("font_color", Color("f1f3ff"))
	btn.add_theme_color_override("font_hover_color", Color("ffffff"))
	btn.add_theme_color_override("font_pressed_color", Color("ffffff"))
	btn.add_theme_color_override("font_focus_color", Color("ffffff"))
	btn.add_theme_color_override("font_outline_color", Color("221210"))

	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_constant_override("outline_size", 8)

	if ui_font != null:
		btn.add_theme_font_override("font", ui_font)

func _style_reset_button(btn: Button) -> void:
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.custom_minimum_size = Vector2(0, 44)

	var normal := _make_box("1a1110", "4a302f")
	var hover := _make_box("2c1a18", "8a6258")
	var pressed := _make_box("3a211f", "a97a6b")
	var focus := _make_box("241614", "e8f3ff")

	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6

	hover.content_margin_left = 12
	hover.content_margin_right = 12
	hover.content_margin_top = 6
	hover.content_margin_bottom = 6

	pressed.content_margin_left = 12
	pressed.content_margin_right = 12
	pressed.content_margin_top = 6
	pressed.content_margin_bottom = 6

	focus.content_margin_left = 12
	focus.content_margin_right = 12
	focus.content_margin_top = 6
	focus.content_margin_bottom = 6

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", focus)

	btn.add_theme_color_override("font_color", Color("f1f3ff"))
	btn.add_theme_color_override("font_hover_color", Color("ffffff"))
	btn.add_theme_color_override("font_pressed_color", Color("ffffff"))
	btn.add_theme_color_override("font_focus_color", Color("ffffff"))
	btn.add_theme_color_override("font_outline_color", Color("221210"))

	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_constant_override("outline_size", 8)

	if ui_font != null:
		btn.add_theme_font_override("font", ui_font)

func _on_back_pressed() -> void:
	SceneManager.goto_main_menu(SceneManager.Transition.DROP_UP)

func _setup_tooltip_theme() -> void:
	if theme == null:
		theme = Theme.new()

	var panel_sb := StyleBoxFlat.new()
	panel_sb.bg_color = Color("241614")
	panel_sb.border_color = Color("8a6258")
	panel_sb.set_border_width_all(2)
	panel_sb.corner_radius_top_left = 6
	panel_sb.corner_radius_top_right = 6
	panel_sb.corner_radius_bottom_left = 6
	panel_sb.corner_radius_bottom_right = 6
	panel_sb.content_margin_left = 10
	panel_sb.content_margin_right = 10
	panel_sb.content_margin_top = 6
	panel_sb.content_margin_bottom = 6

	theme.set_stylebox("panel", "TooltipPanel", panel_sb)
	theme.set_color("font_color", "TooltipLabel", Color("e8f3ff"))
	theme.set_color("font_outline_color", "TooltipLabel", Color("1a0d06"))
	theme.set_color("font_shadow_color", "TooltipLabel", Color("0000007f"))
	theme.set_constant("outline_size", "TooltipLabel", 2)
	theme.set_constant("shadow_offset_x", "TooltipLabel", 2)
	theme.set_constant("shadow_offset_y", "TooltipLabel", 2)
	theme.set_font_size("font_size", "TooltipLabel", 16)

	if ui_font != null:
		theme.set_font("font", "TooltipLabel", ui_font)
