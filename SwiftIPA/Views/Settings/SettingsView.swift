import SwiftUI

private enum ResetAction: Identifiable, Equatable {
    case signedApps
    case importedApps
    case certificates
    case everything

    var id: Int {
        switch self {
        case .signedApps: return 0
        case .importedApps: return 1
        case .certificates: return 2
        case .everything: return 3
        }
    }

    var title: String {
        switch self {
        case .signedApps: return String(localized: "Remove all signed apps?")
        case .importedApps: return String(localized: "Remove all imported apps?")
        case .certificates: return String(localized: "Remove all certificates?")
        case .everything: return String(localized: "Reset SwiftIPA completely?")
        }
    }

    var message: String {
        switch self {
        case .signedApps: return String(localized: "This deletes every signed app from your library. Their original imported IPAs are removed too.")
        case .importedApps: return String(localized: "This deletes every app in your library that hasn't been signed yet. Signed apps are left alone.")
        case .certificates: return String(localized: "This deletes every certificate, its saved password, and its expiry tracking.")
        case .everything: return String(localized: "This deletes your entire library, all certificates, tweaks, presets, sources, and the signing cache, and resets every setting. There's no undo.")
        }
    }

    var confirmTitle: String {
        self == .everything ? String(localized: "Reset Everything") : String(localized: "Remove")
    }
}

// MARK: - Reusable Settings Icon Badge
private struct SettingsIcon: View {
    let systemName: String
    let backgroundColor: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(backgroundColor.gradient)
                .frame(width: 28, height: 28)
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

struct SettingsView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var certificateStore = CertificateStore.shared
    @ObservedObject private var dylibStore = DylibLibraryStore.shared
    @State private var cacheSize: Int64 = SigningCache.shared.totalSize
    @State private var updateResult: UpdateCheckResult?
    @State private var isCheckingUpdate = false
    @State private var updateError: String?

    var body: some View {
        List {
            // MARK: - Signing
            Section {
                NavigationLink {
                    CertificatesView()
                } label: {
                    HStack(spacing: 12) {
                        SettingsIcon(systemName: "checkmark.seal.fill", backgroundColor: .orange)
                        Text("Certificates")
                            .foregroundStyle(SIColor.textPrimary)
                        Spacer()
                        Text("\(certificateStore.certificates.count)")
                            .font(.subheadline)
                            .foregroundStyle(SIColor.textSecondary)
                    }
                }

                NavigationLink {
                    TweaksLibraryView()
                } label: {
                    HStack(spacing: 12) {
                        SettingsIcon(systemName: "shippingbox.fill", backgroundColor: .purple)
                        Text("Tweak Library")
                            .foregroundStyle(SIColor.textPrimary)
                        Spacer()
                        Text("\(dylibStore.dylibs.count)")
                            .font(.subheadline)
                            .foregroundStyle(SIColor.textSecondary)
                    }
                }

                NavigationLink {
                    PresetsView()
                } label: {
                    HStack(spacing: 12) {
                        SettingsIcon(systemName: "slider.horizontal.3", backgroundColor: .blue)
                        Text("Signing Presets")
                            .foregroundStyle(SIColor.textPrimary)
                    }
                }

                NavigationLink {
                    DefaultSigningOptionsView()
                } label: {
                    HStack(spacing: 12) {
                        SettingsIcon(systemName: "gearshape.2.fill", backgroundColor: .gray)
                        Text("Default Signing Options")
                            .foregroundStyle(SIColor.textPrimary)
                    }
                }
            } header: {
                Text("Signing")
            }

            // MARK: - Appearance
            Section {
                NavigationLink {
                    ThemePickerView()
                } label: {
                    HStack(spacing: 12) {
                        SettingsIcon(systemName: "paintpalette.fill", backgroundColor: .pink)
                        Text("Theme")
                            .foregroundStyle(SIColor.textPrimary)
                        Spacer()
                        HStack(spacing: 6) {
                            Circle()
                                .fill(SIColor.accent)
                                .frame(width: 8, height: 8)
                            Text(themeManager.current.id.displayName)
                                .font(.subheadline)
                                .foregroundStyle(SIColor.textSecondary)
                        }
                    }
                }
            } header: {
                Text("Appearance")
            }

            // MARK: - Cache
            Section {
                HStack(spacing: 12) {
                    SettingsIcon(systemName: "internaldrive.fill", backgroundColor: .teal)
                    Text("Instant-Resign Cache")
                        .foregroundStyle(SIColor.textPrimary)
                    Spacer()
                    Text(ByteCountFormatter.string(fromByteCount: cacheSize, countStyle: .file))
                        .font(.subheadline)
                        .foregroundStyle(SIColor.textSecondary)
                }

                Button(role: .destructive) {
                    SigningCache.shared.clear()
                    cacheSize = 0
                } label: {
                    HStack(spacing: 12) {
                        SettingsIcon(systemName: "trash.fill", backgroundColor: .red)
                        Text("Clear Cache")
                            .fontWeight(.medium)
                        Spacer()
                    }
                }
            } header: {
                Text("Cache")
            }

            // MARK: - Support & Community
            Section {
                NavigationLink {
                    BugReportView()
                } label: {
                    HStack(spacing: 12) {
                        SettingsIcon(systemName: "ladybug.fill", backgroundColor: .red)
                        Text("Bugs & Issues")
                            .foregroundStyle(SIColor.textPrimary)
                    }
                }

                NavigationLink {
                    ChangelogView()
                } label: {
                    HStack(spacing: 12) {
                        SettingsIcon(systemName: "sparkles", backgroundColor: .yellow)
                        Text("Changelog")
                            .foregroundStyle(SIColor.textPrimary)
                    }
                }

                Link(destination: URL(string: "https://t.me/ashtemobile")!) {
                    HStack(spacing: 12) {
                        SettingsIcon(systemName: "paperplane.fill", backgroundColor: Color(red: 0.16, green: 0.58, blue: 0.94))
                        Text("Telegram Channel")
                            .foregroundStyle(SIColor.textPrimary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(SIColor.textSecondary)
                    }
                }
            } header: {
                Text("Support")
            }

            // MARK: - About & Updates
            Section {
                HStack(spacing: 12) {
                    SettingsIcon(systemName: "info.circle.fill", backgroundColor: .cyan)
                    Text("Version")
                        .foregroundStyle(SIColor.textPrimary)
                    Spacer()
                    Text(versionString)
                        .font(.subheadline)
                        .foregroundStyle(SIColor.textSecondary)
                }

                Button {
                    checkForUpdate()
                } label: {
                    HStack(spacing: 12) {
                        SettingsIcon(systemName: "arrow.triangle.2.circlepath", backgroundColor: .green)
                        Text("Check for Updates")
                            .foregroundStyle(SIColor.textPrimary)
                        Spacer()
                        if isCheckingUpdate {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                }
                .disabled(isCheckingUpdate)

                if let updateResult {
                    if updateResult.isUpdateAvailable {
                        Link(destination: updateResult.releaseURL) {
                            HStack(spacing: 12) {
                                SettingsIcon(systemName: "arrow.down.app.fill", backgroundColor: SIColor.accent)
                                Text("Update to \(updateResult.latestVersion)")
                                    .fontWeight(.medium)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                        }
                    } else {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("You're up to date.")
                                .foregroundStyle(SIColor.textSecondary)
                                .font(.subheadline)
                        }
                        .padding(.vertical, 2)
                    }
                }

                if let updateError {
                    Text(updateError)
                        .foregroundStyle(SIColor.danger)
                        .font(SIFont.caption)
                }
            } header: {
                Text("About")
            }

            // MARK: - Storage & Advanced
            Section {
                NavigationLink {
                    StorageResetView()
                } label: {
                    HStack(spacing: 12) {
                        SettingsIcon(systemName: "cylinder.split.1x2.fill", backgroundColor: .orange)
                        Text("Storage & Reset")
                            .foregroundStyle(SIColor.textPrimary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .siScreen()
        .navigationTitle("Settings")
        .onAppear { cacheSize = SigningCache.shared.totalSize }
    }

    private var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        return "\(version) (\(build))"
    }

    private func checkForUpdate() {
        isCheckingUpdate = true
        updateError = nil
        Task {
            do {
                let result = try await UpdateChecker.shared.checkForUpdate()
                await MainActor.run {
                    updateResult = result
                    isCheckingUpdate = false
                }
            } catch {
                await MainActor.run {
                    updateError = error.localizedDescription
                    isCheckingUpdate = false
                }
            }
        }
    }
}

private struct ThemePickerView: View {
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        List {
            ForEach(SIThemeID.allCases) { id in
                Button {
                    themeManager.select(id)
                } label: {
                    HStack(spacing: 14) {
                        Circle()
                            .fill(SITheme.theme(for: id).accent)
                            .frame(width: 16, height: 16)
                        Text(id.displayName)
                            .foregroundStyle(SIColor.textPrimary)
                        Spacer()
                        if themeManager.current.id == id {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(SIColor.accent)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.insetGrouped)
        .siScreen()
        .navigationTitle("Theme")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct StorageResetView: View {
    @State private var pendingReset: ResetAction?

    var body: some View {
        List {
            Section {
                Button {
                    openAppFolder()
                } label: {
                    HStack(spacing: 12) {
                        SettingsIcon(systemName: "folder.fill", backgroundColor: .blue)
                        Text("View App Folder")
                            .foregroundStyle(SIColor.textPrimary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(SIColor.textSecondary)
                    }
                }
            } footer: {
                Text("Opens SwiftIPA's Documents folder in the Files app — imported and signed IPAs, certificates, tweaks, and presets all live there.")
            }

            Section {
                Button(role: .destructive) {
                    pendingReset = .signedApps
                } label: {
                    HStack(spacing: 12) {
                        SettingsIcon(systemName: "trash", backgroundColor: .red.opacity(0.8))
                        Text("Remove All Signed Apps")
                    }
                }

                Button(role: .destructive) {
                    pendingReset = .importedApps
                } label: {
                    HStack(spacing: 12) {
                        SettingsIcon(systemName: "doc.badge.arrow.up", backgroundColor: .red.opacity(0.8))
                        Text("Remove All Imported Apps")
                    }
                }

                Button(role: .destructive) {
                    pendingReset = .certificates
                } label: {
                    HStack(spacing: 12) {
                        SettingsIcon(systemName: "xmark.seal", backgroundColor: .red.opacity(0.8))
                        Text("Remove All Certificates")
                    }
                }

                Button(role: .destructive) {
                    pendingReset = .everything
                } label: {
                    HStack(spacing: 12) {
                        SettingsIcon(systemName: "exclamationmark.triangle.fill", backgroundColor: .red)
                        Text("Reset Everything")
                            .fontWeight(.semibold)
                    }
                }
            } header: {
                Text("Reset")
            } footer: {
                Text("These remove data from this device only and can't be undone.")
            }
        }
        .listStyle(.insetGrouped)
        .siScreen()
        .navigationTitle("Storage & Reset")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            pendingReset?.title ?? "",
            isPresented: Binding(get: { pendingReset != nil }, set: { if !$0 { pendingReset = nil } }),
            titleVisibility: .visible
        ) {
            if let pendingReset {
                Button(pendingReset.confirmTitle, role: .destructive) {
                    performReset(pendingReset)
                }
            }
        } message: {
            if let pendingReset {
                Text(pendingReset.message)
            }
        }
    }

    private func openAppFolder() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        guard let url = URL(string: "shareddocuments://" + documents.path) else { return }
        UIApplication.shared.open(url)
    }

    private func performReset(_ action: ResetAction) {
        switch action {
        case .signedApps:
            AppLibraryStore.shared.removeAll { $0.isSigned }
        case .importedApps:
            AppLibraryStore.shared.removeAll { !$0.isSigned }
        case .certificates:
            CertificateStore.shared.removeAllCertificates()
        case .everything:
            AppLibraryStore.shared.removeAll { _ in true }
            CertificateStore.shared.removeAllCertificates()
            DylibLibraryStore.shared.removeAll()
            PresetStore.shared.removeAll()
            SourceStore.shared.removeAll()
            DefaultSigningOptionsStore.shared.resetToDefaults()
            SigningCache.shared.clear()
        }
    }
}
