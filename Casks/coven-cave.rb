cask "coven-cave" do
  arch arm: "aarch64", intel: "x86_64"

  version "0.3.9"
  sha256 arm:   "e3fb24e44e05142f97b9e7ed72f1bcb0ab37dc7556af4a6e4edacb9a81758560",
         intel: "752eedbc2929e03d4174cc3701ebe0311c78bd148460a138cee1cab9cfdad838"

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
