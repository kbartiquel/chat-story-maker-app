//
//  ToggleRow.swift
//  Textory
//
//  Label on left, toggle on right
//

import SwiftUI

struct ToggleRow: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(.accentColor)
                        .frame(width: 24)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    Form {
        ToggleRow(title: "Sound Effects", icon: "speaker.wave.2.fill", isOn: .constant(true))
        ToggleRow(title: "Show Keyboard", subtitle: "Display keyboard during export", isOn: .constant(false))
        ToggleRow(title: "Dark Mode", isOn: .constant(true))
    }
}
