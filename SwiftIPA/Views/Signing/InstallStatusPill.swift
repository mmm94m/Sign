import SwiftUI

struct InstallStatusPill: View {
    let entryID: UUID
    let onClose: () -> Void

    @State private var status: InstallStatus = .preparing
    @State private var backgroundLoadURL: URL?

    var body: some View {
        HStack(spacing: 16) {
            icon
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(4)
                }
                if case .sendingPayload(let fraction) = status {
                    ProgressView(value: fraction)
                        .tint(.orange) // ڕەنگی مۆدێرنی پرتەقاڵی
                }
            }

            Spacer(minLength: 0)

            Button {
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(8)
                    .background(Color(UIColor.tertiarySystemFill))
                    .clipShape(Circle())
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 5)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .animation(.easeOut(duration: 0.25), value: status)
        .background {
            if let backgroundLoadURL {
                HiddenInstallWebView(url: backgroundLoadURL)
                    .frame(width: 1, height: 1)
                    .opacity(0.01)
                    .allowsHitTesting(false)
            }
        }
        .task { await start() }
        .onChange(of: status) { newStatus in
            guard newStatus == .installing else { return }
            Task {
                try? await Task.sleep(nanoseconds: 6_000_000_000)
                onClose()
            }
        }
        .onDisappear {
            InstallServer.shared.onStatus = nil
            InstallServer.shared.stop()
        }
    }

    @ViewBuilder
    private var icon: some View {
        switch status {
        case .preparing, .waitingForSystem:
            ProgressView()
                .tint(.orange)
        case .sendingPayload:
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(.orange)
        case .installing:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(.green)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundColor(.red)
        }
    }

    private var title: String {
        switch status {
        case .preparing:
            return String(localized: "Preparing install…")
        case .waitingForSystem:
            return String(localized: "Waiting for iOS…")
        case .sendingPayload(let fraction):
            return String(localized: "Sending payload…") + " \(Int(fraction * 100)) %"
        case .installing:
            return String(localized: "Installing…")
        case .failed:
            return String(localized: "Install failed")
        }
    }

    private var detail: String? {
        switch status {
        case .preparing:
            return nil
        case .waitingForSystem:
            return String(localized: "Confirm the install prompt from iOS.")
        case .sendingPayload:
            return String(localized: "Keep SwiftIPA open until the transfer finishes.")
        case .installing:
            return String(localized: "Watch your Home Screen, the app appears there in a moment.")
        case .failed(let message):
            return message
        }
    }

    @MainActor
    private func start() async {
        guard let entry = AppLibraryStore.shared.apps.first(where: { $0.id == entryID }) else {
            onClose()
            return
        }
        guard entry.bundleIdentifier != Bundle.main.bundleIdentifier else {
            status = .failed(String(localized: "SwiftIPA can't install over itself, iOS closes it mid-transfer. Use Export IPA and install it with another signer."))
            return
        }
        InstallServer.shared.onStatus = { newStatus in
            status = newStatus
        }
        status = .preparing
        do {
            let link = try await InstallServer.shared.startInstall(
                ipaURL: AppLibraryStore.shared.ipaURL(for: entry),
                appName: entry.name,
                bundleIdentifier: entry.bundleIdentifier,
                version: entry.displayVersion,
                mode: .externalManifest
            )
            status = .waitingForSystem
            switch link.presentationStyle {
            case .direct:
                _ = await UIApplication.shared.open(link.url)
            case .webView:
                backgroundLoadURL = link.url
            }
        } catch {
            status = .failed(error.localizedDescription)
        }
    }
}
