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
        case .hostPlaceholder: return "IP Address / Host (e.g. 141.136.44.12)"
        case .userPlaceholder: return "User"
        case .portPlaceholder: return "Port"
        case .sshPasswordAuth: return "SSH Password"
        case .sshKeyAuth: return "SSH Key"
        case .sshPasswordPlaceholder: return "Root password from Hostinger panel"
        case .sshKeyPathPlaceholder: return "Key path (e.g. ~/.ssh/id_ed25519)"
        case .httpInstructions: return "Run 1 command in server terminal to install agent:"
        case .httpUrlPlaceholder: return "URL endpoint (e.g. http://141.136.44.12:9123/stats)"
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
        case .noServerEmptyDesc: return "Configure SSH or HTTP endpoint to monitor remote CPU, RAM, and disk metrics."
        case .configureVpsBtn: return "Configure VPS Server"
            
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
        case .hostPlaceholder: return "Adres IP / Host (np. 141.136.44.12)"
        case .userPlaceholder: return "Użytkownik"
        case .portPlaceholder: return "Port"
        case .sshPasswordAuth: return "Hasło SSH"
        case .sshKeyAuth: return "Klucz SSH"
        case .sshPasswordPlaceholder: return "Hasło roota z panelu Hostinger"
        case .sshKeyPathPlaceholder: return "Ścieżka do klucza (np. ~/.ssh/id_ed25519)"
        case .httpInstructions: return "Uruchom 1 komendę w terminalu serwera, aby zainstalować agenta:"
        case .httpUrlPlaceholder: return "Adres URL (np. http://141.136.44.12:9123/stats)"
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
        case .noServerEmptyDesc: return "Dodaj tabelę serwerów lub wprowadź adres swojego VPS-a, aby odbierać telemetrię CPU, RAM i dysku."
        case .configureVpsBtn: return "Wprowadź dane serwera VPS"
            
        case .compactBar: return "Kompaktowy pasek"
        case .launchAtLogin: return "Autostart przy logowaniu"
        case .commandCopied: return "🟢 Skopiowano komendę do schowka!"
        }
    }
}
