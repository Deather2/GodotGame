extends Node2D

@onready var layer1: ParallaxLayer = $World/BG/Layer1
@onready var layer2: ParallaxLayer = $World/BG/Layer2
@onready var layer3: ParallaxLayer = $World/BG/Layer3

@onready var bg1: Sprite2D = $World/BG/Layer1/Sprite2D
@onready var bg2: Sprite2D = $World/BG/Layer2/Sprite2D
@onready var bg3: Sprite2D = $World/BG/Layer3/Sprite2D

func _ready() -> void:
	_apply_bg_scale()
	get_viewport().size_changed.connect(_apply_bg_scale)

func _apply_bg_scale() -> void:
	var vp: Vector2 = get_viewport_rect().size
	_scale_one(bg1, layer1, vp)
	_scale_one(bg2, layer2, vp)
	_scale_one(bg3, layer3, vp)

func _scale_one(s: Sprite2D, layer: ParallaxLayer, vp: Vector2) -> void:
	var tex: Texture2D = s.texture
	if tex == null:
		return

	var ts: Vector2i = tex.get_size()
	if ts.x <= 0 or ts.y <= 0:
		return

	var k: float = max(vp.x / float(ts.x), vp.y / float(ts.y))
	s.scale = Vector2(k, k)

	var mirror_x: int = int(round(float(ts.x) * k))
	layer.motion_mirroring = Vector2(mirror_x, 0)
