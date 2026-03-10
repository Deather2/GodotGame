extends Button
class_name ShopCard

signal card_pressed(character_id: int)

@onready var preview_center: Control = $BgPanel/VBox/PreviewCenter
@onready var preview_sprite: Sprite2D = $BgPanel/VBox/PreviewCenter/PreviewSprite

@onready var price_ui: Control = $BgPanel/VBox/PriceUI
@onready var price_count: Label = $BgPanel/VBox/PriceUI/PriceCount
@onready var star_box: Control = $BgPanel/VBox/PriceUI/StarBox
@onready var star_icon: TextureRect = $BgPanel/VBox/PriceUI/StarBox/StarIcon

var character_id: int = 0
const FONT_SIZE_OWNED := 20
const FONT_SIZE_PRICE := 24

const PREVIEW_TARGET_H := 180.0

const PREVIEW_Y_BIAS := -35.0

func setup(id: int, tex: Texture2D, text: String, star_tex: Texture2D) -> void:
	character_id = id
	preview_sprite.texture = tex
	star_icon.texture = star_tex

	price_ui.visible = true
	if text == "Ir nopirkts":
		price_count.text = text
		star_box.visible = false
		price_count.add_theme_font_size_override("font_size", FONT_SIZE_OWNED)
	else:
		price_count.text = text
		star_box.visible = true
		price_count.add_theme_font_size_override("font_size", FONT_SIZE_PRICE)

	_apply_preview()

func _apply_preview() -> void:
	call_deferred("_apply_preview_deferred")

func _apply_preview_deferred() -> void:
	if preview_center.size == Vector2.ZERO:
		call_deferred("_apply_preview_deferred")
		return

	preview_sprite.centered = true
	preview_sprite.position = preview_center.size * 0.5 + Vector2(0.0, PREVIEW_Y_BIAS)

	var tex := preview_sprite.texture
	if tex != null:
		var s := PREVIEW_TARGET_H / float(tex.get_height())
		preview_sprite.scale = Vector2(s, s)
	else:
		preview_sprite.scale = Vector2.ONE

func _pressed() -> void:
	emit_signal("card_pressed", character_id)

func _on_button_mouse_entered() -> void:
	Cursor.set_hover()

func _on_button_mouse_exited() -> void:
	Cursor.set_normal()
