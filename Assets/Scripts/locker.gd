extends Control

@export var db: CharacterDB
var characters: Array[Texture2D] = []

@onready var preview_center: Control = $Background/BigSign/CharacterBox/PreviewCenter
@onready var preview_sprite: Sprite2D = $Background/BigSign/CharacterBox/PreviewCenter/PreviewSprite

@onready var left_button: Button = $Background/LeftButton
@onready var right_button: Button = $Background/RightButton
@onready var select_button: Button = $Background/SelectButton
@onready var name_label: Label = $Background/Name
@onready var story_label: Label = $Background/StoryBox/StoryPad/Story
@onready var info_label: Label = $Background/InfoLabel

@onready var info_button: Button = $Background/InfoButton
@onready var info_bubble: Control = $Background/InfoBubble
@onready var info_bubble_text: Label = $Background/InfoBubble/Text

@onready var story_scroll: ScrollContainer = $Background/StoryBox

@onready var UIButtonSound: AudioStreamPlayer = $UIButtonSound
@onready var UIConfirmationSound: AudioStreamPlayer = $UIConfirmationSound

var unlocked_ids: Array[int] = []
var current_pos: int = 0
var info_pinned: bool = false

const PREVIEW_BASE := 64.0
const PREVIEW_FILL := 1.6
const PREVIEW_Y_BIAS := -40.0


func _ready() -> void:
	GameState.show_cursor()
	Cursor.set_normal()

	if db != null:
		characters = db.textures

	if characters.is_empty():
		return

	_rebuild_unlocked_list()

	if not unlocked_ids.has(GameState.selected_character_index):
		GameState.set_selected_character(0)

	current_pos = unlocked_ids.find(GameState.selected_character_index)
	if current_pos == -1:
		current_pos = 0

	_update_character()
	_style_story_scrollbar()

	info_bubble.visible = false
	info_bubble_text.text = "Tēla izskats neietekmē spēles gaitu, grūtību vai spējas. Tas ir tikai vizuāls noformējums — izvēlies to, kas patīk!"

	if GameState.has_signal("unlocks_changed"):
		GameState.connect("unlocks_changed", Callable(self, "_on_unlocks_changed"))


func _on_unlocks_changed() -> void:
	var current_id := _get_current_id()

	_rebuild_unlocked_list()

	if unlocked_ids.has(current_id):
		current_pos = unlocked_ids.find(current_id)
	else:
		current_pos = 0

	_update_character()


func _rebuild_unlocked_list() -> void:
	unlocked_ids.clear()

	for id in GameState.unlocked_characters:
		var i := int(id)
		if i >= 0 and i < characters.size():
			if not unlocked_ids.has(i):
				unlocked_ids.append(i)

	if not unlocked_ids.has(0):
		unlocked_ids.insert(0, 0)

	unlocked_ids.sort()


func _get_current_id() -> int:
	if unlocked_ids.is_empty():
		return 0
	return unlocked_ids[current_pos]


func _update_character() -> void:
	var id := _get_current_id()

	preview_sprite.texture = characters[id]
	_apply_preview()

	_update_select_button()

	if db != null:
		name_label.text = db.names[id] if id < db.names.size() else ""
		story_label.text = db.stories[id] if id < db.stories.size() else ""


func _apply_preview() -> void:
	call_deferred("_apply_preview_deferred")


func _apply_preview_deferred() -> void:
	if preview_center.size == Vector2.ZERO:
		call_deferred("_apply_preview_deferred")
		return

	preview_sprite.centered = true
	preview_sprite.position = preview_center.size * 0.5 + Vector2(0.0, PREVIEW_Y_BIAS)

	var tex := preview_sprite.texture
	if tex != null:
		var k := (preview_center.size.y * PREVIEW_FILL) / PREVIEW_BASE
		preview_sprite.scale = Vector2(k, k)
	else:
		preview_sprite.scale = Vector2.ONE


func _update_select_button() -> void:
	if unlocked_ids.size() <= 1:
		select_button.visible = false
		left_button.visible = false
		right_button.visible = false
		info_label.visible = true
		return

	info_label.visible = false
	left_button.visible = true
	right_button.visible = true

	var id := _get_current_id()
	select_button.visible = id != GameState.selected_character_index


func _on_left_button_pressed() -> void:
	if unlocked_ids.size() <= 1:
		print("Jums pagaidām ir atbloķēts tikai viens tēls.")
		return

	current_pos = (current_pos - 1 + unlocked_ids.size()) % unlocked_ids.size()
	UIButtonSound.play()
	_update_character()


func _on_right_button_pressed() -> void:
	if unlocked_ids.size() <= 1:
		print("Jums pagaidām ir atbloķēts tikai viens tēls.")
		return

	current_pos = (current_pos + 1) % unlocked_ids.size()
	UIButtonSound.play()
	_update_character()


func _on_select_button_pressed() -> void:
	UIConfirmationSound.play()
	var id := _get_current_id()
	GameState.set_selected_character(id)
	_update_select_button()


func _on_button_mouse_entered() -> void:
	Cursor.set_hover()


func _on_button_mouse_exited() -> void:
	Cursor.set_normal()


func _on_back_pressed() -> void:
	UIButtonSound.play()
	SceneManager.goto_main_menu(SceneManager.Transition.DROP_UP)


func _on_info_button_mouse_entered() -> void:
	Cursor.set_hover()
	info_bubble.visible = true


func _on_info_button_mouse_exited() -> void:
	Cursor.set_normal()
	if !info_pinned:
		info_bubble.visible = false


func _on_info_button_pressed() -> void:
	UIButtonSound.play()
	info_pinned = !info_pinned
	info_bubble.visible = info_pinned or info_button.is_hovered()


func _input(event: InputEvent) -> void:
	if !info_pinned:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var p: Vector2 = mb.position

			var on_button := info_button.get_global_rect().has_point(p)
			var on_bubble := info_bubble.get_global_rect().has_point(p)

			if !on_button and !on_bubble:
				info_pinned = false
				info_bubble.visible = false

func _style_story_scrollbar() -> void:
	var vbar := story_scroll.get_v_scroll_bar()

	var track := StyleBoxFlat.new()
	track.bg_color = Color("4a2416")
	track.border_color = Color("8a4a1f")
	track.set_border_width_all(2)
	track.corner_radius_top_left = 3
	track.corner_radius_top_right = 3
	track.corner_radius_bottom_left = 3
	track.corner_radius_bottom_right = 3

	var grabber := StyleBoxFlat.new()
	grabber.bg_color = Color("c56a1f")
	grabber.border_color = Color("f0b05a")
	grabber.set_border_width_all(2)
	grabber.corner_radius_top_left = 3
	grabber.corner_radius_top_right = 3
	grabber.corner_radius_bottom_left = 3
	grabber.corner_radius_bottom_right = 3

	var grabber_hover := StyleBoxFlat.new()
	grabber_hover.bg_color = Color("dc7c28")
	grabber_hover.border_color = Color("ffd27a")
	grabber_hover.set_border_width_all(2)
	grabber_hover.corner_radius_top_left = 3
	grabber_hover.corner_radius_top_right = 3
	grabber_hover.corner_radius_bottom_left = 3
	grabber_hover.corner_radius_bottom_right = 3

	var grabber_pressed := StyleBoxFlat.new()
	grabber_pressed.bg_color = Color("e39136")
	grabber_pressed.border_color = Color("fff0b0")
	grabber_pressed.set_border_width_all(2)
	grabber_pressed.corner_radius_top_left = 3
	grabber_pressed.corner_radius_top_right = 3
	grabber_pressed.corner_radius_bottom_left = 3
	grabber_pressed.corner_radius_bottom_right = 3

	vbar.add_theme_stylebox_override("scroll", track)
	vbar.add_theme_stylebox_override("grabber", grabber)
	vbar.add_theme_stylebox_override("grabber_highlight", grabber_hover)
	vbar.add_theme_stylebox_override("grabber_pressed", grabber_pressed)

	vbar.custom_minimum_size.x = 12
	
	vbar.mouse_entered.connect(_on_button_mouse_entered)
	vbar.mouse_exited.connect(_on_button_mouse_exited)
	
	vbar.gui_input.connect(_on_story_scrollbar_gui_input)

func _on_story_scrollbar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			UIButtonSound.play()
