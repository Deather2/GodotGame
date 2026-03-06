extends Node2D

var finished := false
var pending_finish := false

func _physics_process(_delta: float) -> void:
	if finished or !pending_finish:
		return

	var p := $Player
	if p is CharacterBody2D and (p as CharacterBody2D).is_on_floor():
		pending_finish = false
		finished = true
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
	$Cutscene.play_end_cutscene()
