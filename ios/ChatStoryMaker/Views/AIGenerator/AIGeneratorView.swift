//
//  AIGeneratorView.swift
//  ChatStoryMaker
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
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 50))
                            .foregroundColor(.purple)
                        Text("AI Story Generator")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Enter a prompt and let AI create your chat story")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)

                    // Prompt input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Story Prompt")
                            .font(.headline)
                        TextEditor(text: $viewModel.prompt)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                        Text("e.g., \"Two friends planning a surprise birthday party\"")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Genre picker
                    GenrePickerView(selectedGenre: $viewModel.selectedGenre)

                    // Mood picker
                    MoodPickerView(selectedMood: $viewModel.selectedMood)

                    // Length picker
                    LengthPickerView(selectedLength: $viewModel.selectedLength)

                    // Generate button
                    generateButton
                }
                .padding()
            }
            .navigationTitle("AI Generate")
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
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
        }
    }

    private var generateButton: some View {
        Button(action: {
            Task { await viewModel.generateStory() }
        }) {
            Group {
                if viewModel.isGenerating {
                    HStack(spacing: 12) {
                        ProgressView()
                            .tint(.white)
                        Text("Generating...")
                    }
                } else {
                    Label("Generate Story", systemImage: "sparkles")
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.canGenerate ? Color.purple : Color.gray)
            .cornerRadius(12)
        }
        .disabled(!viewModel.canGenerate)
    }
}

struct GenrePickerView: View {
    @Binding var selectedGenre: AIService.Genre

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Genre")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(AIService.Genre.allCases, id: \.self) { genre in
                        ChipButton(
                            title: genre.rawValue,
                            icon: genreIcon(genre),
                            isSelected: selectedGenre == genre,
                            color: .blue
                        ) {
                            selectedGenre = genre
                        }
                    }
                }
            }
        }
    }

    private func genreIcon(_ genre: AIService.Genre) -> String {
        switch genre {
        case .drama: return "theatermasks.fill"
        case .comedy: return "face.smiling.fill"
        case .romance: return "heart.fill"
        case .horror: return "bolt.fill"
        case .mystery: return "magnifyingglass"
        }
    }
}

struct MoodPickerView: View {
    @Binding var selectedMood: AIService.Mood

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mood")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(AIService.Mood.allCases, id: \.self) { mood in
                        ChipButton(
                            title: mood.rawValue,
                            icon: moodIcon(mood),
                            isSelected: selectedMood == mood,
                            color: .orange
                        ) {
                            selectedMood = mood
                        }
                    }
                }
            }
        }
    }

    private func moodIcon(_ mood: AIService.Mood) -> String {
        switch mood {
        case .funny: return "face.smiling"
        case .dramatic: return "exclamationmark.triangle"
        case .scary: return "eye.fill"
        case .romantic: return "heart.circle"
        }
    }
}

struct LengthPickerView: View {
    @Binding var selectedLength: AIService.MessageLength

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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

struct ChipButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? color.opacity(0.2) : Color(.systemGray6))
            .foregroundColor(isSelected ? color : .primary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
        }
    }
}

#Preview {
    AIGeneratorView()
        .modelContainer(for: [Conversation.self, Character.self, Message.self], inMemory: true)
}
