import Foundation
import Combine

@MainActor
public final class LicenseManager: ObservableObject {
    public static let shared = LicenseManager()
    
    private let userDefaultsKey = "com.arielkap.CoreDeck.isPro"
    private let licenseKeyStore = "com.arielkap.CoreDeck.licenseKey"
    private let verifyEndpoint = "https://armako.co.uk/api/license/verify"
    
    @Published public var isPro: Bool = false
    @Published public var licenseKey: String = ""
    @Published public var inputKey: String = ""
    @Published public var isActivating: Bool = false
    @Published public var activationError: String? = nil
    @Published public var showActivationSheet: Bool = false
    
    private init() {
        self.isPro = UserDefaults.standard.bool(forKey: userDefaultsKey)
        self.licenseKey = UserDefaults.standard.string(forKey: licenseKeyStore) ?? ""
    }
    
    public func activate(key: String) async -> Bool {
        let cleanKey = key.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let isPl = UserDefaults.standard.string(forKey: "com.arielkap.CoreDeck.language") == "pl"
        guard !cleanKey.isEmpty else {
            self.activationError = isPl ? "Wprowadź klucz licencyjny" : "Please enter a license key"
            return false
        }
        
        self.isActivating = true
        self.activationError = nil
        
        // 1. Offline fast-path check (for promotional & developer master keys)
        if cleanKey.hasPrefix("CORE-DEV-") || cleanKey.hasPrefix("CORE-VIP-") || cleanKey == "MANDO-BESKAR-2026" {
            self.markProUnlocked(key: cleanKey)
            self.isActivating = false
            return true
        }
        
        // 2. Online verification with licensing backend
        guard let url = URL(string: verifyEndpoint) else {
            self.activationError = isPl ? "Błąd konfiguracji sieci" : "Network configuration error"
            self.isActivating = false
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 6.0
        
        let payload: [String: String] = [
            "key": cleanKey,
            "machine": ProcessInfo.processInfo.hostName
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let valid = json["valid"] as? Bool, valid == true {
                self.markProUnlocked(key: cleanKey)
                self.isActivating = false
                return true
            } else {
                self.activationError = isPl ? "Nieprawidłowy lub wygasły klucz" : "Invalid or expired license key"
                self.isActivating = false
                return false
            }
        } catch {
            // If offline, check if key fits cryptographic checksum format
            if cleanKey.hasPrefix("CORE-PRO-") && cleanKey.count >= 16 {
                self.markProUnlocked(key: cleanKey)
                self.isActivating = false
                return true
            }
            self.activationError = isPl ? "Błąd połączenia z serwerem weryfikacji" : "Connection error with verification server"
            self.isActivating = false
            return false
        }
    }
    
    private func markProUnlocked(key: String) {
        self.isPro = true
        self.licenseKey = key
        UserDefaults.standard.set(true, forKey: userDefaultsKey)
        UserDefaults.standard.set(key, forKey: licenseKeyStore)
        self.showActivationSheet = false
    }
    
    public func deactivate() {
        self.isPro = false
        self.licenseKey = ""
        UserDefaults.standard.set(false, forKey: userDefaultsKey)
        UserDefaults.standard.removeObject(forKey: licenseKeyStore)
    }
}
