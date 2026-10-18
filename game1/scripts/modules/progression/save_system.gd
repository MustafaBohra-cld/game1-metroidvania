extends Node
## SaveSystem — autoload singleton (inside Progression module).
## Versioned JSON saves, atomic writes (tmp + rename), .bak fallback.
## Schema: replica/architecture.md "Save schema (v1)".

const SAVE_VERSION := 1
const SLOT_PATH := "user://save_slot_0.json"


func _notification(what: int) -> void:
	# Android can kill the app on focus loss. Persist first.
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		save_game()


func has_save() -> bool:
	return FileAccess.file_exists(SLOT_PATH)


func save_game() -> int:
	"""0 ok, 1 write failed. Atomic: write tmp, rename over live, keep .bak."""
	var gs := get_node("/root/GameState")
	var player := get_tree().get_first_node_in_group("player")
	var data := {
		"version": SAVE_VERSION,
		"saved_at_unix": int(Time.get_unix_time_from_system()),
		"player": {
			"health_max": 5,
			"health": player.get_health() if player else 5,
			"resource": player.resource if player else 0,
			"pos": [player.global_position.x, player.global_position.y] if player else [200.0, 400.0],
			"abilities": gs.abilities,
			"playtime_s": int(gs.playtime_s),
		},
		"currency": gs.currency,
		"loadout": {"equipped": gs.equipped, "sockets_total": gs.sockets_total},
		"relics_owned": gs.relics_owned,
		"flags": gs.flags,
		"last_hearth": gs.last_hearth,
		"echo": {"amount": gs.echo_amount, "pos": [gs.echo_pos.x, gs.echo_pos.y]},
		"monetization": {"ads_removed": false, "owned_products": []},
	}
	var tmp := SLOT_PATH + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return 1
	f.store_string(JSON.stringify(data))
	f.close()
	if FileAccess.file_exists(SLOT_PATH):
		DirAccess.copy_absolute(SLOT_PATH, SLOT_PATH + ".bak")
	DirAccess.rename_absolute(tmp, SLOT_PATH)
	print("SaveSystem: saved.")
	return 0


func load_game() -> int:
	"""0 ok, 1 no save, 2 corrupt (tried .bak)."""
	var path := SLOT_PATH
	if not FileAccess.file_exists(path):
		return 1
	var data := _read(path)
	if data.is_empty():
		data = _read(SLOT_PATH + ".bak")
		if data.is_empty():
			return 2
	_apply(data)
	print("SaveSystem: loaded.")
	return 0


func _read(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if not (parsed is Dictionary):
		return {}
	var data := parsed as Dictionary
	if int(data.get("version", 0)) < 1:
		return {}
	return data # unknown fields ignored: forward tolerance


func _apply(data: Dictionary) -> void:
	var gs := get_node("/root/GameState")
	var p: Dictionary = data.get("player", {})
	gs.currency = int(data.get("currency", 0))
	gs.abilities.assign(data.get("player", {}).get("abilities", []))
	gs.relics_owned.assign(data.get("relics_owned", []))
	var loadout: Dictionary = data.get("loadout", {})
	gs.equipped.assign(loadout.get("equipped", []))
	gs.sockets_total = int(loadout.get("sockets_total", 3))
	gs.flags = data.get("flags", {})
	gs.last_hearth = data.get("last_hearth", gs.last_hearth)
	var echo: Dictionary = data.get("echo", {})
	gs.echo_amount = int(echo.get("amount", 0))
	var epos: Array = echo.get("pos", [0.0, 0.0])
	gs.echo_pos = Vector2(float(epos[0]), float(epos[1]))
	gs.playtime_s = float(p.get("playtime_s", 0))
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("apply_save"):
		player.apply_save(int(p.get("health", 5)), int(p.get("resource", 0)))
