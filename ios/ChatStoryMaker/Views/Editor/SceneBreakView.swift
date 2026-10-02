//
//  SceneBreakView.swift
//  Textery
//
//  Inline scene break divider shown between messages in the editor
//

import SwiftUI

struct SceneBreakView: View {
    let sceneBreak: SceneBreak
    var onDelete: () -> Void

    private let coral = Color(red: 224/255, green: 123/255, blue: 94/255)

    var body: some View {
        HStack(spacing: 10) {
            line
            content
            line

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
        }
        .padding(.vertical, 6)
    }

    private var line: some View {
        Rectangle()
            .fill(coral.opacity(0.25))
            .frame(height: 1)
    }

    private var content: some View {
        VStack(spacing: 2) {
            Text(sceneBreak.title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(coral)
                .multilineTextAlignment(.center)
            if let subtitle = sceneBreak.subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 10)
        .fixedSize(horizontal: true, vertical: false)
    }
}

// Inline button to add a scene break between two messages
struct AddSceneBreakButton: View {
    var onAdd: (String) -> Void
    @State private var showPrompt = false
    @State private var title = ""

    private let coral = Color(red: 224/255, green: 123/255, blue: 94/255)

    var body: some View {
        HStack {
            Spacer()
            Button { showPrompt = true } label: {
                Label("Scene Break", systemImage: "plus")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(coral)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(coral.opacity(0.1))
                    .clipShape(Capsule())
            }
            Spacer()
        }
        .alert("Add Scene Break", isPresented: $showPrompt) {
            TextField("Scene title (e.g. Next Day)", text: $title)
            Button("Cancel", role: .cancel) { title = "" }
            Button("Add") {
                let t = title.trimmingCharacters(in: .whitespaces)
                if !t.isEmpty { onAdd(t) }
                title = ""
            }
        } message: {
            Text("Give this scene a short title")
        }
    }
}
