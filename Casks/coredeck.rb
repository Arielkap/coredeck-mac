cask "coredeck" do
  version "2.0.0"
  sha256 "9819affbe25d7bff7e0bacbb1e6aa50be5293c3b31d0fa8a7b5f71741f6b1956"

  url "https://armako.co.uk/coredeck/CoreDeck-Installer.dmg"
  name "CoreDeck"
  desc "Apple Silicon HUD & remote Linux/VPS telemetry companion"
  homepage "https://armako.co.uk/coredeck/"

  livecheck do
    url :homepage
    regex(/v?(\d+(?:\.\d+)+)/i)
  end

  auto_updates false
  depends_on macos: ">= :ventura"
  depends_on arch: :arm64

  app "CoreDeck.app"

  zap trash: [
    "~/Library/Application Support/CoreDeck",
    "~/Library/Preferences/com.arielkap.CoreDeck.plist",
  ]
end
