extends CharacterBody2D
## EchoShade — the player's dropped cinders, given hostile form.
## Stationary guardian. Kill it to reclaim the echo.

var _t := 0.0

@onready var _health: EmberHealth = $Health


func _ready() -> void:
	var hurtbox := $Hurtbox as EmberHurtbox
	hurtbox.health = _health
	hurtbox.team = 1
	var contact := $ContactHitbox as EmberHitbox
	contact.team = 1
	contact.damage = 1
	contact.knockback = Vector2(260.0, -200.0)
	contact.resource_gain = 0
	contact.activate()
	_health.died.connect(_on_reclaimed)


func _physics_process(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	_t += delta
	$Visual.position.y = -20.0 + sin(_t * 3.0) * 6.0


func _on_reclaimed() -> void:
	var gs := get_node("/root/GameState")
	gs.add_currency(gs.echo_amount)
	gs.clear_echo()
	get_node("/root/SaveSystem").save_game()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_toast"):
		hud.show_toast("Echo reclaimed: +%d cinders" % gs.currency)
	queue_free()
