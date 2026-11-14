## Never miss a bite again

**Obvious Fishing** makes fishing in **World of Warcraft: Forever** easier to follow. The bite splash is loud, your own bobber is clearly marked, and a cast bar shows how long your cast has left. Everything it changes is put back when you stop fishing.

## Features

- **Loud bite splash.** While you fish, your game sound is turned up so the splash is easy to hear. Music and ambient sounds can be muted too.
- **Hear it while alt-tabbed.** Game sound keeps playing while you're switched to another window, so you still hear the splash.
- **Your bobber, marked.** A raid target icon sits on your own bobber, so you can tell it apart from other players' bobbers. The marker never moves or animates, so the only thing moving on screen is the bobber.
- **Fishing cast bar.** A cast bar in the style of the default one shows the time left on your cast.
- **Auto loot while fishing.** Catches go straight to your bags.
- **Lure reminder.** A chat message reminds you when you start fishing without a lure on your pole, or when your lure runs out.
- **Your settings are safe.** Your own sound and auto loot settings come back a few seconds after you stop fishing, and even after a crash or disconnect. A line in chat tells you when settings change and when they're back to normal.

## Settings

Open **Game Menu → Options → AddOns → Obvious Fishing**, click it in the minimap addon menu, or type `/obvfish`. Every feature can be turned on or off:

- Turn sound up while fishing, and the volume to use
- Mute music, mute ambience
- Play sound in the background
- Auto loot while fishing
- Lure reminder
- Mark your bobber, which raid icon, and its size
- Show the cast bar, and its size (shift-drag the bar to move it)

## Tip: catch with one key

Bind a key to **Interact** (Game Menu → Options → Keybindings, then search for "Interact"). When you hear the splash, press that key to catch the fish without clicking the bobber.

## Commands

- `/obvfish` opens the settings
- `/obvfish test` previews the marker and cast bar
- `/obvfish offset <y> [x]` nudges the marker
- `/obvfish reset` puts your sound back right away and resets the cast bar position
- `/obvfish debug` shows, while fishing, why your bobber is or isn't being marked
- `/obvfish credits` shows the credits

## FAQ

**Can it flash or alert me when a fish bites?**

No. The game doesn't tell addons when a fish bites, so no addon can detect it. The splash sound is the real signal, so Obvious Fishing makes it as loud and clear as possible.

**Will it mess up my sound or auto loot settings?**

No. It remembers your settings before changing anything and puts them back when you stop fishing. If the game crashes or disconnects while you're fishing, they're restored the next time you log in.

**Can it mute other players' splashes but not mine?**

No. The game only lets addons mute a sound for everyone, which would include your own splash.

**The marker isn't on my bobber.**

Face your bobber. The game only gives the bobber a nameplate (which the marker sits on) when it's in front of you. If it still doesn't show, type `/obvfish debug` while fishing and include the output in a bug report.

## Bugs and ideas

Report bugs and suggest ideas on the [GitHub issues page](https://github.com/tehwave/wow-obvious-fishing/issues). The bug report form asks for what's needed to fix it, like the `/obvfish debug` output and any Lua error.

## Credits

- Made by **tehwave**
- Built with help from [Claude](https://claude.com) by Anthropic
- Released with [BigWigsMods packager](https://github.com/BigWigsMods/packager)
- Blizzard UI reference: [Gethe/wow-ui-source](https://github.com/Gethe/wow-ui-source)

Source code: [github.com/tehwave/wow-obvious-fishing](https://github.com/tehwave/wow-obvious-fishing) (MIT license)
