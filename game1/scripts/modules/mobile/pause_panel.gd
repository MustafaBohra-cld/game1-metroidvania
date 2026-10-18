extends CanvasLayer
## PausePanel — Mobile module. Minimal pause menu: Resume / Restart.

var _dim: ColorRect
var _panel: PanelContainer
var _list: VBoxContainer


func _ready() -> void:
	add_to_group("pause_panel")
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	_dim = ColorRect.new()
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(0, 0, 0, 0.6)
	add_child(_dim)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(420, 300)
	_panel.offset_left = -210
	_panel.offset_top = -150
	_panel.offset_right = 210
	_panel.offset_bottom = 150
	add_child(_panel)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 12)
	_panel.add_child(_list)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_list.add_child(title)

	var resume := Button.new()
	resume.text = "Resume"
	resume.pressed.connect(toggle)
	_list.add_child(resume)

	var restart := Button.new()
	restart.text = "Restart (reload room)"
	restart.pressed.connect(_on_restart)
	_list.add_child(restart)


func toggle() -> void:
	get_node("/root/AudioManager").play_sfx("ui_click")
	visible = not visible
	get_tree().paused = visible


func _on_restart() -> void:
	get_node("/root/AudioManager").play_sfx("ui_click")
	get_tree().paused = false
	get_tree().reload_current_scene()
