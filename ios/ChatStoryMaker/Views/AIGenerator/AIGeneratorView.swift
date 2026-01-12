//
//  AIGeneratorView.swift
//  Textory
//
//  AI-powered story generation screen
//

import SwiftUI
import SwiftData

struct AIGeneratorView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = AIGeneratorViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Credits badge (only show for non-premium users)
                    if !viewModel.isPremium {
                        creditsBadge
                    }

                    // Prompt Section
                    PromptInputView(prompt: $viewModel.prompt)

                    // Chat Type
                    CharacterCountPickerView(numCharacters: $viewModel.numCharacters)

                    // Genre
                    GenrePickerView(
                        selectedGenre: $viewModel.selectedGenre,
                        customGenre: $viewModel.customGenre
                    )

                    // Mood
                    MoodPickerView(
                        selectedMood: $viewModel.selectedMood,
                        customMood: $viewModel.customMood
                    )

                    // Length
                    LengthPickerView(selectedLength: $viewModel.selectedLength)

                    // Generate button
                    generateButton
                        .padding(.top, 8)
                }
                .padding()
            }
            .navigationTitle("Create Story")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(isPresented: $viewModel.showingEditor) {
                if let conversation = viewModel.generatedConversation {
                    ChatEditorView(conversation: conversation)
                }
            }
            .alert("Generation Error", isPresented: Binding(
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
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
        }
    }

    private var creditsBadge: some View {
        Button {
            viewModel.showPaywall = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                Text("\(viewModel.remainingGenerations) generations left")
                    .font(.system(size: 14, weight: .medium))
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
            }
            .foregroundColor(viewModel.remainingGenerations > 0 ? .purple : .red)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(viewModel.remainingGenerations > 0 ? Color.purple.opacity(0.1) : Color.red.opacity(0.1))
            )
        }
    }

    private var generateButton: some View {
        Button(action: {
            Task { await viewModel.generateStory() }
        }) {
            HStack(spacing: 10) {
                if viewModel.isGenerating {
                    ProgressView()
                        .tint(.white)
                    Text("Generating...")
                } else {
                    Image(systemName: "sparkles")
                    Text("Generate")
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(viewModel.canGenerate ? Color.purple : Color.gray)
            )
        }
        .disabled(!viewModel.canGenerate)
    }
}

// MARK: - Prompt Input

struct PromptInputView: View {
    @Binding var prompt: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What's your story about?")
                .font(.headline)

            TextField("Describe your story idea...", text: $prompt, axis: .vertical)
                .lineLimit(3...6)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(12)

            Text("Be specific for better results")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Chat Type Picker

struct CharacterCountPickerView: View {
    @Binding var numCharacters: Int

    private var isGroupChat: Bool {
        numCharacters > 2
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Chat Type")
                .font(.headline)

            HStack(spacing: 10) {
                ChatTypeButton(
                    title: "1-on-1",
                    icon: "person.2.fill",
                    isSelected: !isGroupChat
                ) {
                    numCharacters = 2
                }

                ChatTypeButton(
                    title: "Group",
                    icon: "person.3.fill",
                    isSelected: isGroupChat
                ) {
                    if numCharacters < 3 {
                        numCharacters = 3
                    }
                }
            }

            if isGroupChat {
                HStack {
                    Text("\(numCharacters) people")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.purple)
                        .frame(width: 80, alignment: .leading)

                    Slider(
                        value: Binding(
                            get: { Double(numCharacters) },
                            set: { numCharacters = Int($0) }
                        ),
                        in: 3...10,
                        step: 1
                    )
                    .tint(.purple)
                }
                .padding(.horizontal, 4)
                .padding(.top, 4)
            }
        }
    }
}

struct ChatTypeButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.body)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.purple.opacity(0.12) : Color(.systemGray6))
            .foregroundColor(isSelected ? .purple : .primary)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.purple.opacity(0.5) : Color.clear, lineWidth: 1.5)
            )
        }
    }
}

// MARK: - Genre Picker

struct GenrePickerView: View {
    @Binding var selectedGenre: AIService.Genre?
    @Binding var customGenre: String
    @State private var showCustomInput = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Genre")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(AIService.Genre.allCases, id: \.self) { genre in
                        ChipButton(
                            title: genre.displayName,
                            isSelected: selectedGenre == genre && !showCustomInput,
                            color: .accentColor
                        ) {
                            selectedGenre = genre
                            showCustomInput = false
                            customGenre = ""
                        }
                    }

                    // Custom option
                    ChipButton(
                        title: "Custom",
                        isSelected: showCustomInput,
                        color: .accentColor
                    ) {
                        showCustomInput = true
                        selectedGenre = nil
                    }
                }
            }

            if showCustomInput {
                TextField("Enter custom genre...", text: $customGenre)
                    .textFieldStyle(.roundedBorder)
                    .font(.subheadline)
            }
        }
    }
}

// MARK: - Mood Picker

struct MoodPickerView: View {
    @Binding var selectedMood: AIService.Mood?
    @Binding var customMood: String
    @State private var showCustomInput = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Mood")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(AIService.Mood.allCases, id: \.self) { mood in
                        ChipButton(
                            title: mood.displayName,
                            isSelected: selectedMood == mood && !showCustomInput,
                            color: .orange
                        ) {
                            selectedMood = mood
                            showCustomInput = false
                            customMood = ""
                        }
                    }

                    // Custom option
                    ChipButton(
                        title: "Custom",
                        isSelected: showCustomInput,
                        color: .orange
                    ) {
                        showCustomInput = true
                        selectedMood = nil
                    }
                }
            }

            if showCustomInput {
                TextField("Enter custom mood...", text: $customMood)
                    .textFieldStyle(.roundedBorder)
                    .font(.subheadline)
            }
        }
    }
}

// MARK: - Length Picker

struct LengthPickerView: View {
    @Binding var selectedLength: AIService.MessageLength

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Length")
                .font(.headline)

            Picker("Length", selection: $selectedLength) {
                ForEach(AIService.MessageLength.allCases, id: \.self) { length in
                    Text(length.displayName).tag(length)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

// MARK: - Chip Button

struct ChipButton: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? color.opacity(0.15) : Color(.systemGray6))
                .foregroundColor(isSelected ? color : .primary)
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(isSelected ? color.opacity(0.5) : Color.clear, lineWidth: 1.5)
                )
        }
    }
}

#Preview {
    AIGeneratorView()
        .modelContainer(for: [Conversation.self, Character.self, Message.self], inMemory: true)
}
