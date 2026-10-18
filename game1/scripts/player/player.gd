extends CharacterBody2D
## EmberPlayer — movement + M2 combat.
## Slash (4-way aim), pogo bounce, resource meter, heal channel.
## All numbers in docs/tuning.md.

class_name EmberPlayer

signal resource_changed(value: int)

# Movement (M1).
const MOVE_SPEED := 260.0
const ACCEL := 2000.0
const FRICTION := 2200.0
const JUMP_VELOCITY := -590.0
const GRAVITY := 1350.0
const MAX_FALL := 900.0
const COYOTE_TIME := 0.10
const JUMP_CUT := 0.45
# Combat (M2).
const ATTACK_TIME := 0.18
const ATTACK_CD := 0.38
const RESOURCE_MAX := 99
const RESOURCE_PER_HIT := 8
const HEAL_COST := 33
const HEAL_TIME := 0.8
const POGO_BOUNCE := 0.85
# Dash (M4).
const DASH_SPEED := 700.0
const DASH_TIME := 0.18
const DASH_CD := 1.0
# Cling (M5).
const CLING_SLIDE := 70.0
const WALLKICK_X := 420.0

var resource := 0

var _coyote := 0.0
var _facing := 1
var _attack_timer := 0.0
var _attack_cd := 0.0
var _aim := Vector2.RIGHT
var _healing := false
var _heal_timer := 0.0
var _dash_timer := 0.0
var _dash_cd := 0.0
var _dash_dir := 1
var _squash := 0.0
var _was_on_floor := true
var _clinging := false
var _shake: ScreenShake
var _am: Node
var _trail: SlashTrail

@onready var _gi: Node = get_node("/root/GameInput")
@onready var _gs: Node = get_node("/root/GameState")
@onready var _visual: AnimatedSprite2D = $Visual
@onready var _health: EmberHealth = $Health
@onready var _hitbox: EmberHitbox = $AttackHitbox


func _ready() -> void:
	add_to_group("player")
	_am = get_node("/root/AudioManager")
	var hurtbox := $Hurtbox as EmberHurtbox
	hurtbox.health = _health
	hurtbox.team = 0
	_hitbox.team = 0
	_hitbox.hit_landed.connect(_on_hit_landed)
	_health.died.connect(_on_died)
	_health.damaged.connect(_on_hurt)
	# FX: trauma shake on the camera, slash swoosh trail.
	_shake = ScreenShake.new()
	_shake.name = "ScreenShake"
	$Camera.add_child(_shake)
	_trail = SlashTrail.new()
	add_child(_trail)


func _physics_process(delta: float) -> void:
	_attack_cd = maxf(0.0, _attack_cd - delta)
	_dash_cd = maxf(0.0, _dash_cd - delta)
	_squash = maxf(0.0, _squash - delta)

	if is_dashing():
		# Dash: committed horizontal burst, no gravity.
		_dash_timer -= delta
		velocity = Vector2(_dash_dir * DASH_SPEED, 0.0)
		if _dash_timer <= 0.0:
			velocity.x = _dash_dir * DASH_SPEED * 0.35
		move_and_slide()
		_apply_squash()
		_update_anim()
		return

	# Gravity + coyote.
	if is_on_floor():
		if not _was_on_floor:
			_squash = 0.18 # landing squash
		_coyote = COYOTE_TIME
	else:
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
		_coyote = maxf(0.0, _coyote - delta)
	_was_on_floor = is_on_floor()

	# Horizontal (relic-modified top speed).
	var axis: float = _gi.get_move_axis()
	var top_speed: float = MOVE_SPEED * _gs.get_stat("move_speed")
	if axis != 0.0:
		velocity.x = move_toward(velocity.x, axis * top_speed, ACCEL * delta)
		_facing = int(sign(axis))
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

	# Cling (wall grip, needs the Cling ability): hold toward a wall in the
	# air to slide down slowly; jump to wall-kick away.
	# Release grip if landed or left the wall.
	if _clinging and (is_on_floor() or not is_on_wall()):
		_clinging = false
	# Start grip: holding toward wall, or flying into it (auto-grip for zigzag).
	if not _clinging and _gs.has_ability("cling") and not is_on_floor() and is_on_wall():
		var n := get_wall_normal()
		var holding_toward := axis != 0.0 and signf(axis) == -signf(n.x)
		var flying_toward := absf(velocity.x) > 50.0 and signf(velocity.x) == -signf(n.x)
		if holding_toward or flying_toward:
			_clinging = true
	if _clinging:
		var cn := get_wall_normal()
		velocity.y = minf(velocity.y, CLING_SLIDE)
		velocity.x = 0.0
		_facing = int(-signf(cn.x))

	# Jump.
	if _gi.consume_jump_buffer() and (is_on_floor() or _coyote > 0.0 or _clinging):
		if _clinging:
			_am.play_sfx("wallkick")
			var wn := get_wall_normal()
			velocity = Vector2(wn.x * WALLKICK_X, JUMP_VELOCITY * 0.95)
			_facing = int(signf(wn.x))
			_clinging = false
		else:
			_am.play_sfx("jump")
			velocity.y = JUMP_VELOCITY
		_coyote = 0.0
		_healing = false
	if _gi.is_jump_just_released() and velocity.y < 0.0:
		velocity.y *= JUMP_CUT

	# Attack.
	if _attack_timer > 0.0:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_hitbox.deactivate()
	elif _gi.consume_attack_buffer() and _attack_cd <= 0.0:
		_start_attack()

	# Dash (needs the Ember Dash ability).
	if _gs.has_ability("dash") and _gi.consume_dash_buffer() and _dash_cd <= 0.0:
		_dash_dir = _facing
		_am.play_sfx("dash")
		_dash_timer = DASH_TIME
		_dash_cd = DASH_CD
		_health.grant_iframes(DASH_TIME + 0.15)
		_healing = false
		_squash = 0.0

	# Heal channel: hold heal while still, stocked, and hurt.
	if _gi.is_heal_held() and not _healing \
			and resource >= HEAL_COST \
			and _health.health < _health.max_health \
			and is_on_floor() and absf(velocity.x) < 30.0:
		_healing = true
		_heal_timer = 0.0
	if _healing:
		if not _gi.is_heal_held() or not is_on_floor() or absf(velocity.x) > 60.0:
			_healing = false
		else:
			_heal_timer += delta
			if _heal_timer >= HEAL_TIME:
				_healing = false
				resource -= HEAL_COST
				_health.heal(1)
				resource_changed.emit(resource)

	move_and_slide()
	_apply_squash()
	_update_anim()


func _update_anim() -> void:
	"""Pick the sprite animation from the current state."""
	var s := "idle"
	if is_dashing():
		s = "dash"
	elif _attack_timer > 0.0:
		s = "slash"
	elif not is_on_floor():
		s = "jump" if velocity.y < 0.0 else "fall"
	elif absf(velocity.x) > 20.0:
		s = "run"
	_visual.set_state(s)


func _apply_squash() -> void:
	"""Squash & stretch juice on the visual (facing via flip_h)."""
	_visual.flip_h = _facing < 0
	var base := 0.15
	var sx := base
	var sy := base
	if _squash > 0.0:
		sx *= 1.0 + _squash * 2.0
		sy *= 1.0 - _squash * 1.5
	elif is_dashing():
		sx *= 1.25
		sy *= 0.8
	elif not is_on_floor() and velocity.y < -150.0:
		sx *= 0.92
		sy *= 1.1
	_visual.scale = Vector2(sx, sy)


func _start_attack() -> void:
	_am.play_sfx("slash")
	_aim = _compute_aim()
	_attack_cd = ATTACK_CD
	_attack_timer = ATTACK_TIME
	_healing = false
	# Place the hitbox at the aim offset.
	if _aim == Vector2.UP:
		_hitbox.position = Vector2(0, -95)
	elif _aim == Vector2.DOWN:
		_hitbox.position = Vector2(0, 25)
	else:
		_hitbox.position = Vector2(62 * _facing, -28)
	_hitbox.activate()


func _compute_aim() -> Vector2:
	var v: Vector2 = _gi.get_aim_vector()
	if v.y < -0.5:
		return Vector2.UP
	if v.y > 0.5 and not is_on_floor():
		return Vector2.DOWN
	return Vector2.RIGHT if _facing > 0 else Vector2.LEFT


func _on_hit_landed(_target: EmberHurtbox) -> void:
	_am.play_sfx("hit")
	resource = mini(RESOURCE_MAX, resource + RESOURCE_PER_HIT)
	resource_changed.emit(resource)
	# Pogo: down-slash while airborne bounces you up.
	if _aim == Vector2.DOWN and not is_on_floor():
		velocity.y = JUMP_VELOCITY * POGO_BOUNCE
	# Juice: hitstop + shake + orange sparks + slash swoosh.
	HitStop.freeze(get_tree(), 0.05, 0.1)
	if _shake != null:
		_shake.add_trauma(0.2)
	if _target != null:
		HitParticles.spark(get_tree().current_scene, _target.global_position, HitParticles.HIT_ORANGE)
	if _trail != null:
		_trail.trigger_slash(_aim)


func _on_hurt(_amount: int) -> void:
	_am.play_sfx("player_hurt")
	# Juice: red sparks + heavier shake when the player takes damage.
	HitParticles.spark(get_tree().current_scene, global_position, HitParticles.HURT_RED, 16)
	if _shake != null:
		_shake.add_trauma(0.35)


func _on_died() -> void:
	# Death: drop cinders as an echo shade, respawn at last hearth with full health.
	var amount: int = _gs.currency
	if amount > 0:
		_gs.drop_echo(amount, global_position)
		_gs.currency = 0
	_health.health = _health.max_health
	get_node("/root/SaveSystem").save_game()
	get_tree().reload_current_scene()


func apply_save(health_value: int, resource_value: int) -> void:
	"""Called by SaveSystem after load."""
	# If save has 0/invalid health (corrupted from old bug), restore to full.
	if health_value <= 0:
		health_value = _health.max_health
	_health.health = clampi(health_value, 1, _health.max_health)
	resource = clampi(resource_value, 0, RESOURCE_MAX)
	resource_changed.emit(resource)


func full_heal() -> void:
	_health.heal(_health.max_health)


func get_health() -> int:
	return _health.health


func get_max_health() -> int:
	return _health.max_health


func is_healing() -> bool:
	return _healing


func is_dashing() -> bool:
	return _dash_timer > 0.0


func get_aim() -> Vector2:
	return _aim


func get_attack_phase() -> float:
	"""0..1 progress of the current slash (for the slash arc visual)."""
	if _attack_timer <= 0.0:
		return 0.0
	return _attack_timer / ATTACK_TIME
