cask "coven-cave" do
  arch arm: "aarch64", intel: "x86_64"

  version "0.1.4"
  sha256 arm:   "2229fcd656ef63945cab37e8f6f4aceb32d51aae65e3284ec09ecc93b4e10eb9",
         intel: "9be20f41dc0a280455d2904fdaa8790d58001538dcfc9c25244ee1189c41d33e"

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
