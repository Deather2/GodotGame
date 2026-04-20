extends Area2D

signal collected

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_hint: CanvasLayer = get_parent().get_node_or_null("InteractionHint")
@onready var destruction_sound: AudioStreamPlayer = $CrystalDesctructionSound
@onready var player: CharacterBody2D = get_parent().get_node_or_null("Player")

var player_in_range := false
var activated := false

func _ready() -> void:
	sprite.play("idle")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	sprite.animation_finished.connect(_on_animation_finished)

	if interaction_hint != null:
		interaction_hint.visible = false

func _process(_delta: float) -> void:
	if activated:
		return

	if player_in_range and Input.is_action_just_pressed("interact"):
		activated = true

		if player != null:
			player.cutscene_lock = true
			player.velocity = Vector2.ZERO

		if interaction_hint != null:
			interaction_hint.visible = false

		if destruction_sound != null:
			destruction_sound.play()

		sprite.play("destruction")

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		player_in_range = true
		if interaction_hint != null:
			interaction_hint.visible = true

func _on_body_exited(body: Node) -> void:
	if body.name == "Player":
		player_in_range = false
		if interaction_hint != null:
			interaction_hint.visible = false

func _on_animation_finished() -> void:
	if sprite.animation == "destruction":
		collected.emit()
		hide()
