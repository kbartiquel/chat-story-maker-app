//
//  FolderManagementView.swift
//  Textory
//
//  Create, edit, and delete folders
//

import SwiftUI

struct FolderManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: ConversationViewModel
    @State private var showingNewFolder = false
    @State private var editingFolder: Folder?

    var body: some View {
        NavigationStack {
            List {
                if viewModel.folders.isEmpty {
                    ContentUnavailableView(
                        "No Folders",
                        systemImage: "folder",
                        description: Text("Create folders to organize your conversations")
                    )
                } else {
                    ForEach(viewModel.folders) { folder in
                        Button(action: {
                            editingFolder = folder
                        }) {
                            HStack {
                                Circle()
                                    .fill(folder.color)
                                    .frame(width: 24, height: 24)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(folder.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    let count = viewModel.conversationsInFolder(folder).count
                                    Text("\(count) conversation\(count == 1 ? "" : "s")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel.deleteFolder(folder)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Folders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingNewFolder = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewFolder) {
                FolderEditorView(
                    mode: .create,
                    onSave: { name, colorHex in
                        viewModel.createFolder(name: name, colorHex: colorHex)
                    }
                )
            }
            .sheet(item: $editingFolder) { folder in
                FolderEditorView(
                    mode: .edit(folder),
                    onSave: { name, colorHex in
                        viewModel.updateFolder(folder, name: name, colorHex: colorHex)
                    }
                )
            }
        }
    }
}

// MARK: - Folder Editor

struct FolderEditorView: View {
    enum Mode {
        case create
        case edit(Folder)
    }

    @Environment(\.dismiss) private var dismiss
    let mode: Mode
    let onSave: (String, String) -> Void

    @State private var name: String = ""
    @State private var selectedColorHex: String = "#1DB678"

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Folder name", text: $name)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(Folder.presetColors, id: \.self) { colorHex in
                            Circle()
                                .fill(Color(hex: colorHex))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColorHex == colorHex ? 3 : 0)
                                )
                                .onTapGesture {
                                    selectedColorHex = colorHex
                                    HapticManager.selection()
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Preview") {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color(hex: selectedColorHex))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "folder.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            )

                        Text(name.isEmpty ? "Folder Name" : name)
                            .font(.headline)
                    }
                }
            }
            .navigationTitle(isCreating ? "New Folder" : "Edit Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(name.trimmingCharacters(in: .whitespaces), selectedColorHex)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if case .edit(let folder) = mode {
                    name = folder.name
                    selectedColorHex = folder.colorHex
                }
            }
        }
    }

    private var isCreating: Bool {
        if case .create = mode { return true }
        return false
    }
}

#Preview {
    FolderManagementView(viewModel: ConversationViewModel())
}
