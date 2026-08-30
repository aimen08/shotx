cask "shotx" do
  version "1.9.9"
  sha256 "590086071eeaa38248e452c439080040ef8f6a09ec42bbddab875305a471f338"

  url "https://github.com/aimen08/shotx/releases/download/v#{version}/ShotX-#{version}.dmg",
      verified: "github.com/aimen08/shotx/"
  name "ShotX"
  desc "Modern macOS screen capture for the menu bar"
  homepage "https://github.com/aimen08/shotx"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true
  depends_on macos: ">= :ventura"

  app "ShotX.app"

  zap trash: [
    "~/Library/Application Support/ShotX",
    "~/Library/Caches/com.shotx.app",
    "~/Library/Preferences/com.shotx.app.plist",
    "~/Library/Saved Application State/com.shotx.app.savedState",
    "~/Library/HTTPStorages/com.shotx.app",
  ]
end
