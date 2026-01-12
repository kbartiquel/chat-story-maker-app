//
//  TimestampEditorView.swift
//  Textory
//
//  Edit message timestamp for storytelling
//

import SwiftUI

struct TimestampEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var showTimestamp: Bool
    @Binding var displayTime: Date?
    let actualTime: Date

    @State private var selectedDate: Date

    init(showTimestamp: Binding<Bool>, displayTime: Binding<Date?>, actualTime: Date) {
        self._showTimestamp = showTimestamp
        self._displayTime = displayTime
        self.actualTime = actualTime
        self._selectedDate = State(initialValue: displayTime.wrappedValue ?? actualTime)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Show Timestamp", isOn: $showTimestamp)
                }

                if showTimestamp {
                    Section("Display Time") {
                        DatePicker(
                            "Time",
                            selection: $selectedDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.graphical)

                        Button("Reset to Actual Time") {
                            selectedDate = actualTime
                            displayTime = nil
                            HapticManager.selection()
                        }
                        .foregroundColor(.accentColor)
                    }

                    Section("Preview") {
                        HStack {
                            Spacer()
                            TimestampView(date: selectedDate)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Edit Timestamp")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if selectedDate != actualTime {
                            displayTime = selectedDate
                        } else {
                            displayTime = nil
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    TimestampEditorView(
        showTimestamp: .constant(true),
        displayTime: .constant(nil),
        actualTime: Date()
    )
}
