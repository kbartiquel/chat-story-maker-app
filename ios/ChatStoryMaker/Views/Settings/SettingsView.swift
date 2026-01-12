//
//  SettingsView.swift
//  Textory
//
//  App settings screen
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @State private var soundsEnabled = AudioService.shared.soundsEnabled
    @State private var showOnboarding = false
    @State private var showPaywall = false
    @State private var isPremium = SubscriptionService.shared.hasPremiumAccess()

    var body: some View {
        NavigationStack {
            List {
                // Premium section
                Section {
                    if isPremium {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                            Text("Premium Active")
                                .fontWeight(.semibold)
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.purple)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Upgrade to Premium")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    Text("Unlimited exports & AI generations")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }

                        // Usage stats
                        let usage = LimitTrackingService.shared.getUsageSummary()
                        HStack {
                            Text("Video Exports")
                            Spacer()
                            Text("\(usage.videoExports)/\(usage.videoLimit)")
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("AI Generations")
                            Spacer()
                            Text("\(usage.aiGenerations)/\(usage.aiLimit)")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Subscription")
                }

                // App settings
                Section {
                    Toggle(isOn: $soundsEnabled) {
                        Label("Sound Effects", systemImage: "speaker.wave.2.fill")
                    }
                    .onChange(of: soundsEnabled) { _, newValue in
                        AudioService.shared.soundsEnabled = newValue
                    }
                } header: {
                    Text("Preferences")
                }

                // Help section
                Section {
                    Button {
                        showOnboarding = true
                    } label: {
                        Label("Replay Introduction", systemImage: "arrow.counterclockwise")
                    }
                } header: {
                    Text("Help")
                }

                // About section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About")
                }

                // Debug section (for testing)
                #if DEBUG
                Section {
                    Button("Reset Usage Limits") {
                        LimitTrackingService.shared.resetAllCounts()
                    }

                    Button(isPremium ? "Revoke Premium (Test)" : "Grant Premium (Test)") {
                        if isPremium {
                            SubscriptionService.shared.revokePremiumAccess()
                        } else {
                            SubscriptionService.shared.grantPremiumAccess()
                        }
                        isPremium = SubscriptionService.shared.hasPremiumAccess()
                    }
                } header: {
                    Text("Debug")
                }
                #endif
            }
            .navigationTitle("Settings")
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView(showOnboarding: $showOnboarding)
            }
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallView(showCloseButtonImmediately: true)
            }
            .onChange(of: showPaywall) { _, _ in
                isPremium = SubscriptionService.shared.hasPremiumAccess()
            }
        }
    }
}

#Preview {
    SettingsView()
}
