extends Node
## EmberHealth — Combat module. Damage, i-frames, death. Attach to any actor.
## Damage flows: EmberHitbox -> EmberHurtbox -> EmberHealth.

class_name EmberHealth

signal damaged(amount: int)
signal healed(amount: int)
signal died

const IFRAME_TIME := 0.5

@export var max_health := 5

var health: int
var _iframes := 0.0


func _ready() -> void:
	health = max_health


func _process(delta: float) -> void:
	_iframes = maxf(0.0, _iframes - delta)


func take_damage(amount: int, _from: Vector2) -> bool:
	"""Returns true if the damage was applied (not in i-frames, not dead)."""
	if _iframes > 0.0 or health <= 0:
		return false
	health = maxi(0, health - amount)
	_iframes = IFRAME_TIME
	damaged.emit(amount)
	if health == 0:
		died.emit()
	return true


func heal(amount: int) -> void:
	if health <= 0:
		return
	health = mini(max_health, health + amount)
	healed.emit(amount)


func grant_iframes(duration: float) -> void:
	"""Temporary invulnerability (dash, etc.)."""
	_iframes = maxf(_iframes, duration)


func is_alive() -> bool:
	return health > 0
