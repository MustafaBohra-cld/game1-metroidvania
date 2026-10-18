extends ParallaxBackground
## Zone parallax background — creates live, multi-layer backgrounds.
## Attach to a room, set zone_theme, and it builds 3 parallax layers + particles.
## Themes: "emberfall" (Zone 1), "tideglass" (Zone 2), "frostglass" (Zone 3), "ashfall" (Zone 4)

@export var zone_theme: String = "emberfall"

const THEMES := {
	"emberfall": {
		"far_color": Color(0.08, 0.05, 0.04),
		"mid_color": Color(0.15, 0.08, 0.05),
		"near_color": Color(0.10, 0.06, 0.04),
		"glow_color": Color(1.0, 0.45, 0.15),
		"particle_color": Color(1.0, 0.55, 0.2),
	},
	"tideglass": {
		"far_color": Color(0.04, 0.08, 0.10),
		"mid_color": Color(0.06, 0.14, 0.16),
		"near_color": Color(0.05, 0.10, 0.12),
		"glow_color": Color(0.3, 0.9, 0.85),
		"particle_color": Color(0.4, 0.95, 0.9),
	},
	"frostglass": {
		"far_color": Color(0.08, 0.10, 0.14),
		"mid_color": Color(0.12, 0.16, 0.20),
		"near_color": Color(0.10, 0.13, 0.17),
		"glow_color": Color(0.6, 0.85, 1.0),
		"particle_color": Color(0.75, 0.92, 1.0),
	},
	"ashfall": {
		"far_color": Color(0.06, 0.06, 0.07),
		"mid_color": Color(0.10, 0.10, 0.11),
		"near_color": Color(0.08, 0.08, 0.09),
		"glow_color": Color(0.9, 0.3, 0.15),
		"particle_color": Color(0.7, 0.7, 0.72),
	},
}


func _ready() -> void:
	var theme: Dictionary = THEMES.get(zone_theme, THEMES["emberfall"])
	_build_layers(theme)
	_build_particles(theme)


func _build_layers(theme: Dictionary) -> void:
	# Load parallax art for the zone
	var base_path := "res://assets/backgrounds/"
	var far_tex := load(base_path + "media-generation-z1-parallax-far-0-fd82cfd5-378b-47d4-8d5c-a89fccc3047f.webp") as Texture2D
	var mid_tex := load(base_path + "media-generation-z1-parallax-mid-0-66497e41-8b93-4406-871a-ae26a879a9a5.webp") as Texture2D
	var near_tex := load(base_path + "media-generation-z1-parallax-near-0-42a4a6f4-88b5-4e77-8528-e4b84cb86f56.webp") as Texture2D

	# Far layer: slow (0.2)
	if far_tex != null:
		var far := ParallaxLayer.new()
		far.motion_scale = Vector2(0.2, 0.2)
		far.name = "Far"
		add_child(far)
		var far_sprite := Sprite2D.new()
		far_sprite.texture = far_tex
		far_sprite.centered = false
		far_sprite.scale = Vector2(3.0, 3.0)  # Scale up to cover
		far.add_child(far_sprite)

	# Mid layer: medium (0.5)
	if mid_tex != null:
		var mid := ParallaxLayer.new()
		mid.motion_scale = Vector2(0.5, 0.5)
		mid.name = "Mid"
		add_child(mid)
		var mid_sprite := Sprite2D.new()
		mid_sprite.texture = mid_tex
		mid_sprite.centered = false
		mid_sprite.scale = Vector2(2.0, 2.0)
		mid.add_child(mid_sprite)

	# Near layer: fast (0.85)
	if near_tex != null:
		var near := ParallaxLayer.new()
		near.motion_scale = Vector2(0.85, 0.2)  # Mostly horizontal
		near.name = "Near"
		add_child(near)
		var near_sprite := Sprite2D.new()
		near_sprite.texture = near_tex
		near_sprite.centered = false
		near_sprite.scale = Vector2(2.5, 2.5)
		near_sprite.position = Vector2(0, 400)  # Lower for foreground
		near.add_child(near_sprite)


func _build_particles(theme: Dictionary) -> void:
	# Ambient floating particles
	var particles := CPUParticles2D.new()
	particles.name = "AmbientParticles"
	particles.amount = 30
	particles.lifetime = 6.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(800, 400)
	particles.direction = Vector2(0, -1)
	particles.spread = 30.0
	particles.initial_velocity_min = 10.0
	particles.initial_velocity_max = 30.0
	particles.gravity = Vector2.ZERO
	particles.scale_amount_min = 1.5
	particles.scale_amount_max = 3.5
	particles.color = Color(theme["particle_color"], 0.6)
	# Position at camera center (will follow via canvas layer)
	particles.position = Vector2(640, 360)
	add_child(particles)
