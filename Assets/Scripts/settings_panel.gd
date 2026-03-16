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

@onready var brightness_slider: HSlider = %BrightnessSlider
@onready var brightness_spinbox: SpinBox = %BrightnessSpinBox

@export var ui_font: Font

func _ready() -> void:
	video_tab.pressed.connect(func(): _scroll_to_section(video_title))
	controls_tab.pressed.connect(func(): _scroll_to_section(controls_title))
	audio_tab.pressed.connect(func(): _scroll_to_section(audio_title))

	_fill_video_options()
	_load_video_values_into_ui()
	_style_option_button(window_mode_option)
	_style_option_button(vsync_option)
	_style_brightness_slider(brightness_slider)
	_style_brightness_spinbox(brightness_spinbox)

	brightness_slider.share(brightness_spinbox)
	brightness_slider.value_changed.connect(_on_brightness_changed)

	window_mode_option.item_selected.connect(_on_window_mode_selected)
	vsync_option.item_selected.connect(_on_vsync_selected)

	_style_scrollbar()


func _fill_video_options() -> void:
	window_mode_option.clear()
	window_mode_option.add_item("Logs", GameState.WINDOW_MODE_WINDOWED)
	window_mode_option.add_item("Pilnekrāns", GameState.WINDOW_MODE_FULLSCREEN)
	window_mode_option.add_item("Bez apmales", GameState.WINDOW_MODE_BORDERLESS)

	vsync_option.clear()
	vsync_option.add_item("Izsl.", 0)
	vsync_option.add_item("Iesl.", 1)


func _load_video_values_into_ui() -> void:
	window_mode_option.select(GameState.window_mode)

	if GameState.vsync_enabled:
		vsync_option.select(1)
	else:
		vsync_option.select(0)

	brightness_slider.value = GameState.brightness_percent
	window_mode_option.select(GameState.window_mode)

	if GameState.vsync_enabled:
		vsync_option.select(1)
	else:
		vsync_option.select(0)


func _on_window_mode_selected(index: int) -> void:
	GameState.set_window_mode_setting(index)


func _on_vsync_selected(index: int) -> void:
	GameState.set_vsync_enabled_setting(index == 1)


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

	sb.add_theme_icon_override("updown", _make_spinbox_arrows(Color("f1f3ff")))

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
	sb.alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	sb.add_theme_constant_override("buttons_width", 12)
	sb.add_theme_constant_override("field_and_buttons_separation", 0)

	if ui_font != null:
		line_edit.add_theme_font_override("font", ui_font)

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
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton

		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var spin_rect := Rect2(
				brightness_spinbox.global_position,
				brightness_spinbox.size
			)

			if not spin_rect.has_point(mb.global_position):
				get_viewport().gui_release_focus()
