cask "coven-cave" do
  arch arm: "aarch64", intel: "x86_64"

  version "0.5.14"
  sha256 arm:   "5caf83743a3186997d4667534d7ad5264f5ec2902c1e2ef02f5a108750d6a9cd",
         intel: "63d228684cc79c396736bbf92790b5f6d042be13d15d1cea64621d615872cf10"

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
