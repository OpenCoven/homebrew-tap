# frozen_string_literal: true

cask "psyche-build" do
  arch arm: "aarch64", intel: "x86_64"

  version "0.0.1"
  sha256 arm:   "e0c8cce02cedc7b7cc122c4b453da8ccc665f42da457aa571c2c476d3f03c74f",
         intel: "c6d62f8aeea1570f377fe6bc2d5c90f5b6a4701390af1c42073465f2a586e882"

  url "https://github.com/OpenCoven/psyche-build/releases/download/v#{version}/Psyche-Build-v#{version}-#{arch}.dmg"
  name "Psyche Build"
  desc "Multiagent coding harness for parallel agent lanes"
  homepage "https://github.com/OpenCoven/psyche-build"

  depends_on macos: :monterey

  app "Psyche Build.app"

  zap trash: [
    "~/Library/Application Support/dev.opencoven.psyche",
    "~/Library/Caches/dev.opencoven.psyche",
    "~/Library/Preferences/dev.opencoven.psyche.plist",
    "~/Library/Saved Application State/dev.opencoven.psyche.savedState",
    "~/Library/WebKit/dev.opencoven.psyche",
  ]
end
