extends Node

@export var player_path: NodePath
@export var camera_path: NodePath
@export var world_dark_path: NodePath
@export var parallax_dark_path: NodePath
@export var player_light_path: NodePath

@export var monologue_path: NodePath
@onready var monologue := get_node(monologue_path)

@onready var player := get_node(player_path)
@onready var cam := get_node(camera_path) as Camera2D
@onready var world_dark := get_node(world_dark_path) as CanvasModulate
@onready var parallax_dark := get_node(parallax_dark_path) as CanvasModulate
@onready var player_light := get_node(player_light_path) as PointLight2D

@onready var earthquake_sound: AudioStreamPlayer = $EarthquakeSound

var earthquake_base_volume := 1.0


func _ready() -> void:
	world_dark.visible = false
	parallax_dark.visible = false
	player_light.enabled = false
	cam.offset = Vector2.ZERO

	earthquake_base_volume = earthquake_sound.volume_linear


func _fade_in_earthquake(time_sec := 0.35) -> void:
	earthquake_sound.stop()
	earthquake_sound.volume_linear = 0.001
	earthquake_sound.play()

	var tw := create_tween()
	tw.tween_property(earthquake_sound, "volume_linear", earthquake_base_volume, time_sec) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)
	await tw.finished


func _play_earthquake_shake(duration := 2.6, max_strength := 5.0, fade_out_time := 0.6) -> void:
	var elapsed := 0.0
	var phase_x := randf() * TAU
	var phase_y := randf() * TAU

	while elapsed < duration:
		var dt := get_process_delta_time()
		elapsed += dt

		var p := clampf(elapsed / duration, 0.0, 1.0)

		var envelope := sin(p * PI)
		var strength := lerpf(0.25, max_strength, envelope)
		var freq := lerpf(1.8, 8.0, envelope)

		phase_x += dt * freq * TAU * 1.0
		phase_y += dt * freq * TAU * 1.37

		var offset := Vector2(
			sin(phase_x),
			cos(phase_y + 0.8)
		) * strength

		cam.offset = offset.round()

		var fade_start := duration - fade_out_time
		if elapsed >= fade_start:
			var fade_p := clampf((elapsed - fade_start) / fade_out_time, 0.0, 1.0)
			earthquake_sound.volume_linear = lerpf(earthquake_base_volume, 0.001, fade_p)

		await get_tree().process_frame

	cam.offset = Vector2.ZERO
	earthquake_sound.stop()
	earthquake_sound.volume_linear = earthquake_base_volume


func play_end_cutscene() -> void:
	player.set("cutscene_lock", true)

	await _fade_in_earthquake(0.35)
	await get_tree().create_timer(0.18).timeout
	await _play_earthquake_shake(3.2, 5.0)

	world_dark.visible = true
	parallax_dark.visible = true
	world_dark.modulate.a = 0.0
	parallax_dark.modulate.a = 0.0

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(world_dark, "modulate:a", 1.0, 0.8) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(parallax_dark, "modulate:a", 1.0, 0.8) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)

	await tw.finished

	await monologue.call("start")
	while monologue.visible:
		await get_tree().process_frame

	await get_tree().create_timer(1.0).timeout

	player_light.enabled = true
	var target_energy := player_light.energy
	player_light.energy = 0.0

	var tw2 := create_tween()
	tw2.tween_property(player_light, "energy", target_energy, 1.0) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)
	await tw2.finished

	get_parent().call("save_win_result")
	await get_tree().create_timer(1.0).timeout
	get_parent().call("show_win_ui")
