class_name MusicGen
extends Node
## MusicGen — procedural dark-ambient music for Project Ember.
## Real-time synthesis via AudioStreamGenerator (no audio files, infinite loop).
##
## Modes:
##   "ambient" — low drone + sparse ember plinks (Zone exploration)
##   "boss"    — brighter drone + heartbeat pulse + tense plinks (Boss fights)
## Mode changes crossfade smoothly (~2s). Call start(mode) once, set_mode() to switch.

const RATE := 22050
const PENTA := [220.0, 261.63, 293.66, 329.63, 392.0, 440.0] # A minor pentatonic
const TENSION := [311.13, 466.16] # Eb, Bb — dissonant color for boss mode

var _player: AudioStreamPlayer
var _pb: AudioStreamGeneratorPlayback
var _mode := "ambient"
var _blend := 0.0 # 0 = ambient, 1 = boss (smoothed)

var _t := 0.0
var _ph1 := 0.0
var _ph2 := 0.0
var _ph3 := 0.0
var _php := 0.0
var _lp := 0.0
var _next_plink := 4.0
var _plinks: Array = [] # each: [freq, start_t, dur, amp]


func start(mode: String = "ambient") -> void:
	_mode = mode
	_blend = 1.0 if mode == "boss" else 0.0
	_player = AudioStreamPlayer.new()
	_player.bus = "Music"
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = RATE
	gen.buffer_length = 0.6
	_player.stream = gen
	add_child(_player)
	_player.play()
	_pb = _player.get_stream_playback() as AudioStreamGeneratorPlayback


func set_mode(mode: String) -> void:
	_mode = mode


func stop() -> void:
	if _player:
		_player.stop()


func _process(_delta: float) -> void:
	if _pb == null or not _player.playing:
		return
	# Smooth mode crossfade.
	var target := 1.0 if _mode == "boss" else 0.0
	_blend = move_toward(_blend, target, _delta * 0.5)
	# Schedule ember plinks.
	if _t >= _next_plink:
		_spawn_plink()
		var gap := randf_range(4.0, 9.0) if _blend < 0.5 else randf_range(1.5, 4.0)
		_next_plink = _t + gap
	# Fill the generator buffer.
	var avail := _pb.get_frames_available()
	for i in avail:
		var s := _sample()
		_pb.push_frame(Vector2(s, s))
		_t += 1.0 / RATE


func _spawn_plink() -> void:
	var pool: Array = PENTA.duplicate()
	if _blend > 0.3 and randf() < 0.35:
		pool.append_array(TENSION)
	var f: float = pool[randi() % pool.size()]
	var amp := randf_range(0.05, 0.12) * (1.0 + _blend * 0.6)
	_plinks.append([f, _t, randf_range(1.6, 2.6), amp])


func _sample() -> float:
	# Drone: 55/82.5Hz ambient -> 65.4/98Hz boss.
	var f1 := lerpf(55.0, 65.41, _blend)
	var f2 := lerpf(82.5, 98.0, _blend)
	_ph1 += TAU * f1 / RATE
	_ph2 += TAU * f2 / RATE
	_ph3 += TAU * f1 * 2.0 / RATE
	var lfo := 0.7 + 0.3 * sin(TAU * 0.05 * _t)
	var drone := (sin(_ph1) * 0.5 + sin(_ph2) * 0.3 + sin(_ph3) * 0.15) * lfo
	# Airy noise wash, slow breathing.
	_lp += (randf_range(-1.0, 1.0) - _lp) * 0.02
	var air := _lp * 2.5 * (0.5 + 0.5 * sin(TAU * 0.033 * _t + 1.0)) * 0.35
	# Boss heartbeat pulse (~2.2Hz thump).
	_php += TAU * 58.0 / RATE
	var gate := pow(0.5 + 0.5 * sin(TAU * 2.2 * _t), 4.0)
	var pulse := sin(_php) * gate * _blend * 0.8
	# Active plinks with exponential decay.
	var plink_sum := 0.0
	for idx in range(_plinks.size() - 1, -1, -1):
		var p: Array = _plinks[idx]
		var age: float = _t - p[1]
		if age >= p[2]:
			_plinks.remove_at(idx)
			continue
		var f: float = p[0]
		var env := exp(-age * 2.5)
		plink_sum += (sin(TAU * f * age) + 0.3 * sin(TAU * f * 2.0 * age)) * env * p[3]
	var total := (drone * 0.5 + air * 0.5 + pulse * 0.5 + plink_sum) * 0.35
	return clampf(total, -1.0, 1.0)
