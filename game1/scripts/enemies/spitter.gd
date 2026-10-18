extends CharacterBody2D
## Spitter — Z1 wall turret. A stationary fleshy pod: closed (invulnerable)
## until the player is in range, then it opens, spits one arcing glob, and
## closes again. Retreats (closes) if the player gets too close. 2 HP.
##
## Expected scene nodes (parent wires the .tscn):
##   Health (EmberHealth, max_health = 2), Hurtbox (EmberHurtbox), Visual (Node2D).

class_name Spitter

signal opened
signal spat
signal closed

const AGGRO_RANGE := 600.0
const RETREAT_RANGE := 150.0
const OPEN_TIME := 0.5
const CLOSE_TIME := 0.3
const IDLE_COOLDOWN := 2.0
const GLOB_SPEED := 380.0
const GLOB_ARC := 150.0

const TINT_CLOSED := Color(0.45, 0.42, 0.48)
const TINT_OPEN := Color(1.0, 1.0, 1.0)

enum S { IDLE, OPEN, SPIT, CLOSE }

var _state: int = S.IDLE
var _t: float = 0.0

@onready var _health: EmberHealth = $Health
@onready var _hurtbox: EmberHurtbox = $Hurtbox
@onready var _visual: Node2D = $Visual


class SpitGlob extends EmberHitbox:
	"""Arcing projectile. EmberHitbox (hits the player) + EmberHurtbox with
	1 HP (the player can slash / pogo it). Dies on terrain contact."""
	var vel: Vector2 = Vector2.ZERO
	var _life: float = 3.0

	func _ready() -> void:
		super._ready()
		team = 1
		damage = 1
		knockback = Vector2(200.0, -300.0)
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(18, 18)
		shape.shape = rect
		add_child(shape)
		var hp := EmberHealth.new()
		hp.max_health = 1
		add_child(hp)
		var hurt := EmberHurtbox.new()
		hurt.team = 1
		hurt.health = hp
		var hs := CollisionShape2D.new()
		var hrect := RectangleShape2D.new()
		hrect.size = Vector2(20, 20)
		hs.shape = hrect
		hurt.add_child(hs)
		add_child(hurt)
		hp.died.connect(queue_free)
		hit_landed.connect(_on_hit_landed)
		body_entered.connect(_on_body_entered)
		activate()

	func _physics_process(delta: float) -> void:
		_life -= delta
		if _life <= 0.0:
			queue_free()
			return
		vel.y += 950.0 * delta
		position += vel * delta

	func _on_hit_landed(_target: EmberHurtbox) -> void:
		queue_free()

	func _on_body_entered(body: Node2D) -> void:
		if body is StaticBody2D:
			queue_free()


func _ready() -> void:
	add_to_group("enemies")
	_hurtbox.health = _health
	_hurtbox.team = 1
	_hurtbox.set_deferred("monitorable", false) # closed = invulnerable
	_visual.modulate = TINT_CLOSED
	_health.died.connect(_die)


func _physics_process(delta: float) -> void:
	_t -= delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var dist: float = 1000000.0
	if player != null:
		dist = global_position.distance_to(player.global_position)
	match _state:
		S.IDLE:
			if player != null and dist < AGGRO_RANGE and dist > RETREAT_RANGE:
				_open()
		S.OPEN:
			if player != null and dist < RETREAT_RANGE:
				_close()
			elif _t <= 0.0:
				_spit(player)
		S.SPIT:
			_close()
		S.CLOSE:
			if _t <= 0.0:
				_state = S.IDLE
				_t = IDLE_COOLDOWN
	velocity = Vector2.ZERO
	move_and_slide()


func _open() -> void:
	_state = S.OPEN
	_t = OPEN_TIME
	_hurtbox.set_deferred("monitorable", true)
	_visual.modulate = TINT_OPEN
	_visual.scale = Vector2(1.15, 1.15)
	opened.emit()


func _close() -> void:
	_state = S.CLOSE
	_t = CLOSE_TIME
	_hurtbox.set_deferred("monitorable", false)
	_visual.modulate = TINT_CLOSED
	_visual.scale = Vector2.ONE
	closed.emit()


func _spit(player: Node2D) -> void:
	_state = S.SPIT
	if player != null:
		var glob := SpitGlob.new()
		get_parent().add_child(glob)
		glob.global_position = global_position + Vector2(0.0, -8.0)
		var dir := (player.global_position - glob.global_position).normalized()
		glob.vel = dir * GLOB_SPEED + Vector2(0.0, -GLOB_ARC)
	spat.emit()


func _die() -> void:
	get_node("/root/AudioManager").play_sfx("enemy_die")
	DeathBurst.explode(get_tree(), global_position)
	var gs := get_node("/root/GameState")
	gs.add_currency(int(round(float(randi_range(2, 3)) * float(gs.get_stat("currency_gain")))))
	queue_free()
