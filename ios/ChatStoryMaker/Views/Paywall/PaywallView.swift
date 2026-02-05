//
//  PaywallView.swift
//  Textery
//
//  Dynamic paywall with intro offer support
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
                    // App Icon with animation
                    Image("AppIconImage")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
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
            VStack(spacing: 12) {
                // Plan order: Yearly → Monthly → Weekly
                if let plan = viewModel.yearlyPlanInfo {
                    planOptionView(plan: plan, planId: "yearly")
                }

                if let plan = viewModel.monthlyPlanInfo {
                    planOptionView(plan: plan, planId: "monthly")
                }

                if let plan = viewModel.weeklyPlanInfo {
                    planOptionView(plan: plan, planId: "weekly")
                }

                // Purchase Button
                Button(action: { viewModel.handlePurchase(onSuccess: { dismiss() }) }) {
                    Text(viewModel.buttonText)
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

                    Link("Privacy", destination: URL(string: "https://chat-story-maker.onrender.com/privacy")!)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)

                    Text("•").font(.system(size: 12)).foregroundColor(.gray)

                    Link("Terms", destination: URL(string: "https://chat-story-maker.onrender.com/terms")!)
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

    private func planOptionView(plan: PlanDisplayInfo, planId: String) -> some View {
        let isSelected = viewModel.selectedPlan == planId

        return Button(action: { viewModel.selectPlan(planId) }) {
            HStack(spacing: 12) {
                // Left side: Plan info (matching Quiz Maker AI layout)
                VStack(alignment: .leading, spacing: 2) {
                    // Plan name - small header
                    Text(plan.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)
                        .tracking(0.5)

                    // Price info - THE BIG/PROMINENT ONE
                    Text(plan.priceInfo)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(plan.isFreeOffer ? Color(hex: "#1A9E6D") : .black)

                    // Secondary info
                    Text(plan.secondaryInfo)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                }

                Spacer()

                // Right side: Radio button on top, badge below
                VStack(alignment: .trailing, spacing: 6) {
                    // Radio button
                    ZStack {
                        Circle()
                            .stroke(isSelected ? Color(hex: "#E07B5E") : Color.gray.opacity(0.4), lineWidth: 2)
                            .frame(width: 20, height: 20)

                        if isSelected {
                            Circle()
                                .fill(Color(hex: "#E07B5E"))
                                .frame(width: 10, height: 10)
                        }
                    }

                    // Badge below radio button
                    if let badge = plan.badge {
                        HStack(spacing: 2) {
                            if plan.badgeColor == .orange {
                                Text("🔥")
                                    .font(.system(size: 11))
                            }
                            Text(badge)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(plan.badgeColor == Color(hex: "#1A9E6D") ? Color(hex: "#1A9E6D") : .gray)
                                .tracking(0.3)
                        }
                    }
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(isSelected ? Color(hex: "#E07B5E").opacity(0.1) : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(hex: "#E07B5E") : Color.gray.opacity(0.3), lineWidth: 2)
            )
            .cornerRadius(12)
        }
    }
}

// MARK: - Plan Display Info

struct PlanDisplayInfo {
    let title: String
    let priceInfo: String
    let secondaryInfo: String
    let badge: String?
    let badgeColor: Color
    let isFreeOffer: Bool
}

// MARK: - View Model

@MainActor
class PaywallViewModel: ObservableObject {

    // ===== DEBUG TEST FLAGS =====
    // Set all to false for production or to use actual App Store offers
    // These simulate intro offers without needing App Store Connect setup

    // Yearly: Test free trial (e.g., "FREE for 3 days, then $29.99/year")
    private let testYearlyFreeTrial = true
    private let testYearlyFreeTrialDays = 3
    private let testYearlyPrice = "$29.99"

    // Monthly: Test free trial (e.g., "FREE for 3 days, then $9.99/month")
    private let testMonthlyFreeTrial = false
    private let testMonthlyFreeTrialDays = 3
    private let testMonthlyPrice = "$9.99"

    // Weekly: Test paid intro (e.g., "$0.99 first week, then $4.99/week")
    private let testWeeklyPaidIntro = false
    private let testWeeklyIntroPrice = "$0.99"
    private let testWeeklyPrice = "$4.99"

    // Weekly: Test free trial (e.g., "FREE for 3 days, then $4.99/week")
    // Note: If both testWeeklyPaidIntro and testWeeklyFreeTrial are true, paid intro takes priority
    private let testWeeklyFreeTrial = false
    private let testWeeklyFreeTrialDays = 3

    // ===== END DEBUG FLAGS =====

    @Published var offering: Offering?
    @Published var yearlyPackage: Package?
    @Published var monthlyPackage: Package?
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

    // MARK: - Dynamic Plan Info

    var yearlyPlanInfo: PlanDisplayInfo? {
        guard let package = yearlyPackage else { return nil }
        let settings = PaywallSettingsService.shared.getSettings()
        guard settings.paywallYearly else { return nil }
        return buildPlanInfo(package: package, weeksPerPeriod: 52, periodName: "year")
    }

    var monthlyPlanInfo: PlanDisplayInfo? {
        guard let package = monthlyPackage else { return nil }
        let settings = PaywallSettingsService.shared.getSettings()
        guard settings.paywallMonthly else { return nil }
        return buildPlanInfo(package: package, weeksPerPeriod: 4, periodName: "month")
    }

    var weeklyPlanInfo: PlanDisplayInfo? {
        guard let package = weeklyPackage else { return nil }
        let settings = PaywallSettingsService.shared.getSettings()
        guard settings.paywallWeekly else { return nil }
        return buildWeeklyPlanInfo(package: package)
    }

    private func buildPlanInfo(package: Package, weeksPerPeriod: Int, periodName: String) -> PlanDisplayInfo {
        let product = package.storeProduct
        let intro = product.introductoryDiscount
        let price = product.price as Decimal
        let priceString = product.localizedPriceString

        // Check for test mode based on period
        let isTestingFreeTrial: Bool
        let testFreeTrialDays: Int
        let testPrice: String

        if periodName == "year" {
            isTestingFreeTrial = testYearlyFreeTrial
            testFreeTrialDays = testYearlyFreeTrialDays
            testPrice = testYearlyPrice
        } else {
            isTestingFreeTrial = testMonthlyFreeTrial
            testFreeTrialDays = testMonthlyFreeTrialDays
            testPrice = testMonthlyPrice
        }

        // Calculate per-week price
        let perWeekPrice = NSDecimalNumber(decimal: price / Decimal(weeksPerPeriod)).doubleValue
        let currencySymbol = extractCurrencySymbol(from: priceString)
        let perWeekFormatted = String(format: "%.2f", perWeekPrice)

        // Title with per-week price (YEARLY, MONTHLY)
        let title = "\(periodName.uppercased())LY (Only \(currencySymbol)\(perWeekFormatted)/week)"

        // Determine intro offer type
        let isFreeIntro = intro != nil && intro!.price == 0
        let isPaidIntro = intro != nil && (intro!.price as Decimal) > 0

        var priceInfo: String
        var secondaryInfo: String
        var isFreeOffer = false

        // DEBUG: Test free trial override
        if isTestingFreeTrial {
            let unit = testFreeTrialDays == 1 ? "day" : "days"
            priceInfo = "FREE for \(testFreeTrialDays) \(unit)"
            secondaryInfo = "then \(testPrice)/\(periodName)"
            isFreeOffer = true
        } else if isFreeIntro, let intro = intro {
            // Real free trial from App Store
            let units = intro.subscriptionPeriod.value
            let unit = formatPeriodUnit(intro.subscriptionPeriod.unit, value: units)
            priceInfo = "FREE for \(units) \(unit)"
            secondaryInfo = "then \(priceString)/\(periodName)"
            isFreeOffer = true
        } else if isPaidIntro, let intro = intro {
            // Paid intro offer
            let introPrice = intro.localizedPriceString
            let units = intro.subscriptionPeriod.value
            let unit = formatPeriodUnit(intro.subscriptionPeriod.unit, value: units)
            priceInfo = "\(introPrice) first \(unit)"
            secondaryInfo = "then \(priceString)/\(periodName)"
        } else {
            // No intro
            priceInfo = priceString
            secondaryInfo = "Billed \(periodName)ly"
        }

        // Calculate savings badge
        let savingsBadge = calculateSavingsVsWeekly(price: price, weeksPerPeriod: weeksPerPeriod)

        return PlanDisplayInfo(
            title: title,
            priceInfo: priceInfo,
            secondaryInfo: secondaryInfo,
            badge: savingsBadge,
            badgeColor: .gray,  // Gray text badge like Quiz Maker AI
            isFreeOffer: isFreeOffer
        )
    }

    private func buildWeeklyPlanInfo(package: Package) -> PlanDisplayInfo {
        let product = package.storeProduct
        let intro = product.introductoryDiscount
        let priceString = product.localizedPriceString

        let isFreeIntro = intro != nil && intro!.price == 0
        let isPaidIntro = intro != nil && (intro!.price as Decimal) > 0

        var priceInfo: String
        var secondaryInfo: String
        var badge: String? = nil
        var badgeColor: Color = .orange
        var isFreeOffer = false

        // DEBUG: Test paid intro override (takes priority)
        if testWeeklyPaidIntro {
            priceInfo = "\(testWeeklyIntroPrice) first week"
            secondaryInfo = "then \(testWeeklyPrice)/week"
            badge = "MOST POPULAR"
            badgeColor = .orange
        }
        // DEBUG: Test free trial override
        else if testWeeklyFreeTrial {
            let unit = testWeeklyFreeTrialDays == 1 ? "day" : "days"
            priceInfo = "FREE for \(testWeeklyFreeTrialDays) \(unit)"
            secondaryInfo = "then \(testWeeklyPrice)/week"
            badge = "TRY FREE"
            badgeColor = Color(hex: "#1A9E6D")
            isFreeOffer = true
        }
        // Real free trial from App Store
        else if isFreeIntro, let intro = intro {
            let units = intro.subscriptionPeriod.value
            let unit = formatPeriodUnit(intro.subscriptionPeriod.unit, value: units)
            priceInfo = "FREE for \(units) \(unit)"
            secondaryInfo = "then \(priceString)/week"
            badge = "TRY FREE"
            badgeColor = Color(hex: "#1A9E6D")
            isFreeOffer = true
        }
        // Real paid intro from App Store
        else if isPaidIntro, let intro = intro {
            let introPrice = intro.localizedPriceString
            priceInfo = "\(introPrice) first week"
            secondaryInfo = "then \(priceString)/week"
            badge = "MOST POPULAR"
            badgeColor = .orange
        }
        // No intro
        else {
            priceInfo = priceString
            secondaryInfo = "Billed weekly"
        }

        return PlanDisplayInfo(
            title: "WEEKLY",
            priceInfo: priceInfo,
            secondaryInfo: secondaryInfo,
            badge: badge,
            badgeColor: badgeColor,
            isFreeOffer: isFreeOffer
        )
    }

    private func extractCurrencySymbol(from priceString: String) -> String {
        // Find first non-digit, non-decimal character
        for char in priceString {
            if !char.isNumber && char != "." && char != "," && char != " " {
                return String(char)
            }
        }
        return "$"
    }

    private func formatPeriodUnit(_ unit: SubscriptionPeriod.Unit, value: Int) -> String {
        switch unit {
        case .day: return value == 1 ? "day" : "days"
        case .week: return value == 1 ? "week" : "weeks"
        case .month: return value == 1 ? "month" : "months"
        case .year: return value == 1 ? "year" : "years"
        @unknown default: return "period"
        }
    }

    private func calculateSavingsVsWeekly(price: Decimal, weeksPerPeriod: Int) -> String? {
        guard let weeklyPackage = weeklyPackage else { return nil }
        let weeklyPrice = weeklyPackage.storeProduct.price as Decimal
        let weeklyAnnualized = weeklyPrice * Decimal(weeksPerPeriod)
        guard weeklyAnnualized > 0 else { return nil }
        let savings = ((weeklyAnnualized - price) / weeklyAnnualized) * 100
        let savingsInt = Int(NSDecimalNumber(decimal: savings).doubleValue)
        return savingsInt > 0 ? "SAVE \(savingsInt)%" : nil
    }

    // MARK: - Button Text

    var buttonText: String {
        // Check for test free trial flags first
        switch selectedPlan {
        case "yearly":
            if testYearlyFreeTrial { return "Try For FREE" }
        case "monthly":
            if testMonthlyFreeTrial { return "Try For FREE" }
        case "weekly":
            if testWeeklyFreeTrial { return "Try For FREE" }
        default:
            break
        }

        // Check real intro offers
        let package: Package?
        switch selectedPlan {
        case "yearly": package = yearlyPackage
        case "monthly": package = monthlyPackage
        case "weekly": package = weeklyPackage
        default: package = nil
        }

        guard let pkg = package else { return "Subscribe" }
        let intro = pkg.storeProduct.introductoryDiscount

        // Free trial shows "Try For FREE", everything else shows "Continue"
        if let intro = intro, intro.price == 0 {
            return "Try For FREE"
        }
        return "Continue"
    }

    // MARK: - Load Offering

    func loadOffering(closeDelay: Int) {
        totalSeconds = closeDelay
        secondsRemaining = closeDelay
        canClose = closeDelay == 0

        Task {
            if let offerings = await SubscriptionService.shared.getOfferings(),
               let offering = offerings.current {
                self.offering = offering
                self.yearlyPackage = offering.annual
                self.monthlyPackage = offering.monthly
                self.weeklyPackage = offering.weekly

                // Smart default selection
                selectDefaultPlan()

                self.isLoading = false
                startCloseTimer()
            } else {
                self.isLoading = false
                self.errorMessage = "Failed to load subscription options"
                self.showError = true
            }
        }
    }

    private func selectDefaultPlan() {
        let settings = PaywallSettingsService.shared.getSettings()

        // Check if weekly has paid intro (most attractive offer)
        if let weeklyPackage = weeklyPackage,
           let intro = weeklyPackage.storeProduct.introductoryDiscount,
           (intro.price as Decimal) > 0,
           settings.paywallWeekly {
            selectedPlan = "weekly"
            return
        }

        // Otherwise prefer yearly
        if yearlyPackage != nil && settings.paywallYearly {
            selectedPlan = "yearly"
            return
        }

        // Fallback to monthly
        if monthlyPackage != nil && settings.paywallMonthly {
            selectedPlan = "monthly"
            return
        }

        // Final fallback to weekly
        if weeklyPackage != nil && settings.paywallWeekly {
            selectedPlan = "weekly"
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
        rotationTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.25)) {
                    if self.iconRotation == 0 {
                        self.iconRotation = 5
                    } else if self.iconRotation > 0 {
                        self.iconRotation = -5
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

    func handlePurchase(onSuccess: @escaping () -> Void) {
        let package: Package?
        switch selectedPlan {
        case "yearly": package = yearlyPackage
        case "monthly": package = monthlyPackage
        case "weekly": package = weeklyPackage
        default: package = nil
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
