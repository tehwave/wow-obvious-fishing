# AGENTS.md

Notes for anyone (human or AI agent) working on this addon. The player-facing
docs are in README.md; keep that one written for players.

## What this is

A single-file World of Warcraft addon for **WoW Forever** (`## Interface: 16001`).
While the player fishes it boosts sound CVars, marks the player's own bobber
with a static raid icon on its soft-target nameplate, and shows a fishing cast
bar. Everything is restored after fishing stops.

- `ObviousFishing.lua` - all code
- `ObviousFishing.toc` - addon manifest (`@project-version@` is replaced by the packager)
- `.pkgmeta` - packager config (zip folder name, files left out of the zip)
- `.github/workflows/release.yml` - builds and publishes releases on version tags
- `CURSEFORGE.md` - CurseForge setup checklist (not shipped in the zip)

## The client

- Forever runs on the **retail (Mainline) UI code**, not the Classic FrameXML.
  Retail APIs and atlases are available: `C_Spell`, `C_NamePlate`, the
  `Settings` API, `UI-HUD-*` atlases, etc.
- Blizzard's UI source for this client: the `forever` branch of
  https://github.com/Gethe/wow-ui-source. Check API signatures and atlas names
  there instead of guessing; it's the most reliable reference.

## Hard constraints (learned the hard way)

- **There is no "fish bit" event.** Nothing can detect the bite; the splash sound
  is the only signal. Don't promise bite alerts.
- **Nameplate positions can't be measured.** Calling `GetCenter()` (or any
  measuring) on a frame anchored to a nameplate errors with "Can't measure
  restricted regions" every frame. Anchoring to a nameplate is fine; reading
  its position is not.
- **Sounds can only be muted for everyone** (`MuteSoundFile`), so "mute other
  players' splashes but not mine" is impossible.
- **The marker must sit on the nameplate itself** (zero offset by default).
  The gap between nameplate and bobber varies with camera angle and distance.
  `nameplateOtherAtBase` and nameplate distance scaling were both tried and
  don't fix it for game objects.
- **The marker must not animate.** The player watches the bobber for movement,
  so nothing near it may move. No glows, pulses or flipbooks.
- Other players' bobbers are the same game object (entry `35591`), so the addon
  locks on to the first new bobber soft-targeted after the player's own cast.

## Conventions

- Every CVar the addon changes goes through `ApplyBoost`/`RestoreBoost`. The
  originals are saved in `ObviousFishingDB.saved` (a SavedVariable) so they
  survive crashes and get restored at next login.
- Print a chat line whenever settings are boosted or restored.
- Options live in the Blizzard Settings panel (`RegisterSettings`); slash
  commands are only for testing and troubleshooting.
- Match the default UI's look (e.g. the cast bar copies the player cast bar's
  atlases).

## Checking changes

There's no Lua interpreter on the dev machine. Syntax-check with the Python
`luaparser` package:

```bash
pip install --target <some-temp-dir> luaparser
python -c "import sys; sys.path.insert(0, '<some-temp-dir>'); from luaparser import ast; ast.parse(open('ObviousFishing.lua', encoding='utf-8').read()); print('PARSE OK')"
```

Then test in game: `/reload`, `/bobber test`, and an actual fishing cast.
Enable Lua errors with `/console scriptErrors 1`.

## Releasing

1. Don't edit a version number anywhere; the packager takes it from the tag.
2. Create and push an annotated tag:
   ```bash
   git tag -a v1.0.1 -m "v1.0.1"
   git push origin v1.0.1
   ```
3. The workflow builds `ObviousFishing-v1.0.1.zip`, creates a GitHub Release
   with a changelog from the commits since the previous tag, and uploads to
   CurseForge once it's configured (see CURSEFORGE.md).
