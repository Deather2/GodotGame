extends CharacterBody2D

@export var db: CharacterDB

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void:
	_apply_selected()
	$Camera2D.make_current()
	
	if GameState.has_signal("selected_character_changed"):
		GameState.selected_character_changed.connect(func(_i): _apply_selected())

func _apply_selected() -> void:
	if db == null:
		return

	var max_i := db.idle_frames.size() - 1
	if max_i < 0:
		return

	var i := clampi(GameState.selected_character_index, 0, max_i)

	sprite.sprite_frames = db.idle_frames[i]

	if db.sprite_offsets.size() > i:
		sprite.position = db.sprite_offsets[i]
	else:
		sprite.position = Vector2.ZERO

	if db.hitbox_offsets.size() > i:
		collision.position = db.hitbox_offsets[i]
	else:
		collision.position = Vector2.ZERO

	var shape := collision.shape as CapsuleShape2D
	if shape != null:
		if db.hitbox_radii.size() > i and db.hitbox_radii[i] > 0.0:
			shape.radius = db.hitbox_radii[i]

		if db.hitbox_heights.size() > i and db.hitbox_heights[i] > 0.0:
			shape.height = db.hitbox_heights[i]

	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
		
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	move_and_slide()

func die() -> void:
	global_position = get_parent().get_node("SpawnPoint").global_position
	velocity = Vector2.ZERO
