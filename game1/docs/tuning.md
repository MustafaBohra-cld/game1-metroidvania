# Tuning: M1 movement

All movement numbers live here. Change the constant in
`scripts/player/player.gd`, never magic numbers in logic.

| constant | value | what it does |
|---|---|---|
| MOVE_SPEED | 260 px/s | top run speed |
| ACCEL | 2000 px/s² | how fast you reach top speed |
| FRICTION | 2200 px/s² | how fast you stop (snappier than accel = tight) |
| JUMP_VELOCITY | −540 px/s | jump strength |
| GRAVITY | 1350 px/s² | falls faster than default 980 = less floaty |
| MAX_FALL | 900 px/s | terminal velocity |
| COYOTE_TIME | 0.10 s | jump still works just after leaving a ledge |
| JUMP_BUFFER | 0.12 s | jump pressed just before landing still fires |
| JUMP_CUT | 0.45 | release jump early → upward speed × 0.45 (tap = hop) |

Joystick: base 220px, knob 96px, deadzone 0.15, floating origin in left 45%.
Jump button: 76px circle, bottom-right.

## Device feel checklist (his thumbs)

1. Run left/right across the room — does it reach top speed too slowly?
2. Tap jump vs hold jump — hop vs full jump should feel clearly different.
3. Run off a platform and press jump late — coyote should save you.
4. Mash jump before landing — buffer should fire it.
5. Joystick: does the stick appear under your thumb? Drift?

Report in plain words ("jump feels floaty", "turns too slow") and I convert
to numbers.

## M2 combat

| constant | value | what it does |
|---|---|---|
| ATTACK_TIME | 0.18 s | how long the slash hitbox stays active |
| ATTACK_CD | 0.38 s | time between slashes |
| RESOURCE_PER_HIT | 8 | meter gain per landed slash (max 99) |
| HEAL_COST | 33 | resource cost per heal |
| HEAL_TIME | 0.8 s | channel time; moving or releasing cancels |
| POGO_BOUNCE | 0.85 | down-slash bounce = 85% of jump velocity |
| Crawler HP | 3 | Ash Crawler health |
| Crawler SPEED | 60 px/s | patrol speed |
| Player HP | 5 | health pips |

Aim: attack aims with the joystick/keyboard direction at press — up, down
(airborne only, pogo), or facing. Keyboard: J/X attack, K/C heal (hold).

## M3 checkpoint loop

- Hearth: stand in the fire zone + press E (keyboard) or the E button
  (top-right) → Rest panel: Rest (save + full heal + respawn enemies),
  Relics (tap to equip/unequip), Leave.
- Saves: `user://save_slot_0.json`, atomic write + .bak; auto-loads on boot;
  also saves when the app loses focus (Android can kill anytime).
- Relics (2): Longstride +12% move speed; Deep Pockets +50% cinders.
  3 sockets; pickups auto-equip when a socket is free.
- Currency: crawlers drop 3–6 cinders; HUD shows count top-right.
- Death: cinders drop as an echo shade where you died; kill it to reclaim.
  Die again first → the shade (and cinders) are gone for good.

## Level design rule (learned M3)

Max jump height = JUMP_VELOCITY² / (2 × GRAVITY) = 540² / 2700 ≈ **108px**.
Keep every vertical platform step **≤ 90px** (80px comfortable). The original
M3 test room used 130–160px steps — unreachable, fixed the same night.

## M4 boss + dash

| constant | value | what it does |
|---|---|---|
| Cinder Maw HP | 24 | Z1 boss |
| LUNGE_SPEED | 750 px/s | boss lunge |
| DASH_SPEED | 700 px/s | Ember Dash burst |
| DASH_TIME | 0.18 s | dash duration (i-frames + 0.15s) |
| DASH_CD | 1.0 s | dash cooldown |
| Boss reward | Ember Dash + 30 cinders | unlocks dash button + dash-gates |

Boss loop: dormant → emerge → idle → telegraph (flash) → lunge → vulnerable
(2.5s, grey) → burrow → reposition near player → emerge. Keyboard: L/Shift
dash. Dash-gate: cracked seal breaks only while dashing.

## M5a Foundry + cling

| constant | value | what it does |
|---|---|---|
| CLING_SLIDE | 70 px/s | wall-slide fall speed while clinging |
| WALLKICK_X | 320 px/s | horizontal wall-kick velocity |
| Wall-kick jump | 513 px/s up | ≈ 97px per kick — chimney shafts need kicks ≤ 90px apart vertically |
| Rust Drone | 3 HP, 1 dmg | hover → windup (0.5s) → dive (420 px/s) → recover |

Rooms travel via the World autoload: doors call `World.goto_room(scene, tag)`,
room.gd consumes the tag and places the player at `Spawns/Spawn_<tag>`.
Rule: never put a Spawn_default inside a door's trigger (f1 had this bug —
spawn bounced the player straight back through the door).
