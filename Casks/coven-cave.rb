cask "coven-cave" do
  arch arm: "aarch64", intel: "x86_64"

  version "0.5.18"
  sha256 arm:   "04e56490ce7d0d28c2f66976e42276b888b8385820f0fdd1286e262046e5d665",
         intel: "06e6ac629fdc303a59a1153cea9a86eee83ba0eb86261fc2b3e59709a2ffd27e"

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
