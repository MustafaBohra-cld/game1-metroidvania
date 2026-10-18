class_name SlashTrail
extends Node2D
## SlashTrail — FX module. Fading crescent swoosh on player slash.
## Child of the player (NOT of the scaled Visual). Call trigger_slash(aim_dir).
## Draws an orange arc that expands and fades over ~0.18s.

const FADE_TIME := 0.18
const ARC_RADIUS := 52.0
const ARC_WIDTH := 16.0
const ARC_HALF_ANGLE := 1.15

var _poly: Polygon2D
var _t := 1.0


func _ready() -> void:
	_poly = Polygon2D.new()
	_poly.color = Color(1.0, 0.72, 0.28, 0.85)
	_poly.polygon = _build_crescent()
	_poly.visible = false
	add_child(_poly)


func _build_crescent() -> PackedVector2Array:
	var pts := PackedVector2Array()
	var steps := 14
	for i in range(steps + 1):
		var a := lerpf(-ARC_HALF_ANGLE, ARC_HALF_ANGLE, float(i) / float(steps))
		pts.append(Vector2(cos(a), sin(a)) * ARC_RADIUS)
	for i in range(steps, -1, -1):
		var a := lerpf(-ARC_HALF_ANGLE, ARC_HALF_ANGLE, float(i) / float(steps))
		pts.append(Vector2(cos(a), sin(a)) * (ARC_RADIUS - ARC_WIDTH))
	return pts


func trigger_slash(direction: Vector2) -> void:
	if direction.length() < 0.01:
		direction = Vector2.RIGHT
	rotation = direction.angle()
	_t = 0.0
	_poly.visible = true


func _process(delta: float) -> void:
	if _t >= 1.0:
		_poly.visible = false
		return
	_t = minf(1.0, _t + delta / FADE_TIME)
	var c := _poly.color
	c.a = 0.85 * (1.0 - _t)
	_poly.color = c
	var s := 0.75 + _t * 0.55
	_poly.scale = Vector2(s, s)
