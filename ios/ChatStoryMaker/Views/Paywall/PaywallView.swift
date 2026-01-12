//
//  PaywallView.swift
//  Textory
//
//  Custom paywall screen with plan selection
//

import SwiftUI
import Combine

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
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#1DB678")))
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
                    // App Icon with animation
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "#1A9E6D"), Color(hex: "#2EC4A0")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(viewModel.iconRotation))
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

                // Lifetime Package
                if let lifetimePackage = viewModel.lifetimePackage, settings.paywallLifetime {
                    planOption(
                        title: "Lifetime Access",
                        subtitle: "Pay Once, Use Forever",
                        price: lifetimePackage.product.localizedPriceString,
                        badge: "Best Value",
                        isSelected: viewModel.selectedPlan == "lifetime",
                        onTap: {
                            viewModel.selectPlan("lifetime", hasTrial: false)
                        }
                    )
                }

                // Monthly Package
                if let monthlyPackage = viewModel.monthlyPackage, settings.paywallMonthly {
                    let hasTrial = monthlyPackage.product.hasFreeTrial
                    planOption(
                        title: hasTrial ? "3-Day Free Trial" : "Monthly Plan",
                        subtitle: hasTrial ? "Then \(monthlyPackage.product.localizedPriceString)/month" : "Billed monthly, cancel anytime",
                        price: hasTrial ? "FREE" : monthlyPackage.product.localizedPriceString,
                        isSelected: viewModel.selectedPlan == "monthly",
                        onTap: {
                            viewModel.selectPlan("monthly", hasTrial: hasTrial)
                        }
                    )
                }

                // Weekly Package
                if let weeklyPackage = viewModel.weeklyPackage, settings.paywallWeekly {
                    let hasTrial = weeklyPackage.product.hasFreeTrial
                    planOption(
                        title: hasTrial ? "3-Day Free Trial" : "Weekly Plan",
                        subtitle: hasTrial ? "Then \(weeklyPackage.product.localizedPriceString)/week" : "Billed weekly, cancel anytime",
                        price: hasTrial ? "FREE" : weeklyPackage.product.localizedPriceString,
                        isSelected: viewModel.selectedPlan == "weekly",
                        onTap: {
                            viewModel.selectPlan("weekly", hasTrial: hasTrial)
                        }
                    )
                }

                // Free Trial Toggle
                if viewModel.shouldShowTrialToggle {
                    Toggle(isOn: $viewModel.trialEnabled) {
                        Text("Free Trial Enabled")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                    }
                    .tint(Color.green)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .onChange(of: viewModel.trialEnabled) { _, newValue in
                        if !viewModel.isUpdatingFromPlanSelection {
                            viewModel.handleTrialToggle(enabled: newValue)
                        }
                        viewModel.isUpdatingFromPlanSelection = false
                    }
                }

                // Purchase Button
                Button(action: { viewModel.handlePurchase(onSuccess: { dismiss() }) }) {
                    HStack {
                        Text(viewModel.getButtonText())
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)

                        Image(systemName: "arrow.right")
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#1A9E6D"), Color(hex: "#2EC4A0")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(28)
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

                    Link("Privacy", destination: URL(string: "https://kimbytes.com/textory/privacy.html")!)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)

                    Text("•").font(.system(size: 12)).foregroundColor(.gray)

                    Link("Terms", destination: URL(string: "https://kimbytes.com/textory/terms.html")!)
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
                    .fill(Color(hex: "#1DB678").opacity(0.1))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#1DB678"))
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
        let isFreePrice = price == "FREE"

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
                            .foregroundColor(isFreePrice ? .green : .black)
                    }

                    ZStack {
                        Circle()
                            .stroke(isSelected ? Color(hex: "#1DB678") : Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 24, height: 24)

                        if isSelected {
                            Circle()
                                .fill(Color(hex: "#1DB678"))
                                .frame(width: 24, height: 24)

                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .padding()
            .background(isSelected ? Color(hex: "#1DB678").opacity(0.1) : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(hex: "#1DB678") : Color.gray.opacity(0.3), lineWidth: 2)
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
    @Published var offering: MockOffering?
    @Published var lifetimePackage: MockPackage?
    @Published var yearlyPackage: MockPackage?
    @Published var monthlyPackage: MockPackage?
    @Published var weeklyPackage: MockPackage?
    @Published var selectedPlan: String = "lifetime"
    @Published var trialEnabled = false
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
    var isUpdatingFromPlanSelection = false

    /// Returns true if at least one visible package has a trial
    var hasVisibleTrial: Bool {
        let settings = PaywallSettingsService.shared.getSettings()
        let monthlyHasTrial = (monthlyPackage?.product.hasFreeTrial ?? false) && settings.paywallMonthly
        let weeklyHasTrial = (weeklyPackage?.product.hasFreeTrial ?? false) && settings.paywallWeekly
        return monthlyHasTrial || weeklyHasTrial
    }

    /// Determines if the trial toggle should be shown
    var shouldShowTrialToggle: Bool {
        let settings = PaywallSettingsService.shared.getSettings()
        let monthlyShown = monthlyPackage != nil && settings.paywallMonthly
        let weeklyShown = weeklyPackage != nil && settings.paywallWeekly

        // If only one subscription package shown, check if it has a trial
        if monthlyShown && !weeklyShown {
            return monthlyPackage?.product.hasFreeTrial ?? false
        }
        if !monthlyShown && weeklyShown {
            return weeklyPackage?.product.hasFreeTrial ?? false
        }

        // Both packages shown - show toggle if at least one has a trial
        return hasVisibleTrial
    }

    init() {
        startRingingAnimation()
    }

    func loadOffering(closeDelay: Int) {
        totalSeconds = closeDelay
        secondsRemaining = closeDelay
        canClose = closeDelay == 0

        Task {
            if let offering = await SubscriptionService.shared.getOfferings() {
                self.offering = offering
                self.lifetimePackage = offering.lifetimePackage
                self.yearlyPackage = offering.yearlyPackage
                self.monthlyPackage = offering.monthlyPackage
                self.weeklyPackage = offering.weeklyPackage

                // Set initial selected plan
                let settings = PaywallSettingsService.shared.getSettings()
                if settings.paywallLifetime && self.lifetimePackage != nil {
                    self.selectedPlan = "lifetime"
                } else if settings.paywallWeekly && self.weeklyPackage != nil {
                    self.selectedPlan = "weekly"
                    self.trialEnabled = self.weeklyPackage?.product.hasFreeTrial ?? false
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

    func selectPlan(_ plan: String, hasTrial: Bool) {
        isUpdatingFromPlanSelection = true
        selectedPlan = plan
        trialEnabled = hasTrial
    }

    func handleTrialToggle(enabled: Bool) {
        let settings = PaywallSettingsService.shared.getSettings()
        let weeklyHasTrial = (weeklyPackage?.product.hasFreeTrial ?? false) && settings.paywallWeekly
        let monthlyHasTrial = (monthlyPackage?.product.hasFreeTrial ?? false) && settings.paywallMonthly

        if enabled {
            if weeklyHasTrial {
                selectedPlan = "weekly"
            } else if monthlyHasTrial {
                selectedPlan = "monthly"
            }
        } else {
            if settings.paywallLifetime {
                selectedPlan = "lifetime"
            } else if settings.paywallYearly {
                selectedPlan = "yearly"
            }
        }
    }

    func getButtonText() -> String {
        if selectedPlan == "lifetime" {
            return "Get Lifetime Access"
        } else if selectedPlan == "yearly" {
            return "Get Yearly Access"
        } else if trialEnabled && hasVisibleTrial {
            return "Try 3 Days Free"
        } else {
            return "Subscribe Now"
        }
    }

    func handlePurchase(onSuccess: @escaping () -> Void) {
        let package: MockPackage?
        if selectedPlan == "lifetime" {
            package = lifetimePackage
        } else if selectedPlan == "yearly" {
            package = yearlyPackage
        } else if selectedPlan == "monthly" {
            package = monthlyPackage
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
