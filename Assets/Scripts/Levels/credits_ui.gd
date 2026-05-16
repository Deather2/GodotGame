extends CanvasLayer

@export var credits_scroll_time := 20.0
@export var thanks_move_time := 2.0
@export var thanks_hold_time := 1.2
@export var side_margin := 64.0
@export var start_bottom_offset := 60.0
@export var end_top_offset := 60.0

@onready var root: Control = $Root
@onready var black_bg: ColorRect = $Root/BlackBg
@onready var credits_text: Label = $Root/CreditsText
@onready var thanks_label: Label = $Root/ThanksLabel

@export var bg_scroll_speed := 10.0

func _ready() -> void:
	visible = false

	if root != null:
		root.set_anchors_preset(Control.PRESET_FULL_RECT)
		root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if black_bg != null:
		black_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		black_bg.color = Color.BLACK
		black_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if credits_text != null:
		credits_text.visible = false
		credits_text.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if thanks_label != null:
		thanks_label.visible = false
		thanks_label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_black_bg() -> void:
	visible = true

	if black_bg != null:
		black_bg.visible = true

	if credits_text != null:
		credits_text.visible = false

	if thanks_label != null:
		thanks_label.visible = false


func play_credits() -> void:
	visible = true
	_set_bg_scroll_offset(0.0)

	if black_bg != null:
		black_bg.visible = true

	await get_tree().process_frame

	var bg_tw := create_tween()
	bg_tw.tween_method(
		_set_bg_scroll_offset,
		0.0,
		bg_scroll_speed * (credits_scroll_time + thanks_move_time + thanks_hold_time),
		credits_scroll_time + thanks_move_time + thanks_hold_time
	).set_trans(Tween.TRANS_LINEAR)

	var vp := get_viewport().get_visible_rect().size

	if credits_text != null:
		credits_text.visible = true
		credits_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		credits_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		credits_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		var text_width := vp.x - side_margin * 2.0
		var text_height := credits_text.get_combined_minimum_size().y

		credits_text.size = Vector2(text_width, text_height)
		credits_text.position = Vector2(side_margin, vp.y + start_bottom_offset)

		var target_y := -text_height - end_top_offset

		var tw := create_tween()
		tw.tween_property(credits_text, "position:y", target_y, credits_scroll_time) \
			.set_trans(Tween.TRANS_LINEAR) \
			.set_ease(Tween.EASE_IN_OUT)

		await tw.finished
		credits_text.visible = false

	if thanks_label != null:
		thanks_label.visible = true
		thanks_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		thanks_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		var thanks_height := maxf(thanks_label.get_combined_minimum_size().y, 80.0)

		thanks_label.size = Vector2(vp.x, thanks_height)
		thanks_label.position = Vector2(0, vp.y + 40.0)

		var center_y := vp.y * 0.5 - thanks_height * 0.5

		var tw2 := create_tween()
		tw2.tween_property(thanks_label, "position:y", center_y, thanks_move_time) \
			.set_trans(Tween.TRANS_SINE) \
			.set_ease(Tween.EASE_OUT)

		await tw2.finished
		await get_tree().create_timer(thanks_hold_time, false).timeout

func _set_bg_scroll_offset(value: float) -> void:
	if black_bg == null:
		return

	var mat := black_bg.material as ShaderMaterial
	if mat == null:
		return

	mat.set_shader_parameter("scroll_offset", value)
