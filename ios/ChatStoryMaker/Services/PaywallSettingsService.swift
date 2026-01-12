//
//  PaywallSettingsService.swift
//  Textory
//
//  Service for fetching and caching paywall configuration from server
//

import Foundation

/// Paywall configuration settings
struct PaywallSettings: Codable {
    // Feature limits
    let videoExportLimit: Int
    let aiGenerationLimit: Int

    // Paywall behavior
    let hardPaywall: Bool
    let paywallCloseButtonDelay: Int
    let paywallCloseButtonDelayOnLimit: Int
    let showPaywallOnStart: Bool

    // Plan visibility
    let paywallMonthly: Bool
    let paywallWeekly: Bool
    let paywallYearly: Bool
    let paywallLifetime: Bool

    enum CodingKeys: String, CodingKey {
        case videoExportLimit
        case aiGenerationLimit
        case hardPaywall
        case paywallCloseButtonDelay
        case paywallCloseButtonDelayOnLimit
        case showPaywallOnStart
        case paywallMonthly
        case paywallWeekly
        case paywallYearly
        case paywallLifetime
    }
}

/// Service for managing paywall settings
final class PaywallSettingsService {
    static let shared = PaywallSettingsService()

    private let userDefaults = UserDefaults.standard
    private let cacheKey = "cached_paywall_settings"
    private let lastFetchKey = "last_settings_fetch"

    private var currentSettings: PaywallSettings?

    // Use same base URL as ServerExportService
    private var baseURL: String {
        ServerExportService.baseURL
    }

    // Cache duration: 5 minutes
    private let cacheDuration: TimeInterval = 300

    private init() {
        // Load from cache on init
        if let cached = loadFromCache() {
            currentSettings = cached
        } else {
            currentSettings = defaultSettings()
        }

        // Fetch fresh settings in background
        Task {
            await fetchSettings()
        }
    }

    // MARK: - Public Methods

    /// Get current settings (returns cached if available, otherwise default)
    func getSettings() -> PaywallSettings {
        if let settings = currentSettings {
            return settings
        }

        // Try to load from cache
        if let cached = loadFromCache() {
            currentSettings = cached
            return cached
        }

        // Return default settings
        return defaultSettings()
    }

    /// Fetch settings from server
    @discardableResult
    func fetchSettings() async -> PaywallSettings {
        // Check if we have recent cached settings
        if let lastFetch = userDefaults.object(forKey: lastFetchKey) as? Date,
           Date().timeIntervalSince(lastFetch) < cacheDuration,
           let cached = loadFromCache() {
            currentSettings = cached
            return cached
        }

        do {
            guard let url = URL(string: "\(baseURL)/settings") else {
                print("PaywallSettingsService: Invalid URL")
                return getSettings()
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 10

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("PaywallSettingsService: Server returned error")
                return getSettings()
            }

            let decoder = JSONDecoder()
            let settings = try decoder.decode(PaywallSettings.self, from: data)

            // Update current settings and cache
            currentSettings = settings
            saveToCache(settings)
            userDefaults.set(Date(), forKey: lastFetchKey)

            print("PaywallSettingsService: Successfully fetched settings from server")
            return settings

        } catch {
            print("PaywallSettingsService: Failed to fetch settings - \(error.localizedDescription)")
            return getSettings()
        }
    }

    /// Force refresh settings from server
    func refreshSettings() async -> PaywallSettings {
        // Clear last fetch time to force refresh
        userDefaults.removeObject(forKey: lastFetchKey)
        return await fetchSettings()
    }

    /// Update settings locally (for testing purposes)
    func updateSettings(_ settings: PaywallSettings) {
        currentSettings = settings
        saveToCache(settings)
    }

    /// Reset to default settings
    func resetToDefaults() {
        currentSettings = defaultSettings()
        saveToCache(currentSettings!)
        userDefaults.removeObject(forKey: lastFetchKey)
    }

    // MARK: - Private Methods

    private func saveToCache(_ settings: PaywallSettings) {
        if let encoded = try? JSONEncoder().encode(settings) {
            userDefaults.set(encoded, forKey: cacheKey)
        }
    }

    private func loadFromCache() -> PaywallSettings? {
        guard let data = userDefaults.data(forKey: cacheKey) else {
            return nil
        }
        return try? JSONDecoder().decode(PaywallSettings.self, from: data)
    }

    private func defaultSettings() -> PaywallSettings {
        return PaywallSettings(
            videoExportLimit: 3,
            aiGenerationLimit: 5,
            hardPaywall: false,
            paywallCloseButtonDelay: 3,
            paywallCloseButtonDelayOnLimit: 5,
            showPaywallOnStart: true,
            paywallMonthly: true,
            paywallWeekly: true,
            paywallYearly: false,
            paywallLifetime: true
        )
    }
}
