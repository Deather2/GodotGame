extends AnimatableBody2D

@export var move_offset: Vector2 = Vector2(160, 0)
@export var speed: float = 120.0

var start_position: Vector2
var end_position: Vector2
var real_position: Vector2
var going_forward := true


func _ready() -> void:
	sync_to_physics = true

	start_position = position.round()
	end_position = (start_position + move_offset).round()

	real_position = start_position
	position = start_position


func _physics_process(delta: float) -> void:
	var target := end_position if going_forward else start_position

	real_position = real_position.move_toward(target, speed * delta)
	position = real_position.round()

	if real_position.is_equal_approx(target):
		real_position = target
		position = target
		going_forward = !going_forward
