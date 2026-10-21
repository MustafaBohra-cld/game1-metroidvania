extends Node
## World — World module (M5). Room-to-room travel.
## Doors call goto_room(); the new room's room.gd consumes the spawn tag.
## Tunnel transitions use a quick fade to feel like walking through, not teleporting.

## DEBUG ROOM SELECT: Set to a room filename (e.g. "f2_shaft") to boot directly there.
## Empty string = normal start from the beginning.
## Edit this line, save, redeploy — no other files needed.
const DEBUG_START_ROOM := ""

var pending_spawn := ""
var _fade: ColorRect


func get_debug_start_room() -> String:
	var room_name := DEBUG_START_ROOM.strip_edges()
	if room_name == "":
		return ""
	if not room_name.ends_with(".tscn"):
		room_name = "res://scenes/rooms/" + room_name + ".tscn"
	if not ResourceLoader.exists(room_name):
		push_warning("Debug start room not found: " + room_name)
		return ""
	return room_name


func _ready() -> void:
	# Fade overlay for tunnel transitions
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)


func goto_room(scene_path: String, spawn_tag: String) -> void:
	pending_spawn = spawn_tag
	# Quick fade out, change scene, fade in — feels like a tunnel, not a door
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, 0.25)
	tween.tween_callback(_do_change.bind(scene_path))
	tween.tween_property(_fade, "color:a", 0.0, 0.25)


func _do_change(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)


func consume_spawn() -> String:
	var s := pending_spawn
	pending_spawn = ""
	return s
