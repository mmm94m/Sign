import SwiftUI

struct AddSourceSheet: View {
    @State private var urlText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("https://example.com/repo.json", text: $urlText)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.go) // کیبۆردەکە دوگمەی Go نیشان دەدات
                        .disabled(isLoading)
                        .onSubmit {
                            // کاتێک لە کیبۆردەکە Go دادەگریت، ڕاستەوخۆ هەوڵی زیادکردن دەدات
                            if canAdd { add() }
                        }
                } header: {
                    Text("REPOSITORY URL")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                } footer: {
                    Text("Works with AltStore and ESign-format sources.")
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(SIColor.danger)
                            .font(.caption)
                    }
                }
            }
            .formStyle(.grouped) // ستایلی فەرمی و مۆدێرنی فۆڕم
            .siScreen()
            .presentationDragIndicator(.visible)
            .navigationTitle("Add Source")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(SIColor.accent) // ڕەنگی تایبەتی پڕۆژەکەت (پرتەقاڵی)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        add()
                    } label: {
                        if isLoading { 
                            ProgressView() 
                        } else { 
                            Text("Add")
                                .fontWeight(.semibold) 
                        }
                    }
                    .disabled(!canAdd || isLoading)
                    .foregroundColor(canAdd ? SIColor.accent : .gray) // کاتێک لینکەکە دروستە ڕەنگەکەی دەگەشێتەوە
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // پشکنین بۆ ئەوەی بزانین لینکەکە نوسراوە و دروستە
    private var canAdd: Bool {
        URL(string: urlText) != nil && !urlText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func add() {
        guard let url = URL(string: urlText) else { return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                _ = try await SourceStore.shared.addSource(url: url)
                await MainActor.run { dismiss() }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
