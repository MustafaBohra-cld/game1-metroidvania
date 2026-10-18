# Windows setup checklist — Project Ember

Do once, in order. Tick each off.

- [ ] **Godot 4.7.2** standard edition installed (Help > About confirms version).
      Not the .NET build — this project is GDScript.
- [ ] **Export templates**: Editor > Manage Export Templates > Download and Install.
- [ ] **OpenJDK 17** installed (must be 17 — newer JDKs break the Gradle build).
- [ ] **Android SDK** via Android Studio: SDK Manager > install platform-tools,
      build-tools, a recent platform, NDK, and CMake.
- [ ] **Paths**: Editor > Editor Settings > Export > Android — set Java SDK Path
      and Android SDK Path.
- [ ] **Phone**: Settings > About Phone > tap Build Number 7x > Developer Options >
      enable USB debugging.
- [ ] **Smoke test**: open this folder in Godot, press F5 — debugger shows
      "Project Ember scaffold OK".
- [ ] **APK test**: Project > Export > select the Android preset > Export Project.
      Install on phone. Game opens = Phase 0 complete.

## When exporting for Google Play later

- Project > Export > enable "Gradle Build", export **.aab** (not .apk).
- Create a release keystore once (`keytool -genkey ...`) and **never commit it**
  (it's already in `.gitignore`). Back it up somewhere safe — losing it means
  you can never update the app.
- Replace the placeholder package id `com.projectember.game1` with the real one.
