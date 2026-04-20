extends CanvasLayer

@onready var key_label: Label = $Panel/MarginContainer/HBoxContainer/KeyLabel

func _ready() -> void:
	visible = false
	_update_interact_key()

	if GameState.has_signal("controls_changed"):
		GameState.controls_changed.connect(_update_interact_key)

func _update_interact_key() -> void:
	var events := InputMap.action_get_events("interact")
	if events.is_empty():
		key_label.text = "?"
		return

	var event := events[0]

	if event is InputEventKey:
		key_label.text = event.as_text().replace(" (Physical)", "").replace(" (physical)", "")
	elif event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				key_label.text = "LMB"
			MOUSE_BUTTON_RIGHT:
				key_label.text = "RMB"
			MOUSE_BUTTON_MIDDLE:
				key_label.text = "MMB"
			_:
				key_label.text = "MB%s" % event.button_index
	else:
		key_label.text = event.as_text()
