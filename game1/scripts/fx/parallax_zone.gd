extends ParallaxBackground
## Zone parallax background — creates live, multi-layer backgrounds.
## Attach to a room, set zone_theme, and it builds parallax layers + particles.
## Themes: "emberfall" (Zone 1, full 5-layer stack), "tideglass" (Zone 2),
## "frostglass" (Zone 3), "ashfall" (Zone 4) — non-emberfall themes use the
## legacy 3-layer build until their own art passes exist.
##
## Emberfall stack (back → front):
##   Far 0.10 — distant caverns, light rays, far landmark
##   Mid 0.35 — rock formations, ember veins (top alpha-faded)
##   Fog 0.50 — warm fog band between mid and near (depth separation)
##   Near 0.65 — detailed lava rocks + stalactites (top alpha-faded)
##   Foreground 1.15 — black silhouette frame, separate ParallaxBackground
##   at canvas layer 5 (in front of gameplay, below touch controls at 10)
## Plus a soft light that follows the player (player_glow.gd).

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

const BG := "res://assets/backgrounds/"


func _ready() -> void:
	var theme: Dictionary = THEMES.get(zone_theme, THEMES["emberfall"])
	if zone_theme == "emberfall":
		_build_emberfall_layers()
		_build_foreground()
		_build_player_glow(theme)
	else:
		_build_legacy_layers()
	_build_particles(theme)


func _make_layer(parent: Node, layer_name: String, tex: Texture2D, motion: Vector2, spr_scale: float, spr_pos: Vector2) -> void:
	if tex == null:
		return
	var layer := ParallaxLayer.new()
	layer.name = layer_name
	layer.motion_scale = motion
	layer.motion_mirroring = Vector2(tex.get_width() * spr_scale, 0.0)
	parent.add_child(layer)
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.centered = false
	spr.scale = Vector2(spr_scale, spr_scale)
	spr.position = spr_pos
	layer.add_child(spr)


func _build_emberfall_layers() -> void:
	var far_tex := load(BG + "media-generation-z1-parallax-far-v2-0-1c7fb1c4-3a73-4b5b-9fc8-9793732bcf35.webp") as Texture2D
	var mid_tex := load(BG + "z1-mid-v2.png") as Texture2D
	var fog_tex := load(BG + "z1-fog.png") as Texture2D
	var near_tex := load(BG + "z1-near-v2.png") as Texture2D
	_make_layer(self, "Far", far_tex, Vector2(0.10, 0.08), 0.72, Vector2(0, 0))
	_make_layer(self, "Mid", mid_tex, Vector2(0.35, 0.22), 0.79, Vector2(0, -30))
	_make_layer(self, "Fog", fog_tex, Vector2(0.50, 0.30), 2.0, Vector2(0, -100))
	_make_layer(self, "Near", near_tex, Vector2(0.65, 0.38), 0.70, Vector2(0, 180))


func _build_foreground() -> void:
	# Foreground silhouettes drift slightly faster than the world = depth in front.
	var fg_tex := load(BG + "z1-fg-silhouette.png") as Texture2D
	if fg_tex == null or get_parent() == null:
		return
	var fg_bg := ParallaxBackground.new()
	fg_bg.name = "ForegroundBG"
	fg_bg.layer = 5  # Above gameplay (0), below TouchControls (10) and HUD
	_make_layer(fg_bg, "FG", fg_tex, Vector2(1.15, 1.02), 0.75, Vector2(0, -20))
	get_parent().add_child.call_deferred(fg_bg)


func _build_player_glow(theme: Dictionary) -> void:
	if get_parent() == null:
		return
	var glow_script := load("res://scripts/fx/player_glow.gd") as Script
	if glow_script == null:
		return
	var glow := Node2D.new()
	glow.set_script(glow_script)
	glow.name = "PlayerGlow"
	glow.set("tint", theme["glow_color"])
	get_parent().add_child.call_deferred(glow)


func _build_legacy_layers() -> void:
	# Pre-enhancement 3-layer build, kept for zones without their own art yet.
	var far_tex := load(BG + "media-generation-z1-parallax-far-0-fd82cfd5-378b-47d4-8d5c-a89fccc3047f.webp") as Texture2D
	var mid_tex := load(BG + "media-generation-z1-parallax-mid-0-66497e41-8b93-4406-871a-ae26a879a9a5.webp") as Texture2D
	var near_tex := load(BG + "media-generation-z1-parallax-near-0-42a4a6f4-88b5-4e77-8528-e4b84cb86f56.webp") as Texture2D

	if far_tex != null:
		var far := ParallaxLayer.new()
		far.motion_scale = Vector2(0.2, 0.2)
		far.name = "Far"
		add_child(far)
		var far_sprite := Sprite2D.new()
		far_sprite.texture = far_tex
		far_sprite.centered = false
		far_sprite.scale = Vector2(3.0, 3.0)
		far.add_child(far_sprite)

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

	if near_tex != null:
		var near := ParallaxLayer.new()
		near.motion_scale = Vector2(0.85, 0.2)
		near.name = "Near"
		add_child(near)
		var near_sprite := Sprite2D.new()
		near_sprite.texture = near_tex
		near_sprite.centered = false
		near_sprite.scale = Vector2(2.5, 2.5)
		near_sprite.position = Vector2(0, 400)
		near.add_child(near_sprite)


func _build_particles(theme: Dictionary) -> void:
	# Ambient floating particles
	var particles := CPUParticles2D.new()
	particles.name = "AmbientParticles"
	particles.amount = 36
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
	particles.position = Vector2(640, 360)
	add_child(particles)
