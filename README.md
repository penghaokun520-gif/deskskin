# deskskin Auto Update

This skin folder includes a built-in updater and is configured for:

- Repo: `https://github.com/penghaokun520-gif/deskskin`
- Branch: `main`

## How it works

1. Manual update:
- Right-click the skin and click `Check Skin Update`.

2. Auto check:
- Each time the skin refreshes, it runs a silent update check once.
- If a newer version exists, it updates files automatically.

## Release flow

When you publish a new version to GitHub:

1. Edit `version.json` and increase `version` (example: `1.0.0` -> `1.0.1`).
2. Optionally update `updated_at`.
3. Commit and push to `main`.

Clients will update on the next auto check or manual check.

## Main files

- `updater/update.ps1`: compare version, download ZIP, copy files
- `updater/update.vbs`: manual update entry
- `updater/autocheck.vbs`: silent auto-check entry
- `scripts/resolve_cloudmusic_path.ps1`: auto-detect CloudMusic install path
- `version.json`: local version metadata

## Folder structure

- `assets/icons`: all image assets
- `scripts`: playback control and title fallback scripts
- `updater`: updater scripts

## Path detection

- `scripts/play.vbs` now resolves `cloudmusic.exe` from process, registry, shortcuts, and known install locations.
- Detected path is cached in `scripts/cloudmusic_path.cache` for faster startup.
