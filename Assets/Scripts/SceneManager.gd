extends Node

const MAIN_MENU := "res://Assets/Scenes/main_menu.tscn"
const LEVELS_MENU := "res://Assets/Scenes/levels_menu.tscn"
const SHOP := "res://Assets/Scenes/shop.tscn"
const LOCKER := "res://Assets/Scenes/locker.tscn"
const SETTINGS := "res://Assets/Scenes/settings.tscn"
const LEVELS_DIR := "res://Assets/Scenes/Levels/"

const FPS_COUNTER_SCENE := preload("res://Assets/Scenes/UI/FpsCounter.tscn")
const LOADING_SPINNER_SCENE := preload("res://Assets/Scenes/UI/LoadingSpinner.tscn")

const MAIN_MENU_SCENE := preload("res://Assets/Scenes/main_menu.tscn")
const LEVELS_MENU_SCENE := preload("res://Assets/Scenes/levels_menu.tscn")
const SHOP_SCENE := preload("res://Assets/Scenes/shop.tscn")
const LOCKER_SCENE := preload("res://Assets/Scenes/locker.tscn")
const SETTINGS_SCENE := preload("res://Assets/Scenes/settings.tscn")

const SLIDE_DUR := 0.35
const FADE_OUT_DUR := 0.45
const FADE_IN_DUR := 0.45
const LOADING_MIN_TIME := 0.5

const LEVELS_PER_PAGE := 3
var levels_menu_start_page: int = 0

enum Transition { FADE, SLIDE_LEFT, SLIDE_RIGHT, DROP_DOWN, DROP_UP }

signal transition_finished

var _fps_counter: CanvasLayer = null

var _busy := false
var _current: Node = null
var _stack: Array[Node] = []

var _layer: CanvasLayer
var _stage: Control

var _fade_layer: CanvasLayer
var _fade: ColorRect
var _loading_spinner: Control

var _opened_once: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	call_deferred("update_fps_counter")
	call_deferred("_adopt_initial_scene")


func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 1000
	add_child(_layer)

	_stage = Control.new()
	_stage.name = "Stage"
	_stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_stage)

	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 20000
	add_child(_fade_layer)

	_fade = ColorRect.new()
	_fade.name = "Fade"
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.color = Color(0, 0, 0, 1)
	_fade.modulate.a = 0.0
	_fade.visible = true
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_layer.add_child(_fade)

	_loading_spinner = LOADING_SPINNER_SCENE.instantiate()
	_loading_spinner.visible = false
	_fade_layer.add_child(_loading_spinner)


func _adopt_initial_scene() -> void:
	var cs := get_tree().current_scene
	if cs == null or cs == self:
		return

	if cs.get_parent() != null:
		cs.get_parent().remove_child(cs)

	if _is_level_path(cs.scene_file_path):
		get_tree().root.add_child(cs)
	else:
		_stage.add_child(cs)
		_set_pos(cs, Vector2.ZERO)

	_current = cs
	_stack.clear()
	_stack.append(_current)
	_mark_path_opened(cs.scene_file_path)


func goto_main_menu(tr: int = Transition.FADE) -> void:
	await _go(MAIN_MENU, tr, _is_current_level_scene())
	MusicManager.play_menu_music_delayed(0.5)


func goto_levels_menu(tr: int = Transition.FADE) -> void:
	await _go(LEVELS_MENU, tr, _is_current_level_scene())
	MusicManager.play_menu_music_delayed(0.5)


func goto_levels_menu_from_pause() -> void:
	if _busy:
		return

	_busy = true

	_set_levels_menu_page_from_current_level()

	await _go_fade_load_from_pause(LEVELS_MENU, true)
	_busy = false

	MusicManager.play_menu_music_delayed(0.5)


func goto_shop(tr: int = Transition.FADE) -> void:
	_go(SHOP, tr)


func goto_locker(tr: int = Transition.FADE) -> void:
	_go(LOCKER, tr)


func goto_settings(tr: int = Transition.FADE) -> void:
	_go(SETTINGS, tr)

func goto_level(i: int, tr: int = Transition.FADE) -> void:
	MusicManager.stop_menu_music()
	clear_stack_keep_top()
	var path := "%sLevel_%d.tscn" % [LEVELS_DIR, i + 1]
	_go(path, tr, true)


func goto_next_level(current_level_index: int, tr: int = Transition.FADE) -> void:
	goto_level(current_level_index + 1, tr)


func reload_current_level() -> void:
	if _busy:
		return
	if _current == null:
		return
	if _current.scene_file_path == "":
		return

	_busy = true

	var path := _current.scene_file_path
	var old := _current

	if old != null and is_instance_valid(old) and old.has_method("force_stop_level_music"):
		old.force_stop_level_music()

	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	_fade.modulate.a = 0.0

	var t := create_tween()
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(_fade, "modulate:a", 1.0, FADE_OUT_DUR)
	await t.finished

	var loading_started := Time.get_ticks_msec()
	_show_loading_spinner()

	get_tree().paused = false

	if old != null and is_instance_valid(old):
		old.queue_free()

	await get_tree().process_frame
	await get_tree().process_frame

	var packed: PackedScene = _get_packed_scene(path)
	var next: Node = packed.instantiate()
	get_tree().root.add_child(next)

	_current = next
	_stack.clear()
	_stack.append(_current)

	await get_tree().process_frame
	await get_tree().process_frame

	var elapsed := (Time.get_ticks_msec() - loading_started) / 1000.0
	if elapsed < LOADING_MIN_TIME:
		await get_tree().create_timer(LOADING_MIN_TIME - elapsed).timeout

	_hide_loading_spinner()

	var t2 := create_tween()
	t2.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t2.tween_property(_fade, "modulate:a", 0.0, FADE_IN_DUR)
	await t2.finished

	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false

	transition_finished.emit()


func back() -> void:
	if _busy:
		return
	_busy = true
	await _pop_overlay_up()
	_busy = false


func quit_game() -> void:
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()


func _go(path: String, tr: int, show_loading: bool = false) -> void:
	if _busy:
		return
	_busy = true
	var prepared_next: Node = null
	if _should_prepare_first_menu_scene(path, show_loading):
		prepared_next = await _prepare_scene_with_dots(path)

	if tr == Transition.DROP_DOWN:
		await _push_overlay_from_top(path, prepared_next)
		_busy = false
		return

	if tr == Transition.DROP_UP:
		await _back_load_under_and_slide_up(path, prepared_next)
		_busy = false
		return

	if tr == Transition.FADE:
		await _go_fade_load(path, show_loading, prepared_next)
		_busy = false
		return

	var next: Node = prepared_next
	if next == null:
		var packed: PackedScene = _get_packed_scene(path)
		next = packed.instantiate()

		if _is_level_path(path):
			get_tree().root.add_child(next)
		else:
			_stage.add_child(next)
	else:
		_set_canvas_item_alpha(next, 1.0)

	var size := get_viewport().get_visible_rect().size
	var old := _current

	match tr:
		Transition.SLIDE_LEFT:
			await _tr_slide(old, next, Vector2(-size.x, 0), Vector2(size.x, 0))
		Transition.SLIDE_RIGHT:
			await _tr_slide(old, next, Vector2(size.x, 0), Vector2(-size.x, 0))
		_:
			await _tr_fade(old, next)

	if old != null and is_instance_valid(old):
		old.queue_free()

	_current = next

	if not _is_level_path(path):
		_set_pos(_current, Vector2.ZERO)

	_stack.clear()
	_stack.append(_current)
	_mark_path_opened(path)
	
func _go_fade_load(path: String, show_loading: bool = false, prepared_next: Node = null) -> void:
	var old := _current

	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	_fade.modulate.a = 0.0

	var t := create_tween()
	t.tween_property(_fade, "modulate:a", 1.0, FADE_OUT_DUR)
	await t.finished

	var loading_started := 0
	if show_loading:
		_show_loading_spinner()
		loading_started = Time.get_ticks_msec()

	var next: Node = prepared_next
	if next == null:
		var packed: PackedScene = _get_packed_scene(path)
		next = packed.instantiate()

		if _is_level_path(path):
			get_tree().root.add_child(next)
		else:
			_stage.add_child(next)
			_set_pos(next, Vector2.ZERO)
	else:
		_set_canvas_item_alpha(next, 1.0)
		if not _is_level_path(path):
			_set_pos(next, Vector2.ZERO)

	await get_tree().process_frame
	await get_tree().process_frame

	if show_loading:
		var elapsed := (Time.get_ticks_msec() - loading_started) / 1000.0
		if elapsed < LOADING_MIN_TIME:
			await get_tree().create_timer(LOADING_MIN_TIME - elapsed).timeout

	if old != null and is_instance_valid(old):
		old.queue_free()

	_current = next
	_stack.clear()
	_stack.append(_current)
	_mark_path_opened(path)

	if show_loading:
		_hide_loading_spinner()

	var t2 := create_tween()
	t2.tween_property(_fade, "modulate:a", 0.0, FADE_IN_DUR)
	await t2.finished

	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_finished.emit()


func _go_fade_load_from_pause(path: String, show_loading: bool = false) -> void:
	var old := _current

	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	_fade.modulate.a = 0.0

	var t := create_tween()
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(_fade, "modulate:a", 1.0, FADE_OUT_DUR)
	await t.finished

	var loading_started := 0
	if show_loading:
		_show_loading_spinner()
		loading_started = Time.get_ticks_msec()

	get_tree().paused = false

	var packed: PackedScene = _get_packed_scene(path)
	var next: Node = packed.instantiate()

	if _is_level_path(path):
		get_tree().root.add_child(next)
	else:
		_stage.add_child(next)
		_set_pos(next, Vector2.ZERO)

	await get_tree().process_frame
	await get_tree().process_frame

	if show_loading:
		var elapsed := (Time.get_ticks_msec() - loading_started) / 1000.0
		if elapsed < LOADING_MIN_TIME:
			await get_tree().create_timer(LOADING_MIN_TIME - elapsed).timeout

	if old != null and is_instance_valid(old):
		old.queue_free()

	_current = next
	_stack.clear()
	_stack.append(_current)

	if show_loading:
		_hide_loading_spinner()

	var t2 := create_tween()
	t2.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t2.tween_property(_fade, "modulate:a", 0.0, FADE_IN_DUR)
	await t2.finished

	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_finished.emit()


func _push_overlay_from_top(path: String, prepared_next: Node = null) -> void:
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	_fade.modulate.a = 0.0

	if _stack.is_empty() and _current != null and is_instance_valid(_current):
		_stack.append(_current)

	var next: Node = prepared_next
	if next == null:
		var packed: PackedScene = _get_packed_scene(path)
		next = packed.instantiate()
		_stage.add_child(next)
	else:
		_set_canvas_item_alpha(next, 1.0)

	var size := get_viewport().get_visible_rect().size
	var from := Vector2(0, -size.y)

	next.visible = true
	_set_pos(next, from)

	var t := create_tween()
	t.tween_property(next, "position", Vector2.ZERO, SLIDE_DUR).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await t.finished

	_stack.append(next)
	_mark_path_opened(path)
	_current = next

	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _back_load_under_and_slide_up(path: String, prepared_next: Node = null) -> void:
	if _stack.size() >= 2:
		await _pop_overlay_up()
		return

	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	_fade.modulate.a = 0.0

	var top: Node = _current
	if top == null or !is_instance_valid(top):
		_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return

	var under: Node = prepared_next
	if under == null:
		var packed: PackedScene = _get_packed_scene(path)
		under = packed.instantiate()
		_stage.add_child(under)
	else:
		_set_canvas_item_alpha(under, 1.0)

	_stage.move_child(under, top.get_index())

	under.visible = true
	_set_pos(under, Vector2.ZERO)

	var size := get_viewport().get_visible_rect().size
	var t := create_tween()
	t.tween_property(top, "position", Vector2(0, -size.y), SLIDE_DUR).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await t.finished

	top.queue_free()
	_current = under

	_stack.clear()
	_stack.append(_current)
	_mark_path_opened(path)

	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _pop_overlay_up() -> void:
	if _stack.size() < 2:
		return

	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	_fade.modulate.a = 0.0

	var top: Node = _stack[_stack.size() - 1]
	var below: Node = _stack[_stack.size() - 2]

	below.visible = true
	_set_pos(below, Vector2.ZERO)

	var size := get_viewport().get_visible_rect().size
	var t := create_tween()
	t.tween_property(top, "position", Vector2(0, -size.y), SLIDE_DUR).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await t.finished

	top.queue_free()
	_stack.pop_back()
	_current = below

	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _tr_fade(old: Node, next: Node) -> void:
	next.visible = false
	if not _is_level_path(next.scene_file_path):
		_set_pos(next, Vector2.ZERO)

	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	_fade.modulate.a = 0.0

	var t := create_tween()
	t.tween_property(_fade, "modulate:a", 1.0, FADE_OUT_DUR)
	await t.finished

	if old != null and is_instance_valid(old):
		old.visible = false
	next.visible = true

	var t2 := create_tween()
	t2.tween_property(_fade, "modulate:a", 0.0, FADE_IN_DUR)
	await t2.finished

	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _tr_slide(old: Node, next: Node, old_to: Vector2, new_from: Vector2) -> void:
	_set_pos(next, new_from)
	_set_pos(old, Vector2.ZERO)

	var t := create_tween()
	t.set_parallel(true)

	if old != null and is_instance_valid(old):
		t.tween_property(old, "position", old_to, SLIDE_DUR).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	t.tween_property(next, "position", Vector2.ZERO, SLIDE_DUR).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await t.finished


func _set_pos(n: Node, p: Vector2) -> void:
	if n == null or !is_instance_valid(n):
		return
	if n.has_method("set_position"):
		n.set_position(p)
	elif "position" in n:
		n.position = p


func clear_stack_keep_top() -> void:
	if _stack.size() <= 1:
		return

	for idx in range(_stack.size() - 1):
		var n: Node = _stack[idx]
		if n != null and is_instance_valid(n):
			n.queue_free()

	var top := _stack[_stack.size() - 1]
	_stack.clear()
	_stack.append(top)


func _show_fps_counter() -> void:
	if _fps_counter != null and is_instance_valid(_fps_counter):
		return

	_fps_counter = FPS_COUNTER_SCENE.instantiate()
	_fps_counter.layer = 1001
	get_tree().root.add_child(_fps_counter)


func _hide_fps_counter() -> void:
	if _fps_counter == null or not is_instance_valid(_fps_counter):
		return

	_fps_counter.queue_free()
	_fps_counter = null


func update_fps_counter() -> void:
	if GameState.show_fps:
		_show_fps_counter()
	else:
		_hide_fps_counter()


func _show_loading_spinner() -> void:
	if _loading_spinner == null or not is_instance_valid(_loading_spinner):
		return
	_loading_spinner.visible = true


func _hide_loading_spinner() -> void:
	if _loading_spinner == null or not is_instance_valid(_loading_spinner):
		return
	_loading_spinner.visible = false


func is_transitioning() -> bool:
	return _busy


func _get_packed_scene(path: String) -> PackedScene:
	match path:
		MAIN_MENU:
			return MAIN_MENU_SCENE
		LEVELS_MENU:
			return LEVELS_MENU_SCENE
		SHOP:
			return SHOP_SCENE
		LOCKER:
			return LOCKER_SCENE
		SETTINGS:
			return SETTINGS_SCENE
		_:
			return load(path) as PackedScene


func _is_level_path(path: String) -> bool:
	return path.contains("/Levels/")


func _is_current_level_scene() -> bool:
	return _current != null and is_instance_valid(_current) and _is_level_path(_current.scene_file_path)

func _mark_path_opened(path: String) -> void:
	if path == "":
		return

	_opened_once[path] = true

func _should_prepare_first_menu_scene(path: String, show_loading: bool) -> bool:
	if show_loading:
		return false

	if _is_level_path(path):
		return false

	match path:
		LEVELS_MENU, SHOP, LOCKER, SETTINGS:
			return not _opened_once.get(path, false)
		_:
			return false

func _set_canvas_item_alpha(node: Node, alpha: float) -> void:
	if node is CanvasItem:
		(node as CanvasItem).modulate.a = alpha

func _prepare_scene_with_dots(path: String) -> Node:
	var loading_started := Time.get_ticks_msec()
	_show_loading_spinner()

	var packed: PackedScene = _get_packed_scene(path)
	var next: Node = packed.instantiate()

	_stage.add_child(next)
	_set_pos(next, Vector2.ZERO)
	_set_canvas_item_alpha(next, 0.0)

	await get_tree().process_frame
	await get_tree().process_frame

	var elapsed := (Time.get_ticks_msec() - loading_started) / 1000.0
	if elapsed < LOADING_MIN_TIME:
		await get_tree().create_timer(LOADING_MIN_TIME - elapsed).timeout

	_hide_loading_spinner()
	return next

func _set_levels_menu_page_from_current_level() -> void:
	levels_menu_start_page = 0

	if _current == null:
		return

	var path := _current.scene_file_path
	if path == "":
		return

	var file_name := path.get_file().get_basename()
	var parts := file_name.split("_")

	for part in parts:
		if part.is_valid_int():
			var level_number := int(part)

			if level_number > 0:
				levels_menu_start_page = int((level_number - 1) / LEVELS_PER_PAGE)

			return


func consume_levels_menu_start_page() -> int:
	var p := levels_menu_start_page
	levels_menu_start_page = 0
	return p

func fade_to_black(duration: float = FADE_OUT_DUR) -> void:
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP

	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(_fade, "modulate:a", 1.0, duration)

	await tw.finished


func fade_from_black(duration: float = FADE_IN_DUR) -> void:
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(_fade, "modulate:a", 0.0, duration)

	await tw.finished

	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
