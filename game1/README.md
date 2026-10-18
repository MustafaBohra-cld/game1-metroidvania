# Project Ember (GAME-01)

An original 2D action-metroidvania for mobile — first game built on the
reusable mobile-game system. Godot 4.7.2, GDScript, Android-first.

## Quick start (Windows)

1. Install Godot 4.7.2 (standard edition, **not** .NET).
2. Editor > Manage Export Templates > Download and Install.
3. Install OpenJDK 17 and the Android SDK (platform-tools, build-tools,
   platform, NDK, CMake). Set both paths in
   Editor > Editor Settings > Export > Android.
4. Open this folder in Godot (`project.godot`). Press F5 — you should see
   "Project Ember scaffold OK" in the debugger output.
5. Project > Export > Android > Export Project → install the APK on your phone.

See `SETUP.md` for the full checklist.

## Layout

- `scenes/` — game scenes (main.tscn is a temporary bootstrap)
- `scripts/` — game code; `scripts/modules/` holds the six system modules:
  `input`, `combat`, `world`, `progression`, `mobile`, `monetization`
- `assets/` — art, audio, fonts (all original or CC0 — see IP rule)
- `replica/` — pipeline outputs: recon map, feature matrix, architecture…
- `tools/` — validation/build scripts
- `docs/` — design notes

## IP rule

Original art, music, story, characters, dialogue, and names only.
We study genre mechanics, never anyone's expression. The Brand phase
(final naming) plus the sweep tool enforce this before launch.
