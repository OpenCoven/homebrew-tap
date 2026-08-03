# OpenCoven Homebrew Tap

Homebrew tap for [OpenCoven](https://github.com/OpenCoven) apps. It ships
CovenCave today; Psyche Build becomes available after its public v0.0.1
release is published and the generated Cask pull request is merged.

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

## Install Psyche Build

After the public v0.0.1 release and Cask merge:

```bash
brew install --cask opencoven/tap/psyche-build
brew upgrade --cask opencoven/tap/psyche-build
brew uninstall --cask opencoven/tap/psyche-build
```

Use `brew uninstall --cask --zap opencoven/tap/psyche-build` to also remove
the app's confirmed Tauri bundle data. The Cask does not remove `~/.psyche`
or Psyche Build project data.

## How the Casks stay current

The two apps intentionally use different update paths:

- `.github/workflows/update-cask.yml` keeps CovenCave current with the
  existing direct-to-main updater. `scripts/update-cask.sh` requires both
  checksums and downloadable DMGs before it writes the Cask.
- `.github/workflows/update-psyche-build-cask.yml` never pushes main. It
  verifies the complete published Psyche Build release, renders the Cask,
  validates it, and creates or updates a versioned automation pull request.
  A six-hour schedule recovers if the release dispatch is missed.

Psyche Build's release pipeline should send repository dispatch type
`psyche-build-release` with payload `{"tag":"v0.0.1"}`. A maintainer can
recover manually by running the **Update Psyche Build cask** workflow with
tag `v0.0.1`; leaving the tag empty selects the latest stable release.

Every Cask change is style-checked and audited online. CI continues to
install-test CovenCave on both macOS architectures, and automatically adds
native Apple Silicon and Intel install, launch, no-op upgrade, uninstall,
reinstall, and zap tests once `Casks/psyche-build.rb` exists.

Manual bump:

```bash
scripts/update-cask.sh          # latest stable release
scripts/update-cask.sh v0.1.0   # specific tag
```

Offline Psyche Build renderer verification:

```bash
ruby scripts/update-psyche-build-cask.rb \
  --tag v0.0.1 \
  --release-json test/fixtures/psyche-build-v0.0.1-release.json \
  --checksums test/fixtures/psyche-build-v0.0.1-SHA256SUMS \
  --output /tmp/psyche-build.rb
```

## License

MIT — see [coven-cave](https://github.com/OpenCoven/coven-cave) for the
app's own licensing (MIT OR AGPL-3.0-only).
