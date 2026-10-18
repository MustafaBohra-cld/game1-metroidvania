class_name HitParticles
extends RefCounted
## HitParticles — FX module. CPUParticles2D one-shot bursts (Android-safe).
## Static helpers: spawn at a position, auto-free after the burst.
##
##   HitParticles.spark(scene, pos, HitParticles.HIT_ORANGE)
##   HitParticles.spark(scene, pos, HitParticles.HURT_RED, 16)
##   HitParticles.burst(scene, pos, color, count, lifetime)

const HIT_ORANGE := Color(1.0, 0.6, 0.2)
const HIT_YELLOW := Color(1.0, 0.85, 0.4)
const HURT_RED := Color(1.0, 0.25, 0.2)
const CINDER_GOLD := Color(1.0, 0.75, 0.25)
const BOSS_PURPLE := Color(0.7, 0.3, 1.0)


static func spark(parent: Node, pos: Vector2, color: Color, count: int = 12) -> void:
	"""Quick impact spark (slash hits, player hurt)."""
	burst(parent, pos, color, count, 0.35, 320.0)


static func burst(
	parent: Node, pos: Vector2, color: Color,
	count: int = 16, lifetime: float = 0.5, speed: float = 380.0
) -> void:
	"""Generic one-shot particle burst. Auto-frees."""
	if parent == null:
		return
	var tree := parent.get_tree()
	if tree == null:
		return
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.explosiveness = 0.92
	p.amount = count
	p.lifetime = lifetime
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, 700)
	p.damping_min = 40.0
	p.damping_max = 120.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.5
	p.color = color
	p.position = pos - parent.global_position if parent is Node2D else pos
	parent.add_child(p)
	p.emitting = true
	var timer := tree.create_timer(lifetime + 0.6)
	timer.timeout.connect(p.queue_free)
