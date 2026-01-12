//
//  ExportViewModel.swift
//  Textory
//
//  ViewModel for export settings and video/image generation
//

import SwiftUI
import UIKit
import AVFoundation

@Observable
class ExportViewModel {
    var conversation: Conversation
    var settings = ExportSettings()
    var isExporting = false
    var exportProgress: Double = 0
    var exportedVideoURL: URL?
    var exportedImage: UIImage?
    var exportedImages: [UIImage] = []  // For multi-page screenshots
    var showShareSheet = false
    var errorMessage: String?
    var showPaywall = false

    // Export history record to be saved after successful export
    var lastExportHistory: ExportHistory?

    private let videoExportService = VideoExportService()
    private let serverExportService = ServerExportService()
    private let imageExportService = ImageExportService()

    init(conversation: Conversation) {
        self.conversation = conversation
    }

    // MARK: - Limits

    var hasReachedVideoExportLimit: Bool {
        LimitTrackingService.shared.hasReachedVideoExportLimit()
    }

    var remainingVideoExports: Int {
        LimitTrackingService.shared.getRemainingVideoExports()
    }

    var isPremium: Bool {
        SubscriptionService.shared.hasPremiumAccess()
    }

    /// Create export history record after successful export
    func createExportHistory(videoURL: URL? = nil, localPath: String? = nil, jobId: String? = nil) -> ExportHistory {
        // Generate thumbnail from first frame or video
        var thumbnailData: Data?
        if let url = videoURL ?? exportedVideoURL {
            thumbnailData = generateThumbnail(from: url)
        } else if let image = exportedImage {
            thumbnailData = image.jpegData(compressionQuality: 0.5)
        }

        return ExportHistory(
            conversationTitle: conversation.title,
            exportType: settings.exportType,
            renderMode: settings.renderMode,
            format: settings.format,
            videoURL: videoURL?.absoluteString,
            localPath: localPath ?? exportedVideoURL?.path,
            thumbnailData: thumbnailData,
            duration: nil,
            messageCount: conversation.messages.count,
            jobId: jobId
        )
    }

    private func generateThumbnail(from url: URL) -> Data? {
        // For local files, generate thumbnail from video
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }

        let asset = AVURLAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true

        do {
            let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
            let uiImage = UIImage(cgImage: cgImage)
            return uiImage.jpegData(compressionQuality: 0.5)
        } catch {
            return nil
        }
    }

    var canExport: Bool {
        !conversation.messages.isEmpty && !isExporting
    }

    var shareItems: [Any] {
        if let url = exportedVideoURL {
            return [url]
        } else if !exportedImages.isEmpty {
            // Share all images (for multi-page screenshots)
            return exportedImages
        } else if let image = exportedImage {
            return [image]
        }
        return []
    }

    func export() async {
        switch settings.exportType {
        case .video:
            await exportVideo()
        case .screenshot:
            await exportScreenshot()
        }
    }

    // Called from button after isExporting is already set
    func startExport() async {
        errorMessage = nil
        switch settings.exportType {
        case .video:
            await performVideoExport()
        case .screenshot:
            await performScreenshotExport()
        }
    }

    func exportVideo() async {
        guard canExport else { return }

        // Check limits first (only for video exports)
        if hasReachedVideoExportLimit {
            await MainActor.run {
                showPaywall = true
            }
            return
        }

        // Update UI state on main actor first
        await MainActor.run {
            isExporting = true
            exportProgress = 0
            errorMessage = nil
        }

        AnalyticsService.shared.trackExportStarted(
            format: "video",
            aspectRatio: settings.format.rawValue,
            isDarkMode: settings.darkMode
        )

        await performVideoExport()
    }

    private func performVideoExport() async {
        // Convert SwiftData objects to simple structs ON MAIN THREAD (quick)
        let exportMessages = conversation.sortedMessages.map { msg in
            VideoExportService.ExportMessage(
                id: msg.id,
                text: msg.text,
                characterID: msg.characterID
            )
        }

        let exportCharacters = conversation.characters.map { char in
            VideoExportService.ExportCharacter(
                id: char.id,
                name: char.name,
                isMe: char.isMe,
                colorHex: char.colorHex,
                avatarEmoji: char.avatarEmoji,
                avatarImageData: char.avatarImageData
            )
        }

        let theme = conversation.theme
        let exportSettings = settings
        let title = conversation.title
        let isGroup = conversation.isGroupChat

        // Create config with plain data (thread-safe)
        let config = VideoExportService.ExportConfig(
            messages: exportMessages,
            characters: exportCharacters,
            theme: theme,
            settings: exportSettings,
            conversationTitle: title,
            isGroupChat: isGroup
        )

        // Capture weak self for progress updates
        weak var weakSelf = self

        // Choose render mode based on settings
        if settings.renderMode == .server {
            // SERVER RENDERING
            await performServerExport(config: config, weakSelf: weakSelf)
        } else {
            // DEVICE RENDERING (original implementation)
            await performDeviceExport(config: config, weakSelf: weakSelf)
        }
    }

    private func performDeviceExport(config: VideoExportService.ExportConfig, weakSelf: ExportViewModel?) async {
        let service = videoExportService

        // Use Task.detached to run export on background thread pool
        // This allows Task.yield() in the export loop to actually yield
        do {
            let url = try await Task.detached(priority: .userInitiated) { [service, config] in
                try await service.exportVideo(config: config) { progress in
                    // Update progress on main actor
                    Task { @MainActor in
                        weakSelf?.exportProgress = progress
                    }
                }
            }.value

            // Back on main actor - update UI
            exportedVideoURL = url
            exportedImage = nil
            isExporting = false
            showShareSheet = true
            lastExportHistory = createExportHistory(localPath: url.path)
            HapticManager.notification(.success)
            LimitTrackingService.shared.recordVideoExport()
            AnalyticsService.shared.trackExportCompleted(format: "video", durationSeconds: 0)
        } catch {
            errorMessage = error.localizedDescription
            isExporting = false
            HapticManager.notification(.error)
            AnalyticsService.shared.trackExportFailed(format: "video", error: error.localizedDescription)
        }
    }

    private func performServerExport(config: VideoExportService.ExportConfig, weakSelf: ExportViewModel?) async {
        let service = serverExportService

        do {
            let url = try await service.exportVideo(config: config) { progress in
                // Update progress on main actor
                Task { @MainActor in
                    weakSelf?.exportProgress = progress
                }
            }

            // Back on main actor - update UI
            await MainActor.run {
                self.exportedVideoURL = url
                self.exportedImage = nil
                self.isExporting = false
                self.showShareSheet = true
                self.lastExportHistory = self.createExportHistory(videoURL: url, localPath: url.path)
                HapticManager.notification(.success)
                LimitTrackingService.shared.recordVideoExport()
                AnalyticsService.shared.trackExportCompleted(format: "video", durationSeconds: 0)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isExporting = false
                HapticManager.notification(.error)
                AnalyticsService.shared.trackExportFailed(format: "video", error: error.localizedDescription)
            }
        }
    }

    func exportScreenshot() async {
        guard canExport else { return }

        await MainActor.run {
            isExporting = true
            exportProgress = 0
            errorMessage = nil
        }

        AnalyticsService.shared.trackExportStarted(
            format: "screenshot",
            aspectRatio: settings.format.rawValue,
            isDarkMode: settings.darkMode
        )

        await performScreenshotExport()
    }

    private func performScreenshotExport() async {
        // Use server-side rendering for consistent look with video exports
        let exportMessages = conversation.sortedMessages.map { msg in
            VideoExportService.ExportMessage(
                id: msg.id,
                text: msg.text,
                characterID: msg.characterID
            )
        }

        let exportCharacters = conversation.characters.map { char in
            VideoExportService.ExportCharacter(
                id: char.id,
                name: char.name,
                isMe: char.isMe,
                colorHex: char.colorHex,
                avatarEmoji: char.avatarEmoji,
                avatarImageData: char.avatarImageData
            )
        }

        let config = VideoExportService.ExportConfig(
            messages: exportMessages,
            characters: exportCharacters,
            theme: conversation.theme,
            settings: settings,
            conversationTitle: conversation.title,
            isGroupChat: conversation.isGroupChat
        )

        do {
            let images = try await serverExportService.exportScreenshot(
                config: config,
                mode: settings.screenshotMode
            )

            // Save images to disk for export history
            let savedPaths = saveScreenshotsToDocuments(images: images)

            await MainActor.run {
                self.exportedImages = images
                self.exportedImage = images.first  // For backward compatibility
                self.exportedVideoURL = nil
                self.isExporting = false
                self.showShareSheet = true

                // Create export history with first image as thumbnail
                if let firstPath = savedPaths.first {
                    self.lastExportHistory = createScreenshotExportHistory(
                        localPath: firstPath,
                        thumbnailImage: images.first,
                        pageCount: images.count
                    )
                }

                HapticManager.notification(.success)
                AnalyticsService.shared.trackExportCompleted(format: "screenshot", durationSeconds: 0)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isExporting = false
                HapticManager.notification(.error)
                AnalyticsService.shared.trackExportFailed(format: "screenshot", error: error.localizedDescription)
            }
        }
    }

    /// Save screenshots to documents directory
    private func saveScreenshotsToDocuments(images: [UIImage]) -> [String] {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let screenshotsFolder = documentsPath.appendingPathComponent("Screenshots")

        // Create folder if needed
        try? fileManager.createDirectory(at: screenshotsFolder, withIntermediateDirectories: true)

        let timestamp = Int(Date().timeIntervalSince1970)
        var savedPaths: [String] = []

        for (index, image) in images.enumerated() {
            let filename = "\(conversation.title.prefix(20))_\(timestamp)_\(index + 1).png"
            let filePath = screenshotsFolder.appendingPathComponent(filename)

            if let data = image.pngData() {
                try? data.write(to: filePath)
                savedPaths.append(filePath.path)
            }
        }

        return savedPaths
    }

    /// Create export history for screenshot
    private func createScreenshotExportHistory(localPath: String, thumbnailImage: UIImage?, pageCount: Int) -> ExportHistory {
        var thumbnailData: Data?
        if let image = thumbnailImage {
            // Create smaller thumbnail
            let size = CGSize(width: 200, height: 200 * 16 / 9)
            UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: size))
            let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            thumbnailData = thumbnail?.jpegData(compressionQuality: 0.6)
        }

        return ExportHistory(
            conversationTitle: conversation.title,
            exportType: settings.exportType,
            renderMode: settings.renderMode,
            format: settings.format,
            localPath: localPath,
            thumbnailData: thumbnailData,
            duration: Double(pageCount),  // Use duration field to store page count
            messageCount: conversation.messages.count
        )
    }
}
