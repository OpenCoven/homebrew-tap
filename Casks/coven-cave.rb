cask "coven-cave" do
  arch arm: "aarch64", intel: "x86_64"

  version "0.3.12"
  sha256 arm:   "02d7287801f07a7c5132148ac76d8ae54974f00a57d41c7cd60b4a73345ad428",
         intel: "ab64f9675bde27966137236505692342b0c16ccc1be8d07cd80b1ff912cd1015"

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
