//
//  TrackingService.swift
//  Textery
//
//  Sends lightweight analytics events to the backend for admin visibility.
//

import Foundation
import UIKit

final class TrackingService {
    static let shared = TrackingService()

    private let session = URLSession.shared
    private let userDefaults = UserDefaults.standard
    private let deviceIDKey = "textery_tracking_device_id"
    private let firstInstallTrackedKey = "textery_first_install_tracked"

    private init() {}

    var currentUserID: String {
        deviceID()
    }

    var currentAppVersion: String {
        appVersion()
    }

    func track(event: String, properties: [String: String] = [:]) {
        guard let url = URL(string: "\(ServerExportService.baseURL)/track") else {
            return
        }

        let payload = TrackingPayload(
            userID: deviceID(),
            event: event,
            properties: properties,
            platform: "ios",
            appVersion: appVersion()
        )

        guard let body = try? JSONEncoder().encode(payload) else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 8
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        session.dataTask(with: request).resume()
    }

    func trackFirstInstallIfNeeded() {
        guard !userDefaults.bool(forKey: firstInstallTrackedKey) else { return }
        userDefaults.set(true, forKey: firstInstallTrackedKey)
        track(event: "first_install")
    }

    private func deviceID() -> String {
        if let cached = userDefaults.string(forKey: deviceIDKey), !cached.isEmpty {
            return cached
        }

        let identifier = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        userDefaults.set(identifier, forKey: deviceIDKey)
        return identifier
    }

    private func appVersion() -> String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        return "\(version) (\(build))"
    }

    private struct TrackingPayload: Codable {
        let userID: String
        let event: String
        let properties: [String: String]
        let platform: String
        let appVersion: String

        enum CodingKeys: String, CodingKey {
            case userID = "user_id"
            case event, properties, platform
            case appVersion = "app_version"
        }
    }
}
