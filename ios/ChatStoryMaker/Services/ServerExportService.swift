//
//  ServerExportService.swift
//  Textory
//
//  Service for rendering videos via the Python server API
//

import Foundation
import UIKit

class ServerExportService {

    // MARK: - Configuration

    // Change this to your Render URL after deployment
    // For local testing: "http://YOUR_MAC_IP:8000"
    // For production: "https://your-app.onrender.com"
    static var baseURL: String = "http://192.168.1.4:8000"

    // MARK: - Models

    struct RenderRequest: Codable {
        let messages: [MessageData]
        let characters: [CharacterData]
        let theme: String
        let settings: SettingsData
        let conversationTitle: String
        let isGroupChat: Bool

        enum CodingKeys: String, CodingKey {
            case messages, characters, theme, settings
            case conversationTitle = "conversation_title"
            case isGroupChat = "is_group_chat"
        }
    }

    struct MessageData: Codable {
        let id: String
        let text: String
        let characterId: String

        enum CodingKeys: String, CodingKey {
            case id, text
            case characterId = "character_id"
        }
    }

    struct CharacterData: Codable {
        let id: String
        let name: String
        let isMe: Bool
        let colorHex: String
        let avatarEmoji: String?
        let avatarImageBase64: String?

        enum CodingKeys: String, CodingKey {
            case id, name
            case isMe = "is_me"
            case colorHex = "color_hex"
            case avatarEmoji = "avatar_emoji"
            case avatarImageBase64 = "avatar_image_base64"
        }
    }

    struct SettingsData: Codable {
        let exportType: String
        let format: String
        let typingSpeed: String
        let showKeyboard: Bool
        let showTypingIndicator: Bool
        let enableSounds: Bool
        let darkMode: Bool

        enum CodingKeys: String, CodingKey {
            case exportType = "export_type"
            case format
            case typingSpeed = "typing_speed"
            case showKeyboard = "show_keyboard"
            case showTypingIndicator = "show_typing_indicator"
            case enableSounds = "enable_sounds"
            case darkMode = "dark_mode"
        }
    }

    struct JobResponse: Codable {
        let jobId: String
        let status: String
        let progress: Double
        let videoUrl: String?
        let error: String?

        enum CodingKeys: String, CodingKey {
            case jobId = "job_id"
            case status, progress
            case videoUrl = "video_url"
            case error
        }
    }

    // MARK: - Screenshot Models

    struct ScreenshotRequest: Codable {
        let messages: [MessageData]
        let characters: [CharacterData]
        let theme: String
        let conversationTitle: String
        let isGroupChat: Bool
        let darkMode: Bool
        let mode: String

        enum CodingKeys: String, CodingKey {
            case messages, characters, theme
            case conversationTitle = "conversation_title"
            case isGroupChat = "is_group_chat"
            case darkMode = "dark_mode"
            case mode
        }
    }

    struct ScreenshotResponse: Codable {
        let success: Bool
        let imageBase64: String?       // For long mode (single image)
        let imagesBase64: [String]?    // For paginated mode (multiple images)
        let width: Int?
        let height: Int?
        let pageCount: Int?
        let error: String?

        enum CodingKeys: String, CodingKey {
            case success
            case imageBase64 = "image_base64"
            case imagesBase64 = "images_base64"
            case width, height
            case pageCount = "page_count"
            case error
        }
    }

    // MARK: - Errors

    enum ServerError: Error, LocalizedError {
        case invalidURL
        case networkError(Error)
        case serverError(String)
        case decodingError
        case jobFailed(String)
        case timeout

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid server URL"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .serverError(let message):
                return "Server error: \(message)"
            case .decodingError:
                return "Failed to parse server response"
            case .jobFailed(let message):
                return "Rendering failed: \(message)"
            case .timeout:
                return "Request timed out"
            }
        }
    }

    // MARK: - Export Method

    func exportVideo(
        config: VideoExportService.ExportConfig,
        progress: @escaping (Double) -> Void
    ) async throws -> URL {
        // Convert config to request
        let request = RenderRequest(
            messages: config.messages.map { msg in
                MessageData(
                    id: msg.id.uuidString,
                    text: msg.text,
                    characterId: msg.characterID.uuidString
                )
            },
            characters: config.characters.map { char in
                // Convert avatar image data to base64 (compress first to reduce size)
                var avatarBase64: String? = nil
                if let imageData = char.avatarImageData,
                   let image = UIImage(data: imageData) {
                    // Resize to 100x100 and compress to JPEG for smaller payload
                    let size = CGSize(width: 100, height: 100)
                    UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
                    image.draw(in: CGRect(origin: .zero, size: size))
                    let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    if let resized = resizedImage,
                       let jpegData = resized.jpegData(compressionQuality: 0.7) {
                        avatarBase64 = jpegData.base64EncodedString()
                    }
                }

                return CharacterData(
                    id: char.id.uuidString,
                    name: char.name,
                    isMe: char.isMe,
                    colorHex: char.colorHex,
                    avatarEmoji: char.avatarEmoji,
                    avatarImageBase64: avatarBase64
                )
            },
            theme: config.theme.rawValue,
            settings: SettingsData(
                exportType: config.settings.exportType.rawValue,
                format: config.settings.format.rawValue,
                typingSpeed: config.settings.typingSpeed.displayName.lowercased(),
                showKeyboard: config.settings.showKeyboard,
                showTypingIndicator: config.settings.showTypingIndicator,
                enableSounds: config.settings.enableSounds,
                darkMode: config.settings.darkMode
            ),
            conversationTitle: config.conversationTitle,
            isGroupChat: config.isGroupChat
        )

        // Start render job
        let jobResponse = try await startRenderJob(request: request)
        let jobId = jobResponse.jobId

        progress(0.05)

        // Poll for status
        var lastProgress: Double = 0.05
        let maxAttempts = 300 // 5 minutes max (1 second intervals)
        var attempts = 0

        while attempts < maxAttempts {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

            let status = try await getJobStatus(jobId: jobId)

            if status.progress > lastProgress {
                lastProgress = status.progress
                progress(status.progress)
            }

            switch status.status {
            case "completed":
                progress(1.0)
                // Download video
                guard let videoUrlString = status.videoUrl else {
                    throw ServerError.serverError("No video URL returned")
                }
                return try await downloadVideo(urlString: videoUrlString, jobId: jobId)

            case "failed":
                throw ServerError.jobFailed(status.error ?? "Unknown error")

            case "queued", "processing":
                // Continue polling
                break

            default:
                break
            }

            attempts += 1
        }

        throw ServerError.timeout
    }

    // MARK: - Screenshot Export Method

    func exportScreenshot(
        config: VideoExportService.ExportConfig,
        mode: ScreenshotMode
    ) async throws -> [UIImage] {
        // Convert config to screenshot request
        let request = ScreenshotRequest(
            messages: config.messages.map { msg in
                MessageData(
                    id: msg.id.uuidString,
                    text: msg.text,
                    characterId: msg.characterID.uuidString
                )
            },
            characters: config.characters.map { char in
                var avatarBase64: String? = nil
                if let imageData = char.avatarImageData,
                   let image = UIImage(data: imageData) {
                    let size = CGSize(width: 100, height: 100)
                    UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
                    image.draw(in: CGRect(origin: .zero, size: size))
                    let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    if let resized = resizedImage,
                       let jpegData = resized.jpegData(compressionQuality: 0.7) {
                        avatarBase64 = jpegData.base64EncodedString()
                    }
                }

                return CharacterData(
                    id: char.id.uuidString,
                    name: char.name,
                    isMe: char.isMe,
                    colorHex: char.colorHex,
                    avatarEmoji: char.avatarEmoji,
                    avatarImageBase64: avatarBase64
                )
            },
            theme: config.theme.rawValue,
            conversationTitle: config.conversationTitle,
            isGroupChat: config.isGroupChat,
            darkMode: config.settings.darkMode,
            mode: mode.rawValue
        )

        // Make request
        guard let url = URL(string: "\(Self.baseURL)/render-screenshot") else {
            throw ServerError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 60

        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ServerError.serverError("Invalid response")
            }

            if httpResponse.statusCode != 200 {
                throw ServerError.serverError("HTTP \(httpResponse.statusCode)")
            }

            let decoder = JSONDecoder()
            let screenshotResponse = try decoder.decode(ScreenshotResponse.self, from: data)

            guard screenshotResponse.success else {
                throw ServerError.serverError(screenshotResponse.error ?? "Failed to render screenshot")
            }

            var images: [UIImage] = []

            // Handle paginated mode (multiple images)
            if let imagesBase64 = screenshotResponse.imagesBase64 {
                for base64String in imagesBase64 {
                    if let imageData = Data(base64Encoded: base64String),
                       let image = UIImage(data: imageData) {
                        images.append(image)
                    }
                }
            }
            // Handle long mode (single image)
            else if let base64String = screenshotResponse.imageBase64,
                    let imageData = Data(base64Encoded: base64String),
                    let image = UIImage(data: imageData) {
                images.append(image)
            }

            if images.isEmpty {
                throw ServerError.serverError("No images returned")
            }

            return images
        } catch let error as ServerError {
            throw error
        } catch {
            throw ServerError.networkError(error)
        }
    }

    // MARK: - API Methods

    private func startRenderJob(request: RenderRequest) async throws -> JobResponse {
        guard let url = URL(string: "\(Self.baseURL)/render") else {
            throw ServerError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ServerError.serverError("Invalid response")
            }

            if httpResponse.statusCode != 200 {
                throw ServerError.serverError("HTTP \(httpResponse.statusCode)")
            }

            let decoder = JSONDecoder()
            return try decoder.decode(JobResponse.self, from: data)
        } catch let error as ServerError {
            throw error
        } catch {
            throw ServerError.networkError(error)
        }
    }

    private func getJobStatus(jobId: String) async throws -> JobResponse {
        guard let url = URL(string: "\(Self.baseURL)/status/\(jobId)") else {
            throw ServerError.invalidURL
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ServerError.serverError("Invalid response")
            }

            if httpResponse.statusCode != 200 {
                throw ServerError.serverError("HTTP \(httpResponse.statusCode)")
            }

            let decoder = JSONDecoder()
            return try decoder.decode(JobResponse.self, from: data)
        } catch let error as ServerError {
            throw error
        } catch {
            throw ServerError.networkError(error)
        }
    }

    private func downloadVideo(urlString: String, jobId: String) async throws -> URL {
        // Handle relative URLs (local development)
        let fullURL: URL
        if urlString.starts(with: "/") {
            guard let url = URL(string: "\(Self.baseURL)\(urlString)") else {
                throw ServerError.invalidURL
            }
            fullURL = url
        } else {
            guard let url = URL(string: urlString) else {
                throw ServerError.invalidURL
            }
            fullURL = url
        }

        do {
            let (tempURL, response) = try await URLSession.shared.download(from: fullURL)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw ServerError.serverError("Failed to download video")
            }

            // Move to permanent location
            let documentsPath = FileManager.default.temporaryDirectory
            let destinationURL = documentsPath.appendingPathComponent("\(jobId).mp4")

            // Remove existing file if any
            try? FileManager.default.removeItem(at: destinationURL)

            try FileManager.default.moveItem(at: tempURL, to: destinationURL)

            return destinationURL
        } catch let error as ServerError {
            throw error
        } catch {
            throw ServerError.networkError(error)
        }
    }
}
