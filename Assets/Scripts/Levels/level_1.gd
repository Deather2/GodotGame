extends Node2D

var finished := false
var pending_finish := false

var level_time := 0.0
var timer_running := true

@onready var level_timer_ui = $LevelTimer

func _physics_process(_delta: float) -> void:
	if finished or !pending_finish:
		return

	var p := $Player
	if p is CharacterBody2D and (p as CharacterBody2D).is_on_floor():
		pending_finish = false
		finished = true
		timer_running = false
		$LevelTimer.visible = false
		$Cutscene.play_end_cutscene()

func _on_kill_zone_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.die()


func _on_finish_area_body_entered(body: Node2D) -> void:
	if finished:
		return
	if !body.is_in_group("player"):
		return

	if body is CharacterBody2D and !(body as CharacterBody2D).is_on_floor():
		pending_finish = true
		return

	finished = true
	timer_running = false
	$LevelTimer.visible = false
	$Cutscene.play_end_cutscene()

func _process(delta: float) -> void:
	if timer_running and !finished:
		level_time += delta
		level_timer_ui.set_time_text(get_level_time_text())	

func get_level_time_text() -> String:
	var total_seconds := int(level_time)
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]

func get_earned_stars() -> int:
	if level_time <= 20.0:
		return 3
	if level_time <= 30.0:
		return 2
	return 1

func save_win_result() -> void:
	GameState.save_level_result(0, get_earned_stars(), level_time)

func show_win_ui() -> void:
	$WinUi.setup_result(get_earned_stars(), get_level_time_text(), 0)
	$WinUi.show_with_anim()
