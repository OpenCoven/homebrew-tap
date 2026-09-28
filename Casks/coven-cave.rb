cask "coven-cave" do
  arch arm: "aarch64", intel: "x86_64"

  version "0.5.3"
  sha256 arm:   "eb857160c0672aa9eaf65ff44d4509734e908352ab292937a93f5861cc0ce109",
         intel: "72bb14ad226c311bb8415709b0c8fd43976233cec9d2137dcc4e7086a9d19829"

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
