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

var boss_intro_started := false
var boss_fight_started := false
var boss_fight_resetting := false
var boss_fight_checkpoint_time := 0.0

@export var boss_camera_move_time: float = 1.2

@export var world_light_restore_time: float = 4.0
@export var player_light_fade_time: float = 1.8

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

@onready var boss_intro_trigger: Area2D = get_node_or_null("BossIntroTrigger")
@onready var boss_run_target: Marker2D = get_node_or_null("BossRunTarget")
@onready var boss_camera_target: Marker2D = get_node_or_null("BossCameraTarget")
@onready var boss_arena_left_wall: StaticBody2D = get_node_or_null("BossArenaLeftWall")
@onready var boss: CharacterBody2D = get_node_or_null("BringerBoss")
@onready var final_crystal: Area2D = get_node_or_null("Crystal")
@onready var boss_hp_ui: CanvasLayer = get_node_or_null("BossHpUi")
@onready var boss_dialogue: Control = get_node_or_null("BossDialogueUi/Root/BossDialogue")

var credits_ui: CanvasLayer = null

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

	if boss_intro_trigger != null and not boss_intro_trigger.is_connected("body_entered", Callable(self, "_on_boss_intro_trigger_body_entered")):
		boss_intro_trigger.connect("body_entered", Callable(self, "_on_boss_intro_trigger_body_entered"))

	if boss != null and boss.has_signal("hp_changed") and not boss.is_connected("hp_changed", Callable(self, "_on_boss_hp_changed")):
		boss.connect("hp_changed", Callable(self, "_on_boss_hp_changed"))

	if boss != null and boss.has_signal("defeated") and not boss.is_connected("defeated", Callable(self, "_on_boss_defeated")):
		boss.connect("defeated", Callable(self, "_on_boss_defeated"))

	if final_crystal != null and final_crystal.has_signal("collected") and not final_crystal.is_connected("collected", Callable(self, "_on_final_crystal_collected")):
		final_crystal.connect("collected", Callable(self, "_on_final_crystal_collected"))

	if boss_arena_left_wall != null:
		var wall_shape := boss_arena_left_wall.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if wall_shape != null:
			wall_shape.disabled = true

	_set_final_crystal_locked(true)

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


func stop_level_music(fade_time: float = LEVEL_MUSIC_FADE_OUT) -> void:
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
	tw.tween_property(level_music, "volume_linear", 0.001, fade_time) \
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

	if boss_fight_started and not finished and not boss_fight_resetting:
		_restart_boss_fight_after_death()

func _on_boss_intro_trigger_body_entered(body: Node) -> void:
	if boss_intro_started:
		return

	if not body.is_in_group("player"):
		return

	boss_intro_started = true
	_start_boss_intro_sequence()


func _start_boss_intro_sequence() -> void:
	if player == null or boss_run_target == null or boss_camera_target == null:
		return

	finish_transition = true
	timer_running = false
	_set_level_timer_visible(false)

	if boss_intro_trigger != null:
		boss_intro_trigger.set_deferred("monitoring", false)

	player.disable_attack()
	player.cutscene_lock = false
	player.start_finish_auto_run()

	stop_level_music(4.0)

	while player.global_position.x < boss_run_target.global_position.x:
		await get_tree().physics_frame

	player.stop_finish_auto_run()
	player.velocity = Vector2.ZERO
	player.cutscene_lock = true

	await get_tree().physics_frame

	player.set_camera_follow_enabled(false)

	var cam := player.get_node_or_null("Camera2D") as Camera2D
	if cam != null:
		var tw := create_tween()
		tw.tween_property(cam, "global_position", boss_camera_target.global_position.round(), boss_camera_move_time) \
			.set_trans(Tween.TRANS_SINE) \
			.set_ease(Tween.EASE_IN_OUT)

		await tw.finished

	_enable_boss_arena_wall()

	await _play_pre_boss_dialogue()

	_start_boss_fight()


func _enable_boss_arena_wall() -> void:
	if boss_arena_left_wall == null:
		return

	var wall_shape := boss_arena_left_wall.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if wall_shape != null:
		wall_shape.disabled = false


func _start_boss_fight() -> void:
	if boss_fight_started:
		return

	boss_fight_started = true
	boss_fight_checkpoint_time = level_time
	timer_running = true
	_set_level_timer_visible(true)
	finish_transition = false

	if player != null:
		player.cutscene_lock = false
		player.enable_attack()

	if boss_hp_ui != null and boss != null:
		if boss_hp_ui.has_method("setup") and boss.has_method("get_max_hp") and boss.has_method("get_hp"):
			boss_hp_ui.setup(boss.get_max_hp(), boss.get_hp())

	if boss != null and boss.has_method("start_fight"):
		boss.start_fight()

func _set_final_crystal_locked(value: bool) -> void:
	if final_crystal == null:
		return

	if final_crystal.has_method("set_locked"):
		final_crystal.set_locked(value)

func get_current_respawn_point() -> Node2D:
	if boss_intro_started or boss_fight_started:
		return boss_run_target

	return spawn_point

func _restart_boss_fight_after_death() -> void:
	boss_fight_resetting = true
	timer_running = false
	_set_level_timer_visible(false)
	if boss_hp_ui != null and boss_hp_ui.has_method("hide_ui"):
		boss_hp_ui.hide_ui()

	if player != null:
		player.disable_attack()
		player.cutscene_lock = true

	await get_tree().create_timer(0.75, false).timeout
	await SceneManager.fade_to_black(0.7)

	if boss != null and boss.has_method("stop_fight"):
		boss.stop_fight()

	await _wait_until_player_respawn_finished()

	_clear_boss_spells()

	level_time = boss_fight_checkpoint_time

	if level_timer_ui != null:
		level_timer_ui.set_time_text(get_level_time_text())

	if player != null:
		player.set_camera_follow_enabled(false)

		var cam := player.get_node_or_null("Camera2D") as Camera2D
		if cam != null and boss_camera_target != null:
			cam.global_position = boss_camera_target.global_position.round()

	if boss != null and boss.has_method("reset_fight"):
		boss.reset_fight()

	await get_tree().create_timer(0.25, false).timeout
	await SceneManager.fade_from_black(0.7)

	await get_tree().create_timer(0.45, false).timeout

	timer_running = true
	_set_level_timer_visible(true)
	if boss_hp_ui != null and boss != null:
		if boss_hp_ui.has_method("setup") and boss.has_method("get_max_hp") and boss.has_method("get_hp"):
			boss_hp_ui.setup(boss.get_max_hp(), boss.get_hp())

	if player != null:
		player.cutscene_lock = false
		player.enable_attack()

	if boss != null and boss.has_method("start_fight"):
		boss.start_fight()

	boss_fight_resetting = false


func _wait_until_player_respawn_finished() -> void:
	if player == null:
		return

	while true:
		var busy := false

		if "is_dying" in player and player.is_dying:
			busy = true

		if "death_windup_active" in player and player.death_windup_active:
			busy = true

		if "death_respawn_active" in player and player.death_respawn_active:
			busy = true

		if "fall_respawn_active" in player and player.fall_respawn_active:
			busy = true

		if not busy:
			return

		await get_tree().physics_frame


func _clear_boss_spells() -> void:
	for spell in get_tree().get_nodes_in_group("boss_spell"):
		if spell != null and is_instance_valid(spell) and is_ancestor_of(spell):
			spell.queue_free()

func _set_level_timer_visible(value: bool) -> void:
	if level_timer_ui != null:
		level_timer_ui.visible = value

func _on_boss_hp_changed(max_hp: int, current_hp: int) -> void:
	if boss_hp_ui != null and boss_hp_ui.has_method("update_hp"):
		boss_hp_ui.update_hp(max_hp, current_hp)


func _on_boss_defeated() -> void:
	if finished:
		return

	finish_transition = true
	timer_running = false
	_set_level_timer_visible(false)

	if boss_hp_ui != null and boss_hp_ui.has_method("hide_ui"):
		boss_hp_ui.hide_ui()

	if player != null:
		player.disable_attack()
		player.cutscene_lock = true
		player.velocity = Vector2.ZERO

	await _play_after_boss_dialogue()

	if boss != null and boss.has_method("play_death"):
		await boss.play_death()

	await get_tree().create_timer(0.5, false).timeout

	_set_final_crystal_locked(false)

	boss_fight_started = false
	timer_running = true
	_set_level_timer_visible(true)

	if player != null:
		player.cutscene_lock = false

	finish_transition = false

func _play_pre_boss_dialogue() -> void:
	if boss_dialogue == null or not boss_dialogue.has_method("play_sequence"):
		return

	await boss_dialogue.play_sequence([
		{
			"speaker": "Varonis",
			"text": "Kas tu esi? Ko tu šeit dari?"
		},
		{
			"speaker": "Apokalipse",
			"text": "Es esmu Apokalipse. Es sargāju pēdējo kristālu."
		},
		{
			"speaker": "Varonis",
			"text": "Es tevi apturēšu un atjaunošu visuma līdzsvaru."
		},
		{
			"speaker": "Apokalipse",
			"text": "Tad parādi, ko spēj, mirstīgais."
		}
	])

func _play_after_boss_dialogue() -> void:
	if boss_dialogue == null or not boss_dialogue.has_method("play_sequence"):
		return

	await boss_dialogue.play_sequence([
		{
			"speaker": "Apokalipse",
			"text": "Kā tas iespējams... Kā mirstīgais spēja mani uzva..."
		}
	])

func _on_final_crystal_collected() -> void:
	if finished:
		return

	finished = true
	finish_transition = true
	timer_running = false
	_set_level_timer_visible(false)

	if player != null:
		player.disable_attack()
		player.cutscene_lock = true
		player.velocity = Vector2.ZERO

	await _restore_world_light_fx()

	await get_tree().create_timer(0.8, false).timeout

	await SceneManager.fade_to_black(1.0)

	var credits := _get_credits_ui()

	if credits == null:
		push_error("CreditsUi still not found")
	else:
		if credits.has_method("show_black_bg"):
			credits.show_black_bg()

	await SceneManager.fade_from_black(0.35)

	if credits != null and credits.has_method("play_credits"):
		await credits.play_credits()

	save_win_result()
	show_win_ui()

func _restore_world_light_fx() -> void:
	var player_light := get_node_or_null("Player/PointLight2D") as PointLight2D

	if light_on_sound != null:
		light_on_sound.play()

	var tw := create_tween()
	tw.set_parallel(true)

	if player_light != null:
		tw.tween_property(player_light, "energy", 0.0, player_light_fade_time) \
			.set_trans(Tween.TRANS_SINE) \
			.set_ease(Tween.EASE_IN_OUT)

	if world_dark != null:
		world_dark.visible = true
		tw.tween_property(world_dark, "color", Color(1, 1, 1, 1), world_light_restore_time) \
			.set_trans(Tween.TRANS_SINE) \
			.set_ease(Tween.EASE_IN_OUT)

	if parallax_dark != null:
		parallax_dark.visible = true
		tw.tween_property(parallax_dark, "color", Color(1, 1, 1, 1), world_light_restore_time) \
			.set_trans(Tween.TRANS_SINE) \
			.set_ease(Tween.EASE_IN_OUT)

	await tw.finished

	if world_dark != null:
		world_dark.visible = false

	if parallax_dark != null:
		parallax_dark.visible = false

	if player_light != null:
		player_light.enabled = false

func get_earned_stars() -> int:
	var max_by_deaths := 3

	if death_count == 1:
		max_by_deaths = 2
	elif death_count >= 2:
		max_by_deaths = 1

	var stars_by_time := 1

	if level_time <= 80.0:
		stars_by_time = 3
	elif level_time <= 110.0:
		stars_by_time = 2

	return min(max_by_deaths, stars_by_time)


func save_win_result() -> void:
	GameState.save_level_result(LEVEL_INDEX, get_earned_stars(), level_time)


func show_win_ui() -> void:
	var win_ui := get_node_or_null("WinUi")
	if win_ui == null:
		win_ui = get_node_or_null("WinUI")

	if win_ui == null:
		return

	GameState.show_cursor()
	win_ui.setup_result(get_earned_stars(), get_level_time_text(), LEVEL_INDEX)

	var death_label := win_ui.get_node_or_null("Panel/VBox/DeathLabel") as Label
	if death_label != null:
		death_label.text = "Nāves: %d" % death_count

	win_ui.show_with_anim()

func _get_credits_ui() -> CanvasLayer:
	if credits_ui == null:
		credits_ui = get_node_or_null("CreditsUi") as CanvasLayer

	return credits_ui
