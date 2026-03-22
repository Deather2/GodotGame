extends Node

@onready var cursor_normal: Texture2D = preload("res://Assets/Cursors/cursor_main.png")
@onready var cursor_hover:  Texture2D = preload("res://Assets/Cursors/cursor_hover.png")

var hotspot := Vector2(8, 4) 

func _ready() -> void:
	set_normal()  

func set_hover() -> void:
	Input.set_custom_mouse_cursor(cursor_hover, Input.CURSOR_ARROW, hotspot)

func set_normal() -> void:
	Input.set_custom_mouse_cursor(cursor_normal, Input.CURSOR_ARROW, hotspot)
