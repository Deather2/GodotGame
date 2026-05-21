extends CanvasLayer

@onready var panel: PanelContainer = $PanelContainer
@onready var title_label: Label = $PanelContainer/VBoxContainer/TitleLabel
@onready var count_label: Label = $PanelContainer/VBoxContainer/CountLabel

var showing := false
var shown_pos: Vector2
var hidden_pos: Vector2


func _ready() -> void:
	layer = 1100
	visible = false

	await get_tree().process_frame

	shown_pos = panel.position
	hidden_pos = shown_pos + Vector2(panel.size.x + 60.0, 0.0)

	panel.position = hidden_pos
	panel.modulate.a = 0.0
	panel.scale = Vector2.ONE


func show_artifact_collected() -> void:
	var collected := GameState.get_collected_hidden_crystals_count()
	var total := GameState.get_hidden_crystals_count()

	title_label.text = "Artefakts atrasts!"
	count_label.text = "Savākti artefakti: %d / %d" % [collected, total]

	if showing:
		return

	showing = true
	visible = true

	panel.position = hidden_pos
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.96, 0.96)

	var tw := create_tween()
	tw.set_parallel(true)

	tw.tween_property(panel, "position", shown_pos, 0.35) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)

	tw.tween_property(panel, "modulate:a", 1.0, 0.2)

	tw.tween_property(panel, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)

	await tw.finished
	await get_tree().create_timer(2.2).timeout

	var tw_out := create_tween()
	tw_out.set_parallel(true)

	tw_out.tween_property(panel, "position", hidden_pos, 0.3) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_IN)

	tw_out.tween_property(panel, "modulate:a", 0.0, 0.2)
	tw_out.tween_property(panel, "scale", Vector2(0.96, 0.96), 0.25)

	await tw_out.finished

	visible = false
	showing = false
