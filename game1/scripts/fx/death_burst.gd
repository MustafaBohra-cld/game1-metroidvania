class_name DeathBurst
extends RefCounted
## DeathBurst — FX module. Enemy death: particle explosion + cinder scatter + shake.
## Static helper: DeathBurst.explode(get_tree(), global_position)
## Pass big=true for bosses (bigger burst, heavier shake).
##
## Note: cinders are visual only (economy still via GameState.add_currency).


static func explode(tree: SceneTree, pos: Vector2, big: bool = false) -> void:
	if tree == null or tree.current_scene == null:
		return
	var scene := tree.current_scene
	var scale_mult := 1.8 if big else 1.0
	# Core explosion: orange embers
	HitParticles.burst(scene, pos, HitParticles.HIT_ORANGE, int(18 * scale_mult), 0.6, 420.0)
	# Hot center: yellow-white flash
	HitParticles.burst(scene, pos, HitParticles.HIT_YELLOW, int(10 * scale_mult), 0.35, 260.0)
	# Cinder scatter: gold dots arc outward and linger
	_cinder_scatter(scene, pos, int(7 * scale_mult))
	# Screen shake: medium on kill, big on boss
	ScreenShake.add_trauma_to_player_camera(tree, 0.7 if big else 0.4)


static func _cinder_scatter(scene: Node, pos: Vector2, count: int) -> void:
	"""Golden cinder motes that pop up and fall — pure visual juice."""
	var tree := scene.get_tree()
	if tree == null:
		return
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.explosiveness = 0.85
	p.amount = count
	p.lifetime = 0.9
	p.spread = 160.0
	p.direction = Vector2(0, -1)
	p.initial_velocity_min = 180.0
	p.initial_velocity_max = 340.0
	p.gravity = Vector2(0, 900)
	p.scale_amount_min = 2.5
	p.scale_amount_max = 4.0
	p.color = HitParticles.CINDER_GOLD
	p.position = pos - scene.global_position if scene is Node2D else pos
	scene.add_child(p)
	p.emitting = true
	var timer := tree.create_timer(1.6)
	timer.timeout.connect(p.queue_free)
