extends Area2D

signal collected

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_hint: CanvasLayer = get_parent().get_node_or_null("InteractionHint")
@onready var destruction_sound: AudioStreamPlayer = $CrystalDesctructionSound
@onready var player: CharacterBody2D = get_parent().get_node_or_null("Player")

var player_in_range := false
var activated := false
@export var locked := false


func _ready() -> void:
	sprite.play("idle")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	sprite.animation_finished.connect(_on_animation_finished)

	if interaction_hint != null:
		interaction_hint.visible = false


func _process(_delta: float) -> void:
	if locked:
		if interaction_hint != null:
			interaction_hint.visible = false
		return

	if activated:
		if interaction_hint != null and player_in_range:
			interaction_hint.visible = false
		return

	if player_in_range:
		_update_interaction_hint()

		if _can_interact() and Input.is_action_just_pressed("interact"):
			_activate_crystal()


func _can_interact() -> bool:
	if locked:
		return false

	if not player_in_range:
		return false

	if player == null:
		return false

	if not player.is_on_floor():
		return false

	return true


func _update_interaction_hint() -> void:
	if interaction_hint == null:
		return

	interaction_hint.visible = _can_interact()


func _activate_crystal() -> void:
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

		if player == null:
			player = body as CharacterBody2D

		_update_interaction_hint()


func _on_body_exited(body: Node) -> void:
	if body.name == "Player":
		player_in_range = false

		if interaction_hint != null:
			interaction_hint.visible = false


func _on_animation_finished() -> void:
	if sprite.animation == "destruction":
		collected.emit()
		hide()

func set_locked(value: bool) -> void:
	locked = value

	if locked and interaction_hint != null:
		interaction_hint.visible = false
