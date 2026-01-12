//
//  Constants.swift
//  Textory
//
//  App-wide constants and configuration
//

import Foundation

enum Constants {
    // Free Tier Limits
    static let freeExportsPerDay = 3
    static let freeMaxCharacters = 2

    // UI Constants
    static let bubbleCornerRadius: CGFloat = 20
    static let maxBubbleWidthRatio: CGFloat = 0.75
    static let messagePadding: CGFloat = 16

    // Video Export
    static let videoFPS: Int32 = 60
    static let defaultTypingIndicatorDuration: Double = 0.5

    // Animation
    static let defaultAnimationDuration: Double = 0.3
}

enum Config {
    // Replace with your actual API keys
    static let claudeAPIKey = "YOUR_CLAUDE_API_KEY"
    static let revenueCatAPIKey = "YOUR_REVENUECAT_API_KEY"

    enum Entitlements {
        static let premium = "premium"
    }

    enum Products {
        static let monthly = "chatstorymaker_monthly"
        static let yearly = "chatstorymaker_yearly"
    }
}
