import Foundation

public struct ParsedSshInput: Sendable, Equatable {
    public let host: String
    public let user: String?
    public let port: Int?
    public let keyPath: String?
    public let wasSmartParsed: Bool

    public var isValid: Bool {
        !host.isEmpty
    }
}

public enum SshInputParser {
    /// Parses flexible user inputs such as:
    /// - "<ip>" or "<ip>:<port>"
    /// - "<user>@<host>" or "<user>@<host>:<port>"
    /// - "ssh <user>@<host>"
    /// - "ssh -p 2222 -i ~/.ssh/id_ed25519 <user>@<host>"
    public static func parse(_ raw: String) -> ParsedSshInput {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ParsedSshInput(host: "", user: nil, port: nil, keyPath: nil, wasSmartParsed: false)
        }

        var working = trimmed
        var smart = false

        // Strip leading ssh:// scheme if pasted from a browser/tool
        if working.lowercased().hasPrefix("ssh://") {
            working = String(working.dropFirst(6))
            smart = true
        }

        let tokens = working.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        var user: String? = nil
        var port: Int? = nil
        var keyPath: String? = nil
        var targetToken: String? = nil

        var idx = 0
        if let first = tokens.first, first.lowercased() == "ssh" {
            smart = true
            idx = 1
        }

        while idx < tokens.count {
            let tok = tokens[idx]
            if tok == "-p", idx + 1 < tokens.count {
                if let p = Int(tokens[idx + 1]), (1...65535).contains(p) {
                    port = p
                    smart = true
                }
                idx += 2
                continue
            } else if tok.hasPrefix("-p"), tok.count > 2, let p = Int(tok.dropFirst(2)), (1...65535).contains(p) {
                port = p
                smart = true
                idx += 1
                continue
            } else if tok == "-i", idx + 1 < tokens.count {
                keyPath = tokens[idx + 1]
                smart = true
                idx += 2
                continue
            } else if tok == "-l", idx + 1 < tokens.count {
                user = tokens[idx + 1]
                smart = true
                idx += 2
                continue
            } else if tok.hasPrefix("-") {
                // Skip unknown flags (e.g. -o, -v, -A); if -o take next arg too
                if tok == "-o" || tok == "-F" || tok == "-J" || tok == "-L" || tok == "-R" {
                    idx += 2
                } else {
                    idx += 1
                }
                smart = true
                continue
            } else {
                if targetToken == nil {
                    targetToken = tok
                }
                idx += 1
            }
        }

        var host = targetToken ?? ""

        // Handle user@host(:port)
        if let atIdx = host.lastIndex(of: "@") {
            let u = String(host[..<atIdx]).trimmingCharacters(in: .whitespaces)
            let h = String(host[host.index(after: atIdx)...]).trimmingCharacters(in: .whitespaces)
            if !u.isEmpty {
                user = u
                smart = true
            }
            host = h
        }

        // Handle host:port (avoid breaking IPv6 unless bracketed)
        if host.hasPrefix("["), let closeBracket = host.firstIndex(of: "]") {
            let afterBracket = host.index(after: closeBracket)
            if afterBracket < host.endIndex, host[afterBracket] == ":" {
                let portStr = String(host[host.index(after: afterBracket)...])
                if let p = Int(portStr), (1...65535).contains(p) {
                    port = p
                    smart = true
                }
            }
            host = String(host[host.index(after: host.startIndex)..<closeBracket])
        } else if host.filter({ $0 == ":" }).count == 1, let colonIdx = host.lastIndex(of: ":") {
            let portStr = String(host[host.index(after: colonIdx)...])
            if let p = Int(portStr), (1...65535).contains(p) {
                port = p
                host = String(host[..<colonIdx])
                smart = true
            }
        }

        // Clean accidental trailing slashes or quotes
        host = host.trimmingCharacters(in: CharacterSet(charactersIn: "/\"'"))

        return ParsedSshInput(
            host: host,
            user: user,
            port: port,
            keyPath: keyPath,
            wasSmartParsed: smart
        )
    }

    /// Scans ~/.ssh for likely private keys (ed25519, rsa, ecdsa, etc.)
    public static func discoverLocalSshKeys() -> [String] {
        let sshDir = ("~/.ssh" as NSString).expandingTildeInPath
        guard let items = try? FileManager.default.contentsOfDirectory(atPath: sshDir) else {
            return ["~/.ssh/id_ed25519"]
        }

        let ignored = Set(["config", "known_hosts", "known_hosts.old", "authorized_keys", "environment", "rc"])
        var found: [String] = []

        for item in items.sorted() {
            if item.hasPrefix(".") || item.hasSuffix(".pub") || ignored.contains(item) {
                continue
            }
            let fullPath = (sshDir as NSString).appendingPathComponent(item)
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDir), !isDir.boolValue else {
                continue
            }
            let hasMatchingPub = items.contains("\(item).pub")
            let isCommonKey = item.hasPrefix("id_") || item.hasSuffix(".pem") || item.hasSuffix(".key")
            if hasMatchingPub || isCommonKey {
                found.append("~/.ssh/\(item)")
            }
        }

        return found.isEmpty ? ["~/.ssh/id_ed25519"] : found
    }
}
