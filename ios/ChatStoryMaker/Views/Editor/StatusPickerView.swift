//
//  StatusPickerView.swift
//  ChatStoryMaker
//
//  Pick delivery status for a message
//

import SwiftUI

struct StatusPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var status: DeliveryStatus
    let receiptStyle: ReceiptStyle

    var body: some View {
        NavigationStack {
            List {
                ForEach(DeliveryStatus.allCases, id: \.self) { statusOption in
                    Button(action: {
                        status = statusOption
                        HapticManager.selection()
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(statusOption.displayName)
                                    .foregroundColor(.primary)

                                if statusOption != .none {
                                    DeliveryStatusView(status: statusOption, style: receiptStyle)
                                }
                            }

                            Spacer()

                            if status == statusOption {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Delivery Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

extension DeliveryStatus {
    var displayName: String {
        switch self {
        case .none: return "No Status"
        case .sending: return "Sending"
        case .sent: return "Sent"
        case .delivered: return "Delivered"
        case .read: return "Read"
        }
    }
}

#Preview {
    StatusPickerView(
        status: .constant(.delivered),
        receiptStyle: .whatsapp
    )
}
