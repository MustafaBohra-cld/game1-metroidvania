# Project Ember — Procedural Audio System

All audio is synthesized in code. No `.wav`/`.mp3` files — lightweight for Android.

## Files (`scripts/audio/`)

| File | Role |
|---|---|
| `sfx_synth.gd` | Static SFX factory. `make_all()` → `{name: AudioStreamWAV}` (22050 Hz, 16-bit mono) |
| `music_gen.gd` | Real-time dark-ambient generator via `AudioStreamGenerator`. Modes: `"ambient"`, `"boss"` |
| `audio_manager.gd` | Autoload. Pre-generates SFX, owns a 10-player SFX pool, runs music, manages `SFX`/`Music` buses |

## Usage

```gdscript
# Anywhere (autoload is global):
get_node("/root/AudioManager").play_sfx("slash")
get_node("/root/AudioManager").play_sfx("hit", 1.0, -6.0)  # pitch, volume_db
get_node("/root/AudioManager").play_music("boss")          # "ambient" | "boss" | "stop"
get_node("/root/AudioManager").set_music_volume(-12.0)
get_node("/root/AudioManager").set_sfx_volume(-6.0)
```

In `player.gd` the autoload is cached as `_am` in `_ready()` — use `_am.play_sfx(...)`.

## Adding a new SFX

1. In `sfx_synth.gd`, write a builder returning `PackedFloat32Array` (mono, −1..1):
   ```gdscript
   static func _build_mysound() -> PackedFloat32Array:
       var dur := 0.2
       var n := int(dur * RATE)
       var s := PackedFloat32Array()
       s.resize(n)
       for i in n:
           var t := float(i) / RATE
           s[i] = sin(TAU * 440.0 * t) * exp(-t * 10.0) * 0.6
       return s
   ```
2. Register it in `make_all()`: `out["mysound"] = _to_wav(_build_mysound())`
3. Play it: `get_node("/root/AudioManager").play_sfx("mysound")`

Helpers available: `_sweep(dur, f0, f1, amp, decay)` (click-free pitch sweep),
`_noise()`, `_mix_into(dst, src, gain)`.

## Current SFX (11)

`slash`, `hit`, `enemy_die`, `player_hurt`, `jump`, `wallkick`, `dash`,
`pickup`, `hearth`, `boss_roar`, `ui_click`

## Music

Generative, infinite (no loop point). Ambient: 55/82.5 Hz drone + airy noise +
sparse pentatonic plinks. Boss: drone rises to 65.4/98 Hz, 2.2 Hz heartbeat
pulse, tenser/faster plinks. Mode switches crossfade over ~2 s.

Boss music triggers in `cinder_maw.gd:activate()`, back to ambient in `_die()`.

## Performance

- SFX pre-generation: ~70 ms, ~215 KB total (one-time at boot)
- Music: ~6 `sin()` + 1 noise per frame at 22050 Hz — negligible
- SFX pool: 10 players, round-robin steal — no allocation at play time
