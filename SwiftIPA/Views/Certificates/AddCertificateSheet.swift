import SwiftUI
import UniformTypeIdentifiers

struct AddCertificateSheet: View {
    @State private var name = ""
    @State private var password = ""
    @State private var p12URL: URL?
    @State private var provisionURL: URL?
    @State private var showingP12Picker = false
    @State private var showingProvisionPicker = false
    @State private var isImporting = false
    @State private var errorMessage: String?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Name Section
                Section {
                    TextField("Name", text: $name)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                } header: {
                    Text("CERTIFICATE NAME")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                // MARK: - Files Section
                Section {
                    filePickerRow(
                        title: String(localized: "Certificate (.p12)"), 
                        selectedName: p12URL?.lastPathComponent
                    ) {
                        showingP12Picker = true
                    }
                    
                    filePickerRow(
                        title: String(localized: "Provisioning Profile\n(.mobileprovision)"), 
                        selectedName: provisionURL?.lastPathComponent
                    ) {
                        showingProvisionPicker = true
                    }
                    
                    SecureField("P12 Password", text: $password)
                        .submitLabel(.done)
                } header: {
                    Text("FILES")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                // MARK: - Error Section
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(SIColor.danger)
                            .font(SIFont.caption)
                    }
                }
            }
            .siScreen() // سیستەمی دیزاینی پڕۆژەکەت دەپارێزێت
            .presentationDragIndicator(.visible)
            .navigationTitle("Add Certificate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(SIColor.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        addCertificate()
                    } label: {
                        if isImporting { 
                            ProgressView() 
                        } else { 
                            Text("Add")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!canAdd || isImporting)
                    .foregroundColor(canAdd ? SIColor.accent : .gray) 
                }
            }
            .sheet(isPresented: $showingP12Picker) {
                DocumentPickerView(contentTypes: [.data, .item], allowsMultipleSelection: false) { urls in
                    p12URL = urls.first
                }
            }
            .sheet(isPresented: $showingProvisionPicker) {
                DocumentPickerView(contentTypes: [.data, .item], allowsMultipleSelection: false) { urls in
                    provisionURL = urls.first
                }
            }
        }
        .preferredColorScheme(.dark) // بۆ ئەوەی ڕێک وەک وێنەکە دەربکەوێت بە تاریکی
    }

    private var canAdd: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && p12URL != nil && provisionURL != nil
    }

    private func filePickerRow(title: String, selectedName: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundStyle(SIColor.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                Spacer()
                
                Text(selectedName ?? String(localized: "Choose..."))
                    .foregroundStyle(SIColor.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .buttonStyle(.plain) // ئەمە زۆر گرنگە بۆ ئەوەی لەناو فۆڕمدا وەک دوگمەیەکی پرۆفێشناڵ کاربکات
    }

    private func addCertificate() {
        guard let p12URL, let provisionURL else { return }
        isImporting = true
        errorMessage = nil

        Task {
            do {
                _ = try await CertificateStore.shared.addCertificate(
                    name: name,
                    p12SourceURL: p12URL,
                    provisionSourceURL: provisionURL,
                    password: password
                )
                await MainActor.run { dismiss() }
            } catch {
                await MainActor.run {
                    isImporting = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
