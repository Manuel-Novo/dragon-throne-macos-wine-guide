#!/bin/zsh
# Launch Dragon Throne: Battle of Red Cliffs on Apple Silicon via free Wine.
# Edit the two paths below to match your setup, then: chmod +x play.sh && ./play.sh
#
# The recipe (see README.md):
#   - modern Wine 11 (wow64), NOT old wine32on64  -> avoids "illegal instruction"
#   - wined3d renderer=vulkan (set once, below)    -> Apple GL is broken, use Metal
#   - cnc-ddraw as local ddraw.dll (renderer=gdi)   -> clean 2D for this 640x480 game
#   - mmdevapi disabled                             -> the audio module asserts (no sound)
#   - press Esc at the first screen                 -> skip the codec-less intro video

GAME_DIR="$HOME/DragonThrone/game"          # folder containing dragonthrone.exe
WINE_APP="/Applications/Wine Stable.app"    # free WineHQ macOS build (Gcenx)

export WINEPREFIX="$HOME/DragonThrone/prefix"
export PATH="$WINE_APP/Contents/Resources/wine/bin:$PATH"

# one-time-safe: ensure the Vulkan renderer is set in this prefix
wine reg add 'HKCU\Software\Wine\Direct3D' /v renderer /t REG_SZ /d 'vulkan' /f >/dev/null 2>&1

# ddraw=n,b loads local cnc-ddraw first (use ddraw=b if you skipped the cnc-ddraw step)
export WINEDLLOVERRIDES="ddraw=n,b;winmm=b;mmdevapi=d;dsound=b"
export WINEDEBUG=-all

cd "$GAME_DIR"
exec wine dragonthrone.exe
