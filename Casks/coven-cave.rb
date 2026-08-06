cask "coven-cave" do
  arch arm: "aarch64", intel: "x86_64"

  version "0.2.4"
  sha256 arm:   "eba9b09ab7bb2809cdfb2764ac3f9e790f5540b44fc9d7cc6f7a1fdfdc64a295",
         intel: "2443c43ca4b2c1420cf75d172cbfba4cee8f8d451c720fd2ea3d0565cc0b6594"

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
