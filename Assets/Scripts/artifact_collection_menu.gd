extends Control

@onready var back_button: Button = $MainPanel/BackButton
@onready var count_label: Label = $MainPanel/CountLabel

@onready var image0: TextureRect = $MainPanel/Pad/RootBox/ArtifactsRow/ArtifactSlot0/SlotBox/CrystalImage
@onready var image1: TextureRect = $MainPanel/Pad/RootBox/ArtifactsRow/ArtifactSlot1/SlotBox/CrystalImage
@onready var image2: TextureRect = $MainPanel/Pad/RootBox/ArtifactsRow/ArtifactSlot2/SlotBox/CrystalImage

@onready var status0: Label = $MainPanel/Pad/RootBox/ArtifactsRow/ArtifactSlot0/SlotBox/StatusLabel
@onready var status1: Label = $MainPanel/Pad/RootBox/ArtifactsRow/ArtifactSlot1/SlotBox/StatusLabel
@onready var status2: Label = $MainPanel/Pad/RootBox/ArtifactsRow/ArtifactSlot2/SlotBox/StatusLabel

var crystal_ids := [0, 1, 2]


func _ready() -> void:
	GameState.show_cursor()

	if not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)

	_update_artifacts()


func _update_artifacts() -> void:
	var images := [image0, image1, image2]
	var statuses := [status0, status1, status2]

	var collected_count := GameState.get_collected_hidden_crystals_count()
	var total_count := GameState.get_hidden_crystals_count()

	count_label.text = "Savākti: %d / %d" % [collected_count, total_count]

	for i in range(3):
		var crystal_id: int = crystal_ids[i]
		var found := GameState.is_hidden_crystal_collected(crystal_id)

		_set_slot_state(images[i], statuses[i], found)


func _set_slot_state(image: TextureRect, status: Label, found: bool) -> void:
	if found:
		image.modulate = Color(1, 1, 1, 1)
		status.text = "Atrasts"
	else:
		image.modulate = Color(0.04, 0.035, 0.035, 0.9)
		status.text = "Nav atrasts"


func _on_back_pressed() -> void:
	SceneManager.goto_main_menu(SceneManager.Transition.DROP_UP)
