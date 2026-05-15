extends CharacterBody2D

signal defeated
signal hp_changed(max_hp: int, current_hp: int)

enum State {
	IDLE,
	WALK,
	MELEE_ATTACK,
	CAST_ATTACK,
	HURT,
	DEAD
}

var waiting_for_death_cutscene := false
@export var fight_active := false

@export var max_hp: int = 10
@export var move_speed: float = 65.0

@export var melee_range: float = 55.0
@export var melee_vertical_tolerance: float = 40.0
@export var cast_range: float = 210.0
@export var stop_distance: float = 42.0

@export var melee_cooldown: float = 1.2
@export var cast_cooldown: float = 2.5
@export var hurt_invulnerable_time: float = 0.35

@export var melee_damage_delay: float = 0.45
@export var melee_damage_time: float = 0.18

@export var boss_spell_scene: PackedScene
@export var spell_spawn_delay: float = 0.55
@export var spell_spawn_global_y: float = 0.0

@onready var sprite_pivot: Node2D = $SpritePivot
@onready var sprite: AnimatedSprite2D = $SpritePivot/AnimatedSprite2D
@onready var melee_hit_box: Area2D = $MeleeHitBox
@onready var melee_hit_shape: CollisionShape2D = $MeleeHitBox/CollisionShape2D
@onready var hurt_box: Area2D = $HurtBox

var gravity: float = float(ProjectSettings.get_setting("physics/2d/default_gravity"))

var hp: int
var state: State = State.IDLE
var player: CharacterBody2D

var face_dir: int = -1
var melee_timer := 0.0
var cast_timer := 0.0
var invulnerable := false

var action_id := 0
var melee_hit_shape_start_pos := Vector2.ZERO
var start_global_position := Vector2.ZERO


func _ready() -> void:
	hp = max_hp
	start_global_position = global_position
	add_to_group("boss")

	player = get_tree().get_first_node_in_group("player") as CharacterBody2D

	melee_hit_shape_start_pos = melee_hit_shape.position
	melee_hit_box.monitoring = false

	if not melee_hit_box.is_connected("body_entered", Callable(self, "_on_melee_hit_box_body_entered")):
		melee_hit_box.connect("body_entered", Callable(self, "_on_melee_hit_box_body_entered"))

	_set_face_dir(-1)
	_play_anim("idle")


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	if not fight_active:
		velocity.x = 0.0

		if not is_on_floor():
			velocity.y += gravity * delta

		_play_anim("idle")
		move_and_slide()
		return

	if waiting_for_death_cutscene:
		velocity.x = 0.0

		if not is_on_floor():
			velocity.y += gravity * delta

		move_and_slide()
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	melee_timer = maxf(melee_timer - delta, 0.0)
	cast_timer = maxf(cast_timer - delta, 0.0)

	if state == State.MELEE_ATTACK or state == State.CAST_ATTACK or state == State.HURT:
		velocity.x = 0.0
		move_and_slide()
		return

	if player == null:
		_idle()
		move_and_slide()
		return

	var dx := player.global_position.x - global_position.x
	var distance := absf(dx)
	var vertical_distance := absf(player.global_position.y - global_position.y)

	if dx < 0.0:
		_set_face_dir(-1)
	elif dx > 0.0:
		_set_face_dir(1)

	if distance <= melee_range and vertical_distance <= melee_vertical_tolerance and melee_timer <= 0.0:
		_start_melee_attack()
	elif distance >= cast_range and cast_timer <= 0.0:
		_start_cast_attack()
	elif distance > stop_distance:
		_walk_towards_player(dx)
	else:
		_idle()

	move_and_slide()


func _idle() -> void:
	velocity.x = 0.0
	state = State.IDLE
	_play_anim("idle")


func _walk_towards_player(dx: float) -> void:
	state = State.WALK
	velocity.x = sign(dx) * move_speed
	_play_anim("walk")


func _start_melee_attack() -> void:
	state = State.MELEE_ATTACK
	action_id += 1
	var current_action := action_id

	melee_timer = melee_cooldown
	velocity.x = 0.0
	melee_hit_box.monitoring = false

	_play_anim("attack")

	await get_tree().create_timer(melee_damage_delay, false).timeout

	if current_action != action_id or state != State.MELEE_ATTACK:
		return

	melee_hit_box.monitoring = true

	await get_tree().physics_frame

	if current_action != action_id or state != State.MELEE_ATTACK:
		return

	_damage_overlapping_melee_bodies()

	await get_tree().create_timer(melee_damage_time, false).timeout

	melee_hit_box.monitoring = false

	if current_action != action_id or state != State.MELEE_ATTACK:
		return

	await sprite.animation_finished

	if current_action != action_id or state != State.MELEE_ATTACK:
		return

	state = State.IDLE
	_play_anim("idle")


func _start_cast_attack() -> void:
	state = State.CAST_ATTACK
	action_id += 1
	var current_action := action_id

	cast_timer = cast_cooldown
	velocity.x = 0.0
	melee_hit_box.monitoring = false

	_play_anim("cast")

	await get_tree().create_timer(spell_spawn_delay, false).timeout

	if current_action != action_id or state != State.CAST_ATTACK:
		return

	_spawn_spell_over_player()

	await sprite.animation_finished

	if current_action != action_id or state != State.CAST_ATTACK:
		return

	state = State.IDLE
	_play_anim("idle")


func take_damage(amount: int = 1) -> void:
	if state == State.DEAD:
		return

	if waiting_for_death_cutscene:
		return

	if invulnerable:
		return

	hp -= amount
	hp = max(hp, 0)
	hp_changed.emit(max_hp, hp)

	if hp <= 0:
		_start_final_hurt()
	else:
		_start_hurt()

func _start_final_hurt() -> void:
	state = State.HURT
	action_id += 1

	waiting_for_death_cutscene = true
	invulnerable = true
	melee_hit_box.monitoring = false
	velocity.x = 0.0

	_play_anim("hurt")

	await sprite.animation_finished

	if state != State.HURT:
		return

	state = State.IDLE
	_play_anim("idle")

	defeated.emit()

func _start_hurt() -> void:
	state = State.HURT
	action_id += 1

	invulnerable = true
	melee_hit_box.monitoring = false
	velocity.x = 0.0

	_play_anim("hurt")

	_end_invulnerability_later()

	await sprite.animation_finished

	if state != State.HURT:
		return

	state = State.IDLE
	_play_anim("idle")


func _end_invulnerability_later() -> void:
	await get_tree().create_timer(hurt_invulnerable_time, false).timeout
	invulnerable = false


func _die() -> void:
	state = State.DEAD
	action_id += 1

	waiting_for_death_cutscene = false
	melee_hit_box.monitoring = false
	velocity = Vector2.ZERO

	_play_anim("death")

	await sprite.animation_finished

	visible = false

func play_death() -> void:
	if state == State.DEAD:
		return

	await _die()

func _set_face_dir(dir: int) -> void:
	face_dir = dir

	if face_dir == -1:
		sprite_pivot.scale.x = 1.0
	else:
		sprite_pivot.scale.x = -1.0

	melee_hit_shape.position.x = absf(melee_hit_shape_start_pos.x) * face_dir
	melee_hit_shape.position.y = melee_hit_shape_start_pos.y


func _play_anim(anim_name: String) -> void:
	if sprite.sprite_frames == null:
		return

	if not sprite.sprite_frames.has_animation(anim_name):
		return

	if sprite.animation != anim_name:
		sprite.play(anim_name)


func _on_melee_hit_box_body_entered(body: Node) -> void:
	if state != State.MELEE_ATTACK:
		return

	if not melee_hit_box.monitoring:
		return

	if body.has_method("die"):
		body.die()

func _damage_overlapping_melee_bodies() -> void:
	for body in melee_hit_box.get_overlapping_bodies():
		if body.has_method("die"):
			body.die()

func _spawn_spell_over_player() -> void:
	if boss_spell_scene == null:
		return

	if player == null:
		return

	var spell := boss_spell_scene.instantiate()
	get_parent().add_child(spell)

	spell.global_position = Vector2(
		player.global_position.x,
		spell_spawn_global_y
	)

func start_fight() -> void:
	fight_active = true

func stop_fight() -> void:
	fight_active = false
	action_id += 1

	state = State.IDLE
	waiting_for_death_cutscene = false
	invulnerable = false
	melee_timer = 0.0
	cast_timer = 0.0
	velocity = Vector2.ZERO

	if melee_hit_box != null:
		melee_hit_box.set_deferred("monitoring", false)

	_play_anim("idle")


func reset_fight() -> void:
	action_id += 1

	hp = max_hp
	hp_changed.emit(max_hp, hp)
	state = State.IDLE
	fight_active = false
	waiting_for_death_cutscene = false
	invulnerable = false
	melee_timer = 0.0
	cast_timer = 0.0
	velocity = Vector2.ZERO
	visible = true

	global_position = start_global_position

	if melee_hit_box != null:
		melee_hit_box.set_deferred("monitoring", false)

	_set_face_dir(-1)
	_play_anim("idle")

func get_max_hp() -> int:
	return max_hp


func get_hp() -> int:
	return hp
