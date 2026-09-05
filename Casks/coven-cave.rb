cask "coven-cave" do
  arch arm: "aarch64", intel: "x86_64"

  version "0.4.0"
  sha256 arm:   "d87e8be1c19398798d120acac068ac76cd0cec412cb3293c62b1c74e2018daa8",
         intel: "294ca7960b4d83fe9fa3d2ec68c969b7d1d324ca9f853d5a971a4a182f85edc0"

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
