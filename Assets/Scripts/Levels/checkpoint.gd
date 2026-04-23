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

	if is_active:
		return

	if checkpoint_index <= _get_highest_active_checkpoint_index():
		return

	activate()
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

func is_checkpoint_active() -> bool:
	return is_active


func get_checkpoint_index() -> int:
	return checkpoint_index


func get_respawn_point() -> Node2D:
	return respawn_point


func _get_highest_active_checkpoint_index() -> int:
	var highest: int = -1

	for cp in get_tree().get_nodes_in_group("checkpoints"):
		if cp == self:
			continue

		if cp.has_method("is_checkpoint_active") and cp.is_checkpoint_active():
			var idx: int = int(cp.get_checkpoint_index())
			if idx > highest:
				highest = idx

	return highest
