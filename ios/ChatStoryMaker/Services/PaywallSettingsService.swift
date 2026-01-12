//
//  PaywallSettingsService.swift
//  Textory
//
//  Service for fetching and caching paywall configuration
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

    private var currentSettings: PaywallSettings?

    private init() {
        // Load mock settings on init
        currentSettings = loadMockSettings()
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

    /// Update settings (for testing purposes)
    func updateSettings(_ settings: PaywallSettings) {
        currentSettings = settings
        saveToCache(settings)
    }

    /// Reset to default settings
    func resetToDefaults() {
        currentSettings = defaultSettings()
        saveToCache(currentSettings!)
    }

    // MARK: - Private Methods

    private func loadMockSettings() -> PaywallSettings {
        // Mock JSON settings - simulating server response
        // In production, this would be fetched from a server
        return PaywallSettings(
            videoExportLimit: 3,
            aiGenerationLimit: 5,
            hardPaywall: false,
            paywallCloseButtonDelay: 2,
            paywallCloseButtonDelayOnLimit: 5,
            showPaywallOnStart: false,
            paywallMonthly: true,
            paywallWeekly: true,
            paywallYearly: false,
            paywallLifetime: true
        )
    }

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
            paywallCloseButtonDelay: 2,
            paywallCloseButtonDelayOnLimit: 5,
            showPaywallOnStart: false,
            paywallMonthly: true,
            paywallWeekly: true,
            paywallYearly: false,
            paywallLifetime: true
        )
    }
}
