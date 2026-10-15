cask "coredeck" do
  version "2.0.0"
  sha256 "4f25f0942f72bbca08a6c201b806893422ca9cf0265d13558275a89fe7725dd1"

  url "https://armako.co.uk/coredeck/CoreDeck-Installer.dmg"
  name "CoreDeck"
  desc "Apple Silicon HUD & remote Linux/VPS telemetry companion"
  homepage "https://armako.co.uk/coredeck/"

  livecheck do
    url :homepage
    regex(/v?(\d+(?:\.\d+)+)/i)
  end

  auto_updates false
  depends_on macos: :ventura
  depends_on arch: :arm64

  app "CoreDeck.app"

  zap trash: [
    "~/Library/Application Support/CoreDeck",
    "~/Library/Preferences/com.arielkap.CoreDeck.plist",
  ]
end
