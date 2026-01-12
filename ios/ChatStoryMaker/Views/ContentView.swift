//
//  ContentView.swift
//  ChatStoryMaker
//
//  Main tab bar container
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
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
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Conversation.self, Character.self, Message.self], inMemory: true)
}
