extends Button
class_name ShopCard

signal card_pressed(character_id: int)

@onready var preview: TextureRect = $Preview
@onready var price_label: Label = $PriceLabel

var character_id: int = 0

func setup(id: int, tex: Texture2D, text: String) -> void:
	character_id = id
	preview.texture = tex
	price_label.text = text

func _pressed() -> void:
	emit_signal("card_pressed", character_id)
