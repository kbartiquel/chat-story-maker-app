//
//  PaywallView.swift
//  Textery
//
//  Custom paywall screen with plan selection
//

import SwiftUI
import Combine
import RevenueCat

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PaywallViewModel()

    let isLimitTriggered: Bool
    let showCloseButtonImmediately: Bool

    init(isLimitTriggered: Bool = false, showCloseButtonImmediately: Bool = false) {
        self.isLimitTriggered = isLimitTriggered
        self.showCloseButtonImmediately = showCloseButtonImmediately
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#E07B5E")))
            } else if viewModel.offering != nil {
                paywallContent
            }

            // Close button
            if !viewModel.isLoading {
                VStack {
                    HStack {
                        Spacer()
                        if viewModel.canClose {
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 20))
                                    .foregroundColor(.gray)
                                    .frame(width: 32, height: 32)
                            }
                            .padding()
                        } else {
                            // Countdown timer circle
                            ZStack {
                                Circle()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                    .frame(width: 32, height: 32)

                                Circle()
                                    .trim(from: 0, to: viewModel.progress)
                                    .stroke(Color.gray, lineWidth: 2)
                                    .frame(width: 32, height: 32)
                                    .rotationEffect(.degrees(-90))
                            }
                            .padding()
                        }
                    }
                    Spacer()
                }
            }

            // Loading overlay during purchase
            if viewModel.isPurchasing {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
        .onAppear {
            let settings = PaywallSettingsService.shared.getSettings()
            let delay = showCloseButtonImmediately ? 0 : (isLimitTriggered ? settings.paywallCloseButtonDelayOnLimit : settings.paywallCloseButtonDelay)
            viewModel.loadOffering(closeDelay: delay)

            // Track paywall shown
            let source = showCloseButtonImmediately ? "settings" : (isLimitTriggered ? "limit_reached" : "app_launch")
            AnalyticsService.shared.trackPaywallShown(source: source)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    private var paywallContent: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    // App Icon
                    Image("AppIconImage")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .padding(.top, 50)

                    // Title
                    Text("Unlock Premium")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)

                    // Features List
                    VStack(spacing: 10) {
                        featureRow(icon: "infinity", text: "Unlimited Video Exports")
                        featureRow(icon: "sparkles", text: "Unlimited AI Story Generation")
                        featureRow(icon: "paintbrush.fill", text: "All Export Formats")
                        featureRow(icon: "star.fill", text: "Priority Support")
                    }
                    .padding(.vertical, 16)
                }
                .padding(.horizontal, 20)
            }

            // Bottom Section with Plans
            VStack(spacing: 16) {
                let settings = PaywallSettingsService.shared.getSettings()

                // Yearly Package
                if let yearlyPackage = viewModel.yearlyPackage, settings.paywallYearly {
                    planOption(
                        title: "Yearly Plan",
                        subtitle: "Billed yearly, cancel anytime",
                        price: yearlyPackage.localizedPriceString,
                        badge: "Save 50%",
                        isSelected: viewModel.selectedPlan == "yearly",
                        onTap: {
                            viewModel.selectPlan("yearly")
                        }
                    )
                }

                // Weekly Package
                if let weeklyPackage = viewModel.weeklyPackage, settings.paywallWeekly {
                    planOption(
                        title: "Weekly Plan",
                        subtitle: "Billed weekly, cancel anytime",
                        price: weeklyPackage.localizedPriceString,
                        isSelected: viewModel.selectedPlan == "weekly",
                        onTap: {
                            viewModel.selectPlan("weekly")
                        }
                    )
                }

                // Purchase Button
                Button(action: { viewModel.handlePurchase(onSuccess: { dismiss() }) }) {
                    Text(viewModel.getButtonText())
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(hex: "#1A9E6D"))
                        .cornerRadius(12)
                }
                .disabled(viewModel.isPurchasing)

                // Footer Links
                HStack(spacing: 4) {
                    if viewModel.isRestoring {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                            .scaleEffect(0.7)
                    } else {
                        Button("Restore") { viewModel.restorePurchases(onSuccess: { dismiss() }) }
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }

                    Text("•").font(.system(size: 12)).foregroundColor(.gray)

                    Link("Privacy", destination: URL(string: "https://kimbytes.com/textery/privacy.html")!)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)

                    Text("•").font(.system(size: 12)).foregroundColor(.gray)

                    Link("Terms", destination: URL(string: "https://kimbytes.com/textery/terms.html")!)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .background(Color.white)
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#E07B5E").opacity(0.1))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#E07B5E"))
            }

            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
    }

    private func planOption(
        title: String,
        subtitle: String? = nil,
        price: String,
        badge: String? = nil,
        isSelected: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        return Button(action: onTap) {
            HStack(spacing: 12) {
                // Left side: Title and subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                // Right side: Price and Radio button
                HStack(spacing: 8) {
                    if subtitle != nil {
                        Text(price)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                    }

                    ZStack {
                        Circle()
                            .stroke(isSelected ? Color(hex: "#E07B5E") : Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 24, height: 24)

                        if isSelected {
                            Circle()
                                .fill(Color(hex: "#E07B5E"))
                                .frame(width: 24, height: 24)

                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .padding()
            .background(isSelected ? Color(hex: "#E07B5E").opacity(0.1) : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(hex: "#E07B5E") : Color.gray.opacity(0.3), lineWidth: 2)
            )
            .cornerRadius(12)
            .overlay(alignment: .topTrailing) {
                // Badge
                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .cornerRadius(4)
                        .offset(x: -12, y: -10)
                }
            }
        }
    }
}

// MARK: - View Model

@MainActor
class PaywallViewModel: ObservableObject {
    @Published var offering: Offering?
    @Published var yearlyPackage: Package?
    @Published var weeklyPackage: Package?
    @Published var selectedPlan: String = "yearly"
    @Published var isLoading = true
    @Published var isPurchasing = false
    @Published var isRestoring = false
    @Published var canClose = false
    @Published var progress: CGFloat = 0
    @Published var showError = false
    @Published var iconRotation: Double = 0
    var errorMessage = ""

    private var timer: Timer?
    private var secondsRemaining = 0
    private var totalSeconds = 0
    private var rotationTimer: Timer?

    init() {
        startRingingAnimation()
    }

    func loadOffering(closeDelay: Int) {
        totalSeconds = closeDelay
        secondsRemaining = closeDelay
        canClose = closeDelay == 0

        Task {
            if let offerings = await SubscriptionService.shared.getOfferings(),
               let offering = offerings.current {
                self.offering = offering
                self.yearlyPackage = offering.annual
                self.weeklyPackage = offering.weekly

                // Set initial selected plan
                let settings = PaywallSettingsService.shared.getSettings()
                if settings.paywallYearly && self.yearlyPackage != nil {
                    self.selectedPlan = "yearly"
                } else if settings.paywallWeekly && self.weeklyPackage != nil {
                    self.selectedPlan = "weekly"
                }

                self.isLoading = false
                startCloseTimer()
            } else {
                self.isLoading = false
                self.errorMessage = "Failed to load subscription options"
                self.showError = true
            }
        }
    }

    private func startCloseTimer() {
        guard totalSeconds > 0 else { return }

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                if self.secondsRemaining > 0 {
                    self.secondsRemaining -= 1
                    self.progress = CGFloat(self.totalSeconds - self.secondsRemaining) / CGFloat(self.totalSeconds)
                } else {
                    self.canClose = true
                    self.timer?.invalidate()
                }
            }
        }
    }

    private func startRingingAnimation() {
        rotationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.1)) {
                    if self.iconRotation == 0 {
                        self.iconRotation = 8
                    } else if self.iconRotation > 0 {
                        self.iconRotation = -8
                    } else {
                        self.iconRotation = 0
                    }
                }
            }
        }
    }

    func selectPlan(_ plan: String) {
        selectedPlan = plan
    }

    func getButtonText() -> String {
        if selectedPlan == "yearly" {
            return "Get Yearly Access"
        } else {
            return "Subscribe Now"
        }
    }

    func handlePurchase(onSuccess: @escaping () -> Void) {
        let package: Package?
        if selectedPlan == "yearly" {
            package = yearlyPackage
        } else {
            package = weeklyPackage
        }

        guard let package = package else { return }

        isPurchasing = true

        Task {
            let result = await SubscriptionService.shared.purchase(package: package)
            isPurchasing = false

            switch result {
            case .success:
                onSuccess()
            case .failure(let error):
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    func restorePurchases(onSuccess: @escaping () -> Void) {
        isRestoring = true

        Task {
            let result = await SubscriptionService.shared.restorePurchases()
            isRestoring = false

            switch result {
            case .success:
                onSuccess()
            case .failure(let error):
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    deinit {
        timer?.invalidate()
        rotationTimer?.invalidate()
    }
}

// MARK: - Preview

#Preview {
    PaywallView(isLimitTriggered: false)
}
