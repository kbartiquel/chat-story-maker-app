//
//  PurchaseService.swift
//  ChatStoryMaker
//
//  Premium features - Currently bypassed (all features free)
//

import Foundation

@Observable
class PurchaseService {
    static let shared = PurchaseService()

    // BYPASSED: All features are free for now
    var isPremium = true  // Always true - premium bypassed
    var isLoading = false
    var errorMessage: String?

    private init() {}

    func checkPremiumStatus() {
        // Bypassed - always premium
        isPremium = true
    }

    // MARK: - Purchases (Bypassed)

    func purchaseMonthly() async throws {
        // Bypassed
    }

    func purchaseYearly() async throws {
        // Bypassed
    }

    func restorePurchases() async throws {
        // Bypassed
    }

    // MARK: - Export Limits (Bypassed - Unlimited)

    var remainingExportsToday: Int {
        return Int.max  // Unlimited
    }

    var canExport: Bool {
        return true  // Always can export
    }

    func recordExport() {
        // Bypassed - no tracking
    }

    // MARK: - Feature Gating (Bypassed - All Free)

    func canUseTheme(_ theme: ChatTheme) -> Bool {
        return true  // All themes available
    }

    func canUseAIGenerator() -> Bool {
        return true  // AI always available
    }

    var shouldShowWatermark: Bool {
        return false  // No watermark
    }
}
