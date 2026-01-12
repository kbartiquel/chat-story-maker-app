//
//  OnboardingView.swift
//  Textory
//
//  Created with Claude Code
//

import SwiftUI

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @State private var currentPage = 0
    @State private var isAnimating = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Create Chat Stories",
            subtitle: "Design fake text conversations that look completely real. Perfect for storytelling and content creation.",
            iconName: "bubble.left.and.bubble.right.fill",
            gradientColors: [Color(hex: "#1A9E6D"), Color(hex: "#2EC4A0")],
            accentColor: .white
        ),
        OnboardingPage(
            title: "AI Writes For You",
            subtitle: "Let AI generate viral chat stories instantly. Choose genre, mood, and watch the magic happen.",
            iconName: "sparkles",
            gradientColors: [Color(hex: "#159957"), Color(hex: "#1DB678")],
            accentColor: .white
        ),
        OnboardingPage(
            title: "Export & Go Viral",
            subtitle: "Turn your chats into videos with typing animations. Ready for TikTok, Instagram, and YouTube.",
            iconName: "play.rectangle.fill",
            gradientColors: [Color(hex: "#11998E"), Color(hex: "#38EF7D")],
            accentColor: .white
        ),
        OnboardingPage(
            title: "Your Story Awaits",
            subtitle: "Join thousands of creators making engaging content. Start your first chat story now!",
            iconName: "heart.fill",
            gradientColors: [Color(hex: "#1A9E6D"), Color(hex: "#45B649")],
            accentColor: .white
        )
    ]

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: pages[currentPage].gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: currentPage)

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 50)

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(
                            page: pages[index],
                            isActive: currentPage == index
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Custom page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(currentPage == index ? Color.white : Color.white.opacity(0.4))
                            .frame(width: currentPage == index ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 32)

                // Action button
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            currentPage += 1
                        }
                        HapticManager.impact(.light)
                        AnalyticsService.shared.trackOnboardingPageViewed(page: currentPage + 1)
                    } else {
                        completeOnboarding(skipped: false)
                    }
                }) {
                    HStack(spacing: 8) {
                        Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
                            .font(.headline)

                        Image(systemName: currentPage < pages.count - 1 ? "arrow.right" : "sparkles")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundColor(pages[currentPage].gradientColors[0])
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            isAnimating = true
            AnalyticsService.shared.trackOnboardingStarted()
            AnalyticsService.shared.trackOnboardingPageViewed(page: 0)
        }
    }

    private func completeOnboarding(skipped: Bool) {
        HapticManager.notification(.success)
        AnalyticsService.shared.trackOnboardingCompleted(skipped: skipped)
        withAnimation(.easeInOut(duration: 0.3)) {
            showOnboarding = false
        }
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let iconName: String
    let gradientColors: [Color]
    let accentColor: Color
}

#Preview {
    OnboardingView(showOnboarding: .constant(true))
}
