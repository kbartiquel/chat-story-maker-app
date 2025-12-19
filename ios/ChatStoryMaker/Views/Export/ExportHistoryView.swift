//
//  ExportHistoryView.swift
//  ChatStoryMaker
//
//  View to display export history
//

import SwiftUI
import SwiftData
import AVKit

struct ExportHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExportHistory.exportDate, order: .reverse) private var history: [ExportHistory]

    @State private var selectedVideo: URL?
    @State private var showVideoPlayer = false
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []

    var body: some View {
        NavigationStack {
            Group {
                if history.isEmpty {
                    emptyState
                } else {
                    historyList
                }
            }
            .navigationTitle("Export History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                if !history.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Clear All", role: .destructive) {
                            clearAllHistory()
                        }
                    }
                }
            }
            .sheet(isPresented: $showVideoPlayer) {
                if let url = selectedVideo {
                    VideoPlayerView(url: url)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: shareItems)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No Export History")
                .font(.title2.bold())
            Text("Your exported videos will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    private var historyList: some View {
        List {
            ForEach(history) { item in
                ExportHistoryRow(item: item) {
                    playVideo(item)
                } onShare: {
                    shareVideo(item)
                }
            }
            .onDelete(perform: deleteItems)
        }
        .listStyle(.plain)
    }

    private func playVideo(_ item: ExportHistory) {
        if let localPath = item.localPath {
            let url = URL(fileURLWithPath: localPath)
            if FileManager.default.fileExists(atPath: localPath) {
                selectedVideo = url
                showVideoPlayer = true
                return
            }
        }

        if let videoURLString = item.videoURL,
           let url = URL(string: videoURLString) {
            selectedVideo = url
            showVideoPlayer = true
        }
    }

    private func shareVideo(_ item: ExportHistory) {
        if let localPath = item.localPath {
            let url = URL(fileURLWithPath: localPath)
            if FileManager.default.fileExists(atPath: localPath) {
                shareItems = [url]
                showShareSheet = true
                return
            }
        }

        if let videoURLString = item.videoURL,
           let url = URL(string: videoURLString) {
            shareItems = [url]
            showShareSheet = true
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = history[index]
            // Delete local file if exists
            if let localPath = item.localPath {
                try? FileManager.default.removeItem(atPath: localPath)
            }
            modelContext.delete(item)
        }
    }

    private func clearAllHistory() {
        for item in history {
            if let localPath = item.localPath {
                try? FileManager.default.removeItem(atPath: localPath)
            }
            modelContext.delete(item)
        }
    }
}

struct ExportHistoryRow: View {
    let item: ExportHistory
    let onPlay: () -> Void
    let onShare: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            thumbnailView
                .frame(width: 60, height: 80)
                .cornerRadius(8)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.conversationTitle)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Label(item.exportTypeEnum.displayName, systemImage: item.exportTypeEnum.icon)
                    Text("•")
                    Text(item.formatEnum.displayName)
                }
                .font(.caption)
                .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    Image(systemName: item.renderModeEnum == .server ? "cloud" : "iphone")
                    Text(item.formattedDate)
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }

            Spacer()

            // Actions
            VStack(spacing: 8) {
                Button(action: onPlay) {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }

                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if let data = item.thumbnailData,
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            ZStack {
                Rectangle()
                    .fill(Color(.systemGray5))
                Image(systemName: item.exportTypeEnum == .video ? "video.fill" : "photo.fill")
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct VideoPlayerView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VideoPlayer(player: AVPlayer(url: url))
                .ignoresSafeArea()
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

// MARK: - Tab Version (no dismiss button)

struct ExportHistoryTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExportHistory.exportDate, order: .reverse) private var history: [ExportHistory]

    @State private var selectedVideo: URL?
    @State private var showVideoPlayer = false
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []

    var body: some View {
        NavigationStack {
            Group {
                if history.isEmpty {
                    emptyState
                } else {
                    historyList
                }
            }
            .navigationTitle("Exports")
            .toolbar {
                if !history.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button("Clear All", role: .destructive) {
                                clearAllHistory()
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showVideoPlayer) {
                if let url = selectedVideo {
                    VideoPlayerView(url: url)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: shareItems)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.and.arrow.up.on.square")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No Exports Yet")
                .font(.title2.bold())
            Text("Your exported videos will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var historyList: some View {
        List {
            ForEach(history) { item in
                ExportHistoryRow(item: item) {
                    playVideo(item)
                } onShare: {
                    shareVideo(item)
                }
            }
            .onDelete(perform: deleteItems)
        }
        .listStyle(.plain)
    }

    private func playVideo(_ item: ExportHistory) {
        if let localPath = item.localPath {
            let url = URL(fileURLWithPath: localPath)
            if FileManager.default.fileExists(atPath: localPath) {
                selectedVideo = url
                showVideoPlayer = true
                return
            }
        }

        if let videoURLString = item.videoURL,
           let url = URL(string: videoURLString) {
            selectedVideo = url
            showVideoPlayer = true
        }
    }

    private func shareVideo(_ item: ExportHistory) {
        if let localPath = item.localPath {
            let url = URL(fileURLWithPath: localPath)
            if FileManager.default.fileExists(atPath: localPath) {
                shareItems = [url]
                showShareSheet = true
                return
            }
        }

        if let videoURLString = item.videoURL,
           let url = URL(string: videoURLString) {
            shareItems = [url]
            showShareSheet = true
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = history[index]
            if let localPath = item.localPath {
                try? FileManager.default.removeItem(atPath: localPath)
            }
            modelContext.delete(item)
        }
    }

    private func clearAllHistory() {
        for item in history {
            if let localPath = item.localPath {
                try? FileManager.default.removeItem(atPath: localPath)
            }
            modelContext.delete(item)
        }
    }
}

#Preview {
    ExportHistoryTabView()
}
