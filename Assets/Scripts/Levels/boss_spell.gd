extends Area2D

@export var damage_start_frame: int = 8
@export var damage_end_frame: int = 11

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var SpellImpactSound: AudioStreamPlayer2D = $SpellImpactSound

var damage_active := false


func _ready() -> void:
	add_to_group("boss_spell")
	monitoring = false

	if collision != null:
		collision.disabled = true

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	if not sprite.frame_changed.is_connected(_on_frame_changed):
		sprite.frame_changed.connect(_on_frame_changed)

	if not sprite.animation_finished.is_connected(_on_animation_finished):
		sprite.animation_finished.connect(_on_animation_finished)

	sprite.play("spell")
	_play_impact_sound_later()


func _on_frame_changed() -> void:
	var current_frame := sprite.frame + 1

	var should_damage := current_frame >= damage_start_frame and current_frame <= damage_end_frame

	if should_damage and not damage_active:
		_set_damage_active(true)
		_damage_overlapping_bodies()
	elif not should_damage and damage_active:
		_set_damage_active(false)


func _set_damage_active(active: bool) -> void:
	damage_active = active
	monitoring = active

	if collision != null:
		collision.disabled = not active


func _damage_overlapping_bodies() -> void:
	for body in get_overlapping_bodies():
		if body.has_method("die"):
			body.die()


func _on_body_entered(body: Node) -> void:
	if not damage_active:
		return

	if body.has_method("die"):
		body.die()


func _on_animation_finished() -> void:
	queue_free()

func _play_impact_sound_later() -> void:
	await get_tree().create_timer(0.4, false).timeout

	if SpellImpactSound != null:
		SpellImpactSound.play()
