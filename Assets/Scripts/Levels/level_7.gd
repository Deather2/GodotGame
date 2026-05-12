extends Node2D

const LEVEL_INDEX := 6

var finished := false

var level_time := 0.0
var timer_running := true

const LEVEL_MUSIC_GAP := 3.0
const LEVEL_MUSIC_FADE_OUT := 1.0

var music_cycle_active := true
var music_is_stopping := false
var level_music_base_volume := 1.0

var finish_transition := false
var death_count := 0

@onready var level_timer_ui = get_node_or_null("LevelTimer")
@onready var pause_menu: CanvasLayer = get_node_or_null("PauseMenu")
@onready var level_music: AudioStreamPlayer = get_node_or_null("LevelMusicPlayer")

@onready var world_dark: CanvasModulate = get_node_or_null("WorldDark")
@onready var parallax_dark: CanvasModulate = get_node_or_null("ParallaxBackground/ParallaxDark")
@onready var player: CharacterBody2D = get_node_or_null("Player")

@onready var kill_zone: Area2D = get_node_or_null("KillZone")
@onready var blink_off_sound: AudioStreamPlayer = get_node_or_null("BlinkOffSound")
@onready var light_on_sound: AudioStreamPlayer = get_node_or_null("LightOnSound")

@onready var spawn_point: Node2D = get_node_or_null("SpawnPoint")


func _ready() -> void:
	if GameState.preview_mode:
		_prepare_preview_mode()
		return

	GameState.hide_cursor()
	_setup_dark_level()

	if level_music != null:
		level_music_base_volume = level_music.volume_linear

	if SceneManager.is_transitioning():
		await SceneManager.transition_finished

	if level_music != null:
		await _wait_while_paused()
		_start_level_music_cycle()

	if kill_zone != null and not kill_zone.is_connected("body_entered", Callable(self, "_on_kill_zone_body_entered")):
		kill_zone.connect("body_entered", Callable(self, "_on_kill_zone_body_entered"))

	if player != null and not player.is_connected("died", Callable(self, "_on_player_died")):
		player.connect("died", Callable(self, "_on_player_died"))


func _setup_dark_level() -> void:
	if world_dark != null:
		world_dark.visible = true

	if parallax_dark != null:
		parallax_dark.visible = true

	var player_light := get_node_or_null("Player/PointLight2D") as PointLight2D
	if player_light != null:
		player_light.enabled = true
		player_light.texture_scale = 1.5


func _process(delta: float) -> void:
	if timer_running and not finished and level_timer_ui != null:
		level_time += delta
		level_timer_ui.set_time_text(get_level_time_text())


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel") or event.is_echo():
		return

	if pause_menu != null and pause_menu.is_open:
		return

	if finished or finish_transition:
		return

	if player != null and "is_dying" in player and player.is_dying:
		return

	if player != null and "cutscene_lock" in player and player.cutscene_lock:
		return

	if pause_menu != null:
		pause_menu.open_pause()
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	music_cycle_active = false

	if level_music != null:
		level_music.stop()
		level_music.volume_linear = level_music_base_volume


func _start_level_music_cycle() -> void:
	while music_cycle_active:
		await _wait_while_paused()

		if not music_cycle_active or level_music == null:
			return

		level_music.volume_linear = level_music_base_volume
		level_music.play()
		await level_music.finished

		if not music_cycle_active:
			return

		await get_tree().create_timer(LEVEL_MUSIC_GAP, false).timeout

		if not music_cycle_active:
			return


func stop_level_music() -> void:
	if level_music == null:
		return

	if music_is_stopping:
		return

	music_is_stopping = true
	music_cycle_active = false

	if not level_music.playing:
		level_music.volume_linear = level_music_base_volume
		music_is_stopping = false
		return

	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(level_music, "volume_linear", 0.001, LEVEL_MUSIC_FADE_OUT) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN)

	await tw.finished

	level_music.stop()
	level_music.volume_linear = level_music_base_volume
	music_is_stopping = false


func force_stop_level_music() -> void:
	music_cycle_active = false
	music_is_stopping = false

	if level_music != null:
		level_music.stop()
		level_music.volume_linear = level_music_base_volume


func _on_kill_zone_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("fall_death"):
		body.fall_death()


func get_level_time_text() -> String:
	var total_seconds := int(level_time)
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]


func _prepare_preview_mode() -> void:
	var pause := get_node_or_null("PauseMenu")
	if pause != null:
		pause.visible = false

	var win := get_node_or_null("WinUi")
	if win == null:
		win = get_node_or_null("WinUI")
	if win != null:
		win.visible = false

	var timer := get_node_or_null("LevelTimer")
	if timer != null:
		timer.visible = false

	var music := get_node_or_null("LevelMusicPlayer") as AudioStreamPlayer
	if music != null:
		music.stop()


func _wait_while_paused() -> void:
	while get_tree().paused:
		await get_tree().create_timer(0.05, true).timeout


func _on_player_died() -> void:
	death_count += 1
