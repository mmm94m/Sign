import SwiftUI

struct ChangelogView: View {
    // خوێندنەوەی ڤێرژنی ئەپەکە بە شێوەیەکی ئۆتۆماتیکی (یان دەتوانیت خۆت بینووسیت وەک "2.0.0")
    private var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        List {
            // MARK: - Header Section (Logo & Info)
            Section {
                VStack(spacing: 16) {
                    AsyncImage(url: URL(string: "https://ashtemobile.site/a.png")) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 100, height: 100)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        case .failure:
                            // ئەگەر ئینتەرنێت کێشەی هەبوو ئەمە نیشان دەدات
                            Image(systemName: "apple.logo")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                                .frame(width: 100, height: 100)
                                .background(Color.orange.gradient)
                                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .padding(.top, 10)
                    
                    VStack(spacing: 4) {
                        Text("AshteMobile")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Version \(versionString)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .padding(.bottom, 10)
            }
            
            // MARK: - Social Media Links
            Section {
                // Telegram
                Link(destination: URL(string: "https://t.me/ashtemobile")!) {
                    SocialMediaRow(
                        icon: "paperplane.fill",
                        bgColor: Color(red: 0.16, green: 0.58, blue: 0.94),
                        title: "Telegram Channel",
                        subtitle: "@ashtemobile"
                    )
                }
                
                // Instagram
                Link(destination: URL(string: "https://www.instagram.com/ashtemobile")!) {
                    SocialMediaRow(
                        icon: "camera.fill",
                        bgColor: Color.pink,
                        title: "Instagram",
                        subtitle: "@ashtemobile"
                    )
                }
                
                // TikTok
                Link(destination: URL(string: "https://www.tiktok.com/@ashtemobile")!) {
                    SocialMediaRow(
                        icon: "play.tv.fill", // ئایکۆنێکی گونجاو بۆ تیکتۆک
                        bgColor: Color.black,
                        title: "TikTok",
                        subtitle: "@ashtemobile"
                    )
                }
            } header: {
                Text("Follow Us")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            } footer: {
                Text("Join our community for the latest updates, tweaks, and certificates.")
                    .padding(.top, 8)
            }
        }
        .listStyle(.insetGrouped)
        .siScreen()
        .navigationTitle("About AshteMobile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Reusable Social Media Row Component
private struct SocialMediaRow: View {
    let icon: String
    let bgColor: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(bgColor.gradient)
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "arrow.up.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
