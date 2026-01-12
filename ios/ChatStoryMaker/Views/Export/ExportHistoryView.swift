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
                ExportHistoryRow(item: item)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        playVideo(item)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            deleteItem(item)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Button {
                            shareVideo(item)
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .tint(.blue)
                    }
            }
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

    private func deleteItem(_ item: ExportHistory) {
        if let localPath = item.localPath {
            try? FileManager.default.removeItem(atPath: localPath)
        }
        modelContext.delete(item)
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

// MARK: - Export History Row (Clean, no buttons)

struct ExportHistoryRow: View {
    let item: ExportHistory

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail with play overlay
            ZStack {
                thumbnailView
                    .frame(width: 60, height: 80)
                    .cornerRadius(8)

                // Play icon overlay
                if item.exportTypeEnum == .video {
                    Image(systemName: "play.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.conversationTitle)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(item.formatEnum.displayName)
                    Text("•")
                    Text("\(item.messageCount) messages")
                }
                .font(.caption)
                .foregroundColor(.secondary)

                Text(item.formattedDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Chevron indicator
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
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

// MARK: - Full Screen Video Player

struct FullScreenVideoPlayer: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            }

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.8))
                            .padding()
                    }
                }
                Spacer()
            }
        }
        .onAppear {
            player = AVPlayer(url: url)
            player?.play()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
}

// Keep the old VideoPlayerView for compatibility
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
                ExportHistoryRow(item: item)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        playVideo(item)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            deleteItem(item)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Button {
                            shareVideo(item)
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .tint(.blue)
                    }
            }
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

    private func deleteItem(_ item: ExportHistory) {
        if let localPath = item.localPath {
            try? FileManager.default.removeItem(atPath: localPath)
        }
        modelContext.delete(item)
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
