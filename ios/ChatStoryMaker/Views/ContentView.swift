//
//  ContentView.swift
//  Textory
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

                ExportHistoryTabView()
                    .tabItem {
                        Label("Exports", systemImage: "square.and.arrow.up.on.square")
                    }

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
            }

            // Onboarding overlay
            if showOnboarding {
                OnboardingView(showOnboarding: $showOnboarding)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            if !hasCompletedOnboarding {
                // New user: show onboarding first, then paywall
                showOnboarding = true
            } else if !SubscriptionService.shared.hasPremiumAccess() {
                // Returning user without premium: show paywall
                showPaywall = true
            }
        }
        .onChange(of: showOnboarding) { _, newValue in
            if !newValue {
                hasCompletedOnboarding = true
                // Show paywall after onboarding completes (if not premium)
                if !SubscriptionService.shared.hasPremiumAccess() {
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
