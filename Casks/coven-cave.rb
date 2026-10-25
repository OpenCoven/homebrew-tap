cask "coven-cave" do
  arch arm: "aarch64", intel: "x86_64"

  version "0.5.16"
  sha256 arm:   "d04478e9482d766064748e0fdac563b8c26f4f2e07d4299e0b97018232b473ea",
         intel: "2cee58d0537b477f676a4323eef8a646137bae07f27a36be302c329ac0a7fef3"

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
