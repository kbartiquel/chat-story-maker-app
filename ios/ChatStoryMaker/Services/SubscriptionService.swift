//
//  SubscriptionService.swift
//  Textery
//
//  RevenueCat subscription service
//

import Foundation
import RevenueCat

// MARK: - Subscription Service

final class SubscriptionService {
    static let shared = SubscriptionService()

    private init() {}

    // MARK: - Offerings

    /// Get current offerings from RevenueCat
    func getOfferings() async -> Offerings? {
        do {
            let offerings = try await Purchases.shared.offerings()
            print("SubscriptionService: Offerings fetched successfully")
            print("SubscriptionService: Current offering: \(offerings.current?.identifier ?? "NONE")")
            print("SubscriptionService: Available packages: \(offerings.current?.availablePackages.map { $0.identifier } ?? [])")
            return offerings
        } catch {
            print("SubscriptionService: Failed to fetch offerings - \(error)")
            print("SubscriptionService: Error details - \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Premium Access

    /// Check if user has premium access
    func hasPremiumAccess() async -> Bool {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            return customerInfo.entitlements[Config.Entitlements.premium]?.isActive == true
        } catch {
            print("SubscriptionService: Failed to check premium status - \(error.localizedDescription)")
            return false
        }
    }

    /// Check premium access synchronously (uses cached value)
    func hasPremiumAccessCached() -> Bool {
        return Purchases.shared.cachedCustomerInfo?.entitlements[Config.Entitlements.premium]?.isActive == true
    }

    // MARK: - Purchase Flow

    /// Purchase a package
    func purchase(package: Package) async -> Result<CustomerInfo, PurchaseError> {
        do {
            let result = try await Purchases.shared.purchase(package: package)

            if !result.userCancelled {
                AnalyticsService.shared.trackPurchaseCompleted(plan: package.identifier)
                return .success(result.customerInfo)
            } else {
                return .failure(.cancelled)
            }
        } catch {
            print("SubscriptionService: Purchase failed - \(error.localizedDescription)")
            return .failure(.failed(error.localizedDescription))
        }
    }

    /// Restore purchases
    func restorePurchases() async -> Result<CustomerInfo, PurchaseError> {
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()

            if customerInfo.entitlements[Config.Entitlements.premium]?.isActive == true {
                return .success(customerInfo)
            } else {
                return .failure(.noPurchasesToRestore)
            }
        } catch {
            print("SubscriptionService: Restore failed - \(error.localizedDescription)")
            return .failure(.failed(error.localizedDescription))
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
