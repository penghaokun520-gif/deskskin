# deskskin Auto Update

This skin folder includes a built-in updater and is configured for:

- Repo: `https://github.com/penghaokun520-gif/deskskin`
- Update source: **GitHub Releases (latest)**

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
4. Create a release tag and publish release (example: `v1.0.1`).

Clients update from the latest published release, not from branch files.

## Main files

- `updater/update.ps1`: compare local version vs latest release tag, then download release ZIP and copy files
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
