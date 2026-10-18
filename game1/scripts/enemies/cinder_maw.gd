extends CharacterBody2D
## CinderMaw — Z1 boss. 12-sprite state machine.
## States: DORMANT -> EMERGE(3) -> IDLE(2) -> BITE_WINDUP -> BITE -> IDLE
##                                    -> SWEEP_WINDUP -> SWEEP -> IDLE
##                              HIT (on damage) -> DEFEAT(2) -> die
## Kill it: unlocks Ember Dash, opens the arena gate, drops 30 cinders.

const MAX_HP := 24
const GRAVITY := 1350.0
const LUNGE_SPEED := 750.0

# Sprite textures - 12 moves
const TEX_EMERGE1 := preload("res://assets/sprites/enemies/maw-emerge1.png")
const TEX_EMERGE2 := preload("res://assets/sprites/enemies/maw-emerge2.png")
const TEX_EMERGE3 := preload("res://assets/sprites/enemies/maw-emerge3.png")
const TEX_IDLE1 := preload("res://assets/sprites/enemies/maw-idle1.png")
const TEX_IDLE2 := preload("res://assets/sprites/enemies/maw-idle2.png")
const TEX_BITE_WINDUP := preload("res://assets/sprites/enemies/maw-bite-windup.png")
const TEX_BITE := preload("res://assets/sprites/enemies/maw-bite.png")
const TEX_SWEEP_WINDUP := preload("res://assets/sprites/enemies/maw-sweep-windup.png")
const TEX_SWEEP := preload("res://assets/sprites/enemies/maw-sweep.png")
const TEX_HIT := preload("res://assets/sprites/enemies/maw-hit.png")
const TEX_DEFEAT1 := preload("res://assets/sprites/enemies/maw-defeat1.png")
const TEX_DEFEAT2 := preload("res://assets/sprites/enemies/maw-defeat2.png")

enum S { DORMANT, EMERGE, IDLE, BITE_WINDUP, BITE, SWEEP_WINDUP, SWEEP, HIT, DEFEAT }

var boss_name := "Cinder Maw"
var boss_active := false

var _state: int = S.DORMANT
var _t := 0.0
var _dir := -1.0
var _emerge_step := 0
var _idle_step := 0
var _idle_timer := 0.0
var _attack_cooldown := 0.0

@onready var _health: EmberHealth = $Health
@onready var _sprite: Sprite2D = $Visual/Sprite


func _ready() -> void:
	add_to_group("boss")
	#visible = false  # DEBUG: always visible
	#set_physics_process(false)  # DEBUG: always active
	var hurtbox := $Hurtbox as EmberHurtbox
	hurtbox.health = _health
	hurtbox.team = 1
	var contact := $ContactHitbox as EmberHitbox
	contact.team = 1
	contact.damage = 1
	contact.knockback = Vector2(420.0, -260.0)
	contact.resource_gain = 0
	contact.activate()
	_health.died.connect(_die)
	_health.damaged.connect(_on_damaged)
	# Set initial sprite
	_sprite.texture = TEX_EMERGE1
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func activate() -> void:
	get_node("/root/AudioManager").play_sfx("boss_roar")
	get_node("/root/AudioManager").play_music("boss")
	visible = true
	set_physics_process(true)
	boss_active = true
	_change_state(S.EMERGE)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_toast"):
		hud.show_toast("Cinder Maw awakens!")


func _change_state(new_state: int) -> void:
	_state = new_state
	match _state:
		S.EMERGE:
			_emerge_step = 0
			_t = 0.5
			_sprite.texture = TEX_EMERGE1
		S.IDLE:
			_t = 999.0  # Stay until attack
			_idle_timer = 0.0
			_idle_step = 0
			_sprite.texture = TEX_IDLE1
		S.BITE_WINDUP:
			_t = 0.6
			_sprite.texture = TEX_BITE_WINDUP
		S.BITE:
			_t = 0.4
			_sprite.texture = TEX_BITE
			_do_bite_attack()
		S.SWEEP_WINDUP:
			_t = 0.7
			_sprite.texture = TEX_SWEEP_WINDUP
		S.SWEEP:
			_t = 0.5
			_sprite.texture = TEX_SWEEP
			_do_sweep_attack()
		S.HIT:
			_t = 0.35
			_sprite.texture = TEX_HIT
		S.DEFEAT:
			_t = 1.5
			_sprite.texture = TEX_DEFEAT1


func _physics_process(delta: float) -> void:
	if not boss_active:
		return
	
	_t -= delta
	_attack_cooldown -= delta
	
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	var player := get_tree().get_first_node_in_group("player") as Node2D
	
	match _state:
		S.EMERGE:
			_sprite.position.x = randf_range(-8.0, 8.0)
			if _t <= 0.0:
				_emerge_step += 1
				if _emerge_step == 1:
					_sprite.texture = TEX_EMERGE2
					_t = 0.5
				elif _emerge_step == 2:
					_sprite.texture = TEX_EMERGE3
					_t = 0.6
					var scr := get_tree().get_first_node_in_group("screenshake") as Node
					if scr and scr.has_method("add_trauma"):
						scr.add_trauma(0.5)
				else:
					_sprite.position.x = 0.0
					_change_state(S.IDLE)
		
		S.IDLE:
			_idle_timer += delta
			if _idle_timer > 0.4:
				_idle_timer = 0.0
				_idle_step = 1 - _idle_step
				_sprite.texture = TEX_IDLE1 if _idle_step == 0 else TEX_IDLE2
			if player:
				_dir = signf(player.global_position.x - global_position.x)
				if _dir == 0.0:
					_dir = 1.0
				_sprite.flip_h = _dir < 0.0
			if _attack_cooldown <= 0.0 and player:
				var dist := absf(player.global_position.x - global_position.x)
				if dist < 350.0:
					_change_state(S.BITE_WINDUP)
				else:
					_change_state(S.SWEEP_WINDUP)
				_attack_cooldown = 2.0
		
		S.BITE_WINDUP:
			velocity.x = 0.0
			if _t <= 0.0:
				_change_state(S.BITE)
		
		S.BITE:
			velocity.x = _dir * LUNGE_SPEED
			if _t <= 0.0:
				velocity.x = 0.0
				_change_state(S.IDLE)
		
		S.SWEEP_WINDUP:
			velocity.x = 0.0
			if _t <= 0.0:
				_change_state(S.SWEEP)
		
		S.SWEEP:
			velocity.x = 0.0
			if _t <= 0.0:
				_change_state(S.IDLE)
		
		S.HIT:
			velocity.x = 0.0
			if _t <= 0.0:
				_change_state(S.IDLE)
		
		S.DEFEAT:
			velocity.x = 0.0
			if _t <= 0.7 and _sprite.texture != TEX_DEFEAT2:
				_sprite.texture = TEX_DEFEAT2
			if _t <= 0.0:
				_finish_defeat()
	
	move_and_slide()
	global_position.x = clampf(global_position.x, 100.0, 1500.0)


func _do_bite_attack() -> void:
	var hitbox := get_node_or_null("BiteHitbox") as EmberHitbox
	if hitbox:
		hitbox.team = 1
		hitbox.damage = 2
		hitbox.knockback = Vector2(_dir * 500.0, -300.0)
		hitbox.activate()
		await get_tree().create_timer(0.3).timeout
		if is_instance_valid(hitbox):
			hitbox.deactivate()
	else:
		# Fallback: use ContactHitbox with higher damage temporarily
		var contact := $ContactHitbox as EmberHitbox
		contact.damage = 2
		await get_tree().create_timer(0.3).timeout
		if is_instance_valid(contact):
			contact.damage = 1


func _do_sweep_attack() -> void:
	var scr := get_tree().get_first_node_in_group("screenshake") as Node
	if scr and scr.has_method("add_trauma"):
		scr.add_trauma(0.3)
	get_node("/root/AudioManager").play_sfx("boss_roar")


func _on_damaged(_amount: int) -> void:
	if _state != S.EMERGE and _state != S.DEFEAT and _state != S.HIT and boss_active:
		_change_state(S.HIT)


func _die() -> void:
	boss_active = false
	velocity.x = 0.0
	_change_state(S.DEFEAT)
	get_node("/root/AudioManager").play_sfx("boss_roar")


func _finish_defeat() -> void:
	var gs := get_node("/root/GameState")
	gs.unlock_ability("dash")
	gs.set_flag("maw_dead", true)
	gs.add_cinders(30)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_toast"):
		hud.show_toast("Ember Dash acquired! (L / dash button)")
	get_node("/root/AudioManager").play_music("ambient")
	queue_free()
