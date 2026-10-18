extends CanvasLayer
## RestPanel — Mobile module. Hearth menu: Rest / Relics / Leave.
## Pauses the game while open. Built in code (M3-simple).

var _hearth: Node2D
var _dim: ColorRect
var _panel: PanelContainer
var _title: Label
var _list: VBoxContainer
var _btn_rest: Button
var _btn_relics: Button
var _btn_back: Button
var _btn_leave: Button
var _showing_relics := false


func _ready() -> void:
	add_to_group("rest_panel")
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	_dim = ColorRect.new()
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(0, 0, 0, 0.6)
	add_child(_dim)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(520, 420)
	_panel.offset_left = -260
	_panel.offset_top = -210
	_panel.offset_right = 260
	_panel.offset_bottom = 210
	add_child(_panel)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 12)
	_panel.add_child(_list)

	_title = Label.new()
	_title.text = "HEARTH"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_list.add_child(_title)

	_btn_rest = Button.new()
	_btn_rest.text = "Rest (save + heal + respawn)"
	_btn_rest.pressed.connect(_on_rest_pressed)
	_list.add_child(_btn_rest)

	_btn_relics = Button.new()
	_btn_relics.text = "Relics"
	_btn_relics.pressed.connect(_on_relics_pressed)
	_list.add_child(_btn_relics)

	_btn_back = Button.new()
	_btn_back.text = "Back"
	_btn_back.pressed.connect(_show_menu)
	_btn_back.visible = false
	_list.add_child(_btn_back)

	_btn_leave = Button.new()
	_btn_leave.text = "Leave"
	_btn_leave.pressed.connect(close)
	_list.add_child(_btn_leave)


func open_rest(hearth: Node2D) -> void:
	get_node("/root/AudioManager").play_sfx("ui_click")
	_hearth = hearth
	_showing_relics = false
	_show_menu()
	visible = true
	get_tree().paused = true


func close() -> void:
	get_node("/root/AudioManager").play_sfx("ui_click")
	visible = false
	get_tree().paused = false


func _show_menu() -> void:
	get_node("/root/AudioManager").play_sfx("ui_click")
	_showing_relics = false
	_title.text = "HEARTH"
	_btn_rest.visible = true
	_btn_relics.visible = true
	_btn_back.visible = false
	_btn_leave.visible = true
	_clear_relic_rows()


func _on_rest_pressed() -> void:
	get_node("/root/AudioManager").play_sfx("ui_click")
	if _hearth and _hearth.has_method("rest"):
		_hearth.rest()


func _on_relics_pressed() -> void:
	get_node("/root/AudioManager").play_sfx("ui_click")
	_showing_relics = true
	_title.text = "RELICS — tap to equip/unequip"
	_btn_rest.visible = false
	_btn_relics.visible = false
	_btn_back.visible = true
	_btn_leave.visible = false
	_clear_relic_rows()
	var gs := get_node("/root/GameState")
	for id: String in gs.relics_owned:
		var row := Button.new()
		var tag := "[E] " if gs.equipped.has(id) else "[ ] "
		row.text = tag + gs.relic_name(id) + " — " + gs.relic_desc(id)
		row.pressed.connect(_on_relic_toggled.bind(id))
		row.name = "relic_" + id
		_list.add_child(row)
		_list.move_child(row, 1)


func _on_relic_toggled(id: String) -> void:
	var gs := get_node("/root/GameState")
	if gs.equipped.has(id):
		gs.unequip_relic(id)
	else:
		var code: int = gs.equip_relic(id)
		if code == 1:
			var hud := get_tree().get_first_node_in_group("hud")
			if hud and hud.has_method("show_toast"):
				hud.show_toast("No free socket")
	get_node("/root/SaveSystem").save_game()
	_on_relics_pressed() # refresh


func _clear_relic_rows() -> void:
	for child in _list.get_children():
		if child.name.begins_with("relic_"):
			child.queue_free()
