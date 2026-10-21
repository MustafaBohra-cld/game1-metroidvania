extends Node2D
## Soft warm light that follows the player — the Hollow Knight-style
## "light focuses on the character" effect. Added to rooms by
## parallax_zone.gd; draws as a faint halo just in front of the world.

@export var tint: Color = Color(1.0, 0.45, 0.15)

var _target: Node2D


func _ready() -> void:
	z_index = 5  # In front of world art, behind all CanvasLayer UI
	var spr := Sprite2D.new()
	spr.texture = load("res://assets/backgrounds/fx-glow-radial.png") as Texture2D
	spr.scale = Vector2(3.4, 3.4)  # 256px texture → ~870px soft halo
	spr.modulate = Color(tint, 0.55)
	add_child(spr)


func _process(_delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group("player") as Node2D
	if _target != null:
		global_position = _target.global_position + Vector2(0, -8)
