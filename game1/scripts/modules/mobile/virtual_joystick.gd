extends Control
## VirtualJoystick — floating touch joystick (Mobile module).
## Appears where the thumb lands in the left 45% of the screen.
## Feeds GameInput.set_touch_move(). Spec: base 220px, knob 96px, deadzone 0.15.

class_name EmberJoystick

const BASE_RADIUS := 110.0
const KNOB_RADIUS := 48.0
const DEADZONE := 0.15
const ACTIVE_AREA := 0.45 # fraction of screen width

var _touch_id: int = -1
var _origin: Vector2 = Vector2.ZERO
var _knob: Vector2 = Vector2.ZERO

var _gi: Node


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gi = get_node("/root/GameInput")


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var w: float = get_viewport_rect().size.x
		if event.pressed and _touch_id == -1 and event.position.x < w * ACTIVE_AREA:
			_touch_id = event.index
			_origin = event.position
			_knob = event.position
			_update_output(event.position)
		elif not event.pressed and event.index == _touch_id:
			_release()
	elif event is InputEventScreenDrag:
		if event.index == _touch_id:
			_update_output(event.position)


func _update_output(pos: Vector2) -> void:
	var d: Vector2 = pos - _origin
	if d.length() > BASE_RADIUS:
		d = d.normalized() * BASE_RADIUS
	_knob = _origin + d
	var v: Vector2 = d / BASE_RADIUS
	_gi.set_touch_move(v if v.length() > DEADZONE else Vector2.ZERO)
	queue_redraw()


func _release() -> void:
	_touch_id = -1
	_gi.set_touch_move(Vector2.ZERO)
	queue_redraw()


func _draw() -> void:
	if _touch_id == -1:
		return
	draw_circle(_origin, BASE_RADIUS, Color(1, 1, 1, 0.10))
	draw_arc(_origin, BASE_RADIUS, 0.0, TAU, 48, Color(1, 1, 1, 0.25), 3.0)
	draw_circle(_knob, KNOB_RADIUS, Color(1, 1, 1, 0.28))
