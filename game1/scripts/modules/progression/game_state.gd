extends Node
## GameState — autoload singleton (Progression module facade).
## Owns currency, relics/loadout, abilities, flags, hearth, echo.
## Gameplay code reads/writes through here, never its own copies.

const RELICS := {
	"longstride": {
		"name": "Longstride", "desc": "+12% move speed",
		"stat": "move_speed", "mult": 1.12,
	},
	"deep_pockets": {
		"name": "Deep Pockets", "desc": "+50% cinders from kills",
		"stat": "currency_gain", "mult": 1.5,
	},
	"thornplate": {
		"name": "Thornplate", "desc": "Reflect 1 contact damage",
		"stat": "thorns", "mult": 1.0,
	},
}

var currency := 0
var abilities: Array[String] = []
var flags := {}
var relics_owned: Array[String] = []
var equipped: Array[String] = []
var sockets_total := 3
var last_hearth := {"zone": "test", "room": "main", "pos": [400.0, 480.0]}
var echo_amount := 0
var echo_pos := Vector2.ZERO
var playtime_s := 0.0


func _process(delta: float) -> void:
	playtime_s += delta


# --- Currency ---

func add_currency(n: int) -> void:
	currency = maxi(0, currency + n)
	if n > 0:
		get_node("/root/AudioManager").play_sfx("pickup")


func spend_currency(n: int) -> bool:
	if currency < n:
		return false
	currency -= n
	return true


# --- Abilities & flags ---

func unlock_ability(id: String) -> void:
	if not abilities.has(id):
		abilities.append(id)


func has_ability(id: String) -> bool:
	return abilities.has(id)


func set_flag(key: String, value: Variant) -> void:
	flags[key] = value


func get_flag(key: String, default: Variant = null) -> Variant:
	return flags.get(key, default)


# --- Relics ---

func give_relic(id: String) -> void:
	if not relics_owned.has(id) and RELICS.has(id):
		relics_owned.append(id)


func equip_relic(id: String) -> int:
	"""0 ok, 1 no free socket, 2 not owned or already equipped."""
	if not relics_owned.has(id) or equipped.has(id):
		return 2
	if equipped.size() >= sockets_total:
		return 1
	equipped.append(id)
	return 0


func unequip_relic(id: String) -> void:
	equipped.erase(id)


func get_stat(stat: String) -> float:
	"""Relic-modified stat multiplier. Single source of truth."""
	var mult := 1.0
	for id: String in equipped:
		var def: Dictionary = RELICS.get(id, {})
		if def.get("stat") == stat:
			mult *= float(def.get("mult", 1.0))
	return mult


func relic_name(id: String) -> String:
	return str(RELICS.get(id, {}).get("name", id))


func relic_desc(id: String) -> String:
	return str(RELICS.get(id, {}).get("desc", ""))


# --- Hearth & echo ---

func set_hearth(zone: String, room: String, pos: Vector2) -> void:
	last_hearth = {"zone": zone, "room": room, "pos": [pos.x, pos.y]}


func get_hearth_pos() -> Vector2:
	var p: Array = last_hearth.get("pos", [200.0, 400.0])
	return Vector2(float(p[0]), float(p[1]))


func drop_echo(amount: int, pos: Vector2) -> void:
	echo_amount = amount
	echo_pos = pos


func clear_echo() -> void:
	echo_amount = 0
