cask "coven-cave" do
  arch arm: "aarch64", intel: "x86_64"

  version "0.2.3"
  sha256 arm:   "f88bdf88bc417674e55d78e184c24d0f958b7c597ae7372afb2647ae1306566a",
         intel: "72581d841374c51e13bdf1db130407d6cf7aa4d953039d47810b0c4ecf968b92"

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
