//
//  DeliveryStatusView.swift
//  ChatStoryMaker
//
//  Delivery status indicators - WhatsApp checkmarks or iMessage text
//

import SwiftUI

struct DeliveryStatusView: View {
    let status: DeliveryStatus
    let style: ReceiptStyle

    var body: some View {
        switch style {
        case .whatsapp:
            whatsappStyle
        case .imessage:
            imessageStyle
        }
    }

    @ViewBuilder
    private var whatsappStyle: some View {
        HStack(spacing: 1) {
            switch status {
            case .none:
                EmptyView()
            case .sending:
                Image(systemName: "clock")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            case .sent:
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
            case .delivered:
                HStack(spacing: -4) {
                    Image(systemName: "checkmark")
                    Image(systemName: "checkmark")
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.gray)
            case .read:
                HStack(spacing: -4) {
                    Image(systemName: "checkmark")
                    Image(systemName: "checkmark")
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.blue)
            }
        }
        .padding(.trailing, 4)
    }

    @ViewBuilder
    private var imessageStyle: some View {
        switch status {
        case .none:
            EmptyView()
        case .sending:
            Text("Sending...")
                .font(.caption2)
                .foregroundColor(.secondary)
        case .sent:
            Text("Sent")
                .font(.caption2)
                .foregroundColor(.secondary)
        case .delivered:
            Text("Delivered")
                .font(.caption2)
                .foregroundColor(.secondary)
        case .read:
            Text("Read")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        VStack(alignment: .trailing, spacing: 8) {
            Text("WhatsApp Style").font(.headline)
            ForEach(DeliveryStatus.allCases, id: \.self) { status in
                HStack {
                    Text(status.rawValue.capitalized)
                    Spacer()
                    DeliveryStatusView(status: status, style: .whatsapp)
                }
            }
        }

        Divider()

        VStack(alignment: .trailing, spacing: 8) {
            Text("iMessage Style").font(.headline)
            ForEach(DeliveryStatus.allCases, id: \.self) { status in
                HStack {
                    Text(status.rawValue.capitalized)
                    Spacer()
                    DeliveryStatusView(status: status, style: .imessage)
                }
            }
        }
    }
    .padding()
}
