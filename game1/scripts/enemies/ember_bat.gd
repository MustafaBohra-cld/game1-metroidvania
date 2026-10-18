extends CharacterBody2D
## EmberBat — Z1 flyer. Hangs from its perch asleep (dimmed) until the player
## comes close, then wakes, swoops in a sine wave toward the player, and
## returns to its perch. 1 HP: fast but fragile.
##
## Expected scene nodes (parent wires the .tscn):
##   Health (EmberHealth, max_health = 1), Hurtbox (EmberHurtbox),
##   ContactHitbox (EmberHitbox), Visual (Node2D with WingL / WingR children).

class_name EmberBat

signal woke
signal swoop_started(direction: Vector2)

const WAKE_RANGE := 300.0
const WAKE_TIME := 0.4
const SWOOP_SPEED := 350.0
const SWOOP_TIME := 1.0
const SINE_AMP := 130.0
const SINE_FREQ := 10.0
const RETURN_SPEED := 260.0
const PERCH_SNAP := 24.0

const TINT_SLEEP := Color(0.5, 0.5, 0.55, 0.75)
const TINT_AWAKE := Color(1.0, 1.0, 1.0)

enum S { SLEEP, WAKE, SWOOP, RETURN }

var _state: int = S.SLEEP
var _t: float = 0.0
var _phase: float = 0.0
var _flap: float = 0.0
var _anchor: Vector2 = Vector2.ZERO
var _swoop_dir: Vector2 = Vector2.RIGHT

@onready var _health: EmberHealth = $Health
@onready var _visual: Node2D = $Visual
@onready var _wing_l: Node2D = $Visual/WingL
@onready var _wing_r: Node2D = $Visual/WingR


func _ready() -> void:
	add_to_group("enemies")
	_anchor = global_position
	_visual.modulate = TINT_SLEEP
	var hurtbox := $Hurtbox as EmberHurtbox
	hurtbox.health = _health
	hurtbox.team = 1
	var contact := $ContactHitbox as EmberHitbox
	contact.team = 1
	contact.damage = 1
	contact.knockback = Vector2(260.0, -220.0)
	contact.activate()
	_health.died.connect(_die)


func _physics_process(delta: float) -> void:
	_t -= delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	match _state:
		S.SLEEP:
			velocity = Vector2.ZERO
			if player != null and global_position.distance_to(player.global_position) < WAKE_RANGE:
				_state = S.WAKE
				_t = WAKE_TIME
				_visual.modulate = TINT_AWAKE
				woke.emit()
		S.WAKE:
			velocity = Vector2(randf_range(-30.0, 30.0), randf_range(-20.0, 20.0))
			if _t <= 0.0:
				if player != null:
					_swoop_dir = (player.global_position - global_position).normalized()
					_phase = 0.0
					_state = S.SWOOP
					_t = SWOOP_TIME
					swoop_started.emit(_swoop_dir)
				else:
					_state = S.SLEEP
					_visual.modulate = TINT_SLEEP
		S.SWOOP:
			_phase += delta * SINE_FREQ
			var perp := Vector2(-_swoop_dir.y, _swoop_dir.x)
			velocity = _swoop_dir * SWOOP_SPEED + perp * sin(_phase) * SINE_AMP
			if _t <= 0.0:
				_state = S.RETURN
		S.RETURN:
			var home := _anchor - global_position
			if home.length() < PERCH_SNAP:
				_state = S.SLEEP
				velocity = Vector2.ZERO
				_visual.modulate = TINT_SLEEP
			else:
				velocity = home.normalized() * RETURN_SPEED
	move_and_slide()
	if _state == S.SWOOP and is_on_wall():
		_state = S.RETURN
	# Wing flap: folded while asleep, flapping when awake.
	if _state == S.SLEEP:
		_wing_l.rotation = 0.3
		_wing_r.rotation = -0.3
	else:
		_flap += delta * 18.0
		_wing_l.rotation = sin(_flap) * 0.6
		_wing_r.rotation = -sin(_flap) * 0.6


func _die() -> void:
	get_node("/root/AudioManager").play_sfx("enemy_die")
	DeathBurst.explode(get_tree(), global_position)
	var gs := get_node("/root/GameState")
	gs.add_currency(int(round(float(randi_range(1, 2)) * float(gs.get_stat("currency_gain")))))
	queue_free()
