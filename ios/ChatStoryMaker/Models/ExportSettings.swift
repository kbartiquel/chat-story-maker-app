//
//  ExportSettings.swift
//  Textery
//
//  Video export settings and formats
//

import Foundation

struct ExportSettings {
    var exportType: ExportType = .video
    var format: ExportFormat = .tiktok
    var typingSpeed: TypingSpeed = .normal
    var showKeyboard: Bool = true
    var showTypingIndicator: Bool = true
    var enableSounds: Bool = true
    var darkMode: Bool = false

    // Render mode - always use server/cloud for better quality and emoji support
    var renderMode: RenderMode = .server
}

enum RenderMode: String, CaseIterable {
    case device   // Render on device (original implementation)
    case server   // Render on server (faster, requires internet)

    var displayName: String {
        switch self {
        case .device: return "On Device"
        case .server: return "Cloud"
        }
    }

    var description: String {
        switch self {
        case .device: return "Render locally (no internet needed)"
        case .server: return "Render on server (faster)"
        }
    }
}

enum ExportType: String, CaseIterable {
    case video

    var displayName: String {
        switch self {
        case .video: return "Video"
        }
    }

    var icon: String {
        switch self {
        case .video: return "video.fill"
        }
    }
}

enum ExportFormat: String, CaseIterable {
    case tiktok
    case instagram
    case youtube

    var displayName: String {
        switch self {
        case .tiktok: return "TikTok"
        case .instagram: return "Instagram"
        case .youtube: return "YouTube"
        }
    }

    var aspectRatio: String {
        switch self {
        case .tiktok: return "9:16"
        case .instagram: return "1:1"
        case .youtube: return "16:9"
        }
    }

    var resolution: CGSize {
        switch self {
        case .tiktok: return CGSize(width: 1080, height: 1920)
        case .instagram: return CGSize(width: 1080, height: 1080)
        case .youtube: return CGSize(width: 1920, height: 1080)
        }
    }
}

enum TypingSpeed: Double, CaseIterable {
    case slow = 0.20    // 200ms per character (6 frames at 30fps)
    case normal = 0.12  // 120ms per character (3-4 frames at 30fps)
    case fast = 0.06    // 60ms per character (2 frames at 30fps)

    var displayName: String {
        switch self {
        case .slow: return "Slow"
        case .normal: return "Normal"
        case .fast: return "Fast"
        }
    }

    /// Frames per character at 30fps
    var framesPerChar: Int {
        return max(1, Int(rawValue * 30))
    }

    var charDelay: Double { rawValue }
    var messageDelay: Double { rawValue * 10 }
}
