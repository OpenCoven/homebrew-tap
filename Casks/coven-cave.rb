cask "coven-cave" do
  arch arm: "aarch64", intel: "x86_64"

  version "0.3.11"
  sha256 arm:   "e9c86a9ed60435d83ab6aad06acbbd78ad84da168c283f1633c2063a202e916b",
         intel: "3e045ef8b40aa709705f29a9d9dc850ef0d6b2676edc1be927d084dbd2c7728a"

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
