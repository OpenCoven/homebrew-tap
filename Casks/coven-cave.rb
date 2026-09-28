cask "coven-cave" do
  arch arm: "aarch64", intel: "x86_64"

  version "0.5.2"
  sha256 arm:   "2f4106a9c2cdfa4f7d18d0e3e77ceb4fa00b54816137ac56094dfa110052deb0",
         intel: "72f7e7ac2245dd3c45e5ab25d9b74dabd9878a14ab57cda9c24d765de2c35e4e"

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
