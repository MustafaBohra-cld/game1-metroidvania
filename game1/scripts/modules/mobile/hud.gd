extends CanvasLayer
## HUD — Mobile module. Health pips + resource meter + cinders + toasts.
## Polls the player/GameState each frame (M3-simple).

const DisplayScript := preload("res://scripts/modules/mobile/hud_display.gd")

var _display: Control
var _toast: Label
var _toast_timer := 0.0


func _ready() -> void:
	add_to_group("hud")
	layer = 5
	_display = DisplayScript.new()
	_display.set_anchors_preset(Control.PRESET_FULL_RECT)
	_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_display)

	_toast = Label.new()
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.offset_left = -400
	_toast.offset_right = 400
	_toast.offset_top = 110
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_size_override("font_size", 26)
	_toast.modulate = Color(1, 1, 1, 0)
	add_child(_toast)


func _process(delta: float) -> void:
	var p := get_tree().get_first_node_in_group("player")
	var gs := get_node("/root/GameState")
	if p != null and p.has_method("get_health"):
		_display.set_stats(p.get_health(), p.get_max_health(), p.resource, gs.currency)
	var b := get_tree().get_first_node_in_group("boss")
	if b != null and b.boss_active:
		_display.set_boss(b.boss_name, b.get_health(), b.get_max_health())
	else:
		_display.clear_boss()
	if _toast_timer > 0.0:
		_toast_timer -= delta
		_toast.modulate.a = clampf(_toast_timer, 0.0, 1.0)


func show_toast(text: String) -> void:
	_toast.text = text
	_toast_timer = 2.5
	_toast.modulate.a = 1.0
