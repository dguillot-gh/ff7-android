# Final Fantasy VII Shinra Archaeology Cut for Android

A native Android port of **Final Fantasy VII** (PlayStation), in the **Shinra Archaeology Cut v1.0.5** edition, made
by *static recompilation*: the game's main program is translated to C and compiled for your phone ahead of time, and
the code FF7 loads from the disc while it runs (battles, the field, the world map, the menus) is pre-compiled too,
instead of being emulated. The rest of the console (graphics, sound, CD drive, controllers) comes from the
[psxrecomp](https://github.com/mstan/psxrecomp) engine with its Android layer
([psxrecomp-android](https://github.com/dguillot-gh/psxrecomp-android)).

> **This repository contains no game data.** You build the game from your own discs: the scripts recompile your
> discs on your PC, and nothing made from them is ever committed or shared. Please do not share the builds you make
> (the build folder and the APK contain the game).

## What's in it

- **Everything to build it** in one place: the build scripts, the Android app, the engine (a git submodule) and
  FF7's own setup (configuration, code entry points, the FF7 module extractor). Clone, add your discs, run one script.
- **Speed settings for older phones** as the defaults: the OpenGL renderer at 2x with vsync off, the "stable" texture
  filter (smooth 3D, sharp 2D), the idle-loop skip, and faster battle loading. The in-game menu changes all of them.
- **On the phone**: touch controls you can move and resize, gamepad support, 12 save-state slots, Continue after
  quitting, and an Import memory card button for a card of your own (for example from DuckStation).

## Tested on

- **Google Pixel 8** (Tensor G3, Android 14+): full speed.
- **LG V30** (Snapdragon 835, Adreno 540, Android 8): playable; most of the field runs at or near full speed, heavy
  battles and some menus still dip. Speed work on this phone is ongoing.

Other phones should work (Android 8 or newer, 64-bit ARM, OpenGL ES 3.2 for the GPU renderer). If the picture looks
wrong, the software renderer (in the menu) is the safe fallback.

## What you need

- **Your own discs** of Final Fantasy VII Shinra Archaeology Cut v1.0.5, as `.cue` + `.bin` (one `.bin` per disc).
  The scripts find them by SHA-1, so the file names do not matter:

  | Disc | SHA-1 of the `.bin` |
  |---|---|
  | Disc 1 | `d7525bb78c329c74b614e5af91dbe98e20591856` |
  | Disc 2 | `7b8b4497554a546139141af81d70247618c9eb77` |
  | Disc 3 | `884a7d5a3d8a39a476bbb7254b87dba5b6366faa` |

  **The original (retail) FF7?** Not supported yet. The Shinra Archaeology Cut changes the main program, so a build is
  tied to the discs it was made from. Retail FF7 (SCUS-94163/4/5) has the same layout and should need only its own
  disc hashes and a check of the battle-loading addresses; nobody has tested it here yet.
- **Windows 10 or 11** (64-bit) with **PowerShell 7** (`winget install Microsoft.PowerShell`) and **Git**
  (`winget install Git.Git`). About **20 GB** of free disk space for the tools and the build.
- **An Android phone** (Android 8+, arm64) and a USB cable, with USB debugging on.

## Building it

Clone the repository into a folder of its own (the *workspace*) and put your discs in the workspace's `discs\` folder:

```
workspace\
  ff7-android\            (this repository)
  discs\                  your three .cue + .bin pairs (any names)
```

```powershell
git clone --recurse-submodules https://github.com/dguillot-gh/ff7-android.git
pwsh -File ff7-android\scripts\RUN-ALL.ps1 -Install
```

`RUN-ALL.ps1` gets the build tools, sets the game up from your discs, pre-compiles FF7's disc code, builds the app and
(with `-Install`) installs it on the phone over USB together with your discs. The first run takes one to two hours,
mostly the pre-compile and the app build; later runs are much faster. Every script takes `-DryRun` to check
everything without installing or building anything.

Then, on the phone: open **Final Fantasy VII**, **Select game file**, go to **Download > ff7_recomp**, pick all three
`.cue` files, and **Play**.

## What the scripts do to your PC

The scripts are plain text in `scripts\` (the steps) and `tools\` (the work): read any of them before running it. Each
step writes a log to `logs\` in the workspace.

| Script | What it does | What it changes on your PC |
|---|---|---|
| `1-INSTALL-TOOLS.ps1` | Gets the build tools and the engine, builds the recompiler | Downloads Java 17 (Microsoft OpenJDK), Google's Android SDK (platform 35, NDK 28.2, CMake 3.22; asks you to accept Google's SDK licence first), a portable Python and the llvm-mingw compiler into `tools-cache\` in the workspace. Nothing is installed into Windows; no admin rights. Tools you already have are used instead. |
| `2-PREPARE.ps1` | Finds your discs, sets the game up, generates its code | Reads your discs, never changes them. Copies them into the workspace (`recomps\`, `android-recomp\`). `-Background <picture>` puts a picture of your own on the start screen. |
| `3-PRECOMPILE.ps1` | Pre-compiles the code FF7 loads from the disc | Writes only inside `android-recomp\ff7_recomp\`. Uses every CPU core but two for 20-45 minutes. |
| `4-BUILD-ANDROID.ps1` | Builds the phone app (APK) into `apks\` | Gradle downloads Android libraries from Google and Maven Central, and SDL3, the first time. |
| `5-INSTALL-PHONE.ps1` | Installs the app over USB, copies your discs to the phone | Backs up the app's saves from the phone to `saves-backup\` first; never replaces a memory card. `-Serial` picks a phone when several are connected; `-Card <file.mcd>` imports a memory card of your own. |
| `RUN-ALL.ps1` | Steps 1-4 in order (5 too with `-Install`), stopping at the first that fails | Nothing more than the steps it runs. |

Nothing is uploaded anywhere, nothing is left running in the background, and no system settings are changed.

## How it works

The engine's recompiler reads the main program from Disc 1 and writes it as C; Android's NDK compiles that into the
app. FF7 loads most of its code from the disc while it plays (the field, battles, the world map and the menus are
modules loaded at fixed addresses), so `game\tools\overlay_extract.py` takes each module from your discs, checks that
it really is code at that address, and the pre-compile turns it into native code too. At run time a pre-compiled piece
only runs when its bytes match what the game loaded, so a wrong piece can never run wrong code; anything not
pre-compiled runs on the engine's interpreter. The app can also record code it meets while you play;
`3-PRECOMPILE.ps1 -FromPhone` pulls that recording so the next build covers it.

| Folder | What |
|---|---|
| `game/` | FF7's setup: `game.toml` (memory layout, discs, speed settings), `game.toml.in` (the app's default settings), `seeds/` (code entry points), `tools/overlay_extract.py`, `REFERENCE.md` (notes) |
| `scripts/` | the build steps |
| `tools/` | the build tools (from [psx-android](https://github.com/dguillot-gh/psx-android)) and the copyright guard |
| `template/` | the Android app template |
| `framework/` | the engine: [psxrecomp-android](https://github.com/dguillot-gh/psxrecomp-android) (submodule) |

**Never committed**: discs, saves, BIOS images, generated code, APKs, and capture files (they contain the game's
code). `python tools/check_no_game_data.py` checks every tracked file; `--install-hook` makes it run before each commit.

## Credits and licence

The engine is [psxrecomp](https://github.com/mstan/psxrecomp) by mstan, with this project's Android layer
([psxrecomp-android](https://github.com/dguillot-gh/psxrecomp-android)); it is under the **PolyForm Noncommercial
License 1.0.0**: personal, non-commercial use only. The free OpenBIOS from
[PCSX-Redux](https://github.com/grumpycoders/pcsx-redux) (MIT) ships with the engine, so no Sony BIOS is needed. FF7's
module map comes from the [Final-Fantasy-VII](https://github.com/TechnicallyComputers/Final-Fantasy-VII) static recomp
of the retail game. The Shinra Archaeology Cut is a fan edition of FF7 by its own authors; this repository contains
none of it. Details in [NOTICE.md](NOTICE.md).

This repository's own files (the scripts, tools, template and FF7 setup) are MIT ([LICENSE](LICENSE)). *Final Fantasy
VII* is © Square Enix; this project is not affiliated with or endorsed by Square Enix or Sony.
