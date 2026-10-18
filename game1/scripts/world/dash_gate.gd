extends Area2D
## DashGate — World module. A cracked seal that only breaks when the player
## dashes through it. Guards the Deep Pockets alcove.

@export var wall_path: NodePath

var _broken := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _broken or not body.is_in_group("player"):
		return
	if body.has_method("is_dashing") and body.is_dashing():
		_broken = true
		var wall := get_node(wall_path)
		if wall != null:
			wall.queue_free()
		var hud := get_tree().get_first_node_in_group("hud")
		if hud != null and hud.has_method("show_toast"):
			hud.show_toast("Seal broken!")
		set_deferred("monitoring", false)
