//
//  PaywallView.swift
//  Textery
//
//  Quiz Maker AI custom paywall v3 style adapted for Textery
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
            } else {
                paywallContent
            }

            if viewModel.isPurchasing {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#E07B5E")))
            }
        }
        .onAppear {
            let settings = PaywallSettingsService.shared.getSettings()
            let delay = showCloseButtonImmediately ? 0 : (isLimitTriggered ? settings.paywallCloseButtonDelayOnLimit : settings.paywallCloseButtonDelay)
            let source = showCloseButtonImmediately ? "settings" : (isLimitTriggered ? "limit_reached" : "app_launch")

            viewModel.loadOffering(
                closeDelay: delay,
                showLoadingIndicator: settings.paywallShowLoadingIndicator,
                source: source
            )

            AnalyticsService.shared.trackPaywallShown(source: source)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    private var paywallContent: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 24)
                    .padding(.top, 4)
                    .padding(.bottom, 14)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        heroSection
                            .frame(maxWidth: .infinity, alignment: .top)
                    }
                    .padding(.horizontal, 24)
                    .frame(minHeight: max(0, geometry.size.height - 250), alignment: .top)
                }

                bottomSection
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.0),
                                Color.white.opacity(0.92),
                                Color.white
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea(edges: .bottom)
                    )
            }
        }
    }

    private var topBar: some View {
        HStack {
            SizedBox(width: 80) {
                if !viewModel.hardPaywall {
                    if viewModel.canClose {
                        Button(action: {
                            AnalyticsService.shared.trackPaywallDismissed()
                            dismiss()
                        }) {
                            if viewModel.totalSeconds == 0 {
                                Text("Close")
                                    .font(.system(size: 14))
                                    .foregroundColor(.black.opacity(0.4))
                            } else {
                                Image(systemName: "xmark")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.black.opacity(0.4))
                                    .frame(width: 32, height: 32)
                            }
                        }
                    } else if viewModel.showLoadingIndicator {
                        ZStack {
                            Circle()
                                .stroke(Color.black.opacity(0.08), lineWidth: 2)
                            Circle()
                                .trim(from: 0, to: viewModel.progress)
                                .stroke(Color.black.opacity(0.3), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                        }
                        .frame(width: 26, height: 26)
                    }
                }
            }

            Spacer()

            HStack(spacing: 8) {
                Image("AppIconImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .scaleEffect(viewModel.iconPulse)
                    .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: viewModel.iconPulse)

                Text("Textery")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black.opacity(0.88))
            }

            Spacer()

            SizedBox(width: 80) {
                Button(action: {
                    viewModel.restorePurchases(onSuccess: { dismiss() })
                }) {
                    if viewModel.isRestoring {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#E07B5E")))
                            .scaleEffect(0.8)
                    } else {
                        Text("Restore")
                            .font(.system(size: 13))
                            .foregroundColor(.black.opacity(0.4))
                    }
                }
                .disabled(viewModel.isRestoring)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private var heroSection: some View {
        VStack(spacing: 18) {
            Text(isLimitTriggered ? "Keep Every Story\nFlowing" : "Create Viral Chat\nVideos Faster")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.black.opacity(0.88))
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            Text(isLimitTriggered ? "Unlock unlimited exports and AI story generation" : "Unlimited exports, smarter creation, zero limits")
                .font(.system(size: 14))
                .foregroundColor(.black.opacity(0.4))
                .padding(.top, -8)

            VStack(spacing: 10) {
                featureRow(icon: "video.fill", title: "Unlimited Video Exports", subtitle: "Export every story for TikTok, Reels, and Shorts")
                featureRow(icon: "sparkles", title: "Unlimited AI Story Generation", subtitle: "Generate more dramatic scenes in seconds")
                featureRow(icon: "text.bubble.fill", title: "Creator-Ready Story Editor", subtitle: "Fine-tune pacing, characters, and twists")
                featureRow(icon: "chart.line.uptrend.xyaxis", title: "No More Usage Limits", subtitle: "Create whenever inspiration hits")
            }
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var bottomSection: some View {
        VStack(spacing: 10) {
            if let plan = viewModel.lifetimePlanInfo {
                planTile(plan: plan)
            }
            if let plan = viewModel.yearlyPlanInfo {
                planTile(plan: plan)
            }
            if let plan = viewModel.monthlyPlanInfo {
                planTile(plan: plan)
            }
            if let plan = viewModel.weeklyPlanInfo {
                planTile(plan: plan)
            }

            Spacer().frame(height: 8)

            Button(action: {
                viewModel.handlePurchase(onSuccess: { dismiss() })
            }) {
                Text(viewModel.buttonText)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(hex: "#E07B5E"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(viewModel.isPurchasing)

            HStack {
                HStack(spacing: 0) {
                    footerLink("Privacy", urlString: "https://textery-6e482.web.app/privacy")
                    Text(" | ")
                        .font(.system(size: 13))
                        .foregroundColor(.black.opacity(0.25))
                    footerLink("Terms", urlString: "https://textery-6e482.web.app/terms")
                }

                Spacer()

                Text("Cancel Anytime")
                    .font(.system(size: 13))
                    .foregroundColor(.black.opacity(0.35))
            }
            .padding(.top, 2)
            .padding(.bottom, 5)
        }
    }

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "#E07B5E").opacity(0.12))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(hex: "#E07B5E"))
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black.opacity(0.87))

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.black.opacity(0.4))
            }

            Spacer()
        }
    }

    private func planTile(plan: PlanTileInfo) -> some View {
        let isSelected = viewModel.selectedPlan == plan.id

        return Button(action: {
            viewModel.selectPlan(plan.id)
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    if let label = plan.label {
                        Text(label)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(isSelected ? Color(hex: "#E07B5E") : .black.opacity(0.4))
                    }

                    if let highlightPrefix = plan.highlightPrefix, let highlightText = plan.highlightText {
                        (
                            Text(highlightPrefix)
                                .foregroundColor(.black.opacity(0.87))
                            +
                            Text(highlightText)
                                .foregroundColor(Color(hex: "#E07B5E"))
                        )
                        .font(.system(size: 17, weight: .bold))
                    } else {
                        Text(plan.priceText)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.black.opacity(0.87))
                    }

                    Text(plan.periodText)
                        .font(.system(size: 13))
                        .foregroundColor(.black.opacity(0.45))
                }

                Spacer(minLength: 12)

                if let badge = plan.badge, !badge.isEmpty {
                    Text(badge)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "#E07B5E"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#E07B5E").opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(isSelected ? Color(hex: "#E07B5E").opacity(0.08) : Color.black.opacity(0.03))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color(hex: "#E07B5E") : Color.black.opacity(0.1), lineWidth: isSelected ? 1.5 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private func footerLink(_ title: String, urlString: String) -> some View {
        Link(destination: URL(string: urlString)!) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.black.opacity(0.35))
        }
    }
}

private struct SizedBox<Content: View>: View {
    let width: CGFloat
    let content: Content

    init(width: CGFloat, @ViewBuilder content: () -> Content) {
        self.width = width
        self.content = content()
    }

    var body: some View {
        content.frame(width: width)
    }
}

struct PlanTileInfo {
    let id: String
    let label: String?
    let priceText: String
    let periodText: String
    let badge: String?
    let highlightPrefix: String?
    let highlightText: String?
}

@MainActor
final class PaywallViewModel: ObservableObject {
    @Published var offering: Offering?
    @Published var yearlyPackage: Package?
    @Published var monthlyPackage: Package?
    @Published var weeklyPackage: Package?
    @Published var lifetimePackage: Package?
    @Published var selectedPlan: String = "yearly"
    @Published var isLoading = true
    @Published var isPurchasing = false
    @Published var isRestoring = false
    @Published var canClose = false
    @Published var progress: CGFloat = 0
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var iconPulse: CGFloat = 1.0

    var totalSeconds = 0
    var hardPaywall = false
    var showLoadingIndicator = true

    private var timer: Timer?
    private var secondsRemaining = 0
    private var pulseTimer: Timer?
    private var paywallSource = "app_launch"

    init() {
        startPulseAnimation()
    }

    var yearlyPlanInfo: PlanTileInfo? {
        let settings = PaywallSettingsService.shared.getSettings()
        guard settings.paywallYearly, let package = yearlyPackage else { return nil }
        return buildSubscriptionPlanInfo(planID: "yearly", package: package, label: "Auto Renewal", badge: calculateYearlySavings())
    }

    var monthlyPlanInfo: PlanTileInfo? {
        let settings = PaywallSettingsService.shared.getSettings()
        guard settings.paywallMonthly, let package = monthlyPackage else { return nil }
        return buildSubscriptionPlanInfo(planID: "monthly", package: package, label: "Auto Renewal", badge: nil)
    }

    var weeklyPlanInfo: PlanTileInfo? {
        let settings = PaywallSettingsService.shared.getSettings()
        guard settings.paywallWeekly, let package = weeklyPackage else { return nil }
        return buildSubscriptionPlanInfo(planID: "weekly", package: package, label: "Auto Renewal", badge: nil)
    }

    var lifetimePlanInfo: PlanTileInfo? {
        let settings = PaywallSettingsService.shared.getSettings()
        guard settings.paywallLifetime, let package = lifetimePackage else { return nil }
        return PlanTileInfo(
            id: "lifetime",
            label: "ONE TIME",
            priceText: package.storeProduct.localizedPriceString,
            periodText: "/ Lifetime",
            badge: "Best Value",
            highlightPrefix: nil,
            highlightText: nil
        )
    }

    var buttonText: String {
        selectedPlanHasFreeTrial ? "Try for FREE" : "Continue"
    }

    private var selectedPlanHasFreeTrial: Bool {
        package(for: selectedPlan)?.storeProduct.introductoryDiscount?.price == 0
    }

    func loadOffering(closeDelay: Int, showLoadingIndicator: Bool, source: String) {
        self.totalSeconds = closeDelay
        self.secondsRemaining = closeDelay
        self.canClose = closeDelay == 0
        self.showLoadingIndicator = showLoadingIndicator
        self.paywallSource = source
        self.hardPaywall = PaywallSettingsService.shared.getSettings().hardPaywall

        Task {
            if let offerings = await SubscriptionService.shared.getOfferings(),
               let offering = offerings.current {
                self.offering = offering
                self.yearlyPackage = offering.annual
                self.monthlyPackage = offering.monthly
                self.weeklyPackage = offering.weekly
                self.lifetimePackage = offering.lifetime
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

    func selectPlan(_ plan: String) {
        selectedPlan = plan
    }

    func handlePurchase(onSuccess: @escaping () -> Void) {
        guard let package = package(for: selectedPlan) else { return }

        isPurchasing = true

        Task {
            let result = await SubscriptionService.shared.purchase(package: package)
            isPurchasing = false

            switch result {
            case .success:
                AnalyticsService.shared.trackPurchaseCompleted(plan: selectedPlan)
                onSuccess()
            case .failure(let error):
                AnalyticsService.shared.trackPurchaseFailed(plan: selectedPlan, error: error.localizedDescription)
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
                AnalyticsService.shared.trackRestorePurchases(success: true)
                onSuccess()
            case .failure(let error):
                AnalyticsService.shared.trackRestorePurchases(success: false)
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func package(for plan: String) -> Package? {
        switch plan {
        case "yearly": return yearlyPackage
        case "monthly": return monthlyPackage
        case "weekly": return weeklyPackage
        case "lifetime": return lifetimePackage
        default: return nil
        }
    }

    private func selectDefaultPlan() {
        let settings = PaywallSettingsService.shared.getSettings()

        let shownPlans: [(String, Package?, Bool)] = [
            ("yearly", yearlyPackage, settings.paywallYearly),
            ("monthly", monthlyPackage, settings.paywallMonthly),
            ("weekly", weeklyPackage, settings.paywallWeekly)
        ]

        if let freeTrialPlan = shownPlans.first(where: { $0.2 && $0.1?.storeProduct.introductoryDiscount?.price == 0 })?.0 {
            selectedPlan = freeTrialPlan
            return
        }

        if settings.paywallYearly, yearlyPackage != nil {
            selectedPlan = "yearly"
        } else if settings.paywallMonthly, monthlyPackage != nil {
            selectedPlan = "monthly"
        } else if settings.paywallWeekly, weeklyPackage != nil {
            selectedPlan = "weekly"
        } else if settings.paywallLifetime, lifetimePackage != nil {
            selectedPlan = "lifetime"
        }
    }

    private func buildSubscriptionPlanInfo(planID: String, package: Package, label: String, badge: String?) -> PlanTileInfo {
        let product = package.storeProduct

        if let intro = product.introductoryDiscount {
            if intro.price == 0 {
                let units = intro.subscriptionPeriod.value
                let freeText = "\(units) \(formatPeriodUnit(intro.subscriptionPeriod.unit, value: units)) free"
                return PlanTileInfo(
                    id: planID,
                    label: nil,
                    priceText: "",
                    periodText: "then \(product.localizedPriceString)/\(periodLabel(planID))",
                    badge: badge,
                    highlightPrefix: "\(periodLabelLong(planID)) · ",
                    highlightText: freeText
                )
            }

            let introLength = "\(intro.subscriptionPeriod.value)-\(singularUnit(intro.subscriptionPeriod.unit).capitalized)"
            return PlanTileInfo(
                id: planID,
                label: nil,
                priceText: "\(intro.localizedPriceString) for \(introLength)",
                periodText: "then \(product.localizedPriceString)/\(periodLabel(planID))",
                badge: badge,
                highlightPrefix: nil,
                highlightText: nil
            )
        }

        return PlanTileInfo(
            id: planID,
            label: label,
            priceText: product.localizedPriceString,
            periodText: "/ \(periodLabel(planID).capitalized)",
            badge: badge,
            highlightPrefix: nil,
            highlightText: nil
        )
    }

    private func calculateYearlySavings() -> String? {
        guard let yearlyPackage = yearlyPackage else { return nil }
        let yearlyPrice = yearlyPackage.storeProduct.price as Decimal
        let settings = PaywallSettingsService.shared.getSettings()

        if settings.paywallWeekly, let weeklyPackage = weeklyPackage {
            let weeklyAnnualized = (weeklyPackage.storeProduct.price as Decimal) * 52
            guard weeklyAnnualized > 0 else { return nil }
            let savings = ((weeklyAnnualized - yearlyPrice) / weeklyAnnualized * 100).roundedDecimalToInt
            return savings > 0 ? "Save \(savings)%" : nil
        }

        if settings.paywallMonthly, let monthlyPackage = monthlyPackage {
            let monthlyAnnualized = (monthlyPackage.storeProduct.price as Decimal) * 12
            guard monthlyAnnualized > 0 else { return nil }
            let savings = ((monthlyAnnualized - yearlyPrice) / monthlyAnnualized * 100).roundedDecimalToInt
            return savings > 0 ? "Save \(savings)%" : nil
        }

        return nil
    }

    private func periodLabelLong(_ plan: String) -> String {
        switch plan {
        case "weekly": return "Weekly"
        case "monthly": return "Monthly"
        case "yearly": return "Yearly"
        default: return ""
        }
    }

    private func periodLabel(_ plan: String) -> String {
        switch plan {
        case "weekly": return "week"
        case "monthly": return "month"
        case "yearly": return "year"
        default: return "period"
        }
    }

    private func singularUnit(_ unit: SubscriptionPeriod.Unit) -> String {
        switch unit {
        case .day: return "day"
        case .week: return "week"
        case .month: return "month"
        case .year: return "year"
        @unknown default: return "period"
        }
    }

    private func formatPeriodUnit(_ unit: SubscriptionPeriod.Unit, value: Int) -> String {
        let label = singularUnit(unit)
        return value == 1 ? label : "\(label)s"
    }

    private func startCloseTimer() {
        guard totalSeconds > 0 else { return }

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self else { return }

            Task { @MainActor in
                if self.secondsRemaining > 0 {
                    self.secondsRemaining -= 1
                    self.progress = CGFloat(self.totalSeconds - self.secondsRemaining) / CGFloat(max(self.totalSeconds, 1))
                } else {
                    self.canClose = true
                    timer.invalidate()
                }
            }
        }
    }

    private func startPulseAnimation() {
        pulseTimer?.invalidate()
        pulseTimer = Timer.scheduledTimer(withTimeInterval: 0.9, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.iconPulse = self.iconPulse == 1.0 ? 1.08 : 1.0
            }
        }
    }

    deinit {
        timer?.invalidate()
        pulseTimer?.invalidate()
    }
}

private extension Decimal {
    var roundedDecimalToInt: Int {
        Int(NSDecimalNumber(decimal: self).doubleValue.rounded())
    }
}

#Preview {
    PaywallView()
}
