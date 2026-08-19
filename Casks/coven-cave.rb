cask "coven-cave" do
  arch arm: "aarch64", intel: "x86_64"

  version "0.3.7"
  sha256 arm:   "5478f00e51c1d449d2eebef098f92a1c90f8f77860f2d7c6615b3fdc11ed6d88",
         intel: "fc9da20e86ad645e27456af481761a4bf19fbabd5f3bf3b1003fe42905a59aa4"

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
