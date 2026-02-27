extends CharacterBody2D

@export var db: CharacterDB

@onready var sprite_pivot: Node2D = $SpritePivot
@onready var sprite: AnimatedSprite2D = $SpritePivot/AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var cam: Camera2D = $Camera2D
@onready var stand_check: ShapeCast2D = $StandCheck

@onready var capsule: CapsuleShape2D = collision.shape as CapsuleShape2D

const SPEED := 300.0
const JUMP_VELOCITY := -400.0
const CROUCH_SPEED_MULT := 0.45

const SLOPE_TILT_MAX := deg_to_rad(21.0)
const SLOPE_TILT_DEAD := deg_to_rad(3.0)
const SLOPE_TILT_LERP := 0.15
const SLOPE_TILT_MULT := 1.15

@export var crouch_height := 20.0
@export var crouch_radius := 7.0

var gravity: float = float(ProjectSettings.get_setting("physics/2d/default_gravity"))
var face_dir: int = 1
var jump_anim_playing := false
var crouching := false
var _was_crouching := false

var stand_h: float
var stand_r: float
var stand_y: float

func _ready() -> void:
	_apply_selected()
	cam.make_current()

	if capsule != null:
		stand_h = capsule.height
		stand_r = capsule.radius
	stand_y = collision.position.y
	
	var sc_shape := stand_check.shape as CapsuleShape2D
	if sc_shape != null:
		sc_shape.height = stand_h
		sc_shape.radius = stand_r

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
		sprite.offset = db.sprite_offsets[i]
	else:
		sprite.offset = Vector2.ZERO

	var sc := 1.0
	if db.sprite_scales.size() > i and db.sprite_scales[i] > 0.0:
		sc = db.sprite_scales[i]
	sprite.scale = Vector2(sc, sc)

	sprite_pivot.rotation = 0.0

	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	var direction := Input.get_axis("move_left", "move_right")

	var want_crouch := Input.is_action_pressed("crouch")

	if not is_on_floor():
		crouching = false
	else:
		if want_crouch:
			crouching = true
		else:
			crouching = not _can_stand()

	var jump_pressed := Input.is_action_just_pressed("jump")
	var jump_requested := false

	if jump_pressed and is_on_floor():
		if crouching and not _can_stand():
			pass
		else:
			if crouching and _can_stand():
				crouching = false

			velocity.y = JUMP_VELOCITY
			jump_requested = true

	if crouching != _was_crouching:
		_apply_crouch_collision(crouching)
		_was_crouching = crouching

	var speed := SPEED
	if crouching:
		speed *= CROUCH_SPEED_MULT

	if direction != 0.0:
		velocity.x = direction * speed
		face_dir = int(sign(direction))
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)

	sprite.flip_h = face_dir < 0

	move_and_slide()

	if jump_requested and not is_on_floor():
		jump_anim_playing = true
		if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("jump"):
			sprite.play("jump")
	elif jump_requested and is_on_floor():
		jump_anim_playing = false

	_update_slope_tilt()
	_update_anim()

func _apply_crouch_collision(on: bool) -> void:
	if capsule == null:
		return

	var new_h := crouch_height if on else stand_h
	var new_r := crouch_radius if on else stand_r

	var dh := stand_h - new_h

	capsule.height = new_h
	capsule.radius = new_r

	
	collision.position.y = stand_y + dh * 0.5

func _update_slope_tilt() -> void:
	if is_on_floor():
		var a: float = get_floor_angle()
		var nx: float = get_floor_normal().x
		var sign_x: float = sign(nx)

		var target: float = a * -sign_x

		if absf(target) < SLOPE_TILT_DEAD:
			target = 0.0

		target *= SLOPE_TILT_MULT
		target = clampf(target, -SLOPE_TILT_MAX, SLOPE_TILT_MAX)

		sprite_pivot.rotation = lerp_angle(sprite_pivot.rotation, -target, SLOPE_TILT_LERP)
	else:
		sprite_pivot.rotation = lerp_angle(sprite_pivot.rotation, 0.0, SLOPE_TILT_LERP)

func _update_anim() -> void:
	if sprite.sprite_frames == null:
		return

	var on_floor := is_on_floor()
	var moving := absf(velocity.x) > 5.0

	if not on_floor:
		if jump_anim_playing and sprite.animation == "jump":
			if not sprite.is_playing():
				var last := sprite.sprite_frames.get_frame_count("jump") - 1
				if last >= 0:
					sprite.frame = last
		return

	jump_anim_playing = false

	if crouching:
		var target := "crouch_walk" if moving else "crouch"
		if not sprite.sprite_frames.has_animation(target):
			target = "crouch"

		if sprite.sprite_frames.has_animation(target) and sprite.animation != target:
			sprite.play(target)

		if target == "crouch" and not sprite.is_playing():
			var last2 := sprite.sprite_frames.get_frame_count("crouch") - 1
			if last2 >= 0:
				sprite.frame = last2
		return

	var target2 := "run" if moving else "idle"
	if sprite.sprite_frames.has_animation(target2) and sprite.animation != target2:
		sprite.play(target2)

func die() -> void:
	var sp := get_parent().get_node("SpawnPoint") as Node2D
	var feet := $Feet as Node2D
	global_position += sp.global_position - feet.global_position
	velocity = Vector2.ZERO

func _process(_delta: float) -> void:
	cam.global_position = cam.global_position.round()

func _can_stand() -> bool:
	stand_check.force_shapecast_update()
	return not stand_check.is_colliding()
