//
//  SettingsViewModel.swift
//  ChatStoryMaker
//
//  ViewModel for settings and premium state
//

import SwiftUI

@Observable
class SettingsViewModel {
    var showingPaywall = false
    var purchaseService = PurchaseService.shared

    var isPremium: Bool {
        purchaseService.isPremium
    }

    var remainingExports: Int {
        purchaseService.remainingExportsToday
    }

    func restorePurchases() async {
        do {
            try await purchaseService.restorePurchases()
        } catch {
            print("Restore failed: \(error)")
        }
    }
}
