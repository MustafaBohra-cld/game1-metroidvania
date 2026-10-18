extends CanvasLayer
## TouchControls — Mobile module touch UI root.
## Floating joystick (left) + jump / attack / heal buttons (bottom-right).

const JoystickScript := preload("res://scripts/modules/mobile/virtual_joystick.gd")
const ButtonScript := preload("res://scripts/modules/mobile/touch_button.gd")

const BTN := 76.0
const GAP := 16.0
const MARGIN := 120.0

var _gs: Node
var _dash_btn: Control


func _ready() -> void:
	_gs = get_node("/root/GameState")
	var joy: Control = JoystickScript.new()
	joy.name = "Joystick"
	add_child(joy)

	# Bottom-right cluster: [dash] [attack] [jump], heal above jump.
	# Interact sits top-right; pause sits top-center.
	_add_button(&"dash", MARGIN + 2.0 * (BTN + GAP), MARGIN)
	_add_button(&"attack", MARGIN + BTN + GAP, MARGIN)
	_add_button(&"jump", MARGIN, MARGIN)
	_add_button(&"heal", MARGIN, MARGIN + BTN + GAP)
	_add_top_button(&"interact")
	_add_top_center_button(&"pause")


func _process(_delta: float) -> void:
	# Dash button appears only once the Ember Dash ability is unlocked.
	if _dash_btn != null:
		_dash_btn.visible = _gs.has_ability("dash")


func _add_button(action: StringName, from_right: float, from_bottom: float) -> void:
	var b: Control = ButtonScript.new()
	b.name = action.capitalize() + "Button"
	b.action_name = action
	b.anchor_left = 1.0
	b.anchor_top = 1.0
	b.anchor_right = 1.0
	b.anchor_bottom = 1.0
	b.offset_left = -from_right - BTN
	b.offset_top = -from_bottom - BTN
	b.offset_right = -from_right
	b.offset_bottom = -from_bottom
	add_child(b)
	if action == &"dash":
		_dash_btn = b
		b.visible = false


func _add_top_button(action: StringName) -> void:
	var b: Control = ButtonScript.new()
	b.name = action.capitalize() + "Button"
	b.action_name = action
	b.anchor_left = 1.0
	b.anchor_top = 0.0
	b.anchor_right = 1.0
	b.anchor_bottom = 0.0
	b.offset_left = -MARGIN - BTN
	b.offset_top = MARGIN
	b.offset_right = -MARGIN
	b.offset_bottom = MARGIN + BTN
	add_child(b)


func _add_top_center_button(action: StringName) -> void:
	var b: Control = ButtonScript.new()
	b.name = action.capitalize() + "Button"
	b.action_name = action
	b.anchor_left = 0.5
	b.anchor_top = 0.0
	b.anchor_right = 0.5
	b.anchor_bottom = 0.0
	b.offset_left = -32.0
	b.offset_top = 24.0
	b.offset_right = 32.0
	b.offset_bottom = 88.0
	add_child(b)
