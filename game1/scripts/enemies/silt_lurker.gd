extends CharacterBody2D
## SiltLurker — Foundry ambusher (M5b). Buried with only glowing eyes visible;
## erupts when the player is within 120px horizontally above it, snaps upward
## for 2 damage, then reburies. 4 HP.
##
## Expected scene nodes (parent wires the .tscn):
##   Health (EmberHealth), Hurtbox (EmberHurtbox), ContactHitbox (EmberHitbox),
##   SnapHitbox (EmberHitbox, positioned above the lurker), Visual (Node2D).
## The eye dots are created in code.

class_name SiltLurker

## Emitted when the lurker erupts from the silt.
signal erupted
## Emitted when the snap lunge begins.
signal snapped

const GRAVITY := 1350.0
const ERUPT_TIME := 0.3
const REBURY_TIME := 2.0
const TRIGGER_X := 120.0
const TRIGGER_Y_MIN := 20.0
const TRIGGER_Y_MAX := 200.0
const SNAP_SPEED := 520.0
const RISE_OFFSET := 44.0

enum S { BURIED, ERUPT, SNAP, REBURY }

var _state: int = S.BURIED
var _t := 0.0
var _flash := 0.0
var _rest_y := 0.0
var _eye_l: Polygon2D
var _eye_r: Polygon2D

@onready var _health: EmberHealth = $Health
@onready var _visual: Node2D = $Visual
@onready var _snap_hitbox: EmberHitbox = $SnapHitbox


func _ready() -> void:
	add_to_group("enemies")
	_rest_y = position.y
	_make_eyes()
	_apply_buried_visual()
	var hurtbox := $Hurtbox as EmberHurtbox
	hurtbox.health = _health
	hurtbox.team = 1
	var contact := $ContactHitbox as EmberHitbox
	contact.team = 1
	contact.damage = 1
	contact.knockback = Vector2(260.0, -320.0)
	_snap_hitbox.team = 1
	_snap_hitbox.damage = 2
	_snap_hitbox.knockback = Vector2(200.0, -420.0)
	_health.damaged.connect(_on_damaged)
	_health.died.connect(_die)


func _make_eyes() -> void:
	# Two small glowing diamonds, the only visible part while buried.
	var eye_poly := PackedVector2Array(
		[Vector2(-5, 0), Vector2(0, -4), Vector2(5, 0), Vector2(0, 4)])
	_eye_l = Polygon2D.new()
	_eye_l.polygon = eye_poly
	_eye_l.color = Color(0.4, 0.9, 1.0)
	_eye_l.position = Vector2(-10, -18)
	_eye_r = Polygon2D.new()
	_eye_r.polygon = eye_poly
	_eye_r.color = Color(0.4, 0.9, 1.0)
	_eye_r.position = Vector2(10, -18)
	add_child(_eye_l)
	add_child(_eye_r)


func _apply_buried_visual() -> void:
	_visual.visible = false
	_eye_l.visible = true
	_eye_r.visible = true
	var contact := $ContactHitbox as EmberHitbox
	contact.deactivate()


func _apply_exposed_visual() -> void:
	_visual.visible = true
	_eye_l.visible = false
	_eye_r.visible = false
	var contact := $ContactHitbox as EmberHitbox
	contact.activate()


func _physics_process(delta: float) -> void:
	_t -= delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	match _state:
		S.BURIED:
			velocity = Vector2.ZERO
			move_and_slide()
			if player != null and _player_above(player):
				_state = S.ERUPT
				_t = ERUPT_TIME
				_apply_exposed_visual()
				erupted.emit()
		S.ERUPT:
			# Rise telegraph: lift toward the surface.
			velocity = Vector2.ZERO
			position.y = lerpf(position.y, _rest_y - RISE_OFFSET, 12.0 * delta)
			move_and_slide()
			if _t <= 0.0:
				_state = S.SNAP
				velocity.y = -SNAP_SPEED
				_snap_hitbox.activate()
				snapped.emit()
		S.SNAP:
			velocity.y += GRAVITY * delta
			velocity.x = 0.0
			move_and_slide()
			if is_on_floor() and velocity.y >= 0.0:
				_snap_hitbox.deactivate()
				_state = S.REBURY
				_t = REBURY_TIME
		S.REBURY:
			velocity = Vector2.ZERO
			position.y = lerpf(position.y, _rest_y, 6.0 * delta)
			move_and_slide()
			if _t <= 0.0:
				_state = S.BURIED
				_apply_buried_visual()


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash -= delta
		modulate = Color(1, 0.4, 0.4) if _flash > 0.0 else Color.WHITE
	# Eye blink while buried.
	if _state == S.BURIED:
		var blink: float = 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.004)
		_eye_l.modulate.a = blink
		_eye_r.modulate.a = blink


func _player_above(player: Node2D) -> bool:
	var dx: float = absf(player.global_position.x - global_position.x)
	var dy: float = global_position.y - player.global_position.y
	return dx < TRIGGER_X and dy > TRIGGER_Y_MIN and dy < TRIGGER_Y_MAX


func _on_damaged(_amount: int) -> void:
	_flash = 0.12


func _die() -> void:
	get_node("/root/AudioManager").play_sfx("enemy_die")
	_snap_hitbox.deactivate()
	var gs := get_node("/root/GameState")
	var roll := 3 + randi() % 4 # 3-6 cinders
	gs.add_currency(int(round(float(roll) * float(gs.get_stat("currency_gain")))))
	queue_free()
