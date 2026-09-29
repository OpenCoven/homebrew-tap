cask "coven-cave" do
  arch arm: "aarch64", intel: "x86_64"

  version "0.5.4"
  sha256 arm:   "c3196b24ca5b975d41f3e16453904ef34ddf8b4fabc91f9f4b9bc6a3d9bb8ec9",
         intel: "665d968cfba6bb2e6402b16c93be83804467ee4933ccca36b10b7a2a8d4cfb5e"

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
