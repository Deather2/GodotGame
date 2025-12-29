extends Button
class_name LevelButton

@export var star_empty: Texture2D
@export var star_full: Texture2D

@onready var label: Label = $Label
@onready var lock_tex: TextureRect = $Lock
@onready var star_nodes: Array[TextureRect] = [
	$Stars/Star1,
	$Stars/Star2,
	$Stars/Star3
]
@onready var preview: TextureRect = $Preview


var level_index: int = 0

func setup(i: int) -> void:
	level_index = i
	label.text = "Level %d" % (i + 1)
	_refresh()

func _refresh() -> void:
	var unlocked := GameState.is_level_unlocked(level_index)
	disabled = not unlocked
	lock_tex.visible = not unlocked

	var got := GameState.stars_per_level[level_index]
	for s in range(3):
		star_nodes[s].texture = star_full if s < got else star_empty

func set_preview(tex: Texture2D) -> void:
	preview.texture = tex
