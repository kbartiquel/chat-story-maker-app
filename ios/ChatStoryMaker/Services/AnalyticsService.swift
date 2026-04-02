//
//  AnalyticsService.swift
//  Textery
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
        TrackingService.shared.trackFirstInstallIfNeeded()
    }

    private func track(_ event: String, properties: [String: String] = [:]) {
        Aptabase.shared.trackEvent(event, with: properties)
        TrackingService.shared.track(event: event, properties: properties)
    }

    // MARK: - App Events

    func trackAppLaunch() {
        track("app_launch")
    }

    // MARK: - Conversation Events

    func trackConversationCreated(isGroupChat: Bool, characterCount: Int) {
        track("conversation_created", properties: [
            "is_group_chat": String(isGroupChat),
            "character_count": String(characterCount)
        ])
    }

    func trackConversationDeleted() {
        track("conversation_deleted")
    }

    func trackConversationDuplicated() {
        track("conversation_duplicated")
    }

    // MARK: - Message Events

    func trackMessageAdded(type: String) {
        track("message_added", properties: [
            "type": type
        ])
    }

    func trackReactionAdded(reaction: String) {
        track("reaction_added", properties: [
            "reaction": reaction
        ])
    }

    // MARK: - Export Events

    func trackExportStarted(format: String, aspectRatio: String, isDarkMode: Bool) {
        track("export_started", properties: [
            "format": format,
            "aspect_ratio": aspectRatio,
            "dark_mode": String(isDarkMode)
        ])
    }

    func trackExportCompleted(format: String, durationSeconds: Double) {
        track("export_completed", properties: [
            "format": format,
            "duration_seconds": String(format: "%.1f", durationSeconds)
        ])
    }

    func trackExportFailed(format: String, error: String) {
        track("export_failed", properties: [
            "format": format,
            "error": error
        ])
    }

    func trackExportShared() {
        track("export_shared")
    }

    // MARK: - AI Generation Events

    func trackAIGenerationStarted(genre: String, mood: String, length: String, characterCount: Int) {
        track("ai_generation_started", properties: [
            "genre": genre,
            "mood": mood,
            "length": length,
            "character_count": String(characterCount)
        ])
    }

    func trackAIGenerationCompleted(messageCount: Int) {
        track("ai_generation_completed", properties: [
            "message_count": String(messageCount)
        ])
    }

    func trackAIGenerationFailed(error: String) {
        track("ai_generation_failed", properties: [
            "error": error
        ])
    }

    // MARK: - Folder Events

    func trackFolderCreated() {
        track("folder_created")
    }

    func trackFolderDeleted() {
        track("folder_deleted")
    }

    // MARK: - Navigation Events

    func trackTabSelected(tab: String) {
        track("tab_selected", properties: [
            "tab": tab
        ])
    }

    // MARK: - Onboarding Events

    func trackOnboardingStarted() {
        track("onboarding_started")
    }

    func trackOnboardingCompleted(skipped: Bool = false) {
        track("onboarding_completed", properties: [
            "skipped": String(skipped)
        ])
    }

    func trackOnboardingPageViewed(page: Int) {
        track("onboarding_page_viewed", properties: [
            "page": String(page)
        ])
    }

    // MARK: - Paywall Events

    func trackPaywallShown(source: String) {
        track("paywall_shown", properties: [
            "source": source
        ])
    }

    func trackPaywallDismissed() {
        track("paywall_dismissed")
    }

    func trackPurchaseCompleted(plan: String) {
        track("purchase_completed", properties: [
            "plan": plan
        ])
    }

    func trackPurchaseFailed(plan: String, error: String) {
        track("purchase_failed", properties: [
            "plan": plan,
            "error": error
        ])
    }

    func trackRestorePurchases(success: Bool) {
        track("restore_purchases", properties: [
            "success": String(success)
        ])
    }
}
