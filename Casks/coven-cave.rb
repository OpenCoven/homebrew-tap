cask "coven-cave" do
  arch arm: "aarch64", intel: "x86_64"

  version "0.5.5"
  sha256 arm:   "b0c5ca70e6c1b6f0d8c0efbdb8f8ff8fb9c11cf88a94661778f50e32573e2269",
         intel: "fa1424f54e67db4b63d29dc6759f23663b816b1a38e83b9a394ab2c521738e57"

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
