//
//  SettingsView.swift
//  Textery
//
//  App settings screen
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @State private var soundsEnabled = AudioService.shared.soundsEnabled
    @State private var showOnboarding = false
    @State private var showPaywall = false
    @State private var isPremium = SubscriptionService.shared.hasPremiumAccessCached()
    @State private var screenshotSeedMessage: String?

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
                    Button("Load Screenshot Mock Data") {
                        do {
                            try ScreenshotMockDataService.shared.seedAppStoreMockData(in: modelContext)
                            screenshotSeedMessage = "App Store mock conversations loaded."
                        } catch {
                            screenshotSeedMessage = "Failed to load mock data: \(error.localizedDescription)"
                        }
                    }

                    Button("Reset Usage Limits") {
                        LimitTrackingService.shared.resetAllCounts()
                    }

                    Button("Refresh Premium Status") {
                        Task {
                            _ = await SubscriptionService.shared.hasPremiumAccess()
                            await MainActor.run {
                                isPremium = SubscriptionService.shared.hasPremiumAccessCached()
                            }
                        }
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
            .alert("Screenshot Mock Data", isPresented: Binding(
                get: { screenshotSeedMessage != nil },
                set: { if !$0 { screenshotSeedMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(screenshotSeedMessage ?? "")
            }
            .onChange(of: showPaywall) { _, _ in
                isPremium = SubscriptionService.shared.hasPremiumAccessCached()
            }
        }
    }
}

#Preview {
    SettingsView()
}
