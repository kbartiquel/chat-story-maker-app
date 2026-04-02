//
//  TexteryApp.swift
//  Textery
//
//  Created with Claude Code
//  Copyright © 2024 KimBytes. All rights reserved.
//

import SwiftUI
import SwiftData
import Aptabase
import RevenueCat

@main
struct TexteryApp: App {
    let container: ModelContainer

    init() {
        // Initialize analytics
        AnalyticsService.shared.initialize()
        AnalyticsService.shared.trackAppLaunch()

        // Initialize RevenueCat
        Purchases.logLevel = .error
        Purchases.configure(
            withAPIKey: Config.revenueCatAPIKey,
            appUserID: TrackingService.shared.currentUserID
        )

        do {
            let schema = Schema([Conversation.self, Character.self, Message.self, Folder.self, ExportHistory.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            // If migration fails, try to delete and recreate
            print("ModelContainer error: \(error). Attempting to reset database...")
            do {
                // Delete existing store and create fresh
                let schema = Schema([Conversation.self, Character.self, Message.self, Folder.self, ExportHistory.self])
                let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

                // Try to delete old data
                let url = config.url
                try? FileManager.default.removeItem(at: url)
                // Also remove related files
                let walURL = url.deletingPathExtension().appendingPathExtension("sqlite-wal")
                let shmURL = url.deletingPathExtension().appendingPathExtension("sqlite-shm")
                try? FileManager.default.removeItem(at: walURL)
                try? FileManager.default.removeItem(at: shmURL)

                container = try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("Failed to create ModelContainer after reset: \(error)")
            }
        }
    }

    @AppStorage("hasSeenDisclaimer") private var hasSeenDisclaimer = false
    @State private var showDisclaimer = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    if !hasSeenDisclaimer {
                        showDisclaimer = true
                    }
                }
                .sheet(isPresented: $showDisclaimer) {
                    DisclaimerView(isPresented: $showDisclaimer)
                        .interactiveDismissDisabled()
                        .onDisappear {
                            hasSeenDisclaimer = true
                        }
                }
        }
        .modelContainer(container)
    }

}
