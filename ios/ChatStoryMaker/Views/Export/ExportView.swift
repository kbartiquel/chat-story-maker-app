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
                        ExportSettingsSection(
                            settings: $viewModel.settings,
                            messages: viewModel.conversation.sortedMessages
                        )

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

    private var mainContact: Character? {
        conversation.characters.first { !$0.isMe }
    }

    private var participants: [Character] {
        conversation.characters.filter { !$0.isMe }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(settings.darkMode ? Color.black : Color.white)
                .aspectRatio(settings.exportType == .screenshot ? 9/16 : aspectRatio, contentMode: .fit)
                .overlay(
                    VStack(spacing: 0) {
                        // iMessage-style header
                        previewHeader
                            .padding(.bottom, 8)

                        Divider()

                        // iMessage label
                        Text("iMessage")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                            .padding(.top, 6)

                        // Messages
                        VStack(spacing: 6) {
                            ForEach(conversation.sortedMessages.prefix(4)) { message in
                                let character = conversation.characters.first { $0.id == message.characterID }
                                let isMe = character?.isMe ?? true
                                HStack(alignment: .bottom, spacing: 6) {
                                    if isMe { Spacer(minLength: 40) }

                                    // Avatar for received messages in group chat
                                    if !isMe && conversation.isGroupChat {
                                        Circle()
                                            .fill(Color(hex: character?.colorHex ?? "#34C759"))
                                            .frame(width: 20, height: 20)
                                            .overlay(
                                                Text(character?.avatarEmoji ?? String(character?.name.prefix(1) ?? "?"))
                                                    .font(.system(size: character?.avatarEmoji != nil ? 10 : 8))
                                                    .foregroundColor(.white)
                                            )
                                    }

                                    Text(message.text)
                                        .font(.system(size: 12))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(isMe ? conversation.theme.senderBubbleColor : (settings.darkMode ? Color(white: 0.23) : conversation.theme.receiverBubbleColor))
                                        .foregroundColor(isMe ? conversation.theme.senderTextColor : (settings.darkMode ? .white : conversation.theme.receiverTextColor))
                                        .cornerRadius(16)
                                        .lineLimit(2)

                                    if !isMe { Spacer(minLength: 40) }
                                }
                            }
                            if conversation.messages.count > 4 {
                                Text("+ \(conversation.messages.count - 4) more")
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 8)

                        Spacer()
                    }
                )

            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
        }
        .frame(height: 320)
    }

    @ViewBuilder
    private var previewHeader: some View {
        if conversation.isGroupChat {
            // Group chat header with stacked avatars
            groupPreviewHeader
        } else {
            // 1:1 chat header
            contactPreviewHeader
        }
    }

    @ViewBuilder
    private var contactPreviewHeader: some View {
        VStack(spacing: 2) {
            // Avatar
            previewAvatar(mainContact, size: 36)

            // Name with chevron
            HStack(spacing: 2) {
                Text(mainContact?.name ?? conversation.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(settings.darkMode ? .white : .black)
                Image(systemName: "chevron.right")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .overlay(alignment: .leading) {
            // Back arrow
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
                .padding(.leading, 12)
                .padding(.top, 8)
        }
        .overlay(alignment: .trailing) {
            // Video icon
            Image(systemName: "video.fill")
                .font(.system(size: 14))
                .foregroundColor(.blue)
                .padding(.trailing, 12)
                .padding(.top, 8)
        }
    }

    @ViewBuilder
    private var groupPreviewHeader: some View {
        let hasGroupName = !conversation.title.isEmpty &&
            conversation.title != "Chat" &&
            conversation.title != "Group Chat"

        VStack(spacing: 2) {
            // Stacked avatars
            HStack(spacing: -8) {
                ForEach(participants.prefix(4)) { participant in
                    previewAvatar(participant, size: 28)
                        .overlay(
                            Circle()
                                .stroke(settings.darkMode ? Color.black : Color.white, lineWidth: 1.5)
                        )
                }
            }

            if hasGroupName {
                // Group name (bold)
                HStack(spacing: 2) {
                    Text(conversation.title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(settings.darkMode ? .white : .black)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(.gray)
                }

                // Member count (gray)
                Text("\(conversation.characters.count) People")
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
            } else {
                // Just people count
                HStack(spacing: 2) {
                    Text("\(conversation.characters.count) People")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(settings.darkMode ? .white : .black)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .overlay(alignment: .leading) {
            // Back arrow
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
                .padding(.leading, 12)
                .padding(.top, 8)
        }
    }

    @ViewBuilder
    private func previewAvatar(_ character: Character?, size: CGFloat) -> some View {
        Circle()
            .fill(Color(hex: character?.colorHex ?? "#007AFF"))
            .frame(width: size, height: size)
            .overlay(
                Group {
                    if let imageData = character?.avatarImageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    } else {
                        Text(character?.avatarEmoji ?? String(character?.name.prefix(1) ?? "?"))
                            .font(.system(size: character?.avatarEmoji != nil ? size * 0.5 : size * 0.4))
                            .foregroundColor(.white)
                    }
                }
            )
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
    let messages: [Message]

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
                VStack(alignment: .leading, spacing: 12) {
                    Text("Screenshot Mode")
                        .font(.subheadline)
                    HStack(spacing: 12) {
                        ForEach(ScreenshotMode.allCases, id: \.self) { mode in
                            Button(action: {
                                settings.screenshotMode = mode
                                HapticManager.selection()
                            }) {
                                VStack(spacing: 6) {
                                    Image(systemName: mode.icon)
                                        .font(.title3)
                                    Text(mode.displayName)
                                        .font(.caption)
                                        .fontWeight(settings.screenshotMode == mode ? .semibold : .regular)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(settings.screenshotMode == mode ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
                                .foregroundColor(settings.screenshotMode == mode ? .accentColor : .primary)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(settings.screenshotMode == mode ? Color.accentColor : Color.clear, lineWidth: 2)
                                )
                            }
                        }
                    }
                    Text(settings.screenshotMode.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

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
