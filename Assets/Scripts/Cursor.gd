extends Control

@onready var cursor_normal: Texture2D = preload("res://Assets/Cursors/cursor_main.png")
@onready var cursor_hover: Texture2D  = preload("res://Assets/Cursors/cursor_hover.png")

var hotspot := Vector2(0,0) 

func _ready() -> void:
	Input.set_custom_mouse_cursor(cursor_normal, Input.CURSOR_ARROW, hotspot)


func _on_mouse_entered() -> void:
	Input.set_custom_mouse_cursor(cursor_hover, Input.CURSOR_ARROW, hotspot)


func _on_mouse_exited() -> void:
	Input.set_custom_mouse_cursor(cursor_normal, Input.CURSOR_ARROW, hotspot)
