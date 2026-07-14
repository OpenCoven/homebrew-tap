#!/usr/bin/env bash
# Regenerate Casks/coven-cave.rb from a CovenCave GitHub release.
#
# Usage:
#   scripts/update-cask.sh            # latest stable release
#   scripts/update-cask.sh v0.1.0     # specific tag
#
# Reads the release's SHA256SUMS asset, extracts the per-arch DMG
# checksums, verifies both DMGs are actually downloadable, and renders
# the cask. Any missing artifact or checksum is fatal, so a partial or
# still-uploading release can never produce a broken cask.
set -euo pipefail

REPO="OpenCoven/coven-cave"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CASK="$ROOT/Casks/coven-cave.rb"

TAG="${1:-}"

if [ -z "$TAG" ]; then
  auth=()
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    auth=(-H "Authorization: Bearer $GITHUB_TOKEN")
  fi
  TAG="$(
    curl -fsSL "${auth[@]}" -H "Accept: application/vnd.github+json" \
      "https://api.github.com/repos/$REPO/releases/latest" \
      | python3 -c 'import json,sys; print(json.load(sys.stdin)["tag_name"])'
  )"
fi

if ! printf '%s' "$TAG" | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "error: tag '$TAG' is not a stable vX.Y.Z release tag" >&2
  exit 1
fi
VERSION="${TAG#v}"

BASE="https://github.com/$REPO/releases/download/$TAG"
SUMS="$(curl -fsSL "$BASE/SHA256SUMS")"

sha_for() {
  local name="$1" sha
  sha="$(printf '%s\n' "$SUMS" | awk -v n="$name" '$2 == n { print $1 }')"
  if [ -z "$sha" ]; then
    echo "error: no SHA256 entry for $name in $TAG's SHA256SUMS" >&2
    exit 1
  fi
  printf '%s' "$sha"
}

ARM_SHA="$(sha_for "CovenCave-$TAG-aarch64.dmg")"
INTEL_SHA="$(sha_for "CovenCave-$TAG-x86_64.dmg")"

for arch in aarch64 x86_64; do
  curl -fsIL -o /dev/null "$BASE/CovenCave-$TAG-$arch.dmg" || {
    echo "error: $BASE/CovenCave-$TAG-$arch.dmg is not downloadable" >&2
    exit 1
  }
done

cat > "$CASK" <<EOF
cask "coven-cave" do
  arch arm: "aarch64", intel: "x86_64"

  version "$VERSION"
  sha256 arm:   "$ARM_SHA",
         intel: "$INTEL_SHA"

  url "https://github.com/OpenCoven/coven-cave/releases/download/v#{version}/CovenCave-v#{version}-#{arch}.dmg"
  name "CovenCave"
  name "Coven Cave"
  desc "Desktop control room for OpenCoven familiars and local agent sessions"
  homepage "https://github.com/OpenCoven/coven-cave"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true
  depends_on :macos

  app "CovenCave.app"

  zap trash: [
    "~/Library/Application Support/ai.opencoven.cave",
    "~/Library/Caches/ai.opencoven.cave",
    "~/Library/Preferences/ai.opencoven.cave.plist",
    "~/Library/Saved Application State/ai.opencoven.cave.savedState",
    "~/Library/WebKit/ai.opencoven.cave",
  ]
end
EOF

echo "rendered Casks/coven-cave.rb for $TAG"
echo "  arm:   $ARM_SHA"
echo "  intel: $INTEL_SHA"
