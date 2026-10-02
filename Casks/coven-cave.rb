cask "coven-cave" do
  arch arm: "aarch64", intel: "x86_64"

  version "0.5.7"
  sha256 arm:   "31613051aa1f144a0b52fc4e529243eb0ea61047a4fcd6b5db715f7cecfad25c",
         intel: "035fdd2c25fa91f42ff59ccaba4d49b1e5232446eddfb49c40c5d47033305678"

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
