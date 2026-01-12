//
//  SubscriptionService.swift
//  Textory
//
//  Mock subscription service - simulates RevenueCat behavior
//  Replace with real RevenueCat implementation when ready
//

import Foundation

// MARK: - Mock Package Models (simulating RevenueCat)

struct MockProduct {
    let id: String
    let localizedPriceString: String
    let price: Decimal
    let periodUnit: PeriodUnit
    let hasFreeTrial: Bool
    let trialDays: Int

    enum PeriodUnit {
        case week
        case month
        case year
        case lifetime
    }
}

struct MockPackage: Identifiable {
    let id: String
    let product: MockProduct
    let packageType: PackageType

    enum PackageType {
        case weekly
        case monthly
        case yearly
        case lifetime
    }
}

struct MockOffering {
    let id: String
    let packages: [MockPackage]

    var weeklyPackage: MockPackage? {
        packages.first { $0.packageType == .weekly }
    }

    var monthlyPackage: MockPackage? {
        packages.first { $0.packageType == .monthly }
    }

    var yearlyPackage: MockPackage? {
        packages.first { $0.packageType == .yearly }
    }

    var lifetimePackage: MockPackage? {
        packages.first { $0.packageType == .lifetime }
    }
}

// MARK: - Subscription Service

final class SubscriptionService {
    static let shared = SubscriptionService()

    private let userDefaults = UserDefaults.standard
    private let premiumKey = "user_has_premium"
    private let purchaseDateKey = "premium_purchase_date"

    private init() {}

    // MARK: - Mock Offerings

    /// Get mock offerings (simulates RevenueCat offerings)
    func getOfferings() async -> MockOffering? {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        return MockOffering(
            id: "default",
            packages: [
                // Lifetime package
                MockPackage(
                    id: "lifetime",
                    product: MockProduct(
                        id: "com.kimbytes.textory.lifetime",
                        localizedPriceString: "$29.99",
                        price: 29.99,
                        periodUnit: .lifetime,
                        hasFreeTrial: false,
                        trialDays: 0
                    ),
                    packageType: .lifetime
                ),
                // Weekly package with 3-day trial
                MockPackage(
                    id: "weekly",
                    product: MockProduct(
                        id: "com.kimbytes.textory.weekly",
                        localizedPriceString: "$4.99",
                        price: 4.99,
                        periodUnit: .week,
                        hasFreeTrial: true,
                        trialDays: 3
                    ),
                    packageType: .weekly
                ),
                // Monthly package
                MockPackage(
                    id: "monthly",
                    product: MockProduct(
                        id: "com.kimbytes.textory.monthly",
                        localizedPriceString: "$9.99",
                        price: 9.99,
                        periodUnit: .month,
                        hasFreeTrial: true,
                        trialDays: 3
                    ),
                    packageType: .monthly
                ),
                // Yearly package
                MockPackage(
                    id: "yearly",
                    product: MockProduct(
                        id: "com.kimbytes.textory.yearly",
                        localizedPriceString: "$39.99",
                        price: 39.99,
                        periodUnit: .year,
                        hasFreeTrial: false,
                        trialDays: 0
                    ),
                    packageType: .yearly
                )
            ]
        )
    }

    // MARK: - Premium Access

    /// Check if user has premium access
    func hasPremiumAccess() -> Bool {
        return userDefaults.bool(forKey: premiumKey)
    }

    /// Grant premium access (mock purchase)
    func grantPremiumAccess() {
        userDefaults.set(true, forKey: premiumKey)
        userDefaults.set(Date(), forKey: purchaseDateKey)
        print("[SubscriptionService] Premium access granted")
    }

    /// Revoke premium access (for testing)
    func revokePremiumAccess() {
        userDefaults.set(false, forKey: premiumKey)
        userDefaults.removeObject(forKey: purchaseDateKey)
        print("[SubscriptionService] Premium access revoked")
    }

    // MARK: - Mock Purchase Flow

    /// Simulate purchasing a package
    func purchase(package: MockPackage) async -> Result<Bool, PurchaseError> {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds

        // Mock: Always succeed for now
        // In production, this would call RevenueCat's purchase method
        grantPremiumAccess()

        AnalyticsService.shared.trackPurchaseCompleted(plan: package.id)

        return .success(true)
    }

    /// Simulate restoring purchases
    func restorePurchases() async -> Result<Bool, PurchaseError> {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        // Mock: Check if user previously had premium
        // In production, this would call RevenueCat's restore method
        if hasPremiumAccess() {
            return .success(true)
        } else {
            return .failure(.noPurchasesToRestore)
        }
    }

    // MARK: - Error Types

    enum PurchaseError: LocalizedError {
        case cancelled
        case failed(String)
        case noPurchasesToRestore

        var errorDescription: String? {
            switch self {
            case .cancelled:
                return "Purchase was cancelled"
            case .failed(let message):
                return "Purchase failed: \(message)"
            case .noPurchasesToRestore:
                return "No purchases to restore"
            }
        }
    }
}

