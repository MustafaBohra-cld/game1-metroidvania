extends Area2D
## EmberHurtbox — Combat module. The "I can be hit here" area on an actor.
## Owner wires: hurtbox.health = $Health ; hurtbox.team = 0 (player) / 1 (enemy).

class_name EmberHurtbox

@export var team := 1

var health: EmberHealth
