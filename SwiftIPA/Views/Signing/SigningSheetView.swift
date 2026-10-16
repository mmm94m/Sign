import SwiftUI
import Combine

struct SigningSheetView: View {
    let entryID: UUID
    var onSignedSuccessfully: (() -> Void)?

    @ObservedObject private var library = AppLibraryStore.shared
    @ObservedObject private var certificateStore = CertificateStore.shared
    @ObservedObject private var presetStore = PresetStore.shared
    @ObservedObject private var defaultsStore = DefaultSigningOptionsStore.shared

    @State private var options = SigningOptions()
    @State private var certificateID: UUID?
    @State private var isSigning = false
    @State private var jobStatus: SigningJobStatus = .queued
    @State private var errorMessage: String?
    @State private var showingSavePreset = false
    @State private var hasSeededDefaults = false

    @Environment(\.dismiss) private var dismiss

    private var entry: AppEntry? {
        library.apps.first { $0.id == entryID }
    }

    var body: some View {
        NavigationStack {
            Form {
                if let entry {
                    
                    // MARK: - App Header Section
                    Section {
                        HStack(spacing: 16) {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(UIColor.secondarySystemFill))
                                .frame(width: 65, height: 65)
                                .overlay(
                                    Image(systemName: "app.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.orange)
                                )

                            VStack(alignment: .leading, spacing: 6) {
                                Text(entry.name)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                
                                Text("Ready to Sign")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.orange.opacity(0.15))
                                    .foregroundColor(.orange)
                                    .clipShape(Capsule())
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.clear)
                    
                    if isSigning {
                        progressSection
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    certificateSection
                    
                    identitySection(entry: entry)
                    
                    SigningOptionsEditor(options: $options, certificateID: certificateID, layout: .compact)
                }
            }
            .formStyle(.grouped)
            .tint(.orange)
            .background(Color(UIColor.systemGroupedBackground))
            .animation(.easeOut(duration: 0.25), value: isSigning)
            .presentationDragIndicator(.visible)
            .navigationTitle("Sign")
            .navigationBarTitleDisplayMode(.inline)
            .disabled(isSigning)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.orange)
                }
                ToolbarItem(placement: .primaryAction) {
                    presetMenu
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        sign()
                    } label: {
                        if isSigning {
                            ProgressView().tint(.orange)
                        } else {
                            Text("Sign").fontWeight(.bold)
                        }
                    }
                    .disabled(certificateID == nil || isSigning)
                    .foregroundColor((certificateID == nil || isSigning) ? .gray : .orange)
                }
            }
            .onAppear(perform: prepareDefaults)
            .alert("Signing Failed", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .sheet(isPresented: $showingSavePreset) {
                NameInputSheet(title: String(localized: "Save Preset"), placeholder: String(localized: "Preset name"), text: "", confirmTitle: String(localized: "Save")) { name in
                    presetStore.save(name: name, certificateID: certificateID, options: options)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var presetMenu: some View {
        Menu {
            if !presetStore.presets.isEmpty {
                Section("Load Preset") {
                    ForEach(presetStore.presets) { preset in
                        Button(preset.name) {
                            options = preset.options
                            certificateID = preset.certificateID ?? certificateID
                            presetStore.markUsed(preset)
                        }
                    }
                }
            }
            Button {
                showingSavePreset = true
            } label: {
                Label("Save Current as Preset", systemImage: "square.and.arrow.down.on.square")
            }
        } label: {
            Image(systemName: "slider.horizontal.3")
                .foregroundColor(.orange)
        }
    }

    private var certificateSection: some View {
        Group {
            if certificateStore.certificates.isEmpty {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title3)
                        Text("Add a certificate in Settings first.")
                            .font(.callout)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.red)
                    .listRowBackground(Color.red.opacity(0.15))
                }
            } else {
                Section {
                    Picker("Certificate", selection: $certificateID) {
                        ForEach(certificateStore.certificates) { certificate in
                            Text(certificate.name).tag(UUID?.some(certificate.id))
                        }
                    }
                } header: {
                    Text("CERTIFICATE")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var certificateBundleID: String? {
        certificateStore.profileBundleIdentifier(forCertificateID: certificateID)
    }

    private func identitySection(entry: AppEntry) -> some View {
        let original = entry.originalBundleIdentifier ?? entry.bundleIdentifier
        return Section {
            TextField("Display Name", text: $options.displayName)
                .autocorrectionDisabled()

            Picker("Bundle ID", selection: $options.bundleIdentifierRule) {
                ForEach(BundleIdentifierRule.allCases) { rule in
                    Text(rule.displayName).tag(rule)
                }
            }

            switch options.bundleIdentifierRule {
            case .appendSuffix:
                TextField("Suffix", text: $options.bundleIdentifierSuffix)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            case .custom:
                TextField("com.example.app", text: $options.bundleIdentifier)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                if let certificateBundleID {
                    Button {
                        options.bundleIdentifier = SigningOptions.bundleIdentifier(fromCertificateID: certificateBundleID, original: original)
                    } label: {
                        Label("Use Bundle ID from Certificate", systemImage: "checkmark.seal.fill")
                    }
                }
            default:
                EmptyView()
            }

            HStack {
                TextField("Version", text: $options.version)
                Divider()
                TextField("Build", text: $options.build)
            }
            .keyboardType(.numbersAndPunctuation)

            TextField("Minimum iOS Version", text: $options.minimumOSVersion)
                .keyboardType(.numbersAndPunctuation)
        } header: {
            Text("IDENTITY")
                .font(.footnote)
                .foregroundColor(.secondary)
        } footer: {
            identityFooter(original: original)
        }
    }

    @ViewBuilder
    private func identityFooter(original: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if options.bundleIdentifierRule == .randomSuffix {
                Text("Original bundle ID: \(original)")
            } else {
                let resolved = options.resolvedBundleIdentifier(original: original, certificateBundleID: certificateBundleID)
                Text("Signs as: \(resolved)")
                if resolved != original {
                    Text("Original bundle ID: \(original)")
                }
            }
            if let certificateBundleID {
                Text("Certificate bundle ID: \(certificateBundleID)")
            }
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }

    private var progressSection: some View {
        Section {
            HStack(spacing: 12) {
                if jobStatus.isInProgress {
                    ProgressView().tint(.orange)
                }
                signingProgressFooter
            }
        }
    }

    @ViewBuilder
    private var signingProgressFooter: some View {
        switch jobStatus {
        case .queued: Text("Queued…")
        case .extracting: Text("Unpacking IPA…")
        case .patching: Text("Applying modifiers…")
        case .signing: Text("Signing with zsign…")
        case .packaging: Text("Repacking IPA…")
        case .cached: Text("Found identical build in cache…")
        case .done(let seconds):
            Text(String(format: "Done in %.1fs.", seconds)).foregroundColor(.green)
        case .failed(let message): 
            Text(message).foregroundColor(.red)
        }
    }

    private func prepareDefaults() {
        guard let entry else { return }
        certificateID = certificateStore.defaultCertificateID ?? certificateStore.certificates.first?.id
        guard !hasSeededDefaults else { return }
        hasSeededDefaults = true
        options = defaultsStore.makeOptions(seededWith: entry)
        
        // ڕاستەوخۆ دیاریکردنی ئینستاڵکردن
        options.installAfterSigning = true
    }

    private func sign() {
        guard let entry, let certificateID else { return }
        isSigning = true

        let job = SigningJob(
            appEntryID: entry.id,
            sourceIPAURL: library.ipaURL(for: entry),
            displayName: entry.name,
            options: options,
            certificateID: certificateID
        )

        Task {
            let cancellable = job.$status.sink { status in
                Task { @MainActor in jobStatus = status }
            }
            await SigningEngine.shared.run(jobs: [job])
            cancellable.cancel()

            await MainActor.run {
                isSigning = false
                if case .failed(let message) = job.status {
                    errorMessage = message
                } else {
                    // ١. سەرەتا پەنجەرەی واژووکردن دادەخات
                    dismiss()
                    
                    // ٢. کێشەکە لێرە چارەسەر کرا: چاوەڕێی ٠.٥ چرکە دەکات تا شیتەکە بە تەواوی دادەخرێت ئینجا نامەی ئینستاڵ دەهێنێت
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onSignedSuccessfully?()
                    }
                }
            }
        }
    }
}
