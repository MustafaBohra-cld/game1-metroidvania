extends Node2D
## SlashVfx — draws the slash arc swipe during an attack (M4 juice).
## Child of Player; reads aim + swing phase from the player.


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var player := get_parent()
	if not player.has_method("get_attack_phase"):
		return
	var phase: float = player.get_attack_phase()
	if phase <= 0.0:
		return
	var aim: Vector2 = player.get_aim()
	var ang := aim.angle()
	var center := aim * 45.0 + Vector2(0, -28)
	draw_arc(center, 62.0, ang - 0.9, ang + 0.9, 24,
		Color(1.0, 0.62, 0.25, 0.55 * phase), 16.0, true)
	draw_arc(center, 62.0, ang - 0.9, ang + 0.9, 24,
		Color(1.0, 0.9, 0.7, 0.85 * phase), 5.0, true)
