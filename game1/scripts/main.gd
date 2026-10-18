extends Node2D
## Game entry point. M3: checkpoint loop.
## Loads save if present, spawns player at last hearth, spawns echo shade.

const EchoShadeScene := preload("res://scenes/echo_shade.tscn")


func _ready() -> void:
	print("Project Ember M4 — boss + dash. Godot %s"
		% Engine.get_version_info().get("string", "unknown"))
	var gs := get_node("/root/GameState")
	var ss := get_node("/root/SaveSystem")
	if ss.has_save():
		ss.load_game()
	$Player.position = gs.get_hearth_pos()
	# Boss stays dead across reloads.
	if gs.get_flag("maw_dead", false):
		$CinderMaw.queue_free()
	if gs.echo_amount > 0:
		var shade := EchoShadeScene.instantiate()
		shade.position = gs.echo_pos
		add_child(shade)
