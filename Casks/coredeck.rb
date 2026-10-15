cask "coredeck" do
  version "2.1.0"
  sha256 "af9fcc0ade33fd22bd8863b4d66561f7249c7ae82defe783eedbdfe8e9e2de85"

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
