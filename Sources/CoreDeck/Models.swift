import Foundation

public struct ProcessHog: Identifiable, Sendable {
    public let id: Int32
    public let name: String
    public let displayName: String
    public let memMB: Double
    public let icon: String
    public let category: String
    
    public var formattedMem: String {
        if memMB >= 1024 {
            return String(format: "%.2f GB", memMB / 1024.0)
        } else {
            return String(format: "%.0f MB", memMB)
        }
    }
}

public enum ServerConnectionType: String, Codable, Sendable, CaseIterable {
    case ssh = "SSH"
    case http = "HTTP"
}

public struct VpsServerConfig: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var connectionType: ServerConnectionType
    
    // SSH fields (Hostinger / Linux VPS direct)
    public var host: String
    public var port: Int
    public var user: String
    public var authType: String // "password" or "key"
    public var password: String
    public var keyPath: String
    
    // HTTP fields (1-Liner Agent or custom API)
    public var urlString: String
    public var apiKey: String
    
    public var isEnabled: Bool
    
    public init(
        id: UUID = UUID(),
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
        self.id = id
        self.name = name
        self.connectionType = connectionType
        self.host = host
        self.port = port
        self.user = user
        self.authType = authType
        self.password = password
        self.keyPath = keyPath
        self.urlString = urlString
        self.apiKey = apiKey
        self.isEnabled = isEnabled
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, connectionType, host, port, user, authType, password, keyPath, urlString, apiKey, isEnabled
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Serwer VPS"
        self.host = try container.decodeIfPresent(String.self, forKey: .host) ?? ""
        self.port = try container.decodeIfPresent(Int.self, forKey: .port) ?? 22
        self.user = try container.decodeIfPresent(String.self, forKey: .user) ?? "root"
        self.authType = try container.decodeIfPresent(String.self, forKey: .authType) ?? "password"
        self.password = try container.decodeIfPresent(String.self, forKey: .password) ?? ""
        self.keyPath = try container.decodeIfPresent(String.self, forKey: .keyPath) ?? "~/.ssh/id_ed25519"
        self.urlString = try container.decodeIfPresent(String.self, forKey: .urlString) ?? ""
        self.apiKey = try container.decodeIfPresent(String.self, forKey: .apiKey) ?? ""
        self.isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        
        if let decodedType = try container.decodeIfPresent(ServerConnectionType.self, forKey: .connectionType) {
            self.connectionType = decodedType
        } else if !self.urlString.isEmpty && self.host.isEmpty {
            self.connectionType = .http
        } else {
            self.connectionType = .ssh
        }
    }
}

public struct VpsRamStats: Codable, Sendable {
    public let total_mb: Double
    public let used_mb: Double
    public let percent: Double?
}

public struct VpsDiskStats: Codable, Sendable {
    public let total_gb: Double
    public let used_gb: Double
    public let free_gb: Double?
    public let percent: Double?
}

public struct VpsTelemetry: Codable, Sendable {
    public let status: String?
    public let hostname: String?
    public let ram: VpsRamStats?
    public let load: [Double]?
    public let uptime: String?
    public let disk: VpsDiskStats?
    public let timestamp: String?
    
    public var isOnline: Bool {
        return (status?.lowercased() == "online" || ram != nil)
    }
}

