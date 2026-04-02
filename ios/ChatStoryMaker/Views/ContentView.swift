//
//  ContentView.swift
//  Textery
//
//  Main tab bar container
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            TabView {
                HomeView()
                    .tabItem {
                        Label("Stories", systemImage: "bubble.left.and.bubble.right.fill")
                    }

                AIGeneratorView()
                    .tabItem {
                        Label("Generate", systemImage: "sparkles")
                    }

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
            }
            .tint(Color(hex: "#007AFF")) // iOS Blue for tab bar

            // Onboarding overlay
            if showOnboarding {
                OnboardingView(showOnboarding: $showOnboarding)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            let settings = PaywallSettingsService.shared.getSettings()

            if !hasCompletedOnboarding {
                // New user: show onboarding first, then paywall
                showOnboarding = true
            } else if settings.showPaywallOnStart && !SubscriptionService.shared.hasPremiumAccessCached() {
                // Returning user without premium: show paywall
                showPaywall = true
            }
        }
        .onChange(of: showOnboarding) { _, newValue in
            if !newValue {
                hasCompletedOnboarding = true
                let settings = PaywallSettingsService.shared.getSettings()
                // Show paywall after onboarding completes (if not premium)
                if settings.showPaywallOnStart && !SubscriptionService.shared.hasPremiumAccessCached() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showPaywall = true
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(isLimitTriggered: false, showCloseButtonImmediately: false)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Conversation.self, Character.self, Message.self], inMemory: true)
}

#Preview("Onboarding") {
    OnboardingView(showOnboarding: .constant(true))
}
