//
//  SettingsView.swift
//  ChatStoryMaker
//
//  App settings screen
//

import SwiftUI

struct SettingsView: View {
    @State private var soundsEnabled = AudioService.shared.soundsEnabled

    var body: some View {
        NavigationStack {
            List {
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

                // About section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                        Text("All Features Unlocked")
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
