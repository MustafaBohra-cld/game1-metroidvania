extends Node2D
## Room — World module (M5). Generic room root shared by every room scene.
## Places the player at the door's spawn tag (or the default spawn),
## applies camera limits, spawns the echo shade, handles r1 boss persistence.

const EchoShadeScene := preload("res://scenes/echo_shade.tscn")

@export var cam_bounds := Rect2(0, 0, 3200, 720)


func _ready() -> void:
	var gs := get_node("/root/GameState")
	var ss := get_node("/root/SaveSystem")
	var world := get_node("/root/World")
	# DEBUG: Jump straight to test room (see debug_start.txt).
	# Only triggers on the boot scene (main.tscn) to avoid redirect loops.
	var cur_path := get_tree().current_scene.scene_file_path if get_tree().current_scene else ""
	if cur_path.ends_with("main.tscn"):
		var debug_room: String = world.get_debug_start_room()
		if debug_room != "":
			# DEBUG: Grant movement abilities so the room is testable in isolation
			gs.unlock_ability("cling")
			gs.unlock_ability("dash")
			world.pending_spawn = ""
			get_tree().call_deferred("change_scene_to_file", debug_room)
			return
	if ss.has_save():
		ss.load_game()
	var tag: String = world.consume_spawn()
	var spawn := get_node_or_null("Spawns/Spawn_default")
	if tag != "":
		spawn = get_node_or_null("Spawns/Spawn_" + tag)
	if spawn != null:
		$Player.position = spawn.position
	else:
		$Player.position = gs.get_hearth_pos()
	# Camera limits for this room.
	var cam: Camera2D = $Player.get_node("Camera")
	cam.limit_left = int(cam_bounds.position.x)
	cam.limit_top = int(cam_bounds.position.y)
	cam.limit_right = int(cam_bounds.end.x)
	cam.limit_bottom = int(cam_bounds.end.y)
	# Boss stays dead across reloads (r1 only).
	if gs.get_flag("maw_dead", false):
		var maw := get_node_or_null("CinderMaw")
		if maw != null:
			maw.queue_free()
		# Arena forward gate stays open after boss defeat (tun_arena).
		var gatefwd := get_node_or_null("GateFwd")
		if gatefwd != null:
			gatefwd.queue_free()
	if gs.echo_amount > 0:
		var shade := EchoShadeScene.instantiate()
		shade.position = gs.echo_pos
		add_child(shade)
	# Auto-add parallax live background based on room zone
	_add_parallax_bg()


func _add_parallax_bg() -> void:
	var scene_path: String = get_tree().current_scene.scene_file_path if get_tree().current_scene else ""
	var theme := "emberfall"
	if "f1_" in scene_path or "f2_" in scene_path or "f3_" in scene_path or "f4_" in scene_path or "f5_" in scene_path or "f6_" in scene_path:
		theme = "tideglass"
	elif "tun_" in scene_path:
		theme = "emberfall"
	else:
		return  # Hub/main uses its own bg
	var parallax_script := load("res://scripts/fx/parallax_zone.gd") as Script
	var pb := ParallaxBackground.new()
	pb.set_script(parallax_script)
	pb.set("zone_theme", theme)
	# Add at the back (before other nodes)
	add_child(pb)
	move_child(pb, 0)
