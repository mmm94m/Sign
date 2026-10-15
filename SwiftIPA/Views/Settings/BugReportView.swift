import SwiftUI
import UIKit

/// Builds a prefilled report and opens Telegram, so reporting
/// a bug is one tap after writing it down.
struct BugReportView: View {
    static let telegramURL = URL(string: "https://t.me/ashtemobile")!

    enum Kind: String, CaseIterable, Identifiable {
        case bug
        case feature
        case question

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .bug: return String(localized: "Bug")
            case .feature: return String(localized: "Feature Request")
            case .question: return String(localized: "Question")
            }
        }

        // زیادکردنی ئیمۆجی بۆ ئەوەی لە تێلیگرام جوانتر دەربکەوێت
        var titlePrefix: String {
            switch self {
            case .bug: return "🐛 Bug:"
            case .feature: return "✨ Feature:"
            case .question: return "❓ Question:"
            }
        }
    }

    @State private var kind: Kind = .bug
    @State private var title = ""
    @State private var details = ""
    @State private var steps = ""
    @State private var includeDeviceInfo = true
    @Environment(\.openURL) private var openURL

    var body: some View {
        Form {
            Section {
                Picker("Type", selection: $kind) {
                    ForEach(Kind.allCases) { kind in
                        Text(kind.displayName).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            Section {
                TextField("Short summary", text: $title)
                ZStack(alignment: .topLeading) {
                    if details.isEmpty {
                        Text(kind == .feature ? LocalizedStringKey("What would you like SwiftIPA to do?") : LocalizedStringKey("What happened, and what did you expect?"))
                            .foregroundStyle(SIColor.textSecondary)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $details)
                        .frame(minHeight: 110)
                        .scrollContentBackground(.hidden)
                }
            } header: {
                Text("Report")
            }

            if kind == .bug {
                Section {
                    ZStack(alignment: .topLeading) {
                        if steps.isEmpty {
                            Text("1. Open …\n2. Tap …\n3. …")
                                .foregroundStyle(SIColor.textSecondary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $steps)
                            .frame(minHeight: 80)
                            .scrollContentBackground(.hidden)
                    }
                } header: {
                    Text("Steps to Reproduce")
                }
            }

            Section {
                Toggle("Include Device Info", isOn: $includeDeviceInfo)
                    .tint(SIColor.accent)
                if includeDeviceInfo {
                    Text(Self.deviceInfo)
                        .font(SIFont.mono)
                        .foregroundStyle(SIColor.textSecondary)
                        .textSelection(.enabled)
                }
            } footer: {
                Text("Only what's shown here is added to your report.")
            }

            Section {
                Button {
                    // ١. کۆپیکردنی ڕاپۆرتەکە بۆ کلیپبۆردی مۆبایلەکە
                    UIPasteboard.general.string = generatedReport
                    
                    // ٢. کردنەوەی چەناڵی تێلیگرام
                    openURL(Self.telegramURL)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "paperplane.fill")
                        Text("Copy & Send via Telegram")
                            .fontWeight(.medium)
                    }
                    // گۆڕینی ڕەنگ بۆ شینی تێلیگرام ئەگەر فۆڕمەکە پڕکرابێتەوە
                    .foregroundColor(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : Color(red: 0.16, green: 0.58, blue: 0.94))
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                
            } footer: {
                Text("This will copy your report to the clipboard and open Telegram so you can paste it directly into the support chat.")
            }
        }
        .siScreen()
        .navigationTitle("Bugs & Issues")
        .navigationBarTitleDisplayMode(.inline)
    }

    // ئامادەکردنی دەقی ڕاپۆرتەکە بۆ ئەوەی لە تێلیگرام بە جوانی دەربکەوێت
    private var generatedReport: String {
        var body = "\(kind.titlePrefix) \(title.trimmingCharacters(in: .whitespacesAndNewlines))\n\n"
        
        let trimmedDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)
        body += "📝 Description:\n\(trimmedDetails.isEmpty ? "No description provided." : trimmedDetails)\n\n"
        
        let trimmedSteps = steps.trimmingCharacters(in: .whitespacesAndNewlines)
        if kind == .bug, !trimmedSteps.isEmpty {
            body += "🔄 Steps to reproduce:\n\(trimmedSteps)\n\n"
        }
        
        if includeDeviceInfo {
            body += "📱 Device Info:\n\(Self.deviceInfo)\n"
        }
        
        return body
    }

    static var deviceInfo: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        let device = UIDevice.current
        return [
            "SwiftIPA: \(version) (\(build))",
            "iOS: \(device.systemVersion)",
            "Device: \(modelIdentifier)",
            "Language: \(Locale.preferredLanguages.first ?? "?")",
            "Certificates: \(CertificateStore.shared.certificates.count)",
            "Tweaks: \(DylibLibraryStore.shared.dylibs.count)"
        ].joined(separator: "\n")
    }

    private static var modelIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let identifier = withUnsafeBytes(of: &systemInfo.machine) { buffer in
            String(decoding: buffer.prefix { $0 != 0 }, as: UTF8.self)
        }
        return identifier.isEmpty ? UIDevice.current.model : identifier
    }
}
