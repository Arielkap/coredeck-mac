import Foundation

public enum AppLanguage: String, Codable, CaseIterable, Sendable {
    case en = "en"
    case pl = "pl"
    
    public var flag: String {
        switch self {
        case .en: return "🇬🇧"
        case .pl: return "🇵🇱"
        }
    }
    
    public var code: String {
        switch self {
        case .en: return "EN"
        case .pl: return "PL"
        }
    }
    
    public var title: String {
        switch self {
        case .en: return "English"
        case .pl: return "Polski"
        }
    }
}

public enum L10nKey: Sendable {
    // Header & Reactor
    case fleetHudSubtitle
    case proTag
    case upgradeBtn
    case optimal
    case elevated
    case criticalLoad
    case reactorOptimalTitle
    case reactorOptimalBody
    case reactorElevatedTitle
    case reactorElevatedBody
    case reactorCriticalTitle
    case reactorCriticalBody
    
    // License
    case activateProTitle
    case activateProDesc
    case licenseKeyPlaceholder
    case activateBtn
    case buyLicensePrompt
    case enterKeyError
    case networkError
    case invalidKeyError
    case proActive
    case freeEvaluation
    
    // Memory Gauges
    case unifiedMemory
    case swapMemory
    case diskApfs
    case wired
    case active
    case compressed
    case free
    
    // Top Hogs
    case topMemoryHogs
    case topMemoryHogsPro
    case topMemoryHogsFree
    case actionsHeader
    case actionsPro
    case noHogsFound
    case term
    case kill
    
    // Quick Actions
    case flushCache
    case flushCachePro
    case ejectAi
    case ejectAiPro
    case coffeeTitle
    case coffeeTitlePro
    case coffeeActive
    case coffeeNormal
    case coffeeDurationPrompt
    
    // VPS & Fleet
    case vpsTelemetryTitle
    case closeBtn
    case serversBtn
    case configureBtn
    case serversTableTitle
    case addServer
    case activeBadge
    case noServersConfiguredPrompt
    case editServerTitle
    case addServerTitle
    case sshTab
    case httpTab
    case serverNamePlaceholder
    case sshInstructions
    case hostPlaceholder
    case userPlaceholder
    case portPlaceholder
    case sshPasswordAuth
    case sshKeyAuth
    case sshPasswordPlaceholder
    case sshKeyPathPlaceholder
    case httpInstructions
    case httpUrlPlaceholder
    case httpKeyPlaceholder
    case testBtn
    case testingConnection
    case cancelBtn
    case saveServerBtn
    case connectingTo
    case checkBtn
    case vpsPromoDesc
    case unlockVpsPro
    case noServerEmptyTitle
    case noServerEmptyDesc
    case configureVpsBtn
    
    // VPS Manager Window (v2.2)
    case vpsWindowTitle
    case vpsWindowSubtitle
    case magicPasteLabel
    case magicPastePlaceholder
    case magicPasteHint
    case parsedPreviewPrefix
    case advancedOptions
    case chooseKeyFileBtn
    case connectAndSaveBtn
    case saveAnywayBtn
    case serverNameOptionalLabel
    case serverNameAutoHint
    case connectionModeLabel
    case quickSshMode
    case httpAgentMode
    case sshErrAuth
    case sshErrTimeout
    case sshErrRefused
    case sshErrDns
    case sshErrHostKey
    case sshErrKeyPerm
    case sshErrKeyMissing
    case sshErrGeneric
    case httpErrGeneric
    case connectedSummary
    case keychainNotice
    
    // Footer
    case compactBar
    case launchAtLogin
    case commandCopied
}

public struct L10n {
    public static func text(_ key: L10nKey, lang: AppLanguage) -> String {
        switch lang {
        case .en:
            return english(key)
        case .pl:
            return polish(key)
        }
    }
    
    private static func english(_ key: L10nKey) -> String {
        switch key {
        case .fleetHudSubtitle: return "APPLE SILICON & FLEET HUD"
        case .proTag: return "PRO"
        case .upgradeBtn: return "UPGRADE"
        case .optimal: return "OPTIMAL"
        case .elevated: return "ELEVATED"
        case .criticalLoad: return "CRITICAL LOAD"
        case .reactorOptimalTitle: return "Memory looks great"
        case .reactorOptimalBody: return "RAM and Swap are in the safe zone. No action needed."
        case .reactorElevatedTitle: return "Memory getting tight"
        case .reactorElevatedBody: return "macOS is starting to use disk Swap.\n• Click 'Flush Cache' if the Mac feels sluggish.\n• Close unused browser tabs or heavy apps below."
        case .reactorCriticalTitle: return "High memory pressure!"
        case .reactorCriticalBody: return "RAM is nearly full or Swap is heavy, which slows down your Mac.\n• Click 'Flush Cache' or 'Purge VRAM & Cache'.\n• Close top memory hogs (TERM / KILL) in the list below."
            
        case .activateProTitle: return "ACTIVATE COREDECK PRO (LIFETIME)"
        case .activateProDesc: return "Unlock instant process termination, universal VRAM & memory purger, and remote VPS telemetry."
        case .licenseKeyPlaceholder: return "Enter license key (e.g. CORE-XXXX-XXXX)"
        case .activateBtn: return "Activate"
        case .buyLicensePrompt: return "Don't have a key? Buy lifetime license ($14.99) →"
        case .enterKeyError: return "Please enter a license key"
        case .networkError: return "Network configuration error"
        case .invalidKeyError: return "Invalid license key"
        case .proActive: return "⭐️ Pro License (Active)"
        case .freeEvaluation: return "Free Evaluation Version"
            
        case .unifiedMemory: return "UNIFIED MEMORY (RAM)"
        case .swapMemory: return "SWAP MEMORY"
        case .diskApfs: return "DISK APFS"
        case .wired: return "WIRED"
        case .active: return "ACTIVE"
        case .compressed: return "COMPR."
        case .free: return "FREE"
            
        case .topMemoryHogs: return "TOP MEMORY CONSUMERS"
        case .topMemoryHogsPro: return "TOP MEMORY HOGS (PRO: 5)"
        case .topMemoryHogsFree: return "TOP MEMORY HOGS (FREE: 3)"
        case .actionsHeader: return "PID / ACTIONS"
        case .actionsPro: return "ACTIONS [🔒 PRO]"
        case .noHogsFound: return "No heavy processes found"
        case .term: return "TERM"
        case .kill: return "KILL"
            
        case .flushCache: return "Flush Cache"
        case .flushCachePro: return "Flush Cache [PRO]"
        case .ejectAi: return "Purge VRAM & Cache"
        case .ejectAiPro: return "Purge VRAM [PRO]"
        case .coffeeTitle: return "Anti-Sleep (Coffee Mode)"
        case .coffeeTitlePro: return "Anti-Sleep [PRO]"
        case .coffeeActive: return "Active (Prevent Sleep)"
        case .coffeeNormal: return "Normal Display Sleep"
        case .coffeeDurationPrompt: return "Select Duration"
            
        case .vpsTelemetryTitle: return "REMOTE VPS TELEMETRY"
        case .closeBtn: return "Close"
        case .serversBtn: return "Servers"
        case .configureBtn: return "Configure"
        case .serversTableTitle: return "VPS SERVERS TABLE"
        case .addServer: return "Add server"
        case .activeBadge: return "ACTIVE"
        case .noServersConfiguredPrompt: return "No servers configured. Click 'Add server' to enter connection details."
        case .editServerTitle: return "EDIT VPS SERVER"
        case .addServerTitle: return "ADD VPS SERVER"
        case .sshTab: return "SSH (Hostinger / VPS)"
        case .httpTab: return "HTTP Agent (1-Liner)"
        case .serverNamePlaceholder: return "Server name (e.g. Production VPS)"
        case .sshInstructions: return "Paste credentials from Hostinger panel (SSH Access tab):"
        case .hostPlaceholder: return "IP Address / Host (e.g. 203.0.113.10)"
        case .userPlaceholder: return "User"
        case .portPlaceholder: return "Port"
        case .sshPasswordAuth: return "SSH Password"
        case .sshKeyAuth: return "SSH Key"
        case .sshPasswordPlaceholder: return "Root password from Hostinger panel"
        case .sshKeyPathPlaceholder: return "Key path (e.g. ~/.ssh/id_ed25519)"
        case .httpInstructions: return "Run 1 command in server terminal to install agent:"
        case .httpUrlPlaceholder: return "URL endpoint (e.g. http://203.0.113.10:9123/stats)"
        case .httpKeyPlaceholder: return "API Key / Token (from installer)"
        case .testBtn: return "Test"
        case .testingConnection: return "Testing connection..."
        case .cancelBtn: return "Cancel"
        case .saveServerBtn: return "Save server"
        case .connectingTo: return "Connecting to node"
        case .checkBtn: return "Check"
        case .vpsPromoDesc: return "Monitor your remote VPS instances directly from the Mac menu bar in real-time."
        case .unlockVpsPro: return "Unlock VPS telemetry in Pro version"
        case .noServerEmptyTitle: return "No VPS server configured"
        case .noServerEmptyDesc: return "Connect any Linux VPS in 15 seconds to monitor CPU, RAM, and disk from your menu bar."
        case .configureVpsBtn: return "Add VPS Server"
            
        case .vpsWindowTitle: return "VPS Servers"
        case .vpsWindowSubtitle: return "Paste your server IP or SSH command — CoreDeck handles the rest."
        case .magicPasteLabel: return "Server address or SSH command"
        case .magicPastePlaceholder: return "e.g. ssh root@203.0.113.10  or  203.0.113.10" // # opsec-ignore
        case .magicPasteHint: return "Paste directly from Hostinger, Hetzner, DigitalOcean, OVH, or any VPS panel."
        case .parsedPreviewPrefix: return "Detected:"
        case .advancedOptions: return "Advanced options (Name, Port, SSH Key, HTTP Agent)"
        case .chooseKeyFileBtn: return "Browse..."
        case .connectAndSaveBtn: return "Connect & Save"
        case .saveAnywayBtn: return "Save anyway"
        case .serverNameOptionalLabel: return "Display name (optional)"
        case .serverNameAutoHint: return "Leave blank to auto-detect hostname"
        case .connectionModeLabel: return "Connection mode"
        case .quickSshMode: return "SSH (Recommended)"
        case .httpAgentMode: return "HTTP Agent (1-Liner)"
        case .sshErrAuth: return "Wrong password or username. Check if your server uses 'root' or 'ubuntu', or verify your SSH key."
        case .sshErrTimeout: return "Server did not respond (timeout). Check the IP address, port, or firewall rules."
        case .sshErrRefused: return "Connection refused. Verify the SSH port (default 22) and make sure the server is running."
        case .sshErrDns: return "Address not found. Check for typos in the IP address or domain name."
        case .sshErrHostKey: return "Server identity changed (e.g. after OS reinstall). Remove old entry from ~/.ssh/known_hosts."
        case .sshErrKeyPerm: return "SSH key file permissions are too open. Run: chmod 600 on your key file."
        case .sshErrKeyMissing: return "SSH key file not found. Select a valid key file or switch to Password."
        case .sshErrGeneric: return "Could not connect via SSH. Verify the address, port, and credentials."
        case .httpErrGeneric: return "No valid response from HTTP Agent URL. Check the URL, port, and API token."
        case .connectedSummary: return "Connected to"
        case .keychainNotice: return "Passwords & tokens are stored securely in macOS Keychain"
            
        case .compactBar: return "Compact menu bar"
        case .launchAtLogin: return "Launch at login"
        case .commandCopied: return "🟢 Command copied to clipboard!"
        }
    }
    
    private static func polish(_ key: L10nKey) -> String {
        switch key {
        case .fleetHudSubtitle: return "APPLE SILICON & FLEET HUD"
        case .proTag: return "PRO"
        case .upgradeBtn: return "ULEPSZ"
        case .optimal: return "OPTYMALNY"
        case .elevated: return "PODWYŻSZONY"
        case .criticalLoad: return "KRYTYCZNY"
        case .reactorOptimalTitle: return "Pamięć w świetnej formie"
        case .reactorOptimalBody: return "Zużycie RAM i Swap mieści się w normie. Nie musisz nic robić."
        case .reactorElevatedTitle: return "Rośnie zużycie pamięci"
        case .reactorElevatedBody: return "System zaczyna przerzucać dane na dysk (Swap).\n• Kliknij «Wyczyść Cache», jeśli Mac zwolni.\n• Zamknij zbędne karty lub ciężkie aplikacje poniżej."
        case .reactorCriticalTitle: return "Krytyczne obciążenie pamięci!"
        case .reactorCriticalBody: return "RAM jest prawie pełny lub Swap mocno rośnie — Mac może przycinać.\n• Kliknij «Wyczyść Cache» lub «Zwolnij VRAM & Cache».\n• Zamknij największe procesy (TERM / KILL) z listy poniżej."
            
        case .activateProTitle: return "AKTYWUJ COREDECK PRO (DOŻYWOTNIA)"
        case .activateProDesc: return "Odblokuj natychmiastowe zabijanie procesów, zwalnianie pamięci VRAM/Cache i telemetrię serwerów VPS."
        case .licenseKeyPlaceholder: return "Wpisz klucz (np. CORE-XXXX-XXXX)"
        case .activateBtn: return "Aktywuj"
        case .buyLicensePrompt: return "Nie masz klucza? Kup dożywotnią licencję ($14.99) →"
        case .enterKeyError: return "Wprowadź klucz licencyjny"
        case .networkError: return "Błąd konfiguracji sieci"
        case .invalidKeyError: return "Niepoprawny klucz licencyjny"
        case .proActive: return "⭐️ Licencja Pro (Aktywna)"
        case .freeEvaluation: return "Wersja Free (Ewaluacyjna)"
            
        case .unifiedMemory: return "PAMIĘĆ UNIFIED (RAM)"
        case .swapMemory: return "PAMIĘĆ SWAP"
        case .diskApfs: return "DYSK APFS"
        case .wired: return "PRYWATNA"
        case .active: return "AKTYWNA"
        case .compressed: return "SKOMPR."
        case .free: return "WOLNE"
            
        case .topMemoryHogs: return "NAJWIĘKSZE PROCESY (RAM)"
        case .topMemoryHogsPro: return "NAJWIĘKSZE PROCESY (PRO: 5)"
        case .topMemoryHogsFree: return "NAJWIĘKSZE PROCESY (FREE: 3)"
        case .actionsHeader: return "PID / AKCJE"
        case .actionsPro: return "AKCJE [🔒 PRO]"
        case .noHogsFound: return "Brak obciążających procesów"
        case .term: return "TERM"
        case .kill: return "KILL"
            
        case .flushCache: return "Wyczyść Cache"
        case .flushCachePro: return "Wyczyść Cache [PRO]"
        case .ejectAi: return "Zwolnij VRAM & Cache"
        case .ejectAiPro: return "Zwolnij VRAM [PRO]"
        case .coffeeTitle: return "Tryb Kawki (Anty-Uśpienie)"
        case .coffeeTitlePro: return "Tryb Kawki [PRO]"
        case .coffeeActive: return "Kawka Aktywna (Czuwanie)"
        case .coffeeNormal: return "Normalne Uśpienie Ekranu"
        case .coffeeDurationPrompt: return "Wybierz czas trwania"
            
        case .vpsTelemetryTitle: return "TELEMETRIA SERWERA VPS"
        case .closeBtn: return "Zamknij"
        case .serversBtn: return "Serwery"
        case .configureBtn: return "Konfiguruj"
        case .serversTableTitle: return "TABELA SERWERÓW VPS"
        case .addServer: return "Dodaj serwer"
        case .activeBadge: return "AKTYWNY"
        case .noServersConfiguredPrompt: return "Brak skonfigurowanych serwerów. Kliknij 'Dodaj serwer', aby wprowadzić dane połączenia."
        case .editServerTitle: return "EDYCJA SERWERA VPS"
        case .addServerTitle: return "DODAJ SERWER VPS"
        case .sshTab: return "SSH (Hostinger / VPS)"
        case .httpTab: return "HTTP Agent (1-Liner)"
        case .serverNamePlaceholder: return "Nazwa serwera (np. Serwer Produkcyjny)"
        case .sshInstructions: return "Wklej dane z panelu Hostinger (zakładka Dostęp SSH):"
        case .hostPlaceholder: return "Adres IP / Host (np. 203.0.113.10)"
        case .userPlaceholder: return "Użytkownik"
        case .portPlaceholder: return "Port"
        case .sshPasswordAuth: return "Hasło SSH"
        case .sshKeyAuth: return "Klucz SSH"
        case .sshPasswordPlaceholder: return "Hasło roota z panelu Hostinger"
        case .sshKeyPathPlaceholder: return "Ścieżka do klucza (np. ~/.ssh/id_ed25519)"
        case .httpInstructions: return "Uruchom 1 komendę w terminalu serwera, aby zainstalować agenta:"
        case .httpUrlPlaceholder: return "Adres URL (np. http://203.0.113.10:9123/stats)"
        case .httpKeyPlaceholder: return "Klucz API / Token (z instalatora)"
        case .testBtn: return "Testuj"
        case .testingConnection: return "Testowanie połączenia..."
        case .cancelBtn: return "Anuluj"
        case .saveServerBtn: return "Zapisz serwer"
        case .connectingTo: return "Łączenie z węzłem"
        case .checkBtn: return "Sprawdź"
        case .vpsPromoDesc: return "Monitoruj stan swoich serwerów VPS bezpośrednio z menu bara Maca w czasie rzeczywistym."
        case .unlockVpsPro: return "Odblokuj telemetrię VPS w wersji Pro"
        case .noServerEmptyTitle: return "Brak skonfigurowanego serwera VPS"
        case .noServerEmptyDesc: return "Podłącz dowolny serwer Linux/VPS w 15 sekund, aby monitorować RAM, obciążenie i dysk z paska menu."
        case .configureVpsBtn: return "Dodaj serwer VPS"
            
        case .vpsWindowTitle: return "Serwery VPS"
        case .vpsWindowSubtitle: return "Wklej adres IP lub komendę SSH z panelu — CoreDeck sam uzupełni resztę."
        case .magicPasteLabel: return "Adres serwera lub komenda SSH"
        case .magicPastePlaceholder: return "np. ssh root@203.0.113.10  lub  203.0.113.10" // # opsec-ignore
        case .magicPasteHint: return "Wklej prosto z panelu Hostinger, Hetzner, OVH, DigitalOcean, Mikrus itp."
        case .parsedPreviewPrefix: return "Rozpoznano:"
        case .advancedOptions: return "Ustawienia zaawansowane (Nazwa, Port, Klucz SSH, HTTP Agent)"
        case .chooseKeyFileBtn: return "Wybierz plik..."
        case .connectAndSaveBtn: return "Połącz i zapisz"
        case .saveAnywayBtn: return "Zapisz mimo błędu"
        case .serverNameOptionalLabel: return "Nazwa własna (opcjonalnie)"
        case .serverNameAutoHint: return "Zostaw puste, aby pobrać nazwę z serwera"
        case .connectionModeLabel: return "Tryb połączenia"
        case .quickSshMode: return "SSH (Zalecane)"
        case .httpAgentMode: return "HTTP Agent (1-Liner)"
        case .sshErrAuth: return "Złe hasło lub nazwa użytkownika. Sprawdź, czy logujesz się jako 'root' czy 'ubuntu', albo wybierz właściwy klucz."
        case .sshErrTimeout: return "Serwer nie odpowiada (timeout). Sprawdź adres IP, port albo zaporę sieciową (firewall)."
        case .sshErrRefused: return "Serwer odrzucił połączenie. Sprawdź port SSH (domyślnie 22) i upewnij się, że serwer działa."
        case .sshErrDns: return "Nie znaleziono takiego adresu. Sprawdź literówki w adresie IP lub domenie."
        case .sshErrHostKey: return "Tożsamość serwera się zmieniła (np. po reinstalacji systemu). Usuń stary wpis w ~/.ssh/known_hosts."
        case .sshErrKeyPerm: return "Plik klucza SSH ma zbyt otwarte uprawnienia. Uruchom chmod 600 na pliku klucza."
        case .sshErrKeyMissing: return "Nie znaleziono pliku klucza SSH. Wybierz istniejący klucz lub przełącz na hasło."
        case .sshErrGeneric: return "Nie udało się połączyć przez SSH. Sprawdź adres, port oraz dane logowania."
        case .httpErrGeneric: return "Brak odpowiedzi od agenta HTTP. Sprawdź adres URL, port oraz token API."
        case .connectedSummary: return "Połączono z"
        case .keychainNotice: return "Hasła i tokeny są bezpiecznie szyfrowane w Pęku Kluczy macOS"
            
        case .compactBar: return "Kompaktowy pasek"
        case .launchAtLogin: return "Autostart przy logowaniu"
        case .commandCopied: return "🟢 Skopiowano komendę do schowka!"
        }
    }
}
