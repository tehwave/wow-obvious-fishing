# Obvious Fishing

A World of Warcraft addon for **WoW Forever** that makes fishing bites hard to miss.

While you fish, it:

- **Turns the sound up** so the bite splash is loud, and can mute music and ambience. WoW has no "bite" event for addons, so the splash sound is the real signal; this just makes it impossible to miss. Your own sound settings come back about 12 seconds after you stop fishing (and after a crash or disconnect, at your next login).
- **Marks your own bobber** with a static raid target icon on its nameplate, so you can tell it apart from other players' bobbers. Nothing is animated, so the only thing moving on screen is the bobber itself.
- **Shows a cast bar** styled like the default one, with the time left on your cast.

It posts a line in chat whenever it changes your sound settings and when it puts them back.

## Install

Copy the `ObviousFishing` folder into `World of Warcraft/_forever_/Interface/AddOns/` and restart the game.

## Options

Open **Game Menu → Options → AddOns → Obvious Fishing**, click the addon in the minimap addon menu, or type `/bobber`.

- Turn sound up while fishing, and the volume to use
- Mute music / mute ambience
- Mark your bobber, which raid icon, and its size
- Show the cast bar, and its size

Tip: bind a key to **Interact** (Key Bindings → Targeting) and press it when you hear the splash to catch the fish without clicking the bobber.

## Commands

| Command | What it does |
| --- | --- |
| `/bobber` | Open the options panel |
| `/bobber test` | Preview the marker and cast bar |
| `/bobber offset <y> [x]` | Nudge the marker |
| `/bobber reset` | Restore your sound now and reset the cast bar position |
| `/bobber debug` | While fishing, show why your bobber is or isn't detected |

Shift-drag the cast bar to move it.
