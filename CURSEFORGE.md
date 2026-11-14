# CurseForge release checklist

Everything needed to put Obvious Fishing on CurseForge. Not shipped in the
addon zip. Checked against CurseForge's
[moderation policies](https://support.curseforge.com/support/solutions/articles/9000197279-moderation-policies).

## 0. Before you start

- **Make the GitHub repo public.** The description links to GitHub for bug
  reports and source, and CurseForge strongly encourages a working channel for
  bug reports and feedback. Private repo links are dead for everyone else.

## 1. Create the project

On the CurseForge author site, create a new **World of Warcraft** addon project.

| Field | Value |
| --- | --- |
| Name | Obvious Fishing |
| Summary | Makes fishing easier to follow by turning up the bite splash, marking your own bobber, and showing a fishing cast bar. |
| Description | Set the editor's format dropdown to **Markdown** and paste `curseforge-description.md`. It's the README minus the Install section, which links to GitHub downloads (CurseForge doesn't allow external download links). Keep it in sync with the README when features change. |
| Category | Whatever fits best: a professions/fishing category if offered, otherwise a general one like Miscellaneous |
| License | MIT (matches the `LICENSE` file in the repo) |
| Source / Issues links | https://github.com/tehwave/wow-obvious-fishing and https://github.com/tehwave/wow-obvious-fishing/issues |

Why these values pass moderation:

- **Name** is English and has no game name, class name or version number in it.
- **Summary** is one sentence and doesn't repeat the description word for word.
  The game version comes from the file's tags, not the summary.
- **Description** explains what the addon does and how, in English. Links to
  GitHub issues, the source code and the credits are fine, and they sit in the
  lower part of the page as the rules ask. None of them are downloads.

New projects go through CurseForge moderation before they're public. If
moderation asks for changes, fix them on the same project; don't delete and
re-upload it.

## 2. Images (your part)

**Project avatar (required):**

- Exactly **400×400 pixels**, PNG or JPG. **Not WebP**: CurseForge has a known
  bug with WebP avatars.
- Not a single solid color.
- **Your own artwork.** No Blizzard icons or game art (for example the in-game
  fishing pole icon), no copyrighted images. A simple original drawing of a
  bobber, fishing line or splash works well.

**Gallery screenshots** to take in game (keep the UI clean, good lighting,
water in view):

1. **Marker on your bobber:** a cast in progress, the raid star sitting on your
   bobber's nameplate, ideally with another player's bobber nearby and unmarked.
2. **Cast bar:** the Obvious Fishing cast bar mid-cast, near your character.
3. **Settings panel:** Game Menu → Options → AddOns → Obvious Fishing.
4. **Chat messages:** the "fishing - sound turned up…" and "back to normal" lines.
5. **Marker icon options (optional):** two or three casts with different raid
   icons (skull, circle…) to show it's customizable.

Use real, unedited screenshots. If you edit or enhance one with AI and it could
make the addon look different from how it really looks, CurseForge requires a
visible disclaimer on the image or in the description.

Put the image files in a `media/` folder in the repo if you want them versioned;
`.pkgmeta` already keeps `media/` out of the addon zip.

## 3. Hook up automatic uploads

Once the project exists:

1. Copy the **Project ID** from the project page's "About Project" box and add
   it to `ObviousFishing.toc`:
   ```toc
   ## X-Curse-Project-ID: 123456
   ```
2. Create an **API token** in your CurseForge author account settings.
3. Save it as a GitHub secret named `CF_API_KEY`:
   ```bash
   gh secret set CF_API_KEY --repo tehwave/wow-obvious-fishing
   ```
   (it prompts you to paste the token)
4. Commit and push the TOC change.

## 4. Release

1. Make sure `CHANGELOG.md` has a section for the version you're releasing.
   CurseForge requires a changelog on every file; the workflow uses this file
   as the release notes on both GitHub and CurseForge.
2. Tag and push:
   ```bash
   git tag -a v1.0.0 -m "v1.0.0"
   git push origin v1.0.0
   ```

The GitHub workflow builds `ObviousFishing-v1.0.0.zip`, attaches it to a GitHub
Release, and (with steps 3.1–3.3 done) uploads it to CurseForge. The game
version is taken from `## Interface: 16001` in the TOC. After the first upload,
check on CurseForge that the file is tagged for WoW Forever.

Without the CurseForge steps, tagging still produces the GitHub Release, so you
can publish there first and add CurseForge later.

## Things the policy covers that are already fine

- **File format:** the packager makes a real `.zip`. The general rule "no root
  folder in the zip" is written for other games. WoW addon zips must contain
  the `ObviousFishing` folder so the CurseForge app installs it into `AddOns`
  correctly, which is what every WoW addon on CurseForge does.
- **Updates:** only release versions with real changes. Re-uploading the same
  thing or spacing out tiny updates to look active counts as update spam.
- **Game rules (EULA/ToS):** the addon only changes your own settings and adds
  display elements. It never clicks, casts or loots for you (auto loot is the
  game's own setting), has no ads, and the code isn't obfuscated, so it fits
  Blizzard's addon rules.
- **Copyright:** the addon uses only the game's own interface art at runtime,
  and its credits name everything it builds on.
