extends CanvasLayer

@onready var time_label: Label = $MarginContainer/Label

func set_time_text(value: String) -> void:
	time_label.text = value
