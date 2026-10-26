cask "coven-cave" do
  arch arm: "aarch64", intel: "x86_64"

  version "0.5.17"
  sha256 arm:   "ee1287697c26878241af22d5a496de2b6ca426d5f3efea5bad50cc0aeb7cb345",
         intel: "d27b35d4fce208058f382a39a35911cefedd384761c4aab9bb8c722c5eff0753"

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
