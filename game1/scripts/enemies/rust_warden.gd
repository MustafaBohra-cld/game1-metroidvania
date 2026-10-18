extends CharacterBody2D
## RustWarden — Foundry mini-boss with proper state machine.
## States lock animations: attack cannot be overwritten by walk.

class_name RustWarden

signal warden_defeated
signal slam_started

const GRAVITY := 1350.0
const WALK_SPEED := 100.0
const WAKE_RANGE := 320.0

# State machine
enum S { SLEEP, WAKE, WALK, WINDUP, SLAM, RECOVER, HIT, DEFEATED }

var _state: int = S.SLEEP
var _state_t := 0.0  # Time in current state
var _attack_cd := 2.0
var _dir := 1
var boss_active := false  # Boss bar hidden until awake
var boss_name := "Rust Warden"

# Timing constants
const WAKE_DUR := 2.0
const WINDUP_DUR := 0.6
const SLAM_DUR := 0.3
const RECOVER_DUR := 0.8
const HIT_DUR := 0.35

@onready var _health: EmberHealth = $Health
@onready var _visual: Node2D = $Visual
@onready var _sprite: Sprite2D = $Visual/Sprite

# All poses (16)
const TEX_SLEEP1 := preload("res://assets/sprites/enemies/warden-sleep1.png")
const TEX_SLEEP2 := preload("res://assets/sprites/enemies/warden-sleep2.png")
const TEX_STIR := preload("res://assets/sprites/enemies/warden-stir.png")
const TEX_HALFWAKE := preload("res://assets/sprites/enemies/warden-halfwake.png")
const TEX_WAKE1 := preload("res://assets/sprites/enemies/warden-wake1.png")
const TEX_PUSHUP := preload("res://assets/sprites/enemies/warden-pushup.png")
const TEX_STAND1 := preload("res://assets/sprites/enemies/warden-stand1.png")
const TEX_STAND2 := preload("res://assets/sprites/enemies/warden-stand2.png")
const TEX_IDLE := preload("res://assets/sprites/enemies/warden-idle.png")
const TEX_WALK1 := preload("res://assets/sprites/enemies/warden-walk1.png")
const TEX_WALK2 := preload("res://assets/sprites/enemies/warden-walk2.png")
const TEX_WALK3 := preload("res://assets/sprites/enemies/warden-walk3.png")
const TEX_HIT := preload("res://assets/sprites/enemies/warden-hit.png")
const TEX_WINDUP := preload("res://assets/sprites/enemies/warden-windup.png")
const TEX_SLAM := preload("res://assets/sprites/enemies/warden-slam.png")
const TEX_DEFEATED := preload("res://assets/sprites/enemies/warden-defeated.png")


func _set_pose(tex: Texture2D) -> void:
	if is_instance_valid(_sprite):
		_sprite.texture = tex


func get_health() -> float:
	return _health.health


func get_max_health() -> float:
	return _health.max_health


func _change_state(new_state: int) -> void:
	_state = new_state
	_state_t = 0.0


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("miniboss")
	add_to_group("boss")
	var gs := get_node_or_null("/root/GameState")
	if gs != null and gs.get_flag("warden_defeated", false):
		queue_free()
		return
	if gs != null and gs.get_flag("warden_awakened", false):
		_change_state(S.WALK)
		boss_active = true
		_set_pose(TEX_IDLE)
		_sprite.modulate = Color.WHITE
	else:
		_change_state(S.SLEEP)
		boss_active = false
		_set_pose(TEX_SLEEP1)
		_sprite.modulate = Color(0.65, 0.65, 0.75)
	var hurtbox := $Hurtbox as EmberHurtbox
	hurtbox.health = _health
	hurtbox.team = 1
	var contact := $ContactHitbox as EmberHitbox
	contact.team = 1
	contact.damage = 1
	contact.activate()
	_health.died.connect(_die)
	_health.damaged.connect(_on_damaged)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0

	_state_t += delta
	var player := get_tree().get_first_node_in_group("player") as Node2D

	match _state:
		S.SLEEP:
			# Slow breathing: alternate sleep poses gently
			var phase: int = int(_state_t / 1.2) % 2
			_set_pose(TEX_SLEEP1 if phase == 0 else TEX_SLEEP2)
			var breathe: float = sin(_state_t * 2.0) * 0.02
			_visual.scale = Vector2(1.0 + breathe, 1.0 - breathe)
			_visual.rotation = 0.06
			velocity.x = 0.0
			if player != null and global_position.distance_to(player.global_position) < WAKE_RANGE:
				_change_state(S.WAKE)
				_visual.rotation = 0.0
				_visual.scale = Vector2.ONE
				var gs := get_node_or_null("/root/GameState")
				if gs != null:
					gs.set_flag("warden_awakened", true)
				get_node("/root/AudioManager").play_sfx("boss_roar")
				var hud := get_tree().get_first_node_in_group("hud")
				if hud and hud.has_method("show_toast"):
					hud.show_toast("Rust Warden awakens!")

		S.WAKE:
			# Clean rise: stir -> halfwake -> wake1 -> pushup -> stand1 -> stand2
			var poses := [TEX_STIR, TEX_HALFWAKE, TEX_WAKE1, TEX_PUSHUP, TEX_STAND1, TEX_STAND2]
			var idx: int = mini(int((_state_t / WAKE_DUR) * 6.0), 5)
			_set_pose(poses[idx])
			# Brighten gradually, shake early, rise late
			var prog: float = _state_t / WAKE_DUR
			if prog < 0.5:
				_sprite.position.x = randf_range(-4.0, 4.0)
			else:
				_sprite.position.x = 0.0
				_visual.position.y = -25.0 * ((prog - 0.5) * 2.0)
			var b: float = 0.65 + 0.35 * prog
			_sprite.modulate = Color(b, b, b + 0.05)
			velocity.x = 0.0
			if _state_t >= WAKE_DUR:
				# Impact: hold roar pose, shake screen
				_sprite.position.x = 0.0
				_visual.position.y = 0.0
				_sprite.modulate = Color.WHITE
				_set_pose(TEX_STAND2)
				boss_active = true
				var pl := get_tree().get_first_node_in_group("player")
				if pl and pl.has_method("add_trauma"):
					pl.add_trauma(0.5)
				_change_state(S.WALK)
				_attack_cd = 1.5  # First attack soon

		S.WALK:
			if player != null:
				_dir = 1 if player.global_position.x > global_position.x else -1
				velocity.x = float(_dir) * WALK_SPEED
				_sprite.flip_h = _dir < 0
				# Walk cycle
				var wp := [TEX_WALK1, TEX_WALK2, TEX_WALK3]
				_set_pose(wp[int(_state_t * 4.0) % 3])
				_sprite.position.y = -48.0 + sin(_state_t * 10.0) * 3.0
				# Attack when close or timer expires
				_attack_cd -= delta
				var dist: float = absf(player.global_position.x - global_position.x)
				if dist < 150.0 or _attack_cd <= 0.0:
					_change_state(S.WINDUP)
					velocity.x = 0.0
					slam_started.emit()
			else:
				velocity.x = 0.0
				_set_pose(TEX_IDLE)

		S.WINDUP:
			# Telegraph: crouch, hammer back, glow
			_set_pose(TEX_WINDUP)
			velocity.x = 0.0
			_visual.scale = Vector2(1.0 - _state_t * 0.2, 1.0 + _state_t * 0.2)
			if _state_t >= WINDUP_DUR:
				_visual.scale = Vector2.ONE
				_change_state(S.SLAM)
				# Activate hitbox
				var hb := $SlamHitbox as EmberHitbox
				hb.team = 1
				hb.damage = 2
				if player != null:
					hb.global_position = player.global_position
				hb.activate()

		S.SLAM:
			# Active hit frame
			_set_pose(TEX_SLAM)
			velocity.x = 0.0
			_visual.scale = Vector2(1.15, 0.85)  # Squash on impact
			if _state_t >= SLAM_DUR:
				_visual.scale = Vector2.ONE
				var hb2 := $SlamHitbox as EmberHitbox
				hb2.deactivate()
				_change_state(S.RECOVER)

		S.RECOVER:
			# Vulnerable pause
			_set_pose(TEX_IDLE)
			velocity.x = 0.0
			if _state_t >= RECOVER_DUR:
				_attack_cd = 2.0
				_change_state(S.WALK)

		S.HIT:
			# Hit flash on current sprite (no separate sprite to avoid size pop)
			# We keep TEX_HIT but it's same canvas size so no pop
			_set_pose(TEX_HIT)
			velocity.x = 0.0
			if _state_t >= HIT_DUR:
				_sprite.modulate = Color.WHITE
				_change_state(S.WALK)

		S.DEFEATED:
			# Stay in defeated pose, fade out handled by tween in _die
			_set_pose(TEX_DEFEATED)
			velocity.x = 0.0

	move_and_slide()


func _on_damaged(amount: int) -> void:
	# Only interrupt walk/idle, not attack states
	if _state == S.WALK:
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player != null:
			var from_dir: int = 1 if global_position.x > player.global_position.x else -1
			velocity.x = float(from_dir) * 100.0
		_sprite.modulate = Color(1.6, 0.7, 0.7)
		_change_state(S.HIT)


func _die() -> void:
	_change_state(S.DEFEATED)
	var gs := get_node_or_null("/root/GameState")
	if gs != null:
		gs.set_flag("warden_defeated", true)
	# Crumble tween
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_visual, "rotation", 0.9, 0.7)
	tween.tween_property(_visual, "scale", Vector2(0.85, 0.7), 0.7)
	tween.tween_property(_sprite, "modulate:a", 0.0, 0.9).set_delay(0.4)
	var pl := get_tree().get_first_node_in_group("player")
	if pl and pl.has_method("add_trauma"):
		pl.add_trauma(0.5)
	await tween.finished
	if gs != null:
		gs.give_relic("thornplate")
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_toast"):
		hud.show_toast("Relic: Thornplate (Reflect 1 contact damage)")
	warden_defeated.emit()
	queue_free()
