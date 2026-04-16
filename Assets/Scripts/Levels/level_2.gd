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
	if level_time <= 35.0:
		return 3
	if level_time <= 50.0:
		return 2
	return 1


func save_win_result() -> void:
	GameState.save_level_result(1, get_earned_stars(), level_time)


func show_win_ui() -> void:
	var win_ui := get_node_or_null("WinUi")
	if win_ui == null:
		return

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
