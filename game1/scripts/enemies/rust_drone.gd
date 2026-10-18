extends CharacterBody2D
## RustDrone — Foundry flyer. Hovers around its anchor; dives at the player
## when close, then climbs back. 3 HP, contact damage 1.

const HOVER_SPEED := 60.0
const DIVE_SPEED := 420.0
const AGGRO_RANGE := 420.0
const DIVE_CD := 2.2

enum S { HOVER, WINDUP, DIVE, RECOVER }

var _state: int = S.HOVER
var _t := 0.0
var _phase := 0.0
var _anchor := Vector2.ZERO
var _dive_dir := Vector2.ZERO

@onready var _health: EmberHealth = $Health
@onready var _visual: Node2D = $Visual


func _ready() -> void:
	add_to_group("enemies")
	_anchor = global_position
	_phase = randf() * TAU
	var hurtbox := $Hurtbox as EmberHurtbox
	hurtbox.health = _health
	hurtbox.team = 1
	var contact := $ContactHitbox as EmberHitbox
	contact.team = 1
	contact.damage = 1
	contact.knockback = Vector2(300.0, -200.0)
	contact.activate()
	_health.died.connect(_die)


func _physics_process(delta: float) -> void:
	_t -= delta
	_phase += delta * 3.0
	var player := get_tree().get_first_node_in_group("player")
	match _state:
		S.HOVER:
			var target := _anchor + Vector2(cos(_phase) * 60.0, sin(_phase * 1.3) * 40.0)
			velocity = (target - global_position) * 4.0
			if player != null and global_position.distance_to(player.global_position) < AGGRO_RANGE:
				_state = S.WINDUP
				_t = 0.5
		S.WINDUP:
			velocity = velocity.move_toward(Vector2.ZERO, 800.0 * delta)
			_visual.scale = Vector2(1.0, 0.7) # crouch before the dive
			if _t <= 0.0 and player != null:
				_visual.scale = Vector2.ONE
				_dive_dir = (player.global_position - global_position).normalized()
				_state = S.DIVE
				_t = 0.6
		S.DIVE:
			velocity = _dive_dir * DIVE_SPEED
			if _t <= 0.0:
				_state = S.RECOVER
				_t = DIVE_CD
		S.RECOVER:
			var home := _anchor - global_position
			velocity = home * 2.0
			if _t <= 0.0:
				_state = S.HOVER
	# Gentle hover bob (sprite replaces old wing nodes).
	$Visual/Sprite.position.y = sin(_phase * 6.0) * 3.0
	move_and_slide()


func _die() -> void:
	get_node("/root/AudioManager").play_sfx("enemy_die")
	var gs := get_node("/root/GameState")
	gs.add_currency(randi_range(2, 4))
	queue_free()
