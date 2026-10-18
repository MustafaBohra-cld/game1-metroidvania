extends Area2D
## Hearth — World module rest point. Stand inside + press interact (E / E-button).
## Rest: saves, heals to full, respawns enemies, opens the rest panel.

@export var zone_id := "test"
@export var room_id := "main"

var _player_inside := false
var _gi: Node


func _ready() -> void:
	_gi = get_node("/root/GameInput")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = false


func _process(_delta: float) -> void:
	if _player_inside and _gi.consume_interact_buffer():
		var panel := get_tree().get_first_node_in_group("rest_panel")
		if panel and panel.has_method("open_rest"):
			panel.open_rest(self)


func rest() -> void:
	"""Full rest: set hearth, save, heal, respawn enemies via scene reload."""
	get_node("/root/AudioManager").play_sfx("hearth")
	var gs := get_node("/root/GameState")
	var player := get_tree().get_first_node_in_group("player")
	gs.set_hearth(zone_id, room_id, global_position + Vector2(0, -40))
	if player and player.has_method("full_heal"):
		player.full_heal()
	get_node("/root/SaveSystem").save_game()
	get_tree().paused = false
	get_tree().reload_current_scene()
