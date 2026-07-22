cask "coven-cave" do
  arch arm: "aarch64", intel: "x86_64"

  version "0.1.6"
  sha256 arm:   "1fee0a9f65137a77682b2466cbd21fba8feee783ad89cea13f96b1d0fb587841",
         intel: "4ba5392de960bc72163bdfd011112fea630d2061b2fef7a5fa2612db8b8191ab"

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
