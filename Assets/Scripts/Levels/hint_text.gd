extends Node2D

@export_multiline var template := "Lai pārvietotos pa labi, izmanto {move_right}. Lai pārvietotos pa kreisi, izmanto {move_left}."

@onready var label: Label = $Label

func _ready() -> void:
	_refresh()
	
	if not GameState.controls_changed.is_connected(_refresh):
		GameState.controls_changed.connect(_refresh)

func _refresh() -> void:
	label.text = _format_hint(template)

func _format_hint(t: String) -> String:
	var actions := [&"move_left", &"move_right", &"jump", &"crouch", &"ui_cancel"]

	for a in actions:
		t = t.replace("{%s}" % String(a), _action_hint_all(a))

	return t

func _action_hint(action_name: StringName) -> String:
	var events := InputMap.action_get_events(action_name)
	if events.is_empty():
		return "—"

	var e := events[0]

	if e is InputEventKey:
		var k := e as InputEventKey
		if k.physical_keycode != 0:
			return OS.get_keycode_string(k.physical_keycode)
		return OS.get_keycode_string(k.keycode)

	if e is InputEventMouseButton:
		var m := e as InputEventMouseButton
		match m.button_index:
			MOUSE_BUTTON_LEFT: return "LMB"
			MOUSE_BUTTON_RIGHT: return "RMB"
			MOUSE_BUTTON_MIDDLE: return "MMB"
			MOUSE_BUTTON_WHEEL_UP: return "WheelUp"
			MOUSE_BUTTON_WHEEL_DOWN: return "WheelDown"
			_: return "Mouse%d" % m.button_index

	if e is InputEventJoypadButton:
		var j := e as InputEventJoypadButton
		return "Btn%d" % j.button_index

	if e is InputEventJoypadMotion:
		var jm := e as InputEventJoypadMotion
		return "Axis%d" % jm.axis

	return e.as_text()

func _action_hint_all(action_name: StringName, sep := " vai ") -> String:
	var events := InputMap.action_get_events(action_name)
	if events.is_empty():
		return "—"

	var parts: Array[String] = []
	for e in events:
		var s := _event_to_short_text(e)
		if s != "" and not parts.has(s):
			parts.append(s)

	if parts.is_empty():
		return "—"
	return parts[0] if parts.size() == 1 else sep.join(parts)

func _event_to_short_text(e: InputEvent) -> String:
	if e is InputEventKey:
		var k := e as InputEventKey
		if k.physical_keycode != 0:
			return OS.get_keycode_string(k.physical_keycode)
		return OS.get_keycode_string(k.keycode)

	if e is InputEventMouseButton:
		var m := e as InputEventMouseButton
		match m.button_index:
			MOUSE_BUTTON_LEFT: return "LMB"
			MOUSE_BUTTON_RIGHT: return "RMB"
			MOUSE_BUTTON_MIDDLE: return "MMB"
			MOUSE_BUTTON_WHEEL_UP: return "WheelUp"
			MOUSE_BUTTON_WHEEL_DOWN: return "WheelDown"
			_: return "Mouse%d" % m.button_index

	if e is InputEventJoypadButton:
		var j := e as InputEventJoypadButton
		return "Btn%d" % j.button_index

	if e is InputEventJoypadMotion:
		var jm := e as InputEventJoypadMotion
		return "Axis%d" % jm.axis

	return ""
