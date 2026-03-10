extends Control

@export var target_path: NodePath
@export var offset := Vector2(20, -170)

@export_multiline var full_text := "Ak, kas notika..? Kur palika visa gaisma? Velns... Man tas nepatīk. Tas noteikti nav nejauši. Man jāatrod, kas to izdarīja, un jāatgriež gaisma."
@export var cps := 20.0

@export var hint_text := "Nospied jebkuru pogu, lai turpinātu..."
@export var hint_cps := 20.0

@onready var target := get_node(target_path) as Node2D
@onready var text_label: Label = $Bubble/Pad/Text
@onready var hint_label: Label = $Bubble/Pad/Hint

var done := false
var waiting_close := false
var skip_typing := false

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

	var s := full_text
	for i in s.length():
		if skip_typing:
			break
		text_label.text = s.substr(0, i + 1)
		await get_tree().create_timer(1.0 / cps).timeout

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

func _unhandled_input(event: InputEvent) -> void:
	if !visible or !event.is_pressed():
		return

	if !done:
		skip_typing = true
		return

	if waiting_close:
		visible = false
