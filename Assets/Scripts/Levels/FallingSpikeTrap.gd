extends Node2D

@export var fall_distance: float = 144.0
@export var fall_speed: float = 700.0
@export var return_speed: float = 180.0

@export var wait_before_fall: float = 1.0
@export var wait_before_return: float = 0.5

@export var use_local_direction: bool = true

@onready var trap_body: Node2D = $TrapBody

var start_pos: Vector2
var end_pos: Vector2
var state := "waiting_fall"
var wait_timer := 0.0


func _ready() -> void:
	start_pos = trap_body.position

	var direction := Vector2.DOWN
	if use_local_direction:
		direction = Vector2.DOWN.rotated(rotation)

	end_pos = start_pos + direction * fall_distance

	_connect_spike($TrapBody/SpikeLeft)
	_connect_spike($TrapBody/SpikeRight)

	wait_timer = wait_before_fall


func _physics_process(delta: float) -> void:
	match state:
		"waiting_fall":
			_process_waiting_fall(delta)

		"falling":
			_process_falling(delta)

		"waiting_return":
			_process_waiting_return(delta)

		"returning":
			_process_returning(delta)


func _process_waiting_fall(delta: float) -> void:
	wait_timer -= delta

	if wait_timer <= 0.0:
		state = "falling"


func _process_falling(delta: float) -> void:
	trap_body.position = trap_body.position.move_toward(end_pos, fall_speed * delta)

	if trap_body.position.distance_to(end_pos) <= 0.1:
		trap_body.position = end_pos
		wait_timer = wait_before_return
		state = "waiting_return"


func _process_waiting_return(delta: float) -> void:
	wait_timer -= delta

	if wait_timer <= 0.0:
		state = "returning"


func _process_returning(delta: float) -> void:
	trap_body.position = trap_body.position.move_toward(start_pos, return_speed * delta)

	if trap_body.position.distance_to(start_pos) <= 0.1:
		trap_body.position = start_pos
		wait_timer = wait_before_fall
		state = "waiting_fall"


func _connect_spike(area: Area2D) -> void:
	if area.body_entered.is_connected(_on_spike_body_entered):
		return

	area.body_entered.connect(_on_spike_body_entered)


func _on_spike_body_entered(body: Node) -> void:
	if body.has_method("die"):
		body.die()
