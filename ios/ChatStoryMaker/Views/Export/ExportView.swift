//
//  ExportView.swift
//  Textery
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
    @State private var showExportWarning = false

    init(conversation: Conversation) {
        self._viewModel = State(initialValue: ExportViewModel(conversation: conversation))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 24) {
                        StoryVideoHeaderCard(conversation: viewModel.conversation)

                        VideoPreviewView(
                            conversation: viewModel.conversation,
                            settings: viewModel.settings
                        )

                        // Format picker
                        FormatPickerView(selectedFormat: $viewModel.settings.format)

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
                        isVideo: true
                    )
                }
            }
            .navigationTitle("Export Story Video")
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
            .alert("Reminder", isPresented: $showExportWarning) {
                Button("Cancel", role: .cancel) {}
                Button("Export Video") {
                    viewModel.isExporting = true
                    viewModel.exportProgress = 0
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        Task {
                            await viewModel.startExport()
                        }
                    }
                }
            } message: {
                Text("This story video is fictional entertainment content. Share it responsibly and clearly as a created scene.")
            }
        }
    }

    private var exportButton: some View {
        Button {
            guard !viewModel.isExporting && !viewModel.conversation.messages.isEmpty else { return }
            showExportWarning = true
        } label: {
            Group {
                if viewModel.isExporting {
                    HStack(spacing: 12) {
                        ProgressView()
                            .tint(.white)
                        Text("Exporting \(Int(viewModel.exportProgress * 100))%")
                    }
                } else {
                    Label("Export Video", systemImage: "video.fill")
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.canExport ? Color(hex: "#1A9E6D") : Color.gray)
            .cornerRadius(12)
        }
        .disabled(!viewModel.canExport)
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
                .aspectRatio(aspectRatio, contentMode: .fit)
                .overlay(
                    VStack(spacing: 0) {
                        StoryVideoPreviewBanner()
                            .padding(.horizontal, 12)
                            .padding(.top, 12)

                        previewHeader
                            .padding(.top, 4)
                            .padding(.bottom, 8)

                        Divider()

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
                Text(conversation.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(settings.darkMode ? .white : .black)
            }

            Text("Scripted scene")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .overlay(alignment: .leading) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "#E07B5E"))
                .padding(.leading, 12)
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
                HStack(spacing: 2) {
                    Text(conversation.title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(settings.darkMode ? .white : .black)
                }

                Text("Cast scene")
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
            } else {
                Text("Cast scene")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(settings.darkMode ? .white : .black)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .overlay(alignment: .leading) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "#E07B5E"))
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

    private let coral = Color(red: 224/255, green: 123/255, blue: 94/255)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("FORMAT")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(coral)

            HStack(spacing: 12) {
                ForEach(ExportFormat.allCases, id: \.self) { format in
                    let isSelected = selectedFormat == format
                    Button(action: {
                        selectedFormat = format
                        HapticManager.selection()
                    }) {
                        VStack(spacing: 6) {
                            Text(format.displayName)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.primary)
                            Text(format.aspectRatio)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(isSelected ? coral.opacity(0.1) : Color(.systemGray6))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(isSelected ? coral : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
                        )
                    }
                }
            }
        }
    }
}

struct StoryVideoHeaderCard: View {
    let conversation: Conversation

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("FICTIONAL STORY VIDEO")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: "#E07B5E"))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(hex: "#E07B5E").opacity(0.12))
                .clipShape(Capsule())

            Text("Export a creator-ready story scene")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.primary)

            Text("Preview your scripted scene, choose a format, and turn it into a short-form video.")
                .font(.system(size: 15))
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                exportInfoChip(title: conversation.isGroupChat ? "Cast scene" : "Two-character scene", icon: "theatermasks.fill")
                exportInfoChip(title: "Short-form video", icon: "play.rectangle.fill")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func exportInfoChip(title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            .clipShape(Capsule())
    }
}

struct StoryVideoPreviewBanner: View {
    var body: some View {
        HStack {
            Label("Story Video Preview", systemImage: "film.stack.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(hex: "#E07B5E"))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(hex: "#E07B5E").opacity(0.12))
                .clipShape(Capsule())

            Spacer()

            Text("Scripted scene")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
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

            Toggle("Intro Card", isOn: $settings.includeIntroCard)
            Toggle("Outro Card", isOn: $settings.includeOutroCard)
            Toggle("Typing Indicator", isOn: $settings.showTypingIndicator)
            Toggle("Sound Effects", isOn: $settings.enableSounds)
            Toggle("Dark Mode", isOn: $settings.darkMode)

            // Keyboard toggle only applies when story perspective is off
            if !settings.storyPerspective {
                Toggle("Show Keyboard", isOn: $settings.showKeyboard)
            }
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
                Text("Exporting Video")
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
            return "Rendering frames..."
        } else if progress < 0.95 {
            return "Adding audio..."
        } else {
            return "Almost done..."
        }
    }
}

#Preview {
    ExportView(conversation: Conversation(title: "Test"))
}
