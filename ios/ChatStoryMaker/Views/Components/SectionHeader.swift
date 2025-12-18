//
//  SectionHeader.swift
//  ChatStoryMaker
//
//  Gray uppercase text for section titles
//

import SwiftUI

struct SectionHeader: View {
    let title: String
    var showDivider: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if showDivider {
                Divider()
            }

            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .tracking(0.5)
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        SectionHeader(title: "Settings")
        Text("Some content here")

        SectionHeader(title: "Export Options", showDivider: true)
        Text("More content")
    }
    .padding()
}
