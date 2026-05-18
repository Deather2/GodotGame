extends Control

@export var cps := 28.0
@export var hint_text := "Nospied jebkuru pogu, lai turpinātu..."
@export var hint_cps := 35.0

@onready var bubble: Control = $Bubble
@onready var pad: Control = $Bubble/Pad
@onready var content: Control = $Bubble/Pad/Content
@onready var speaker_label: Label = $Bubble/Pad/Content/SpeakerLabel
@onready var text_label: Label = $Bubble/Pad/Content/TextLabel
@onready var hint_label: Label = $Bubble/Pad/Content/HintLabel
@onready var type_sound: AudioStreamPlayer = $TypeSound

var done := false
var waiting_close := false
var skip_typing := false
var typing_sound_active := false


func _ready() -> void:
	visible = false

	anchor_left = 0.25
	anchor_right = 0.75
	anchor_top = 1.0
	anchor_bottom = 1.0

	offset_left = 0
	offset_right = 0
	offset_top = -370
	offset_bottom = -220

	bubble.set_anchors_preset(Control.PRESET_FULL_RECT)
	bubble.offset_left = 0
	bubble.offset_right = 0
	bubble.offset_top = 0
	bubble.offset_bottom = 0

	pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	pad.offset_left = 12
	pad.offset_right = -12
	pad.offset_top = 8
	pad.offset_bottom = -8

	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 0
	content.offset_right = 0
	content.offset_top = 0
	content.offset_bottom = 0

	speaker_label.anchor_left = 0.0
	speaker_label.anchor_right = 1.0
	speaker_label.anchor_top = 0.0
	speaker_label.anchor_bottom = 0.0
	speaker_label.offset_left = 0
	speaker_label.offset_right = 0
	speaker_label.offset_top = 0
	speaker_label.offset_bottom = 26

	text_label.anchor_left = 0.0
	text_label.anchor_right = 1.0
	text_label.anchor_top = 0.0
	text_label.anchor_bottom = 1.0
	text_label.offset_left = 0
	text_label.offset_right = 0
	text_label.offset_top = 34
	text_label.offset_bottom = -34

	hint_label.anchor_left = 0.0
	hint_label.anchor_right = 1.0
	hint_label.anchor_top = 1.0
	hint_label.anchor_bottom = 1.0
	hint_label.offset_left = 0
	hint_label.offset_right = 0
	hint_label.offset_top = -24
	hint_label.offset_bottom = 0

	mouse_filter = Control.MOUSE_FILTER_STOP

	if bubble != null:
		bubble.mouse_filter = Control.MOUSE_FILTER_STOP

	if pad != null:
		pad.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if content != null:
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if speaker_label != null:
		speaker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		speaker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	if text_label != null:
		text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	if hint_label != null:
		hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	if type_sound != null and not type_sound.finished.is_connected(_on_type_sound_finished):
		type_sound.finished.connect(_on_type_sound_finished)


func play_sequence(lines: Array) -> void:
	for line in lines:
		var speaker := str(line.get("speaker", ""))
		var text := str(line.get("text", ""))
		await play_line(speaker, text)


func play_line(speaker: String, text: String) -> void:
	visible = true

	done = false
	waiting_close = false
	skip_typing = false

	speaker_label.text = speaker
	text_label.text = ""
	hint_label.text = ""
	hint_label.visible = true

	_stop_typing_sound()
	_start_typing_sound()

	for i in text.length():
		if skip_typing:
			break

		text_label.text = text.substr(0, i + 1)
		await get_tree().create_timer(1.0 / cps).timeout

	_stop_typing_sound()

	if skip_typing:
		text_label.text = text

	var h := hint_text
	for i in h.length():
		if skip_typing:
			break

		hint_label.text = h.substr(0, i + 1)
		await get_tree().create_timer(1.0 / hint_cps).timeout

	if skip_typing:
		hint_label.text = hint_text

	done = true
	waiting_close = true

	while visible:
		await get_tree().process_frame


func _handle_continue_input() -> void:
	if not done:
		skip_typing = true
		_stop_typing_sound()
		return

	if waiting_close:
		_stop_typing_sound()
		visible = false


func _input(event: InputEvent) -> void:
	if not visible or not event.is_pressed():
		return

	if event is InputEventKey and event.echo:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return

		_handle_continue_input()
		get_viewport().set_input_as_handled()
		return

	_handle_continue_input()
	get_viewport().set_input_as_handled()


func _start_typing_sound() -> void:
	if type_sound == null:
		return

	typing_sound_active = true

	if not type_sound.playing:
		type_sound.play()


func _stop_typing_sound() -> void:
	typing_sound_active = false

	if type_sound != null:
		type_sound.stop()


func _on_type_sound_finished() -> void:
	if typing_sound_active and type_sound != null:
		type_sound.play()
