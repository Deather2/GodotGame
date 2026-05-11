extends Node2D

@export var rotation_speed: float = 120.0

@export_enum("Clockwise", "Counter-clockwise") var rotation_direction: int = 0

@export var move_enabled: bool = false
@export var move_offset: Vector2 = Vector2.ZERO
@export var move_duration: float = 2.0
@export var smooth_movement: bool = true

@onready var pivot: Node2D = $Pivot

var start_position: Vector2
var target_position: Vector2
var move_time := 0.0
var moving_forward := true


func _ready() -> void:
	start_position = global_position
	target_position = start_position + move_offset

	_connect_spike($Pivot/SpikeUp)
	_connect_spike($Pivot/SpikeRight)
	_connect_spike($Pivot/SpikeDown)
	_connect_spike($Pivot/SpikeLeft)


func _physics_process(delta: float) -> void:
	_rotate_trap(delta)

	if move_enabled:
		_move_trap(delta)


func _rotate_trap(delta: float) -> void:
	var direction := 1.0

	if rotation_direction == 1:
		direction = -1.0

	pivot.rotation_degrees += absf(rotation_speed) * direction * delta


func _move_trap(delta: float) -> void:
	if move_duration <= 0.0:
		return

	move_time += delta

	var t := move_time / move_duration
	t = clampf(t, 0.0, 1.0)

	if smooth_movement:
		t = smoothstep(0.0, 1.0, t)

	if moving_forward:
		global_position = start_position.lerp(target_position, t)
	else:
		global_position = target_position.lerp(start_position, t)

	if move_time >= move_duration:
		move_time = 0.0
		moving_forward = !moving_forward


func _connect_spike(area: Area2D) -> void:
	if area.body_entered.is_connected(_on_spike_body_entered):
		return

	area.body_entered.connect(_on_spike_body_entered)


func _on_spike_body_entered(body: Node) -> void:
	if body.has_method("die"):
		body.die()
