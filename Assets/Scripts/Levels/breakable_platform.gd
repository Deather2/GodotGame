extends StaticBody2D

@export var break_delay := 0.45
@export var respawn_time := 2.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var solid_collision: CollisionShape2D = $CollisionShape2D
@onready var trigger_area: Area2D = $TriggerArea
@onready var trigger_collision: CollisionShape2D = $TriggerArea/CollisionShape2D
@onready var respawn_timer: Timer = $RespawnTimer

var breaking := false
var broken := false


func _ready() -> void:
	sprite.play("idle")

	trigger_area.body_entered.connect(_on_trigger_body_entered)
	respawn_timer.timeout.connect(_on_respawn_timer_timeout)

	respawn_timer.one_shot = true


func _on_trigger_body_entered(body: Node) -> void:
	if breaking or broken:
		return

	if body.name != "Player":
		return

	_start_breaking()


func _start_breaking() -> void:
	breaking = true

	trigger_area.set_deferred("monitoring", false)

	sprite.play("break")

	await get_tree().create_timer(break_delay).timeout

	solid_collision.set_deferred("disabled", true)

	await sprite.animation_finished

	visible = false
	broken = true
	breaking = false

	respawn_timer.start(respawn_time)


func _on_respawn_timer_timeout() -> void:
	visible = true

	solid_collision.set_deferred("disabled", false)
	trigger_area.set_deferred("monitoring", true)

	broken = false
	breaking = false

	sprite.play("idle")
