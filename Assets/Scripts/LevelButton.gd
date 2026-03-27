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
@onready var preview: TextureRect = $PreviewHolder/Preview
@onready var preview_shade: Panel = $PreviewHolder/PreviewShade

var level_index: int = 0

const PREVIEW_RADIUS := 14.0
const PREVIEW_SHADER := preload("res://Assets/Shaders/rounded_preview.gdshader")

func _ready() -> void:
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

	preview.visible = false
	preview_shade.visible = false

	_setup_preview_material()

	if not resized.is_connected(_update_preview_material):
		resized.connect(_update_preview_material)

	call_deferred("_update_preview_material")

func _setup_preview_material() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = PREVIEW_SHADER
	preview.material = mat

func _update_preview_material() -> void:
	var mat := preview.material as ShaderMaterial
	if mat == null:
		return

	mat.set_shader_parameter("rect_size", preview.size)
	mat.set_shader_parameter("radius_px", PREVIEW_RADIUS)
	mat.set_shader_parameter("edge_softness", 1.0)

func setup(i: int) -> void:
	level_index = i
	label.text = "Level %d" % (i + 1)
	_refresh()

func _refresh() -> void:
	var unlocked := GameState.is_level_unlocked(level_index)

	disabled = not unlocked
	lock_tex.visible = not unlocked
	$Stars.visible = unlocked

	if not unlocked:
		return

	var got := GameState.stars_per_level[level_index]
	for s in range(3):
		star_nodes[s].texture = star_full if s < got else star_empty

func set_preview(tex: Texture2D) -> void:
	preview.texture = tex
	preview.visible = tex != null
	preview_shade.visible = tex != null
	call_deferred("_update_preview_material")
