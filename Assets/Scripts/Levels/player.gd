extends CharacterBody2D

signal died

@export var db: CharacterDB

@onready var sprite_pivot: Node2D = $SpritePivot
@onready var sprite: AnimatedSprite2D = $SpritePivot/AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var cam: Camera2D = $Camera2D
@onready var stand_check: ShapeCast2D = $StandCheck
@onready var feet: Node2D = $Feet

@onready var capsule: CapsuleShape2D = collision.shape as CapsuleShape2D
@onready var JumpSound: AudioStreamPlayer2D = $JumpSound

@onready var left_floor_ray: RayCast2D = $LeftFloorRay
@onready var right_floor_ray: RayCast2D = $RightFloorRay

@onready var HurtSound: AudioStreamPlayer = $HurtPlayer
@onready var DeathSound: AudioStreamPlayer = $DeathPlayer

@onready var super_jump_vfx: GPUParticles2D = $SuperJumpVFX

@onready var player_light: PointLight2D = $PointLight2D

var finish_auto_run := false
const FINISH_AUTO_RUN_SPEED := 220.0

const SPEED := 300.0

const BASE_JUMP_VELOCITY := -400.0
const SUPER_JUMP_VELOCITY := -520.0

var jump_velocity := BASE_JUMP_VELOCITY
var super_jump_active := false
var super_jump_request_id := 0

const CROUCH_SPEED_MULT := 0.45

const SLOPE_TILT_MAX := deg_to_rad(21.0)
const SLOPE_TILT_DEAD := deg_to_rad(3.0)
const SLOPE_TILT_LERP := 0.15
const SLOPE_TILT_MULT := 1.15

@export var crouch_height := 20.0
@export var crouch_radius := 7.0

const DEATH_JUMP_Y := -330.0
const DEATH_PUSH_X := 110.0
const DEATH_GRAVITY_MULT := 1.15
const DEATH_WINDUP_DELAY := 0.5
const DEATH_RESPAWN_DELAY := 1.6
const DEATH_BLINK_INTERVAL := 0.08

const FALL_CAMERA_TRAVEL_TIME := 0.35

var gravity: float = float(ProjectSettings.get_setting("physics/2d/default_gravity"))
var face_dir: int = 1
var jump_anim_playing := false
var crouching := false
var _was_crouching := false

var stand_h: float
var stand_r: float
var stand_y: float

var cutscene_lock := false
var is_dying := false
var death_windup_active := false
var _death_blink_accum := 0.0

var camera_respawn_travel := false
var cam_follow_offset := Vector2.ZERO

var fall_respawn_active := false
var death_respawn_active := false

const RESPAWN_GROUND_GAP := 2.0

var intro_drop_lock := false

func _ready() -> void:
	_apply_selected()

	var initial_cam_global := cam.global_position
	cam.top_level = true
	cam.global_position = initial_cam_global
	cam.make_current()
	cam_follow_offset = cam.global_position - global_position

	if capsule != null:
		stand_h = capsule.height
		stand_r = capsule.radius
	stand_y = collision.position.y

	_setup_floor_rays()

	var sc_shape := stand_check.shape as CapsuleShape2D
	if sc_shape != null:
		sc_shape.height = stand_h
		sc_shape.radius = stand_r

	if GameState.has_signal("selected_character_changed"):
		GameState.selected_character_changed.connect(func(_i): _apply_selected())

	_setup_super_jump_vfx()
	if super_jump_vfx != null:
		super_jump_vfx.emitting = false

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
	if fall_respawn_active:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if death_respawn_active:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if death_windup_active:
		velocity = Vector2.ZERO

		if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("idle"):
			if sprite.animation != "idle":
				sprite.play("idle")
			sprite.stop()
			sprite.frame = 0

		move_and_slide()
		return

	if is_dying:
		velocity.y += gravity * DEATH_GRAVITY_MULT * delta
		move_and_slide()
		_update_death_blink(delta)
		return

	if cutscene_lock:
		velocity = Vector2.ZERO
		if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	var direction := 0.0

	if finish_auto_run:
		direction = 1.0
	elif intro_drop_lock:
		direction = 0.0
	else:
		direction = Input.get_axis("move_left", "move_right")

	var want_crouch := false if (finish_auto_run or intro_drop_lock) else Input.is_action_pressed("crouch")

	if not is_on_floor():
		crouching = false
	else:
		if want_crouch:
			crouching = true
		else:
			crouching = not _can_stand()

	var jump_pressed := false if (finish_auto_run or intro_drop_lock) else Input.is_action_just_pressed("jump")
	var jump_requested := false

	if jump_pressed and is_on_floor():
		if crouching and not _can_stand():
			pass
		else:
			JumpSound.play()
			if crouching and _can_stand():
				crouching = false

			velocity.y = jump_velocity
			jump_requested = true

	if crouching != _was_crouching:
		_apply_crouch_collision(crouching)
		_was_crouching = crouching

	var speed := FINISH_AUTO_RUN_SPEED if finish_auto_run else SPEED
	if crouching:
		speed *= CROUCH_SPEED_MULT

	if direction != 0.0:
		velocity.x = direction * speed
		face_dir = int(sign(direction))
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)

	sprite.flip_h = face_dir < 0

	move_and_slide()

	if _check_spike_collision():
		return

	if jump_requested and not is_on_floor():
		jump_anim_playing = true
		if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("jump"):
			sprite.play("jump")
	elif jump_requested and is_on_floor():
		jump_anim_playing = false

	_update_slope_tilt()
	_update_anim()
	_update_camera_follow()


func _apply_crouch_collision(on: bool) -> void:
	if capsule == null:
		return

	var new_h := crouch_height if on else stand_h
	var new_r := crouch_radius if on else stand_r
	var dh := stand_h - new_h

	capsule.height = new_h
	capsule.radius = new_r
	collision.position.y = stand_y + dh * 0.5

	_setup_floor_rays()


func _update_slope_tilt() -> void:
	if is_dying or death_windup_active:
		sprite_pivot.rotation = lerp_angle(sprite_pivot.rotation, 0.0, SLOPE_TILT_LERP)
		return

	if not is_on_floor():
		sprite_pivot.rotation = lerp_angle(sprite_pivot.rotation, 0.0, SLOPE_TILT_LERP)
		return

	left_floor_ray.force_raycast_update()
	right_floor_ray.force_raycast_update()

	if not left_floor_ray.is_colliding() or not right_floor_ray.is_colliding():
		return

	var lp := left_floor_ray.get_collision_point()
	var rp := right_floor_ray.get_collision_point()

	var dx := rp.x - lp.x
	if absf(dx) < 0.001:
		sprite_pivot.rotation = lerp_angle(sprite_pivot.rotation, 0.0, SLOPE_TILT_LERP)
		return

	var dy := rp.y - lp.y
	if absf(dy) < 0.1:
		sprite_pivot.rotation = lerp_angle(sprite_pivot.rotation, 0.0, SLOPE_TILT_LERP)
		return

	var target := atan2(dy, dx)
	target *= SLOPE_TILT_MULT
	target = clampf(target, -SLOPE_TILT_MAX, SLOPE_TILT_MAX)

	sprite_pivot.rotation = lerp_angle(sprite_pivot.rotation, target, SLOPE_TILT_LERP)


func _update_anim() -> void:
	if sprite.sprite_frames == null:
		return

	var on_floor := is_on_floor()
	var moving := absf(velocity.x) > 5.0

	if not on_floor:
		if jump_anim_playing and sprite.sprite_frames.has_animation("jump"):
			if sprite.animation != "jump":
				sprite.play("jump")

			if not sprite.is_playing():
				var last := sprite.sprite_frames.get_frame_count("jump") - 1
				if last >= 0:
					sprite.frame = last
		else:
			var air_target := "run" if moving else "idle"
			if sprite.sprite_frames.has_animation(air_target) and sprite.animation != air_target:
				sprite.play(air_target)
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
	if is_dying or death_windup_active:
		return

	clear_super_jump()
	died.emit()

	death_windup_active = true
	cutscene_lock = false
	finish_auto_run = false
	crouching = false
	_was_crouching = false
	jump_anim_playing = false
	_death_blink_accum = 0.0

	velocity = Vector2.ZERO

	_apply_crouch_collision(false)
	sprite_pivot.rotation = 0.0

	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")
		sprite.stop()
		sprite.frame = 0

	sprite.visible = true

	HurtSound.play()
	_start_real_death()


func _start_real_death() -> void:
	await get_tree().create_timer(DEATH_WINDUP_DELAY).timeout

	if not death_windup_active or is_dying:
		return

	death_windup_active = false
	is_dying = true

	sprite.visible = true

	collision.set_deferred("disabled", true)
	stand_check.set_deferred("enabled", false)

	var push_dir := -face_dir
	if push_dir == 0:
		push_dir = -1

	velocity.x = DEATH_PUSH_X * push_dir
	velocity.y = DEATH_JUMP_Y

	DeathSound.play()
	_respawn_after_delay()


func _respawn_after_delay() -> void:
	await get_tree().create_timer(DEATH_RESPAWN_DELAY).timeout
	_die_respawn_with_camera_travel()


func fall_death() -> void:
	if is_dying or fall_respawn_active or death_windup_active:
		return

	clear_super_jump()
	died.emit()

	fall_respawn_active = true
	cutscene_lock = false
	finish_auto_run = false
	crouching = false
	_was_crouching = false
	jump_anim_playing = false
	velocity = Vector2.ZERO

	_apply_crouch_collision(false)
	sprite_pivot.rotation = 0.0
	sprite.visible = false

	collision.set_deferred("disabled", true)
	stand_check.set_deferred("enabled", false)

	_fall_respawn_with_camera_travel()


func _fall_respawn_with_camera_travel() -> void:
	var sp := _get_respawn_anchor()
	if sp == null:
		fall_respawn_active = false
		respawn()
		return

	var target_pos := _get_respawn_position(sp)
	var target_cam_pos := (target_pos + cam_follow_offset).round()

	camera_respawn_travel = true

	global_position = target_pos
	face_dir = 1
	sprite.flip_h = false
	velocity = Vector2.ZERO
	sprite_pivot.rotation = 0.0
	_set_player_visuals_visible(false)

	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")

	await get_tree().physics_frame

	collision.set_deferred("disabled", false)
	stand_check.set_deferred("enabled", true)

	await get_tree().physics_frame

	_apply_crouch_collision(false)

	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame

	_set_player_visuals_visible(true)
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")

	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(cam, "global_position", target_cam_pos, FALL_CAMERA_TRAVEL_TIME) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)

	await tw.finished

	fall_respawn_active = false
	camera_respawn_travel = false
	cam.global_position = target_cam_pos


func _get_respawn_position(sp: Node2D) -> Vector2:
	var bottom_offset := stand_y + stand_h * 0.5 + stand_r

	return Vector2(
		round(sp.global_position.x),
		round(sp.global_position.y - bottom_offset - RESPAWN_GROUND_GAP)
	)


func respawn() -> void:
	var sp := _get_respawn_anchor()
	if sp == null:
		return

	global_position = _get_respawn_position(sp)

	velocity = Vector2.ZERO
	face_dir = 1
	sprite.flip_h = false
	is_dying = false
	death_windup_active = false
	death_respawn_active = false
	crouching = false
	_was_crouching = false
	jump_anim_playing = false
	sprite.visible = true
	sprite_pivot.rotation = 0.0

	collision.set_deferred("disabled", false)
	stand_check.set_deferred("enabled", true)

	_apply_crouch_collision(false)

	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")

	camera_respawn_travel = false
	cam.global_position = (global_position + cam_follow_offset).round()


func _update_death_blink(delta: float) -> void:
	_death_blink_accum += delta
	var phase := int(_death_blink_accum / DEATH_BLINK_INTERVAL) % 2
	sprite.visible = (phase == 0)


func _process(_delta: float) -> void:
	pass

func _update_camera_follow() -> void:
	if not camera_respawn_travel:
		cam.global_position = (global_position + cam_follow_offset).round()

func _can_stand() -> bool:
	stand_check.force_shapecast_update()
	return not stand_check.is_colliding()


func start_finish_auto_run() -> void:
	if is_dying or death_windup_active:
		return
	finish_auto_run = true
	crouching = false


func stop_finish_auto_run() -> void:
	finish_auto_run = false


func _setup_floor_rays() -> void:
	if capsule == null:
		return

	var x_off := maxf(capsule.radius * 0.55, 4.0)
	var y_pos := feet.position.y - 10.0

	left_floor_ray.position = Vector2(-x_off, y_pos)
	right_floor_ray.position = Vector2(x_off, y_pos)

	left_floor_ray.target_position = Vector2(0, 34)
	right_floor_ray.target_position = Vector2(0, 34)

	left_floor_ray.exclude_parent = true
	right_floor_ray.exclude_parent = true

	left_floor_ray.hit_from_inside = true
	right_floor_ray.hit_from_inside = true

	left_floor_ray.collision_mask = stand_check.collision_mask
	right_floor_ray.collision_mask = stand_check.collision_mask

	left_floor_ray.enabled = true
	right_floor_ray.enabled = true


func _check_spike_collision() -> bool:
	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		var collider := col.get_collider()

		if collider is TileMap:
			var tilemap := collider as TileMap
			var hit_pos := col.get_position() - col.get_normal() * 2.0
			var local_pos := tilemap.to_local(hit_pos)
			var cell := tilemap.local_to_map(local_pos)
			var data := tilemap.get_cell_tile_data(0, cell)

			if data and data.get_custom_data("is_spike") == true:
				die()
				return true

	return false

func _die_respawn_with_camera_travel() -> void:
	var sp := _get_respawn_anchor()
	if sp == null:
		death_respawn_active = false
		respawn()
		return

	death_respawn_active = true
	camera_respawn_travel = true

	is_dying = false
	death_windup_active = false
	crouching = false
	_was_crouching = false
	jump_anim_playing = false

	_apply_crouch_collision(false)

	global_position = _get_respawn_position(sp)
	velocity = Vector2.ZERO
	face_dir = 1
	sprite.flip_h = false
	sprite_pivot.rotation = 0.0
	_set_player_visuals_visible(false)

	collision.disabled = false
	stand_check.enabled = true

	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")

	await get_tree().physics_frame

	var target_cam_pos := (global_position + cam_follow_offset).round()
	var need_cam_travel := cam.global_position.distance_to(target_cam_pos) > 1.0

	_set_player_visuals_visible(true)

	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")

	if need_cam_travel:
		var tw := create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(cam, "global_position", target_cam_pos, FALL_CAMERA_TRAVEL_TIME) \
			.set_trans(Tween.TRANS_SINE) \
			.set_ease(Tween.EASE_IN_OUT)

		await tw.finished
	else:
		cam.global_position = target_cam_pos

	death_respawn_active = false
	camera_respawn_travel = false
	cam.global_position = target_cam_pos

func _set_player_visuals_visible(on: bool) -> void:
	sprite.visible = on

	if player_light != null:
		player_light.visible = on

func apply_super_jump(duration: float = 5.0) -> void:
	super_jump_request_id += 1
	var request_id := super_jump_request_id

	super_jump_active = true
	jump_velocity = SUPER_JUMP_VELOCITY

	if super_jump_vfx != null:
		super_jump_vfx.emitting = true

	await get_tree().create_timer(duration).timeout

	if request_id != super_jump_request_id:
		return

	super_jump_active = false
	jump_velocity = BASE_JUMP_VELOCITY

	if super_jump_vfx != null:
		super_jump_vfx.emitting = false

func _setup_super_jump_vfx() -> void:
	if super_jump_vfx == null:
		return

	var img := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 1))

	var tex := ImageTexture.create_from_image(img)

	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(10.0, 18.0, 1.0)

	mat.direction = Vector3(0.0, -1.0, 0.0)
	mat.spread = 20.0

	mat.initial_velocity_min = 18.0
	mat.initial_velocity_max = 32.0

	mat.gravity = Vector3.ZERO

	mat.scale_min = 1.0
	mat.scale_max = 1.0

	mat.color = Color(0.2, 1.0, 0.2, 0.9)

	super_jump_vfx.texture = tex
	super_jump_vfx.process_material = mat
	super_jump_vfx.amount = 18
	super_jump_vfx.lifetime = 0.6
	super_jump_vfx.one_shot = false
	super_jump_vfx.explosiveness = 0.0
	super_jump_vfx.randomness = 0.7
	super_jump_vfx.local_coords = false
	super_jump_vfx.position = Vector2(0, 6)
	super_jump_vfx.emitting = false

func clear_super_jump() -> void:
	super_jump_request_id += 1
	super_jump_active = false
	jump_velocity = BASE_JUMP_VELOCITY

	if super_jump_vfx != null:
		super_jump_vfx.emitting = false

func _get_respawn_anchor() -> Node2D:
	var latest_checkpoint_point := _get_latest_active_checkpoint_respawn()
	if latest_checkpoint_point != null:
		return latest_checkpoint_point

	var parent_node := get_parent()

	if parent_node != null and parent_node.has_method("get_current_respawn_point"):
		var point = parent_node.get_current_respawn_point()
		if point != null:
			return point

	return parent_node.get_node_or_null("SpawnPoint") as Node2D

func _get_latest_active_checkpoint_respawn() -> Node2D:
	var parent_node := get_parent()
	if parent_node == null:
		return null

	var latest_point: Node2D = null
	var highest_index: int = -1

	for cp in get_tree().get_nodes_in_group("checkpoints"):
		if cp == null:
			continue

		if not parent_node.is_ancestor_of(cp):
			continue

		if cp.has_method("is_checkpoint_active") and cp.is_checkpoint_active():
			var idx: int = int(cp.get_checkpoint_index())
			if idx > highest_index:
				highest_index = idx
				latest_point = cp.get_respawn_point()

	return latest_point
