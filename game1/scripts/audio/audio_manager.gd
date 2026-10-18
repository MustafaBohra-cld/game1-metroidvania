extends Node
## AudioManager — central audio hub (autoload).
## Pre-generates all procedural SFX at startup, runs the generative music,
## and owns a small AudioStreamPlayer pool for polyphonic SFX.
##
## Usage from any script (autoload is globally accessible):
##   AudioManager.play_sfx("slash")
##   AudioManager.play_sfx("hit", 1.0, -6.0)  # pitch, volume_db
##   AudioManager.play_music("boss")          # "ambient" | "boss" | "stop"
##   AudioManager.set_music_volume(-12.0)
##   AudioManager.set_sfx_volume(-6.0)

const POOL_SIZE := 10
const SfxSynthLib := preload("res://scripts/audio/sfx_synth.gd")
const MusicGenScript := preload("res://scripts/audio/music_gen.gd")

var _sfx: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _pool_i := 0
var _music: MusicGenScript
var _sfx_bus := 0
var _music_bus := 0


func _ready() -> void:
	_sfx_bus = _make_bus("SFX")
	_music_bus = _make_bus("Music")
	_sfx = SfxSynthLib.make_all()
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
	_music = MusicGenScript.new()
	add_child(_music)
	_music.start("ambient")


func _make_bus(bus_name: String) -> int:
	var idx := AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, bus_name)
	return idx


## Play a pre-generated SFX. pitch ~1.0, vol_db 0.0. Slight random pitch
## variation keeps repeated sounds from feeling mechanical.
func play_sfx(sfx_name: String, pitch: float = 1.0, vol_db: float = 0.0) -> void:
	if not _sfx.has(sfx_name):
		push_warning("AudioManager: unknown sfx '%s'" % sfx_name)
		return
	var p := _pool[_pool_i]
	_pool_i = (_pool_i + 1) % POOL_SIZE
	p.stream = _sfx[sfx_name] as AudioStreamWAV
	p.pitch_scale = pitch * randf_range(0.96, 1.04)
	p.volume_db = vol_db
	p.play()


## Switch music: "ambient", "boss", or "stop".
func play_music(track: String) -> void:
	if _music == null:
		return
	match track:
		"ambient", "boss":
			_music.set_mode(track)
		"stop":
			_music.stop()
		_:
			push_warning("AudioManager: unknown music track '%s'" % track)


func set_music_volume(db: float) -> void:
	AudioServer.set_bus_volume_db(_music_bus, db)


func set_sfx_volume(db: float) -> void:
	AudioServer.set_bus_volume_db(_sfx_bus, db)


func has_sfx(sfx_name: String) -> bool:
	return _sfx.has(sfx_name)
