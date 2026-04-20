extends Node2D

var finished := false
var pending_finish := false

var level_time := 0.0
var timer_running := true

const LEVEL_MUSIC_GAP := 3.0
const LEVEL_MUSIC_FADE_OUT := 1.0

var music_cycle_active := true
var music_is_stopping := false
var level_music_base_volume := 1.0

var finish_transition := false

@onready var level_timer_ui = get_node_or_null("LevelTimer")
@onready var pause_menu: CanvasLayer = get_node_or_null("PauseMenu")
@onready var level_music: AudioStreamPlayer = get_node_or_null("LevelMusicPlayer")

@onready var world_dark: CanvasModulate = get_node_or_null("WorldDark")
@onready var parallax_dark: CanvasModulate = get_node_or_null("ParallaxBackground/ParallaxDark")
@onready var player: CharacterBody2D = get_node_or_null("Player")

@onready var crystal = get_node_or_null("Crystal")
@onready var crystal_intro_trigger: Area2D = get_node_or_null("CrystalIntroTrigger")

@onready var monologue_intro: Control = get_node_or_null("Cutscene/UI/MonologueIntro") as Control
@onready var monologue_outro: Control = get_node_or_null("Cutscene/UI/MonologueOutro") as Control

@onready var blink_on_sound: AudioStreamPlayer = get_node_or_null("Cutscene/BlinkOnSound")
@onready var blink_off_sound: AudioStreamPlayer = get_node_or_null("Cutscene/BlinkOffSound")
@onready var light_on_sound: AudioStreamPlayer = get_node_or_null("Cutscene/LightOnSound")

var intro_cutscene_played := false
var outro_cutscene_played := false
var crystal_collected := false

var death_count := 0

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

	if crystal != null and not crystal.collected.is_connected(_on_crystal_collected):
		crystal.collected.connect(_on_crystal_collected)

	if crystal_intro_trigger != null and not crystal_intro_trigger.body_entered.is_connected(_on_crystal_intro_trigger_body_entered):
		crystal_intro_trigger.body_entered.connect(_on_crystal_intro_trigger_body_entered)


func _setup_dark_level() -> void:
	if world_dark != null:
		world_dark.visible = true

	if parallax_dark != null:
		parallax_dark.visible = true

	var player_light := get_node_or_null("Player/PointLight2D") as PointLight2D
	if player_light != null:
		player_light.enabled = true


func _physics_process(_delta: float) -> void:
	if finished or !pending_finish or finish_transition:
		return

	if player != null and player.is_on_floor():
		await _begin_finish_cutscene()


func _process(delta: float) -> void:
	if timer_running and !finished and level_timer_ui != null:
		level_time += delta
		level_timer_ui.set_time_text(get_level_time_text())


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel") or event.is_echo():
		return

	if pause_menu != null and pause_menu.is_open:
		return

	if finished or pending_finish or finish_transition:
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


func _on_finish_area_body_entered(body: Node2D) -> void:
	if finished or finish_transition:
		return
	if !body.is_in_group("player"):
		return

	if body is CharacterBody2D and !(body as CharacterBody2D).is_on_floor():
		pending_finish = true
		return

	await _begin_finish_cutscene()


func _begin_finish_cutscene() -> void:
	if finish_transition or finished:
		return

	finish_transition = true
	pending_finish = false

	if player != null and player.has_method("start_finish_auto_run"):
		player.start_finish_auto_run()

	await stop_level_music()

	if player != null and player.has_method("stop_finish_auto_run"):
		player.stop_finish_auto_run()

	finished = true
	timer_running = false

	if level_timer_ui != null:
		level_timer_ui.visible = false

	var cutscene := get_node_or_null("Cutscene")
	if cutscene != null and cutscene.has_method("play_end_cutscene"):
		cutscene.play_end_cutscene()
	else:
		show_win_ui()


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
	if level_time <= 32.0:
		stars_by_time = 3
	elif level_time <= 50.0:
		stars_by_time = 2

	return min(max_by_deaths, stars_by_time)


func save_win_result() -> void:
	GameState.save_level_result(1, get_earned_stars(), level_time)


func show_win_ui() -> void:
	var win_ui := get_node_or_null("WinUi")
	if win_ui == null:
		return

	GameState.show_cursor()
	win_ui.setup_result(get_earned_stars(), get_level_time_text(), 1)
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


func _on_crystal_intro_trigger_body_entered(body: Node) -> void:
	if body != player:
		return
	if intro_cutscene_played:
		return
	if crystal_collected:
		return

	intro_cutscene_played = true

	if crystal_intro_trigger != null:
		crystal_intro_trigger.set_deferred("monitoring", false)

	if player != null:
		player.intro_drop_lock = true

	await _force_player_drop_for_intro()
	await _play_intro_cutscene_before_crystal()


func _play_intro_cutscene_before_crystal() -> void:
	if player == null or monologue_intro == null:
		return

	player.cutscene_lock = true
	player.velocity = Vector2.ZERO

	await _play_monologue(monologue_intro)

	player.velocity = Vector2.ZERO
	await _wait_release_after_monologue()

	player.intro_drop_lock = false
	player.cutscene_lock = false


func _on_crystal_collected() -> void:
	if crystal_collected:
		return

	crystal_collected = true
	finish_transition = true
	finished = true

	if crystal_intro_trigger != null:
		crystal_intro_trigger.set_deferred("monitoring", false)

	if player != null:
		player.cutscene_lock = true
		player.velocity = Vector2.ZERO

	timer_running = false
	if level_timer_ui != null:
		level_timer_ui.visible = false

	await stop_level_music()
	await _play_crystal_light_gain_fx()
	await get_tree().create_timer(1.0).timeout
	await _play_outro_cutscene_after_crystal()

	if player != null:
		player.velocity = Vector2.ZERO

	save_win_result()
	show_win_ui()


func _play_outro_cutscene_after_crystal() -> void:
	if outro_cutscene_played:
		return
	if player == null or monologue_outro == null:
		return

	outro_cutscene_played = true

	player.cutscene_lock = true
	player.velocity = Vector2.ZERO

	await _play_monologue(monologue_outro)

	player.velocity = Vector2.ZERO


func _play_monologue(monologue: Control) -> void:
	if monologue == null:
		return
	if not monologue.has_method("start"):
		return

	monologue.start()
	await get_tree().process_frame

	while is_instance_valid(monologue) and monologue.visible:
		await get_tree().process_frame

func _play_crystal_light_gain_fx() -> void:
	var light := get_node_or_null("Player/PointLight2D") as PointLight2D
	if light == null:
		return

	light.texture_scale = 1.0

	await get_tree().create_timer(0.1).timeout

	if blink_off_sound != null:
		blink_off_sound.play()
	light.texture_scale = 1.1
	await get_tree().create_timer(0.28).timeout

	if blink_off_sound != null:
		blink_off_sound.play()
	light.texture_scale = 1.0
	await get_tree().create_timer(0.28).timeout

	if blink_off_sound != null:
		blink_off_sound.play()
	light.texture_scale = 1.1
	await get_tree().create_timer(0.28).timeout

	if blink_off_sound != null:
		blink_off_sound.play()
	light.texture_scale = 1.0
	await get_tree().create_timer(0.35).timeout

	if light_on_sound != null:
		light_on_sound.play()
	light.texture_scale = 1.1

func _force_player_drop_for_intro() -> void:
	if player == null:
		return

	while not player.is_on_floor():
		await get_tree().physics_frame

	player.velocity.x = 0.0

func _wait_release_after_monologue() -> void:
	while Input.is_action_pressed("move_left") \
	or Input.is_action_pressed("move_right") \
	or Input.is_action_pressed("jump") \
	or Input.is_action_pressed("crouch") \
	or Input.is_action_pressed("interact"):
		await get_tree().process_frame

func _on_player_died() -> void:
	death_count += 1
