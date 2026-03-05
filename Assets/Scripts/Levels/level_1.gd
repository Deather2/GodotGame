extends Node2D

var finished := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_kill_zone_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.die()


func _on_finish_area_body_entered(body: Node2D) -> void:
	if finished:
		return
	if !body.is_in_group("player"):
		return

	finished = true
	$Cutscene.play_end_cutscene()
