//
//  AnalyticsService.swift
//  Textory
//
//  Created with Claude Code
//

import Foundation
import Aptabase

/// Analytics service wrapper for Aptabase
final class AnalyticsService {
    static let shared = AnalyticsService()

    private init() {}

    /// Initialize Aptabase with app key
    func initialize() {
        Aptabase.shared.initialize(appKey: "A-US-7778178477")
    }

    // MARK: - App Events

    func trackAppLaunch() {
        Aptabase.shared.trackEvent("app_launch")
    }

    // MARK: - Conversation Events

    func trackConversationCreated(isGroupChat: Bool, characterCount: Int) {
        Aptabase.shared.trackEvent("conversation_created", with: [
            "is_group_chat": String(isGroupChat),
            "character_count": String(characterCount)
        ])
    }

    func trackConversationDeleted() {
        Aptabase.shared.trackEvent("conversation_deleted")
    }

    func trackConversationDuplicated() {
        Aptabase.shared.trackEvent("conversation_duplicated")
    }

    // MARK: - Message Events

    func trackMessageAdded(type: String) {
        Aptabase.shared.trackEvent("message_added", with: [
            "type": type
        ])
    }

    func trackReactionAdded(reaction: String) {
        Aptabase.shared.trackEvent("reaction_added", with: [
            "reaction": reaction
        ])
    }

    // MARK: - Export Events

    func trackExportStarted(format: String, aspectRatio: String, isDarkMode: Bool) {
        Aptabase.shared.trackEvent("export_started", with: [
            "format": format,
            "aspect_ratio": aspectRatio,
            "dark_mode": String(isDarkMode)
        ])
    }

    func trackExportCompleted(format: String, durationSeconds: Double) {
        Aptabase.shared.trackEvent("export_completed", with: [
            "format": format,
            "duration_seconds": String(format: "%.1f", durationSeconds)
        ])
    }

    func trackExportFailed(format: String, error: String) {
        Aptabase.shared.trackEvent("export_failed", with: [
            "format": format,
            "error": error
        ])
    }

    func trackExportShared() {
        Aptabase.shared.trackEvent("export_shared")
    }

    // MARK: - AI Generation Events

    func trackAIGenerationStarted(genre: String, mood: String, length: String, characterCount: Int) {
        Aptabase.shared.trackEvent("ai_generation_started", with: [
            "genre": genre,
            "mood": mood,
            "length": length,
            "character_count": String(characterCount)
        ])
    }

    func trackAIGenerationCompleted(messageCount: Int) {
        Aptabase.shared.trackEvent("ai_generation_completed", with: [
            "message_count": String(messageCount)
        ])
    }

    func trackAIGenerationFailed(error: String) {
        Aptabase.shared.trackEvent("ai_generation_failed", with: [
            "error": error
        ])
    }

    // MARK: - Folder Events

    func trackFolderCreated() {
        Aptabase.shared.trackEvent("folder_created")
    }

    func trackFolderDeleted() {
        Aptabase.shared.trackEvent("folder_deleted")
    }

    // MARK: - Navigation Events

    func trackTabSelected(tab: String) {
        Aptabase.shared.trackEvent("tab_selected", with: [
            "tab": tab
        ])
    }

    // MARK: - Onboarding Events

    func trackOnboardingStarted() {
        Aptabase.shared.trackEvent("onboarding_started")
    }

    func trackOnboardingCompleted(skipped: Bool = false) {
        Aptabase.shared.trackEvent("onboarding_completed", with: [
            "skipped": String(skipped)
        ])
    }

    func trackOnboardingPageViewed(page: Int) {
        Aptabase.shared.trackEvent("onboarding_page_viewed", with: [
            "page": String(page)
        ])
    }

    // MARK: - Paywall Events

    func trackPaywallShown(source: String) {
        Aptabase.shared.trackEvent("paywall_shown", with: [
            "source": source
        ])
    }

    func trackPaywallDismissed() {
        Aptabase.shared.trackEvent("paywall_dismissed")
    }

    func trackPurchaseCompleted(plan: String) {
        Aptabase.shared.trackEvent("purchase_completed", with: [
            "plan": plan
        ])
    }

    func trackPurchaseFailed(plan: String, error: String) {
        Aptabase.shared.trackEvent("purchase_failed", with: [
            "plan": plan,
            "error": error
        ])
    }

    func trackRestorePurchases(success: Bool) {
        Aptabase.shared.trackEvent("restore_purchases", with: [
            "success": String(success)
        ])
    }
}
