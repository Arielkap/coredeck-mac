import SwiftUI
import AppKit

public struct ServerManagerWindow: View {
    @ObservedObject var state: AppState

    public init(state: AppState) {
        self.state = state
    }

    private var parsedQuickInput: ParsedSshInput {
        SshInputParser.parse(state.inputServerQuickConnect)
    }

    private var canSubmit: Bool {
        if state.inputServerConnectionType == .ssh {
            return !state.inputServerHost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } else {
            return !state.inputServerUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // MARK: Window Header
            HStack(alignment: .center, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.cyan.opacity(0.15))
                        .frame(width: 34, height: 34)
                    Image(systemName: "server.rack")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.cyan)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(state.t(.vpsWindowTitle))
                        .font(.system(size: 15, weight: .bold))
                    Text(state.t(.vpsWindowSubtitle))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    // MARK: Saved Servers List
                    if !state.servers.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(state.t(.serversTableTitle))
                                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                                    .foregroundColor(.secondary)
                                Spacer()
                                if !state.isShowingAddServer {
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            state.startAddServer()
                                            state.showAdvancedServerOptions = false
                                        }
                                    } label: {
                                        Label(state.t(.addServer), systemImage: "plus.circle.fill")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(.cyan)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            VStack(spacing: 6) {
                                ForEach(state.servers) { s in
                                    serverRow(s)
                                }
                            }
                        }
                    }

                    // MARK: Add / Edit Server Card
                    if state.isShowingAddServer || state.servers.isEmpty {
                        serverFormCard
                    }
                }
                .padding(.bottom, 4)
            }

            // MARK: Security Footer
            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.green)
                Text(state.t(.keychainNotice))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.top, 2)
        }
        .padding(18)
        .frame(width: 470, height: 540)
        .onAppear {
            state.discoveredSshKeys = SshInputParser.discoverLocalSshKeys()
            if state.servers.isEmpty && !state.isShowingAddServer {
                state.startAddServer()
            }
        }
    }

    // MARK: - Server Row
    @ViewBuilder
    private func serverRow(_ s: VpsServerConfig) -> some View {
        let isSelected = (state.selectedServerId == s.id)
        HStack(spacing: 10) {
            Button {
                state.selectServer(id: s.id)
            } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(s.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(s.connectionType.rawValue)
                        .font(.system(size: 8, weight: .heavy, design: .monospaced))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(s.connectionType == .ssh ? Color.orange.opacity(0.2) : Color.cyan.opacity(0.2))
                        .foregroundColor(s.connectionType == .ssh ? .orange : .cyan)
                        .cornerRadius(4)

                    if isSelected {
                        Text(state.t(.activeBadge))
                            .font(.system(size: 8, weight: .heavy, design: .monospaced))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }
                }

                Text(s.connectionType == .ssh ? "\(s.user)@\(s.host):\(s.port)" : s.urlString)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    state.startEditServer(server: s)
                    state.showAdvancedServerOptions = (s.connectionType == .http || s.port != 22 || s.authType == "key")
                }
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(5)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(5)
            }
            .buttonStyle(.plain)

            Button {
                state.deleteServer(id: s.id)
                if state.editingServerId == s.id {
                    state.cancelServerEdit()
                }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                    .foregroundColor(.red.opacity(0.85))
                    .padding(5)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(5)
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(isSelected ? Color.cyan.opacity(0.08) : Color.secondary.opacity(0.06))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.cyan.opacity(0.35) : Color.secondary.opacity(0.12), lineWidth: 1)
        )
    }

    // MARK: - Form Card
    private var serverFormCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(state.editingServerId != nil ? state.t(.editServerTitle) : state.t(.addServerTitle))
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .foregroundColor(.cyan)
                Spacer()
                if state.inputServerConnectionType == .http {
                    Text("HTTP AGENT")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                }
            }

            if state.inputServerConnectionType == .ssh {
                // 1. Magic Paste Input
                VStack(alignment: .leading, spacing: 5) {
                    Text(state.t(.magicPasteLabel))
                        .font(.system(size: 11, weight: .semibold))

                    TextField(state.t(.magicPastePlaceholder), text: $state.inputServerQuickConnect)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))
                        .onChange(of: state.inputServerQuickConnect) { newVal in
                            state.applyMagicPaste(newVal)
                        }

                    if parsedQuickInput.isValid {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.green)
                            Text("\(state.t(.parsedPreviewPrefix)) \(state.inputServerUser)@\(state.inputServerHost)  •  port \(state.inputServerPort)")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 1)
                    } else {
                        Text(state.t(.magicPasteHint))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }

                // 2. Auth Type + Password / Key
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        authPill(title: state.t(.sshPasswordAuth), icon: "key.fill", value: "password")
                        authPill(title: state.t(.sshKeyAuth), icon: "doc.text.fill", value: "key")
                        Spacer()
                    }

                    if state.inputServerAuthType == "password" {
                        SecureField(state.t(.sshPasswordPlaceholder), text: $state.inputServerPassword)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12, design: .monospaced))
                    } else {
                        HStack(spacing: 6) {
                            Picker("", selection: $state.inputServerKeyPath) {
                                ForEach(state.discoveredSshKeys, id: \.self) { path in
                                    Text(path).tag(path)
                                }
                                if !state.discoveredSshKeys.contains(state.inputServerKeyPath) && !state.inputServerKeyPath.isEmpty {
                                    Text(state.inputServerKeyPath).tag(state.inputServerKeyPath)
                                }
                            }
                            .labelsHidden()
                            .frame(maxWidth: .infinity)

                            Button(state.t(.chooseKeyFileBtn)) {
                                pickSshKeyFile()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
            } else {
                // HTTP Agent Mode
                VStack(alignment: .leading, spacing: 8) {
                    Text(state.t(.httpInstructions))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    HStack(spacing: 6) {
                        Text("curl -fsSL https://raw.githubusercontent.com/Arielkap/coredeck-mac/main/tools/install_agent.sh | bash")
                            .font(.system(size: 9.5, design: .monospaced))
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .foregroundColor(.cyan)

                        Spacer()

                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString("curl -fsSL https://raw.githubusercontent.com/Arielkap/coredeck-mac/main/tools/install_agent.sh | bash", forType: .string)
                            state.serverTestMessage = state.t(.commandCopied)
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(7)
                    .background(Color.black.opacity(0.25))
                    .cornerRadius(6)

                    TextField(state.t(.httpUrlPlaceholder), text: $state.inputServerUrl)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11, design: .monospaced))

                    SecureField(state.t(.httpKeyPlaceholder), text: $state.inputServerKey)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11, design: .monospaced))
                }
            }

            // 3. Collapsible Advanced Options
            DisclosureGroup(isExpanded: $state.showAdvancedServerOptions) {
                VStack(alignment: .leading, spacing: 10) {
                    // Display Name (Optional)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(state.t(.serverNameOptionalLabel))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                        TextField(state.t(.serverNameAutoHint), text: $state.inputServerName)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 11))
                    }

                    if state.inputServerConnectionType == .ssh {
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(state.t(.userPlaceholder))
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.secondary)
                                TextField("root", text: $state.inputServerUser)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 11, design: .monospaced))
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(state.t(.portPlaceholder))
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.secondary)
                                TextField("22", text: $state.inputServerPort)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 11, design: .monospaced))
                                    .frame(width: 75)
                            }
                        }
                    }

                    // Connection Mode Switcher
                    VStack(alignment: .leading, spacing: 4) {
                        Text(state.t(.connectionModeLabel))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                        Picker("", selection: $state.inputServerConnectionType) {
                            Text(state.t(.quickSshMode)).tag(ServerConnectionType.ssh)
                            Text(state.t(.httpAgentMode)).tag(ServerConnectionType.http)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                }
                .padding(.top, 8)
            } label: {
                Text(state.t(.advancedOptions))
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundColor(.secondary)
            }

            // 4. Diagnostic Feedback Banner
            if let testMsg = state.serverTestMessage {
                let isSuccess = testMsg.hasPrefix("🟢")
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(isSuccess ? .green : .red)
                        .padding(.top, 1)
                    Text(testMsg.replacingOccurrences(of: "🟢 ", with: "").replacingOccurrences(of: "🔴 ", with: ""))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(isSuccess ? .green : .primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
                .padding(9)
                .background(isSuccess ? Color.green.opacity(0.12) : Color.red.opacity(0.12))
                .cornerRadius(7)
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(isSuccess ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
                )
            }

            // 5. Action Buttons
            HStack(spacing: 10) {
                if !state.servers.isEmpty {
                    Button(state.t(.cancelBtn)) {
                        withAnimation {
                            state.cancelServerEdit()
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                }

                Spacer()

                if state.lastTestFailed && !state.isTestingServer {
                    Button(state.t(.saveAnywayBtn)) {
                        state.saveCurrentServerIgnoringTest()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                }

                Button {
                    Task {
                        _ = await state.connectAndSaveServer()
                    }
                } label: {
                    HStack(spacing: 6) {
                        if state.isTestingServer {
                            ProgressView()
                                .scaleEffect(0.6)
                                .frame(width: 14, height: 14)
                        } else {
                            Image(systemName: "bolt.horizontal.circle.fill")
                        }
                        Text(state.isTestingServer ? state.t(.testingConnection) : state.t(.connectAndSaveBtn))
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(canSubmit ? Color.cyan : Color.secondary.opacity(0.3))
                    .foregroundColor(canSubmit ? .black : .secondary)
                    .cornerRadius(7)
                }
                .buttonStyle(.plain)
                .disabled(!canSubmit || state.isTestingServer)
            }
            .padding(.top, 4)
        }
        .padding(14)
        .background(Color.secondary.opacity(0.06))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func authPill(title: String, icon: String, value: String) -> some View {
        let active = (state.inputServerAuthType == value)
        Button {
            state.inputServerAuthType = value
            if value == "key" {
                state.discoveredSshKeys = SshInputParser.discoverLocalSshKeys()
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(title)
                    .font(.system(size: 11, weight: active ? .semibold : .regular))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(active ? Color.orange.opacity(0.22) : Color.secondary.opacity(0.1))
            .foregroundColor(active ? .orange : .secondary)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    private func pickSshKeyFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.showsHiddenFiles = true
        panel.directoryURL = URL(fileURLWithPath: ("~/.ssh" as NSString).expandingTildeInPath)
        if panel.runModal() == .OK, let url = panel.url {
            let path = url.path
            let home = NSHomeDirectory()
            let displayPath = path.hasPrefix(home) ? "~" + path.dropFirst(home.count) : path
            state.inputServerKeyPath = displayPath
            if !state.discoveredSshKeys.contains(displayPath) {
                state.discoveredSshKeys.append(displayPath)
            }
        }
    }
}
