cask "coredeck" do
  version "2.0.0"
  sha256 "46805869904fc60a3c633d152b3ec3bc6d509dbe7a680d685697268970728f0d"

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
