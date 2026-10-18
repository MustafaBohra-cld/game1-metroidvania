extends AnimatedSprite2D
## SpriteAnim — builds the wanderer's animations from the sprite strips.
## Run: 6 frames. Jump: rise/apex/fall singles. Slash: 3 frames, plays once.

const BASE_SCALE := 0.15
# Measured lowest-opaque-pixel per frame -> node y that puts the feet on
# the floor. Every frame gets its own value so nothing ever hovers.
# NOTE: the collision capsule is centered on the origin, so the feet sit
# at +28 — all values below already include that offset.
const RUN_Y := [-3.2, -8.0, -4.7, 0.4, -7.5, -5.6]
const JUMP_Y := [-16.9, -4.9, -25.4]
const SLASH_Y := [-8.1, -7.1, -7.2]

const RUN_STRIP := "res://assets/sprites/wanderer_run.png"
const JUMP_STRIP := "res://assets/sprites/wanderer_jump.png"
const SLASH_STRIP := "res://assets/sprites/wanderer_slash.png"


func _ready() -> void:
	var frames := SpriteFrames.new()
	_add_strip(frames, "run", load(RUN_STRIP), 6, 10.0)
	_add_strip(frames, "slash", load(SLASH_STRIP), 3, 14.0)
	frames.set_animation_loop("slash", false)
	_add_single(frames, "jump", load(JUMP_STRIP), 3, 0)
	_add_single(frames, "fall", load(JUMP_STRIP), 3, 2)
	_add_single(frames, "idle", load(RUN_STRIP), 6, 0)
	sprite_frames = frames
	scale = Vector2(BASE_SCALE, BASE_SCALE)
	play("idle")


func _process(_delta: float) -> void:
	# Pin the current frame's feet to the floor.
	match animation:
		&"run":
			position.y = RUN_Y[frame % RUN_Y.size()]
		&"idle":
			position.y = RUN_Y[0]
		&"jump":
			position.y = JUMP_Y[0]
		&"fall":
			position.y = JUMP_Y[2]
		&"slash":
			position.y = SLASH_Y[frame % SLASH_Y.size()]


func set_state(s: String) -> void:
	"""Switch animation; 'dash' maps to a sped-up run."""
	if s == "dash":
		speed_scale = 2.0
		s = "run"
	else:
		speed_scale = 1.0
	if animation == s and is_playing():
		return
	play(s)


func _add_strip(frames: SpriteFrames, anim: String, tex: Texture2D,
		count: int, fps: float) -> void:
	frames.add_animation(anim)
	frames.set_animation_speed(anim, fps)
	var cell := Vector2(tex.get_width() / float(count), tex.get_height())
	for i in count:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(Vector2(i * cell.x, 0.0), cell)
		frames.add_frame(anim, at)


func _add_single(frames: SpriteFrames, anim: String, tex: Texture2D,
		count: int, idx: int) -> void:
	frames.add_animation(anim)
	var cell := Vector2(tex.get_width() / float(count), tex.get_height())
	var at := AtlasTexture.new()
	at.atlas = tex
	at.region = Rect2(Vector2(idx * cell.x, 0.0), cell)
	frames.add_frame(anim, at)
