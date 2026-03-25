extends Control

@export var target_path: NodePath
@export var offset := Vector2(20, -170)

@export_multiline var full_text := "Ak, kas notika..? Kur palika visa gaisma? Velns... Man tas nepatīk. Tas noteikti nav nejauši. Man jāatrod, kas to izdarīja, un jāatgriež gaisma."
@export var cps := 20.0

@export var hint_text := "Nospied jebkuru pogu, lai turpinātu..."
@export var hint_cps := 20.0

@onready var target := get_node(target_path) as Node2D
@onready var bubble: Control = $Bubble
@onready var pad: Control = $Bubble/Pad
@onready var text_label: Label = $Bubble/Pad/Text
@onready var hint_label: Label = $Bubble/Pad/Hint
@onready var type_sound: AudioStreamPlayer = $TypeSound

var done := false
var waiting_close := false
var skip_typing := false
var typing_sound_active := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if not type_sound.finished.is_connected(_on_type_sound_finished):
		type_sound.finished.connect(_on_type_sound_finished)


func _process(_delta: float) -> void:
	if !visible:
		return
	_update_follow_pos()


func _update_follow_pos() -> void:
	if target == null:
		return

	var screen_pos := (get_viewport().get_canvas_transform() * target.global_position) + offset
	var vp := get_viewport_rect().size

	var p := screen_pos
	p.x = clamp(p.x, 8.0, vp.x - size.x - 8.0)
	p.y = clamp(p.y, 8.0, vp.y - size.y - 8.0)

	global_position = p


func start() -> void:
	visible = false
	await get_tree().process_frame
	_update_follow_pos()
	visible = true

	done = false
	waiting_close = false
	skip_typing = false

	text_label.text = ""
	hint_label.text = ""
	hint_label.visible = true

	_stop_typing_sound()

	var s := full_text
	_start_typing_sound()

	for i in s.length():
		if skip_typing:
			break

		text_label.text = s.substr(0, i + 1)
		await get_tree().create_timer(1.0 / cps).timeout

	_stop_typing_sound()

	if skip_typing:
		text_label.text = full_text
		hint_label.text = hint_text
		done = true
		waiting_close = true
		return

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


func _handle_continue_input() -> void:
	if !done:
		skip_typing = true
		_stop_typing_sound()
		return

	if waiting_close:
		_stop_typing_sound()
		visible = false


func _gui_input(event: InputEvent) -> void:
	if !visible or !event.is_pressed():
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return

		_handle_continue_input()
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if !visible or !event.is_pressed():
		return

	if event is InputEventMouseButton:
		return

	if event is InputEventKey and event.echo:
		return

	_handle_continue_input()
	get_viewport().set_input_as_handled()


func _start_typing_sound() -> void:
	typing_sound_active = true
	if not type_sound.playing:
		type_sound.play()


func _stop_typing_sound() -> void:
	typing_sound_active = false
	type_sound.stop()


func _on_type_sound_finished() -> void:
	if typing_sound_active:
		type_sound.play()
