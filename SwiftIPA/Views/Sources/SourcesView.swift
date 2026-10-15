import SwiftUI
import UIKit

struct SourcesView: View {
    @ObservedObject private var sourceStore = SourceStore.shared
    @State private var showingAddSheet = false
    @State private var isAutoLoading = false

    // بەستەری تایبەت بە پڕۆژەکەت
    let defaultSourceURL = URL(string: "https://github.com/ios94/ashtejson/raw/refs/heads/main/ashtemobile94.json")!

    var body: some View {
        Group {
            // ١. ئەگەر سۆرسەکە هەبوو، یەکسەر بەرنامەکان نیشان بدە!
            if let firstSource = sourceStore.sources.first {
                SourceDetailView(sourceID: firstSource.id)
            } else {
                // ٢. ئەگەر سۆرسەکە نەبوو یان خەریکی لۆدکردن بوو
                if isAutoLoading {
                    loadingState
                } else {
                    emptyState
                }
            }
        }
        .siScreen()
        // لابردنی تایتڵی Sources کاتێک دەچێتە ناو بەرنامەکان
        .navigationTitle(sourceStore.sources.isEmpty ? "Sources" : "")
        .toolbar {
            // تەنها کاتێک سۆرس نییە دوگمەی (+) نیشان بدە
            if sourceStore.sources.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.orange)
                    }
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

    // MARK: - Loading View
    private var loadingState: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.orange) // ڕەنگی لۆدینگی پرتەقاڵی
            
            Text("Loading AshteMobile Apps...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State View
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
