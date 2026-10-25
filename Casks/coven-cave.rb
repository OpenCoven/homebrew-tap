cask "coven-cave" do
  arch arm: "aarch64", intel: "x86_64"

  version "0.5.15"
  sha256 arm:   "145edd555749c870cd482fba5746fdf2e4d987eeb43894b8a5ab2fbf784cad65",
         intel: "907a2b1a7b90145fbb75b581d642697f5b72dcccc3d8dfce229e4413c6cbf034"

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
