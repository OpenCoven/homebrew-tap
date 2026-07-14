# OpenCoven Homebrew Tap

Homebrew tap for [OpenCoven](https://github.com/OpenCoven) apps.

## Install CovenCave

```bash
brew install --cask opencoven/tap/coven-cave
```

Or tap first, then install:

```bash
brew tap opencoven/tap
brew install --cask coven-cave
```

Upgrades ride the app's built-in updater (`auto_updates true`), or:

```bash
brew upgrade --cask coven-cave
```

Uninstall (add `--zap` to also remove app data):

```bash
brew uninstall --cask coven-cave
```

The cask installs the signed + notarized per-architecture DMG (Apple
Silicon and Intel) from the latest
[coven-cave release](https://github.com/OpenCoven/coven-cave/releases/latest).

## How the cask stays current

`.github/workflows/update-cask.yml` re-renders the cask from the newest
stable release — triggered by a `repository_dispatch` from coven-cave's
release pipeline the moment artifacts finish uploading, with a 6-hourly
schedule as a no-secrets fallback. `scripts/update-cask.sh` is fail-closed:
it only renders when the release's `SHA256SUMS` covers both DMGs and both
are downloadable. Every change is validated with `brew style`,
`brew audit --cask --online`, and (in CI) a real `brew install --cask`
smoke test on both macOS architectures.

Manual bump:

```bash
scripts/update-cask.sh          # latest stable release
scripts/update-cask.sh v0.1.0   # specific tag
```

## License

MIT — see [coven-cave](https://github.com/OpenCoven/coven-cave) for the
app's own licensing (MIT OR AGPL-3.0-only).
