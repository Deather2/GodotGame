extends Area2D

signal picked_up

@onready var icon: Sprite2D = $Icon
@onready var respawn_timer: Timer = $RespawnTimer
@onready var interaction_hint: CanvasLayer = get_parent().get_node_or_null("InteractionHint")
@onready var player: CharacterBody2D = get_parent().get_node_or_null("Player")
@onready var pickup_sound: AudioStreamPlayer = $PickUpSound

var player_in_range := false
var activated := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	respawn_timer.timeout.connect(_on_respawn_timer_timeout)

	if interaction_hint != null:
		interaction_hint.visible = false


func _process(_delta: float) -> void:
	if activated:
		return

	if player_in_range and Input.is_action_just_pressed("interact"):
		activated = true

		if player != null:
			player.velocity = Vector2.ZERO

		if interaction_hint != null:
			interaction_hint.visible = false

		if pickup_sound != null:
			pickup_sound.play()

		icon.visible = false
		monitoring = false
		picked_up.emit()
		respawn_timer.start()


func _on_body_entered(body: Node) -> void:
	if not monitoring:
		return

	if body.name == "Player":
		player_in_range = true
		if interaction_hint != null:
			interaction_hint.visible = true


func _on_body_exited(body: Node) -> void:
	if body.name == "Player":
		player_in_range = false
		if interaction_hint != null:
			interaction_hint.visible = false


func _on_respawn_timer_timeout() -> void:
	activated = false
	player_in_range = false
	icon.visible = true
	monitoring = true

func force_reset() -> void:
	activated = false
	player_in_range = false

	if respawn_timer != null:
		respawn_timer.stop()

	icon.visible = true
	monitoring = true

	if interaction_hint != null:
		interaction_hint.visible = false
