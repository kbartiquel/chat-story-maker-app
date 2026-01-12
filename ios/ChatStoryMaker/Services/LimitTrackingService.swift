//
//  LimitTrackingService.swift
//  Textory
//
//  Service for tracking user action limits (video exports and AI generations)
//

import Foundation

/// Service for tracking video export and AI generation limits
final class LimitTrackingService {
    static let shared = LimitTrackingService()

    private let userDefaults = UserDefaults.standard
    private let videoExportCountKey = "video_export_count"
    private let aiGenerationCountKey = "ai_generation_count"

    private init() {}

    // MARK: - Record Usage

    /// Record that a video was exported
    func recordVideoExport() {
        let count = getVideoExportCount()
        userDefaults.set(count + 1, forKey: videoExportCountKey)
        print("[LimitTracking] Video export count: \(count + 1)")
    }

    /// Record that an AI story was generated
    func recordAIGeneration() {
        let count = getAIGenerationCount()
        userDefaults.set(count + 1, forKey: aiGenerationCountKey)
        print("[LimitTracking] AI generation count: \(count + 1)")
    }

    // MARK: - Get Counts

    /// Get current video export count
    func getVideoExportCount() -> Int {
        return userDefaults.integer(forKey: videoExportCountKey)
    }

    /// Get current AI generation count
    func getAIGenerationCount() -> Int {
        return userDefaults.integer(forKey: aiGenerationCountKey)
    }

    // MARK: - Check Limits

    /// Check if video export limit has been reached (premium users bypass limits)
    func hasReachedVideoExportLimit() -> Bool {
        // Check premium access first
        if SubscriptionService.shared.hasPremiumAccess() {
            return false // Premium users have no limits
        }

        let count = getVideoExportCount()
        let settings = PaywallSettingsService.shared.getSettings()
        return count >= settings.videoExportLimit
    }

    /// Check if AI generation limit has been reached (premium users bypass limits)
    func hasReachedAIGenerationLimit() -> Bool {
        // Check premium access first
        if SubscriptionService.shared.hasPremiumAccess() {
            return false // Premium users have no limits
        }

        let count = getAIGenerationCount()
        let settings = PaywallSettingsService.shared.getSettings()
        return count >= settings.aiGenerationLimit
    }

    /// Check if any limit has been reached (premium users bypass limits)
    func hasReachedAnyLimit() -> Bool {
        // Check premium access first
        if SubscriptionService.shared.hasPremiumAccess() {
            return false // Premium users have no limits
        }

        return hasReachedVideoExportLimit() || hasReachedAIGenerationLimit()
    }

    // MARK: - Remaining Credits

    /// Get remaining video exports before limit
    func getRemainingVideoExports() -> Int {
        if SubscriptionService.shared.hasPremiumAccess() {
            return 999 // Unlimited for premium
        }
        let count = getVideoExportCount()
        let settings = PaywallSettingsService.shared.getSettings()
        return max(0, settings.videoExportLimit - count)
    }

    /// Get remaining AI generations before limit
    func getRemainingAIGenerations() -> Int {
        if SubscriptionService.shared.hasPremiumAccess() {
            return 999 // Unlimited for premium
        }
        let count = getAIGenerationCount()
        let settings = PaywallSettingsService.shared.getSettings()
        return max(0, settings.aiGenerationLimit - count)
    }

    // MARK: - Reset

    /// Reset all counts (for testing or after purchase)
    func resetAllCounts() {
        userDefaults.set(0, forKey: videoExportCountKey)
        userDefaults.set(0, forKey: aiGenerationCountKey)
        print("[LimitTracking] All counts reset")
    }

    // MARK: - Usage Summary

    /// Get a summary of current usage
    func getUsageSummary() -> (videoExports: Int, aiGenerations: Int, videoLimit: Int, aiLimit: Int) {
        let settings = PaywallSettingsService.shared.getSettings()
        return (
            videoExports: getVideoExportCount(),
            aiGenerations: getAIGenerationCount(),
            videoLimit: settings.videoExportLimit,
            aiLimit: settings.aiGenerationLimit
        )
    }
}
