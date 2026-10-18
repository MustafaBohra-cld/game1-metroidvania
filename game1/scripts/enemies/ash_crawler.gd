extends CharacterBody2D
## AshCrawler — Z1 walker enemy. Patrols, flips at walls and ledges.
## Contact damage via its own hitbox. 3 HP.

class_name AshCrawler

const SPEED := 60.0
const GRAVITY := 1350.0

var _dir := -1
var _flash := 0.0

@onready var _health: EmberHealth = $Health
@onready var _visual: Node2D = $Visual
@onready var _ledge: RayCast2D = $LedgeCheck


func _ready() -> void:
	var hurtbox := $Hurtbox as EmberHurtbox
	hurtbox.health = _health
	hurtbox.team = 1
	var contact := $ContactHitbox as EmberHitbox
	contact.team = 1
	contact.damage = 1
	contact.knockback = Vector2(260.0, -200.0)
	contact.resource_gain = 0
	contact.activate() # contact damage is always on
	_health.damaged.connect(_on_damaged)
	_health.died.connect(_die)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = _dir * SPEED
	move_and_slide()
	if is_on_wall():
		_dir *= -1
	_ledge.position.x = 22.0 * _dir
	if is_on_floor() and not _ledge.is_colliding():
		_dir *= -1
	_visual.scale.x = float(_dir)


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash -= delta
		modulate = Color(1, 0.4, 0.4) if _flash > 0.0 else Color.WHITE


func _on_damaged(_amount: int) -> void:
	_flash = 0.12


func _die() -> void:
	get_node("/root/AudioManager").play_sfx("enemy_die")
	DeathBurst.explode(get_tree(), global_position)
	var gs := get_node("/root/GameState")
	var roll := 3 + randi() % 4 # 3-6 cinders
	gs.add_currency(int(round(roll * gs.get_stat("currency_gain"))))
	queue_free()
