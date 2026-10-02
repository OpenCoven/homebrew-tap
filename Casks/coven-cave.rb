cask "coven-cave" do
  arch arm: "aarch64", intel: "x86_64"

  version "0.5.6"
  sha256 arm:   "93ac74a794fab0dc3791d2817150cd86877794f00dfea953018640241dfabbfc",
         intel: "b2a1b3265c631d5848eaeffb976e5de439e9ad071d69b4562e9c0cddef49b6c9"

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
