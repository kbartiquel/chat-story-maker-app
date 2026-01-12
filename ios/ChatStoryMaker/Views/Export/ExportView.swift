//
//  ExportView.swift
//  Textory
//
//  Export settings screen with video/screenshot preview
//

import SwiftUI
import SwiftData

struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ExportViewModel
    @State private var showHistory = false

    init(conversation: Conversation) {
        self._viewModel = State(initialValue: ExportViewModel(conversation: conversation))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 24) {
                        // Credits badge (only for video exports, non-premium users)
                        if viewModel.settings.exportType == .video && !viewModel.isPremium {
                            creditsBadge
                        }

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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                    .disabled(viewModel.isExporting)
                }
            }
            .sheet(isPresented: $viewModel.showShareSheet) {
                ShareSheet(items: viewModel.shareItems)
            }
            .sheet(isPresented: $showHistory) {
                ExportHistoryView()
            }
            .onChange(of: viewModel.lastExportHistory) { _, newHistory in
                // Save export history to SwiftData
                if let history = newHistory {
                    modelContext.insert(history)
                    viewModel.lastExportHistory = nil
                }
            }
            .alert("Export Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
            .fullScreenCover(isPresented: $viewModel.showPaywall) {
                PaywallView(isLimitTriggered: true)
            }
        }
    }

    private var creditsBadge: some View {
        Button {
            viewModel.showPaywall = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "film")
                    .font(.system(size: 14))
                Text("\(viewModel.remainingVideoExports) exports left")
                    .font(.system(size: 14, weight: .medium))
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
            }
            .foregroundColor(viewModel.remainingVideoExports > 0 ? .accentColor : .red)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(viewModel.remainingVideoExports > 0 ? Color.accentColor.opacity(0.1) : Color.red.opacity(0.1))
            )
        }
    }

    private var exportButton: some View {
        Button {
            guard !viewModel.isExporting && !viewModel.conversation.messages.isEmpty else { return }
            // Set exporting state immediately for instant UI feedback
            viewModel.isExporting = true
            viewModel.exportProgress = 0

            // Delay export to let UI render and animations start
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                Task {
                    await viewModel.startExport()
                }
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
            .background(viewModel.canExport ? Color.accentColor : Color.gray)
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
                        .background(selectedType == type ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
                        .foregroundColor(selectedType == type ? .accentColor : .primary)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(selectedType == type ? Color.accentColor : Color.clear, lineWidth: 2)
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
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
            .foregroundColor(isSelected ? .accentColor : .primary)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
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

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            // Progress card
            VStack(spacing: 20) {
                // Circular progress indicator with percentage
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 12)
                        .frame(width: 120, height: 120)

                    // Progress arc glow (behind)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            Color.cyan.opacity(0.5),
                            style: StrokeStyle(lineWidth: 16, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .blur(radius: 4)

                    // Progress arc
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                colors: [.accentColor, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))

                    // Percentage text in center
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())
                }
                .animation(.easeOut(duration: 0.2), value: progress)

                // Title
                Text(isVideo ? "Exporting Video" : "Exporting Screenshot")
                    .font(.headline)
                    .foregroundColor(.white)

                // Status text
                Text(statusText)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
            )
        }
    }

    private var statusText: String {
        if progress < 0.1 {
            return "Preparing..."
        } else if progress < 0.8 {
            return isVideo ? "Rendering frames..." : "Generating image..."
        } else if progress < 0.95 {
            return isVideo ? "Adding audio..." : "Finishing up..."
        } else {
            return "Almost done..."
        }
    }
}

#Preview {
    ExportView(conversation: Conversation(title: "Test"))
}
