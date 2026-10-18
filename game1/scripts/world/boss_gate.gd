extends Area2D
## BossGate — World module. Seals the boss arena when the player enters,
## wakes the boss. The boss calls open_gates() on death.

@export var gate_path: NodePath
@export var boss_path: NodePath
@export var gate_path2: NodePath

var _triggered := false


func _ready() -> void:
	add_to_group("boss_gate")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _triggered or not body.is_in_group("player"):
		return
	# Boss already dead (re-entering after a reload): leave the arena open.
	if get_node("/root/GameState").get_flag("maw_dead", false):
		return
	_triggered = true
	_set_gate(true)
	var boss := get_node_or_null(boss_path)
	if boss != null and boss.has_method("activate"):
		boss.activate()


func open_gates() -> void:
	_set_gate(false)


func _set_gate(closed: bool) -> void:
	_apply_gate(gate_path, closed)
	if gate_path2 != NodePath(""):
		_apply_gate(gate_path2, closed)


func _apply_gate(path: NodePath, closed: bool) -> void:
	var gate := get_node_or_null(path)
	if gate == null:
		return
	gate.visible = closed
	gate.set_deferred("collision_layer", 1 if closed else 0)
	gate.set_deferred("collision_mask", 1 if closed else 0)
