extends CharacterBody2D

@export var character_db: CharacterDB

@onready var sprite: AnimatedSprite2D = $StandPoint/MenuCharacter
@onready var col: CollisionShape2D = $CollisionShape2D

var gravity: float = 2000.0

func _ready() -> void:
	_setup_character()
	_setup_collider_from_texture()

func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta
	move_and_slide()

func _setup_character() -> void:
	if character_db == null or character_db.idle_frames.is_empty():
		return

	var idx: int = clamp(GameState.selected_character_index, 0, character_db.idle_frames.size() - 1)
	var frames: SpriteFrames = character_db.idle_frames[idx] as SpriteFrames
	if frames == null:
		return

	sprite.sprite_frames = frames
	sprite.stop()
	sprite.animation = &"idle"
	sprite.frame = 0
	sprite.play()

func _setup_collider_from_texture() -> void:
	if sprite.sprite_frames == null:
		return

	if not sprite.sprite_frames.has_animation(&"idle"):
		return

	var tex: Texture2D = sprite.sprite_frames.get_frame_texture(&"idle", 0)
	if tex == null:
		return

	var size_px: Vector2 = Vector2(tex.get_size())
	var s: Vector2 = size_px * sprite.scale

	var capsule: CapsuleShape2D = CapsuleShape2D.new()
	capsule.radius = max(4.0, s.x * 0.35)
	capsule.height = max(8.0, s.y * 0.75)
	col.shape = capsule

	var foot_offset: float = sprite.scale.y
	sprite.position = Vector2(0.0, -s.y * 0.5 + foot_offset)
