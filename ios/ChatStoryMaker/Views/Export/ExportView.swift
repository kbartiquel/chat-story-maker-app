//
//  ExportView.swift
//  ChatStoryMaker
//
//  Export settings screen with video/screenshot preview
//

import SwiftUI

struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ExportViewModel

    init(conversation: Conversation) {
        self._viewModel = State(initialValue: ExportViewModel(conversation: conversation))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 24) {
                        // Export type picker
                        ExportTypePickerView(selectedType: $viewModel.settings.exportType)

                        // Preview area
                        VideoPreviewView(
                            conversation: viewModel.conversation,
                            settings: viewModel.settings
                        )

                        // Format picker (video only)
                        if viewModel.settings.exportType == .video {
                            FormatPickerView(selectedFormat: $viewModel.settings.format)
                        }

                        // Settings
                        ExportSettingsSection(settings: $viewModel.settings)

                        // Export button
                        exportButton
                    }
                    .padding()
                }
                .disabled(viewModel.isExporting)
                .blur(radius: viewModel.isExporting ? 3 : 0)

                // Full-screen export progress overlay
                if viewModel.isExporting {
                    ExportProgressOverlay(
                        progress: viewModel.exportProgress,
                        isVideo: viewModel.settings.exportType == .video
                    )
                }
            }
            .navigationTitle(viewModel.settings.exportType == .video ? "Export Video" : "Export Screenshot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .disabled(viewModel.isExporting)
                }
            }
            .sheet(isPresented: $viewModel.showShareSheet) {
                ShareSheet(items: viewModel.shareItems)
            }
            .alert("Export Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
        }
    }

    private var exportButton: some View {
        Button {
            guard !viewModel.isExporting && !viewModel.conversation.messages.isEmpty else { return }
            // Set exporting state immediately for instant UI feedback
            viewModel.isExporting = true
            viewModel.exportProgress = 0
            Task {
                await viewModel.startExport()
            }
        } label: {
            Group {
                if viewModel.isExporting {
                    HStack(spacing: 12) {
                        ProgressView()
                            .tint(.white)
                        if viewModel.settings.exportType == .video {
                            Text("Exporting \(Int(viewModel.exportProgress * 100))%")
                        } else {
                            Text("Generating...")
                        }
                    }
                } else {
                    Label(
                        viewModel.settings.exportType == .video ? "Export Video" : "Export Screenshot",
                        systemImage: viewModel.settings.exportType.icon
                    )
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.canExport ? Color.blue : Color.gray)
            .cornerRadius(12)
        }
        .disabled(!viewModel.canExport)
    }
}

struct ExportTypePickerView: View {
    @Binding var selectedType: ExportType

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export Type")
                .font(.headline)

            HStack(spacing: 12) {
                ForEach(ExportType.allCases, id: \.self) { type in
                    Button(action: {
                        selectedType = type
                        HapticManager.selection()
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: type.icon)
                                .font(.title2)
                            Text(type.displayName)
                                .font(.subheadline)
                                .fontWeight(selectedType == type ? .semibold : .regular)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(selectedType == type ? Color.blue.opacity(0.1) : Color(.systemGray6))
                        .foregroundColor(selectedType == type ? .blue : .primary)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(selectedType == type ? Color.blue : Color.clear, lineWidth: 2)
                        )
                    }
                }
            }
        }
    }
}

struct VideoPreviewView: View {
    let conversation: Conversation
    let settings: ExportSettings

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(settings.darkMode ? Color.black : conversation.theme.backgroundColor)
                .aspectRatio(aspectRatio, contentMode: .fit)
                .overlay(
                    VStack(spacing: 8) {
                        ForEach(conversation.sortedMessages.prefix(3)) { message in
                            let character = conversation.characters.first { $0.id == message.characterID }
                            let isMe = character?.isMe ?? true
                            HStack {
                                if isMe { Spacer() }
                                Text(message.text)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(isMe ? conversation.theme.senderBubbleColor : conversation.theme.receiverBubbleColor)
                                    .foregroundColor(isMe ? conversation.theme.senderTextColor : conversation.theme.receiverTextColor)
                                    .cornerRadius(12)
                                if !isMe { Spacer() }
                            }
                        }
                        if conversation.messages.count > 3 {
                            Text("+ \(conversation.messages.count - 3) more messages")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                )

            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
        }
        .frame(height: 300)
    }

    private var aspectRatio: CGFloat {
        let size = settings.format.resolution
        return size.width / size.height
    }
}

struct FormatPickerView: View {
    @Binding var selectedFormat: ExportFormat

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Format")
                .font(.headline)

            HStack(spacing: 12) {
                ForEach(ExportFormat.allCases, id: \.self) { format in
                    FormatButton(
                        format: format,
                        isSelected: selectedFormat == format,
                        onTap: { selectedFormat = format }
                    )
                }
            }
        }
    }
}

struct FormatButton: View {
    let format: ExportFormat
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Text(format.displayName)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                Text(format.aspectRatio)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .foregroundColor(isSelected ? .blue : .primary)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
}

struct ExportSettingsSection: View {
    @Binding var settings: ExportSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.headline)

            if settings.exportType == .video {
                // Video-specific settings
                VStack(alignment: .leading, spacing: 8) {
                    Text("Typing Speed")
                        .font(.subheadline)
                    Picker("Speed", selection: $settings.typingSpeed) {
                        ForEach(TypingSpeed.allCases, id: \.self) { speed in
                            Text(speed.displayName).tag(speed)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Toggle("Show Keyboard", isOn: $settings.showKeyboard)
                Toggle("Typing Indicator", isOn: $settings.showTypingIndicator)
                Toggle("Sound Effects", isOn: $settings.enableSounds)
            } else {
                // Screenshot-specific settings
                VStack(alignment: .leading, spacing: 8) {
                    Text("Image Quality")
                        .font(.subheadline)
                    Picker("Quality", selection: $settings.imageQuality) {
                        ForEach(ImageQuality.allCases, id: \.self) { quality in
                            Text(quality.displayName).tag(quality)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Toggle("Show Avatars", isOn: $settings.showAvatars)
                Toggle("Show Timestamps", isOn: $settings.showTimestamps)
                Toggle("Show Reactions", isOn: $settings.showReactions)
            }

            // Common settings
            Toggle("Dark Mode", isOn: $settings.darkMode)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Export Progress Overlay

struct ExportProgressOverlay: View {
    let progress: Double
    let isVideo: Bool

    @State private var isAnimating = false
    @State private var simulatedPercent: Int = 1

    func statusText(for displayProgress: Double) -> String {
        if displayProgress < 0.1 {
            return "Preparing..."
        } else if displayProgress < 0.8 {
            return isVideo ? "Rendering frames..." : "Generating image..."
        } else if displayProgress < 0.95 {
            return isVideo ? "Adding audio..." : "Finishing up..."
        } else {
            return "Almost done..."
        }
    }

    // Display the higher of simulated or real progress
    var displayProgress: Double {
        max(Double(simulatedPercent) / 100.0, progress)
    }

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            // Progress card
            VStack(spacing: 24) {
                // Animated icon
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 8)
                        .frame(width: 100, height: 100)

                    // Progress ring
                    Circle()
                        .trim(from: 0, to: displayProgress)
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))

                    // Percentage text
                    VStack(spacing: 2) {
                        Text("\(Int(displayProgress * 100))")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("%")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                // Status text
                VStack(spacing: 8) {
                    Text(isVideo ? "Exporting Video" : "Exporting Screenshot")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(statusText(for: displayProgress))
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))

                    // Animated dots
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(Color.white)
                                .frame(width: 6, height: 6)
                                .opacity(isAnimating ? 1 : 0.3)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                        .repeatForever()
                                        .delay(Double(index) * 0.2),
                                    value: isAnimating
                                )
                        }
                    }
                    .padding(.top, 4)
                }

                // Tip text
                Text("Please wait, this may take a moment...")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.top, 8)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.3), radius: 20)
            )
        }
        .onAppear {
            isAnimating = true
            startFakeProgress()
        }
    }

    private func startFakeProgress() {
        Task {
            while simulatedPercent < 79 {
                // Variable delay based on current progress
                let delayMs: UInt64
                if simulatedPercent < 10 {
                    delayMs = 250  // Fast: 1% every 0.25s (0-10% in ~2.5s)
                } else if simulatedPercent < 30 {
                    delayMs = 350  // Medium: 1% every 0.35s (10-30% in ~7s)
                } else if simulatedPercent < 50 {
                    delayMs = 500  // Slower: 1% every 0.5s (30-50% in ~10s)
                } else if simulatedPercent < 70 {
                    delayMs = 800  // Even slower: 1% every 0.8s (50-70% in ~16s)
                } else {
                    delayMs = 1500 // Very slow: 1% every 1.5s (70-79% in ~13.5s)
                }

                try? await Task.sleep(nanoseconds: delayMs * 1_000_000)

                // Only increment if simulated is still ahead of real progress
                let realPercent = Int(progress * 100)
                await MainActor.run {
                    if simulatedPercent >= realPercent && simulatedPercent < 79 {
                        simulatedPercent += 1
                    }
                }
            }
        }
    }
}

#Preview {
    ExportView(conversation: Conversation(title: "Test"))
}
