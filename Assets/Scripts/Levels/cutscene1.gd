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

var cam_base_pos := Vector2.ZERO

func _ready() -> void:
	cam_base_pos = cam.position
	world_dark.visible = false
	parallax_dark.visible = false
	player_light.enabled = false

func play_end_cutscene() -> void:
	player.set("cutscene_lock", true)

	await get_tree().create_timer(1.0).timeout

	var t := 1.6
	var strength := 7.0
	while t > 0.0:
		var dt := get_process_delta_time()
		t -= dt
		cam.position = cam_base_pos + Vector2(
			randf_range(-strength, strength),
			randf_range(-strength, strength)
		)
		await get_tree().process_frame
	cam.position = cam_base_pos

	world_dark.visible = true
	parallax_dark.visible = true
	world_dark.modulate.a = 0.0
	parallax_dark.modulate.a = 0.0

	var tw := create_tween()
	tw.tween_property(world_dark, "modulate:a", 1.0, 0.8)
	tw.parallel().tween_property(parallax_dark, "modulate:a", 1.0, 0.8)
	await tw.finished
	
	await monologue.call("start")
	while monologue.visible:
		await get_tree().process_frame

	await get_tree().create_timer(1.0).timeout

	player_light.enabled = true
	var target_energy := player_light.energy
	player_light.energy = 0.0

	var tw2 := create_tween()
	tw2.tween_property(player_light, "energy", target_energy, 1.0) # 1 сек плавно
	await tw2.finished
	get_parent().call("save_win_result")
	await get_tree().create_timer(2.0).timeout
	get_parent().call("show_win_ui")
