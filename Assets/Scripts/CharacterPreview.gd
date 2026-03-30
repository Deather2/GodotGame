extends Control
class_name CharacterPreview

@export var db: CharacterDB
@export var character_id: int = 0
@export var animation_name: StringName = &"idle"
@export var frame_index: int = 0
@export var target_height: float = 90.0
@export var baseline_y: float = 110.0

@onready var preview_sprite: Sprite2D = $PreviewSprite


func _ready() -> void:
	call_deferred("_update_preview")


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_update_preview()


func set_character(id: int) -> void:
	character_id = id
	_update_preview()


func refresh() -> void:
	_update_preview()


func _update_preview() -> void:
	if size == Vector2.ZERO:
		return

	var tex := _get_preview_texture()
	if tex == null:
		preview_sprite.texture = null
		return

	preview_sprite.texture = tex
	preview_sprite.centered = false

	var visible_rect := _get_visible_rect(tex)
	if visible_rect.size.x <= 0.0 or visible_rect.size.y <= 0.0:
		visible_rect = Rect2(Vector2.ZERO, tex.get_size())

	var scale_value: float = target_height / maxf(visible_rect.size.y, 1.0)
	preview_sprite.scale = Vector2.ONE * scale_value

	var visible_center_x := visible_rect.position.x + visible_rect.size.x * 0.5
	var visible_bottom_y := visible_rect.position.y + visible_rect.size.y

	preview_sprite.position = Vector2(
		size.x * 0.5 - visible_center_x * scale_value,
		baseline_y - visible_bottom_y * scale_value
	)


func _get_preview_texture() -> Texture2D:
	if db == null:
		return null

	if character_id < 0 or character_id >= db.idle_frames.size():
		return null

	var frames := db.idle_frames[character_id]
	if frames == null:
		return null

	var anim := animation_name
	if not frames.has_animation(anim):
		anim = &"idle"

	if not frames.has_animation(anim):
		return null

	var count := frames.get_frame_count(anim)
	if count <= 0:
		return null

	var idx := clampi(frame_index, 0, count - 1)
	return frames.get_frame_texture(anim, idx)


func _get_visible_rect(tex: Texture2D) -> Rect2:
	var img := tex.get_image()
	if img == null:
		return Rect2(Vector2.ZERO, tex.get_size())

	var w := img.get_width()
	var h := img.get_height()

	var min_x := w
	var min_y := h
	var max_x := -1
	var max_y := -1

	for y in range(h):
		for x in range(w):
			if img.get_pixel(x, y).a > 0.01:
				if x < min_x:
					min_x = x
				if y < min_y:
					min_y = y
				if x > max_x:
					max_x = x
				if y > max_y:
					max_y = y

	if max_x == -1 or max_y == -1:
		return Rect2(Vector2.ZERO, tex.get_size())

	return Rect2(
		Vector2(min_x, min_y),
		Vector2(max_x - min_x + 1, max_y - min_y + 1)
	)
