import SwiftUI
import UIKit // ئەمە زیادکرا بۆ چارەسەری ئیرۆری ڕەنگەکان

struct SourcesView: View {
    @ObservedObject private var sourceStore = SourceStore.shared
    @State private var showingAddSheet = false
    @State private var isAutoLoading = false // بۆ نیشاندانی لۆدینگی ئۆتۆماتیکی

    // بەستەری تایبەت بە پڕۆژەکەت
    let defaultSourceURL = URL(string: "https://github.com/ios94/ashtejson/raw/refs/heads/main/ashtemobile94.json")!

    var body: some View {
        Group {
            if sourceStore.sources.isEmpty {
                if isAutoLoading {
                    loadingState
                } else {
                    emptyState
                }
            } else {
                sourceList
            }
        }
        .siScreen()
        .navigationTitle("Sources")
        .navigationDestination(for: RepositorySource.self) { source in
            SourceDetailView(sourceID: source.id)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(.orange) // ڕەنگی مۆدێرنی پرتەقاڵی
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddSourceSheet()
        }
        .onAppear {
            autoLoadDefaultSource()
        }
    }

    // MARK: - Auto Load Logic
    private func autoLoadDefaultSource() {
        // ئەگەر سۆرسەکان بەتاڵ بوون، با ڕاستەوخۆ سۆرسەکەی تۆ ئاد بکات
        guard sourceStore.sources.isEmpty else { return }
        
        isAutoLoading = true
        Task {
            do {
                _ = try await sourceStore.addSource(url: defaultSourceURL)
                await MainActor.run {
                    isAutoLoading = false
                }
            } catch {
                await MainActor.run {
                    isAutoLoading = false
                    print("Failed to auto-load source: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Views
    private var sourceList: some View {
        List {
            ForEach(sourceStore.sources) { source in
                NavigationLink(value: source) {
                    SourceRow(source: source)
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .onDelete { offsets in
                for index in offsets { 
                    sourceStore.removeSource(sourceStore.sources[index]) 
                }
            }
        }
        .listStyle(.plain)
        .padding(.top, 8)
    }

    // دیزاینی کاتی لۆدکردنی ئۆتۆماتیکی
    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading AshteMobile Apps...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // دیزاینی مۆدێرن بۆ کاتی بەتاڵی (ئەگەر ئینتەرنێت نەبوو یان سڕییەوە)
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
                .padding(.bottom, 8)

            Text("No sources yet")
                .font(.title2)
                .fontWeight(.bold)

            Text("Add an AltStore or ESign-compatible repo URL to browse and sign apps straight from it.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                showingAddSheet = true
            } label: {
                Text("Add Source")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SourceRow: View {
    let source: RepositorySource

    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: source.iconURL) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 50, height: 50)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                case .failure:
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemFill)) // ئێرۆرەکە لێرەدا چارەسەرکرا
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "tray.fill")
                                .foregroundColor(.gray)
                        )
                @unknown default:
                    EmptyView()
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(source.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(source.subtitle ?? source.url.host ?? "Unknown")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // نیشاندانی ژمارەی ئەپەکان بە شێوازێکی جوان
            Text("\(source.appCount) Apps")
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.orange.opacity(0.15))
                .foregroundColor(.orange)
                .clipShape(Capsule())
        }
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground)) // ئێرۆرەکە لێرەدا چارەسەرکرا
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
