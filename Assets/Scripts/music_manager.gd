extends Node

@onready var menu_music: AudioStreamPlayer = $MenuMusicPlayer

var _menu_play_request_id: int = 0


func play_menu_music() -> void:
	_menu_play_request_id += 1

	if menu_music.stream == null:
		return
	if not menu_music.playing:
		menu_music.play()


func play_menu_music_delayed(delay: float = 0.25) -> void:
	_menu_play_request_id += 1
	var request_id := _menu_play_request_id

	await get_tree().create_timer(delay).timeout

	if request_id != _menu_play_request_id:
		return

	if menu_music.stream == null:
		return
	if not menu_music.playing:
		menu_music.play()


func stop_menu_music() -> void:
	_menu_play_request_id += 1

	if menu_music.playing:
		menu_music.stop()
