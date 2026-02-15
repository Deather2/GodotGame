extends Node

const MAIN_MENU  := "res://Assets/Scenes/main_menu.tscn"
const LEVELS_MENU := "res://Assets/Scenes/levels_menu.tscn"
const SHOP       := "res://Assets/Scenes/shop.tscn"
const LOCKER     := "res://Assets/Scenes/locker.tscn"
const SETTINGS   := "res://Assets/Scenes/settings.tscn"
const LEVELS_DIR := "res://Assets/Scenes/Levels/"

const SLIDE_DUR := 0.35
const FADE_OUT_DUR := 0.45
const FADE_IN_DUR := 0.45

enum Transition { FADE, SLIDE_LEFT, SLIDE_RIGHT, DROP_DOWN, DROP_UP }

var _busy := false
var _current: Node = null
var _stack: Array[Node] = []

var _layer: CanvasLayer
var _stage: Control

var _fade_layer: CanvasLayer
var _fade: ColorRect


func _ready() -> void:
	_build_ui()
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


func _adopt_initial_scene() -> void:
	var cs := get_tree().current_scene
	if cs == null or cs == self:
		return

	if cs.get_parent() != null and cs.get_parent() != _stage:
		cs.get_parent().remove_child(cs)

	_stage.add_child(cs)
	_current = cs
	_set_pos(_current, Vector2.ZERO)

	_stack.clear()
	_stack.append(_current)


func goto_main_menu(tr: int = Transition.FADE) -> void:
	_go(MAIN_MENU, tr)

func goto_levels_menu(tr: int = Transition.FADE) -> void:
	_go(LEVELS_MENU, tr)

func goto_shop(tr: int = Transition.FADE) -> void:
	_go(SHOP, tr)

func goto_locker(tr: int = Transition.FADE) -> void:
	_go(LOCKER, tr)

func goto_settings(tr: int = Transition.FADE) -> void:
	_go(SETTINGS, tr)
	
func goto_level(i: int, tr: int = Transition.FADE) -> void:
	clear_stack_keep_top()
	var path := "%sLevel_%d.tscn" % [LEVELS_DIR, i + 1]
	_go(path, tr)

func back() -> void:
	if _busy:
		return
	_busy = true
	await _pop_overlay_up()
	_busy = false

func quit_game() -> void:
	get_tree().quit()


func _go(path: String, tr: int) -> void:
	if _busy:
		return
	_busy = true

	if tr == Transition.DROP_DOWN:
		await _push_overlay_from_top(path)
		_busy = false
		return

	if tr == Transition.DROP_UP:
		await _back_load_under_and_slide_up(path)
		_busy = false
		return

	var packed: PackedScene = load(path) as PackedScene
	var next: Node = packed.instantiate()
	_stage.add_child(next)

	var size := get_viewport().get_visible_rect().size
	var old := _current

	match tr:
		Transition.FADE:
			await _tr_fade(old, next)
		Transition.SLIDE_LEFT:
			await _tr_slide(old, next, Vector2(-size.x, 0), Vector2(size.x, 0))
		Transition.SLIDE_RIGHT:
			await _tr_slide(old, next, Vector2(size.x, 0), Vector2(-size.x, 0))
		_:
			await _tr_fade(old, next)

	if old != null and is_instance_valid(old):
		old.queue_free()

	_current = next
	_set_pos(_current, Vector2.ZERO)

	_stack.clear()
	_stack.append(_current)

	_busy = false


func _push_overlay_from_top(path: String) -> void:
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	_fade.modulate.a = 0.0

	if _stack.is_empty() and _current != null and is_instance_valid(_current):
		_stack.append(_current)

	var packed: PackedScene = load(path) as PackedScene
	var next: Node = packed.instantiate()
	_stage.add_child(next)

	var size := get_viewport().get_visible_rect().size
	var from := Vector2(0, -size.y)

	next.visible = true
	_set_pos(next, from)

	var t := create_tween()
	t.tween_property(next, "position", Vector2.ZERO, SLIDE_DUR).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await t.finished

	_stack.append(next)
	_current = next

	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _back_load_under_and_slide_up(path: String) -> void:
	if _stack.size() >= 2:
		await _pop_overlay_up()
		return

	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	_fade.modulate.a = 0.0

	var top: Node = _current
	if top == null or !is_instance_valid(top):
		_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return

	var packed: PackedScene = load(path) as PackedScene
	var under: Node = packed.instantiate()
	_stage.add_child(under)

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
