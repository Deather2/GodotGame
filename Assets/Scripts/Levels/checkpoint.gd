extends Area2D

signal reached(checkpoint)

@export var checkpoint_index: int = 0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var respawn_point: Node2D = $RespawnPoint
@onready var checkpointSound: AudioStreamPlayer = $CheckpointSound

var is_active := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_set_inactive_visual()


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	reached.emit(self)


func activate() -> void:
	if is_active:
		return

	is_active = true

	checkpointSound.play()

	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")


func deactivate() -> void:
	is_active = false
	_set_inactive_visual()


func _set_inactive_visual() -> void:
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("idle"):
		sprite.stop()
		sprite.animation = "idle"
		sprite.frame = 0
