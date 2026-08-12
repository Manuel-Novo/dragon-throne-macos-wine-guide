# Dragon Throne: Battle of Red Cliffs on Apple Silicon (free, no CrossOver)

A working recipe to run the 2001 RTS **Dragon Throne: Battle of Red Cliffs**
(a.k.a. the *Fate of the Dragon* expansion, Steam appid **2633500**) on an
**Apple Silicon Mac** using only **free, open‑source software** — no CrossOver
subscription, no virtual machine, no cracks.

> ✅ **Tested working:** Apple **M1**, **macOS 26**, August 2026. The game reaches its
> menu and plays (see the three fixes below). The one known limitation today is **no
> sound** (explained at the end).

![status](https://img.shields.io/badge/status-playable-brightgreen)
![cost](https://img.shields.io/badge/cost-%E2%82%AC0-blue)
![layer](https://img.shields.io/badge/layer-Wine%2011%20(free)-orange)

---

## Why this is tricky (and why most guides don't cover it)

Dragon Throne is a **32‑bit x86** DirectDraw/Direct3D game from 2001. On Apple Silicon
that combination hits three separate walls at once:

1. **Apple's OpenGL is broken/deprecated**, so Wine's default `wined3d` GL renderer
   floods `GL_INVALID_FRAMEBUFFER_OPERATION` and the screen stays black.
2. **The audio layer crashes.** Some Wine builds abort with
   `Assertion failed: !status … mmdevapi_private.h` a few seconds after launch.
3. **Old `wine32on64` (CrossOver ≤ 24 tech) throws `illegal instruction`** on this
   game's self‑modifying/generated init code under Rosetta 2. Apple's **Game Porting
   Toolkit is 64‑bit only**, so it can't run this game at all.

The fix is to use **modern Wine (wow64)** and neutralise walls #1 and #2 with two
settings. That's the whole trick.

---

## Prerequisites

- An **Apple Silicon** Mac (M1/M2/M3/M4), macOS 14 or newer, with **Rosetta 2** installed
  (`softwareupdate --install-rosetta --agree-to-license` if needed).
- **You must own the game.** It's sold DRM‑free on
  [Steam (appid 2633500)](https://store.steampowered.com/app/2633500/), and also on
  Epic and ZOOM Platform. This guide does **not** provide the game — bring your own copy.
- [Homebrew](https://brew.sh) (optional but easiest for installing Wine).

---

## Step 1 — Install free Wine (with MoltenVK)

The free, official WineHQ macOS packages are maintained by **Gcenx**. They bundle
**MoltenVK** (Vulkan → Metal), which is what makes fix #1 possible.

```bash
brew install --cask --no-quarantine gstreamer-runtime wine-stable
```

> If your Homebrew has dropped `--no-quarantine`, download the tarball directly from the
> [Gcenx releases](https://github.com/Gcenx/macOS_Wine_builds/releases), verify its
> checksum, unzip it, and move `Wine Stable.app` to `/Applications`. The bundles are
> signed but not notarised, so you either strip quarantine or approve them once in
> *System Settings → Privacy & Security*.

For the rest of this guide, Wine lives at:

```
/Applications/Wine Stable.app/Contents/Resources/wine/bin
```

## Step 2 — Put the game somewhere and create a Wine prefix

Copy your legally‑owned game files (the folder containing `dragonthrone.exe`) to, say,
`~/DragonThrone/game`. Then:

```bash
export WINEPREFIX="$HOME/DragonThrone/prefix"
export PATH="/Applications/Wine Stable.app/Contents/Resources/wine/bin:$PATH"
wineboot -i
```

## Step 3 — The two key settings

**Fix #1 — route Direct3D/DirectDraw through Vulkan/Metal instead of Apple's broken GL:**

```bash
wine reg add 'HKCU\Software\Wine\Direct3D' /v renderer /t REG_SZ /d 'vulkan' /f
```

**Fix #2 — disable the audio component that asserts.** This is done at launch via
`WINEDLLOVERRIDES` (next step). `mmdevapi=d` disables the crashing module; the game runs
**without sound** but stops dying.

## Step 4 — (recommended) drop in cnc-ddraw for clean 2D rendering

Dragon Throne is a 2D DirectDraw game (640×480). **cnc-ddraw** by FunkyFr3sh renders that
2D perfectly on the CPU (GDI), independent of the GPU path.

1. Download the official release from
   [github.com/FunkyFr3sh/cnc-ddraw](https://github.com/FunkyFr3sh/cnc-ddraw/releases).
2. Copy its `ddraw.dll` **into the game folder** (next to `dragonthrone.exe`). Keep a
   backup of any existing `ddraw.dll` first.
3. Drop the `ddraw.ini` from this repo next to it (renderer set to `gdi`, windowed).

## Step 5 — Launch

Use [`play.sh`](play.sh) (edit the two paths at the top), or run directly:

```bash
export WINEPREFIX="$HOME/DragonThrone/prefix"
export PATH="/Applications/Wine Stable.app/Contents/Resources/wine/bin:$PATH"
export WINEDLLOVERRIDES="ddraw=n,b;winmm=b;mmdevapi=d;dsound=b"
export WINEDEBUG=-all
cd "$HOME/DragonThrone/game"
wine dragonthrone.exe
```

> `ddraw=n,b` tells Wine to load the local **cnc-ddraw** first. If you skip Step 4, use
> `ddraw=b` instead (Wine's builtin, rendered via the Vulkan setting from Step 3).

## Step 6 — Skip the intro

The 2001 intro video (`DATA/fod.avi`) has no codec under Wine, so the first screen looks
almost blank. **Press `Esc`** (or click) to skip it and reach the menu. The game plays
from there.

---

## The winning configuration, in one table

| Concern | Setting | Why |
|---|---|---|
| Rendering | `wined3d` `renderer=vulkan` (registry) | Apple's OpenGL is broken; Vulkan→MoltenVK→Metal works |
| 2D output | cnc-ddraw `ddraw.dll`, `renderer=gdi` | Perfect CPU 2D blitting for a 640×480 DirectDraw game |
| Audio crash | `WINEDLLOVERRIDES="…;mmdevapi=d;dsound=b"` | Removes the asserting audio module (no sound) |
| Instruction crash | Modern Wine 11 **wow64** (not `wine32on64`) | Avoids the Rosetta `illegal instruction` on generated code |
| Intro hang | Press `Esc` at first screen | Intro video has no codec under Wine |

---

## Known limitations

- **No sound** yet. Disabling `mmdevapi` is what keeps the game alive on Wine **stable 11.0**.
  We tested the whole free build matrix (Aug 2026):
  | Gcenx build | Display | Audio |
  |---|---|---|
  | stable 11.0 | ✅ works (cnc-ddraw GDI windowed) | ❌ `mmdevapi` assertion crash |
  | staging 11.15 | ❌ blank window, ~99% CPU spin | ✅ fixed (with `DirectSound HardwareAcceleration=Emulation`) |
  | devel 11.15 | ❌ same blank+spin → an **upstream 11.15 display regression**, not a staging patch | ✅ fixed |
  So today you choose: **picture without sound (11.0)** — this guide's default — or neither.
  When a build ships with the 11.15 audio fix but without the display regression, sound
  should just work by removing `mmdevapi=d;dsound=b` from the overrides and setting
  `HKCU\Software\Wine\DirectSound` → `HardwareAcceleration`=`Emulation`. PRs welcome.
- **Renderer notes (stable 11.0):** cnc-ddraw `renderer=gdi` + windowed is the only mode
  that displays. `opengl` = black window, `direct3d9` = crash, GDI fullscreen = unscaled
  and choppy. For a bigger picture, set **1024×768 in the in-game OPTIONS** menu instead.
- Windowed 640×480 by default (the game's native resolution). cnc-ddraw can scale/borderless
  — tweak its `ddraw.ini`.
- Tested on **M1 / macOS 26**. Other chips/OS versions should behave the same but aren't
  independently confirmed here.

## What does NOT work (so you don't waste time)

- **Apple Game Porting Toolkit** — 64‑bit only; this game is 32‑bit. Dead end.
- **Old `wine32on64`** (WineskinCX 21, CrossOver ≤ 24) — `illegal instruction` at launch.
- **Default `wined3d` GL renderer** — black screen, `GL_INVALID_FRAMEBUFFER_OPERATION`.

## Credits

- [Wine](https://www.winehq.org/) and the WineHQ project
- [Gcenx](https://github.com/Gcenx/macOS_Wine_builds) — free macOS Wine builds + MoltenVK bundling
- [FunkyFr3sh / cnc-ddraw](https://github.com/FunkyFr3sh/cnc-ddraw) — the DirectDraw wrapper
- [MoltenVK](https://github.com/KhronosGroup/MoltenVK) — Vulkan on Metal

## License

This guide (text and scripts) is released under the **MIT License** — see [LICENSE](LICENSE).
It contains **no game files and no third‑party binaries**; every tool is linked to its
official source. *Dragon Throne: Battle of Red Cliffs* is © its respective rights holders;
you must own a legitimate copy.
