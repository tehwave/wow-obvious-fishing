# CurseForge release checklist

Everything needed to put Obvious Fishing on CurseForge. Not shipped in the
addon zip.

## 1. Create the project

On the CurseForge author site, create a new **World of Warcraft** addon project.

| Field | Value |
| --- | --- |
| Name | Obvious Fishing |
| Summary | Never miss a bite: a loud bite splash, a marker on your own bobber, and a fishing cast bar for WoW Forever. |
| Description | Paste the content of `README.md`, from "What it does" through "Credits" (drop the Install section; CurseForge handles that) |
| Category | Whatever fits best: a professions/fishing category if offered, otherwise a general one like Miscellaneous |
| License | MIT (matches the `LICENSE` file in the repo) |
| Source / Issues links | https://github.com/tehwave/wow-obvious-fishing and https://github.com/tehwave/wow-obvious-fishing/issues |

New projects go through CurseForge moderation before they're public.

## 2. Images (your part)

**Project avatar:** a square icon. The in-game icon is WoW's fishing pole
(`Interface\Icons\Trade_Fishing`); something in that spirit works.

**Gallery screenshots** to take in game (keep the UI clean, good lighting,
water in view):

1. **Marker on your bobber:** a cast in progress, the raid star sitting on your
   bobber's nameplate, ideally with another player's bobber nearby and unmarked.
2. **Cast bar:** the Obvious Fishing cast bar mid-cast, near your character.
3. **Settings panel:** Game Menu → Options → AddOns → Obvious Fishing.
4. **Chat messages:** the "fishing - sound turned up…" and "back to normal" lines.
5. **Marker icon options (optional):** two or three casts with different raid
   icons (skull, circle…) to show it's customizable.

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

```bash
git tag -a v1.0.0 -m "v1.0.0"
git push origin v1.0.0
```

The GitHub workflow builds `ObviousFishing-v1.0.0.zip`, attaches it to a GitHub
Release, and (with steps 3.1–3.3 done) uploads it to CurseForge with a
changelog made from the commit messages since the last tag. The game version is
taken from `## Interface: 16001` in the TOC. After the first upload, check on
CurseForge that the file is tagged for WoW Forever.

Without the CurseForge steps, tagging still produces the GitHub Release, so you
can publish there first and add CurseForge later.
