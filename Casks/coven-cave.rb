cask "coven-cave" do
  arch arm: "aarch64", intel: "x86_64"

  version "0.2.1"
  sha256 arm:   "2c965099b67b39df04f78dabcbaee55c0c2f96816220ca34dc5de25b0a150a40",
         intel: "b4dbe711de02707ecabce0534cc0876d6d5790ba7926ded067ec01233a9c53d4"

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
