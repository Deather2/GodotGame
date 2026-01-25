extends Button
class_name ShopCard

signal card_pressed(character_id: int)

@onready var preview: TextureRect = $BgPanel/VBox/Preview

@onready var price_ui: Control = $BgPanel/VBox/PriceUI
@onready var price_count: Label = $BgPanel/VBox/PriceUI/PriceCount
@onready var star_box: Control = $BgPanel/VBox/PriceUI/StarBox
@onready var star_icon: TextureRect = $BgPanel/VBox/PriceUI/StarBox/StarIcon

var character_id: int = 0
const FONT_SIZE_OWNED := 20
const FONT_SIZE_PRICE := 24

func setup(id: int, tex: Texture2D, text: String, star_tex: Texture2D) -> void:
	character_id = id
	preview.texture = tex
	star_icon.texture = star_tex

	if text == "Ir nopirkts":
		price_ui.visible = true
		price_count.text = text
		star_box.visible = false
		price_count.add_theme_font_size_override("font_size", FONT_SIZE_OWNED)
	else:
		price_ui.visible = true
		price_count.text = text
		star_box.visible = true
		price_count.add_theme_font_size_override("font_size", FONT_SIZE_PRICE)


func _pressed() -> void:
	emit_signal("card_pressed", character_id)
