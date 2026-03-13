extends CenterContainer

@onready var content_scroll: ScrollContainer = $Panel/Pad/Root/Body/RightWrap/ContentPanel/ContentScroll

@onready var video_tab: Button = $Panel/Pad/Root/Body/LeftMenu/VideoTab
@onready var controls_tab: Button = $Panel/Pad/Root/Body/LeftMenu/ControlsTab
@onready var audio_tab: Button = $Panel/Pad/Root/Body/LeftMenu/AudioTab

@onready var video_title: Control = $Panel/Pad/Root/Body/RightWrap/ContentPanel/ContentScroll/ContentPad/Sections/VideoTitle
@onready var controls_title: Control = $Panel/Pad/Root/Body/RightWrap/ContentPanel/ContentScroll/ContentPad/Sections/ControlsTitle
@onready var audio_title: Control = $Panel/Pad/Root/Body/RightWrap/ContentPanel/ContentScroll/ContentPad/Sections/AudioTitle

@onready var window_mode_option: OptionButton = $Panel/Pad/Root/Body/RightWrap/ContentPanel/ContentScroll/ContentPad/Sections/VideoSection/VideoRows/ModeRow/ModeOption
@onready var resolution_option: OptionButton = $Panel/Pad/Root/Body/RightWrap/ContentPanel/ContentScroll/ContentPad/Sections/VideoSection/VideoRows/ResolutionRow/ResolutionOption


func _ready() -> void:
	video_tab.pressed.connect(func(): _scroll_to_section(video_title))
	controls_tab.pressed.connect(func(): _scroll_to_section(controls_title))
	audio_tab.pressed.connect(func(): _scroll_to_section(audio_title))

	_fill_video_options()
	_load_video_values_into_ui()

	window_mode_option.item_selected.connect(_on_window_mode_selected)
	resolution_option.item_selected.connect(_on_resolution_selected)

	_style_scrollbar()


func _fill_video_options() -> void:
	window_mode_option.clear()
	window_mode_option.add_item("Logs", GameState.WINDOW_MODE_WINDOWED)
	window_mode_option.add_item("Pilnekrāns", GameState.WINDOW_MODE_FULLSCREEN)
	window_mode_option.add_item("Bez apmales", GameState.WINDOW_MODE_BORDERLESS)

	resolution_option.clear()
	resolution_option.add_item("16:9", GameState.RESOLUTION_MODE_16_9)
	resolution_option.add_item("4:3", GameState.RESOLUTION_MODE_4_3)
	resolution_option.add_item("1:1", GameState.RESOLUTION_MODE_1_1)


func _load_video_values_into_ui() -> void:
	window_mode_option.select(GameState.window_mode)
	resolution_option.select(GameState.resolution_mode)


func _on_window_mode_selected(index: int) -> void:
	GameState.set_window_mode_setting(index)


func _on_resolution_selected(index: int) -> void:
	GameState.set_resolution_mode_setting(index)


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
