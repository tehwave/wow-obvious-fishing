# Obvious Fishing

**Never miss a bite again.** Obvious Fishing is a small addon for **World of Warcraft: Forever** that makes fishing easier to follow: the bite splash is loud, your own bobber is marked, and a cast bar shows how long your cast has left.

## What it does

- **Loud bite splash.** While you fish, your game sound is turned up so the splash is easy to hear, and music and ambient sounds can be muted. Your normal sound settings come back on their own a few seconds after you stop fishing.
- **Marks your bobber.** A raid target icon sits on your own bobber, so you can tell it apart from other players' bobbers. The marker never moves or animates, so the only thing moving on screen is the bobber.
- **Fishing cast bar.** A cast bar in the same style as the default one shows how much time your cast has left.
- **Auto loot while fishing.** Catches go straight to your bags while you fish. Your own auto loot setting comes back when you stop.
- **Lure reminder.** A chat message reminds you when you start fishing without a lure on your pole, or when your lure runs out.
- **Tells you what it's doing.** A line in chat lets you know when your settings are changed for fishing and when they're back to normal.

## Install

**CurseForge app:** search for **Obvious Fishing** and click Install.

**Manually:**

1. Download the latest `ObviousFishing-v….zip` from the [Releases page](https://github.com/tehwave/wow-obvious-fishing/releases) (under **Assets**, not the "Source code" zip).
2. Unzip it into `World of Warcraft/_forever_/Interface/AddOns/`. You should end up with an `ObviousFishing` folder there.
3. Restart the game.

## Settings

Open **Game Menu → Options → AddOns → Obvious Fishing**, click it in the minimap addon menu, or type `/bobber`.

| Setting | What it does |
| --- | --- |
| Turn sound up while fishing | Raises your game sound while you fish |
| Volume while fishing | How loud the game gets while you fish |
| Mute music / Mute ambience | Silences music or ambient sounds while you fish |
| Auto loot while fishing | Turns auto loot on while you fish |
| Remind me when my pole has no lure | Chat reminder when you fish without a lure |
| Mark your bobber | Shows the icon on your own bobber |
| Marker icon / Marker size | Which raid icon to use, and how big |
| Show fishing cast bar / Cast bar size | Shows the cast bar, and how big |

Shift-drag the cast bar to move it.

## Tip: catch with one key

Bind a key to **Interact** (Game Menu → Options → Keybindings, then search for "Interact"). When you hear the splash, press that key to catch the fish without clicking the bobber.

## Commands

| Command | What it does |
| --- | --- |
| `/bobber` | Open the settings |
| `/bobber test` | Preview the marker and cast bar |
| `/bobber offset <y> [x]` | Nudge the marker up/down (and left/right) |
| `/bobber reset` | Put your sound back right away and reset the cast bar position |
| `/bobber debug` | While fishing, show why your bobber is or isn't being marked |

## FAQ

**Can it flash or alert me when a fish bites?**
No. The game doesn't tell addons when a fish bites, so no addon can detect it. The splash sound is the real signal, so Obvious Fishing makes that as loud and clear as possible.

**Will it mess up my sound or auto loot settings?**
No. It remembers your settings before changing anything and puts them back when you stop fishing. If the game crashes or disconnects while you're fishing, they're restored the next time you log in.

**Can it mute other players' splashes but not mine?**
No. The game only lets addons mute a sound for everyone, which would include your own splash.

**The marker isn't on my bobber.**
Face your bobber. The game only gives the bobber a nameplate (which the marker sits on) when it's in front of you. If it still doesn't show, type `/bobber debug` while fishing and include the output in a bug report.

## Bugs and ideas

Open an issue on the [GitHub issues page](https://github.com/tehwave/wow-obvious-fishing/issues). The bug report form asks for what's needed to fix it, like the `/bobber debug` output and any Lua error.

## License

[MIT](LICENSE)
