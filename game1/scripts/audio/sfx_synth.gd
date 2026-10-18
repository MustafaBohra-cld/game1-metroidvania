class_name SfxSynth
extends RefCounted
## SfxSynth — procedural SFX library for Project Ember.
## Generates all sound effects as AudioStreamWAV in code (no audio files).
## Call make_all() once at startup; it returns {name: AudioStreamWAV}.
##
## To add a new SFX:
##   1. Write a static func _build_<name>() -> PackedFloat32Array (mono, -1..1).
##   2. Register it in make_all():  out["<name>"] = _to_wav(_build_<name>())

const RATE := 22050


static func make_all() -> Dictionary:
	var out := {}
	out["slash"] = _to_wav(_build_slash())
	out["hit"] = _to_wav(_build_hit())
	out["enemy_die"] = _to_wav(_build_enemy_die())
	out["player_hurt"] = _to_wav(_build_player_hurt())
	out["jump"] = _to_wav(_build_jump())
	out["wallkick"] = _to_wav(_build_wallkick())
	out["dash"] = _to_wav(_build_dash())
	out["pickup"] = _to_wav(_build_pickup())
	out["hearth"] = _to_wav(_build_hearth())
	out["boss_roar"] = _to_wav(_build_boss_roar())
	out["ui_click"] = _to_wav(_build_ui_click())
	return out


# --- WAV packing -----------------------------------------------------------

static func _to_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		var v := int(clampf(samples[i], -1.0, 1.0) * 32767.0)
		bytes[i * 2] = v & 0xFF
		bytes[i * 2 + 1] = (v >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	return wav


static func _noise() -> float:
	return randf_range(-1.0, 1.0)


## Frequency-swept sine with phase accumulation (click-free).
static func _sweep(dur: float, f0: float, f1: float, amp: float, decay: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var f := lerpf(f0, f1, t / dur)
		phase += TAU * f / RATE
		s[i] = sin(phase) * amp * exp(-t * decay)
	return s


static func _mix_into(dst: PackedFloat32Array, src: PackedFloat32Array, gain: float = 1.0) -> void:
	var n := mini(dst.size(), src.size())
	for i in n:
		dst[i] = clampf(dst[i] + src[i] * gain, -1.0, 1.0)


# --- SFX builders (all return mono -1..1) -----------------------------------

## Quick whoosh: noise + downward pitch sweep.
static func _build_slash() -> PackedFloat32Array:
	var dur := 0.18
	var n := int(dur * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	var phase := 0.0
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		var k := t / dur
		var f := lerpf(1600.0, 320.0, k)
		phase += TAU * f / RATE
		var x := _noise()
		lp += (x - lp) * lerpf(0.9, 0.15, k) # closing filter = whoosh
		var env := exp(-t * 16.0)
		s[i] = (lp * 0.7 + sin(phase) * 0.35) * env
	return s


## Impact thud: low sine + click.
static func _build_hit() -> PackedFloat32Array:
	var dur := 0.16
	var n := int(dur * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / RATE
		var thump := sin(TAU * 110.0 * t) * exp(-t * 28.0)
		var click := _noise() * exp(-t * 70.0) * 0.5
		s[i] = thump * 0.9 + click
	return s


## Pop + fade: downward sweep + noise tail.
static func _build_enemy_die() -> PackedFloat32Array:
	var dur := 0.35
	var s := _sweep(dur, 430.0, 70.0, 0.8, 9.0)
	var n := s.size()
	for i in n:
		var t := float(i) / RATE
		s[i] += _noise() * exp(-t * 13.0) * 0.3
		s[i] = clampf(s[i], -1.0, 1.0)
	return s


## Harsh buzz: stacked harmonics + noise.
static func _build_player_hurt() -> PackedFloat32Array:
	var dur := 0.3
	var n := int(dur * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / RATE
		var env := exp(-t * 11.0)
		var buzz := sin(TAU * 160.0 * t) + 0.5 * sin(TAU * 320.0 * t) + 0.25 * sin(TAU * 480.0 * t)
		s[i] = (buzz * 0.45 + _noise() * 0.3 * exp(-t * 9.0)) * env
	return s


## Soft upward blip.
static func _build_jump() -> PackedFloat32Array:
	return _sweep(0.13, 280.0, 640.0, 0.5, 16.0)


## Sharp snap: noise burst + high blip.
static func _build_wallkick() -> PackedFloat32Array:
	var dur := 0.1
	var n := int(dur * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / RATE
		s[i] = _noise() * exp(-t * 65.0) * 0.7 + sin(TAU * 900.0 * t) * exp(-t * 45.0) * 0.4
	return s


## Airy whoosh: swelling noise + rising tone.
static func _build_dash() -> PackedFloat32Array:
	var dur := 0.28
	var n := int(dur * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var k := t / dur
		var env := pow(sin(PI * clampf(k, 0.0, 1.0)), 0.7)
		var f := lerpf(220.0, 950.0, k)
		phase += TAU * f / RATE
		s[i] = (_noise() * 0.55 + sin(phase) * 0.25) * env
	return s


## Coin-like ding: two sines, B5 then E6.
static func _build_pickup() -> PackedFloat32Array:
	var dur := 0.3
	var n := int(dur * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / RATE
		var v := 0.0
		if t < 0.12:
			v = (sin(TAU * 987.77 * t) + 0.3 * sin(TAU * 1975.5 * t)) * exp(-t * 18.0)
		else:
			var t2 := t - 0.12
			v = (sin(TAU * 1318.5 * t2) + 0.3 * sin(TAU * 2637.0 * t2)) * exp(-t2 * 14.0)
		s[i] = v * 0.55
	return s


## Warm chord swell: low major-ish stack, slow attack.
static func _build_hearth() -> PackedFloat32Array:
	var dur := 1.4
	var n := int(dur * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	var freqs := [110.0, 164.81, 220.0, 277.18]
	for i in n:
		var t := float(i) / RATE
		var attack := clampf(t / 0.45, 0.0, 1.0)
		var rel := exp(-maxf(0.0, t - 0.55) * 2.2)
		var v := 0.0
		for f in freqs:
			v += sin(TAU * f * t)
		v = v / freqs.size()
		v += 0.12 * sin(TAU * 880.0 * t) * sin(TAU * 0.8 * t)
		s[i] = v * attack * rel * 0.8
	return s


## Low rumble + growling noise.
static func _build_boss_roar() -> PackedFloat32Array:
	var dur := 1.6
	var n := int(dur * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		var k := t / dur
		var env := sin(PI * clampf(k, 0.0, 1.0))
		var growl := 0.6 + 0.4 * sin(TAU * 7.0 * t)
		var rumble := (sin(TAU * 48.0 * t) * 0.7 + sin(TAU * 96.0 * t) * 0.3) * growl
		lp += (_noise() - lp) * 0.08
		s[i] = (rumble * 0.8 + lp * 1.6) * env * 0.85
	return s


## Tiny UI blip.
static func _build_ui_click() -> PackedFloat32Array:
	return _sweep(0.07, 1250.0, 900.0, 0.4, 70.0)
