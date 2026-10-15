import Foundation
import Combine
import CryptoKit

@MainActor
public final class LicenseManager: ObservableObject {
    public static let shared = LicenseManager()
    
    private let userDefaultsKey = "com.arielkap.CoreDeck.isPro"
    private let licenseKeyStore = "com.arielkap.CoreDeck.licenseKey"
    
    // Official Master Ed25519 Public Key (32 bytes raw representation)
    private static let masterPublicKeyHex = "0f181a71a9a36b7937e5ec0249d104b5c2d9ac69827983094a33ff8150dd1dc4"
    
    @Published public var isPro: Bool = false
    @Published public var licenseKey: String = ""
    @Published public var inputKey: String = ""
    @Published public var isActivating: Bool = false
    @Published public var activationError: String? = nil
    @Published public var showActivationSheet: Bool = false
    
    private init() {
        let storedKey = UserDefaults.standard.string(forKey: licenseKeyStore) ?? ""
        if Self.verifyLicenseSignature(key: storedKey) {
            self.isPro = true
            self.licenseKey = storedKey
        } else {
            self.isPro = false
            self.licenseKey = ""
            UserDefaults.standard.set(false, forKey: userDefaultsKey)
        }
    }
    
    public func activate(key: String) async -> Bool {
        let cleanKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        let isPl = UserDefaults.standard.string(forKey: "com.arielkap.CoreDeck.language") == "pl"
        
        guard !cleanKey.isEmpty else {
            self.activationError = isPl ? "Wprowadź klucz licencyjny" : "Please enter a license key"
            return false
        }
        
        self.isActivating = true
        self.activationError = nil
        
        // Asymmetric Cryptographic Verification (Curve25519 / Ed25519)
        if Self.verifyLicenseSignature(key: cleanKey) {
            self.markProUnlocked(key: cleanKey)
            self.isActivating = false
            return true
        } else {
            self.activationError = isPl ? "Nieprawidłowy klucz lub sfałszowany podpis" : "Invalid license key or signature"
            self.isActivating = false
            return false
        }
    }
    
    public static func verifyLicenseSignature(key: String) -> Bool {
        let parts = key.split(separator: ".")
        guard parts.count == 2 else { return false }
        
        let payload = String(parts[0])
        let sigString = String(parts[1])
        
        guard payload.hasPrefix("CORE-PRO-") else { return false }
        guard let pubKeyData = hexToData(masterPublicKeyHex),
              let publicKey = try? Curve25519.Signing.PublicKey(rawRepresentation: pubKeyData) else {
            return false
        }
        
        let sigData: Data?
        if sigString.count == 128 { // Hex format
            sigData = hexToData(sigString)
        } else { // Base64 or Base64URL format
            var base64 = sigString.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
            while base64.count % 4 != 0 { base64.append("=") }
            sigData = Data(base64Encoded: base64)
        }
        
        guard let signature = sigData, signature.count == 64 else { return false }
        guard let payloadData = payload.data(using: .utf8) else { return false }
        
        return publicKey.isValidSignature(signature, for: payloadData)
    }
    
    private static func hexToData(_ hex: String) -> Data? {
        var data = Data()
        var temp = ""
        for char in hex {
            temp.append(char)
            if temp.count == 2 {
                guard let byte = UInt8(temp, radix: 16) else { return nil }
                data.append(byte)
                temp = ""
            }
        }
        return data.count == hex.count / 2 ? data : nil
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
