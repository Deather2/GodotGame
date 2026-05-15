extends CanvasLayer

@onready var hp_red: ColorRect = $Root/CenterContainer/VBoxContainer/HpBarBack/HpRed
@onready var hp_white: ColorRect = $Root/CenterContainer/VBoxContainer/HpBarBack/HpWhite

var max_width := 314.0


func _ready() -> void:
	visible = false

	if hp_red != null:
		max_width = hp_red.size.x


func setup(max_hp: int, current_hp: int) -> void:
	visible = true
	update_hp(max_hp, current_hp)


func update_hp(max_hp: int, current_hp: int) -> void:
	if hp_red == null:
		return

	if max_hp <= 0:
		hp_red.size.x = 0
		return

	var percent := clampf(float(current_hp) / float(max_hp), 0.0, 1.0)
	hp_red.size.x = max_width * percent


func hide_ui() -> void:
	visible = false
