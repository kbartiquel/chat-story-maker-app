//
//  PaywallView.swift
//  ChatStoryMaker
//
//  Premium upgrade paywall
//

import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var purchaseService = PurchaseService.shared
    @State private var selectedPlan: Plan = .yearly

    enum Plan {
        case monthly, yearly
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)

                        Text("Upgrade to Premium")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Unlock all features and create unlimited stories")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)

                    // Features comparison
                    featuresComparison

                    // Plan selection
                    planSelection

                    // Purchase button
                    purchaseButton

                    // Restore purchases
                    Button("Restore Purchases") {
                        Task {
                            try? await purchaseService.restorePurchases()
                            if purchaseService.isPremium {
                                dismiss()
                            }
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                    // Terms
                    Text("Subscription auto-renews. Cancel anytime.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private var featuresComparison: some View {
        VStack(spacing: 16) {
            FeatureRow(feature: "Daily Exports", free: "3/day", premium: "Unlimited")
            FeatureRow(feature: "Watermark", free: "Yes", premium: "No")
            FeatureRow(feature: "Themes", free: "iMessage", premium: "All 4 themes")
            FeatureRow(feature: "AI Generator", free: "No", premium: "Yes")
            FeatureRow(feature: "Characters", free: "2", premium: "Unlimited")
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var planSelection: some View {
        VStack(spacing: 12) {
            PlanButton(
                title: "Yearly",
                price: "$29.99/year",
                subtitle: "Save 50%",
                isSelected: selectedPlan == .yearly,
                isBestValue: true
            ) {
                selectedPlan = .yearly
            }

            PlanButton(
                title: "Monthly",
                price: "$4.99/month",
                subtitle: nil,
                isSelected: selectedPlan == .monthly,
                isBestValue: false
            ) {
                selectedPlan = .monthly
            }
        }
    }

    private var purchaseButton: some View {
        Button(action: purchase) {
            Group {
                if purchaseService.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Continue")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(purchaseService.isLoading)
    }

    private func purchase() {
        Task {
            do {
                if selectedPlan == .monthly {
                    try await purchaseService.purchaseMonthly()
                } else {
                    try await purchaseService.purchaseYearly()
                }
                if purchaseService.isPremium {
                    dismiss()
                }
            } catch {
                print("Purchase failed: \(error)")
            }
        }
    }
}

struct FeatureRow: View {
    let feature: String
    let free: String
    let premium: String

    var body: some View {
        HStack {
            Text(feature)
                .font(.subheadline)
            Spacer()
            Text(free)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 70)
            Text(premium)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.blue)
                .frame(width: 70)
        }
    }
}

struct PlanButton: View {
    let title: String
    let price: String
    let subtitle: String?
    let isSelected: Bool
    let isBestValue: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.headline)
                        if isBestValue {
                            Text("BEST VALUE")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .cornerRadius(4)
                        }
                    }
                    Text(price)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.green)
                }

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .foregroundColor(.primary)
    }
}

#Preview {
    PaywallView()
}
