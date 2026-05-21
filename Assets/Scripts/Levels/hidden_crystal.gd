extends Area2D

signal collected(crystal_id: int)

@export_range(0, 2) var crystal_id: int = 0
@export var crystal_frames: SpriteFrames
@export var light_color: Color = Color("#66FF88")

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var crystal_light: PointLight2D = $CrystalLight
@onready var interaction_hint: CanvasLayer = get_parent().get_node_or_null("InteractionHint")
@onready var destruction_sound: AudioStreamPlayer = $CrystalDesctructionSound
@onready var player: CharacterBody2D = get_parent().get_node_or_null("Player")
@onready var artifact_notification: CanvasLayer = get_parent().get_node_or_null("ArtifactNotification")

var player_in_range := false
var activated := false
var collected_now := false

func _ready() -> void:
	if GameState.is_hidden_crystal_collected(crystal_id):
		queue_free()
		return

	if crystal_frames != null:
		sprite.sprite_frames = crystal_frames

	crystal_light.color = light_color

	sprite.play("idle")

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	sprite.animation_finished.connect(_on_animation_finished)

	if interaction_hint != null:
		interaction_hint.visible = false


func _process(_delta: float) -> void:
	if activated:
		if interaction_hint != null and player_in_range:
			interaction_hint.visible = false
		return

	if player_in_range:
		_update_interaction_hint()

		if _can_interact() and Input.is_action_just_pressed("interact"):
			_activate_crystal()


func _can_interact() -> bool:
	if activated:
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

	collected_now = GameState.collect_hidden_crystal(crystal_id)

	if player != null:
		player.cutscene_lock = true
		player.velocity = Vector2.ZERO

	if interaction_hint != null:
		interaction_hint.visible = false

	if collision != null:
		collision.set_deferred("disabled", true)

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
	if sprite.animation != "destruction":
		return

	if player != null:
		player.cutscene_lock = false

	if collected_now and artifact_notification != null and artifact_notification.has_method("show_artifact_collected"):
		artifact_notification.show_artifact_collected()

	collected.emit(crystal_id)
	queue_free()
