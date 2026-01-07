extends CharacterBody2D

@export var character_db: CharacterDB

@onready var sprite: AnimatedSprite2D = $StandPoint/MenuCharacter
@onready var col: CollisionShape2D = $CollisionShape2D

var gravity: float = 2000.0
var _last_index: int = -1

func _ready() -> void:
	# чтобы не ловить двойные коннекты
	if not GameState.selected_character_changed.is_connected(_on_selected_changed):
		GameState.selected_character_changed.connect(_on_selected_changed)

	_refresh(true)

func _exit_tree() -> void:
	if GameState.selected_character_changed.is_connected(_on_selected_changed):
		GameState.selected_character_changed.disconnect(_on_selected_changed)

func _process(_delta: float) -> void:
	# железный fallback: если сигнал не дошёл из-за оверлея/паузы — всё равно обновим
	if GameState.selected_character_index != _last_index:
		_refresh(false)

func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta
	move_and_slide()

func _on_selected_changed(_idx: int) -> void:
	_refresh(false)

func _refresh(force: bool) -> void:
	if not force and GameState.selected_character_index == _last_index:
		return
	_last_index = GameState.selected_character_index

	_setup_character()
	# ВАЖНО: не двигаем sprite.position по размеру текстуры,
	# иначе разные персонажи будут "стоять" на разной высоте.
	#sprite.position = Vector2.ZERO

	# Коллизию в меню лучше оставить фиксированной (как ты настроил руками).
	# Если хочешь авто — вернём потом, но правильно (через отдельные offsets в DB).
	# _setup_collider_from_texture()

func _setup_character() -> void:
	if character_db == null:
		return
	if character_db.idle_frames.is_empty():
		return

	var idx: int = clamp(GameState.selected_character_index, 0, character_db.idle_frames.size() - 1)
	var frames: SpriteFrames = character_db.idle_frames[idx] as SpriteFrames
	if frames == null:
		return

	sprite.sprite_frames = frames
	sprite.play(&"idle")
	
	_align_to_standpoint()


func _setup_collider_from_texture() -> void:
	if sprite.sprite_frames == null:
		return
	if not sprite.sprite_frames.has_animation(&"idle"):
		return

	var tex: Texture2D = sprite.sprite_frames.get_frame_texture(&"idle", 0)
	if tex == null:
		return

	var size_px: Vector2 = tex.get_size()
	var s: Vector2 = size_px * sprite.scale

	var capsule: CapsuleShape2D = CapsuleShape2D.new()
	capsule.radius = max(4.0, s.x * 0.35)
	capsule.height = max(8.0, s.y * 0.75)
	col.shape = capsule

func _align_to_standpoint() -> void:
	if sprite.sprite_frames == null:
		return
	if not sprite.sprite_frames.has_animation(&"idle"):
		return

	var tex: Texture2D = sprite.sprite_frames.get_frame_texture(&"idle", 0)
	if tex == null:
		return

	var h: float = tex.get_size().y * sprite.scale.y

	# если Centered включён — низ = y + h/2
	# если Centered выключен — низ = y + h
	if sprite.centered:
		sprite.position.y = -h * 0.5
	else:
		sprite.position.y = -h
