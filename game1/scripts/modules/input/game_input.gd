extends Node
## GameInput — autoload singleton (Input module facade).
## Unified keyboard + touch (+ gamepad later) input with press buffering.
## Gameplay code reads from here. Never from Input directly.

const JUMP_BUFFER := 0.12
const ATTACK_BUFFER := 0.15
const INTERACT_BUFFER := 0.15
const DASH_BUFFER := 0.15

var _touch_move: Vector2 = Vector2.ZERO
var _touch_jump_held: bool = false
var _touch_jump_released: bool = false
var _touch_heal_held: bool = false
var _jump_buffer_timer: float = 0.0
var _attack_buffer_timer: float = 0.0
var _interact_buffer_timer: float = 0.0
var _dash_buffer_timer: float = 0.0


func _ready() -> void:
	_ensure_actions()


func _ensure_actions() -> void:
	_add_key_action(&"move_left", [KEY_A, KEY_LEFT])
	_add_key_action(&"move_right", [KEY_D, KEY_RIGHT])
	_add_key_action(&"jump", [KEY_SPACE, KEY_W, KEY_UP])
	_add_key_action(&"attack", [KEY_J, KEY_X])
	_add_key_action(&"heal", [KEY_K, KEY_C])
	_add_key_action(&"aim_up", [KEY_W, KEY_UP])
	_add_key_action(&"aim_down", [KEY_S, KEY_DOWN])
	_add_key_action(&"interact", [KEY_E, KEY_F])
	_add_key_action(&"dash", [KEY_L, KEY_SHIFT])
	# dash / interact / pause arrive in later milestones.


func _add_key_action(action: StringName, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key: int in keys:
		var exists := false
		for e: InputEvent in InputMap.action_get_events(action):
			if e is InputEventKey and e.physical_keycode == key:
				exists = true
		if not exists:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)


func _process(delta: float) -> void:
	if Input.is_action_just_pressed(&"jump"):
		_jump_buffer_timer = JUMP_BUFFER
	else:
		_jump_buffer_timer = maxf(0.0, _jump_buffer_timer - delta)
	if Input.is_action_just_pressed(&"attack"):
		_attack_buffer_timer = ATTACK_BUFFER
	else:
		_attack_buffer_timer = maxf(0.0, _attack_buffer_timer - delta)
	if Input.is_action_just_pressed(&"interact"):
		_interact_buffer_timer = INTERACT_BUFFER
	else:
		_interact_buffer_timer = maxf(0.0, _interact_buffer_timer - delta)
	if Input.is_action_just_pressed(&"dash"):
		_dash_buffer_timer = DASH_BUFFER
	else:
		_dash_buffer_timer = maxf(0.0, _dash_buffer_timer - delta)


## --- Touch API (called by touch controls) ---

func set_touch_move(v: Vector2) -> void:
	_touch_move = v


func set_touch_jump_held(held: bool) -> void:
	_touch_jump_held = held


func set_touch_heal_held(held: bool) -> void:
	_touch_heal_held = held


func press_jump() -> void:
	"""Touch jump button pressed: buffer a jump immediately."""
	_jump_buffer_timer = JUMP_BUFFER


func press_attack() -> void:
	"""Touch attack button pressed: buffer an attack immediately."""
	_attack_buffer_timer = ATTACK_BUFFER


func press_interact() -> void:
	"""Touch interact button pressed: buffer an interaction immediately."""
	_interact_buffer_timer = INTERACT_BUFFER


func press_dash() -> void:
	"""Touch dash button pressed: buffer a dash immediately."""
	_dash_buffer_timer = DASH_BUFFER


func notify_jump_released() -> void:
	_touch_jump_released = true


## --- Gameplay API ---

func get_move_axis() -> float:
	"""Horizontal move intent -1..1, strongest source wins."""
	var axis := Input.get_axis(&"move_left", &"move_right")
	if absf(_touch_move.x) > absf(axis):
		axis = _touch_move.x
	return clampf(axis, -1.0, 1.0)


func get_aim_vector() -> Vector2:
	"""4-way aim intent for attacks. Touch joystick merges with keyboard."""
	var v := Input.get_vector(&"move_left", &"move_right", &"aim_up", &"aim_down")
	if _touch_move.length() > v.length():
		v = _touch_move
	return v


func is_jump_held() -> bool:
	return Input.is_action_pressed(&"jump") or _touch_jump_held


func is_heal_held() -> bool:
	return Input.is_action_pressed(&"heal") or _touch_heal_held


func is_jump_just_released() -> bool:
	if Input.is_action_just_released(&"jump"):
		return true
	if _touch_jump_released:
		_touch_jump_released = false
		return true
	return false


func consume_jump_buffer() -> bool:
	"""True once per buffered jump press. Player calls each physics frame."""
	if _jump_buffer_timer > 0.0:
		_jump_buffer_timer = 0.0
		return true
	return false


func consume_attack_buffer() -> bool:
	"""True once per buffered attack press. Player calls each physics frame."""
	if _attack_buffer_timer > 0.0:
		_attack_buffer_timer = 0.0
		return true
	return false


func consume_interact_buffer() -> bool:
	"""True once per buffered interact press. Hearths call each frame."""
	if _interact_buffer_timer > 0.0:
		_interact_buffer_timer = 0.0
		return true
	return false


func consume_dash_buffer() -> bool:
	"""True once per buffered dash press. Player calls each physics frame."""
	if _dash_buffer_timer > 0.0:
		_dash_buffer_timer = 0.0
		return true
	return false
