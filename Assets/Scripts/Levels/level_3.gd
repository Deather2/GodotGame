extends Node2D

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
var crystal_collected := false

var current_respawn_point: Node2D

@onready var level_timer_ui = get_node_or_null("LevelTimer")
@onready var pause_menu: CanvasLayer = get_node_or_null("PauseMenu")
@onready var level_music: AudioStreamPlayer = get_node_or_null("LevelMusicPlayer")

@onready var world_dark: CanvasModulate = get_node_or_null("WorldDark")
@onready var parallax_dark: CanvasModulate = get_node_or_null("ParallaxBackground/ParallaxDark")
@onready var player: CharacterBody2D = get_node_or_null("Player")

@onready var kill_zone: Area2D = get_node_or_null("KillZone")
@onready var crystal = get_node_or_null("Crystal")

@onready var blink_off_sound: AudioStreamPlayer = get_node_or_null("BlinkOffSound")
@onready var light_on_sound: AudioStreamPlayer = get_node_or_null("LightOnSound")

@onready var super_jump_pickup = get_node_or_null("SuperJumpPickup")

@onready var spawn_point: Node2D = $SpawnPoint

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

	if crystal != null and crystal.has_signal("collected") and not crystal.is_connected("collected", Callable(self, "_on_crystal_collected")):
		crystal.connect("collected", Callable(self, "_on_crystal_collected"))

	if player != null and not player.is_connected("died", Callable(self, "_on_player_died")):
		player.connect("died", Callable(self, "_on_player_died"))

	if super_jump_pickup != null:
		if not super_jump_pickup.picked_up.is_connected(_on_super_jump_picked_up):
			super_jump_pickup.picked_up.connect(_on_super_jump_picked_up)


func _setup_dark_level() -> void:
	if world_dark != null:
		world_dark.visible = true

	if parallax_dark != null:
		parallax_dark.visible = true

	var player_light := get_node_or_null("Player/PointLight2D") as PointLight2D
	if player_light != null:
		player_light.enabled = true
		player_light.texture_scale = 1.1


func _process(delta: float) -> void:
	if timer_running and !finished and level_timer_ui != null:
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


func _on_crystal_collected() -> void:
	if crystal_collected or finished or finish_transition:
		return

	crystal_collected = true
	finish_transition = true
	finished = true

	if player != null:
		player.cutscene_lock = true
		player.velocity = Vector2.ZERO

	timer_running = false
	if level_timer_ui != null:
		level_timer_ui.visible = false

	await stop_level_music()
	await _play_crystal_light_gain_fx()

	if player != null:
		player.velocity = Vector2.ZERO

	await get_tree().create_timer(1.0).timeout

	save_win_result()
	show_win_ui()


func _play_crystal_light_gain_fx() -> void:
	var light := get_node_or_null("Player/PointLight2D") as PointLight2D
	if light == null:
		return

	light.texture_scale = 1.1

	await get_tree().create_timer(0.1).timeout

	if blink_off_sound != null:
		blink_off_sound.play()
	light.texture_scale = 1.2
	await get_tree().create_timer(0.28).timeout

	if blink_off_sound != null:
		blink_off_sound.play()
	light.texture_scale = 1.1
	await get_tree().create_timer(0.28).timeout

	if blink_off_sound != null:
		blink_off_sound.play()
	light.texture_scale = 1.2
	await get_tree().create_timer(0.28).timeout

	if blink_off_sound != null:
		blink_off_sound.play()
	light.texture_scale = 1.1
	await get_tree().create_timer(0.35).timeout

	if light_on_sound != null:
		light_on_sound.play()
	light.texture_scale = 1.2


func get_level_time_text() -> String:
	var total_seconds := int(level_time)
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]


func get_earned_stars() -> int:
	var max_by_deaths := 3

	if death_count == 1:
		max_by_deaths = 2
	elif death_count >= 2:
		max_by_deaths = 1

	var stars_by_time := 1
	if level_time <= 40.0:
		stars_by_time = 3
	elif level_time <= 60.0:
		stars_by_time = 2

	return min(max_by_deaths, stars_by_time)


func save_win_result() -> void:
	GameState.save_level_result(2, get_earned_stars(), level_time)


func show_win_ui() -> void:
	var win_ui := get_node_or_null("WinUi")
	if win_ui == null:
		return

	GameState.show_cursor()
	win_ui.setup_result(get_earned_stars(), get_level_time_text(), 2)

	var death_label := win_ui.get_node_or_null("Panel/VBox/DeathLabel") as Label
	if death_label != null:
		death_label.text = "Nāves: %d" % death_count

	win_ui.show_with_anim()


func _prepare_preview_mode() -> void:
	var pause := get_node_or_null("PauseMenu")
	if pause != null:
		pause.visible = false

	var win := get_node_or_null("WinUi")
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

	if player != null and player.has_method("clear_super_jump"):
		player.clear_super_jump()

	if super_jump_pickup != null and super_jump_pickup.has_method("force_reset"):
		super_jump_pickup.force_reset()

func _on_super_jump_picked_up() -> void:
	if player != null and player.has_method("apply_super_jump"):
		player.apply_super_jump(5.0)
