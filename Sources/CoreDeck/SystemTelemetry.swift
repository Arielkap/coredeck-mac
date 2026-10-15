import Foundation
import Darwin

public final class SystemTelemetry: @unchecked Sendable {
    public static let shared = SystemTelemetry()
    
    private init() {}
    
    public struct LocalStats: Sendable {
        public let totalRamGB: Double
        public let usedRamGB: Double
        public let freeRamGB: Double
        public let ramPercent: Double
        public let usedSwapGB: Double
        public let totalSwapGB: Double
        public let freeDiskGB: Double
        public let totalDiskGB: Double
    }
    
    public func fetchLocalStats() -> LocalStats {
        // 1. RAM via Darwin host_statistics64
        let physicalMem = ProcessInfo.processInfo.physicalMemory
        let totalRamGB = Double(physicalMem) / (1024.0 * 1024.0 * 1024.0)
        
        var vmStat = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        let hostPort = mach_host_self()
        let ret = withUnsafeMutablePointer(to: &vmStat) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(hostPort, HOST_VM_INFO64, intPtr, &count)
            }
        }
        
        var usedRamGB: Double = 0.0
        if ret == KERN_SUCCESS {
            let pageSize = UInt64(getpagesize())
            let active = UInt64(vmStat.active_count) * pageSize
            let wired = UInt64(vmStat.wire_count) * pageSize
            let compressed = UInt64(vmStat.compressor_page_count) * pageSize
            usedRamGB = Double(active + wired + compressed) / (1024.0 * 1024.0 * 1024.0)
        } else {
            usedRamGB = totalRamGB * 0.5
        }
        let freeRamGB = max(0.0, totalRamGB - usedRamGB)
        let ramPercent = (usedRamGB / totalRamGB) * 100.0
        
        // 2. Swap via sysctl vm.swapusage
        var swap = xsw_usage()
        var swapSize = MemoryLayout<xsw_usage>.size
        var usedSwapGB: Double = 0.0
        var totalSwapGB: Double = 0.0
        if sysctlbyname("vm.swapusage", &swap, &swapSize, nil, 0) == 0 {
            usedSwapGB = Double(swap.xsu_used) / (1024.0 * 1024.0 * 1024.0)
            totalSwapGB = Double(swap.xsu_total) / (1024.0 * 1024.0 * 1024.0)
        }
        
        // 3. Disk via Foundation URL resource values
        var freeDiskGB: Double = 0.0
        var totalDiskGB: Double = 0.0
        if let values = try? URL(fileURLWithPath: "/").resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey, .volumeTotalCapacityKey]) {
            freeDiskGB = Double(values.volumeAvailableCapacityForImportantUsage ?? 0) / (1024.0 * 1024.0 * 1024.0)
            totalDiskGB = Double(values.volumeTotalCapacity ?? 0) / (1024.0 * 1024.0 * 1024.0)
        }
        
        return LocalStats(
            totalRamGB: totalRamGB,
            usedRamGB: usedRamGB,
            freeRamGB: freeRamGB,
            ramPercent: ramPercent,
            usedSwapGB: usedSwapGB,
            totalSwapGB: totalSwapGB,
            freeDiskGB: freeDiskGB,
            totalDiskGB: totalDiskGB
        )
    }
    
    public func fetchTopProcesses(limit: Int = 5) -> [ProcessHog] {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/ps")
        task.arguments = ["-axo", "pid,rss,comm", "-m"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return [] }
            
            var hogs: [ProcessHog] = []
            let lines = output.components(separatedBy: .newlines)
            
            for line in lines.dropFirst() {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { continue }
                let parts = trimmed.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true)
                guard parts.count == 3,
                      let pid = Int32(parts[0]),
                      let rssKB = Double(parts[1]) else { continue }
                
                let rawPath = String(parts[2])
                let memMB = rssKB / 1024.0
                guard memMB >= 40.0 else { continue } // Filter noise
                
                let fileName = URL(fileURLWithPath: rawPath).lastPathComponent
                let (category, icon, displayName) = categorize(path: rawPath, fileName: fileName)
                
                hogs.append(ProcessHog(
                    id: pid,
                    name: fileName,
                    displayName: displayName,
                    memMB: memMB,
                    icon: icon,
                    category: category
                ))
            }
            
            hogs.sort { $0.memMB > $1.memMB }
            return Array(hogs.prefix(limit))
        } catch {
            return []
        }
    }
    
    private func categorize(path: String, fileName: String) -> (String, String, String) {
        let p = path.lowercased()
        let f = fileName.lowercased()
        
        if p.contains("ollama") || f.contains("ollama") || p.contains("llama") || p.contains("mlx") || p.contains("comfy") {
            return ("AI / LLM", "cpu.fill", "Ollama / LLM Runner")
        }
        if p.contains("arc.app") || f.contains("arc") {
            return ("Browser", "globe", "Arc Browser")
        }
        if p.contains("chrome.app") || f.contains("chrome") {
            return ("Browser", "globe", "Google Chrome")
        }
        if p.contains("safari.app") || f.contains("safari") {
            return ("Browser", "safari.fill", "Safari")
        }
        if p.contains("docker") || f.contains("docker") {
            return ("DevOps", "shippingbox.fill", "Docker Engine")
        }
        if p.contains("xcode") || f.contains("xcode") {
            return ("Development", "hammer.fill", "Xcode")
        }
        if p.contains("code") || f.contains("electron") {
            return ("Development", "chevron.left.forwardslash.chevron.right", "VS Code")
        }
        if p.contains("spotify") {
            return ("Media", "music.note", "Spotify")
        }
        if p.contains("slack") || p.contains("discord") || p.contains("telegram") {
            return ("Chat", "message.fill", fileName)
        }
        return ("System / App", "bolt.fill", fileName)
    }
    
    public func killProcess(pid: Int32, force: Bool = false) -> Bool {
        let sig = force ? SIGKILL : SIGTERM
        return Darwin.kill(pid, sig) == 0
    }
    
    public func purgeBuffers() {
        Darwin.sync()
    }
    
    /// Purges inactive file-backed cache and purgeable memory via safe chunked VM pressure,
    /// triggering Darwin's memory compressor and pageout daemon.
    @discardableResult
    public func purgeInactiveMemory() -> Double {
        var vmStat = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        let hostPort = mach_host_self()
        
        let getStats: () -> (Double, Double) = {
            _ = withUnsafeMutablePointer(to: &vmStat) { ptr in
                ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                    host_statistics64(hostPort, HOST_VM_INFO64, $0, &count)
                }
            }
            let pageSize = UInt64(getpagesize())
            let free = Double(UInt64(vmStat.free_count) * pageSize) / (1024.0 * 1024.0)
            let inact = Double(UInt64(vmStat.inactive_count) * pageSize) / (1024.0 * 1024.0)
            return (free, inact)
        }
        
        let (freeBefore, inactiveMB) = getStats()
        
        // Attempt system purge if permissions allow
        let purgeTask = Process()
        purgeTask.executableURL = URL(fileURLWithPath: "/usr/sbin/purge")
        try? purgeTask.run()
        purgeTask.waitUntilExit()
        
        guard inactiveMB > 120.0 else {
            Darwin.sync()
            let (freeAfter, _) = getStats()
            return max(0.0, freeAfter - freeBefore)
        }
        
        let pageSize = Int(getpagesize())
        let chunkSize = 128 * 1024 * 1024 // 128 MB chunks
        // Calculate safe allocation target: free + 60% inactive, capped at 5 GB
        let targetMB = min(freeBefore + (inactiveMB * 0.6), 5120.0)
        let totalChunks = max(1, Int(targetMB / 128.0))
        
        var allocations: [vm_address_t] = []
        allocations.reserveCapacity(totalChunks)
        
        for _ in 0..<totalChunks {
            var addr: vm_address_t = 0
            let kr = vm_allocate(mach_task_self_, &addr, vm_size_t(chunkSize), VM_FLAGS_ANYWHERE)
            if kr == KERN_SUCCESS {
                allocations.append(addr)
                let ptr = UnsafeMutableRawPointer(bitPattern: addr)!
                for offset in stride(from: 0, to: chunkSize, by: pageSize) {
                    ptr.storeBytes(of: 1, toByteOffset: offset, as: UInt8.self)
                }
            } else {
                break
            }
        }
        
        for addr in allocations {
            vm_deallocate(mach_task_self_, addr, vm_size_t(chunkSize))
        }
        
        Darwin.sync()
        
        let (freeAfter, _) = getStats()
        return max(0.0, freeAfter - freeBefore)
    }
    
    /// Scans running processes and terminates lingering AI / Metal runners holding Unified Memory
    public func killHangingMetalRunners() -> [String] {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/ps")
        task.arguments = ["-axo", "pid,comm,args"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return [] }
            
            let myPid = ProcessInfo.processInfo.processIdentifier
            var killedNames: [String] = []
            
            let runnerPatterns = [
                "ollama_llama_server",
                "llama-server",
                "llama-cli",
                "llama-bench",
                "lms-server",
                "mlx_lm",
                "whisper-metal",
                "whisper.cpp",
                "comfyui",
                "stable-diffusion",
                "vllm"
            ]
            
            let lines = output.components(separatedBy: .newlines)
            for line in lines.dropFirst() {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { continue }
                let parts = trimmed.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true)
                guard parts.count >= 2,
                      let pid = Int32(parts[0]),
                      pid != myPid else { continue }
                
                let comm = String(parts[1]).lowercased()
                let args = (parts.count == 3 ? String(parts[2]) : comm).lowercased()
                
                // Absolute guard against system processes, terminals, and CoreDeck itself
                if comm.contains("coredeck") || args.contains("coredeck") ||
                   comm.contains("antigravity") || args.contains("antigravity") ||
                   comm.contains("gemini") || args.contains("gemini") ||
                   comm.contains("xcode") || comm.contains("swift") ||
                   comm.contains("iterm") || comm.contains("terminal") || comm.contains("zsh") ||
                   comm.hasPrefix("/system/") || comm.hasPrefix("/usr/libexec/") {
                    continue
                }
                
                let isMatch = runnerPatterns.contains { pat in
                    comm.contains(pat) || args.contains(pat)
                } || (comm.contains("python") && (args.contains("mlx_lm") || args.contains("comfyui") || args.contains("vllm") || args.contains("llama_cpp")))
                  || (args.contains(".ollama/runners"))
                
                if isMatch {
                    let displayName = URL(fileURLWithPath: comm).lastPathComponent
                    _ = Darwin.kill(pid, SIGTERM)
                    usleep(120_000)
                    if Darwin.kill(pid, 0) == 0 {
                        _ = Darwin.kill(pid, SIGKILL)
                    }
                    killedNames.append(displayName)
                }
            }
            return killedNames
        } catch {
            return []
        }
    }
    
    public func unloadOllamaModels() async -> Int {
        guard let url = URL(string: "http://localhost:11434/api/ps") else { return 0 }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let models = json["models"] as? [[String: Any]] else { return 0 }
            
            var count = 0
            for m in models {
                guard let name = (m["model"] as? String) ?? (m["name"] as? String) else { continue }
                if let genUrl = URL(string: "http://localhost:11434/api/generate") {
                    var req = URLRequest(url: genUrl)
                    req.httpMethod = "POST"
                    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    let body: [String: Any] = ["model": name, "keep_alive": 0]
                    req.httpBody = try? JSONSerialization.data(withJSONObject: body)
                    _ = try? await URLSession.shared.data(for: req)
                    count += 1
                }
            }
            return count
        } catch {
            return 0
        }
    }
    
    public func fetchVpsTelemetry(server: VpsServerConfig) async -> VpsTelemetry? {
        switch server.connectionType {
        case .ssh:
            return await fetchSshTelemetry(server: server)
        case .http:
            return await fetchHttpTelemetry(server: server)
        }
    }
    
    public func fetchHttpTelemetry(server: VpsServerConfig) async -> VpsTelemetry? {
        guard !server.urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        
        var urlStr = server.urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if !urlStr.lowercased().hasPrefix("http://") && !urlStr.lowercased().hasPrefix("https://") {
            urlStr = "https://" + urlStr
        }
        
        let cleanKey = server.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanKey.isEmpty && !urlStr.contains("key=") && !urlStr.contains("token=") {
            let separator = urlStr.contains("?") ? "&" : "?"
            urlStr += "\(separator)key=\(cleanKey)"
        }
        
        guard let url = URL(string: urlStr) else { return nil }
        var req = URLRequest(url: url)
        req.timeoutInterval = 4.0
        req.setValue("CoreDeckNative/2.0", forHTTPHeaderField: "User-Agent")
        if !cleanKey.isEmpty {
            req.setValue(cleanKey, forHTTPHeaderField: "X-API-Key")
            req.setValue("Bearer \(cleanKey)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { return nil }
            return try JSONDecoder().decode(VpsTelemetry.self, from: data)
        } catch {
            return nil
        }
    }
    
    public func fetchSshTelemetry(server: VpsServerConfig) async -> VpsTelemetry? {
        let cleanHost = server.host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanHost.isEmpty else { return nil }
        
        let portStr = "\(server.port)"
        let userStr = server.user.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "root" : server.user.trimmingCharacters(in: .whitespacesAndNewlines)
        let target = "\(userStr)@\(cleanHost)"
        
        let remoteCmd = "LOAD=$(cat /proc/loadavg | awk '{print $1,$2,$3}') && RAM=$(awk '/^MemTotal:/{t=$2}/^MemAvailable:/{a=$2}END{u=t-a; printf \"%.1f %.1f %.1f\", t/1024, u/1024, (u/t)*100}' /proc/meminfo) && DISK=$(df -m / | tail -n 1 | awk '{t=$2/1024; u=$3/1024; f=$4/1024; p=$5; sub(/%/,\"\",p); printf \"%.1f %.1f %.1f %.1f\", t, u, f, p}') && UP=$(awk '{d=int($1/86400); h=int(($1%86400)/3600); if(d>0) printf \"%dd %dh\", d, h; else printf \"%dh\", h}' /proc/uptime) && HOST=$(hostname) && echo \"$HOST|$LOAD|$RAM|$DISK|$UP\""
        
        return await Task.detached { () -> VpsTelemetry? in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")
            
            var args = [
                "-p", portStr,
                "-o", "StrictHostKeyChecking=accept-new",
                "-o", "ConnectTimeout=5",
                "-o", "ServerAliveInterval=3",
                "-o", "ServerAliveCountMax=1"
            ]
            
            var tempAskpassPath: String? = nil
            var environment = ProcessInfo.processInfo.environment
            
            if server.authType == "password" && !server.password.isEmpty {
                let randomId = UUID().uuidString.prefix(8)
                let askpassFile = "/tmp/coredeck_askpass_\(randomId).sh"
                let escapedPassword = server.password.replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "$", with: "\\$")
                let scriptContent = "#!/bin/sh\necho \"\(escapedPassword)\"\n"
                
                if (try? scriptContent.write(toFile: askpassFile, atomically: true, encoding: .utf8)) != nil {
                    chmod(askpassFile, 0o700)
                    tempAskpassPath = askpassFile
                    environment["SSH_ASKPASS"] = askpassFile
                    environment["SSH_ASKPASS_REQUIRE"] = "force"
                    environment["DISPLAY"] = "coredeck:0"
                    args.append(contentsOf: ["-o", "BatchMode=no"])
                } else {
                    args.append(contentsOf: ["-o", "BatchMode=yes"])
                }
            } else {
                args.append(contentsOf: ["-o", "BatchMode=yes"])
                if server.authType == "key" && !server.keyPath.isEmpty {
                    let expandedKey = (server.keyPath as NSString).expandingTildeInPath
                    args.append(contentsOf: ["-i", expandedKey])
                }
            }
            
            args.append(target)
            args.append(remoteCmd)
            
            process.arguments = args
            process.environment = environment
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = Pipe()
            
            do {
                try process.run()
                process.waitUntilExit()
                
                if let temp = tempAskpassPath {
                    try? FileManager.default.removeItem(atPath: temp)
                }
                
                guard process.terminationStatus == 0 else { return nil }
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                guard let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) else { return nil }
                
                let parts = output.components(separatedBy: "|")
                guard parts.count >= 5 else { return nil }
                
                let hostName = parts[0]
                let loadParts = parts[1].components(separatedBy: " ").compactMap { Double($0) }
                
                let ramParts = parts[2].components(separatedBy: " ").compactMap { Double($0) }
                let ramStats = VpsRamStats(
                    total_mb: ramParts.count > 0 ? ramParts[0] : 0,
                    used_mb: ramParts.count > 1 ? ramParts[1] : 0,
                    percent: ramParts.count > 2 ? ramParts[2] : nil
                )
                
                let diskParts = parts[3].components(separatedBy: " ").compactMap { Double($0) }
                let diskStats = VpsDiskStats(
                    total_gb: diskParts.count > 0 ? diskParts[0] : 0,
                    used_gb: diskParts.count > 1 ? diskParts[1] : 0,
                    free_gb: diskParts.count > 2 ? diskParts[2] : nil,
                    percent: diskParts.count > 3 ? diskParts[3] : nil
                )
                
                let upTime = parts[4]
                
                return VpsTelemetry(
                    status: "online",
                    hostname: hostName,
                    ram: ramStats,
                    load: loadParts,
                    uptime: upTime,
                    disk: diskStats,
                    timestamp: "\(Date().timeIntervalSince1970)"
                )
            } catch {
                if let temp = tempAskpassPath {
                    try? FileManager.default.removeItem(atPath: temp)
                }
                return nil
            }
        }.value
    }
    
    public func testServerConnection(server: VpsServerConfig) async -> (success: Bool, message: String) {
        if let tele = await fetchVpsTelemetry(server: server) {
            let host = tele.hostname ?? server.name
            let mode = server.connectionType == .ssh ? "SSH" : "HTTP"
            return (true, "Połączono (\(mode)) z \(host) • RAM: \(Int(tele.ram?.percent ?? 0))%")
        } else {
            if server.connectionType == .ssh {
                return (false, "Błąd SSH: Sprawdź Host/IP (\(server.host)), Port, Użytkownika lub Hasło/Klucz")
            } else {
                return (false, "Błąd HTTP: Brak odpowiedzi z endpointu \(server.urlString)")
            }
        }
    }
}
