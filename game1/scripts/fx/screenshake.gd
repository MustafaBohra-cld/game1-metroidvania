class_name ScreenShake
extends Node
## ScreenShake — FX module. Trauma-based camera shake.
## Attach as a child of the player Camera2D. Call add_trauma(amount).
## Trauma decays over time; offset is trauma^2 scaled for smooth feel.
##
## Helper for non-player code (enemies, etc.):
##   ScreenShake.add_trauma_to_player_camera(get_tree(), 0.4)

const DECAY_RATE := 1.6
const MAX_OFFSET := 26.0
const NOISE_SPEED := 32.0

var trauma := 0.0

var _camera: Camera2D
var _noise_t := 0.0


func _ready() -> void:
	_camera = get_parent() as Camera2D


func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)


func _process(delta: float) -> void:
	if _camera == null:
		return
	_noise_t += delta * NOISE_SPEED
	trauma = maxf(0.0, trauma - delta * DECAY_RATE)
	if trauma <= 0.0:
		_camera.offset = Vector2.ZERO
		return
	var s := trauma * trauma * MAX_OFFSET
	_camera.offset = Vector2(
		sin(_noise_t * 1.13) * s,
		cos(_noise_t * 1.71) * s
	)


static func add_trauma_to_player_camera(tree: SceneTree, amount: float) -> void:
	"""One-liner for enemies/bosses: shake the player camera without a reference."""
	if tree == null:
		return
	var player := tree.get_first_node_in_group("player")
	if player == null:
		return
	var shake := player.get_node_or_null("Camera/ScreenShake") as ScreenShake
	if shake != null:
		shake.add_trauma(amount)
