import SwiftUI

struct CertificatesView: View {
    @ObservedObject private var certificateStore = CertificateStore.shared
    @State private var showingAddSheet = false

    var body: some View {
        Group {
            if certificateStore.certificates.isEmpty {
                emptyState
            } else {
                certificateList
            }
        }
        .siScreen()
        .navigationTitle("Certificates")
        .navigationDestination(for: SigningCertificate.self) { certificate in
            CertificateDetailView(certificateID: certificate.id)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(.orange)
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddCertificateSheet()
        }
    }

    private var certificateList: some View {
        List {
            ForEach(certificateStore.certificates) { certificate in
                NavigationLink(value: certificate) {
                    CertificateRow(certificate: certificate, isDefault: certificate.id == certificateStore.defaultCertificateID)
                }
                .buttonStyle(.siPressableCard)
            }
            .onDelete { offsets in
                for index in offsets { certificateStore.removeCertificate(certificateStore.certificates[index]) }
            }
            .listRowInsets(EdgeInsets(top: SISpacing.xs, leading: SISpacing.md, bottom: SISpacing.xs, trailing: SISpacing.md))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
    }

    // دیزاینی مۆدێرن بۆ کاتی نەبوونی هیچ بڕوانامەیەک
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(.secondary)
                .padding(.bottom, 8)

            Text("No certificates yet")
                .font(.title2)
                .fontWeight(.bold)

            Text("Import a .p12 and its matching .mobileprovision to start signing.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                showingAddSheet = true
            } label: {
                Text("Add Certificate")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 40)
            .padding(.top, 16)
        }
    }
}

struct CertificateRow: View {
    let certificate: SigningCertificate
    let isDefault: Bool

    var body: some View {
        HStack(spacing: SISpacing.md) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title2)
                .foregroundStyle(Color.orange) // گۆڕینی ڕەنگی ئایکۆن بۆ پرتەقاڵی
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(certificate.name).font(SIFont.headline)
                    if isDefault {
                        StatusBadge(text: String(localized: "Default"), color: .orange)
                    }
                }
                Text(certificate.displayExpiry).font(SIFont.caption).foregroundStyle(SIColor.textSecondary)
            }
            Spacer()
            CertificateHealthBadge(health: certificate.health)
        }
        .padding(SISpacing.sm + 4)
        .siCard()
    }
}
