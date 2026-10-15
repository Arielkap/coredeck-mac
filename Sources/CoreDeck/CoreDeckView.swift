import SwiftUI

public struct CoreDeckView: View {
    @ObservedObject var state: AppState
    @ObservedObject var license = LicenseManager.shared
    
    public init(state: AppState) {
        self.state = state
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            // MARK: Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.shield.fill")
                            .foregroundColor(.cyan)
                        Text("COREDECK")
                            .font(.system(size: 13, weight: .heavy, design: .monospaced))
                        
                        if license.isPro {
                            Text("PRO")
                                .font(.system(size: 8, weight: .heavy, design: .monospaced))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.yellow.opacity(0.2))
                                .foregroundColor(.yellow)
                                .clipShape(Capsule())
                        }
                    }
                    Text(state.t(.fleetHudSubtitle))
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Pro Upgrade Button or Status
                if !license.isPro {
                    Button {
                        withAnimation {
                            license.showActivationSheet.toggle()
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 9))
                            Text(state.t(.upgradeBtn))
                                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                
                // Status Pill
                let (icon, color, label) = state.reactorStatus
                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .bold))
                    Text(label)
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(color.opacity(0.15))
                .foregroundColor(color)
                .clipShape(Capsule())
                
                // Refresh Button
                Button {
                    state.refreshLocal()
                    state.refreshVps()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .bold))
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                
                // Quit Button
                Button {
                    state.quitApp()
                } label: {
                    Image(systemName: "power")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.red.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 2)
            
            // MARK: License Activation Drawer
            if license.showActivationSheet {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundColor(.yellow)
                        Text(state.t(.activateProTitle))
                            .font(.system(size: 10, weight: .heavy, design: .monospaced))
                        Spacer()
                        Button {
                            withAnimation {
                                license.showActivationSheet = false
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Text(state.t(.activateProDesc))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 6) {
                        TextField(state.t(.licenseKeyPlaceholder), text: $license.inputKey)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 11, design: .monospaced))
                        
                        Button {
                            Task {
                                _ = await license.activate(key: license.inputKey)
                                if license.isPro {
                                    state.refreshLocal()
                                    state.refreshVps()
                                }
                            }
                        } label: {
                            if license.isActivating {
                                ProgressView()
                                    .scaleEffect(0.5)
                                    .frame(width: 40)
                            } else {
                                Text(state.t(.activateBtn))
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .background(Color.yellow.opacity(0.9))
                                    .foregroundColor(.black)
                                    .cornerRadius(5)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if let err = license.activationError {
                        Text(err)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.red)
                    }
                    
                    HStack {
                        Spacer()
                        Button {
                            if let url = URL(string: "https://coredeck.app/#pricing") {
                                NSWorkspace.shared.open(url)
                            }
                        } label: {
                            Text(state.t(.buyLicensePrompt))
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.cyan)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(10)
                .background(Color.yellow.opacity(0.08))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
            }
            
            // MARK: Toast Message if any
            if let msg = state.statusMessage {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.cyan)
                    Text(msg)
                        .font(.system(size: 11, weight: .medium))
                    Spacer()
                }
                .padding(6)
                .background(Color.cyan.opacity(0.12))
                .cornerRadius(6)
            }
            
            // MARK: Mac Core Stats Card
            VStack(alignment: .leading, spacing: 8) {
                // RAM Gauge
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Label(state.t(.unifiedMemory), systemImage: "memorychip")
                            .font(.system(size: 11, weight: .semibold))
                        Spacer()
                        Text("\(String(format: "%.1f", state.stats.usedRamGB)) / \(Int(state.stats.totalRamGB)) GB")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                        Text("(\(Int(state.stats.ramPercent))%)")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    
                    // Progress Bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.secondary.opacity(0.2))
                                .frame(height: 6)
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: state.stats.ramPercent > 85 ? [.orange, .red] : [.cyan, .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(state.stats.ramPercent / 100.0))), height: 6)
                        }
                    }
                    .frame(height: 6)
                }
                
                // Swap & Disk Split
                HStack(spacing: 8) {
                    // Swap Box
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 13))
                            .foregroundColor(state.stats.usedSwapGB > 0.5 ? .orange : .secondary)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(state.t(.swapMemory))
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.secondary)
                            Text(String(format: "%.2f GB", state.stats.usedSwapGB))
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(state.stats.usedSwapGB > 1.0 ? .red : .primary)
                        }
                        Spacer()
                    }
                    .padding(6)
                    .background(Color.secondary.opacity(0.08))
                    .cornerRadius(6)
                    
                    // Disk Box
                    HStack {
                        Image(systemName: "internaldrive")
                            .font(.system(size: 13))
                            .foregroundColor(.cyan)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(state.t(.diskApfs))
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f GB", state.stats.freeDiskGB))
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                        }
                        Spacer()
                    }
                    .padding(6)
                    .background(Color.secondary.opacity(0.08))
                    .cornerRadius(6)
                }
            }
            .padding(10)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
            )
            
            // MARK: Top Memory Consumers
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(license.isPro ? state.t(.topMemoryHogsPro) : state.t(.topMemoryHogsFree))
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(license.isPro ? state.t(.actionsHeader) : state.t(.actionsPro))
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundColor(license.isPro ? .secondary : .yellow)
                }
                
                if state.hogs.isEmpty {
                    Text(state.t(.noHogsFound))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                } else {
                    ForEach(state.hogs) { hog in
                        HStack(spacing: 8) {
                            Image(systemName: hog.icon)
                                .font(.system(size: 12))
                                .foregroundColor(.cyan)
                                .frame(width: 16)
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(hog.displayName)
                                    .font(.system(size: 11, weight: .semibold))
                                    .lineLimit(1)
                                Text("PID \(hog.id)")
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(hog.formattedMem)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.orange)
                            
                            if license.isPro {
                                Button {
                                    state.killHog(pid: hog.id, name: hog.name, force: false)
                                } label: {
                                    Text(state.t(.term))
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Color.secondary.opacity(0.2))
                                        .cornerRadius(4)
                                }
                                .buttonStyle(.plain)
                                
                                Button {
                                    state.killHog(pid: hog.id, name: hog.name, force: true)
                                } label: {
                                    Text(state.t(.kill))
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Color.red.opacity(0.8))
                                        .cornerRadius(4)
                                }
                                .buttonStyle(.plain)
                            } else {
                                Button {
                                    withAnimation {
                                        license.showActivationSheet = true
                                    }
                                } label: {
                                    HStack(spacing: 2) {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 8))
                                        Text(state.t(.kill))
                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.15))
                                    .foregroundColor(.secondary)
                                    .cornerRadius(4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .padding(10)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
            )
            
            // MARK: Emergency Quick Actions
            HStack(spacing: 8) {
                Button {
                    state.purgeMemory()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: license.isPro ? "trash.fill" : "lock.fill")
                        Text(license.isPro ? state.t(.flushCache) : state.t(.flushCachePro))
                    }
                    .font(.system(size: 10, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(license.isPro ? Color.secondary.opacity(0.12) : Color.secondary.opacity(0.06))
                    .foregroundColor(license.isPro ? .primary : .secondary)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                
                Button {
                    state.unloadAIModels()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: license.isPro ? "cpu.fill" : "lock.fill")
                        Text(license.isPro ? state.t(.ejectAi) : state.t(.ejectAiPro))
                    }
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(license.isPro ? .cyan : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(license.isPro ? Color.cyan.opacity(0.12) : Color.secondary.opacity(0.06))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            
            // MARK: Remote Server / VPS Telemetry Card & Configuration Table
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(state.activeServer != nil ? (license.isPro ? ((state.vps?.isOnline == true) ? Color.green : Color.red) : Color.yellow) : Color.secondary)
                            .frame(width: 7, height: 7)
                        
                        Text(state.activeServer != nil ? state.activeServer!.name.uppercased() : state.t(.vpsTelemetryTitle))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Buttons
                    if state.activeServer != nil && license.isPro {
                        if state.isVpsLoading {
                            ProgressView()
                                .scaleEffect(0.5)
                                .frame(width: 12, height: 12)
                        } else {
                            Button {
                                state.refreshVps()
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 9))
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.secondary)
                        }
                    }
                    
                    // Toggle Server Configuration Table / Drawer
                    Button {
                        withAnimation {
                            state.isConfiguringServers.toggle()
                            state.serverTestMessage = nil
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: state.isConfiguringServers ? "xmark" : "slider.horizontal.3")
                                .font(.system(size: 9, weight: .bold))
                            Text(state.isConfiguringServers ? state.t(.closeBtn) : (state.servers.isEmpty ? state.t(.configureBtn) : state.t(.serversBtn)))
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(state.isConfiguringServers ? Color.red.opacity(0.15) : Color.secondary.opacity(0.12))
                        .foregroundColor(state.isConfiguringServers ? .red : .primary)
                        .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }
                
                // Content: Either Config Table or Telemetry Display
                if state.isConfiguringServers {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(state.t(.serversTableTitle))
                                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                                .foregroundColor(.secondary)
                            Spacer()
                            if !state.isShowingAddServer {
                                Button {
                                    withAnimation {
                                        state.startAddServer()
                                    }
                                } label: {
                                    HStack(spacing: 3) {
                                        Image(systemName: "plus")
                                        Text(state.t(.addServer))
                                    }
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.cyan)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        // Server Table
                        if !state.servers.isEmpty {
                            VStack(spacing: 4) {
                                ForEach(state.servers) { s in
                                    HStack(spacing: 6) {
                                        // Active selection radio
                                        Button {
                                            state.selectServer(id: s.id)
                                        } label: {
                                            Image(systemName: state.selectedServerId == s.id ? "largecircle.fill.circle" : "circle")
                                                .font(.system(size: 10))
                                                .foregroundColor(state.selectedServerId == s.id ? .green : .secondary)
                                        }
                                        .buttonStyle(.plain)
                                        
                                        VStack(alignment: .leading, spacing: 1) {
                                            HStack(spacing: 4) {
                                                Text(s.name)
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundColor(state.selectedServerId == s.id ? .primary : .secondary)
                                                
                                                Text(s.connectionType.rawValue)
                                                    .font(.system(size: 7, weight: .heavy, design: .monospaced))
                                                    .padding(.horizontal, 3)
                                                    .padding(.vertical, 0.5)
                                                    .background(s.connectionType == .ssh ? Color.orange.opacity(0.2) : Color.cyan.opacity(0.2))
                                                    .foregroundColor(s.connectionType == .ssh ? .orange : .cyan)
                                                    .cornerRadius(3)
                                                
                                                if state.selectedServerId == s.id {
                                                    Text(state.t(.activeBadge))
                                                        .font(.system(size: 7, weight: .heavy, design: .monospaced))
                                                        .padding(.horizontal, 3)
                                                        .padding(.vertical, 0.5)
                                                        .background(Color.green.opacity(0.2))
                                                        .foregroundColor(.green)
                                                        .cornerRadius(3)
                                                }
                                            }
                                            Text(s.connectionType == .ssh ? "\(s.user)@\(s.host):\(s.port)" : s.urlString)
                                                .font(.system(size: 8, design: .monospaced))
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                        
                                        Spacer()
                                        
                                        // Edit button
                                        Button {
                                            withAnimation {
                                                state.startEditServer(server: s)
                                            }
                                        } label: {
                                            Image(systemName: "pencil")
                                                .font(.system(size: 9))
                                                .foregroundColor(.secondary)
                                        }
                                        .buttonStyle(.plain)
                                        
                                        // Delete button
                                        Button {
                                            state.deleteServer(id: s.id)
                                            if state.editingServerId == s.id {
                                                state.cancelServerEdit()
                                            }
                                        } label: {
                                            Image(systemName: "trash")
                                                .font(.system(size: 9))
                                                .foregroundColor(.red.opacity(0.8))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(5)
                                    .background(state.selectedServerId == s.id ? Color.cyan.opacity(0.08) : Color.secondary.opacity(0.04))
                                    .cornerRadius(5)
                                }
                            }
                        } else if !state.isShowingAddServer {
                            Text(state.t(.noServersConfiguredPrompt))
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                                .padding(.vertical, 4)
                        }
                        
                        // Add / Edit Server Form
                        if state.isShowingAddServer || state.servers.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(state.editingServerId != nil ? state.t(.editServerTitle) : state.t(.addServerTitle))
                                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                                    .foregroundColor(.cyan)
                                
                                // Protocol Selector: SSH vs HTTP
                                HStack(spacing: 4) {
                                    Button {
                                        withAnimation { state.inputServerConnectionType = .ssh }
                                    } label: {
                                        HStack(spacing: 3) {
                                            Image(systemName: "terminal.fill")
                                            Text(state.t(.sshTab))
                                        }
                                        .font(.system(size: 8, weight: .bold))
                                        .padding(.vertical, 3)
                                        .frame(maxWidth: .infinity)
                                        .background(state.inputServerConnectionType == .ssh ? Color.orange.opacity(0.25) : Color.secondary.opacity(0.08))
                                        .foregroundColor(state.inputServerConnectionType == .ssh ? .orange : .secondary)
                                        .cornerRadius(4)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Button {
                                        withAnimation { state.inputServerConnectionType = .http }
                                    } label: {
                                        HStack(spacing: 3) {
                                            Image(systemName: "network")
                                            Text(state.t(.httpTab))
                                        }
                                        .font(.system(size: 8, weight: .bold))
                                        .padding(.vertical, 3)
                                        .frame(maxWidth: .infinity)
                                        .background(state.inputServerConnectionType == .http ? Color.cyan.opacity(0.25) : Color.secondary.opacity(0.08))
                                        .foregroundColor(state.inputServerConnectionType == .http ? .cyan : .secondary)
                                        .cornerRadius(4)
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                TextField(state.t(.serverNamePlaceholder), text: $state.inputServerName)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 10))
                                
                                if state.inputServerConnectionType == .ssh {
                                    // SSH Mode Inputs
                                    Text(state.t(.sshInstructions))
                                        .font(.system(size: 8))
                                        .foregroundColor(.secondary)
                                    
                                    TextField(state.t(.hostPlaceholder), text: $state.inputServerHost)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.system(size: 10, design: .monospaced))
                                    
                                    HStack(spacing: 6) {
                                        TextField(state.t(.userPlaceholder), text: $state.inputServerUser)
                                            .textFieldStyle(.roundedBorder)
                                            .font(.system(size: 10, design: .monospaced))
                                            .frame(maxWidth: .infinity)
                                        
                                        TextField(state.t(.portPlaceholder), text: $state.inputServerPort)
                                            .textFieldStyle(.roundedBorder)
                                            .font(.system(size: 10, design: .monospaced))
                                            .frame(width: 55)
                                    }
                                    
                                    HStack(spacing: 6) {
                                        Button {
                                            state.inputServerAuthType = "password"
                                        } label: {
                                            Text(state.t(.sshPasswordAuth))
                                                .font(.system(size: 8, weight: state.inputServerAuthType == "password" ? .bold : .regular))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(state.inputServerAuthType == "password" ? Color.orange.opacity(0.2) : Color.clear)
                                                .foregroundColor(state.inputServerAuthType == "password" ? .orange : .secondary)
                                                .cornerRadius(3)
                                        }
                                        .buttonStyle(.plain)
                                        
                                        Button {
                                            state.inputServerAuthType = "key"
                                        } label: {
                                            Text(state.t(.sshKeyAuth))
                                                .font(.system(size: 8, weight: state.inputServerAuthType == "key" ? .bold : .regular))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(state.inputServerAuthType == "key" ? Color.orange.opacity(0.2) : Color.clear)
                                                .foregroundColor(state.inputServerAuthType == "key" ? .orange : .secondary)
                                                .cornerRadius(3)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    
                                    if state.inputServerAuthType == "password" {
                                        SecureField(state.t(.sshPasswordPlaceholder), text: $state.inputServerPassword)
                                            .textFieldStyle(.roundedBorder)
                                            .font(.system(size: 10, design: .monospaced))
                                    } else {
                                        TextField(state.t(.sshKeyPathPlaceholder), text: $state.inputServerKeyPath)
                                            .textFieldStyle(.roundedBorder)
                                            .font(.system(size: 10, design: .monospaced))
                                    }
                                } else {
                                    // HTTP Mode Inputs
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(state.t(.httpInstructions))
                                            .font(.system(size: 8))
                                            .foregroundColor(.secondary)
                                        
                                        HStack {
                                            Text("curl -fsSL https://raw.githubusercontent.com/Arielkap/coredeck-mac/main/tools/install_agent.sh | bash")
                                                .font(.system(size: 7.5, design: .monospaced))
                                                .lineLimit(1)
                                                .foregroundColor(.cyan)
                                            
                                            Spacer()
                                            
                                            Button {
                                                NSPasteboard.general.clearContents()
                                                NSPasteboard.general.setString("curl -fsSL https://raw.githubusercontent.com/Arielkap/coredeck-mac/main/tools/install_agent.sh | bash", forType: .string)
                                                state.serverTestMessage = state.t(.commandCopied)
                                            } label: {
                                                Image(systemName: "doc.on.doc")
                                                    .font(.system(size: 8))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .padding(4)
                                        .background(Color.black.opacity(0.3))
                                        .cornerRadius(4)
                                    }
                                    
                                    TextField(state.t(.httpUrlPlaceholder), text: $state.inputServerUrl)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.system(size: 10, design: .monospaced))
                                    
                                    SecureField(state.t(.httpKeyPlaceholder), text: $state.inputServerKey)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.system(size: 10, design: .monospaced))
                                }
                                
                                if let testMsg = state.serverTestMessage {
                                    Text(testMsg)
                                        .font(.system(size: 8, weight: .semibold))
                                        .foregroundColor(testMsg.hasPrefix("🟢") ? .green : .red)
                                }
                                
                                HStack(spacing: 6) {
                                    // Test button
                                    Button {
                                        Task {
                                            let temp = VpsServerConfig(
                                                name: state.inputServerName,
                                                connectionType: state.inputServerConnectionType,
                                                host: state.inputServerHost,
                                                port: Int(state.inputServerPort) ?? 22,
                                                user: state.inputServerUser,
                                                authType: state.inputServerAuthType,
                                                password: state.inputServerPassword,
                                                keyPath: state.inputServerKeyPath,
                                                urlString: state.inputServerUrl,
                                                apiKey: state.inputServerKey
                                            )
                                            _ = await state.testServer(server: temp)
                                        }
                                    } label: {
                                        if state.isTestingServer {
                                            ProgressView()
                                                .scaleEffect(0.5)
                                                .frame(width: 45)
                                        } else {
                                            Text(state.t(.testBtn))
                                                .font(.system(size: 9, weight: .bold))
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.secondary.opacity(0.15))
                                                .foregroundColor(.primary)
                                                .cornerRadius(4)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Spacer()
                                    
                                    if !state.servers.isEmpty {
                                        Button {
                                            withAnimation {
                                                state.cancelServerEdit()
                                            }
                                        } label: {
                                            Text(state.t(.cancelBtn))
                                                .font(.system(size: 9))
                                                .foregroundColor(.secondary)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 4)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    
                                    Button {
                                        let isSsh = state.inputServerConnectionType == .ssh
                                        let hostOrUrlValid = isSsh ? !state.inputServerHost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty : !state.inputServerUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                        guard hostOrUrlValid else { return }
                                        
                                        state.addOrUpdateServer(
                                            id: state.editingServerId,
                                            name: state.inputServerName,
                                            connectionType: state.inputServerConnectionType,
                                            host: state.inputServerHost,
                                            port: Int(state.inputServerPort) ?? 22,
                                            user: state.inputServerUser,
                                            authType: state.inputServerAuthType,
                                            password: state.inputServerPassword,
                                            keyPath: state.inputServerKeyPath,
                                            urlString: state.inputServerUrl,
                                            apiKey: state.inputServerKey
                                        )
                                        state.cancelServerEdit()
                                    } label: {
                                        Text(state.t(.saveServerBtn))
                                            .font(.system(size: 9, weight: .heavy))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(state.inputServerConnectionType == .ssh ? Color.orange : Color.cyan)
                                            .foregroundColor(.black)
                                            .cornerRadius(4)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(state.inputServerConnectionType == .ssh ? state.inputServerHost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty : state.inputServerUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                }
                            }
                            .padding(8)
                            .background(Color.secondary.opacity(0.06))
                            .cornerRadius(6)
                        }
                    }
                } else {
                    // Normal Telemetry View
                    if let server = state.activeServer {
                        // Multi-server switcher pills if more than 1 server
                        if state.servers.count > 1 {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 4) {
                                    ForEach(state.servers) { s in
                                        let isSelected = (state.selectedServerId == s.id)
                                        Button {
                                            state.selectServer(id: s.id)
                                        } label: {
                                            Text(s.name)
                                                .font(.system(size: 8, weight: isSelected ? .bold : .regular, design: .monospaced))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(isSelected ? Color.cyan.opacity(0.2) : Color.secondary.opacity(0.1))
                                                .foregroundColor(isSelected ? Color.cyan : Color.secondary)
                                                .cornerRadius(3)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        
                        if license.isPro {
                            if let vps = state.vps {
                                HStack(spacing: 8) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("RAM")
                                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                                            .foregroundColor(.secondary)
                                        Text(vps.ram != nil ? "\(Int(vps.ram!.used_mb))/\(Int(vps.ram!.total_mb))M" : "--")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    }
                                    Spacer()
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("LOAD")
                                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                                            .foregroundColor(.secondary)
                                        Text(vps.load?.first != nil ? String(format: "%.2f", vps.load!.first!) : "--")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    }
                                    Spacer()
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("DISK")
                                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                                            .foregroundColor(.secondary)
                                        Text(vps.disk != nil ? "\(Int(vps.disk!.used_gb))/\(Int(vps.disk!.total_gb))G" : "--")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    }
                                    Spacer()
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("UPTIME")
                                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                                            .foregroundColor(.secondary)
                                        Text(vps.uptime ?? "--")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .lineLimit(1)
                                    }
                                }
                                .padding(6)
                                .background(Color.secondary.opacity(0.08))
                                .cornerRadius(6)
                            } else {
                                HStack {
                                    Text("\(state.t(.connectingTo)) \(server.name)...")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Button(state.t(.checkBtn)) {
                                        state.refreshVps()
                                    }
                                    .font(.system(size: 9, weight: .bold))
                                    .buttonStyle(.plain)
                                    .foregroundColor(.cyan)
                                }
                                .padding(6)
                            }
                        } else {
                            // Locked Promo Box
                            VStack(alignment: .leading, spacing: 6) {
                                Text(state.t(.vpsPromoDesc))
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                
                                Button {
                                    withAnimation {
                                        license.showActivationSheet = true
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "lock.open.fill")
                                        Text(state.t(.unlockVpsPro))
                                    }
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.yellow)
                                    .frame(maxWidth: .infinity)
                                    .padding(6)
                                    .background(Color.yellow.opacity(0.1))
                                    .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(6)
                            .background(Color.secondary.opacity(0.04))
                            .cornerRadius(6)
                        }
                    } else {
                        // Empty State: No Server Configured
                        VStack(spacing: 6) {
                            HStack {
                                Image(systemName: "server.rack")
                                    .foregroundColor(.cyan)
                                Text(state.t(.noServerEmptyTitle))
                                    .font(.system(size: 10, weight: .semibold))
                                Spacer()
                            }
                            Text(state.t(.noServerEmptyDesc))
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                            
                            Button {
                                withAnimation {
                                    state.isConfiguringServers = true
                                    state.startAddServer()
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                    Text(state.t(.configureVpsBtn))
                                }
                                .font(.system(size: 10, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(6)
                                .background(Color.cyan.opacity(0.15))
                                .foregroundColor(.cyan)
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(6)
                    }
                }
            }
            .padding(10)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
            )
            
            // MARK: Footer Settings
            VStack(spacing: 6) {
                HStack {
                    Toggle(isOn: $state.isCompact) {
                        Text(state.t(.compactBar))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .toggleStyle(.checkbox)
                    
                    Spacer()
                    
                    Toggle(isOn: Binding(
                        get: { state.launchAtLogin },
                        set: { _ in state.toggleLaunchAtLogin() }
                    )) {
                        Text(state.t(.launchAtLogin))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .toggleStyle(.checkbox)
                }
                
                HStack {
                    if license.isPro {
                        Text(state.t(.proActive))
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.yellow)
                    } else {
                        Text(state.t(.freeEvaluation))
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    // Language Switcher Flag Button
                    Button {
                        state.toggleLanguage()
                    } label: {
                        HStack(spacing: 3) {
                            Text(state.language.flag)
                                .font(.system(size: 11))
                            Text(state.language.code)
                                .font(.system(size: 8, weight: .heavy, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.12))
                        .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    
                    Text("v2.0 Native Swift")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.secondary.opacity(0.5))
                }
            }
            .padding(.top, 2)
        }
        .padding(12)
        .frame(width: 350)
    }
}
