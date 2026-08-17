cask "coven-cave" do
  arch arm: "aarch64", intel: "x86_64"

  version "0.3.6"
  sha256 arm:   "237894f60fc2ae084d9d396a8a93596e21174dd406b6654dac9d2e5680b5ef29",
         intel: "0e1e4c96651ca1bd0914d37fc8bfa7997f6b1071622f569a23e5adfec451f9fa"

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
