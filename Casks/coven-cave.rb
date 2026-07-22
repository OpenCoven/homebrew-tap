cask "coven-cave" do
  arch arm: "aarch64", intel: "x86_64"

  version "0.1.5"
  sha256 arm:   "55f38994c63b34ed40c797b867997e0ed1a5f75db4c29b2df75d48b38c15fb21",
         intel: "7dcd9fcbb0a382b0653576b0e48681d2079b77bbaeefab8504d3d770a1523369"

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
