import SwiftUI

struct SigningOptionsEditor: View {
    enum Layout {
        case full
        case compact
        case advancedOnly
    }

    @Binding var options: SigningOptions
    var certificateID: UUID?
    var showsInstallToggle: Bool = true
    var layout: Layout = .full

    @ObservedObject private var dylibStore = DylibLibraryStore.shared
    @State private var showingTweakPicker = false
    @State private var isImportingTweak = false
    @State private var tweakImportError: String?

    var body: some View {
        switch layout {
        case .full:
            tweaksSection
            advancedSections
        case .compact:
            tweaksSection
            moreOptionsSection
        case .advancedOnly:
            advancedSections
        }
    }

    @ViewBuilder
    private var advancedSections: some View {
        appearanceSection
        compatibilitySection
        removalSection
        networkSection
        entitlementsSection
        advancedSection
    }

    private var moreOptionsSection: some View {
        Section {
            NavigationLink {
                Form {
                    SigningOptionsEditor(
                        options: $options,
                        certificateID: certificateID,
                        showsInstallToggle: showsInstallToggle,
                        layout: .advancedOnly
                    )
                }
                .formStyle(.grouped)
                .navigationTitle("More Options")
                .navigationBarTitleDisplayMode(.inline)
                .preferredColorScheme(.dark)
            } label: {
                HStack {
                    Text("More Options")
                    Spacer()
                    if changedOptionCount > 0 {
                        Text("\(changedOptionCount) changed")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if showsInstallToggle {
                Toggle("Install After Signing", isOn: $options.installAfterSigning)
            }
        } footer: {
            Text("Appearance, compatibility, removal, network, entitlements and speed settings.")
        }
    }

    private var changedOptionCount: Int {
        let d = SigningOptions()
        let flags: [Bool] = [
            options.appearance != d.appearance,
            options.liquidGlassMode != d.liquidGlassMode,
            options.forceFileSharing != d.forceFileSharing,
            options.forceDocumentBrowser != d.forceDocumentBrowser,
            options.forceFullScreen != d.forceFullScreen,
            options.forceProMotion != d.forceProMotion,
            options.forceGameMode != d.forceGameMode,
            options.forceLocalizedDisplayName != d.forceLocalizedDisplayName,
            options.removePlugins != d.removePlugins,
            options.removeWatchApp != d.removeWatchApp,
            options.removeProvisioningProfile != d.removeProvisioningProfile,
            options.removeLocalizations != d.removeLocalizations,
            options.removeURLSchemes != d.removeURLSchemes,
            options.allowArbitraryLoads != d.allowArbitraryLoads,
            options.entitlements != d.entitlements,
            options.useCache != d.useCache,
            options.stripExistingSignature != d.stripExistingSignature,
            options.fastPackaging != d.fastPackaging,
        ]
        return flags.filter { $0 }.count
    }

    private var appearanceSection: some View {
        Section {
            Picker("Appearance", selection: $options.appearance) {
                ForEach(AppAppearance.allCases) { appearance in
                    Text(appearance.displayName).tag(appearance)
                }
            }
            Picker("Design", selection: $options.liquidGlassMode) {
                ForEach(LiquidGlassMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
        } header: {
            Text("APPEARANCE")
        }
    }

    private var compatibilitySection: some View {
        Section {
            Toggle("iTunes File Sharing", isOn: $options.forceFileSharing)
            Toggle("Files App Access", isOn: $options.forceDocumentBrowser)
            Toggle("Force Full Screen", isOn: $options.forceFullScreen)
            Toggle("Force ProMotion (120Hz)", isOn: $options.forceProMotion)
            Toggle("Force Game Mode", isOn: $options.forceGameMode)
            Toggle("Force Localized Display Name", isOn: $options.forceLocalizedDisplayName)
        } header: {
            Text("COMPATIBILITY")
        }
    }

    private var removalSection: some View {
        Section {
            Toggle("Remove App Extensions", isOn: $options.removePlugins)
            Toggle("Remove Watch App", isOn: $options.removeWatchApp)
            Toggle("Remove Embedded Provisioning", isOn: $options.removeProvisioningProfile)
            Toggle("Remove Localizations Except English", isOn: $options.removeLocalizations)
            Toggle("Remove URL Schemes", isOn: $options.removeURLSchemes)
        } header: {
            Text("REMOVAL")
        }
    }

    private var networkSection: some View {
        Section {
            Toggle("Allow Arbitrary Network Loads", isOn: $options.allowArbitraryLoads)
        } header: {
            Text("NETWORK")
        }
    }

    private var injectableTweaks: [InjectedDylib] {
        dylibStore.dylibs.filter { !$0.isSubstrateProvider }
    }

    private var tweaksSection: some View {
        Section {
            ForEach(injectableTweaks) { dylib in
                Toggle(isOn: Binding(
                    get: { options.injectedDylibIDs.contains(dylib.id) },
                    set: { isOn in
                        if isOn {
                            options.injectedDylibIDs.append(dylib.id)
                        } else {
                            options.injectedDylibIDs.removeAll { $0 == dylib.id }
                        }
                    }
                )) {
                    TweakRow(dylib: dylib, analysis: dylibStore.analyses[dylib.id], hasProvider: dylibStore.substrateProvider != nil)
                }
            }

            Button {
                showingTweakPicker = true
            } label: {
                if isImportingTweak {
                    HStack(spacing: 12) {
                        ProgressView().tint(.orange)
                        Text("Importing…")
                            .foregroundColor(.primary)
                    }
                } else {
                    HStack(spacing: 12) {
                        Image(systemName: "plus")
                            .font(.body.weight(.bold))
                        Text("Add .dylib or .deb")
                            .fontWeight(.medium)
                    }
                }
            }
            .disabled(isImportingTweak)
            .foregroundColor(.orange)

            if !injectableTweaks.isEmpty {
                Toggle("Inject Weakly", isOn: $options.weakInjection)
                Toggle("Inject into Extensions", isOn: $options.injectIntoExtensions)
            }
        } header: {
            Text("TWEAKS")
                .font(.footnote)
                .foregroundColor(.secondary)
        } footer: {
            Text("Tweaks from a .deb usually need ElleKit. Add ElleKit's .deb here too and it gets injected automatically.")
        }
        .sheet(isPresented: $showingTweakPicker) {
            DocumentPickerView(contentTypes: [.data, .item], allowsMultipleSelection: true) { urls in
                importTweaks(urls)
            }
            .ignoresSafeArea()
        }
        .alert("Import Failed", isPresented: Binding(get: { tweakImportError != nil }, set: { if !$0 { tweakImportError = nil } })) {
            Button("OK") { tweakImportError = nil }
        } message: {
            Text(tweakImportError ?? "")
        }
    }

    private func importTweaks(_ urls: [URL]) {
        guard !urls.isEmpty else { return }
        isImportingTweak = true
        Task {
            var firstError: String?
            var newIDs: [UUID] = []
            for url in urls {
                do {
                    let imported = try await dylibStore.importFile(at: url)
                    newIDs.append(contentsOf: imported.filter { !$0.isSubstrateProvider }.map(\.id))
                } catch {
                    if firstError == nil { firstError = error.localizedDescription }
                }
            }
            await MainActor.run {
                options.injectedDylibIDs.append(contentsOf: newIDs.filter { !options.injectedDylibIDs.contains($0) })
                isImportingTweak = false
                tweakImportError = firstError
            }
        }
    }

    private var entitlementsSection: some View {
        Section {
            NavigationLink {
                EntitlementsEditorView(
                    text: Binding(
                        get: { options.entitlements ?? "" },
                        set: { options.entitlements = $0.isEmpty ? nil : $0 }
                    ),
                    certificateID: certificateID
                )
            } label: {
                HStack {
                    Text("Entitlements")
                    Spacer()
                    Text(options.entitlements == nil ? "From Provisioning Profile" : "Customized")
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("ENTITLEMENTS")
        }
    }

    private var advancedSection: some View {
        Section {
            Toggle("Fast Packaging", isOn: $options.fastPackaging)
            Toggle("Use Instant-Resign Cache", isOn: $options.useCache)
            Toggle("Force Re-sign", isOn: $options.stripExistingSignature)
            if showsInstallToggle && layout != .advancedOnly {
                Toggle("Install After Signing", isOn: $options.installAfterSigning)
            }
        } header: {
            Text("SPEED")
        }
    }
}
