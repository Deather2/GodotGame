extends CharacterBody2D

@export var speed: float = 40.0
@export var direction: int = -1
@export var turn_cooldown: float = 0.12

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var wall_check: RayCast2D = $WallCheck
@onready var hurt_box: Area2D = $HurtBox
@onready var player: Node = get_parent().get_node_or_null("Player")

var gravity: float = float(ProjectSettings.get_setting("physics/2d/default_gravity"))
var turn_cooldown_left: float = 0.0

@export var hurt_box_offset_x: float = 2.0

var hurt_box_base_pos: Vector2

func _ready() -> void:
	hurt_box.body_entered.connect(_on_hurt_box_body_entered)

	if player != null:
		wall_check.add_exception(player)

	hurt_box_base_pos = hurt_box.position

	_apply_direction_setup()
	_play_default_anim()


func _physics_process(delta: float) -> void:
	if turn_cooldown_left > 0.0:
		turn_cooldown_left -= delta

	if not is_on_floor():
		velocity.y += gravity * delta

	wall_check.force_raycast_update()

	if turn_cooldown_left <= 0.0 and wall_check.is_colliding():
		var collider := wall_check.get_collider()

		if collider != null and collider.is_in_group("enemies"):
			_reverse_direction()

			if collider.has_method("turn_from_enemy_contact"):
				collider.turn_from_enemy_contact()

			velocity.x = direction * speed
			move_and_slide()
			return

		else:
			_reverse_direction()

	velocity.x = direction * speed
	move_and_slide()


func turn_from_enemy_contact() -> void:
	if turn_cooldown_left > 0.0:
		return

	_reverse_direction()


func _reverse_direction() -> void:
	direction *= -1
	turn_cooldown_left = turn_cooldown
	_apply_direction_setup()


func _apply_direction_setup() -> void:
	var px := absf(wall_check.position.x)
	var tx := absf(wall_check.target_position.x)

	wall_check.position.x = px * direction
	wall_check.target_position.x = tx * direction

	hurt_box.position.x = hurt_box_base_pos.x + hurt_box_offset_x * direction

	sprite.flip_h = direction > 0


func _play_default_anim() -> void:
	if sprite.sprite_frames == null:
		return

	if sprite.sprite_frames.has_animation("walk"):
		sprite.play("walk")
	elif sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")


func _on_hurt_box_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	if body.has_method("die"):
		body.die()
