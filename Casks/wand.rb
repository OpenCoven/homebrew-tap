cask "wand" do
  version "0.0.25"
  sha256 "b97331c7140124d938548a6f855e1ded490ee9bf1ab699a701396af14aac6262"

  url "https://github.com/OpenCoven/wand-releases/releases/download/v#{version}/Wand-macOS.zip"
  name "Wand"
  desc "Menu bar companion that sends reviewed context to your Coven familiars"
  homepage "https://github.com/OpenCoven/wand-releases"

  livecheck do
    url :url
    strategy :github_releases
  end

  # Wand updates itself from Settings > Updates after verifying the Developer ID
  # signature, notarization, team and bundle identifier of the download.
  auto_updates true
  depends_on macos: :tahoe

  app "Wand.app"

  uninstall quit: "ai.opencoven.wand"

  zap trash: [
    "~/Library/Application Support/OpenCoven/Wand",
    "~/Library/Caches/ai.opencoven.wand",
    "~/Library/HTTPStorages/ai.opencoven.wand",
    "~/Library/Preferences/ai.opencoven.wand.plist",
    "~/Library/Saved Application State/ai.opencoven.wand.savedState",
  ]
end
