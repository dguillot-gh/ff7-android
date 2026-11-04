# Notices

## This repository
The scripts, build tools, Android app template and FF7 setup are MIT-licensed ([LICENSE](LICENSE)). The build tools
come from [psx-android](https://github.com/dguillot-gh/psx-android) (MIT, same author).

## The engine (`framework/`, a git submodule)
[psxrecomp-android](https://github.com/dguillot-gh/psxrecomp-android): [psxrecomp](https://github.com/mstan/psxrecomp)
by mstan plus an Android layer. **PolyForm Noncommercial License 1.0.0**
(<https://polyformproject.org/licenses/noncommercial/1.0.0>): personal and other non-commercial use only. Its own
third-party notices are in the submodule.

## OpenBIOS
`framework/bios/openbios.bin` is OpenBIOS from [PCSX-Redux](https://github.com/grumpycoders/pcsx-redux), MIT; see
`framework/bios/OpenBIOS.LICENSE`. It is bundled into the app so no Sony BIOS is needed.

## Downloaded at build time (not in this repository)
- Java 17 (Microsoft Build of OpenJDK), the Android SDK, NDK and CMake (Google; you accept Android's SDK licence),
  Python (python.org, via NuGet), llvm-mingw (mstorsjo/llvm-mingw), SDL3 (libsdl.org, zlib licence), Gradle and the
  Android libraries the app uses.
- The app icon is made from the retail FF7 cover in [libretro-thumbnails](https://github.com/libretro-thumbnails/libretro-thumbnails),
  downloaded during the build and kept out of the repository.

## References
- FF7's module map (which code loads at which address) follows the
  [Final-Fantasy-VII](https://github.com/TechnicallyComputers/Final-Fantasy-VII) static recomp of the retail game, which
  uses the same engine. Nothing was copied from it; see `game/REFERENCE.md`.

## The game
*Final Fantasy VII* is © Square Enix. The Shinra Archaeology Cut is a fan edition by its own authors. This repository
contains no part of either: you build from your own discs, and the builds you make are for your own use.
