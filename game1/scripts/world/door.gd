extends Area2D
## Door — World module (M5). Walk in to travel to another room scene.

@export var target_scene := ""
@export var spawn_tag := "default"
@export var toast_text := ""

var _used := false
var _born_ms := 0


func _ready() -> void:
	_born_ms = Time.get_ticks_msec()
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _used or target_scene == "" or not body.is_in_group("player"):
		return
	# Spawn protection: ignore the player for 1.5s after the room loads,
	# so a fresh spawn can never instantly bounce back through a door.
	if Time.get_ticks_msec() - _born_ms < 1500:
		return
	_used = true
	if toast_text != "":
		var hud := get_tree().get_first_node_in_group("hud")
		if hud != null and hud.has_method("show_toast"):
			hud.show_toast(toast_text)
	# Deferred: body_entered fires inside a physics callback.
	call_deferred("_travel")


func _travel() -> void:
	get_node("/root/World").goto_room(target_scene, spawn_tag)
