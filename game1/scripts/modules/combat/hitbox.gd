extends Area2D
## EmberHitbox — Combat module. The "this attack hits" area.
## Only damages EmberHurtbox nodes on a different team, once per activation.

class_name EmberHitbox

signal hit_landed(target: EmberHurtbox)

@export var team := 0
@export var damage := 1
@export var knockback := Vector2(320.0, -160.0)
@export var resource_gain := 8

var active := false
var _hit_set := {}


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	monitoring = false


func activate() -> void:
	active = true
	_hit_set.clear()
	set_deferred("monitoring", true)


func deactivate() -> void:
	active = false
	set_deferred("monitoring", false)


func _on_area_entered(area: Area2D) -> void:
	if not active:
		return
	if not (area is EmberHurtbox):
		return
	var hb := area as EmberHurtbox
	if hb.team == team or _hit_set.has(hb):
		return
	if hb.health == null:
		return
	if hb.health.take_damage(damage, global_position):
		_hit_set[hb] = true
		_apply_knockback(hb)
		hit_landed.emit(hb)


func _apply_knockback(hb: EmberHurtbox) -> void:
	var body := hb.get_parent() as CharacterBody2D
	if body == null:
		return
	var dir := signf(body.global_position.x - global_position.x)
	if dir == 0.0:
		dir = 1.0
	body.velocity.x = dir * knockback.x
	body.velocity.y = knockback.y
