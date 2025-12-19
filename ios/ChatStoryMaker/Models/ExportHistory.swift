//
//  ExportHistory.swift
//  ChatStoryMaker
//
//  Model to store export history records
//

import Foundation
import SwiftData

@Model
final class ExportHistory {
    var id: UUID
    var conversationTitle: String
    var exportDate: Date
    var exportType: String  // "video" or "screenshot"
    var renderMode: String  // "device" or "server"
    var format: String      // "tiktok", "instagram", "youtube"
    var videoURL: String?   // URL string for cloud videos
    var localPath: String?  // Local file path if saved
    var thumbnailData: Data? // Thumbnail image data
    var duration: Double?   // Video duration in seconds
    var messageCount: Int
    var jobId: String?      // Server job ID for re-downloading

    init(
        conversationTitle: String,
        exportType: ExportType,
        renderMode: RenderMode,
        format: ExportFormat,
        videoURL: String? = nil,
        localPath: String? = nil,
        thumbnailData: Data? = nil,
        duration: Double? = nil,
        messageCount: Int,
        jobId: String? = nil
    ) {
        self.id = UUID()
        self.conversationTitle = conversationTitle
        self.exportDate = Date()
        self.exportType = exportType.rawValue
        self.renderMode = renderMode.rawValue
        self.format = format.rawValue
        self.videoURL = videoURL
        self.localPath = localPath
        self.thumbnailData = thumbnailData
        self.duration = duration
        self.messageCount = messageCount
        self.jobId = jobId
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: exportDate)
    }

    var exportTypeEnum: ExportType {
        ExportType(rawValue: exportType) ?? .video
    }

    var renderModeEnum: RenderMode {
        RenderMode(rawValue: renderMode) ?? .device
    }

    var formatEnum: ExportFormat {
        ExportFormat(rawValue: format) ?? .tiktok
    }
}
