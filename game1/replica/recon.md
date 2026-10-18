# Recon map: reference action-metroidvania (PC/console) → original mobile game

Scope: core loop + progression systems of a 2D action-metroidvania, rebuilt as an
original mobile game in Godot 4. Mechanics and flows only — clean-room style.
For: mustafa's GAME-01 (first game on the reusable mobile-game system)
Date: 2026-10-14

> IP rule: this document describes generic game-design patterns in original
> language. No names, characters, story, dialogue, art, or music from the
> reference. The Brand step gives everything its own identity; the sweep
> tool blocks anything that slips through.

## Sources

| # | source | URL | notes |
|---|---|---|---|
| 1 | official site | https://www.hollowknight.com/ | positioning, core loop in their words |
| 2 | developer site | https://teamcherry.com.au/ | studio source |
| 3 | fan wiki (gameplay) | https://hollowknight.fandom.com/wiki/Hollow_Knight_(game) | mechanics: exploration, maps, bosses, currency, death, resource |
| 4 | fan wiki (systems) | https://hollowknight.wiki | loadout system details (45 items, socket counts) |
| 5 | beginner's guide | https://www.noobfeed.com/articles/hollow-knight-beginners-guide-gameplay-tips | benches, loadout rules, heal economy, map shop |

## Core loop

Explore an interconnected underground world, fight precise melee combat to earn
currency and combat resource, spend them on healing/abilities/gear at
checkpoints, and push through ability-gated zones and bosses that open new areas.

## Systems inventory

| ID | system | how the player reaches it | purpose | key components | states seen |
|---|---|---|---|---|---|
| S01 | Movement | always on | traverse rooms, dodge | run, variable-height jump, unlockable dash / wall-cling / double-jump | grounded, airborne, dashing, clinging |
| S02 | Melee combat | attack button | kill enemies, gain resource | 4-directional slash, downward "pogo" bounce off enemies and hazards | neutral, attacking, bouncing, i-frames |
| S03 | Combat resource meter | landing hits | fuel for healing and specials | meter fills per hit, spend full chunk to heal (vulnerable while channeling) or cast | empty, partial, full, channeling |
| S04 | Health pips | always visible | survivability | pip-based HP, collectible shards (4 shards = +1 max pip) | full, damaged, one-pip, dead |
| S05 | Relic loadout | rest points only | build customization | equippable modifier items, each costs sockets, limited socket count, can over-equip at a penalty | loadout screen, over-equipped warning |
| S06 | Rest points | scattered in world | checkpoint + recovery | save game, full heal, respawn regular enemies, open loadout/vendor UI | rested, unrested |
| S07 | Death & retrieval | on death | stakes without hard punishment | drop all currency at death spot, respawn at last rest point, defeat your "echo" to recover it; die again before recovering = lost forever | echo spawned, echo defeated, currency lost |
| S08 | Zone maps | cartographer NPC per zone | navigation | buy per-zone map (fills as you explore rooms), buy compass relic to show player position, buy marker pins | unmapped, mapped, position shown |
| S09 | Fast travel | station network | cut backtracking | ride network between unlocked stations | locked, unlocked, riding |
| S10 | Boss gates | critical path rooms | skill checks + rewards | multi-phase bosses blocking progress, reward abilities or large currency | undefeated, defeated |
| S11 | Vendors & NPCs | hub + hidden shops | economy sinks | buy relics, sockets, keys, map upgrades; lore dialogue | browsing, purchased |
| S12 | Unlockable abilities | boss/quest rewards | gate keys for new zones | projectile spell, ground-slam dive, dash — each opens previously blocked paths | locked, unlocked |
| S13 | Hot springs | hidden rooms | soft recovery | stand in spring to slowly heal | healing, full |
| S14 | Arena trial | optional building | combat challenge | wave-based fights, currency/relic rewards | idle, in-trial, cleared |
| S15 | Bestiary/journal | pause menu | collection | enemy entries unlock on kills | locked, unlocked |

## Player flows

```
F01 Core loop (the game)
    explore S01 -> fight S02/S03 -> earn currency -> rest S06 (heal/equip S05)
    -> push gated zone S12 -> boss S10 -> new ability -> new zones open
    happy path clicks: n/a (real-time game); session length target 10-20 min
    edge: lost with no map, under-equipped for boss, echo unrecoverable

F02 Death & retrieval
    die S07 -> respawn at rest point S06 -> trek back -> defeat echo -> recover currency
    edge: die en route (currency lost forever), echo in boss room

F03 First 10 minutes (onboarding)
    wake -> movement basics -> first combat (attack/pogo) -> first rest point
    -> first relic equip -> boss gate teased in distance
    edge: player skips tutorialization, quits before first rest point

F04 Map purchase
    find cartographer S08 -> buy zone map -> rooms fill as explored
    -> buy compass -> player position shown
    edge: never finds cartographer (navigation pain = intended pressure valve)
```

## UI components (touch-first)

| component | variants | states | used on |
|---|---|---|---|
| Virtual joystick | fixed, floating | idle, active | gameplay |
| Action buttons | attack, jump, dash, heal | idle, pressed, cooldown, locked | gameplay |
| HUD | health pips, resource meter, currency | full/partial/empty | gameplay |
| Boss health bar | — | intro, depleting, defeated | boss rooms |
| Pause menu | resume, loadout, map, settings, quit | — | pause |
| Loadout screen | relic grid, socket row | equipped, unequipped, over-equipped | rest points |
| Map screen | zone select, room grid | unmapped, mapped, marker pins | map UI |
| Dialogue box | NPC, lore tablet | typing, complete | NPCs |
| Damage vignette | — | flash, fade | on hit |
| Touch settings | joystick type, button size/opacity | — | settings |

## Inferred data model

```
PlayerState  health_max, health, resource, currency, position (zone, room, x, y),
             unlocked_abilities[], playtime
             evidence: S03, S04, F01 / confidence: high
Relic        id, name_key, socket_cost, effect_id, effect_value, synergy_tags[], source
             evidence: S05, wiki loadout counts / confidence: high
Loadout      equipped_relic_ids[], socket_total, overequipped_flag
             evidence: S05 / confidence: high
Zone         id, rooms[], gates[{room, required_ability}], map_purchased, explored_rooms[],
             cartographer_found
             evidence: S08, S12 / confidence: high
RestPoint    id, zone_id, position, discovered
             evidence: S06 / confidence: high
SaveSlot     version, timestamp, player_state, loadout, zone_states{}, world_flags{}
             evidence: S06 / confidence: high
Vendor       id, inventory[{relic_id | item_id, price}], restock_rules
             evidence: S11 / confidence: medium
Boss         id, zone_id, hp, phases[], reward{ability_id | currency}
             evidence: S10 / confidence: high

Relationships: PlayerState 1-1 Loadout, Loadout n-n Relic, Zone 1-n RestPoint,
Zone 1-n Boss, Zone 1-1 Vendor (optional), SaveSlot 1-1 PlayerState
```

## Feature matrix

See `features.csv`. Must: 24, should: 10, could: 6, skip: 5.

## Out of scope (cannot or should not be cloned)

- The reference's art, animation, music, sound, story, characters, dialogue, names — all original in ours (Brand step).
- Licensed content: none in the reference's mechanics; nothing to license.
- The reference's community/content network: not applicable.
- PC/console ports: mobile-first; desktop export is a debug convenience only.
- Online multiplayer / leaderboards: not part of the reference loop; skip for game 1.

## Mobile translation notes (design constraints for Architect)

- Touch controls are the primary input; keyboard/gamepad are secondary. Combat
  timing windows widened ~15% vs PC reference; no pixel-precise jumps required
  on the critical path.
- Sessions are 10–20 minutes: rest points placed so a session always ends at a
  safe save; suspend/resume must restore mid-room state, not just rest points.
- Performance budget: 60fps on mid-range Android, Compatibility renderer,
  room-based streaming (never hold the whole zone in memory).

## Size

Systems 15, flows 4, entities 8. Hard parts: touch-feel combat tuning,
room streaming on low-end devices, save/versioning robustness, boss AI.
Size: **L** (a quarter) for the full game; **M** for the vertical slice.
