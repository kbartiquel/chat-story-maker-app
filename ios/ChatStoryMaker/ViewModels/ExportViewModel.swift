//
//  ExportViewModel.swift
//  ChatStoryMaker
//
//  ViewModel for export settings and video/image generation
//

import SwiftUI
import UIKit

@Observable
class ExportViewModel {
    var conversation: Conversation
    var settings = ExportSettings()
    var isExporting = false
    var exportProgress: Double = 0
    var exportedVideoURL: URL?
    var exportedImage: UIImage?
    var showShareSheet = false
    var errorMessage: String?

    private let videoExportService = VideoExportService()
    private let imageExportService = ImageExportService()

    init(conversation: Conversation) {
        self.conversation = conversation
    }

    var canExport: Bool {
        !conversation.messages.isEmpty && !isExporting
    }

    var shareItems: [Any] {
        if let url = exportedVideoURL {
            return [url]
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

        // Update UI state on main actor first
        await MainActor.run {
            isExporting = true
            exportProgress = 0
            errorMessage = nil
        }

        await performVideoExport()
    }

    private func performVideoExport() async {

        // Prepare config with copies of data to avoid main actor access during export
        let messages = conversation.sortedMessages
        let characters = conversation.characters
        let theme = conversation.theme
        let exportSettings = settings
        let title = conversation.title
        let isGroup = conversation.isGroupChat

        let config = VideoExportService.ExportConfig(
            messages: messages,
            characters: characters,
            theme: theme,
            settings: exportSettings,
            conversationTitle: title,
            isGroupChat: isGroup,
            getCharacter: { id in
                characters.first { $0.id == id }
            }
        )

        // Capture self weakly for progress updates
        let updateProgress: @Sendable (Double) -> Void = { [weak self] progress in
            Task { @MainActor in
                self?.exportProgress = progress
            }
        }

        // Run heavy export work on background thread
        do {
            let service = videoExportService
            let url = try await Task.detached(priority: .userInitiated) {
                try await service.exportVideo(config: config, progress: updateProgress)
            }.value

            await MainActor.run {
                self.exportedVideoURL = url
                self.exportedImage = nil
                self.isExporting = false
                self.showShareSheet = true
                HapticManager.notification(.success)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isExporting = false
                HapticManager.notification(.error)
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

        await performScreenshotExport()
    }

    private func performScreenshotExport() async {
        let config = ImageExportService.ExportConfig(
            messages: conversation.sortedMessages,
            characters: conversation.characters,
            theme: conversation.theme,
            settings: settings,
            conversationTitle: conversation.title,
            isGroupChat: conversation.isGroupChat,
            getCharacter: { [weak self] id in
                self?.conversation.characters.first { $0.id == id }
            }
        )

        let image = imageExportService.exportImage(config: config)

        await MainActor.run {
            self.exportedImage = image
            self.exportedVideoURL = nil
            self.isExporting = false
            self.showShareSheet = true
            HapticManager.notification(.success)
        }
    }
}
