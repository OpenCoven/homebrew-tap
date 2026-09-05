cask "coven-cave" do
  arch arm: "aarch64", intel: "x86_64"

  version "0.3.13"
  sha256 arm:   "72f6da4a713d98fccadb8cf67f09ab672732d14c9c05e5140c5958dd0927ad3c",
         intel: "24a2882b540ef6892b98dfb5b6d4652c523138b581c9a7227198bdbaf970334c"

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
