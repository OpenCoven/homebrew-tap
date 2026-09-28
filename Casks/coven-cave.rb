cask "coven-cave" do
  arch arm: "aarch64", intel: "x86_64"

  version "0.5.1"
  sha256 arm:   "c0108210bf3b00f166a5b904b59545cd191bb97f6f33ee4b9759863142ce10c8",
         intel: "d73fc58099b2ffc45fdad2b6dc134626d9d0e6d8038eca2805e8afa53a044e47"

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
