extends Area2D
## RelicPickup — World module. Walk over to collect; auto-equips if a socket
## is free. Toast confirms.

@export var relic_id := "longstride"


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Tint the diamond per relic (M3: two relics, two colors).
	$Diamond.color = Color(1.0, 0.48, 0.18) if relic_id == "longstride" \
		else Color(1.0, 0.84, 0.4)


func _process(_delta: float) -> void:
	$Diamond.rotation += 0.02


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	var gs := get_node("/root/GameState")
	gs.give_relic(relic_id)
	var code: int = gs.equip_relic(relic_id)
	get_node("/root/SaveSystem").save_game()
	var hud := get_tree().get_first_node_in_group("hud")
	var msg := "Relic: %s (%s)" % [gs.relic_name(relic_id), gs.relic_desc(relic_id)]
	if code == 1:
		msg += " — no free socket"
	if hud and hud.has_method("show_toast"):
		hud.show_toast(msg)
	else:
		print(msg)
	queue_free()
