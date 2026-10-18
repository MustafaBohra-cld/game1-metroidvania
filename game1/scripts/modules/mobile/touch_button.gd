extends Control
## TouchButton — circular touch action button (Mobile module).
## Reports press/release to GameInput. Spec: 76px circle.

class_name TouchButton

const DIAMETER := 76.0

@export var action_name: StringName = &"jump"

var _touch_id: int = -1
var _pressed := false
var _gi: Node


func _ready() -> void:
	custom_minimum_size = Vector2(DIAMETER, DIAMETER)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gi = get_node("/root/GameInput")


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var inside: bool = get_global_rect().has_point(event.position)
		if event.pressed and _touch_id == -1 and inside:
			_touch_id = event.index
			_set_pressed(true)
		elif not event.pressed and event.index == _touch_id:
			_touch_id = -1
			_set_pressed(false)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var inside: bool = get_global_rect().has_point(event.position)
		if event.pressed and inside:
			_set_pressed(true)
		elif not event.pressed and _pressed:
			_set_pressed(false)


func _set_pressed(p: bool) -> void:
	_pressed = p
	match action_name:
		&"jump":
			if p:
				_gi.press_jump()
				_gi.set_touch_jump_held(true)
			else:
				_gi.set_touch_jump_held(false)
				_gi.notify_jump_released()
		&"attack":
			if p:
				_gi.press_attack()
		&"heal":
			_gi.set_touch_heal_held(p)
		&"interact":
			if p:
				_gi.press_interact()
		&"dash":
			if p:
				_gi.press_dash()
		&"pause":
			if p:
				var pp := get_tree().get_first_node_in_group("pause_panel")
				if pp != null and pp.has_method("toggle"):
					pp.toggle()
	queue_redraw()


func _draw() -> void:
	var r: float = minf(size.x, size.y) * 0.5
	var c: Vector2 = size * 0.5
	var fill := Color(1.0, 0.48, 0.18, 0.85) if _pressed else Color(1, 1, 1, 0.16)
	draw_circle(c, r, fill)
	draw_arc(c, r, 0.0, TAU, 48, Color(1, 1, 1, 0.40), 3.0)
	var glyph := Color(1, 1, 1, 0.85)
	var s := r * 0.35
	match action_name:
		&"jump": # up chevron
			draw_polyline(PackedVector2Array([
				c + Vector2(-s, s * 0.4), c + Vector2(0, -s * 0.5),
				c + Vector2(s, s * 0.4)]), glyph, 5.0, true)
		&"attack": # slash
			draw_line(c + Vector2(-s, s), c + Vector2(s, -s), glyph, 5.0, true)
		&"heal": # plus
			draw_line(c + Vector2(-s, 0), c + Vector2(s, 0), glyph, 5.0, true)
			draw_line(c + Vector2(0, -s), c + Vector2(0, s), glyph, 5.0, true)
		&"interact": # E glyph
			var font := ThemeDB.fallback_font
			var fs := 34
			var tw: float = font.get_string_size("E", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			draw_string(font, c + Vector2(-tw * 0.5, fs * 0.35), "E",
				HORIZONTAL_ALIGNMENT_LEFT, -1, fs, glyph)
		&"dash": # double chevron
			draw_polyline(PackedVector2Array([
				c + Vector2(-s * 0.9, -s), c + Vector2(-s * 0.1, 0),
				c + Vector2(-s * 0.9, s)]), glyph, 5.0, true)
			draw_polyline(PackedVector2Array([
				c + Vector2(-s * 0.1, -s), c + Vector2(s * 0.7, 0),
				c + Vector2(-s * 0.1, s)]), glyph, 5.0, true)
		&"pause": # two bars
			draw_line(c + Vector2(-s * 0.35, -s * 0.7), c + Vector2(-s * 0.35, s * 0.7), glyph, 6.0, true)
			draw_line(c + Vector2(s * 0.35, -s * 0.7), c + Vector2(s * 0.35, s * 0.7), glyph, 6.0, true)
