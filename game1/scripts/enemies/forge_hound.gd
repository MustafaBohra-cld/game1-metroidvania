extends CharacterBody2D
## ForgeHound — Foundry charger (M5b). Paces back and forth; when the player
## is in range it telegraphs (0.6s paw-scrape flash), charges at 900px/s,
## and stuns for 1.2s on wall impact (takes double damage while stunned).
## 5 HP, 2 contact damage.
##
## Expected scene nodes (parent wires the .tscn):
##   Health (EmberHealth), Hurtbox (EmberHurtbox), ContactHitbox (EmberHitbox),
##   Visual (Node2D).

class_name ForgeHound

## Emitted when the charge begins. [param direction] is -1 or 1.
signal charge_started(direction: int)
## Emitted when the hound stuns itself on a wall.
signal stunned_started

const PACE_SPEED := 80.0
const CHARGE_SPEED := 900.0
const GRAVITY := 1350.0
const TELEGRAPH_TIME := 0.6
const STUN_TIME := 1.2
const CHARGE_MAX_TIME := 1.5
const AGGRO_RANGE := 480.0

enum S { PACE, TELEGRAPH, CHARGE, STUNNED }

var _state: int = S.PACE
var _t := 0.0
var _dir := -1
var _flash := 0.0
var _scrape_phase := 0.0
var _applying_bonus := false

@onready var _health: EmberHealth = $Health
@onready var _visual: Node2D = $Visual


func _ready() -> void:
	add_to_group("enemies")
	var hurtbox := $Hurtbox as EmberHurtbox
	hurtbox.health = _health
	hurtbox.team = 1
	var contact := $ContactHitbox as EmberHitbox
	contact.team = 1
	contact.damage = 2
	contact.knockback = Vector2(420.0, -260.0)
	contact.activate()
	_health.damaged.connect(_on_damaged)
	_health.died.connect(_die)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0
	var player := get_tree().get_first_node_in_group("player") as Node2D
	match _state:
		S.PACE:
			velocity.x = float(_dir) * PACE_SPEED
			move_and_slide()
			if is_on_wall():
				_dir *= -1
			if player != null and _player_in_range(player):
				_state = S.TELEGRAPH
				_t = TELEGRAPH_TIME
				_scrape_phase = 0.0
		S.TELEGRAPH:
			velocity.x = 0.0
			move_and_slide()
			_scrape_phase += delta * 30.0
			# Paw-scrape shake; face the player.
			if player != null:
				_dir = 1 if player.global_position.x > global_position.x else -1
			_visual.position.x = sin(_scrape_phase) * 4.0
			if _t <= 0.0:
				_visual.position.x = 0.0
				_state = S.CHARGE
				_t = CHARGE_MAX_TIME
				charge_started.emit(_dir)
		S.CHARGE:
			velocity.x = float(_dir) * CHARGE_SPEED
			move_and_slide()
			if is_on_wall():
				_enter_stun()
			elif _t <= 0.0:
				_state = S.PACE
		S.STUNNED:
			velocity.x = 0.0
			move_and_slide()
			if _t <= 0.0:
				_state = S.PACE
	_t -= delta
	_visual.scale.x = float(_dir)


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash -= delta
		modulate = Color(1, 0.4, 0.4) if _flash > 0.0 else Color.WHITE
	if _state == S.TELEGRAPH:
		# Redden while telegraphing.
		modulate = Color(1.0, 0.5 + 0.3 * sin(_scrape_phase), 0.5)
	elif _state == S.STUNNED:
		# Dizzy flicker while stunned.
		_visual.rotation = sin(Time.get_ticks_msec() * 0.02) * 0.15
	else:
		_visual.rotation = 0.0


func _player_in_range(player: Node2D) -> bool:
	var to_player: Vector2 = player.global_position - global_position
	return absf(to_player.x) < AGGRO_RANGE and absf(to_player.y) < 140.0


func _enter_stun() -> void:
	_state = S.STUNNED
	_t = STUN_TIME
	velocity.x = 0.0
	stunned_started.emit()


func _on_damaged(amount: int) -> void:
	_flash = 0.12
	# Stunned = double damage. Guard against recursion and i-frames by
	# applying the bonus directly; the damaged handler runs before died.
	if _state == S.STUNNED and not _applying_bonus and _health.is_alive():
		_applying_bonus = true
		_health.health = maxi(0, _health.health - amount)
		_health.damaged.emit(amount)
		if _health.health == 0:
			_health.died.emit()
		_applying_bonus = false


func _die() -> void:
	get_node("/root/AudioManager").play_sfx("enemy_die")
	var gs := get_node("/root/GameState")
	var roll := 4 + randi() % 4 # 4-7 cinders
	gs.add_currency(int(round(float(roll) * float(gs.get_stat("currency_gain")))))
	queue_free()
