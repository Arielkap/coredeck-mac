import Foundation
import SwiftUI
import Combine
import ServiceManagement

@MainActor
public final class AppState: ObservableObject {
    @Published public var stats: SystemTelemetry.LocalStats
    @Published public var hogs: [ProcessHog] = []
    
    // Server / VPS Telemetry & Management
    @Published public var servers: [VpsServerConfig] = []
    @Published public var selectedServerId: UUID? = nil
    @Published public var vps: VpsTelemetry?
    @Published public var isVpsLoading: Bool = false
    @Published public var isConfiguringServers: Bool = false
    @Published public var serverTestMessage: String? = nil
    @Published public var isTestingServer: Bool = false
    
    // Server Edit Form State (stored in AppState to avoid CLI macro issues)
    @Published public var inputServerConnectionType: ServerConnectionType = .ssh
    @Published public var inputServerQuickConnect: String = ""
    @Published public var inputServerName: String = ""
    @Published public var inputServerHost: String = ""
    @Published public var inputServerPort: String = "22"
    @Published public var inputServerUser: String = "root"
    @Published public var inputServerAuthType: String = "password" // "password" or "key"
    @Published public var inputServerPassword: String = ""
    @Published public var inputServerKeyPath: String = "~/.ssh/id_ed25519"
    @Published public var inputServerUrl: String = ""
    @Published public var inputServerKey: String = ""
    @Published public var editingServerId: UUID? = nil
    @Published public var isShowingAddServer: Bool = false
    @Published public var lastTestFailed: Bool = false
    @Published public var showAdvancedServerOptions: Bool = false
    @Published public var discoveredSshKeys: [String] = SshInputParser.discoverLocalSshKeys()
    
    @Published public var isCompact: Bool = false
    @Published public var launchAtLogin: Bool = false
    @Published public var statusMessage: String?
    @Published public var showReactorPopover: Bool = false
    
    // Localization
    @Published public var language: AppLanguage = .en
    private let languageStorageKey = "com.arielkap.CoreDeck.language"
    
    private let serversStorageKey = "com.arielkap.CoreDeck.servers"
    private let selectedServerStorageKey = "com.arielkap.CoreDeck.selectedServerId"
    
    private var localTimer: AnyCancellable?
    private var vpsTimer: AnyCancellable?
    private var coffeeCancellable: AnyCancellable?
    
    public init() {
        self.stats = SystemTelemetry.shared.fetchLocalStats()
        if #available(macOS 13.0, *) {
            self.launchAtLogin = (SMAppService.mainApp.status == .enabled)
        }
        
        // Load Language (default to English for commercial release)
        if let savedLang = UserDefaults.standard.string(forKey: languageStorageKey),
           let lang = AppLanguage(rawValue: savedLang) {
            self.language = lang
        } else {
            self.language = .en
        }
        
        self.loadServers()
        self.refreshLocal()
        self.refreshVps()
        
        // Local stats refresh every 4 seconds
        self.localTimer = Timer.publish(every: 4.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshLocal()
            }
            
        // VPS stats refresh every 25 seconds
        self.vpsTimer = Timer.publish(every: 25.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshVps()
            }
            
        // Coffee Mode state listener
        self.coffeeCancellable = CoffeeManager.shared.$isActive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
    }
    
    public func t(_ key: L10nKey) -> String {
        return L10n.text(key, lang: language)
    }
    
    public func toggleLanguage() {
        self.language = (self.language == .en) ? .pl : .en
        UserDefaults.standard.set(self.language.rawValue, forKey: languageStorageKey)
    }
    
    public func setLanguage(_ lang: AppLanguage) {
        self.language = lang
        UserDefaults.standard.set(self.language.rawValue, forKey: languageStorageKey)
    }
    
    public var activeServer: VpsServerConfig? {
        if let id = selectedServerId, let found = servers.first(where: { $0.id == id && $0.isEnabled }) {
            return found
        }
        return servers.first(where: { $0.isEnabled })
    }
    
    public var reactorStatus: (icon: String, color: Color, label: String) {
        if stats.usedSwapGB > 1.5 || stats.ramPercent > 88.0 {
            return ("flame.fill", .red, t(.criticalLoad))
        } else if stats.usedSwapGB > 0.5 || stats.ramPercent > 75.0 {
            return ("bolt.fill", .orange, t(.elevated))
        } else {
            return ("checkmark.circle.fill", .green, t(.optimal))
        }
    }
    
    public var reactorAdvice: (title: String, body: String) {
        if stats.usedSwapGB > 1.5 || stats.ramPercent > 88.0 {
            return (t(.reactorCriticalTitle), t(.reactorCriticalBody))
        } else if stats.usedSwapGB > 0.5 || stats.ramPercent > 75.0 {
            return (t(.reactorElevatedTitle), t(.reactorElevatedBody))
        } else {
            return (t(.reactorOptimalTitle), t(.reactorOptimalBody))
        }
    }
    
    public var menuBarText: String {
        let coffeeEmoji = CoffeeManager.shared.isActive ? "☕️ " : ""
        let (icon, _, _) = reactorStatus
        let iconEmoji = icon == "flame.fill" ? "🔥" : (icon == "bolt.fill" ? "⚡" : "🟢")
        
        let serverPart: String
        if let server = activeServer {
            let isOnline = (vps != nil && vps?.isOnline == true)
            let sEmoji = isOnline ? "🟢" : "🔴"
            serverPart = " | \(sEmoji) \(server.name)"
        } else {
            serverPart = ""
        }
        
        if isCompact {
            return "\(coffeeEmoji)\(iconEmoji) \(Int(stats.ramPercent))% | 🔄 \(String(format: "%.1fG", stats.usedSwapGB))\(serverPart)"
        } else {
            return "\(coffeeEmoji)\(iconEmoji) \(String(format: "%.1f", stats.usedRamGB))/\(Int(stats.totalRamGB))G | 💾 \(Int(stats.freeDiskGB))G | 🔄 \(String(format: "%.1fG", stats.usedSwapGB))\(serverPart)"
        }
    }
    
    public func refreshLocal() {
        self.stats = SystemTelemetry.shared.fetchLocalStats()
        let limit = LicenseManager.shared.isPro ? 5 : 3
        self.hogs = SystemTelemetry.shared.fetchTopProcesses(limit: limit)
    }
    
    public func refreshVps() {
        guard LicenseManager.shared.isPro else {
            self.vps = nil
            return
        }
        guard let server = activeServer else {
            self.vps = nil
            return
        }
        isVpsLoading = true
        Task {
            let res = await SystemTelemetry.shared.fetchVpsTelemetry(server: server)
            self.vps = res
            self.isVpsLoading = false
        }
    }
    
    private func keychainPasswordKey(for id: UUID) -> String { "vps_\(id.uuidString)_password" }
    private func keychainApiKeyKey(for id: UUID) -> String { "vps_\(id.uuidString)_apikey" }
    
    public func loadServers() {
        var needsMigrationSave = false
        if let data = UserDefaults.standard.data(forKey: serversStorageKey),
           var decoded = try? JSONDecoder().decode([VpsServerConfig].self, from: data) {
            for i in decoded.indices {
                let sid = decoded[i].id
                // Migrate legacy plaintext password/apiKey into Keychain if present
                if !decoded[i].password.isEmpty {
                    KeychainHelper.save(key: keychainPasswordKey(for: sid), value: decoded[i].password)
                    needsMigrationSave = true
                } else if let kcPass = KeychainHelper.load(key: keychainPasswordKey(for: sid)) {
                    decoded[i].password = kcPass
                }
                
                if !decoded[i].apiKey.isEmpty {
                    KeychainHelper.save(key: keychainApiKeyKey(for: sid), value: decoded[i].apiKey)
                    needsMigrationSave = true
                } else if let kcKey = KeychainHelper.load(key: keychainApiKeyKey(for: sid)) {
                    decoded[i].apiKey = kcKey
                }
            }
            self.servers = decoded
            if needsMigrationSave {
                self.saveServers()
            }
        }
        if let savedIdStr = UserDefaults.standard.string(forKey: selectedServerStorageKey),
           let savedUUID = UUID(uuidString: savedIdStr) {
            self.selectedServerId = savedUUID
        } else {
            self.selectedServerId = self.servers.first?.id
        }
    }
    
    public func saveServers() {
        // Persist secrets in Keychain and strip them before writing JSON to UserDefaults
        let sanitized: [VpsServerConfig] = self.servers.map { srv in
            KeychainHelper.save(key: keychainPasswordKey(for: srv.id), value: srv.password)
            KeychainHelper.save(key: keychainApiKeyKey(for: srv.id), value: srv.apiKey)
            var copy = srv
            copy.password = ""
            copy.apiKey = ""
            return copy
        }
        if let data = try? JSONEncoder().encode(sanitized) {
            UserDefaults.standard.set(data, forKey: serversStorageKey)
        }
        if let id = selectedServerId {
            UserDefaults.standard.set(id.uuidString, forKey: selectedServerStorageKey)
        } else {
            UserDefaults.standard.removeObject(forKey: selectedServerStorageKey)
        }
    }
    
    public func addOrUpdateServer(
        id: UUID? = nil,
        name: String,
        connectionType: ServerConnectionType = .ssh,
        host: String = "",
        port: Int = 22,
        user: String = "root",
        authType: String = "password",
        password: String = "",
        keyPath: String = "~/.ssh/id_ed25519",
        urlString: String = "",
        apiKey: String = "",
        isEnabled: Bool = true
    ) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackName = connectionType == .ssh
            ? (cleanHost.isEmpty ? (language == .en ? "SSH Server" : "Serwer SSH") : cleanHost)
            : (language == .en ? "HTTP Server" : "Serwer HTTP")
        let finalName = cleanName.isEmpty ? fallbackName : cleanName
        
        let newConfig = VpsServerConfig(
            id: id ?? UUID(),
            name: finalName,
            connectionType: connectionType,
            host: cleanHost,
            port: port,
            user: user.trimmingCharacters(in: .whitespacesAndNewlines),
            authType: authType,
            password: password,
            keyPath: keyPath.trimmingCharacters(in: .whitespacesAndNewlines),
            urlString: urlString.trimmingCharacters(in: .whitespacesAndNewlines),
            apiKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines),
            isEnabled: isEnabled
        )
        
        if let targetId = id, let idx = servers.firstIndex(where: { $0.id == targetId }) {
            servers[idx] = newConfig
        } else {
            servers.append(newConfig)
            selectedServerId = newConfig.id
        }
        saveServers()
        refreshVps()
    }
    
    public func deleteServer(id: UUID) {
        KeychainHelper.delete(key: keychainPasswordKey(for: id))
        KeychainHelper.delete(key: keychainApiKeyKey(for: id))
        servers.removeAll(where: { $0.id == id })
        if selectedServerId == id {
            selectedServerId = servers.first?.id
        }
        saveServers()
        refreshVps()
    }
    
    public func selectServer(id: UUID) {
        selectedServerId = id
        saveServers()
        refreshVps()
    }
    
    public func applyMagicPaste(_ raw: String) {
        let parsed = SshInputParser.parse(raw)
        self.inputServerHost = parsed.host
        if let u = parsed.user {
            self.inputServerUser = u
        } else if self.inputServerUser.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.inputServerUser = "root"
        }
        if let p = parsed.port {
            self.inputServerPort = "\(p)"
        }
        if let k = parsed.keyPath {
            self.inputServerKeyPath = k
            self.inputServerAuthType = "key"
        }
        self.lastTestFailed = false
    }
    
    private func buildDraftServerConfig(resolvedName: String? = nil) -> VpsServerConfig {
        let preferredName = inputServerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = preferredName.isEmpty ? (resolvedName ?? "") : preferredName
        return VpsServerConfig(
            id: editingServerId ?? UUID(),
            name: finalName,
            connectionType: inputServerConnectionType,
            host: inputServerHost.trimmingCharacters(in: .whitespacesAndNewlines),
            port: Int(inputServerPort) ?? 22,
            user: inputServerUser.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "root" : inputServerUser.trimmingCharacters(in: .whitespacesAndNewlines),
            authType: inputServerAuthType,
            password: inputServerPassword,
            keyPath: inputServerKeyPath.trimmingCharacters(in: .whitespacesAndNewlines),
            urlString: inputServerUrl.trimmingCharacters(in: .whitespacesAndNewlines),
            apiKey: inputServerKey.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
    
    public func testServer(server: VpsServerConfig) async -> (success: Bool, message: String, telemetry: VpsTelemetry?) {
        self.isTestingServer = true
        self.lastTestFailed = false
        self.serverTestMessage = t(.testingConnection)
        let result = await SystemTelemetry.shared.testServerConnection(server: server, lang: language)
        self.isTestingServer = false
        self.lastTestFailed = !result.success
        self.serverTestMessage = (result.success ? "🟢 " : "🔴 ") + result.message
        return result
    }
    
    public func connectAndSaveServer() async -> Bool {
        let draft = buildDraftServerConfig()
        let result = await testServer(server: draft)
        guard result.success else { return false }
        
        let autoName = result.telemetry?.hostname
        let finalName = inputServerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? (autoName ?? draft.host)
            : inputServerName
        
        addOrUpdateServer(
            id: editingServerId,
            name: finalName,
            connectionType: draft.connectionType,
            host: draft.host,
            port: draft.port,
            user: draft.user,
            authType: draft.authType,
            password: draft.password,
            keyPath: draft.keyPath,
            urlString: draft.urlString,
            apiKey: draft.apiKey
        )
        if let tele = result.telemetry {
            self.vps = tele
        }
        self.editingServerId = nil
        self.isShowingAddServer = false
        self.lastTestFailed = false
        return true
    }
    
    public func saveCurrentServerIgnoringTest() {
        let draft = buildDraftServerConfig()
        addOrUpdateServer(
            id: editingServerId,
            name: draft.name,
            connectionType: draft.connectionType,
            host: draft.host,
            port: draft.port,
            user: draft.user,
            authType: draft.authType,
            password: draft.password,
            keyPath: draft.keyPath,
            urlString: draft.urlString,
            apiKey: draft.apiKey
        )
        cancelServerEdit()
    }
    
    public func startAddServer() {
        self.editingServerId = nil
        self.inputServerConnectionType = .ssh
        self.inputServerQuickConnect = ""
        self.inputServerName = ""
        self.inputServerHost = ""
        self.inputServerPort = "22"
        self.inputServerUser = "root"
        self.inputServerAuthType = "password"
        self.inputServerPassword = ""
        self.inputServerKeyPath = SshInputParser.discoverLocalSshKeys().first ?? "~/.ssh/id_ed25519"
        self.inputServerUrl = ""
        self.inputServerKey = ""
        self.isShowingAddServer = true
        self.serverTestMessage = nil
        self.lastTestFailed = false
    }
    
    public func startEditServer(server: VpsServerConfig) {
        self.editingServerId = server.id
        self.inputServerConnectionType = server.connectionType
        self.inputServerName = server.name
        self.inputServerHost = server.host
        self.inputServerPort = "\(server.port)"
        self.inputServerUser = server.user
        self.inputServerQuickConnect = server.port == 22 ? "\(server.user)@\(server.host)" : "ssh -p \(server.port) \(server.user)@\(server.host)"
        self.inputServerAuthType = server.authType
        self.inputServerPassword = server.password
        self.inputServerKeyPath = server.keyPath.isEmpty ? "~/.ssh/id_ed25519" : server.keyPath
        self.inputServerUrl = server.urlString
        self.inputServerKey = server.apiKey
        self.isShowingAddServer = true
        self.serverTestMessage = nil
        self.lastTestFailed = false
    }
    
    public func cancelServerEdit() {
        self.editingServerId = nil
        self.isShowingAddServer = false
        self.serverTestMessage = nil
        self.lastTestFailed = false
    }
    
    public func killHog(pid: Int32, name: String, force: Bool) {
        guard LicenseManager.shared.isPro else {
            LicenseManager.shared.showActivationSheet = true
            return
        }
        let ok = SystemTelemetry.shared.killProcess(pid: pid, force: force)
        if ok {
            self.statusMessage = language == .en ? "Terminated \(name) (PID: \(pid))" : "Zabito \(name) (PID: \(pid))"
        } else {
            self.statusMessage = language == .en ? "Permission denied for PID \(pid)" : "Brak uprawnień do zabicia PID \(pid)"
        }
        self.refreshLocal()
        
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            self.statusMessage = nil
        }
    }
    
    public func purgeMemory() {
        guard LicenseManager.shared.isPro else {
            LicenseManager.shared.showActivationSheet = true
            return
        }
        Task {
            let freedMB = SystemTelemetry.shared.purgeInactiveMemory()
            if freedMB >= 1024.0 {
                self.statusMessage = language == .en ? String(format: "Purged cache (freed %.1f GB)", freedMB / 1024.0) : String(format: "Wyczyszczono cache (zwolniono %.1f GB)", freedMB / 1024.0)
            } else if freedMB > 30.0 {
                self.statusMessage = language == .en ? String(format: "Purged cache (freed %.0f MB)", freedMB) : String(format: "Wyczyszczono cache (zwolniono %.0f MB)", freedMB)
            } else {
                self.statusMessage = language == .en ? "Memory cache is optimal (sync)" : "Pamięć podręczna jest optymalna (sync)"
            }
            self.refreshLocal()
            
            try? await Task.sleep(nanoseconds: 3_500_000_000)
            self.statusMessage = nil
        }
    }
    
    public func unloadAIModels() {
        guard LicenseManager.shared.isPro else {
            LicenseManager.shared.showActivationSheet = true
            return
        }
        Task {
            // 1. Graceful Ollama API unload
            let ollamaCount = await SystemTelemetry.shared.unloadOllamaModels()
            
            // 2. Kill hanging / orphan Metal & AI runners
            let killedRunners = SystemTelemetry.shared.killHangingMetalRunners()
            
            // 3. Purge inactive Unified Memory / Metal buffer cache
            let freedMB = SystemTelemetry.shared.purgeInactiveMemory()
            
            var details: [String] = []
            if ollamaCount > 0 {
                details.append(language == .en ? "Unloaded \(ollamaCount) Ollama models" : "Wyładowano \(ollamaCount) modeli Ollama")
            }
            if !killedRunners.isEmpty {
                let unique = Array(Set(killedRunners))
                let label = language == .en ? "Killed \(killedRunners.count) Metal runners" : "Ubito \(killedRunners.count) runnerów Metal"
                details.append("\(label) (\(unique.prefix(2).joined(separator: ", ")))")
            }
            if freedMB > 30.0 {
                if freedMB >= 1024.0 {
                    details.append(language == .en ? String(format: "Freed %.1f GB memory", freedMB / 1024.0) : String(format: "Zwolniono %.1f GB pamięci", freedMB / 1024.0))
                } else {
                    details.append(language == .en ? String(format: "Freed %.0f MB memory", freedMB) : String(format: "Zwolniono %.0f MB pamięci", freedMB))
                }
            }
            
            if details.isEmpty {
                self.statusMessage = language == .en ? "Unified Memory & VRAM optimal" : "Pamięć Unified i VRAM zoptymalizowane"
            } else {
                self.statusMessage = details.joined(separator: " • ")
            }
            
            self.refreshLocal()
            
            try? await Task.sleep(nanoseconds: 3_500_000_000)
            self.statusMessage = nil
        }
    }
    
    public func toggleCoffee(duration: CoffeeDuration = .indefinite) {
        guard LicenseManager.shared.isPro else {
            LicenseManager.shared.showActivationSheet = true
            return
        }
        CoffeeManager.shared.toggle(duration: duration)
        if CoffeeManager.shared.isActive {
            self.statusMessage = language == .en ? "Coffee Mode Active (Display Awake)" : "Tryb Kawki Aktywny (Ekran nie zaśnie)"
        } else if let guardMsg = CoffeeManager.shared.guardAlertMessage {
            self.statusMessage = guardMsg
        } else {
            self.statusMessage = language == .en ? "Coffee Mode Disabled" : "Tryb Kawki Wyłączony"
        }
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            self.statusMessage = nil
        }
    }
    
    public func toggleLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            do {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                    self.launchAtLogin = false
                    self.statusMessage = language == .en ? "Launch at login disabled" : "Wyłączono autostart"
                } else {
                    try SMAppService.mainApp.register()
                    self.launchAtLogin = true
                    self.statusMessage = language == .en ? "Launch at login enabled" : "Włączono autostart przy logowaniu"
                }
            } catch {
                self.statusMessage = "\(language == .en ? "Launch at login" : "Autostart"): \(error.localizedDescription)"
            }
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                self.statusMessage = nil
            }
        }
    }
    
    public func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
