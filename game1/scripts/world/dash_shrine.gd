extends Area2D
## DashShrine — World module (Zone 1). Interact to unlock the Ember Dash ability.

var _used := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		set_meta("player_near", true)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		set_meta("player_near", false)


func _process(_delta: float) -> void:
	if _used or not get_meta("player_near", false):
		return
	if get_node("/root/GameInput").consume_interact_buffer():
		_used = true
		get_node("/root/GameState").unlock_ability("dash")
		get_node("/root/SaveSystem").save_game()
		var hud := get_tree().get_first_node_in_group("hud")
		if hud != null and hud.has_method("show_toast"):
			hud.show_toast("Ember Dash acquired! Press dash button mid-air.")
		$Visual.modulate = Color(0.6, 0.6, 0.6)
